package tests;

using com.dongxiguo.continuation.Continuation;

/**
 * @author 杨博
 */
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("cps"))
class TestContinuation 
{
  
  static var joiner:Counter = null;
  @cps static function forkJoin():Int
  {
    var a = [1, 2, 3, 4];
    var joiner:Counter = new Counter(a.length);
    Lambda.iter(a).async();
    trace(a);
    read(4).async();
    trace(a);
    joiner.join().async();
    if (read(1).async() == 1)
    {
      return 1;
    }
    else
    {
      return 2;
    }
  }
  
  static function good(a, b):Int
  {
    trace(a + b);
    return a + b;
  }
  
  static function xx(xxx):Int return 1

  static function read(n:Int, handler:Int -> Void):Void
  {
  }

  @cps static function write(n:Int):Int
  {
    var i = forkJoin().async();
    return n + i;
  }
  @cps static function void1(n:Int):Void
  {
    return;
  }
  
  @cps static function void2(n:Int):Void
  {
    if (false)
    {
      return hang0().async();
      Any.code.after._return_.will.be.gone();
    }
    return void1(n).async();
  }
  
  @cps static function baz(n:Int):Int
  {
    if (false)
    {
      return hang1().async();
      Any.code.after._return_.will.be.gone();
    }
    void2(3).async();
    return foo(n + 3).async();
  }
  
  static inline function hang0(handler:Void->Void):Void {}
  static inline function hang1<T>(handler:T->Void):Void {}
  
  @cps static function foo(n:Int):Int
  {
    if (true)
    {
      return hang1().async();
      Any.code.after._return_.will.be.gone();
    }
    return read(3).async() * 4 + hang1().async();
  }
  
  static function bar(n:Int, s:String, f:Float, handler:Int->Void):Void
  {
    
  }
  
  inline static function tuple2(p0, p1, handler):Void
  {
    handler(p0, p1);
  }
  
  static function doubleResult(handler:Int->String->Void):Void
  {
    
  }
  
  static function dummy():Void {}
  
  static function main() 
  {
    baz(4, function(result)
    {
      trace(result);
    });
    write(2, function(result)
    {
      good(1, 2);
    });
    Continuation.cpsFunction(
      function testFor():Void
      {
        var y = [ tuple2(0, 1).async(), 2, tuple2(3, 4).async()];
        trace(y.length);
        var x = { b: 3, d: "xxx", asdf: read(34).async() };
        for (j in [2, 4, 5])
        {
          for (i in 0...123)
          {
            var a, b = switch (read(3).async())
            {
              case 2:
                tuple2(2, x.asdf).async();
            }
          }
        }
      }
    );
    Continuation.cpsFunction(
      function testTry():Void
      {
        try
        {
          dummy();
        }
        catch (x:Array<Dynamic>)
        {
          trace("catch");
          foo(read(1).async()).async();
        }
        read(
          try
          {
            good(3, 2);
          }
          catch (x:Array<Dynamic>)
          {
            foo(read(x[0]).async()).async();
          }
          catch (x:IntHash<Dynamic>)
          {
          }
          catch (x:String)
          {
            read(3).async();
          }).async();
      }
    );
    Continuation.cpsFunction(
      function voidFunction():Void
      {
        good(3, 2);
      }
    );
    Continuation.cpsFunction(
      function intFunction():Int
      {
        return good(3, 2);
      }
    );
    
    Continuation.cpsFunction(function functionOfFunction():(Int->Void)->Void
    {
      return function():Int { return 1; }.cpsFunction();
    });
    
    Continuation.cpsFunction(function myFunction():Int
    {
      var ff = functionOfFunction().async();
      trace(ff);
      return ff().async();
      //return f().async();
    });
    Continuation.cpsFunction(function multiVar()
    {
      var c = 1, a, b = doubleResult().async();
      return tuple2(c, a).async();
    });
    var asyncDo = callback(read, 3);
    Continuation.cpsFunction(function myFunction():Int
    {
      var xxx = bar(234, "foo", 34.5).async();
      var result = read(2).async();
      
      var z = asyncDo().async() + 2 * bar(asyncDo().async(), "foo", 34.5).async() + read(read(2).async()).async();
      var x = good(asyncDo().async(), bar(asyncDo().async(), "foo", 34.5).async());
      var c = asyncDo().async();
      var a = 1 + 2 * x + z;
      var b = 3 + 4 + c, d = a +  asyncDo().async(), e = asyncDo().async() * asyncDo().async();
      return asyncDo().async() + a + b * e + d - c;
    });
    
    Continuation.cpsFunction(function myFunction2():Int
    {
      good(3, 4);
      return 1 + myFunction().async();
    });
    Continuation.cpsFunction(function myFunction3():Int
    {
      good(4, 5);
      myFunction().async();
      myFunction().async();
      return read(3).async();
    });
    Continuation.cpsFunction(function myFunction():Int
    {
      return good(1, good(good(2, 3), good(4, 5)));
    });
    Continuation.cpsFunction(function myFunction():Int
    {
      return return 1;
      return 2;
    });
    Continuation.cpsFunction(function myFunction():Int
    {
      return asyncDo().async();
      return 2;
    });
    Continuation.cpsFunction(function myFunction():Int
    {
      if (asyncDo().async() == 0)
      {
        return 44;
      }
      else
      {
        return asyncDo().async();
      }
        
      return (if (asyncDo().async() == 0)
        {
          return 2;
        }
        else if (asyncDo().async() == 1)
        {
          asyncDo().async();
        }
        else
        {
          43;
        }) + (if (asyncDo().async() == 0) { asyncDo().async(); } else { 1; } );
    });
    
    Continuation.cpsFunction(function testWhile():Int
    {
      while (asyncDo().async() > 1)
      {
        asyncDo().async();
        if (true) break;
        if (asyncDo().async() <= 4) continue;
        asyncDo().async();
      }
      return 1;
    });
    Continuation.cpsFunction(function testDoWhile():Void
    {
      do
      {
        
      }
      while (true);
    });
  }
  
  
}
typedef A = Int;