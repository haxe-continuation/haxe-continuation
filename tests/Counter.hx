package tests;
class Counter
{
  var n:Int;
  public function new(n:Int)
  {
    this.n = n;
  }
  public function join(handler:Void->Void):Void
  {
    if (0 == --n)
    {
      handler();
    }
  }
}
