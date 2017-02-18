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
  var cache = new tink.macro.TypeMap<Expr>();
  
  static public function crawl(type:Type, pos:Position, gen:Generator) {
    var c = new Crawler(gen, type, pos);
    
    var expr = c.genType(type, pos);
    
    return {
      expr: expr,
      fields: c.ret,
    }
  }
  
  function cached(t:Type, pos:Position, make:Void->Expr) 
    return switch cache.get(t) {
      case null:
        var method = 'parse${Lambda.count(cache)}';
              
        var placeholder = macro @:pos(pos) null;
        
        var ct = t.toComplex();
        var func = gen.wrap(placeholder, t.toComplex());      
        var args = [for (a in func.args) a.name.resolve()];
        
        var call = macro @:pos(pos) this.$method($a{args});
        cache.set(t, call);

        add([{
          name: method,
          pos: pos,
          kind: FFun(func),
        }]);
        
        var impl = make();
        
        placeholder.expr = impl.expr;
        placeholder.pos = impl.pos;
        
        call;
      case v: v;
    }
  
  var methodCalls = new Map<String, Expr>();
  
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
                        pos: f.pos,
                        meta: f.meta.get(),
                      }];
                    case TFun(args, ret):
                      [for (a in args) { 
                        name: a.name, 
                        type: a.t, 
                        expr: genType(a.t, c.pos), 
                        optional: a.opt, 
                        pos: c.pos,
                        meta: [], // TODO: meta is lost?
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
              return gen.enm(constructors, ct, pos, genType);
            });
          
          case v: 
            cached(t, pos, function () return switch gen.rescue(t, pos, genType) {
              case None: pos.error(gen.reject(t));
              case Some(e): e; 
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
        meta: f.meta.get(),
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
  
  static public function typesEqual(t1, t2)
    return Context.unify(t1, t2) && Context.unify(t2, t1);//TODO: make this more exact
  
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