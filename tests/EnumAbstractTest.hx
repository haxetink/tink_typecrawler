package;

import haxe.macro.Expr;
import tink.unit.Assert.*;

#if macro
using tink.MacroApi;
#end

class EnumAbstractTest {
  public function new() {}
  
  public function test() {
    return assert(run().join(',') == 'A,B,C');
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
  override function enumAbstract(names:Array<String>, e:Expr):Expr
    return macro $a{names.map(function(n) return macro $v{n})};
}
#end


@:enum
abstract EnumAbstract(String) {
  var A = 'A';
  var B = 'B';
  var C = 'C';
  
  public static var i:Int;
  public static function f() {}
}