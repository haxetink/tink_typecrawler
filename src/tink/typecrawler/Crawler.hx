package tink.typecrawler;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.ds.Option;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

@:callable
abstract GeneratorProvider(Crawler->Generator) from Crawler->Generator {
  @:from static function fromGenerator(g:Generator):GeneratorProvider
    return function (_) return g;
}

class Crawler {

  var ret:Array<Field> = [];
  var gen:Generator;
  var cacheSize = 0;
  var cache = new tink.macro.TypeMap<Expr>(function (t) return t);

  static public function crawl(type:Type, pos:Position, gen:GeneratorProvider) {
    var c = new Crawler(gen);

    var expr = c.genType(type, pos);

    return {
      expr: expr,
      fields: c.ret,
    }
  }

  public function add(td:TypeDefinition) {
    for (t in td.fields)
      ret.push(t);
    return td.fields;
  }

  public function cached(t:Type, pos:Position, make:Int->Expr)
    return switch cache.get(t) {
      case null:
        var id = cacheSize++;
        var method = 'process${id}';

        var placeholder = macro @:pos(pos) null;

        var ct = t.toComplex();
        var func = gen.wrap(placeholder, t.toComplex());
        var args = [for (a in func.args) a.name.resolve()];

        var call = macro @:pos(pos) this.$method($a{args});
        cache.set(t, call);

        ret.push({
          name: method,
          pos: pos,
          kind: FFun(func),
        });

        var impl = make(id);

        placeholder.expr = impl.expr;
        placeholder.pos = impl.pos;

        call;
      case v: v;
    }

  var methodCalls = new Map<String, Expr>();

  function new(gen:GeneratorProvider) {
    this.gen = gen(this);
  }

  function genType(t:Type, pos:Position):Expr
    return gen.drive(t, pos, doGenType);

  function doGenType(t:Type, pos:Position):Expr
    return
      if (t.getID(false) == 'Null')
        gen.nullable(genType(t.reduce(true), pos));
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

            cached(t, pos, function (_) {
              var info = fields.get().fields
                .filter(gen.shouldIncludeField.bind(_, None))
                .map(convertField);
              return gen.anon(info, t.toComplex());
            });

          case TInst(_.get() => { name: 'Array', pack: [] }, [t]):

            gen.array(genType(t, pos));

          case TDynamic(t) if (t != null):

            gen.dyn(gen.dynAccess(genType(t, pos)), t.toComplex());

          case TAbstract(_.get() => {meta: meta, impl: impl, type: underlying, name: name, module: module}, _) if(meta.has(':enum')):

            var statics = impl.get().statics.get();
            var path = ('$module.$name').split('.');
            var id = t.getID();
            var names = statics
              .filter(function(s) return s.kind.match(FVar(_)) && s.isPublic && s.type.getID() == id)
              .map(function(s) return macro $p{path.concat([s.name])});
            gen.enumAbstract(names, genType(underlying, pos), t.toComplex(), pos);

          case TAbstract(_.get() => { name: 'DynamicAccess', pack: ['haxe'] }, [v]): //TODO: if we capture the param as "t" here, weird errors occur

            gen.dynAccess(genType(v, pos));

          case TAbstract(_.get() => { name: 'Map', pack: [] | ['haxe', 'ds']}, [k, v]):

            gen.map(genType(k, pos), genType(v, pos));

          case plainAbstract(_) => Some(a):

            genType(a, pos);

          case TEnum(_.get() => e, params):

            cached(t, pos, function (_) {
              var constructors = [];
              for (name in e.names) {

                var c = e.constructs[name],
                    inlined = false;

                var cfields =
                  switch c.type.applyTypeParameters(e.params, params).reduce() {
                    case TFun([{ name: name, t: _.reduce() => TAnonymous(anon) }], ret) if (name.toLowerCase() == c.name.toLowerCase()):
                      inlined = true;
                      [for (f in anon.get().fields) convertField(f)];
                    case TFun(args, ret):
                      [for (a in args) makeInfo(
                        { name: a.name, type: a.t, pos: c.pos },
                        a.opt,
                        []// TODO: meta is lost?
                      )];
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
            cached(t, pos, function (_) return switch gen.rescue(t, pos, genType) {
              case None: pos.error(gen.reject(t));
              case Some(e): e;
            });

        }

  function convertField(f:ClassField):FieldInfo
    return FieldInfo.ofClassField(f, genType);

  function makeInfo(part, optional, meta):FieldInfo
    return new FieldInfo(part, genType, optional, meta);

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
