package
{
	import fancy2209.dynamite.DynamiteCanvas;
	import starling.core.Starling;
	import flash.display.Sprite;
	import starling.display.Sprite;

	public class AS3Tess extends starling.display.Sprite
	{
		[Embed(source='../Away.swf', symbol='Away3D')]
		public var Away3DLogoClass:Class;
		private var Away3DLogoHW:DynamiteCanvas

		public function AS3Tess()
		{
			super();

			var Away3DLogo:flash.display.Sprite = new Away3DLogoClass()
			Away3DLogo.scaleX = Away3DLogo.scaleY = 2
			Away3DLogo.x = 100*8
			Away3DLogo.y = 100*2
			Starling.current.nativeStage.addChild(Away3DLogo)
			Away3DLogoHW = new DynamiteCanvas(Away3DLogo.graphics.readGraphicsData());
			Away3DLogoHW.scaleX = Away3DLogoHW.scaleY = 2
			Away3DLogoHW.x = 100
			Away3DLogoHW.y = 100*2
			addChild(Away3DLogoHW)
			}

	}
}
