package tests;

using com.dongxiguo.continuation.Continuation;
#if macro
import haxe.macro.Expr;
#end
/**
 * @author 杨博
 */
#if !macro
  @:build(com.dongxiguo.continuation.Continuation.cpsByMeta("cps"))
#end
class TestContinuation 
{
  static function good(a, b):Int
  {
    trace(a + b);
    return a + b;
  }
  
  //@:extern static inline var async:Dynamic = null;
  
  static function xx(xxx):Int return 1
  
  @:macro static function macroThrow(e:Expr):Expr
  {
    trace("xxx");
    throw "xxx";
    return null;
  }
  

  static function read(n:Int, handler:Int -> Void):Void
  {
    
  }

  @cps static function write(n:Int):Int
  {
    return n + 1;
  }
  
  /*
  // This does not work, and I don't know why.
  @cps static function foo(n:Int):Int
  {
    return async(Main.read, 3) * 4;
  }
  */
  
  static function foo(n:Int, h:Int->Void):Void h.cps(
  {
    return async(read, 3) * 4;
  })
  
  
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
    write(2, function(result)
    {
      good(1, 2);
    });
    Continuation.cpsFunction(
      function testFor():Void
      {
        var y = [ async(tuple2, 0, 1), 2, async(tuple2, 3, 4)];
        trace(y.length);
        var x = { b: 3, d: "xxx", asdf: async(read, 34) };
        for (j in [2, 4, 5])
        {
          for (i in 0...123)
          {
            var a, b = switch (async(read, 3))
            {
              case 2:
                async(tuple2, 2, x.asdf);
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
        catch (x:Float)
        {
          trace("catch");
          async(foo, async(read, 1));
        }
        async(read,
          try
          {
            good(3, 2);
          }
          catch (x:Int)
          {
            async(foo, async(read, x));
          }
          catch (x:Float)
          {
          }
          catch (x:String)
          {
            async(read, 3);
          });
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
      return Continuation.cpsFunction(function():Int { return 1; } );
    });
    
    Continuation.cpsFunction(function myFunction():Int
    {
      return async(async(functionOfFunction));
    });
    Continuation.cpsFunction(function multiVar()
    {
      var c = 1, a, b = async(doubleResult);
      return async(tuple2, c, a);
    });
    var asyncDo = callback(read, 3);
    Continuation.cpsFunction(function myFunction():Int
    {
      var xxx = async(bar, 234, "foo", 34.5);
      var result = async(read, 2);
      
      var z = async(asyncDo) + 2 * async(bar, async(asyncDo), "foo", 34.5) + async(read, async(read, 2));
      var x = good(async(asyncDo), async(bar, async(asyncDo), "foo", 34.5));
      var c = async(asyncDo);
      var a = 1 + 2 * x + z;
      var b = 3 + 4 + c, d = a +  async(asyncDo), e = async(asyncDo) * async(asyncDo);
      return async(asyncDo) + a + b * e + d - c;
    });
    
    Continuation.cpsFunction(function myFunction2():Int
    {
      good(3, 4);
      return 1 + async(myFunction);
    });
    Continuation.cpsFunction(function myFunction3():Int
    {
      good(4, 5);
      async(myFunction);
      async(myFunction);
      return async(read, 3);
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
      return async(asyncDo);
      return 2;
    });
    Continuation.cpsFunction(function myFunction():Int
    {
      if (async(asyncDo) == 0)
      {
        return 44;
      }
      else
      {
        return async(asyncDo);
      }
        
      return (if (async(asyncDo) == 0)
        {
          return 2;
        }
        else if (async(asyncDo) == 1)
        {
          async(asyncDo);
        }
        else
        {
          43;
        }) + (if (async(asyncDo) == 0) { async(asyncDo); } else { 1; } );
    });
    
    Continuation.cpsFunction(function testWhile():Int
    {
      while (async(asyncDo) > 1)
      {
        async(asyncDo);
        if (true) break;
        if (async(asyncDo) <= 4) continue;
        async(asyncDo);
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