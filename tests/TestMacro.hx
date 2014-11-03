package tests;

/**
  @author 杨博
**/
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":cps"))
class TestMacro
{

  static function main():Void
  {
    var f = com.dongxiguo.continuation.Continuation.cpsFunction(function() @await M.m());
  }

}
