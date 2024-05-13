package starling.display.graphics
{
	import flash.geom.Point;
	
	import starling.display.util.MathUtil;
	
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.styles.MeshStyle;
	import starling.textures.Texture;
	
	public class RoundRectangleMesh extends Mesh
	{
		// properties
		
		protected var _rectangleWidth:Number;
		protected var _rectangleHeight:Number;
		
		protected var _cornerRadius:Number;
		protected var _cornerRadiusPrecision:Number;
		
		protected var _colour:uint;
		
		private static var __vertexData:VertexData
		private static var __indexData:IndexData
		
		public function RoundRectangleMesh(rectWidth:Number = 100,
										   rectHeight:Number = 100,
										   rectCornerRadius:Number = 25,
										   rectCornerRadiusPrecision:Number = 50,
										   colour:uint = 0,
										   meshTexture:Texture = null)
		{
			
			_rectangleWidth = rectWidth;
			_rectangleHeight = rectHeight;
			
			_cornerRadius = validateCornerRadius(rectCornerRadius);
			
			_cornerRadiusPrecision = rectCornerRadiusPrecision;
			
			_colour = colour;
			
			pixelSnapping = true;
			
			__vertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 4 * _cornerRadiusPrecision);
			__indexData = new IndexData(4 * _cornerRadiusPrecision);
			
			super(__vertexData, __indexData);
			
			texture = meshTexture;

			updateVertices()
			
			vertexData.colorize(colAttr, _colour, 1, 0, -1);

			__vertexData = null;
			__indexData = null;
		}
		
		protected function validateCornerRadius(value:Number):Number
		{
			return Math.min(
				value,
				Math.min(_rectangleWidth, _rectangleHeight) / 2
			);
		}
		
		public function set cornerRadius(val:Number):void
		{
			if (_cornerRadius != val)
			{
				_cornerRadius = validateCornerRadius(val);
				setRequiresRedraw();
			}
		}
		
		public function set cornerRadiusPrecision(val:Number):void
		{
			if (_cornerRadiusPrecision != val)
			{
				_cornerRadiusPrecision = val;
				setRequiresRedraw();
			}
		}
		
		public function set rectangleWidth(val:Number):void
		{
			if (_rectangleWidth != val)
			{
				_rectangleWidth = val;
				setRequiresRedraw();
			}
		}
		
		public function set rectangleHeight(val:Number):void
		{
			if (_rectangleHeight != val)
			{
				_rectangleHeight = val;
				setRequiresRedraw();
			}
		}
		
		public function set colour(val:uint):void
		{
			if(_colour != val)
			{
				_colour = val;
				setRequiresRedraw();
			}
		}
		
		override public function setRequiresRedraw():void
		{
			vertexData.colorize(colAttr, _colour, 1, 0, -1);
			
			super.setRequiresRedraw();
		}
		
		private static var colAttr:String = "color";
		
		protected static var i:int, len:int;
		
		protected var verticeCount:int;
		
		protected static var posAttr:String = "position";
		protected static var texAttr:String = "texCoords";
		
		protected static var vData:VertexData;
		protected static var iData:IndexData;
		
		protected static var anglePoint:Point = new Point();
		protected static var texturePoint:Point = new Point();
		
		protected static var angleIncrement:Number;
		protected static var currentAngle:Number;
		protected static var halfSides:Number;
		
		protected static var halfWidth:Number;
		protected static var halfHeight:Number;
		
		protected static var cornerRadiusStart:Point = new Point();
		
		protected static var cornerCenterX:Number;
		protected static var cornerCenterY:Number;
		protected static var meshTexture:Texture;
		protected static var ratioX:Number = 1, ratioY:Number = 1;
		
		protected function updateVertices():void
		{
			verticeCount = 0;
			
			vData = vertexData;
			
			halfWidth = _rectangleWidth * 0.5;
			halfHeight = _rectangleHeight * 0.5;
			
			cornerRadiusStart.x = halfWidth - _cornerRadius;
			cornerRadiusStart.y = halfHeight - _cornerRadius;
			
			vData.setPoint(0, posAttr, 0, 0);
			
			meshTexture = texture;
			
			if(meshTexture)
			{
				meshTexture.setTexCoords(vData, 0, texAttr, 0.5, 0.5);
			}
			
			verticeCount++;
			
			angleIncrement = (90 / _cornerRadiusPrecision) * MathUtil.DEG_TO_RAD;
			currentAngle = 0;
			
			if(meshTexture)
			{
				ratioX = 1 / _rectangleWidth;
				ratioY = 1 / _rectangleHeight;
			}

			// bottom right corner
			for(i = 0; i <_cornerRadiusPrecision; i++, currentAngle += angleIncrement)
			{
				MathUtil.calculateAnglePoint(cornerRadiusStart.x, cornerRadiusStart.y, _cornerRadius, currentAngle, anglePoint);
				
				vData.setPoint(verticeCount, posAttr, anglePoint.x, anglePoint.y);
				
				if(meshTexture)
				{
					meshTexture.setTexCoords(
						vData,
						verticeCount,
						texAttr, (anglePoint.x * ratioX) + 0.5, (anglePoint.y * ratioY) + 0.5);
				}
				
				verticeCount++;
			}
			
			
			
			anglePoint.x = halfWidth - _cornerRadius;
			anglePoint.y = halfHeight;
			
			vData.setPoint(verticeCount, posAttr, anglePoint.x, anglePoint.y);
			
			if(meshTexture)
			{
				meshTexture.setTexCoords(
					vData,
					verticeCount,
					texAttr,
					(anglePoint.x * ratioX) + 0.5,
					(anglePoint.y * ratioY) + 0.5
				);
			}
			
			verticeCount++;
			
			cornerCenterX = cornerRadiusStart.x * -1;
			currentAngle = Math.PI / 2;
			
			// bottom left corner
			for(i = 0; i < _cornerRadiusPrecision; i++, currentAngle += angleIncrement)
			{
				MathUtil.calculateAnglePoint(cornerCenterX, cornerRadiusStart.y, _cornerRadius, currentAngle, anglePoint);
				
				vData.setPoint(verticeCount, posAttr, anglePoint.x, anglePoint.y);
				
				if(meshTexture)
				{
					meshTexture.setTexCoords(
						vData,
						verticeCount,
						texAttr,
						0.5 - (Math.abs(anglePoint.x) * ratioX),
						(anglePoint.y * ratioY) + 0.5
					);
				}
				
				verticeCount++;
			}
			
			anglePoint.x = halfWidth * -1;
			anglePoint.y = halfHeight - _cornerRadius;
			
			vData.setPoint(verticeCount, posAttr, anglePoint.x, anglePoint.y);
			
			if(meshTexture)
			{
				meshTexture.setTexCoords(
					vData,
					verticeCount,
					texAttr,
					0.5 - Math.abs(anglePoint.x * ratioX),
					(anglePoint.y * ratioY) + 0.5
				);
			}
			
			verticeCount++;
			
			cornerCenterY = cornerRadiusStart.y * -1
			currentAngle = Math.PI;
			
			// top left corner
			for(i = 0; i < _cornerRadiusPrecision; i++, currentAngle += angleIncrement)
			{
				MathUtil.calculateAnglePoint(cornerCenterX, cornerCenterY, _cornerRadius, currentAngle, anglePoint);
				
				vData.setPoint(verticeCount, posAttr, anglePoint.x, anglePoint.y);
				
				if(meshTexture)
				{
					meshTexture.setTexCoords(
						vData,
						verticeCount,
						texAttr,
						0.5 - Math.abs(anglePoint.x * ratioX),
						0.5 - Math.abs(anglePoint.y * ratioY)
					);
				}

				verticeCount++;
			}

			vData.setPoint(verticeCount, posAttr, cornerCenterX, halfHeight * -1);
			
			if(meshTexture)
			{
				meshTexture.setTexCoords(
					vData,
					verticeCount,
					texAttr,
					0.5 - Math.abs(cornerCenterX * ratioX),
					0
				);
			}
			
			verticeCount++;
			
			cornerCenterX = cornerRadiusStart.x;
			currentAngle = 270 * MathUtil.DEG_TO_RAD;
			
			// top right corner
			for(i = 0; i < _cornerRadiusPrecision; i++, currentAngle += angleIncrement)
			{
				MathUtil.calculateAnglePoint(cornerRadiusStart.x, cornerCenterY, _cornerRadius, currentAngle, anglePoint);
				
				vData.setPoint(verticeCount, posAttr, anglePoint.x, anglePoint.y);
				
				if(meshTexture)
				{
					meshTexture.setTexCoords(
						vData,
						verticeCount,
						texAttr,
						(anglePoint.x * ratioX) + 0.5,
						0.5 - Math.abs(anglePoint.y * ratioY)
					);
				}
				
				verticeCount++;
			}			

			anglePoint.y = (halfHeight - _cornerRadius) * -1;
			
			vData.setPoint(verticeCount, posAttr, halfWidth, anglePoint.y);
			
			if(meshTexture)
			{
				meshTexture.setTexCoords(
					vData,
					verticeCount,
					texAttr,
					1,
					0.5 - Math.abs(anglePoint.y * ratioY) 
				);
			}
			
			verticeCount++;
			
			iData = indexData;
			
			iData.numIndices = 0;
			vData.numVertices = verticeCount;
			
			for(i = 0, len = verticeCount - 2; i < len; i++)
			{				
				iData.addTriangle(0, i + 1, i + 2);
			}
			
			iData.addTriangle(0, i + 1, 1);
			
			vData = null;
			iData = null;
		}
	}
}