package fancy2209.dynamite.utils 
{
public class VectorUtil 
{
    private var _vector:*;

    public function VectorUtil(vector:*)
    {
        _vector = vector;
    }

    public function toArray():Array
    {
        var a:Array = [];
        for (var i:int = 0; i < _vector.length; ++i)
            a.push(_vector[i]);
        return a;
    }
}
}