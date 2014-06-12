// Copyright (c) 2013-2014, 杨博 (Yang Bo)
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

package com.dongxiguo.continuation.utils;

@:final
class ForkJoin
{
  /**
    Hangs up the current thread.

    Usage: `return ForkJoin.hang().async();`
  **/
  @:noUsing
  @:extern
  public static inline function hang(handler:Dynamic):Void
  {
  }

  /**
    Forks the current thread.

    Usage:
    <pre>`if (ForkJoin.fork().async())
    {
      // Forked thread #1
    }
    else
    {
      // Forked thread #2
    }`</pre>
  **/
  @:noUsing
  @:extern
  public static inline function fork(handler:Bool->Void):Void
  {
    handler(true);
    handler(false);
  }

  /**
    Like `ForkJoin.startThreads`, but returns a `CollectFunction` instead of `JoinFunction`.
   **/
  @:noUsing
  public static function startCollectors<Identifier, Result>(
    collectorIdentifiers: Iterable<Identifier>,
    handler:Identifier->CollectFunction<Result>->Void):Void
  {
    if (Lambda.empty(collectorIdentifiers))
    {
      throw "collectorIdentifiers must not be empty!";
    }
    var counter = 1;
    var results:Array<Null<Result>> = [];
    var quickCollectHandler = null;
    var i = 0;
    for (id in collectorIdentifiers)
    {
      counter++;
      var index = i;
      handler(id, function(result:Result, collectHandler:Array<Result>->Void)
      {
        if (results[index] != null)
        {
          throw "Cannot collect twice in one collector!";
        }
        else
        {
          results[index] = result;
          if (--counter == 0)
          {
            collectHandler(results);
          }
          else
          {
            quickCollectHandler = collectHandler;
          }
        }
      });
      i++;
    }
    if (--counter == 0)
    {
      quickCollectHandler(results);
    }

  }

  /**
    Forks threads for every element in `threadIdentifiers`.
    @param handler The callback function invoked for each element in `threadIdentifiers`.
    The `handler` can receive two parameters:
    the element in `threadIdentifiers` and the `JoinFunction`.
   **/
  @:noUsing
  public static function startThreads<Identifier>(
    threadIdentifiers: Iterable<Identifier>,
    handler:Identifier->JoinFunction->Void):Void
  {
    if (Lambda.empty(threadIdentifiers))
    {
      throw "threadIdentifiers must not be empty!";
    }
    var counter = 1;
    var quickJoinHandler = null;
    for (id in threadIdentifiers)
    {
      counter++;
      var isJoined = false;
      handler(id, function(joinHandler)
      {
        if (isJoined)
        {
          throw "Cannot join twice in one thread!";
        }
        else
        {
          isJoined = true;
          if (--counter == 0)
          {
            joinHandler();
          }
          else
          {
            quickJoinHandler = joinHandler;
          }
        }
      });
    }
    if (--counter == 0)
    {
      quickJoinHandler();
    }
  }

}

/**
  The function should be invoke when the thread exit. The execution continues
  only if all child threads have invoked their `JoinFunction`.
**/
typedef JoinFunction = (Void->Void)->Void;

/**
  Like `JoinFunction`,
  but will collect all results from each child threads into an array.
**/
typedef CollectFunction<Result> = Result->(Array<Result>->Void)->Void;
