package tests;

import com.dongxiguo.continuation.Continuation;

/**
 * @author 杨博
 */
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":cps"))
class Test1
{
  //@:cps static function write(n:Int):Int
  //{
    //return 1 + n;
  //}
//

  public static function aa(a:Array<Int>, f:Void->Void):Void
  {
    
  }

  static var trace = null;
  @:cps static function forkJoin():Int
  {
    //trace(2);
    //asdfsa;
    //var a = [1];
    //var joiner:Counter = new Counter(a.length);
    //Test1.aa(a, null);
    //var i = 
    Lambda.iter([3]).async();
    //trace(i);
    //return 1;
    //read(4).async();
    //trace(a);
    //joiner.join().async();
    //if (write(1).async() == 1)
    //{
      //return 1;
    //}
    //else
    //{
      //return 2;
    //}
  }
  
  static function main()
  {
    
  }
}