haxe-continuation
=================

Enable continuation in Haxe.

## Installation

I have upload **haxe-continuation** to haxelib. To install, type following
command in shell:

    haxelib install continuation

Now you can use continuation in your code:

    haxe -lib continuation -main Your.hx -js your-output.js

## Usage

If a function's last parameter is a callback function, it is an
*asynchronous function*. **haxe-continuation** enable you to write an
asynchronous function in *continuation-passing style (CPS)*.

You can use `Continuation.cpsFunction` to write such a CPS asynchronous
function. In `Continuation.cpsFunction`, `async` is a keyword to invoke other
async functions. With a `.async()` postfix, you need not to explicitly pass a callback
function. Instead, the code after `async` will be captured as the callback
function used by the callee.

    import com.dongxiguo.continuation.Continuation;
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

Another way to write a CPS function is put `@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("cps"))`
before a class, and mark the CPS functions in that class as `@cps`:

    import com.dongxiguo.continuation.Continuation;
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

See https://github.com/Atry/haxe-continuation/blob/master/tests/TestContinuation.hx
for more examples.

### Work with [hx-node](https://github.com/cloudshift/hx-node)

Look at https://github.com/Atry/haxe-continuation/blob/master/tests/TestNode.hx, which create a directory named *TestNode*, and concurrently put 5 files into it.

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
