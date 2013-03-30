// Copyright (c) 2012, 杨博 (Yang Bo)
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

package com.dongxiguo.continuation;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
#end
using Lambda;

/**
 * @author 杨博 <pop.atry@gmail.com>
 */
class Continuation 
{
  /**
   * Wrap a function to CPS function.
   *
   * In wrapped function, you can use <code>.async()</code> postfix to invoke other asynchronous functions.
   */
  @:macro public static function cpsFunction(expr:Expr):Expr
  {
    switch (expr.expr)
    {
      case EFunction(name, f):
      {
        var originExpr = f.expr;
        return
        {
          pos: expr.pos,
          expr: EFunction(
            name,
            {
              ret: TPath(
                {
                  sub: null,
                  params: [],
                  pack: [],
                  name: "Void"
                }),
              params: f.params,
              args: f.args.concat(
                [
                  {
                    name: "__return",
                    opt: false,
                    value: null,
                    type: f.ret == null ? null : TFunction(
                      [ f.ret ],
                      TPath(
                        {
                          sub: null,
                          params: [],
                          pack: [],
                          name: "Void"
                        }))
                  }
                ]),
              expr:
                macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
                  $originExpr,
                  /*inline*/ function(){}),
            })
        };
      }
      default:
      {
        throw "CPS.cpsFunction expect a function as parameter.";
      }
    }
  }
  
  /**
   * When you add <code>@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("metaName"))</code> in front of a class, any method with same metadata name from <code>metaName</code> in that class will be transfromed to CPS function.
   *
   * In these methods, you can use <code>.async()</code> postfix to invoke other asynchronous functions.
   */
  @:noUsing @:macro public static function cpsByMeta(metaName:String):Array<Field>
  {
    var bf = Context.getBuildFields();
    for (field in bf)
    {
      switch (field.kind)
      {
        case FFun(f):
        {
          for (m in field.meta)
          {
            if (m.name == metaName)
            {
              f.args = f.args.concat(
                [
                  {
                    name: "__return",
                    opt: false,
                    value: null,
                    type: f.ret == null ? null : TFunction(
                      [ f.ret ],
                      TPath(
                        {
                          sub: null,
                          params: [],
                          pack: [],
                          name: "Void"
                        }))
                  }
                ]);
              f.ret = TPath(
                {
                  sub: null,
                  params: [],
                  pack: [],
                  name: "Void"
                });
              var originExpr = f.expr;
              f.expr =
                macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($originExpr, /*inline*/ function(){});
              break;
            }
          }
        }
        default:
        {
          continue;
        }
      }
    }
    return bf;
  }

}

/**
 * For internal use only. Don't access it immediately.
 * @private
 */
class ContinuationDetail
{
  #if macro
  static var seed:Int = 0;
  
  static function unpack(exprs: Array<Expr>, pos: Position):Expr
  {
    if (exprs.length != 1)
    {
      Context.error("Expect one return value, but there is " + exprs.length +
      " return value.", pos);
    }
    return exprs[0];
  }

