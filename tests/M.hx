package tests;
import haxe.macro.Expr;

/**
 * ...
 * @author 杨博
 */
class M
{
  public static function t(self:Expr):Expr
  {
    trace(haxe.macro.ExprTools.toString(self));
    return self;
  }

  @:macro
  public static function m(e:Expr):Expr
  {
    return macro $e();
  }
  
}