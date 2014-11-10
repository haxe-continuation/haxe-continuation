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

package com.dongxiguo.continuation.utils;

/**
  An `Iterator<Element>` that yields each element lazily.
**/
@:final
class Generator<Element>
{
  var status:IteratorStatus<Element>;

  public function new(runFunction:RunFunction<Element>)
  {
    this.status = UNKNOWN(runFunction.bind(this.yield.bind(), this.end.bind()));
  }

  function end():Void
  {
    switch (this.status)
    {
      case UNKNOWN(_):
        this.status = NO_NEXT;
      default:
        throw "Must not fork threads in a generator!";
    }
  }

  function yield(nextValue:Element, handler:Void->Void):Void
  {
    switch (this.status)
    {
      case UNKNOWN(_):
        this.status = HAS_NEXT(nextValue, handler);
      default:
        throw "Must not fork threads in a generator!";
    }
  }

  public function next():Null<Element>
  {
    var oldStatus;
    var newStatus = this.status;
    do
    {
      oldStatus = newStatus;
      switch (oldStatus)
      {
        case UNKNOWN(fetchFunction):
        {
          fetchFunction();
          newStatus = this.status;
        }
        case NO_NEXT:
        {
          return null;
        }
        case HAS_NEXT(nextValue, fetchFunction):
        {
          this.status = UNKNOWN(fetchFunction);
          return nextValue;
        }
      }
    }
    while (oldStatus != newStatus);
    return throw "Expect yield or return.";
  }

  public function hasNext():Bool
  {
    var oldStatus;
    var newStatus = this.status;
    do
    {
      oldStatus = newStatus;
      switch (oldStatus)
      {
        case UNKNOWN(fetchFunction):
        {
          fetchFunction();
          newStatus = this.status;
        }
        case NO_NEXT:
        {
          return false;
        }
        case HAS_NEXT(_, _):
        {
          return true;
        }
      }
    }
    while (oldStatus != newStatus);
    return throw "Expect yield or return.";
  }

  public static function iterator<Element>(
    runFunction:RunFunction<Element>):Generator<Element>
  {
    return new Generator(runFunction);
  }

  public static function toIterable<Element>(
    runFunction:RunFunction<Element>):Iterable<Element>
  {
    return
    {
      iterator: function() { return new Generator(runFunction); },
    }
  }

  #if cs

  @:functionCode('
    var generator = new com.dongxiguo.continuation.utils.Generator<object>(runFunction);
    while (generator.hasNext())
    {
      yield return generator.next();
    }
  ')
  public static function toEnumerator(runFunction:RunFunction<Dynamic>):cs.system.collections.IEnumerator return null;

  #end
}

typedef RunFunction<Element> = YieldFunction<Element>->(Void->Void)->Void;

typedef YieldFunction<Element> = Element->(Void->Void)->Void;

private enum IteratorStatus<Element>
{
  UNKNOWN(fetchFunction:Void->Void);
  HAS_NEXT(nextValue:Element, fetchFunction:Void->Void);
  NO_NEXT;
}
