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
   * Convert a function to CPS function.
   *
   * In converted function, you can use <code>.async()</code> postfix to invoke other asynchronous functions.
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
                macro com.dongxiguo.continuation.Continuation.ContinuationDetail
                .cps($originExpr)
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
   * When add <code>@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("metaName"))</code> in front of a class, any method with same metadata name from <code>metaName</code> in that class will be converted to CPS function.
   *
   * In converted function, you can use <code>.async()</code> postfix to invoke other asynchronous functions.
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
                macro com.dongxiguo.continuation.Continuation.ContinuationDetail
                .cps($originExpr);
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

// For internal use only, don't access it immediately.
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

  static function transformCondition(
    pos:Position,
    econd:Expr,
    eif:Expr,
    eelse:Null<Expr>, rest:Array<Expr>->Expr):Expr
  {
    if (eelse == null)
    {
      eelse = { pos: pos, expr: EBlock([]) };
    }
    var endIfName = "__endIf_" + seed++;
    var endIfArgs = [];
    var ifResultIdents = [];
    var numResults = 0;
    var transformedIf =
      transform(
        econd,
        function(econdResult)
        {
          return
          {
            pos: pos,
            expr: EIf(
              unpack(econdResult, econd.pos),
              transform(eif, function(eifResult)
              {
                if (numResults < eifResult.length)
                {
                  numResults = eifResult.length;
                }
                return
                {
                  pos: eif.pos,
                  expr: ECall(
                    {
                      pos: eif.pos,
                      expr: EConst(CIdent(endIfName))
                    },
                    eifResult)
                }
              }),
              transform(eelse, function(eelseResult)
              {
                if (numResults < eelseResult.length)
                {
                  numResults = eelseResult.length;
                }
                return
                {
                  pos: eelse.pos,
                  expr: ECall(
                    {
                      pos: eelse.pos,
                      expr: EConst(CIdent(endIfName))
                    },
                    eelseResult)
                }                    
              })
              )
          };
        });
    for (i in 0...numResults)
    {
      var ifResultName = "__ifResult_" + seed++;
      endIfArgs.push(
      {
        name: ifResultName,
        opt: true,
        value: null,
        type: null
      });
      ifResultIdents.push(
        {
          pos: pos,
          expr: EConst(CIdent(ifResultName))
        });
    }
    return
    {
      pos: pos,
      expr: EBlock(
        [
          {
            pos: pos,
            expr: EFunction(
              endIfName,
              {
                expr: rest(ifResultIdents),
                ret: null,
                params: [],
                args: endIfArgs
              })
          },
          transformedIf
        ])
    };
  }
  
  static function transform(origin:Expr, rest:Array<Expr>->Expr):Expr
  {
    switch (origin.expr)
    {
      case EWhile(econd, e, normalWhile):
      {
        var continueName = "__continue_" + seed++;
        var continueIdent =
        {
          pos: origin.pos,
          expr: EConst(CIdent(continueName))
        };
        var breakName =
          "__break_" + seed++;
        var breakIdent =
        {
          pos: origin.pos,
          expr: EConst(CIdent(breakName))
        };
        
        var continueBody = transform(
          econd,
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
        return
        {
          pos: origin.pos,
          expr: EBlock(
            [
              {
                pos: origin.pos,
                expr: EFunction(
                  breakName,
                  {
                    expr: rest([]),
                    ret: null,
                    params: [],
                    args: []
                  })
              },
              (macro var $continueName = null),
              {
                pos: origin.pos,
                expr: EFunction(
                  "__do",
                  {
                    expr:
                    {
                      pos: origin.pos,
                      expr: EBlock(
                      [
                        macro inline function __continue():Void
                        {
                          return $continueIdent();
                        },
                        macro inline function __break():Void
                        {
                          return $breakIdent();
                        },
                        transform(e, function(eResult)
                        {
                          return
                          {
                            pos: origin.pos,
                            expr: EBlock(eResult.concat([ macro $continueIdent()]))
                          };
                        })
                      ])
                    },
                    ret: null,
                    params: [],
                    args: []
                  })
              },
              macro $continueIdent = function()
              {
                $continueBody;
              },
              normalWhile ? macro $continueIdent() : macro __do()
            ])
        };
      }
      case EVars(originVars):
      {
        var transformedVars = [];
        return originVars.fold(
          function(originVar, e:Expr):Expr
          {
            transformedVars.push(
            {
              name: originVar.name,
              type: originVar.type,
              expr: null
            });
            if (originVar.expr == null)
            {
              return e;
            }
            else
            {
              return transform(originVar.expr, function(transformedExprs:Array<Expr>):Expr
              {
                if (transformedVars.length < transformedExprs.length)
                {
                  Context.error(
                    "Expect " + transformedExprs.length + " variable declarations.",
                    origin.pos);
                }
                for (i in 0...transformedExprs.length)
                {
                  var transformedVar =
                    transformedVars[
                      transformedVars.length - transformedExprs.length + i];
                  if (transformedVar.expr == null)
                  {
                    transformedVar.expr = transformedExprs[i];
                  }
                  else
                  {
                    Context.error(
                      "Expect " + transformedExprs.length + " variable declarations.",
                      origin.pos);
                  }
                }
                return e;
              });
            }
          },
          rest(
            [
              {
                pos: origin.pos,
                expr: EVars(transformedVars)
              }
            ]));
      }
      case EUntyped(e):
      {
        return transform(
          e,
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
        return transform(
          e,
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
      #if !haxe3
      case EType(e, field):
      {
        return transform(
          e,
          function(eResult)
          {
            return rest(
              [
                {
                  pos: origin.pos,
                  expr: EType(unpack(eResult, origin.pos), field)
                }
              ]);
          });
      }
      #end
      case ETry(e, catches):
      {
        var endTryName = "__endTry_" + seed++;
        var endTryIdent = 
        {
          pos: origin.pos,
          expr: EConst(CIdent(endTryName))
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
            endTryName,
            {
              ret: null,
              params: [],
              expr: rest([ tryResultIdent ]),
              args:
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
        var transformedTry = 
        {
          pos: origin.pos,
          expr: ETry(macro { __tryResult = $e; __noException = true; }, catches.map(
            function(catchBody)
            {
              return
              {
                expr: transform(
                  catchBody.expr,
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
                            endTryIdent,
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
        return macro
        {
          $endTryFunction;
          var __noException = false;
          var __tryResult = cast null;
          $transformedTry;
          if (__noException)
          {
            $endTryIdent(__tryResult);
          }
        };
      }
      case EThrow(e):
      {
        return transform(
          e,
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
        return transformCondition(origin.pos, econd, eif, eelse, rest);
      }
      case ESwitch(e, cases, edef):
      {
        if (edef == null)
        {
          edef =
          {
            pos: origin.pos,
            expr: EBlock([])
          }
        }
        var endSwitchName = "__endSwitch_" + seed++;
        var endSwitchIdent = 
        {
          pos: origin.pos,
          expr: EConst(CIdent(endSwitchName))
        }
        var numResults = 0;
        var transformedSwitch = transform(e, function(eResults)
        {
          return
          {
            pos: origin.pos,
            expr: ESwitch(
              unpack(eResults, e.pos),
              cases.map(
                function(caseBody)
                {
                  return
                  {
                    expr: transform(
                      caseBody.expr,
                      function(caseResults)
                      {
                        if (numResults < caseResults.length)
                        {
                          numResults = caseResults.length;
                        }
                        return
                        {
                          pos: caseBody.expr.pos,
                          expr: ECall(endSwitchIdent, caseResults)
                        };
                      }),
                    values: caseBody.values
                  }
                }
              ).array(),
              transform(
                edef,
                function(edefResults)
                {
                  if (numResults < edefResults.length)
                  {
                    numResults = edefResults.length;
                  }
                  return
                  {
                    pos: edef.pos,
                    expr: ECall(endSwitchIdent, edefResults)
                  };
                }))
          };
        });
        var endSwitchArgs = [];
        var endSwitchArgIdents = [];
        for (i in 0...numResults)
        {
          var switchResultName = "__switchResult_" + seed++;
          endSwitchArgIdents.push(
          {
            pos: origin.pos,
            expr: EConst(CIdent(switchResultName))
          });
          endSwitchArgs.push(
            {
              name: switchResultName,
              opt: true,
              type: null,
              value: null
            });
        }        
        var endSwitchFunction =
        {
          pos: origin.pos,
          expr: EFunction(
            endSwitchName,
            {
              ret: null,
              params: [],
              expr: rest(endSwitchArgIdents),
              args: endSwitchArgs
            })
        }
        return macro
        {
          $endSwitchFunction;
          var __switchResult = null;
          $transformedSwitch;
          if (__switchResult != null)
          {
            $endSwitchIdent(__switchResult);
          }
        };

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
                        // 优化 e 是另一个异步函数的情况
                        return transform(e, function(functionResult)
                        {
                          var transformedParams = [];
                          var result =
                            {
                              iterator: function()
                              {
                                return 0...originParams.length;
                              }
                            }.fold(
                              function(i, expr)
                              {
                                return transform(
                                  originParams[i],
                                  function(prefixResult:Array<Expr>):Expr
                                  {
                                    transformedParams.push(unpack(prefixResult, expr.pos));
                                    return expr;
                                  });
                              },
                              {
                                pos: origin.pos,
                                expr: ECall(
                                  unpack(functionResult, origin.pos),
                                  transformedParams)
                              });
                          transformedParams.push(
                            {
                              expr: EConst(CIdent("__return")),
                              pos: origin.pos
                            });
                          return result;
                        });
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
        return transform(
          returnExpr,
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
        return transform(e, rest);
      }
      case EObjectDecl(originFields):
      {
        var transformedFields = [];
        return originFields.fold(function(field, expr)
        {
          return transform(
            field.expr,
            function(fieldResult:Array<Expr>):Expr
            {
              for (fieldIdent in fieldResult)
              {
                transformedFields.push(
                  {
                    expr: fieldIdent,
                    field: field.field
                  });
              }
              return expr;
            });
        }, rest(
          [
            {
              pos: origin.pos,
              expr: EObjectDecl(transformedFields)
            }
          ]));
      }
      case ENew(t, originValues):
      {
        var transformedValues = [];
        return originValues.fold(function(originValue, expr)
        {
          return transform(
            originValue,
            function(valueResults:Array<Expr>):Expr
            {
              for (valueResult in valueResults)
              {
                transformedValues.push(valueResult);
              }
              return expr;
            });
        }, rest(
          [
            {
              pos: origin.pos,
              expr: ENew(t, transformedValues)
            }
          ]));
      }
      case EIn(e1, e2):
      {
        // Unsupported. Don't change it.
        return rest([origin]);
      }
      case EIf(econd, eif, eelse):
      {
        return transformCondition(origin.pos, econd, eif, eelse, rest);
      }
      case EFunction(name, f):
      {
        return rest([origin]);
      }
      case EFor(it, expr):
      {
        switch (it.expr)
        {
          case EIn(e1, e2):
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
            return transform(
              macro
              {
                var __iterator = null;
                {
                  inline function setIterator<T>(
                    iterable:Iterable<T> = null,
                    iterator:Iterator<T> = null):Void
                  {
                    __iterator = iterable != null ? iterable.iterator() : iterator;
                  }
                  setIterator($e2);
                }
                while (__iterator.hasNext())
                {
                  var $elementName = __iterator.next();
                  $expr;
                }
              },
              rest);
          }
          default:
          {
            Context.error("Expect \"in\" in \"for\".", it.pos);
            return null;
          }
        }
      }
      case EField(e, field):
      {
        return transform(
          e,
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
      case EDisplayNew(t):
      {
        return rest([origin]);
      }
      case EDisplay(e, isCall):
      {
        return rest([origin]);
      }
      case EContinue:
      {
        return macro __continue();
      }
      case EConst(c):
      {
        return rest([origin]);
      }
      case ECheckType(e, t):
      {
        return transform(
          e,
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
        return transform(
          e,
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
                    return transform(e, function(functionResult)
                    {
                      var handlerArgs =
                        switch (Context.typeof(unpack(functionResult, e.pos)))
                        {
                          case TFun(args, ret):
                          {
                            switch (args[args.length - 1].t)
                            {
                              case TFun(args, ret):
                              {
                                args;
                              }
                              default:
                              {
                                throw "First parameter of async() must be a function whose last parameter is a handler.";
                              }
                            }
                          }
                          default:
                          {
                            throw "First parameter of async() must be a function";
                          }
                        }
                      var handlerArgResult = [];
                      var handlerArgDefs = [];
                      for (i in 0...handlerArgs.length)
                      {
                        var handlerArg = handlerArgs[i];
                        var name = "__parameter_" + seed++;
                        handlerArgResult[i] =
                          {
                            pos: origin.pos,
                            expr: EConst(CIdent(name))
                          };
                        handlerArgDefs[i] =
                          {
                            opt: handlerArg.opt,
                            name: name,
                            type: null,
                            value: null
                          };
                      }
                      var parameters = [];
                      var result =
                        {
                          iterator: function() { return 0...originParams.length; }
                        }.fold(
                          function(i, expr)
                          {
                            return transform(originParams[i], function(prefixResult:Array<Expr>):Expr
                            {
                              parameters.push(unpack(prefixResult, expr.pos));
                              return expr;
                            });
                          },
                          {
                            pos: origin.pos,
                            expr: ECall(unpack(functionResult, origin.pos), parameters)
                          });
                      parameters.push(
                        {
                          pos: origin.pos,
                          expr: EFunction(null,
                          {
                            ret: null,
                            params: [],
                            expr: rest(handlerArgResult),
                            args: handlerArgDefs
                          })
                        });
                      return result;
                    });
                  }
                  default:
                }
              }
            }
            default:
          }
        }
        return transform(
          e,
          function(fResult):Expr
          {
            var transformedParams = [];
            return originParams.fold(function(param, expr)
            {
              return transform(param, function(paramResult:Array<Expr>):Expr
              {
                for (paramIdent in paramResult)
                {
                  transformedParams.push(paramIdent);
                }
                return expr;
              });
            }, rest(
              [
                {
                  pos: origin.pos,
                  expr: ECall(unpack(fResult, origin.pos), transformedParams)
                }
              ]));
          });
      }
      case EBreak:
      {
        return macro __break();
      }
      case EBlock(exprs):
      {
        if (exprs.length == 0)
        {
          return rest([]);
        }
        function next(blockLineIndex:Int, line:Array<Expr>):Expr
        {
          if (blockLineIndex == exprs.length - 1)
          {
            return
            {
              pos: origin.pos,
              expr: EBlock(
                line.concat(
                  [
                    transform(exprs[blockLineIndex], rest)
                  ]))
            };
          }
          else
          {
            return
            {
              pos: origin.pos,
              expr: EBlock(
                line.concat(
                  [
                    transform(exprs[blockLineIndex], callback(next, blockLineIndex + 1))
                  ]))
            };
          }
        }
        return next(0, []);
      }
      case EBinop(op, e1, e2):
      {
        return transform(
          e1,
          function(e1Result)
          {
            return transform(e2, function(e2Result)
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
      case EArrayDecl(originValues):
      {
        var transformedValues = [];
        return originValues.fold(function(originValue, expr)
        {
          return transform(
            originValue,
            function(valueResults:Array<Expr>):Expr
            {
              for (valueResult in valueResults)
              {
                transformedValues.push(valueResult);
              }
              return expr;
            });
        }, rest(
          [
            {
              pos: origin.pos,
              expr: EArrayDecl(transformedValues)
            }
          ]));
      }
      case EArray(e1, e2):
      {
        return transform(
          e1,
          function(e1Result)
          {
            return transform(e2, function(e2Result)
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
  #end
  
  @:noUsing @:macro public static function cps(body:Expr):Expr
  {
    return transform(
      body,
      function(exprs: Array<Expr>):Expr
      {
        return
        {
          pos: body.pos,
          expr: EBlock(exprs.concat([macro (cast __return)()]))
        }
      });
  }
}

