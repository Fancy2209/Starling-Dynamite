package starling.display.graphics
{
	import flash.geom.Point;
	
	import starling.display.util.MathUtil;
	
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.styles.MeshStyle;
	import starling.textures.Texture;
	
	public class EllipseMesh extends Mesh
	{
		// properties
		protected var _sides:int;

		protected var _colour:uint;

		protected var _radiusX:Number;
		protected var _radiusY:Number;
		
		protected var _maxAngle:Number;
		protected var _reverse:Boolean;
		
		protected static var __vertexData:VertexData
		protected static var __indexData:IndexData

		protected static var meshTexture:Texture;
		protected static var ratioX:Number = 1, ratioY:Number = 1, uvX:Number, uvY:Number;

		public function EllipseMesh(precision:int = 10,
									radiusX:Number = 100,
									radiusY:Number = 100,
									colour:uint = 0,
									meshTexture:Texture = null,
									angle:Number = Math.PI * 2,
									drawReverse:Boolean = false)
		{
			_sides = precision;
			_radiusX = radiusX;
			_radiusY = radiusY;
			_colour = colour;

			_maxAngle = angle;
			_reverse = drawReverse;

			pixelSnapping = false;
			
			__vertexData = new VertexData(MeshStyle.VERTEX_FORMAT, _sides + 2);
			__indexData = new IndexData(3 * _sides);
			
			super(__vertexData, __indexData);
			
			texture = meshTexture;
			
			updateVertices()

			vertexData.colorize(colAttr, _colour, 1, 0, _sides + 2);
			
			__vertexData = null;
			__indexData = null;
		}

		public function set radiusX(val:Number):void
		{
			if (_radiusX != val)
			{
				_radiusX = val;
				setRequiresRedraw();
			}
		}
		
		public function get radiusX():Number
		{
			return _radiusX;
		}

		public function set radiusY(val:Number):void
		{
			if (_radiusY != val)
			{
				_radiusY = val;
				setRequiresRedraw();
			}
		}

		public function get radiusY():Number
		{
			return _radiusY;
		}

		public function set maxAngle(value:Number):void
		{
			if(_maxAngle != value)
			{
				_maxAngle = value;
				setRequiresRedraw();
			}
		}
		
		public function get maxAngle():Number
		{
			return _maxAngle;
		}
		
		public function set reverse(value:Boolean):void
		{
			if(_reverse != value)
			{
				_reverse = value;
				setRequiresRedraw();
			}
		}
		
		public function get reverse():Boolean
		{
			return _reverse;
		}

		public function set colour(val:uint):void
		{
			if(_colour != val)
			{
				_colour = val;
				setRequiresRedraw();
			}
		}

		public function get colour():uint
		{
			return _colour;
		}
		
		protected static var colAttr:String = "color";
		
		override public function setRequiresRedraw():void
		{
			vertexData.colorize(colAttr, _colour, 1, 0, _sides + 2);
			super.setRequiresRedraw();
		}
		
		override public function set texture(value:Texture):void
		{
			super.texture = value;
			
			if(texture)
			{
				texture.setTexCoords(vertexData, 0, texAttr, 1, 1);
			}
			
			setRequiresRedraw();
		}

		protected static var i:int, len:int, fX:Number, fY:Number;

		protected static var iNumVert:int;

		protected static var posAttr:String = "position";
		protected static var texAttr:String = "texCoords";

		protected static var iData:IndexData;
		protected static var vData:VertexData;
		
		protected static var ellipsePoint:Point = new Point();
		protected static var angleIncrement:Number;
		protected static var currentAngle:Number;
		protected static var halfSides:Number;

		protected function updateVertices():void
		{
			iNumVert = 0;

			vData = vertexData;
			meshTexture = texture;

			// centre
			vData.setPoint(0, posAttr, 0, 0);
			
			
			iNumVert++;

			halfSides = _sides / 2;
			angleIncrement = _maxAngle / _sides;


			if(meshTexture)
			{
				ratioX = 1 / (_radiusX * 2);
				ratioY = 1 / (_radiusY * 2);
				
				meshTexture.setTexCoords(
					vData,
					0,
					texAttr,
					0.5,
					0.5
				);
			}

			if(_reverse)
			{
				currentAngle = Math.PI * 2;
				
				for(i = 0; i <= _sides; i++, currentAngle -= angleIncrement)
				{
					MathUtil.calculateElipsePoint(_radiusX, _radiusY, currentAngle, ellipsePoint);

					if(currentAngle > Math.PI) ellipsePoint.y *= -1;

					vData.setPoint(iNumVert, posAttr, ellipsePoint.x, ellipsePoint.y);
					
					if(meshTexture)
					{
						if(ellipsePoint.x >= 0)
						{
							uvX = (ellipsePoint.x * ratioX) + 0.5	
						}
						else
						{
							uvX = 0.5 - (Math.abs(ellipsePoint.x) * ratioX)
						}
						
						if(ellipsePoint.y >= 0)
						{
							uvY = (ellipsePoint.y * ratioY) + 0.5	
						}
						else
						{
							uvY = 0.5 - (Math.abs(ellipsePoint.y) * ratioY)
						}
						
						meshTexture.setTexCoords(
							vData,
							iNumVert,
							texAttr,
							uvX,
							uvY
						);
					}

					iNumVert++;
				}	
			}
			else
			{
				currentAngle = 0;

				for(i = 0; i <= _sides; i++, currentAngle += angleIncrement)
				{
					MathUtil.calculateElipsePoint(_radiusX, _radiusY, currentAngle, ellipsePoint);
					
					if(currentAngle > Math.PI)
					{
						ellipsePoint.y *= -1;
					}

					vData.setPoint(iNumVert, posAttr, ellipsePoint.x, ellipsePoint.y);
					
					if(meshTexture)
					{
						if(ellipsePoint.x >= 0)
						{
							uvX = (ellipsePoint.x * ratioX) + 0.5;
						}
						else
						{
							uvX = 0.5 - (Math.abs(ellipsePoint.x) * ratioX)
						}
						
						if(ellipsePoint.y >= 0)
						{
							uvY = (ellipsePoint.y * ratioY) + 0.5;
						}
						else
						{
							uvY = 0.5 - (Math.abs(ellipsePoint.y) * ratioY)
						}
						
						meshTexture.setTexCoords(
							vData,
							iNumVert,
							texAttr,
							uvX,
							uvY
						);
					}
					
					iNumVert++;
				}		
			}
	
			iData = indexData;
			
			iData.numIndices = 0;
			vData.numVertices = iNumVert;
			
			for(i = 0, len = iNumVert - 2; i < len; i++)
			{				
				iData.addTriangle(0, i + 1, i + 2);
			}
			
			vData = null;
			iData = null;
		}
	}
}