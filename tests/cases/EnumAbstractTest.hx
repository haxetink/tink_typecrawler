package cases;

import haxe.macro.Expr;
import tink.unit.Assert.*;

#if macro
using tink.MacroApi;
#end

class EnumAbstractTest {
  public function new() {}
  
  public function test() {
    return assert(run().join(',') == 'a,b,c');
  }
  macro static function run() {
    return tink.typecrawler.Crawler.crawl(haxe.macro.Context.getType('EnumAbstract'), (macro null).pos, new EnumAbstractGen()).expr;
  }
}

#if macro
class EnumAbstractGen extends Gen {
  override function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func([{name: 'value', type: ct}]);
  override function string():Expr
    return macro value;
  override function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr
    return macro $a{names.map(function(n) return macro {var value = $n; $e;})};
}
#end


@:enum
abstract EnumAbstract(String) {
  var A = 'a';
  var B = 'b';
  var C = 'c';
  
  public static var i:Int;
  public static function f() {}
}