  static function evaluateCondition(
    pos:Position,
    econd:Expr,
    eif:Expr,
    eelse:Null<Expr>,
    completeHandler:Expr,
    additionExpr:Expr):Expr
  {
    if (eelse == null)
    {
      return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($econd, /*inline*/ function(econdResult)
      {
        if (econdResult)
        {
          com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($eif, $completeHandler);
        }
        else
        {
          com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr);
        }
      });
    }
    else
    {
      return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($econd, /*inline*/ function(econdResult)
      {
        if (econdResult)
        {
          com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($eif, $completeHandler);
        }
        else
        {
          com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($eelse, $completeHandler);
        }
      });
    }
  }
  #end
  
  @:macro @:noUsing public static function call(parameters:Array<Expr>):Expr
  {
    var f = parameters.pop();
    return 
    {
      pos: Context.currentPos(),
      expr: ECall(f, parameters),
    }
  }
  
  @:macro @:noUsing public static function apply(f:Expr, prefixParameters:Expr, moreParameters:Array<Expr>):Expr
  {
    switch (prefixParameters.expr)
    {
      case EArrayDecl(values):
      {
        var parameters = values.length == 0 ? moreParameters : values.concat(moreParameters);
        switch (f.expr)
        {
          case EFunction(_, { expr:e, args: [], params: [], ret:r } ) if (r == null):
          {
            return {
              pos: f.pos,
              expr: EBlock(parameters.concat([e])),
            }
          }
          default:
          {
            return
            {
              expr: ECall(f, parameters),
              pos: f.pos,
            }
          }
        }
      }
      default:
      {
        return Context.error("Expected EArrayDecl", prefixParameters.pos);
      }
    }
  }
  
  @:noUsing @:macro public static function evaluate(origin:Expr, completeHandler:Expr, additionParameters:Array<Expr>):Expr
  {
    var additionExpr =
    {
      pos: origin.pos,
      expr: EArrayDecl(additionParameters),
    }
    switch (origin.expr)
    {
      case EWhile(econd, e, normalWhile):
      {
        var testFunctionName = "__test_" + seed++;
        var testFunctionIdent = { pos: origin.pos, expr: EConst(CIdent(testFunctionName)), };
        var body =
          macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, $testFunctionIdent);
        var defineTest =
          macro /*inline*/ function $testFunctionName()
          {
            /*inline*/ function __break() { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr); }
            function __continue()
            {
              com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
                $econd,
                function(econd) { return econd ? $body : __break(); } );
            }
            __continue();
          }
        if (normalWhile)
        {
          return macro
          {
            $defineTest;
            $testFunctionIdent();
          }
        }
        else
        {
          return macro
          {
            $defineTest;
            $body;
          }
        }
      }
      case EVars(originVars):
      {
        if (originVars.length == 0)
        {
          return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr);
        }
        var v = originVars.pop();
        var uninitializedVars = [];
        while (v.expr == null)
        {
          uninitializedVars.unshift(v);
          if (originVars.length == 0)
          {
            return macro { $origin; com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr); }
          }
          v = originVars.pop();
        }
        var result = macro { $origin; com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr); }
        while (true)
        {
          var e = v.expr;
          var functionArgs = [ { name: v.name, opt: false, type:v.type, value: null, } ];
          function prependVars(oldHandler:Expr):Expr
          {
            var oldResult = result;
            var f =
            {
              pos: origin.pos,
              expr: EFunction(
                null,
                {
                  params: [],
                  args: functionArgs,
                  ret: null,
                  expr: oldResult,
                }),
            }
            return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, $f);
          }
          while (true)
          {
            if (originVars.length == 0)
            {
              return prependVars(result);
            }
            v = originVars.pop();
            if (v.expr == null)
            {
              functionArgs.unshift( { name: v.name, opt: false, type:v.type, value: null, } );
            }
            else
            {
              result = prependVars(result);
              break;
            }
          }
        }
      }
      case EUntyped(e):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EUntyped(macro e),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
          $e,
          /*inline*/ function(e)
          {
            com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr);
          } );
      }
      case EUnop(op, postFix, e):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EUnop(op, postFix, macro e),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, /*inline*/ function(e) { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr); } );
      }
      #if !haxe3
      case EType(e, field):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EType(macro e, field),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, /*inline*/ function(e) { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr); } );
      }
      #end
      case ETry(e, catches):
      {
        var tryExpr = {
          expr: ETry(
            macro { result = $e; noException = true; },
            Lambda.array(Lambda.map(catches, function(c)
            {
              var caseExpr = c.expr;
              return { type:c.type, name: c.name, expr: macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($caseExpr, $completeHandler), };
            }))),
          pos: origin.pos,
        };
        return macro
        {
          var result;
          var noException = false;
          $tryExpr;
          if (noException)
          {
            com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, result);
          }
        }
      }
      case EThrow(e):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EThrow(macro e),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, /*inline*/ function(e) { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr); } );
      }
      case ETernary(econd, eif, eelse):
      {
        return evaluateCondition(origin.pos, econd, eif, eelse, completeHandler, additionExpr);
      }
      case ESwitch(e, cases, edef):
      {
        var transformedCases =
        [
          for (c in cases)
          {
            var caseBody = c.expr;
            {
              values: c.values,
              #if haxe_211
              guard: c.guard,
              #end
              expr: macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($caseBody, $completeHandler),
            };
          }
        ];
        var transformedDefault = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($edef, $completeHandler);
        var innerExpr =
        {
          pos: origin.pos,
          expr: ESwitch(macro e, transformedCases, transformedDefault),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
          $e, 
          /*inline*/ function(e)
          {
            $innerExpr;
          });
      }
      case EReturn(returnExpr):
      {
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($returnExpr, __return);
      }
      case EParenthesis(e):
      {
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, $completeHandler);
      }
      case EObjectDecl(originFields):
      {
        var parameterPrefix = "__fieldValue_" + seed++ + "_";
        var transformedFields =
        [
          for (field in originFields)
          {
            {
              field: field.field,
              expr:
              {
                pos: field.expr.pos,
                expr: EConst(CIdent(parameterPrefix + field.field)),
              },
            };
          }
        ];
        var innerExpr =
        {
          pos: origin.pos,
          expr: EObjectDecl(transformedFields),
        }
        var result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr);
        var i = originFields.length - 1;
        while (i >= 0)
        {
          var field = originFields[i];
          var valueExpr = field.expr;
          var oldInnerExpr = result;
          var parameterName = parameterPrefix + field.field;
          var functionExpr =
          {
            pos: origin.pos,
            expr: EFunction(
              null,
              {
                args:
                [
                  {
                  	name: parameterName,
                    opt: false,
                    type: null,
                  }
                ],
                ret: null,
                expr: oldInnerExpr,
                params: [],
              })
          }
          result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($valueExpr, $functionExpr);
          i--;
        }
        return result;
      }
      case ENew(t, originValues):
      {
        var parameterPrefix = "__constructorParameter_" + seed++ + "_";
        var transformedParameters =
        [
          for (i in 0...originValues.length)
          {
            {
              pos: originValues[i].pos,
              expr: EConst(CIdent(parameterPrefix + i)),
            };
          }
        ];
        var innerExpr =
        {
          pos: origin.pos,
          expr: ENew(t, transformedParameters),
        }
        var result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr);
        var i = originValues.length - 1;
        while (i >= 0)
        {
          var parameterExpr = originValues[i];
          var oldResult = result;
          var parameterName = parameterPrefix + i;
          var functionExpr =
          {
            pos: origin.pos,
            expr: EFunction(
              null,
              {
                args:
                [
                  {
                  	name: parameterName,
                    opt: false,
                    type: null,
                  }
                ],
                ret: null,
                expr: oldResult,
                params: [],
              })
          }
          result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($parameterExpr, $functionExpr);
          i--;
        }
        return result;
      }
      case EIf(econd, eif, eelse):
      {
        return evaluateCondition(origin.pos, econd, eif, eelse, completeHandler, additionExpr);
      }
      case EFor({ expr: EIn({expr: EConst(CIdent(elementName))}, e2)}, body):
      {  
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e2, function(collection)
        {
          var __iterator = null;
          {
            /*inline*/ function setIterator<T>(
              iterable:Iterable<T> = null,
              iterator:Iterator<T> = null):Void
            {
              __iterator = iterable != null ? iterable.iterator() : iterator;
            }
            setIterator(collection);
          }
          com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
            while (__iterator.hasNext())
            {
              var $elementName = __iterator.next();
              $body;
            },
            $completeHandler);
        });
      }
      case EField(e, field):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EField(macro e, field),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, /*inline*/ function(e) { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr); } );
      }
      case EDisplay(e, isCall):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EDisplay(macro e, isCall),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, /*inline*/ function(e) { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr); } );
      }
      case EContinue:
      {
        return macro __continue();
      }
      case ECheckType(e, t):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: ECheckType(macro e, t),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, /*inline*/ function(e) { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr); } );
      }
      case ECast(e, t):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: ECast(macro e, t),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($e, /*inline*/ function(e) { com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr); } );
      }
      case ECall( { expr: EField( { expr: ECall(callee, originParams) }, "async") }, []):
      {
        var parameterPrefix = "__asyncCallParameter_" + seed++ + "_";
        trace(callee);
        var evaluateParameters = [callee, macro com.dongxiguo.continuation.Continuation.ContinuationDetail.call];
        for (i in 0...originParams.length)
        {
          evaluateParameters.push(
          {
            pos: originParams[i].pos,
            expr: EConst(CIdent(parameterPrefix + i)),
          });
        }
        evaluateParameters.push(
        {
          expr: ECall(macro $completeHandler.bind, additionParameters),
          pos: origin.pos,
        });
        var result = 
        {
          pos: origin.pos,
          expr: ECall(
            macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate,
            evaluateParameters),
        }
        var i = originParams.length - 1;
        while (i >= 0)
        {
          var parameterExpr = originParams[i];
          var oldResult = result;
          var parameterName = parameterPrefix + i;
          var functionExpr =
          {
            pos: origin.pos,
            expr: EFunction(
              null,
              {
                args:
                [
                  {
                  	name: parameterName,
                    opt: false,
                    type: null,
                  }
                ],
                ret: null,
                expr: oldResult,
                params: [],
              })
          }
          result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($parameterExpr, $functionExpr);
          i--;
        }
        return result;
      }
      case ECall(callee, parameters):
      {
        var parameterPrefix = "__callParameter_" + seed++ + "_";
        var transformedParameters =
        [
          for (i in 0...parameters.length)
          {
            {
              pos: origin.pos,
              expr: EConst(CIdent(parameterPrefix + i)),
            };
          }
        ];
        var innerExpr =
        {
          pos: origin.pos,
          expr: ECall(macro callee, transformedParameters),
        }
        var result =
          macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
            $callee,
            /*inline*/ function(callee)
            {
              com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr);
            });
        var i = parameters.length - 1;
        while (i >= 0)
        {
          var parameterExpr = parameters[i];
          var oldInnerExpr = result;
          var parameterName = parameterPrefix + i;
          var functionExpr =
          {
            pos: origin.pos,
            expr: EFunction(
              null,
              {
                args:
                [
                  {
                  	name: parameterName,
                    opt: false,
                    type: null,
                  }
                ],
                ret: null,
                expr: oldInnerExpr,
                params: [],
              })
          }
          result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($parameterExpr, $functionExpr);
          i--;
        }
        return result;
      }
      case EBreak:
      {
        return macro __break();
      }
      case EBlock(exprs):
      {
        if (exprs.length == 0)
        {
          return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr);
        }
        var lastExpr = exprs.pop();
        var result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($lastExpr, $completeHandler);
        var i = exprs.length - 1;
        while (i >= 0)
        {
          var e = exprs[i];
          var oldResult = result;
          result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
            $e,
            function() { $oldResult; } );
          i--;
        }
        return result;
      }
      case EBinop(op, e1, e2):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EBinop(op, macro e1, macro e2),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
          $e1,
          /*inline*/ function(e1)
          {
            com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
              $e2,
              /*inline*/ function(e2)
              {
                com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr);
              });
          });
      }
      case EArrayDecl([ { expr: EFor({ expr: EIn({expr: EConst(CIdent(elementName))}, collection)}, { expr: EIf(filter, body, eelse) }) } ]) if (eelse == null):
      {
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($collection, function(collection)
        {
          var __iterator = null;
          {
            /*inline*/ function setIterator<T>(
              iterable:Iterable<T> = null,
              iterator:Iterator<T> = null):Void
            {
              __iterator = iterable != null ? iterable.iterator() : iterator;
            }
            setIterator(collection);
          }
          var result = [];
          com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
            {
              while (__iterator.hasNext())
              {
                var $elementName = __iterator.next();
                if ($filter)
                {
                  result.push($body);
                }
              }
              result;
            },
            $completeHandler);
        });
      }
      case EArrayDecl([ { expr: EFor({ expr: EIn({expr: EConst(CIdent(elementName))}, collection)}, body) } ]):
      {
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($collection, function(collection)
        {
          var __iterator = null;
          {
            /*inline*/ function setIterator<T>(
              iterable:Iterable<T> = null,
              iterator:Iterator<T> = null):Void
            {
              __iterator = iterable != null ? iterable.iterator() : iterator;
            }
            setIterator(collection);
          }
          var result = [];
          com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
            {
              while (__iterator.hasNext())
              {
                var $elementName = __iterator.next();
                result.push($body);
              }
              result;
            },
            $completeHandler);
        });
      }
      case EArrayDecl(originValues):
      {
        var parameterPrefix = "__arrayElement_" + seed++ + "_";
        var transformedParameters =
        [
          for (i in 0...originValues.length)
          {
            {
              pos: originValues[i].pos,
              expr: EConst(CIdent(parameterPrefix + i)),
            };
          }
        ];
        var innerExpr =
        {
          pos: origin.pos,
          expr: EArrayDecl(transformedParameters),
        }
        var result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr);
        var i = originValues.length - 1;
        while (i >= 0)
        {
          var parameterExpr = originValues[i];
          var oldResult = result;
          var parameterName = parameterPrefix + i;
          var functionExpr =
          {
            pos: origin.pos,
            expr: EFunction(
              null,
              {
                args:
                [
                  {
                  	name: parameterName,
                    opt: false,
                    type: null,
                  }
                ],
                ret: null,
                expr: oldResult,
                params: [],
              })
          }
          result = macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate($parameterExpr, $functionExpr);
          i--;
        }
        return result;
      }
      case EArray(e1, e2):
      {
        var innerExpr =
        {
          pos: origin.pos,
          expr: EArray(macro e1, macro e2),
        }
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
          $e1,
          /*inline*/ function(e1)
          {
            com.dongxiguo.continuation.Continuation.ContinuationDetail.evaluate(
              $e2,
              /*inline*/ function(e2)
              {
                com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $innerExpr);
              });
          });
      }
      case EConst(_) | EDisplayNew(_) | EFunction(_, _) | EIn(_, _) | EFor(_, _)
      #if haxe_211
        | EMeta(_, _)
      #end
      :
      {
        return macro com.dongxiguo.continuation.Continuation.ContinuationDetail.apply($completeHandler, $additionExpr, $origin);
      }
    }
  }
}

