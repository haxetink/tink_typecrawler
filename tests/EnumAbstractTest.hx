package;

import tink.unit.Assert.*;

class EnumAbstractTest {
  public function new() {}
  
  public function test() {
    return assert(run().join(',') == 'A,B,C');
  }
  macro static function run() {
    return tink.typecrawler.Crawler.crawl(haxe.macro.Context.getType('EnumAbstract'), (macro null).pos, Gen).expr;
  }
}


@:enum
abstract EnumAbstract(String) {
  var A = 'A';
  var B = 'B';
  var C = 'C';
  
  public static var i:Int;
  public static function f() {}
}