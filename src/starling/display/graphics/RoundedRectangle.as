package starling.display.graphics
{
	public class RoundedRectangle extends GraphicRenderer
	{
		private const DEGREES_TO_RADIANS:Number = Math.PI / 180;
		
		private var _width				:Number;
		private var _height				:Number;
		private var _topLeftRadius		:Number;
		private var _topRightRadius		:Number;
		private var _bottomLeftRadius	:Number;
		private var _bottomRightRadius	:Number;
		private var strokePoints		:Vector.<Number>;
		private var _radiusPrecision:uint;

		public function RoundedRectangle( width:Number = 100,
										  height:Number = 100,
										  topLeftRadius:Number = 10, 
										  topRightRadius:Number = 10,
										  bottomLeftRadius:Number = 10,
										  bottomRightRadius:Number = 10,
										  cornerRadiusPrecision:uint = 20
										)
		{
			this.width = width;
			this.height = height;
			this.topLeftRadius = topLeftRadius;
			this.topRightRadius = topRightRadius;
			this.bottomLeftRadius = bottomLeftRadius;
			this.bottomRightRadius = bottomRightRadius;
			this.radiusPrecision = cornerRadiusPrecision;
			
			strokePoints = new Vector.<Number>();
			vertices = new Vector.<Number>();
			indices = new Vector.<uint>();
		}
				
		public function get radiusPrecision():Number
		{
			return _radiusPrecision;
		}
		
		public function set radiusPrecision(value:Number):void
		{
			_radiusPrecision = value < 3 ? 3 : value;
			setGeometryInvalid();
		}

		override public function set width(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_width = value;
			maxBounds.x = _width;
			setGeometryInvalid();
		}

		override public function get height():Number
		{
			return _height;
		}

		override public function set height(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_height = value;
			maxBounds.y = _height;
			setGeometryInvalid();
		}

		public function get cornerRadius():Number
		{
			return _topLeftRadius;
		}
		
		public function set cornerRadius(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_topLeftRadius = _topRightRadius = _bottomLeftRadius = _bottomRightRadius = value;
			setGeometryInvalid();
		}
		
		public function get topLeftRadius():Number
		{
			return _topLeftRadius;
		}
		
		public function set topLeftRadius(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_topLeftRadius = value;
			setGeometryInvalid();
		}
		
		public function get topRightRadius():Number
		{
			return _topRightRadius;
		}
		
		public function set topRightRadius(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_topRightRadius = value;
			setGeometryInvalid();
		}
		
		public function get bottomLeftRadius():Number
		{
			return _bottomLeftRadius;
		}
		
		public function set bottomLeftRadius(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_bottomLeftRadius = value;
			setGeometryInvalid();
		}
		
		public function get bottomRightRadius():Number
		{
			return _bottomRightRadius;
		}
		
		public function set bottomRightRadius(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_bottomRightRadius = value;
			setGeometryInvalid();
		}
		
		public function getStrokePoints():Vector.<Number>
		{
			validateNow();
			return strokePoints;
		}
		
		private static var halfWidth:Number;
		private static var halfHeight:Number;
		private static var tlr:Number;
		private static var trr:Number;
		private static var blr:Number;
		private static var brr:Number;
		private static var numVertices:int;
		
		private static var i:int;
		
		private static var radians:Number;
		private static var sin:Number;
		private static var cos:Number;
		private static var xPos:Number;
		private static var yPos:Number;
		
		private static var vertexCount:uint;
		private static var indicesCount:uint;
		private static var strokePointCount:uint;

		override protected function buildGeometry():void
		{
			strokePoints.length = 0;
			vertices.length = 0;
			indices.length = 0;
			
			halfWidth = _width * 0.5;
			halfHeight = _height * 0.5;
			
			tlr = Math.min(halfWidth, halfHeight, _topLeftRadius);
			trr = Math.min(halfWidth, halfHeight, _topRightRadius);
			blr = Math.min(halfWidth, halfHeight, _bottomLeftRadius);
			brr = Math.min(halfWidth, halfHeight, _bottomRightRadius);
			
			vertexCount = 0;

			vertices[vertexCount++] = tlr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = tlr/_width;
			vertices[vertexCount++] = 0;
			
			
			vertices[vertexCount++] = tlr;
			vertices[vertexCount++] = tlr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = tlr/_width;
			vertices[vertexCount++] = tlr/_height;
			
			
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = tlr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = tlr/_height;
			
			vertices[vertexCount++] = _width-trr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = (_width-trr)/_width;
			vertices[vertexCount++] = 0;
			
			
			vertices[vertexCount++] = _width-trr;
			vertices[vertexCount++] = trr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = (_width-trr)/_width;
			vertices[vertexCount++] = trr/_height;
			
			vertices[vertexCount++] = _width;
			vertices[vertexCount++] = trr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = trr/_height;
			
			vertices[vertexCount++] = blr;
			vertices[vertexCount++] = _height;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = blr/_width;
			vertices[vertexCount++] = 1;
			
			vertices[vertexCount++] = blr;
			vertices[vertexCount++] = _height-blr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = blr/_width;
			vertices[vertexCount++] = (_height-blr)/_height;
			
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = _height-blr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = (_height-blr)/_height;
			
			vertices[vertexCount++] = _width-brr;
			vertices[vertexCount++] = _height;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = (_width-brr)/_width;
			vertices[vertexCount++] = 1;
			
			vertices[vertexCount++] = _width-brr;
			vertices[vertexCount++] = _height-brr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = (_width-brr)/_width;
			vertices[vertexCount++] = (_height-brr)/_height;
			
			vertices[vertexCount++] = _width;
			vertices[vertexCount++] = _height-brr;
			vertices[vertexCount++] = 0;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = 1;
			vertices[vertexCount++] = (_height-brr)/_height;
			
			indicesCount = 0
		
			indices[indicesCount++] = 0;
			indices[indicesCount++] = 3;
			indices[indicesCount++] = 1;
			 
			indices[indicesCount++] = 1;
			indices[indicesCount++] = 3;
			indices[indicesCount++] = 4;
			 
			indices[indicesCount++] = 2;
			indices[indicesCount++] = 1;
			indices[indicesCount++] = 8;
			 
			 
			indices[indicesCount++] = 8;
			indices[indicesCount++] = 1;
			indices[indicesCount++] = 7;
			 
			indices[indicesCount++] = 7;
			indices[indicesCount++] = 1;
			indices[indicesCount++] = 4;
			 
			indices[indicesCount++] = 7;
			indices[indicesCount++] = 4;
			indices[indicesCount++] = 10;
			 
			indices[indicesCount++] = 10;
			indices[indicesCount++] = 4;
			indices[indicesCount++] = 5;
			 
			indices[indicesCount++] = 10;
			indices[indicesCount++] = 5;
			indices[indicesCount++] = 11;
			 
			indices[indicesCount++] = 6;
			indices[indicesCount++] = 7;
			indices[indicesCount++] = 10;
			 
			indices[indicesCount++] = 6;
			indices[indicesCount++] = 10;
			indices[indicesCount++] = 9;

			numVertices = 12;

			strokePointCount = 0;

			strokePoints[strokePointCount++] = 0;
			strokePoints[strokePointCount++] = tlr;

			if ( tlr > 0 )
			{
				for(i = 0; i < _radiusPrecision; i++ )
				{
					radians = ((i+1) / (_radiusPrecision+1)) * Math.PI * 0.5;
					radians += Math.PI * 1.5;
					sin = Math.sin(radians);
					cos = Math.cos(radians);
					xPos = tlr+sin*tlr;
					yPos = tlr-cos*tlr;
					
					vertices[vertexCount++] = xPos;
					vertices[vertexCount++] = yPos;
					vertices[vertexCount++] = 0;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = xPos/_width;
					vertices[vertexCount++] = yPos/_height;

					strokePoints[strokePointCount++] = xPos;
					strokePoints[strokePointCount++] = yPos;

					numVertices++;
					
					if(i == 0)
					{
						indices[indicesCount++] = 1;
						indices[indicesCount++] = 2;
						indices[indicesCount++] = numVertices - 1;
					}
					else
					{
						indices[indicesCount++] = 1;
						indices[indicesCount++] = numVertices - 2;
						indices[indicesCount++] = numVertices - 1;
					}
					
					if(i == _radiusPrecision - 1)
					{
						indices[indicesCount++] = 1;
						indices[indicesCount++] = numVertices - 1;
						indices[indicesCount++] = 0;
					}
				}
			}

			strokePoints[strokePointCount++] = tlr;
			strokePoints[strokePointCount++] = 0;
			
			strokePoints[strokePointCount++] = _width-trr;
			strokePoints[strokePointCount++] = 0;
			
			if ( trr > 0 )
			{
				for ( i = 0; i < _radiusPrecision; i++ )
				{
					radians = ((i+1) / (_radiusPrecision+1)) * Math.PI * 0.5;
					sin = Math.sin(radians);
					cos = Math.cos(radians);
					xPos = _width-trr+sin*trr;
					yPos = trr-cos*trr;

					vertices[vertexCount++] = xPos;
					vertices[vertexCount++] = yPos;
					vertices[vertexCount++] = 0;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = xPos/_width;
					vertices[vertexCount++] = yPos/_height;
					
					strokePoints[strokePointCount++] = xPos;
					strokePoints[strokePointCount++] = yPos;

					numVertices++;
					
					if(i == 0)
					{
						indices[indicesCount++] = 4;
						indices[indicesCount++] = 3;
						indices[indicesCount++] = numVertices-1;
					}
					else
					{
						indices[indicesCount++] = 4;
						indices[indicesCount++] = numVertices - 2;
						indices[indicesCount++] = numVertices - 1;
					}
					
					if(i == _radiusPrecision - 1)
					{
						indices[indicesCount++] = 4;
						indices[indicesCount++] = numVertices - 1;
						indices[indicesCount++] = 5;
					}
				}
			}

			strokePoints[strokePointCount++] = _width;
			strokePoints[strokePointCount++] = trr;
			
			strokePoints[strokePointCount++] = _width;
			strokePoints[strokePointCount++] = _height-brr;
			
			if ( brr > 0 )
			{
				for ( i = 0; i < _radiusPrecision; i++ )
				{
					radians = ((i+1) / (_radiusPrecision+1)) * Math.PI * 0.5;
					radians += Math.PI * 0.5;
					sin = Math.sin(radians);
					cos = Math.cos(radians);
					xPos = _width-brr+sin*brr;
					yPos = _height-brr-cos*brr;
					
					vertices[vertexCount++] = xPos;
					vertices[vertexCount++] = yPos;
					vertices[vertexCount++] = 0;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = xPos/_width;
					vertices[vertexCount++] = yPos/_height;

					strokePoints[strokePointCount++] = xPos;
					strokePoints[strokePointCount++] = yPos;
					
					numVertices++;
					
					if(i == 0)
					{
						indices[indicesCount++] = 10;
						indices[indicesCount++] = 11;
						indices[indicesCount++] = numVertices-1;
					}
					else
					{
						indices[indicesCount++] = 10;
						indices[indicesCount++] = numVertices - 2;
						indices[indicesCount++] = numVertices - 1;
					}
					
					if(i == _radiusPrecision - 1)
					{
						indices[indicesCount++] = 10;
						indices[indicesCount++] = numVertices - 1;
						indices[indicesCount++] = 9;
					}
				}
			}
			
			strokePoints[strokePointCount++] = _width-brr;
			strokePoints[strokePointCount++] = _height;
			
			strokePoints[strokePointCount++] = blr;
			strokePoints[strokePointCount++] = _height;
			
			if ( blr > 0 )
			{
				for ( i = 0; i < _radiusPrecision; i++ )
				{
					radians = ((i+1) / (_radiusPrecision+1)) * Math.PI * 0.5;
					radians += Math.PI;
					sin = Math.sin(radians);
					cos = Math.cos(radians);
					xPos = blr+sin*blr;
					yPos = _height-blr-cos*blr;
					
					vertices[vertexCount++] = xPos;
					vertices[vertexCount++] = yPos;
					vertices[vertexCount++] = 0;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = 1;
					vertices[vertexCount++] = xPos/_width;
					vertices[vertexCount++] = yPos/_height;

					strokePoints[strokePointCount++] = xPos;
					strokePoints[strokePointCount++] = yPos;
					
					numVertices++;
					
					if(i == 0)
					{
						indices[indicesCount++] = 7;
						indices[indicesCount++] = 6;
						indices[indicesCount++] = numVertices-1;
					}
					else
					{
						indices[indicesCount++] = 7;
						indices[indicesCount++] = numVertices-2;
						indices[indicesCount++] = numVertices-1;
					}
					
					if(i == _radiusPrecision-1)
					{
						indices[indicesCount++] = 7;
						indices[indicesCount++] = numVertices - 1;
						indices[indicesCount++] = 8;
					}
				}
			}

			strokePoints[strokePointCount++] = 0;
			strokePoints[strokePointCount++] = _height-blr;
			 
			strokePoints[strokePointCount++] = 0;
			strokePoints[strokePointCount++] = tlr;
		}
	}
}