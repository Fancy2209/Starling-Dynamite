package starling.display
{
	import starling.display.Graphics;

	public class Shape extends DisplayObjectContainer
	{
		private var _graphics:Graphics;

		public function Shape()
		{
			_graphics = new Graphics();
			_graphics.container = this;
		}

		public function get graphics():Graphics
		{
			return _graphics;
		}
		
		override public function dispose():void
		{
			_graphics.clear();
			_graphics.container = null;
			_graphics = null;
			
			super.dispose();
		}
	}
}