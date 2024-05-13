package
{
	import fancy2209.dynamite.HWGraphic;
	import starling.display.Shape;
	import starling.core.Starling;
	import flash.display.Sprite;
	import starling.display.Sprite;

	public class AS3Tess extends starling.display.Sprite
	{
		[Embed(source='../AS3Tess.swf', symbol='inkboardingCircle')]
		public var inkboardingCircleClass:Class;
		private var inkboardingCircleHW:HWGraphic
		private var inkboardingCircleHWShape:starling.display.Shape

		public function AS3Tess()
		{
			super();

			var inkboardingCircle:flash.display.Sprite = new inkboardingCircleClass()
			inkboardingCircle.x = 100
			inkboardingCircle.y = 100
			Starling.current.nativeStage.addChild(inkboardingCircle)
			inkboardingCircleHW = new HWGraphic(inkboardingCircle.graphics.readGraphicsData());
			inkboardingCircleHWShape = inkboardingCircleHW.shape
			inkboardingCircleHWShape.x = 400
			inkboardingCircleHWShape.y = 100
			addChild(inkboardingCircleHWShape)
			}

	}
}
