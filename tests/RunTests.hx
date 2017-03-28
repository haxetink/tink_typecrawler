package ;

#if macro
import tink.typecrawler.*;
import tink.typecrawler.Generator;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

using tink.CoreApi;

class RunTests {
  #if !macro
  static function main() {
    test();
    travix.Logger.println('it works');
    travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  #else
  static public function wrap(placeholder:Expr, ct:ComplexType):Function return throw 'abstract';
  static public function nullable(e:Expr):Expr return throw 'abstract';
  static public function string():Expr return throw 'abstract';
  static public function float():Expr return throw 'abstract';
  static public function int():Expr return throw 'abstract';
  static public function dyn(e:Expr, ct:ComplexType):Expr return throw 'abstract';
  static public function dynAccess(e:Expr):Expr return throw 'abstract';
  static public function bool():Expr return throw 'abstract';
  static public function date():Expr return throw 'abstract';
  static public function bytes():Expr return throw 'abstract';
  static public function anon(fields:Array<FieldInfo>, ct:ComplexType):Expr return throw 'abstract';
  static public function array(e:Expr):Expr return throw 'abstract';
  static public function map(k:Expr, v:Expr):Expr return throw 'abstract';
  static public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr return throw 'abstract';
  static public function enumAbstract(names:Array<String>, e:Expr):Expr return throw 'abstract';
  static public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr> return throw 'abstract';
  static public function reject(t:Type):String return throw 'abstract';
  #end
  macro static function test() {
    return Crawler.crawl(haxe.macro.Context.getType('String'), (macro null).pos, RunTests, function (_, _, _) return macro 'it works').expr;
  }
}