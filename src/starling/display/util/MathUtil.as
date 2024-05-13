package starling.display.util
{
	import flash.geom.Point;

	public class MathUtil
	{
		public static const RAD_TO_DEG:Number = 180 / Math.PI;
		public static const DEG_TO_RAD:Number = Math.PI / 180;
		public static const FULL_CIRCLE_ANGLE:Number = Math.PI * 2;
		public static const HALF_PI:Number = Math.PI / 2;
		public static const QUARTER_PI:Number = HALF_PI / 2;
		
		public function MathUtil()
		{
		}
		
		
		private static var denominator:Number, a:Number, b:Number, numerator1:Number, numerator2:Number;
		
		public static function calculateLineIntersectionPoint(line1StartX:Number,
															  line1StartY:Number,
															  
															  line1EndX:Number,
															  line1EndY:Number,
															  
															  line2StartX:Number,
															  line2StartY:Number,
															  
															  line2EndX:Number,
															  line2EndY:Number,
															  
															  resultPoint:Point):Boolean
		{
			denominator = ((line2EndY - line2StartY) * (line1EndX - line1StartX)) - ((line2EndX - line2StartX) * (line1EndY - line1StartY));

			if (denominator == 0) return false;
			
			a = line1StartY - line2StartY;
			b = line1StartX - line2StartX;
			
			numerator1 = ((line2EndX - line2StartX) * a) - ((line2EndY - line2StartY) * b);
			numerator2 = ((line1EndX - line1StartX) * a) - ((line1EndY - line1StartY) * b);
			
			a = numerator1 / denominator;
			b = numerator2 / denominator;

			resultPoint.x = line1StartX + (a * (line1EndX - line1StartX));
			resultPoint.y = line1StartY + (a * (line1EndY - line1StartY));
			
			return true;
		}
		
		public static function checkIfLineContainsPoint(startPoint:Point, endPoint:Point, checkPoint:Point):Boolean
		{	
			return ((endPoint.y - startPoint.y) * (checkPoint.x - startPoint.x)).toFixed(0) === ((checkPoint.y - startPoint.y) * (endPoint.x - startPoint.x)).toFixed(0) &&
				((startPoint.x > checkPoint.x && checkPoint.x > endPoint.x) || (startPoint.x < checkPoint.x && checkPoint.x < endPoint.x)) &&
				((startPoint.y >= checkPoint.y && checkPoint.y >= endPoint.y) || (startPoint.y <= checkPoint.y && checkPoint.y <= endPoint.y));
		}

		public static function calculateElipseY(a:Number, b:Number, x:Number):Number
		{
			return b / a * (Math.sqrt(Math.pow(a, 2) - Math.pow(x, 2)));
		}

		public static function calculateElipsePoint(width:Number, height:Number, angle:Number, result:Point):void
		{
			result.x = Math.cos(angle) * width;
			result.y = MathUtil.calculateElipseY(width, height, result.x);
		}

		public static function calculateAnglePoint(centerX:Number, centerY:Number, radius:Number, angle:Number, result:Point):void
		{
			result.x = centerX + (radius * Math.cos(angle));
			result.y = centerY + (radius * Math.sin(angle));
		}
	}
}