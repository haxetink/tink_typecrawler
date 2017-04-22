package;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.typecrawler.Generator;
import tink.typecrawler.FieldInfo;

using tink.MacroApi;
using tink.CoreApi;

class Gen {
  public function new() {}
  public function wrap(placeholder:Expr, ct:ComplexType):Function return throw 'abstract';
  public function nullable(e:Expr):Expr return throw 'abstract';
  public function string():Expr return throw 'abstract';
  public function float():Expr return throw 'abstract';
  public function int():Expr return throw 'abstract';
  public function dyn(e:Expr, ct:ComplexType):Expr return throw 'abstract';
  public function dynAccess(e:Expr):Expr return throw 'abstract';
  public function bool():Expr return throw 'abstract';
  public function date():Expr return throw 'abstract';
  public function bytes():Expr return throw 'abstract';
  public function anon(fields:Array<FieldInfo>, ct:ComplexType):Expr return throw 'abstract';
  public function array(e:Expr):Expr return throw 'abstract';
  public function map(k:Expr, v:Expr):Expr return throw 'abstract';
  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr return throw 'abstract';
  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr return throw 'abstract';
  public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr> return throw 'abstract';
  public function reject(t:Type):String return throw 'abstract';
  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool return true;
  public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr return gen(type, pos);
}