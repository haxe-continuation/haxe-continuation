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
#if (nodejs && js)
import js.Node;
import com.dongxiguo.continuation.Continuation;
using Lambda;
/**
 * @author 杨博
 */
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("cps"))
class TestNode
{
  /**
   * Writes <code>content</code> to <code>fd</code>.
   */
  @cps static function writeAll(fd:Int, content:String):Null<NodeErr>
  {
    var totalWritten = 0;
    while (totalWritten < content.length)
    {
      var err, written =
        @await Node.fs.write(
          fd, content,
          totalWritten, content.length - totalWritten, null);
      if (err != null)
      {
        return err;
      }
      totalWritten += written;
    }
    return null;
  }

  /**
   * Creates a directory named "TestNode", and concurrently put 5 files into it.
   */
  @cps static function startTest():Void
  {
    var err = @await Node.fs.mkdir("TestNode");
    if (err != null)
    {
      trace("Node.fs.mkdir failed: " + err);
      return;
    }

    // Lambda.iter() forks threads for each element.
    // Fork 5 threads now!
    var fileName = @await ["1.txt", "2.log", "3.txt", "4.ini", "5.conf"].iter();

    // Note that some asynchronous functions return more than one values!
    // It's OK in CPS functions, just like Lua.
    var err, fd = @await Node.fs.open("TestNode/" + fileName, "w+");
    if (err != null)
    {
      trace("Node.fs.open failed: " + err);
      return;
    }

    // Invoke another CPS function.
    var err = @await writeAll(fd, "Content of " + fileName);
    if (err != null)
    {
      trace("Node.fs.write failed: " + err);
      return;
    }

    var err = @await Node.fs.close(fd);
    if (err != null)
    {
      trace("Node.fs.close failed: " + err);
      return;
    }
  }

  public static function main():Void
  {
    startTest(
      function():Void
      {
        trace("Test is done!");
      });
  }

}
#end
