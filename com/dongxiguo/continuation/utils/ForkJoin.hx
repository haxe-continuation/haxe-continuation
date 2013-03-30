package com.dongxiguo.continuation.utils;

/**
 * @author 杨博
 */
class ForkJoin
{

  public static function startCollectors<Identifier, Result>(collectorIdentifiers: Iterable<Identifier>, handler:Identifier->CollectFunction<Result>->Void):Void
  {
    var counter = 1;
    var results:Array<Result> = [];
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
  
  public static function fork<Identifier>(threadIdentifiers: Iterable<Identifier>, handler:Identifier->JoinFunction->Void):Void
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

typedef JoinFunction = (Void->Void)->Void;

typedef CollectFunction<Result> = Result->(Array<Result>->Void)->Void;
