// Copyright (c) 2012,2013, 杨博 (Yang Bo)
// All rights reserved.
//
// Author: 杨博 (Yang Bo) <pop.atry@gmail.com>
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// * Neither the name of the <ORGANIZATION> nor the names of its contributors
//   may be used to endorse or promote products derived from this software
//   without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

package tests;

import haxe.ds.IntMap;
import haxe.ds.Vector;

using com.dongxiguo.continuation.Continuation;

/**
 * @author 杨博
 */
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":cps"))
class TestContinuation
{
  @:cps static function ifNull(?p:Int)
  {
    if (p == null)
    {
      p = 1;
    }
    trace(p);
  }

  @:cps static function maybeTuple():Void
  {
    if (Math.random() < 0.5)
    {
      @await forkJoin();
    }
    else
    {
      @await tuple2(1, 2);
    }
  }

  @:cps static function forkJoin():Int
  {
    var a:Array<Int> = [1, 2, 3, 4];
    var joiner = new Counter(a.length);
    @await Lambda.iter(a);
    trace(a);
    @await read(4);
    trace(a);
    @await joiner.join();
    if ((@await read(1)) == 1)
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

  static function xx(xxx):Int { return 1; }

  static function read(n:Int, handler:Int -> Void):Void
  {
  }

  @:cps static function write(n:Int):Int
  {
    @await forkJoin();
    return n + 1;
  }
  @:cps static function void1(n:Int):Void
  {
    return;
  }

  @:cps static function void2(n:Int):Void
  {
    if (false)
    {
      return @await hang0();
      Any.code.after._return_.will.be.gone();
    }
    return @await void1(n);
  }

  @:cps static function baz(n:Int):Int
  {
    if (false)
    {
      return @await hang1();
      Any.code.after._return_.will.be.gone();
    }
    @await void2(3);
    return @await foo(n + 3);
  }

  static inline function hang0(handler:Void->Void):Void {}
  static inline function hang1<T>(handler:T->Void):Void {}

  @:cps static function foo(n:Int):Int
  {
    if (true)
    {
      return @await hang1();
      Any.code.after._return_.will.be.gone();
    }
    return (@await read(3)) * 4 + (@await hang1());
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
        var y = [ @await tuple2(0, 1), 2, @await tuple2(3, 4)];
        trace(y.length);
        var x = { b: 3, d: "xxx", asdf: @await read(34) };
        for (j in [2, 4, 5])
        {
          for (i in 0...123)
          {
            var a, b = switch (@await read(3))
            {
              case 2:
                @await tuple2(2, 3);
              default:
                @await tuple2(1, 5);
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
          @await foo(@await read(1));
        }
        @await read(
          try
          {
            good(3, 2);
          }
          catch (x:Array<Dynamic>)
          {
            @await foo(@await read(x[0]));
          }
          catch (x:IntMap<Dynamic>)
          {
          }
          catch (x:String)
          {
            @await read(3);
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
      var ff = @await functionOfFunction();
      trace(ff);
      return @await ff();
    });
    Continuation.cpsFunction(function multiVar()
    {
      var c = 1, a, b = @await doubleResult();
      return @await tuple2(c, a);
    });
    var asyncDo = read.bind(3);
    Continuation.cpsFunction(function myFunction():Int
    {
      var xxx = @await bar(234, "foo", 34.5);
      var result = @await read(2);

      var z = (@await asyncDo()) + 2 * (@await bar(@await asyncDo(), "foo", 34.5)) + @await read(@await read(2));
      var x = good(@await asyncDo(), @await bar(@await asyncDo(), "foo", 34.5));
      var c = @await asyncDo();
      var a = 1 + 2 * x + z;
      var b = 3 + 4 + c, d = a + @await asyncDo(), e = (@await asyncDo()) * @await asyncDo();
      return (@await asyncDo()) + a + b * e + d - c;
    });

    Continuation.cpsFunction(function myFunction2():Int
    {
      good(3, 4);
      return 1 + @await myFunction();
    });
    Continuation.cpsFunction(function myFunction3():Int
    {
      good(4, 5);
      @await myFunction();
      @await myFunction();
      return @await read(3);
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
      return @await asyncDo();
      return 2;
    });
    Continuation.cpsFunction(function myFunction33():Int
    {
      if ((@await asyncDo()) == 0)
      {
        return 44;
      }
      else
      {
        return @await asyncDo();
      }
      var a = ((@await asyncDo()) == 0 ? 1 : 2);
      return (if ((@await asyncDo()) == 0)
        {
          return 2;
        }
        else if ((@await asyncDo()) == 1)
        {
          @await asyncDo();
        }
        else
        {
          43;
        }) + (if ((@await asyncDo()) == 0) { @await asyncDo(); } else { 1; } );
    });

    Continuation.cpsFunction(function testWhile():Int
    {
      while ((@await asyncDo()) > 1)
      {
        @await asyncDo();
        if (true) break;
        if ((@await asyncDo()) <= 4) continue;
        @await asyncDo();
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

    Continuation.cpsFunction(function testVectorForLoop():Void
    {
      var v = haxe.ds.Vector.fromArrayCopy([1, 2, 3]);
      for (e in v)
      {
        trace(@await asyncDo() * e);
      }
      var a1 = [ for (e in v) e * 2 ];
      var a2 = [ for (e in v) if (e < 2) e * 2 ];
      var a3 = [ for (e in v) { if (e < 2) e * 2; } ];
    });
  }


}
typedef A = Int;
