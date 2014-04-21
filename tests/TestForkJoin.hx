// Copyright (c) 2013, 杨博 (Yang Bo)
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

  /** Start 4 worker threads. Every worker is a collector. */
  @:cps public static function startWorkerThreads(parentId:Int, childrenIds:Array<Int>):Array<Int>
  {
    trace("Before fork");
    var threadId, collect = ForkJoin.startCollectors(childrenIds).async();
    var result = collect(
    {
      trace("Start sub-thread #" + parentId + "." + threadId);

      trace("Sub-thread #" + parentId + "." + threadId + " is going to sleep.");
      sleep(Std.int(Math.random() * 5000.0)).async();
      trace("Sub-thread #" + parentId + "." + threadId + " is waken up.");

      trace("Collecting data from sub-thread #" + parentId + "." + threadId + "...");

      threadId * parentId;
    }).async();
    trace("All sub-threads of #" + parentId + " are joined.");
    return result;
  }

  /** Start 4 manager threads. Every manager manages 6 workers. */
  @:cps public static function startManagerThreads():Void
  {
    var threadIds = [ 0, 1, 2, 3 ];
    trace("Before fork");
    {
      var threadId, join = ForkJoin.startThreads(threadIds).async();
      trace("Start thread #" + threadId);

      trace("Data from sub-threads of #" + threadId + ": " + Std.string(startWorkerThreads(threadId, [0, 1, 2, 3, 4, 5]).async()));

      trace("Joining thread #" + threadId + "...");
      join().async();
    }
    trace("All threads are joined.");
  }

  public static function main()
  {
    startManagerThreads(function() { trace("All tests are done."); } );
    trace("All threads are started.");
  }

}
