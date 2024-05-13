package starling.display.util
{
	import flash.geom.Matrix;
	import flash.geom.Point;

	public class MatrixUtil
	{
		public function MatrixUtil()
		{
		}
		
		public static function transformPoint(matrix:Matrix, point:Point, result:Point):void
		{
			result.x = matrix.a*point.x + matrix.c*point.y + matrix.tx; 
			result.y = matrix.b*point.x + matrix.d*point.y + matrix.ty;
		}
	}
}