// Copyright (c) 2012-2014, 杨博 (Yang Bo)
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
import haxe.ds.GenericStack.GenericCell;
#end

using Lambda;

@:final
class Continuation
{
  /**
    Wrap a function to a CPS function.

    In the wrapped function, you can use `.async()` suffix to invoke other
    asynchronous functions.
   **/
  @:noUsing
  macro
  public static function cpsFunction(expr:Expr):Expr
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
              expr: ContinuationDetail.transform(
                originExpr,
                ANY,
                function(transformed:Array<Expr>)
                {
                  transformed.push(
                  {
                    expr: ECall(macro __return, []),
                    pos: originExpr.pos,
                  });
                  return
                  {
                    pos: originExpr.pos,
                    expr: EBlock(transformed),
                  }
                })
            })
        };
      }
      default:
      {
        throw "Expect function.";
      }
    }
  }

  /**
    A [build macro](http://haxe.org/manual/macro-type-building.html) that
    enables CPS transformation for the annotated class.

    In
    `@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("youMeta"))
    class YourClass`,
    all `@youMeta` methods in `YourClass` will be transfromed to CPS functions.
    In these `@youMeta` methods,
    some macros are performed to enable the magic `.async()` suffix syntax that
    invokes other asynchronous functions.
  **/
  @:noUsing
  macro
  public static function cpsByMeta(metaName:String):Array<Field>
  {
    var bf = Context.getBuildFields();
    for (field in bf)
    {
      switch (field.kind)
      {
        case FFun(f):
        {
          var originReturnType = f.ret;
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
                    type: originReturnType == null ? null : TFunction(
                      [ originReturnType ],
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
              f.expr = ContinuationDetail.transform(
                originExpr,
                ANY,
                function(transformed)
                {
                  transformed.push(
                  {
                    expr: ECall(macro __return, []),
                    pos: originExpr.pos,
                  });
                  return
                  {
                    pos: originExpr.pos,
                    expr: EBlock(transformed),
                  }
                });
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
  For internal use only. Don't access it immediately.
**/
@:final
@:dox(hide)
class ContinuationDetail
{
  #if macro

  static function pushMulti(
    gc:GenericCell<Expr>,
    a:Array<Expr>):GenericCell<Expr>
  {
    for (e in a)
    {
      gc = new GenericCell<Expr>(e, gc);
    }
    return gc;
  }

  static function toReverseArray<E>(gc:GenericCell<E>):Array<E>
  {
    var result = [];
    while (gc != null)
    {
      result.unshift(gc.elt);
      gc = gc.next;
    }
    return result;
  }

  static var seed:Int = 0;

  static function unpack(exprs: Array<Expr>, pos: Position):Expr
  {
    if (exprs.length != 1)
    {
      Context.error("Expect one return value, but there are " + exprs.length +
      " return values.", pos);
    }
    return exprs[0];
  }

  static function unblock(expr:Expr):Expr
  {
    switch (expr.expr)
    {
      case EBlock([ b ]): return unblock(b);
      case _: return expr;
    }
  }

  static function transformTailCallAwait(e:Expr, originParams:Array<Expr>, rest:Array<Expr>->Expr):Expr
  {
    // 优化 e 是另一个异步函数的情况
    function transformNext(i:Int, transformedParameters:Null<GenericCell<Expr>>):Expr
    {
      if (i == originParams.length)
      {
        return transformNoDelay(e, ANY, function(functionResult)
        {
          var a = toReverseArray(transformedParameters);
          a.push(
          {
            expr: EConst(CIdent("__return")),
            pos: e.pos
          });
          return
          {
            pos: e.pos,
            expr: ECall(
              unpack(functionResult, e.pos),
              a),
          };
        });
      }
      else
      {
        return transformNoDelay(
          originParams[i],
          ANY,
          function(parameterResult:Array<Expr>):Expr
          {
            return transformNext(
              i + 1,
              pushMulti(
                transformedParameters,
                parameterResult));
          });
      }
    }
    return transformNext(0, null);
  }

  static function transformAwait(e:Expr, originParams:Array<Expr>, rest:Array<Expr>->Expr):Expr
  {
    function transformNext(i:Int, transformedParameters:Null<GenericCell<Expr>>):Expr
    {
      if (i == originParams.length)
      {
        return transformNoDelay(e, ANY, function(functionResult)
        {
          var transformedCalleeExpr = unpack(functionResult, e.pos);
          var typingExpr = switch (transformedCalleeExpr.expr)
          {
            case EField(e, fieldName):
            {
              switch (e.expr)
              {
                case EConst(c):
                {
                  switch (c)
                  {
                    case CIdent(s):
                    {
                      if (s == "super")
                      {
                        {
                          pos: transformedCalleeExpr.pos,
                          expr: EField(macro this, fieldName),
                        }
                      }
                      else
                      {
                        transformedCalleeExpr;
                      }
                    }
                    default: transformedCalleeExpr;
                  }
                }
                default: transformedCalleeExpr;
              }
            }
            default: transformedCalleeExpr;
          }
          var handlerArgResult = [];
          var handlerArgDefs = [];
          var functionType = try
          {
            Context.follow(Context.typeof(typingExpr));
          }
          catch (_:Dynamic)
          {
            null;
          }
          if (functionType == null)
          {
            var name = "__parameter_" + seed++;
            handlerArgResult.push(
              {
                pos: e.pos,
                expr: EConst(CIdent(name))
              });
            handlerArgDefs.push(
              {
                opt: true,
                name: name,
                type: null,
                value: null
              });
          }
          else
          {
            switch (functionType)
            {
              case TFun(args, _):
              {
                switch (Context.follow(args[args.length - 1].t))
                {
                  case TFun(args, _):
                  {
                    for (handlerArg in args)
                    {
                      var name = "__parameter_" + seed++;
                      handlerArgResult.push(
                        {
                          pos: e.pos,
                          expr: EConst(CIdent(name))
                        });
                      handlerArgDefs.push(
                        {
                          opt: handlerArg.opt,
                          name: name,
                          type: haxe.macro.TypeTools.toComplexType(handlerArg.t),
                          value: null
                        });
                    }
                  }
                  default:
                  {
                    var name = "__parameter_" + seed++;
                    handlerArgResult.push(
                      {
                        pos: e.pos,
                        expr: EConst(CIdent(name))
                      });
                    handlerArgDefs.push(
                      {
                        opt: true,
                        name: name,
                        type: null,
                        value: null
                      });
                  }
                }
              }
              default:
              {
                return Context.error("Expect function.", e.pos);
              }
            }
          }
          var a = toReverseArray(transformedParameters);
          a.push(
            {
              pos: e.pos,
              expr: EFunction(null,
              {
                ret: null,
                params: [],
                expr: rest(handlerArgResult),
                args: handlerArgDefs
              })
            });
          return
          {
            pos: e.pos,
            expr: ECall(transformedCalleeExpr, a),
          };
        });
      }
      else
      {
        return transformNoDelay(
          originParams[i],
          ANY,
          function(parameterResult:Array<Expr>):Expr
          {
            return transformNext(
              i + 1,
              pushMulti(
                transformedParameters,
                parameterResult));
          });
      }
    }
    return transformNext(0, null);
  }

  static function transformCondition(
    pos:Position,
    econd:Expr,
    eif:Expr,
    eelse:Null<Expr>,
    parameterRequirement:ParameterRequirement,
    rest:Array<Expr>->Expr):Expr
  {
    var wrapper = new Wrapper(parameterRequirement, rest, false, "__endIf_");
    return transformNoDelay(
      econd,
      EXACT(1),
      function(econdResult)
      {
        var declearation = wrapper.declearation;
        var entry =
        {
          pos: pos,
          expr: EIf(
            unpack(econdResult, econd.pos),
            transformNoDelay(eif, ANY, wrapper.invocation),
            eelse == null ? wrapper.invocation([]) : transformNoDelay(eelse, ANY, wrapper.invocation)),
        };
        return macro { $declearation; $entry; }
      });
  }

  public static function transform(
    origin:Expr,
    parameterRequirement:ParameterRequirement,
    rest:Array<Expr>->Expr):Expr
  {
    return delay(
      origin.pos,
      function()
      {
        return transformNoDelay(origin, parameterRequirement, rest);
      });
  }

  static function transformNoDelay(
    origin:Expr,
    parameterRequirement:ParameterRequirement,
    rest:Array<Expr>->Expr):Expr
  {
    switch (origin.expr)
    {
      case EMeta({ name: "await", params: [] }, { expr: ECall(functionExpr, params) }):
      {
        return transformAwait(functionExpr, params, rest);
      }
      case EMeta({ name: "fork", params: [ { expr: EBinop(OpIn, { expr: EConst(CIdent(variableName)) }, idendifiers) } ] }, forkBody):
      {
        var afterForkExpr = rest([]);
        var transformedBody = transformNoDelay(forkBody, IGNORE, function(exprs) return
        {
          expr: EBlock(exprs.concat([macro __checkCounter()])),
          pos: origin.pos,
        });
        return macro
        {
          var __iterator = com.dongxiguo.continuation.Continuation.ContinuationDetail.toIterator($idendifiers);
          if (com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext($idendifiers, __iterator))
          {
            var __counter = 1;
            function __checkCounter():Void if (--__counter == 0) $afterForkExpr;
            do
            {
              var $variableName = com.dongxiguo.continuation.Continuation.ContinuationDetail.next($idendifiers, __iterator);
              __counter++;
              $transformedBody;
            }
            while (com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext($idendifiers, __iterator));
            __checkCounter();
          }
        };
      }
      case EMeta(s, e):
      {
        return rest([origin]);
      }
      case EWhile(econd, e, normalWhile):
      {
        var continueName = "__continue_" + seed++;
        var continueIdent =
        {
          pos: origin.pos,
          expr: EConst(CIdent(continueName))
        };
        var breakName = "__break_" + seed++;
        #if no_inline
          var inlineBreakName = breakName;
        #else
          var inlineBreakName = "inline_" + breakName;
        #end
        var breakIdent =
        {
          pos: origin.pos,
          expr: EConst(CIdent(inlineBreakName))
        };
        var doBody = transform(e,
          IGNORE,
          function(eResult)
          {
            return
            {
              pos: origin.pos,
              expr: EBlock(eResult.concat([ macro $continueIdent()]))
            };
          });
        var continueBody = transform(
          econd,
          EXACT(1),
          function(econdResult)
          {
            return
            {
              pos: origin.pos,
              expr: EIf(
                unpack(econdResult, econd.pos),
                macro __do(),
                macro $breakIdent())
            };
          });
        var breakBody = rest([]);
        if (normalWhile)
        {
          return macro
          {
            var __doCount = 0;
            function $inlineBreakName():Void
            {
              $breakBody;
            }
            function $continueName():Void
            {
              #if no_inline #else inline #end function __do()
              {
                #if no_inline #else inline #end function __break()
                {
                  $breakIdent();
                }
                #if no_inline #else inline #end function __continue()
                {
                  $continueIdent();
                }
                if (__doCount++ == 0)
                {
                  // Check reenter;
                  do
                  {
                    $doBody;
                  }
                  while (--__doCount != 0);
                }
              }
              $continueBody;
            }
            $continueIdent();
          }
        }
        else
        {
          // #if no_inline
            var inlineContinueName = continueName;
          // #else
          //   var inlineContinueName = "inline_" + continueName;
          // #end
          return macro
          {
            var __doCount = 0;
            function $inlineBreakName():Void
            {
              $breakBody;
            }
            function __do()
            {
              function $inlineContinueName():Void
              {
                $continueBody;
              }
              #if no_inline #else inline #end function __break()
              {
                $breakIdent();
              }
              #if no_inline #else inline #end function __continue()
              {
                $continueIdent();
              }
              if (__doCount++ == 0)
              {
                // Check reenter;
                do
                {
                  $doBody;
                }
                while (--__doCount != 0);
              }
            }
            __do();
          }
        }
      }
      case EVars(originVars):
      {
        var functionName = "__afterVar_" + seed++;
        function transformNext(i:Int, values:Array<Null<Expr>>):Expr
        {
          if (i == originVars.length)
          {
            return
            {
              pos: origin.pos,
              expr: ECall(
                {
                  pos: origin.pos,
                  expr: EConst(CIdent(functionName)),
                },
                values),
            }
          }
          else
          {
            var originVar = originVars[i];
            if (originVar.expr == null)
            {
              return transformNext(i + 1, values);
            }
            else
            {
              return transform(originVar.expr, ANY, function(varResult)
              {
                var v = values.concat([]);
                if (i + 1 < varResult.length)
                {
                  return Context.error(
                    "Expect " + varResult.length + " variable declarations.",
                    origin.pos);
                }
                for (j in 0...varResult.length)
                {
                  var slot = j + i + 1 - varResult.length;
                  if (v[slot] == null)
                  {
                    var originVarJ = originVars[j];
                    v[slot] =
                      if (originVarJ.type == null)
                      {
                        varResult[j];
                      }
                      else
                      {
                        pos: origin.pos,
                        expr: ECheckType(varResult[j], originVarJ.type),
                      }
                  }
                  else
                  {
                    return Context.error(
                      "Expect " + varResult.length + " variable declarations.",
                      origin.pos);
                  }
                }
                return transformNext(i + 1, v);
              });
            }
          }
        }
        var entry = transformNext(0, []);
        return
        {
          pos: origin.pos,
          expr: ECall(
            {
              pos: origin.pos,
              expr: EParenthesis(
                {
                  pos: origin.pos,
                  expr: EFunction(null,
                    {
                      ret: null,
                      expr: entry,
                      params: [],
                      args:
                      [
                        {
                          name: functionName,
                          opt: false,
                          type: null,
                          value: null,
                        },
                      ],
                    }),
                }),
            },
            [
              {
                pos: origin.pos,
                expr: EFunction(
                  null,
                  {
                    params: [],
                    args:
                    {
                      var functionArgs = [];
                      for (originVar in originVars)
                      {
                        functionArgs.push(
                          {
                            name: originVar.name,
                            opt: false,
                            type: originVar.type,
                            value: null,
                          });
                      }
                      functionArgs;
                    },
                    ret: null,
                    expr:
                    {
                      pos: origin.pos,
                      expr: EBlock(
                        {
                          var exprs = [];
                          // Workaround for https://github.com/HaxeFoundation/haxe/issues/2069
                          for (originVar in originVars)
                          {
                            exprs.push(
                              {
                                pos: origin.pos,
                                expr: EConst(CIdent(originVar.name)),
                              });
                          }
                          exprs.push(rest([]));
                            //{
                              //pos: origin.pos,
                              //expr: EReturn(rest([])),
                            //});
                          exprs;
                        }),
                    }
                  }),
              },
            ]),
        }
      }
      case EUntyped(e):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: EUntyped(unpack(eResult, origin.pos))
                }
              ]);
          });
      }
      case EUnop(op, postFix, e):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: EUnop(op, postFix, unpack(eResult, origin.pos))
                }
              ]);
          });
      }
      case ETry(e, catches):
      {
        var endTryName = "__endTry_" + seed++;
        var endTryIdent =
        {
          pos: origin.pos,
          expr: EConst(CIdent(endTryName))
        }
        var isVoidTry = switch (Context.follow(Context.typeof(e)))
        {
          case TAbstract(t, params):
          {
            if (params.length != 0)
            {
              false;
            }
            else
            {
              var voidType = t.get();
              voidType.module == "StdTypes" && voidType.name == "Void";
            }
          }
          default: false;
        }
        var tryResultName = "__tryResult_" + seed++;
        var tryResultIdent =
        {
          pos: origin.pos,
          expr: EConst(CIdent(tryResultName))
        }
        var endTryFunction =
        {
          pos: origin.pos,
          expr: EFunction(
            FNamed(endTryName),
            {
              ret: null,
              params: [],
              expr: rest(isVoidTry ? [] : [ tryResultIdent ]),
              args: isVoidTry ? [] :
              [
                {
                  name: tryResultName,
                  opt: true,
                  type: null,
                  value: null
                }
              ]
            })
        }
        var tryBody = isVoidTry ? (macro { $e; __noException = true; }) : (macro { $tryResultIdent = $e; __noException = true; });
        var transformedTry =
        {
          pos: origin.pos,
          expr: ETry(tryBody, catches.map(
            function(catchBody)
            {
              return
              {
                expr: transformNoDelay(
                  catchBody.expr,
                  parameterRequirement,
                  function(catchResult)
                  {
                    switch (catchResult.length)
                    {
                      case 1:
                      {
                        return
                        {
                          pos: catchBody.expr.pos,
                          expr: ECall(
                            endTryIdent, isVoidTry ? [] :
                            [
                              {
                                pos: catchBody.expr.pos,
                                expr: ECast(
                                  unpack(catchResult, catchBody.expr.pos),
                                  null)
                              }
                            ])
                        };
                      }
                      default:
                      {
                        return
                        {
                          pos: origin.pos,
                          expr: ECall(endTryIdent, catchResult)
                        };
                      }
                    }
                  }),
                type: catchBody.type,
                name: catchBody.name
              }
            }
          ).array())
        }
        return
          isVoidTry ?
          macro
          {
            $endTryFunction;
            var __noException = false;
            $transformedTry;
            if (__noException)
            {
              $endTryIdent();
            }
          } :
          macro
          {
            $endTryFunction;
            var __noException = false;
            var $tryResultName = cast null;
            $transformedTry;
            if (__noException)
            {
              $endTryIdent($tryResultIdent);
            }
          };
      }
      case EThrow(e):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: EThrow(unpack(eResult, origin.pos))
                }
              ]);
          });
      }
      case ETernary(econd, eif, eelse):
      {
        return transformCondition(origin.pos, econd, eif, eelse, parameterRequirement, rest);
      }
      case ESwitch(e, cases, edef):
      {
        var wrapper = new Wrapper(parameterRequirement, rest, false, "__endSwitch_");
        return transformNoDelay(e, EXACT(1), function(eResult)
        {
          function transformGuard(guard:Null<Expr>):Expr
          {
            // Workaround to enable default:
            return parameterRequirement == IGNORE && guard == null ? macro true : guard;
          }
          var transformedCases = cases.map(function(c)
          {
            if (c.expr == null)
            {
              return { expr: wrapper.invocation([]), guard: transformGuard(c.guard), values: c.values };
            }
            else
            {
              return { expr: transform(c.expr, ANY, wrapper.invocation), guard: transformGuard(c.guard), values: c.values };
            }
          }).array();
          var entry = if (edef == null)
          {
            pos: origin.pos,
            expr: ESwitch(
              unpack(eResult, e.pos),
              transformedCases,
              parameterRequirement == IGNORE ? wrapper.invocation([]) : null),
          }
          else if (edef.expr == null)
          {
            pos: origin.pos,
            expr: ESwitch(unpack(eResult, e.pos), transformedCases, wrapper.invocation([])),
          }
          else
          {
            var transformedDef = transform(edef, ANY, wrapper.invocation);
            {
              pos: origin.pos,
              expr: ESwitch(unpack(eResult, e.pos), transformedCases, macro { $transformedDef; } ),
            }
          }
          var declearation = wrapper.declearation;
          return macro
          {
            $declearation;
            $entry;
          }
        });
      }
      case EReturn(returnExpr):
      {
        if (returnExpr == null)
        {
          return
          {
            pos: origin.pos,
            expr: ECall(
              {
                pos: origin.pos,
                expr: EConst(CIdent("__return"))
              },
              [])
          };
        }
        switch (returnExpr.expr)
        {
          case EMeta(s, e):
          {
            switch (e.expr)
            {
              case ECall(functionExpr, params):
              {
                if (s.name == "await" && s.params.empty())
                {
                  return transformTailCallAwait(functionExpr, params, rest);
                }
                else
                {
                  return rest([origin]);
                }
              }
              default:
              {
                return rest([origin]);
              }
            }
          }
          case ECall(e, originParams):
          {
            if (originParams.length == 0)
            {
              switch (e.expr)
              {
                case EField(prefixCall, field):
                {
                  if (field == "async")
                  {
                    switch (prefixCall.expr)
                    {
                      case ECall(e, originParams):
                      {
                        Context.warning("`.async()` is deprecated. Please use `@await` instead.", origin.pos);
                        return transformTailCallAwait(e, originParams, rest);
                      }
                      default:
                    }
                  }
                }
                default:
              }
            }
          }
          default:
        }
        return transformNoDelay(
          returnExpr,
          ANY,
          function(eResult)
          {
            return
            {
              pos: origin.pos,
              expr: ECall(
                {
                  pos: origin.pos,
                  expr: EConst(CIdent("__return"))
                },
                eResult)
            };
          });
      }
      case EParenthesis(e):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(transformedExprs)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: EParenthesis(unpack(transformedExprs, origin.pos)),
                },
              ]);
          });
      }
      case EObjectDecl(originFields):
      {
        function transformNext(i:Int, transformedFields:Null<GenericCell<{ field : String, expr : Expr }>>):Expr
        {
          if (i == originFields.length)
          {
            return rest(
            [
              {
                pos: origin.pos,
                expr: EObjectDecl(cast toReverseArray(transformedFields)),
              }
            ]);
          }
          else
          {
            var originField = originFields[i];
            return transformNoDelay(
              originField.expr,
              EXACT(1),
              function(valueResult:Array<Expr>):Expr
              {
                var t = transformedFields;
                for (e in valueResult)
                {
                  t = new GenericCell(
                    {
                      field: originField.field,
                      expr: unpack(valueResult, originField.expr.pos),
                    },
                    t);
                }
                return transformNext(i + 1, t);
              });
          }
        }
        return transformNext(0, null);
      }
      case ENew(t, originParams):
      {
        function transformNext(i:Int, transformedParameters:Null<GenericCell<Expr>>):Expr
        {
          if (i == originParams.length)
          {
            return rest(
            [
              {
                pos: origin.pos,
                expr: ENew(
                  t,
                  toReverseArray(transformedParameters)),
              }
            ]);
          }
          else
          {
            return transformNoDelay(
              originParams[i],
              ANY,
              function(parameterResult:Array<Expr>):Expr
              {
                return transformNext(
                  i + 1,
                  pushMulti(
                    transformedParameters,
                    parameterResult));
              });
          }
        }
        return transformNext(0, null);
      }
      case EBinop(OpIn, _, _):
      {
        // Unsupported. Don't change it.
        return rest([origin]);
      }
      case EIf(econd, eif, eelse):
      {
        return transformCondition(origin.pos, econd, eif, eelse, parameterRequirement, rest);
      }
      case EFunction(_, _):
      {
        return rest([origin]);
      }
      case EFor(it, expr):
      {
        switch (it.expr)
        {
          case EBinop(OpIn, e1, e2):
          {
            var elementName =
              switch (e1.expr)
              {
                case EConst(c):
                  switch (c)
                  {
                    case CIdent(s):
                    {
                      s;
                    }
                    default:
                    {
                      Context.error("Expect identify before \"in\".", e1.pos);
                    }
                  }
                default:
                {
                  Context.error("Expect identify before \"in\".", e1.pos);
                }
              }
            var toIteratorExpr =
            {
              expr: ECall(
                macro com.dongxiguo.continuation.Continuation.ContinuationDetail.toIterator,
                [ e2 ]),
              pos: Context.currentPos(),
            }
            var hasNextExpr =
            {
              expr: ECall(
                macro com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext,
                [ e2, macro __iterator ]),
              pos: Context.currentPos(),
            }
            var nextExpr =
            {
              expr: ECall(
                macro com.dongxiguo.continuation.Continuation.ContinuationDetail.next,
                [ e2, macro __iterator ]),
              pos: Context.currentPos(),
            }
            var body = transformNoDelay(
              macro while ($hasNextExpr)
              {
                var $elementName = $nextExpr;
                $expr;
              },
              IGNORE,
              rest);
            return macro { var __iterator = $toIteratorExpr; $body; };
          }
          default:
          {
            Context.error("Expect \"e1 in e2\"", it.pos);
            return null;
          }
        }
      }
      case EField(e, field):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: EField(unpack(eResult, origin.pos), field)
                }
              ]);
          });
      }
      case EDisplayNew(_):
      {
        return rest([origin]);
      }
      case EDisplay(_, _):
      {
        return rest([origin]);
      }
      case EContinue:
      {
        return macro __continue();
      }
      case EConst(_):
      {
        return rest([origin]);
      }
      case ECheckType(e, t):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: ECheckType(unpack(eResult, e.pos), t)
                }
              ]);
          });
      }
      case ECast(e, t):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: ECast(unpack(eResult, e.pos), t)
                }
              ]);
          });
      }
      #if (haxe_ver >= "4.2")
      case EIs(e, t):
      {
        return transformNoDelay(
          e,
          EXACT(1),
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: EIs(unpack(eResult, e.pos), t)
                }
              ]);
          });
      }
      #end
      case ECall(callExpr, originParams):
      {
        if (originParams.length == 0)
        {
          switch (callExpr.expr)
          {
            case EField(prefixCall, field):
            {
              if (field == "async")
              {
                switch (prefixCall.expr)
                {
                  case ECall(e, originParams):
                  {
                    Context.warning("`.async()` is deprecated. Please use `@await` instead.", origin.pos);
                    return transformAwait(e, originParams, rest);
                  }
                  default:
                }
              }
            }
            default:
          }
        }
        function transformNext(i:Int, transformedParameters:Null<GenericCell<Expr>>):Expr
        {
          if (i == originParams.length)
          {
            return transformNoDelay(callExpr, EXACT(1), function(functionResult)
            {
              var handlerArgResult = [];
              var handlerArgDefs = [];
              return rest([
              {
                pos: origin.pos,
                expr: ECall(
                  unpack(functionResult, origin.pos),
                  toReverseArray(transformedParameters)),
              }]);
            });
          }
          else
          {
            return transformNoDelay(
              originParams[i],
              ANY,
              function(parameterResult:Array<Expr>):Expr
              {
                return transformNext(
                  i + 1,
                  pushMulti(
                    transformedParameters,
                    parameterResult));
              });
          }
        }
        return transformNext(0, null);
      }
      case EBreak:
      {
        return
        {
          pos: origin.pos,
          expr: ECall(
            {
              pos: origin.pos,
              expr: EConst(CIdent("__break")),
            },
            [])
        };
      }
      case EBlock(exprs):
      {
        if (exprs.length == 0)
        {
          return rest([origin]);
        }
        function transformNext(i:Int):Expr
        {
          if (i == exprs.length - 1)
          {
            return transform(exprs[i], parameterRequirement, rest);
          }
          else
          {
            return transform(exprs[i], IGNORE, function(transformedLine)
            {
              return
              {
                pos: origin.pos,
                expr: EBlock(transformedLine.concat([transformNext(i + 1)])),
              }
            });
          }
        }
        return transformNext(0);
      }
      case EBinop(op, e1, e2):
      {
        switch (op)
        {
          case OpBoolOr:
          {
            return transformNoDelay(macro $e1 ? true : $e2 ? true : false, parameterRequirement, rest);
          }
          case OpBoolAnd:
          {
            return transformNoDelay(macro $e1 ? $e2 ? true : false : false, parameterRequirement, rest);
          }
          default:
          {
            return transformNoDelay(
              e1,
              EXACT(1),
              function(e1Result)
              {
                return transformNoDelay(e2, EXACT(1), function(e2Result)
                {
                  return rest(
                    [
                      {
                        pos: origin.pos,
                        expr: EBinop(
                          op,
                          unpack(e1Result, e1.pos),
                          unpack(e2Result, e2.pos))
                      }
                    ]);
                });
              });
          }
        }
      }
      case EArrayDecl(
        [
          {
            expr: EMeta(
			        #if (haxe_ver >= "4.0.0")
              { name: "fork", params: [ { expr: EBinop(OpIn, { expr: EConst(CIdent(variableName)) }, idendifiers) } ] },
              #else
              { name: "fork", params: [ { expr: EIn( { expr: EConst(CIdent(variableName)) }, idendifiers) } ] },
              #end
              forkBody)
          }
        ]):
      {
        var toIteratorExpr =
        {
          expr: ECall(
            macro com.dongxiguo.continuation.Continuation.ContinuationDetail.toIterator,
            [ idendifiers ]),
          pos: Context.currentPos(),
        }
        var hasNextExpr =
        {
          expr: ECall(
            macro com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext,
            [ idendifiers, macro __iterator ]),
          pos: Context.currentPos(),
        }
        var nextExpr =
        {
          expr: ECall(
            macro com.dongxiguo.continuation.Continuation.ContinuationDetail.next,
            [ idendifiers, macro __iterator ]),
          pos: Context.currentPos(),
        }
        switch (unblock(forkBody))
        {
          case { expr: EIf(econd, eif, null) }:
          {
            var afterForkExpr = rest([ macro __results ]);
            var transformedBody = transformNoDelay(eif, EXACT(1), function(exprs)
            {
              var elementExpr = unpack(exprs, eif.pos);
              return macro
              {
                __results[__index] = $elementExpr;
                __checkCounter();
              }
            });
            return macro
            {
              var __iterator = com.dongxiguo.continuation.Continuation.ContinuationDetail.toIterator($idendifiers);
              if (com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext($idendifiers, __iterator))
              {
                var __results = [];
                var __counter = 1;
                var __i = 0;
                function __checkCounter():Void if (--__counter == 0) $afterForkExpr;
                do
                {
                  var $variableName = com.dongxiguo.continuation.Continuation.ContinuationDetail.next($idendifiers, __iterator);
                  if ($econd)
                  {
                    var __index = __i;
                    __counter++;
                    $transformedBody;
                    __i++;
                  }
                }
                while (com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext($idendifiers, __iterator));
                __checkCounter();
              }
            };
          }
          default:
          {
            var afterForkExpr = rest([ macro __results ]);
            var transformedBody = transformNoDelay(forkBody, EXACT(1), function(exprs)
            {
              var elementExpr = unpack(exprs, forkBody.pos);
              return macro
              {
                __results[__index] = $elementExpr;
                __checkCounter();
              }
            });
            return macro
            {
              var __iterator = com.dongxiguo.continuation.Continuation.ContinuationDetail.toIterator($idendifiers);
              if (com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext($idendifiers, __iterator))
              {
                var __results = [];
                var __counter = 1;
                var __i = 0;
                function __checkCounter():Void if (--__counter == 0) $afterForkExpr;
                do
                {
                  var $variableName = com.dongxiguo.continuation.Continuation.ContinuationDetail.next($idendifiers, __iterator);
                  var __index = __i;
                  __counter++;
                  $transformedBody;
                  __i++;
                }
                while (com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext($idendifiers, __iterator));
                __checkCounter();
              }
            };
          }
        }
      }
      case EArrayDecl(
        [
          {
            expr: EFor(
              {
                expr: EBinop(OpIn,
                  {
                    expr: EConst(CIdent(elementName)),
                  },
                  e2)
              },
              expr),
          }
        ]):
      {
        var toIteratorExpr =
        {
          expr: ECall(
            macro com.dongxiguo.continuation.Continuation.ContinuationDetail.toIterator,
            [ e2 ]),
          pos: Context.currentPos(),
        }
        var hasNextExpr =
        {
          expr: ECall(
            macro com.dongxiguo.continuation.Continuation.ContinuationDetail.hasNext,
            [ e2, macro __iterator ]),
          pos: Context.currentPos(),
        }
        var nextExpr =
        {
          expr: ECall(
            macro com.dongxiguo.continuation.Continuation.ContinuationDetail.next,
            [ e2, macro __iterator ]),
          pos: Context.currentPos(),
        }
        switch (unblock(expr))
        {
          case { expr: EIf(econd, eif, null) }:
          {
            var transformed = transformNoDelay(
              macro
              {
                var __arrayBuilder = [];
                while ($hasNextExpr)
                {
                  var $elementName = $nextExpr;
                  if ($econd) __arrayBuilder.push($eif);
                }
                __arrayBuilder;
              },
              EXACT(1),
              rest);
            return macro { var __iterator = $toIteratorExpr; $transformed; };
          }
          case forBody:
          {
            var transformed = transformNoDelay(
              macro
              {
                var __arrayBuilder = [];
                while ($hasNextExpr)
                {
                  var $elementName = $nextExpr;
                  __arrayBuilder.push($forBody);
                }
                __arrayBuilder;
              },
              EXACT(1),
              rest);
            return macro { var __iterator = $toIteratorExpr; $transformed; };
          }
        }
      }
      case EArrayDecl(originParams):
      {
        function transformNext(i:Int, transformedParameters:Null<GenericCell<Expr>>):Expr
        {
          if (i == originParams.length)
          {
            return rest(
            [
              {
                pos: origin.pos,
                expr: EArrayDecl(
                  toReverseArray(transformedParameters)),
              }
            ]);
          }
          else
          {
            return transformNoDelay(
              originParams[i],
              ANY,
              function(parameterResult:Array<Expr>):Expr
              {
                return transformNext(
                  i + 1,
                  pushMulti(
                    transformedParameters,
                    parameterResult));
              });
          }
        }
        return transformNext(0, null);
      }
      case EArray(e1, e2):
      {
        return transformNoDelay(
          e1,
          EXACT(1),
          function(e1Result)
          {
            return transformNoDelay(e2, EXACT(1), function(e2Result)
            {
              return rest(
                [
                  {
                    pos: origin.pos,
                    expr: EArray(
                      unpack(e1Result, e1.pos),
                      unpack(e2Result, e2.pos))
                  }
                ]);
            });
          });
      }
    }
  }

  @:isVar
  static var delayFunctions(get, set):Array<Void->Expr>;

  static function set_delayFunctions(value:Array<Void->Expr>):Array<Void->Expr>
  {
    return delayFunctions = value;
  }

  static function get_delayFunctions():Array<Void->Expr>
  {
    if (delayFunctions == null)
    {
      Context.onGenerate(
        function(allType)
        {
          delayFunctions = null;
        });
      return delayFunctions = [];
    }
    else
    {
      return delayFunctions;
    }
  }

  static function delay(pos:Position, delayedFunction:Void->Expr):Expr
  {
    var id = delayFunctions.length;
    var idExpr = Context.makeExpr(id, Context.currentPos());
    delayFunctions.push(delayedFunction);
    return
    {
      pos: pos,
      expr: ECall(macro com.dongxiguo.continuation.Continuation.ContinuationDetail.runDelayedFunction, [idExpr]),
    }
  }

  static function hasArrayAccess(abstractType:AbstractType):Bool
  {
    if (abstractType.meta.has(":arrayAccess"))
    {
      return true;
    }
    else
    {
      return !abstractType.array.empty();
    }
  }

  static function hasLength(abstractType:AbstractType):Bool
  {
    var impl = abstractType.impl;
    if (impl == null)
    {
      return false;
    }
    else
    {
      for (field in impl.get().statics.get())
      {
        switch (field)
        {
          case { kind: FVar(AccCall, _), name: "length" }: return true;
          default: continue;
        }
      }
      return false;
    }
  }

  #end

  @:noUsing
  macro
  public static function runDelayedFunction(id:Int):Expr
  {
    return delayFunctions[id]();
  }

  @:noUsing
  macro
  public static function next(iterable:Expr, iterator:Expr):Expr
  {
    switch (Context.follow(Context.typeof(iterable)))
    {
      case TInst(_.get() => { module: "Array", name: "Array" }, _):
      {
        return macro $iterable[$iterator++];
      }
      case TAbstract(_.get() => a, _) if (hasArrayAccess(a) && hasLength(a)):
      {
        return macro $iterable[$iterator++];
      }
      case iterableType:
      {
        return macro $iterator.next();
      }
    }
  }

  @:noUsing
  macro
  public static function hasNext(iterable:Expr, iterator:Expr):Expr
  {
    switch (Context.follow(Context.typeof(iterable)))
    {
      case TInst(_.get() => { module: "Array", name: "Array" }, _):
      {
        return macro $iterator < $iterable.length;
      }
      case TAbstract(_.get() => a, _) if (hasArrayAccess(a) && hasLength(a)):
      {
        return macro $iterator < $iterable.length;
      }
      case iterableType:
      {
        return macro $iterator.hasNext();
      }
    }
  }

  @:noUsing
  macro
  public static function toIterator(iterable:Expr):Expr
  {
    switch (Context.follow(Context.typeof(iterable)))
    {
      case TInst(_.get() => { module: "Array", name: "Array" }, _):
      {
        return macro 0;
      }
      case TAbstract(_.get() => a, _) if (hasArrayAccess(a) && hasLength(a)):
      {
        return macro 0;
      }
      case iterableType:
      {
        function toType(c:ComplexType):Null<Type>
        {
          return c == null ? null : haxe.macro.Context.typeof( { expr: ECheckType(macro null, c), pos: Context.currentPos() } );
        }
        if (
          Context.unify(iterableType, toType(TPath(
          {
            name: "Iterator",
            pack: [],
            sub: null,
            params:
            [
              TPType(TPath(
                {
                  name: "Dynamic",
                  pack: [],
                  sub: null,
                  params: [],
                })),
            ]
          }))))
        {
          return iterable;
        }
        else
        {
          return macro $iterable.iterator();
        }
      }
    }
  }

}

