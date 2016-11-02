package tink.typecrawler;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.ds.Option;

using haxe.macro.Tools;
using tink.MacroApi;

class Crawler { 
  
  var ret:Array<Field> = [];
  var gen:Generator;
  var cache = new Map<String, Type>();
  
  static public function crawl(type:Type, pos:Position, gen:Generator) {
    var c = new Crawler(gen, type, pos);
    
    var expr = c.genType(type, pos);
    
    return {
      expr: expr,
      fields: c.ret,
    }
  }
  
  function func(e:Expr, ret:ComplexType):Function 
    return {
      expr: macro @:pos(e.pos) return $e,
      ret: ret,
      args: [for (a in gen.args()) { name: a, type: null }]
    }
  
  function cached(t:Type, pos:Position, make:Void->Function) {
    var method = null;
    
    for (func in cache.keys()) {
      
      var known = cache[func];
      
      if (typesEqual(t, known)) {
        method = func;
        break;
      }
      
    }
    
    if (method == null) {
      method = 'parse${Lambda.count(cache)}';
      
      cache[method] = t;
      
      var ct = t.toComplex();
      
      add([{
        name: method,
        pos: pos,
        kind: FFun(make()),
      }]);
      
    }    
    
    var args = [for (s in gen.args()) s.resolve()];
    
    return macro this.$method($a{args});
  }
  
  function new(gen, type:Type, pos:Position) {
    this.gen = gen;    
  }  
    
  function add(a:Array<Field>)
    ret = ret.concat(a);
  
  function genType(t:Type, pos:Position):Expr 
    return
      if (t.getID(false) == 'Null')
        gen.nullable(genType(t.reduce(), pos));
      else
        switch t.reduce() {
          
          case _.getID() => 'String': 
            gen.string();
            
          case _.getID() => 'Float': 
            gen.float();
            
          case _.getID() => 'Int': 
            gen.int();
            
          case _.getID() => 'Bool': 
            gen.bool();
            
          case _.getID() => 'Date':
            gen.date();
            
          case _.getID() => 'haxe.io.Bytes':
            gen.bytes();
           
          case TAnonymous(fields):
            
            cached(t, pos, function () 
              return gen.anon(serializableFields(fields.get().fields), t.toComplex())
            );
            
          case TInst(_.get() => { name: 'Array', pack: [] }, [t]):
            
            gen.array(genType(t, pos));
          
          case TDynamic(t) if (t != null):
            
            gen.dyn(gen.dynAccess(genType(t, pos)), t.toComplex());
          
          case TAbstract(_.get() => { name: 'DynamicAccess', pack: ['haxe'] }, [v]): //TODO: if we capture the param as "t" here, weird errors occur
            
            gen.dynAccess(genType(v, pos));
            
          case TAbstract(_.get() => { name: 'Map', pack: [] }, [k, v]):
            
            gen.map(genType(k, pos), genType(v, pos));
            
          case plainAbstract(_) => Some(a):
            
            genType(a, pos);     
            
          case TEnum(_.get() => e, params):
            
            cached(t, pos, function () {
              var constructors = [];
              for (name in e.names) {
                
                var c = e.constructs[name],
                    inlined = false;
                
                var cfields = 
                  switch c.type.applyTypeParameters(e.params, params).reduce() {
                    case TFun([{ name: name, t: _.reduce() => TAnonymous(anon) }], ret) if (name.toLowerCase() == c.name.toLowerCase()):
                      inlined = true;
                      [for (f in anon.get().fields) { 
                        name: f.name, 
                        type: f.type, 
                        expr: genType(f.type, f.pos),
                        optional: f.meta.has(':optional'), 
                        pos: f.pos 
                      }];
                    case TFun(args, ret):
                      [for (a in args) { 
                        name: a.name, 
                        type: a.t, 
                        expr: genType(a.t, c.pos), 
                        optional: a.opt, 
                        pos: c.pos 
                      }];
                    default:
                      [];
                  }
                
                constructors.push({
                  inlined: inlined,
                  ctor: c,
                  fields: cfields,
                });
              }
              var ct = t.toComplex();
              return func(gen.enm(constructors, ct, pos, genType), ct);
            });
          
          case v: 
            cached(t, pos, function () return switch gen.rescue(t, pos, genType) {
              case None: pos.error(gen.reject(t));
              case Some(e): func(e, t.toComplex());
            });
            
        }
        
  function serializableFields(fields:Array<ClassField>):Array<FieldInfo> {//TODO: this clearly does not belong here
    
    var ret = new Array<FieldInfo>();
    
    function add(f:ClassField)
      ret.push({
        name: f.name,
        pos: f.pos,
        type: f.type,
        optional: f.meta.has(':optional'),
        expr: genType(f.type, f.pos),
      });
      
    for (f in fields)
      if (!f.meta.has(':transient'))
        switch f.kind {
          case FVar(AccNever | AccCall, AccNever | AccCall):
            if (f.meta.has(':isVar'))
              add(f);
          case FVar(read, write):
            add(f);
          default:
        }
    return ret;
  }
  
  static function typesEquivalent(t1, t2)
    return Context.unify(t1, t2) && Context.unify(t2, t1);

  static public function typesEqual(t1, t2)
    return typesEquivalent(t1, t2);//TODO: make this more exact
  
  static public function plainAbstract(t:Type)
    return switch t.reduce() {
      case TAbstract(_.get() => a, params):
        function apply(t:Type)
          return t.applyTypeParameters(a.params, params);
        
        var ret = apply(a.type);
        
        function get(casts:Array<{t:Type, field:Null<ClassField>}>) {
          for (c in casts)
            if (c.field == null && typesEqual(ret, apply(c.t))) 
              return true;
          return false;
        }        
        
        if (get(a.from) && get(a.to)) Some(ret) else None;
       
      default: None;
    }  
    
}