package;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.typecrawler.Generator;
import tink.typecrawler.FieldInfo;

using tink.MacroApi;
using tink.CoreApi;

class Gen {
  static public function wrap(placeholder:Expr, ct:ComplexType):Function {
	  return placeholder.func([{name: 'value', type: ct}]);
  }
  
  static public function nullable(e:Expr):Expr {
	  return throw 'abstract';
  }
  
  static public function string():Expr {
	  return macro value;
  }
  
  static public function float():Expr {
	  return throw 'abstract';
  }
  
  static public function int():Expr {
	  return throw 'abstract';
  }
  
  static public function dyn(e:Expr, ct:ComplexType):Expr {
	  return throw 'abstract';
  }
  
  static public function dynAccess(e:Expr):Expr {
	  return throw 'abstract';
  }
  
  static public function bool():Expr {
	  return throw 'abstract';
  }
  
  static public function date():Expr {
	  return throw 'abstract';
  }
  
  static public function bytes():Expr {
	  return throw 'abstract';
  }
  
  static public function anon(fields:Array<FieldInfo>, ct:ComplexType):Expr {
	  return throw 'abstract';
  }
  
  static public function array(e:Expr):Expr {
	  return throw 'abstract';
  }
  
  static public function map(k:Expr, v:Expr):Expr {
	  return throw 'abstract';
  }
  
  static public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr {
	  return throw 'abstract';
  }
  
  static public function enumAbstract(names:Array<String>, e:Expr):Expr {
	  return macro $a{names.map(function(n) return macro $v{n})};
  }
  
  static public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr> {
	  return throw 'abstract';
  }
  
  static public function reject(t:Type):String {
	  return throw 'abstract';
  }
  
  static public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool {
    return true;
  }
  
  static public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr {
    return gen(type, pos);
  }
  
}