package com.dongxiguo.continuation.utils;

class StateMachine<Event>
{

  public function new() {}

  var nextEventFunction:Null<Event->Void> = null;

  public inline function waitForNextEvent(f:Event->Void):Void
  {
    if (nextEventFunction == null)
    {
      nextEventFunction = f;
    }
    else
    {
      throw "Unable to wait for the next event twice!";
    }
  }

  public inline function post(event:Event):Void
  {
    var f = nextEventFunction;
    nextEventFunction = null;
    f(event);
  }

}