#if macro
private enum ParameterRequirement
{

  /** 必须正好是numParameters个参数 */
  EXACT(numParameters:Int);

  /** 忽略参数 */
  IGNORE;

  /** 接受任意数量的参数 */
  ANY;

}

private class Wrapper
{
  static var seed:Int = 0;

  public var declearation(default, null):Expr;

  public var invocation(default, null):Array<Expr>->Expr;

  static function declearWrapper(
    functionName:String,
    numParameters:Int,
    rest:Array<Expr>->Expr):Expr
  {
    var parameterNames:Array<String> = [];
    for (i in 0...numParameters)
    {
      parameterNames.push(functionName + "_parameter_" + i);
    }
    return
    {
      pos: Context.currentPos(),
      expr: EFunction(
        FNamed(functionName),
        {
          args:
          {
            var functionArgs:Array<FunctionArg> = [];
            for (parameterName in parameterNames)
            {
              functionArgs.push(
                {
                  name: parameterName,
                  opt: false,
                  type: null,
                  value: null,
                });
            }
            functionArgs;
          },
          ret: null,
          params: [],
          expr:
          {
            pos: Context.currentPos(),
            expr: EReturn(
              rest(
                {
                  var parameterExprs = [];
                  for (parameterName in parameterNames)
                  {
                    parameterExprs.push(
                    {
                      pos: Context.currentPos(),
                      expr: EConst(CIdent(parameterName)),
                    });
                  }
                  parameterExprs;
                }))
          }
        }),
    }
  }

