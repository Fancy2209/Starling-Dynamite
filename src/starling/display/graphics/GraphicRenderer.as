package starling.display.graphics
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.MyBlendMode;
	import starling.display.materials.IMaterial;
	import starling.display.materials.StandardMaterial;
	import starling.display.util.MatrixUtil;
	import starling.errors.AbstractMethodError;
	import starling.errors.MissingContextError;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.utils.Pool;

	/**
	 * Abstract, do not instantiate directly
	 * Used as a base-class for all the drawing API sub-display objects (Like Fill and Stroke).
	 */
	public class GraphicRenderer extends DisplayObject
	{
		protected static const VERTEX_STRIDE		:int = 9;
		protected static var sHelperMatrix			:Matrix = new Matrix();
		
		protected var _material		:IMaterial;
		
		protected var vertexBuffer	:VertexBuffer3D;
		protected var indexBuffer		:IndexBuffer3D;
		protected var vertices		:Vector.<Number>;
		protected var indices		:Vector.<uint>;
		protected var _uvMatrix		:Matrix;
		protected var isInvalid		:Boolean = false;
		protected var uvsInvalid	:Boolean = false;
		
		protected var hasValidatedGeometry:Boolean = false;
				
		private static var sGraphicHelperRect:Rectangle = new Rectangle();
		private static var sGraphicHelperPoint:Point = new Point();
		
		// Filled-out with min/max vertex positions
		// during addVertex(). Used during getBounds().
		protected var minBounds			:Point;
		protected var maxBounds			:Point;
		
		// used for geometry level hit tests. False gives boundingbox results, True gives geometry level results. 
		// True is a lot more exact, but also slower.
		protected var _precisionHitTest:Boolean = false;
		protected var _precisionHitTestDistance:Number = 0; // This is added to the thickness of the line when doing precisionHitTest to make it easier to hit 1px lines etc
		
		protected var _boundsBuffer:Number = 0;
		protected var _boundsBufferX:Number = 0;
		protected var _boundsBufferY:Number = 0;

		private var _boundsBufferDouble:Number = 0;
		private var _boundsBufferXDouble:Number = 0;
		private var _boundsBufferYDouble:Number = 0;
		
		private static  var _uintVectorPool:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>;
		private static  var _numberVectorPool:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;

		public static function getUintVector():Vector.<uint>
		{
			var vector:Vector.<uint>;
			
			if(_uintVectorPool.length > 0)
			{
				vector = _uintVectorPool.pop();
			}
			else
			{
				vector = new Vector.<uint>;
			}
			
			return vector;
		}
		
		public static function putUintVector(vector:Vector.<uint>):void
		{
			if (vector) _uintVectorPool[_uintVectorPool.length] = vector;
		}

		public static function getNumberVector():Vector.<Number>
		{
			var vector:Vector.<Number>;
			
			if(_numberVectorPool.length > 0)
			{
				vector = _numberVectorPool.pop();
			}
			else
			{
				vector = new Vector.<Number>;
			}
			
			return vector;
		}
		
		public static function putNumberVector(vector:Vector.<Number>):void
		{
			if (vector) _numberVectorPool[_numberVectorPool.length] = vector;
		}
		
		public function GraphicRenderer()
		{
			indices = getUintVector();
			vertices = getNumberVector();

			_material = new StandardMaterial();

			minBounds = Pool.getPoint();
			maxBounds = Pool.getPoint();

			if(Starling.current)
			{
				Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			}
		}

		public function get boundsBuffer():Number
		{
			return _boundsBuffer;
		}
		
		public function set boundsBuffer(value:Number):void
		{
			_boundsBuffer = value;
			_boundsBufferDouble = value * 2;
			
			_boundsBufferX = value;
			_boundsBufferY = value;
			
			_boundsBufferXDouble = _boundsBufferDouble;
			_boundsBufferYDouble = _boundsBufferDouble;
		}

		
		public function get boundsBufferX():Number
		{
			return _boundsBufferX;
		}
		
		public function set boundsBufferX(value:Number):void
		{
			_boundsBufferX = value;
			_boundsBufferXDouble = value * 2;
		}
		
		public function get boundsBufferY():Number
		{
			return _boundsBufferY;
		}
		
		public function set boundsBufferY(value:Number):void
		{
			_boundsBufferY = value;
			_boundsBufferYDouble = value * 2;
		}
		
		public function set material(value:IMaterial):void
		{
			_material = value;
		}
		
		public function get material():IMaterial
		{
			return _material;
		}
		
		public function get uvMatrix():Matrix
		{
			return _uvMatrix;
		}
		
		public function set precisionHitTest(value:Boolean) : void
		{
			_precisionHitTest = value;
		}
		public function get precisionHitTest() : Boolean 
		{
			return _precisionHitTest;
		}
		public function set precisionHitTestDistance(value:Number) : void
		{
			_precisionHitTestDistance = value;
		}
		public function get precisionHitTestDistance() : Number
		{
			return _precisionHitTestDistance;
		}
		

		
		public function set uvMatrix(value:Matrix):void
		{
			_uvMatrix = value;
			uvsInvalid = true;
			hasValidatedGeometry = false;
		}

		
		private function onContextCreated(event:Event):void
		{
			hasValidatedGeometry = false;
			
			isInvalid = true;
			uvsInvalid = true;
			
			if(_material) _material.restoreOnLostContext();

			onGraphicLostContext();
		}
		
		protected function onGraphicLostContext():void
		{
		}
		
		override public function dispose():void
		{
			if(Starling.current)
			{
				Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
				super.dispose();
			}

			if(vertexBuffer)
			{
				vertexBuffer.dispose();
				vertexBuffer = null;
			}
			
			if(indexBuffer)
			{
				indexBuffer.dispose();
				indexBuffer = null;
			}
			
			if(_material)
			{
				material.dispose();
				material = null;
			}

			Pool.putPoint(minBounds);
			Pool.putPoint(maxBounds);

			if(indices)
			{
				indices.length = 0;
				putUintVector(indices);
				indices = null;
			}
			
			if(vertices)
			{
				vertices.length = 0;
				putNumberVector(vertices);
				vertices = null;
			}

			_uvMatrix = null;
			minBounds = null;
			maxBounds = null;

			hasValidatedGeometry = false;
		}

		protected static var shapeHitTestPoint:Point = new Point();
		protected static var shapeHitTestResultPoint:Point = new Point();

		public function shapeHitTest( stageX:Number, stageY:Number ):Boolean
		{
			shapeHitTestPoint.x = stageX;
			shapeHitTestPoint.y = stageY;

			globalToLocal(shapeHitTestPoint, shapeHitTestResultPoint);

			return shapeHitTestResultPoint.x >= minBounds.x && shapeHitTestResultPoint.x <= maxBounds.x && shapeHitTestResultPoint.y >= minBounds.y && shapeHitTestResultPoint.y <= maxBounds.y;
		}
		
		protected function shapeHitTestLocalInternal( localX:Number, localY:Number ):Boolean
		{
			return localX >= (minBounds.x-_precisionHitTestDistance) && 
				   localX <= (maxBounds.x+_precisionHitTestDistance) && 
				   localY >= (minBounds.y-_precisionHitTestDistance) && 
				   localY <= (maxBounds.y+_precisionHitTestDistance);
		}
		
		/** Returns the object that is found topmost beneath a point in local coordinates, or nil if 
         *  the test fails. If "forTouch" is true, untouchable and invisible objects will cause
         *  the test to fail. */
		
       /* override public function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            // on a touch test, invisible or untouchable objects cause the test to fail
            if (forTouch && (visible == false || touchable == false )) return null;
            if ( minBounds == null || maxBounds == null ) return null;
			
			// otherwise, check bounding box
			if (getBounds(this, sGraphicHelperRect).containsPoint(localPoint))
			{
				if ( _precisionHitTest )
				{
					if ( shapeHitTestLocalInternal(localPoint.x, localPoint.y ) )
						return this;
				}
				else
					return this;
			}
				
			return null;
			
        }*/
		
		override public function hitTest(localPoint:Point):DisplayObject
        {
            // on a touch test, invisible or untouchable objects cause the test to fail
            if ((visible == false || touchable == false )) return null;
            if ( minBounds == null || maxBounds == null ) return null;
			
			// otherwise, check bounding box
			if (getBounds(this, sGraphicHelperRect).containsPoint(localPoint))
			{
				if ( _precisionHitTest )
				{
					if ( shapeHitTestLocalInternal(localPoint.x, localPoint.y ) )
						return this;
				}
				else
					return this;
			}
				
			return null;
			
        }
		
		private static var topLeft:Point = new Point();
		private static var topRight:Point = new Point();
		private static var bottomRight:Point = new Point();
		private static var bottomLeft:Point = new Point();
		
		private static var sGraphicHelperPointTR:Point = new Point();
		private static var sGraphicHelperPointBL:Point = new Point();

		override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			if (resultRect == null) 
				resultRect = new Rectangle();
			
			if(targetSpace == this) // optimization
			{
				resultRect.x = minBounds.x;
				resultRect.y = minBounds.y;
				resultRect.right = maxBounds.x;
				resultRect.bottom = maxBounds.y;
				
				if(_precisionHitTest)
				{	
					resultRect.x -= _precisionHitTestDistance;
					resultRect.y -= _precisionHitTestDistance;
					resultRect.width += _precisionHitTestDistance * 2;
					resultRect.height += _precisionHitTestDistance * 2;
				}
				
				resultRect.x -= _boundsBufferX;
				resultRect.y -= _boundsBufferY;

				resultRect.width += _boundsBufferXDouble;
				resultRect.height += _boundsBufferYDouble;
				
				resultRect.right += _boundsBufferXDouble;
				resultRect.bottom += _boundsBufferYDouble;

				return resultRect;
			}
			
			getTransformationMatrix(targetSpace, sHelperMatrix);

			sGraphicHelperPointTR.x = minBounds.x + (maxBounds.x - minBounds.x)
			sGraphicHelperPointTR.y = minBounds.y;
			sGraphicHelperPointBL.x = minBounds.x;
			sGraphicHelperPointBL.y =  minBounds.y + (maxBounds.y - minBounds.y);

			/*
			 * Old version, 2 point allocations
			 * var tr:Point = new Point(minBounds.x + (maxBounds.x - minBounds.x), minBounds.y);
			 * var bl:Point = new Point(minBounds.x , minBounds.y + (maxBounds.y - minBounds.y));
			 */ 
			MatrixUtil.transformPoint(sHelperMatrix, minBounds, topLeft);
			
			MatrixUtil.transformPoint(sHelperMatrix, sGraphicHelperPointTR, topRight);

			MatrixUtil.transformPoint(sHelperMatrix, maxBounds, bottomRight);
			
			MatrixUtil.transformPoint(sHelperMatrix, sGraphicHelperPointBL, bottomLeft);
		
			/*
			 * Old version, 2 point allocations through clone
			 var TL:Point = sHelperMatrix.transformPoint(minBounds.clone());
			 tr = sHelperMatrix.transformPoint(bl);
			 var BR:Point = sHelperMatrix.transformPoint(maxBounds.clone());
			 bl = sHelperMatrix.transformPoint(bl);
			*/
			
			
			resultRect.x = Math.min(topLeft.x, bottomRight.x, topRight.x, bottomLeft.x);
			resultRect.y = Math.min(topLeft.y, bottomRight.y, topRight.y, bottomLeft.y);
			resultRect.right = Math.max(topLeft.x, bottomRight.x, topRight.x, bottomLeft.x);
			resultRect.bottom = Math.max(topLeft.y, bottomRight.y, topRight.y, bottomLeft.y);

			if(_precisionHitTest)
			{
				resultRect.x -= _precisionHitTestDistance;
				resultRect.y -= _precisionHitTestDistance;
				resultRect.width += _precisionHitTestDistance * 2;
				resultRect.height += _precisionHitTestDistance * 2;
			}

			resultRect.x -= _boundsBufferX;
			resultRect.y -= _boundsBufferY;
			
			resultRect.width += _boundsBufferXDouble;
			resultRect.height += _boundsBufferYDouble;
			
			resultRect.right += _boundsBufferXDouble;
			resultRect.bottom += _boundsBufferYDouble;

			return resultRect;
		}
		
		protected function buildGeometry():void
		{
			throw( new AbstractMethodError() );
		}
		
		private static var uvPoint:Point = new Point();
		private static var transformedPoint:Point = new Point();
		private static var i:int;

		protected function applyUVMatrix():void
		{
			if ( !vertices ) return;
			if ( !_uvMatrix ) return;
			
			for(i = 0; i < vertices.length; i += VERTEX_STRIDE)
			{
				uvPoint.x = vertices[i+7];
				uvPoint.y = vertices[i+8];

				MatrixUtil.transformPoint(_uvMatrix, uvPoint, transformedPoint);

				if(_material.texture)
				{
					_material.texture.localToGlobal(transformedPoint.x, transformedPoint.y, transformedPoint);
				}

				vertices[i+7] = transformedPoint.x;
				vertices[i+8] = transformedPoint.y;
			}
		}
		
		public function validateNow():void
		{
			if(hasValidatedGeometry)
			{
				return;				
			}
			
			hasValidatedGeometry = true;
			
			if(vertexBuffer && (isInvalid || uvsInvalid))
			{
				vertexBuffer.dispose();
				indexBuffer.dispose();
			}
			
			if(isInvalid)
			{
				buildGeometry();
				applyUVMatrix();
			}
			else if(uvsInvalid)
			{
				applyUVMatrix();
			}
		}
		
		protected function setGeometryInvalid() : void
		{
			isInvalid = true;
			hasValidatedGeometry = false;
		}
		
		private static var numVertices:int;
		private static var context:Context3D;
		private static var blendFactors:Array;

		override public function render(renderSupport:Painter):void 
		{
			validateNow();

			if(indices == null || indices.length < 3)
			{
				return;
			}

			context = Starling.context;

			renderSupport.excludeFromCache(this);

			if(isInvalid || uvsInvalid)
			{
				// Upload vertex/index buffers.
				numVertices = vertices.length / VERTEX_STRIDE;

				vertexBuffer = context.createVertexBuffer(numVertices, VERTEX_STRIDE);
				vertexBuffer.uploadFromVector(vertices, 0, numVertices)
					
				indexBuffer = context.createIndexBuffer(indices.length);
				indexBuffer.uploadFromVector(indices, 0, indices.length);

				isInvalid = uvsInvalid = false;
			}			

			// always call this method when you write custom rendering code!
			// it causes all previously batched quads/images to render.
			renderSupport.finishMeshBatch();

			if (context == null) throw new MissingContextError();

			blendFactors = MyBlendMode.getBlendFactors(
				blendMode == BlendMode.AUTO ? renderSupport.state.blendMode : this.blendMode,
				true
			);

			context.setBlendFactors(blendFactors[0], blendFactors[1]);

			_material.drawTriangles(
				context,
				renderSupport.state.mvpMatrix3D,
				vertexBuffer,
				indexBuffer,
				parent.alpha
			);

			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);

			context.setBlendFactors(
				Context3DBlendFactor.ONE,
				Context3DBlendFactor.ZERO
			);

			context.setBlendFactors(
				Context3DBlendFactor.ONE,
				Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
			);
		}
	}
}