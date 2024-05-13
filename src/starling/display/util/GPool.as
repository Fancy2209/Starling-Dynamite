package starling.display.util
{
	public class GPool
	{
		private static  var _numberVectorPool:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;
		
		public function GPool()
		{
		}

		private static var numberVector:Vector.<Number>;

		public static function getNumberVector():Vector.<Number>
		{
			if(_numberVectorPool.length > 0)
			{
				return _numberVectorPool.pop();
			}
			else
			{
				return new Vector.<Number>;
			}
		}

		public static function putNumberVector(vector:Vector.<Number>):void
		{
			if (vector) _numberVectorPool[_numberVectorPool.length] = vector;
		}
	}
}