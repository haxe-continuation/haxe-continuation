package com.dongxiguo.continuation.utils;

/**
 * ...
 * @author 杨博
 */
class ForkJoin
{

  public static function fork<T>(threadIdentifiers: Iterable<T>, handler:T->JoinFunction->Void):Void
  {
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
          throw "Cannot join twice!";
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

typedef JoinFunction = (Void->Void)->Void;
