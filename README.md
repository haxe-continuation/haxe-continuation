haxe-continuation
=================

<div align="right"><a href="https://travis-ci.org/Atry/haxe-continuation"><img alt="Build Status" src="https://travis-ci.org/Atry/haxe-continuation.png?branch=haxe-3"/></a></div>

An *asynchronous functions* is a function that accept its last parameter 
as a callback function.
And **haxe-continuation** is a macro library enables you to invoke and write
asynchronous functions like synchronization functions, and automatically
transform these functions into *continuation-passing style (CPS)*. That means
you can write code looks like *multithreading* without platform
multithreading support.

## Installation

I have uploaded haxe-continuation on [haxelib](http://lib.haxe.org/p/continuation).
To install, type the following command in shell:

    haxelib install continuation

Now you can use continuation in your project:

Output to JavaScript:

    haxe -lib continuation -main Your.hx -js your-output.js

, or output to SWF:

    haxe -lib continuation -main Your.hx -swf your-output.swf

, or output to any other platform that Haxe supports.

haxe-continuation is tested with Haxe 3.1.3.

## Usage

To write a CPS function, put `@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))`
before a class, and mark the CPS functions in that class as `@:async`:

``` haxe
import com.dongxiguo.continuation.Continuation;
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))
class Sample
{

  // An asynchronous function without automatical CPS transformation.
  static function sleepOneSecond(handler:Void->Void):Void
  {
    haxe.Timer.delay(handler, 1000);
  }

  // The magic @:async transforms this function to:
  // static function asyncTest(__return:Void->Void):Void
  @:async static function asyncTest():Void
  {
    trace("Start continuation.");
    for (i in 0...10)
    {
      // Magic @await prefix to invoke an asynchronous function.
      @await sleepOneSecond();
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
```

In CPS functions, `@await` is a magic word to invoke other
async functions. When calling an asynchronous function with the `@await` prefix, you need not to explicitly pass a callback
function. Instead, the code after `@await` will be captured as the callback
function for the callee.

Another way is using `Continuation.cpsFunction` macro to write nested CPS functions:

``` haxe
import com.dongxiguo.continuation.Continuation;
class Sample2
{
  // An asynchronous function without automatically CPS transformation.
  static function sleepOneSecond(handler:Void->Void):Void
  {
    haxe.Timer.delay(handler, 1000);
  }
  public static function main() 
  {
    // This magic macro will transform function asyncTest to:
    // function asyncTest(__return:Void->Void):Void
    Continuation.cpsFunction(function asyncTest():Void
    {
      trace("Start continuation.");
      for (i in 0...10)
      {
        // Magic @await prefix to invoke an asynchronous function.
        @await sleepOneSecond();
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
```


See https://github.com/Atry/haxe-continuation/blob/haxe-3/tests/TestContinuation.hx
for more examples.

### Working with [hx-node](https://github.com/cloudshift/hx-node)

Look at https://github.com/Atry/haxe-continuation/blob/haxe-3/tests/TestNode.hx.
The example forks 5 threads, and calls Node.js's asynchronous functions in each thread.

### Generator

haxe-continuation also provides an utility to wrap CPS functions into `Iterator`s.

For example:

``` haxe
using com.dongxiguo.continuation.utils.Generator;
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))
class TestGenerator
{
  @:async
  static function intGenerator(yield:YieldFunction<Int>):Void
  {
    for (i in 1...4)
    {
      for (j in 1...(i+1))
      {
        trace('$j * $i =');
        @await yield(i * j);
        trace("-------");
      }
    }
  }
  public static function main() 
  {
    for (i in intGenerator)
    {
      trace(i);
    }
  }
}
```

The output:

    TestGenerator.hx:47: 1 * 1 =
    TestGenerator.hx:59: 1
    TestGenerator.hx:49: -------
    TestGenerator.hx:47: 1 * 2 =
    TestGenerator.hx:59: 2
    TestGenerator.hx:49: -------
    TestGenerator.hx:47: 2 * 2 =
    TestGenerator.hx:59: 4
    TestGenerator.hx:49: -------
    TestGenerator.hx:47: 1 * 3 =
    TestGenerator.hx:59: 3
    TestGenerator.hx:49: -------
    TestGenerator.hx:47: 2 * 3 =
    TestGenerator.hx:59: 6
    TestGenerator.hx:49: -------
    TestGenerator.hx:47: 3 * 3 =
    TestGenerator.hx:59: 9
    TestGenerator.hx:49: -------

### Working with [Unity](http://unity3d.com/)

You can use `@await` to create coroutine for Unity.

``` haxe
// Must compile with `haxe -lib continuation -net-lib UnityEngine.dll`

import com.dongxiguo.continuation.utils.Generator;

@:nativeGen
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))
class MyBehaviour extends unityengine.MonoBehaviour
{
  
  var texture:unityengine.Texture2D;

  @:async function run(yield:YieldFunction<Dynamic>):Void
  {
    var url = "https://avatars3.githubusercontent.com/u/601530";
    var www = new unityengine.WWW(url);
    // Wait for download to complete
    @await yield(www);
    // assign texture
    this.texture = www.texture;
  }
  
  function Start():Void
  {
    StartCoroutine(Generator.toEnumerator(run));
  }
}
```

## Links

 * [haxe-continuation API documentation](http://atry.github.io/haxe-continuation/dox/com/dongxiguo/continuation/)
 * [Test cases and examples](https://github.com/Atry/haxe-continuation/tree/haxe-3/tests)

## License

Copyright (c) 2012, 杨博 (Yang Bo)
All rights reserved.

Author: 杨博 (Yang Bo) <pop.atry@gmail.com>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of the <ORGANIZATION> nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
