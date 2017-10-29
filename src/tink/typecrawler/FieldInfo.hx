package tink.typecrawler;

import haxe.macro.Expr;
import haxe.macro.Type;

class FieldInfo {
  public var name(default, null):String;
  public var pos(default, null):Position;
  public var type(default, null):Type;

  public var expr(get, null):Expr;
    function get_expr() return switch expr {
      case null: expr = as(type);
      case v: v;
    }

  public var optional(default, null):Bool;
  public var meta(default, null):Metadata;
  
  var gen:Generator.GenType;

  public function as(type:Type):Expr 
    return gen(type, pos);

  public function new(o, gen, optional, meta) {
    this.name = o.name;
    this.pos = o.pos;
    this.type = o.type;
    this.gen = gen;
    this.optional = optional;
    this.meta = meta;
  }

  public function makeOptional()
    return 
      if (this.optional) this;
      else new FieldInfo(this, gen, true, meta);

  static public function ofClassField(f:ClassField, gen) 
    return new FieldInfo(f, gen, f.meta.has(':optional'), f.meta.get());
  
}