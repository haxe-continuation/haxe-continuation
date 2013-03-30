package tests;
import com.dongxiguo.continuation.Continuation;

/**
* @author 杨博
*/
class Sample
{
  static function sleepOneSecond(handler:Void->Void):Void
  {
    haxe.Timer.delay(handler, 1000);
  }
  
  public static function main() 
  {
    Continuation.cpsFunction(function asyncTest():Void
    {
      trace("Start continuation.");
      for (i in 0...10)
      {
        sleepOneSecond().async();
        trace("Run sleepOneSecond " + i + " times.");
      }
      trace("Continuation is done.");
    });
    
    asyncTest(function()
    {
      trace("Handler without continuation.");
    });
  }
  
}


/**
* @author 杨博
*/
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("cps"))
class Sample2
{
  static function sleepOneSecond(handler:Void->Void):Void
  {
    haxe.Timer.delay(handler, 1000);
  }
  @cps static function asyncTest():Void
  {
    trace("Start continuation.");
    for (i in 0...10)
    {
      sleepOneSecond().async();
      trace("Run sleepOneSecond " + i + " times.");
    }
    trace("Continuation is done.");
  }
  public static function main() 
  {
    asyncTest(function()
    {
      trace("Handler without continuation.");
    });
  }
}