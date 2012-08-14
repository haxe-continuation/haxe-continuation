package tests;
import js.Node;
import com.dongxiguo.continuation.Continuation;
using Lambda;
/**
 * @author 杨博
 */
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("cps"))
class TestNode 
{
  /**
   * Write <code>content</code> to <code>fd</code>.
   */
  @cps static function writeAll(fd:Int, content:String):Null<NodeErr>
  {
    var totalWritten = 0;
    while (totalWritten < content.length)
    {
      var err, written =
        Node.fs.write(
          fd, content,
          totalWritten, content.length - totalWritten, null).async();
      if (err != null)
      {
        return err;
      }
      totalWritten += written;
    }
  }
  
  /**
   * Create a directory named "TestNode", and concurrently put 5 files into it.
   */
  @cps static function startTest():Void
  {
    var err = Node.fs.mkdir("TestNode").async();
    if (err != null)
    {
      trace("Node.fs.mkdir failed: " + err);
      return;
    }
    
    // Lambda.iter() forks threads for each element.
    // Fork 5 threads now!
    var fileName = ["1.txt", "2.log", "3.txt", "4.ini", "5.conf"].iter().async();
    
    // Note that some asynchronous function return more than one values!
    // It's OK in CPS functions, just like Lua.
    var err, fd = Node.fs.open("TestNode/" + fileName, "w+").async();
    if (err != null)
    {
      trace("Node.fs.open failed: " + err);
      return;
    }
    
    // Invoke another CPS function.
    var err = writeAll(fd, "Content of " + fileName).async();
    if (err != null)
    {
      trace("Node.fs.write failed: " + err);
      return;
    }
    
    var err = Node.fs.close(fd).async();
    if (err != null)
    {
      trace("Node.fs.close failed: " + err);
      return;
    }
  }

  public static function main() 
  {
    startTest(
      function():Void
      {
        trace("Test is done!");
      });
  }
  
}