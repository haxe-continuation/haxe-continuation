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

  @:cps public static function startWorkers(parentId:Int, childrenIds:Array<Int>):Array<Int>
  {
    trace("Before fork");
    var result =
    {
      var threadId, collect = childrenIds.startCollectors().async();
      trace("Start thread #" + threadId);
      
      trace("Thread #" + parentId + "." + threadId + " is going to sleep.");
      sleep(Std.int(Math.random() * 5000.0)).async();
      trace("Thread #" + parentId + "." + threadId + " is waken up.");
      
      trace("Collect data from thread #" + parentId + "." + threadId + "...");
      collect(threadId * parentId).async();
    }
    trace("All sub-threads of #" + parentId + " are joint.");
    return result;
  }
  
  @:cps public static function startManagers():Void
  {
    var threadIds = [ 0, 1, 2, 3 ];
    trace("Before fork");
    {
      var threadId, join = threadIds.fork().async();
      trace("Start thread #" + threadId);
      
      trace("Data from sub-threads of #" + threadId + ": " + startWorkers(threadId, [0, 1, 2, 3, 4, 5]).async());
      
      trace("Joining thread #" + threadId + "...");
      join().async();
    }
    trace("All threads are joint.");
  }

  public static function main()
  {
    startManagers(function() { trace("Test is done."); } );
    trace("All threads are started.");
  }
  
}