  public function new(
    parameterRequirement:ParameterRequirement,
    rest:Array<Expr>->Expr,
    isInline:Bool,
    prefix:String)
  {
    switch (parameterRequirement)
    {
      case ANY:
      {
        this.declearation =
        {
          pos: Context.currentPos(),
          expr: EBlock([]),
        };
        this.invocation = rest;
      }
      case IGNORE:
        var functionName = prefix + Std.string(seed++);
        if (isInline)
        {
          this.declearation = declearWrapper("inline_" + functionName, 0, rest);
        }
        else
        {
          this.declearation = declearWrapper(functionName, 0, rest);
        }
        this.invocation = function(parameters:Array<Expr>):Expr
        {
          return
          {
            pos: Context.currentPos(),
            expr: EBlock(parameters.concat(
              [
                {
                  pos: Context.currentPos(),
                  expr: ECall(
                    {
                      pos: Context.currentPos(),
                      expr: EConst(CIdent(functionName)),
                    },
                    []),
                }
              ])),
          };
        };
      case EXACT(numParameters):
        var functionName = prefix + Std.string(seed++);
        // trace(functionName);
        // #if no_inline
          this.declearation = declearWrapper(functionName, numParameters, rest);
        // #else
          // this.declearation = declearWrapper("inline_" + functionName, numParameters, rest);
        // #end
        this.invocation = function(parameters:Array<Expr>):Expr
        {
          return
          {
            pos: Context.currentPos(),
            expr: EBlock(parameters.concat(
              [
                {
                  pos: Context.currentPos(),
                  expr: ECall(
                    {
                      pos: Context.currentPos(),
                      expr: EConst(CIdent(functionName)),
                    },
                    parameters),
                }
              ])),
          };
        };
    }
  }

}
#end
