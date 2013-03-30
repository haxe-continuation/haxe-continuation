package tests;
import haxe.Timer;

using com.dongxiguo.continuation.utils.ForkJoin;

/**
 * @author 杨博
 */
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":cps"))
class TestForkJoin
{
  static function sleep(time_ms:Int, handler:Void->Void):Void
  {
    Timer.delay(handler, time_ms);
  }
    static  var threadIds = [ 0, 1, 2, 3 ];

  @:cps public static function startThreads():Void
  {
    trace("Before fork");
    {
      var threadId, join = threadIds.fork().async();
      trace("Start thread #" + threadId);
      
      trace("Thread #" + threadId + " is going to sleep.");
      sleep(Std.int(Math.random() * 5000.0)).async();
      trace("Thread #" + threadId + " is waken up.");
      
      trace("Joining thread #" + threadId + "...");
      join().async();
    }
    trace("All threads are joint.");
  }
  
  public static function main()
  {
    startThreads(function() { trace("Test is done."); } );
    trace("All threads is started.");
  }
  
}