package tests;
import com.dongxiguo.continuation.Continuation;
class Sample 
{
  static var sleepOneSecond = callback(haxe.Timer.delay, _, 1000);
  
  public static function main() 
  {
    Continuation.cpsFunction(function asyncTest():Void
    {
      trace("Start continuation.");
      for (i in 0...10)
      {
        async(sleepOneSecond);
        trace("Run sleepOneSecond " + i + " times.");
      }
      trace("Continuation is done.");
    });
    
    asyncTest(function()
    {
      trace("Handler without continuation.");
    });
    //
  }
  
}