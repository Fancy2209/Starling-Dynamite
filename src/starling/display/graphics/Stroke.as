package starling.display.graphics
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.display.graphics.StrokeVertex;
	import starling.display.graphics.util.TriangleUtil;
	import starling.display.util.MathUtil;
	import starling.textures.Texture;
	import starling.utils.MatrixUtil;
		
	public class Stroke extends GraphicRenderer
	{
		public static const JOINT_TYPE_MITER:int = 1;
		public static const JOINT_TYPE_BEVEL:int = 2;
		public static const JOINT_TYPE_ROUND:int = 3;
		
		protected static const DEGENERATE_START_VERTICE_TYPE:uint = 1;
		protected static const DEGENERATE_END_VERTICE_TYPE:uint = 2;

		private var _line:Vector.<StrokeVertex>;
		protected var _numVertices:uint;
		
		protected var _jointType:int;
		
		protected static var sCollissionHelper:StrokeCollisionHelper = null;

		public function Stroke()
		{
			clear();
			_jointType = JOINT_TYPE_MITER;
		}
		
		public function set jointType(value:int):void
		{
			_jointType = value;
		}
		
		public function get jointType():int
		{
			return _jointType;
		}

		public function get numVertices():uint
		{
			return _numVertices;
		}
		
		override public function dispose():void
		{
			clear();
			super.dispose();
		}

		public function clear():void
		{
			if(minBounds)
			{
				minBounds.x = minBounds.y = Number.POSITIVE_INFINITY; 
				maxBounds.x = maxBounds.y = Number.NEGATIVE_INFINITY;
			}

			if (_line)
			{
				StrokeVertex.putInstances(_line);
				_line.length = 0;
			}
			else
			{
				_line = new Vector.<StrokeVertex>;			
			}
				
			_numVertices = 0;
			setGeometryInvalid();
		}
		
		private static var lastVertex:StrokeVertex;
		
		public function addDegenerates(destX:Number, destY:Number):void
		{
			// THERE IS ONLY ONE VERTICE SO REPLACE COORDINATES
			if(_numVertices < 2)
			{
				lastVertex = _line[0];
				lastVertex.x = destX;
				lastVertex.y = destY;
				return;
			}

			lastVertex = _line[_numVertices - 1];
			
			// LAST VERTEX IS DEGENERATE. REPLACE IT
			if(lastVertex.degenerate)
			{
				lastVertex.x = destX;
				lastVertex.y = destY;
				return;
			}
			// LAST VERTEX HAS SAME COORDINATES. SKIPPING ADDING DEGENERATE. X
			else if(lastVertex.x == destX  && lastVertex.y == destY)
			{
				return;
			}
			
			addVertexInternal(lastVertex.x, lastVertex.y, 0);
			
			lastVertex = _line[_numVertices - 1];
			lastVertex.degenerate = DEGENERATE_START_VERTICE_TYPE;
			lastVertex.u = 1;
			
			addVertexInternal(destX, destY, 0);
			
			lastVertex = _line[_numVertices - 1];
			
			lastVertex.degenerate = DEGENERATE_END_VERTICE_TYPE;
			lastVertex.u = 1;
		}
		
		protected function setLastVertexAsDegenerate(type:uint):void
		{
			_line[_numVertices-1].degenerate = type;
			_line[_numVertices-1].u = 0.0;
		}
		
		public function lineTo(	x:Number, y:Number, thickness:Number = 1, color:uint = 0xFFFFFF,  alpha:Number = 1) : void
		{
			addVertexInternal(x, y, thickness, color, alpha, color, alpha);
		}
		
		public function moveTo( x:Number, y:Number, thickness:Number = 1, color:uint = 0xFFFFFF, alpha:Number = 1.0 ) : void
		{
			addDegenerates(x, y);
		}
		
		public function modifyVertexPosition(index:int, x:Number, y:Number) : void
		{
			var v:StrokeVertex = _line[index];
			v.x = x;
			v.y = y;
			
			isInvalid = true;
			hasValidatedGeometry = false;
		}
		
	//	[Deprecated(replacement="starling.display.graphics.Stroke.lineTo()")]
		public function addVertex( 	x:Number, y:Number, thickness:Number = 1,
									color0:uint = 0xFFFFFF,  alpha0:Number = 1,
									color1:uint = 0xFFFFFF, alpha1:Number = 1 ):void
		{
			
			addVertexInternal(x, y, thickness, color0, alpha0, color1, alpha1);
		}
		
		private static var u:Number;
		private static var textures:Vector.<Texture>;
		private static var prevVertex:StrokeVertex;
		private static var dx:Number;
		private static var dy:Number;
		private static var d:Number;
		
		private static var r0:Number;
		private static var g0:Number;
		private static var b0:Number;
		private static var r1:Number;
		private static var g1:Number;
		private static var b1:Number;

		private static var v:StrokeVertex;
		private static var previousVertex:StrokeVertex;

		protected function addVertexInternal(x:Number, y:Number, thickness:Number = 1,
											 color0:uint = 0xFFFFFF,  alpha0:Number = 1,
											 color1:uint = 0xFFFFFF, alpha1:Number = 1):void
		{							
							
			// if thickness is 0 than vertice is degenerate
			if(thickness > 0 && _numVertices > 0)
			{
				previousVertex = _line[_numVertices - 1];

				// VERTICE IS SAME AS PREVIOUS VERTICE. SKIP ADDING VERTICE
				if(previousVertex.x == x && previousVertex.y == y)
				{
					return;
				}
			}

			u = 0;

			if(_material.texture && _line.length > 0)
			{
				prevVertex = _line[_line.length - 1];
				dx = x - prevVertex.x;
				dy = y - prevVertex.y;
				d = Math.sqrt(dx*dx+dy*dy);
				u = prevVertex.u + (d / _material.texture.width);
			}
			
			r0 = (color0 >> 16) / 255;
			g0 = ((color0 & 0x00FF00) >> 8) / 255;
			b0 = (color0 & 0x0000FF) / 255;
			r1 = (color1 >> 16) / 255;
			g1 = ((color1 & 0x00FF00) >> 8) / 255;
			b1 = (color1 & 0x0000FF) / 255;
			
			v = StrokeVertex.getInstance();

			_line[_numVertices] = v;
			v.x = x;
			v.y = y;
			v.r1 = r0;
			v.g1 = g0;
			v.b1 = b0;
			v.a1 = alpha0;
			v.r2 = r1;
			v.g2 = g1;
			v.b2 = b1;
			v.a2 = alpha1;
			v.u = u;
			v.v = 0;
			v.thickness = thickness;
			v.degenerate = 0;
			_numVertices++;
			
			if(x == 0)
			{
				if(minBounds.x == Number.POSITIVE_INFINITY || minBounds.x == 0)
				{
					minBounds.x = -(thickness*0.5);
				}
				
				if(maxBounds.x == Number.NEGATIVE_INFINITY || maxBounds.x == 0)
				{
					maxBounds.x = thickness*0.5;
				}
			}
			
			if(y == 0)
			{
				if(minBounds.y == Number.POSITIVE_INFINITY || minBounds.y == 0)
				{
					minBounds.y = -(thickness*0.5);	
				}
				
				if(maxBounds.y == Number.NEGATIVE_INFINITY || maxBounds.y == 0)
				{
					maxBounds.y = thickness*0.5;	
				}
			}

			if(x < minBounds.x) 
			{
				minBounds.x = x;
			}
			else if(x > maxBounds.x)
			{
				maxBounds.x = x;
			}
			
			if(y < minBounds.y)
			{
				minBounds.y = y;
			}
			else if(y > maxBounds.y)
			{
				maxBounds.y = y;
			}			
			
			if ( maxBounds.x == Number.NEGATIVE_INFINITY )
				maxBounds.x = x;
			if ( maxBounds.y == Number.NEGATIVE_INFINITY )	
				maxBounds.y = y;
			
			isInvalid = true;
			hasValidatedGeometry = false;
		}
		
		
		public function getVertexPosition(index:int, prealloc:Point = null):Point
		{
			var point:Point = prealloc;
			if ( point == null ) 
				point = new Point();
				
			point.x = _line[index].x;
			point.y = _line[index].y;
			return point;
		}
		
		override protected function buildGeometry():void
		{
			//buildGeometryOriginal();
			buildGeometryPreAllocatedVectors();
		}
		
		protected function buildGeometryOriginal() : void
		{
			if ( _line == null || _line.length == 0 )
				return; // block against odd cases.
				
			// This is the original (slower) code that does not preallocate the vectors for vertices and indices.	
			vertices.length = 0;
			indices.length = 0;
				
			var indexOffset:int = 0;
					
			var oldVerticesLength:int = vertices.length;
			var oneOverVertexStride:Number = 1 / VERTEX_STRIDE;	
			
			_numVertices = _line.length;

			createPolyLine( _line, vertices, indices, indexOffset);
			indexOffset += (vertices.length - oldVerticesLength) * oneOverVertexStride;
		}
		
		protected function buildGeometryPreAllocatedVectors() : void
		{
			if( _line == null || _line.length == 0 )
			{
				return; // block against odd cases.
			}

			_numVertices = _line.length;

			vertices.length = 0;
			indices.length = 0;
			
			createPolyLinePreAlloc( _line, vertices, indices, _jointType);	
		}
		
		
		private static const MIN_ANGLE_BUFFER:Number = 0.00000000005;

		private static var vertCounter:int;
		private static var indiciesCounter:int;
		private static var isFirstVertice:Boolean, isMiddleVertice:Boolean, isLastVertice:Boolean;
		
		private static var numVertices:int, lastVerticeIndex:int;
		
		private static var d0:Number;
		private static var d1:Number;
		
		private static var halfLineThickness:Number, verticeAngle:Number, nextVerticeAngle:Number, pointAngle:Number, 
						   nextPointAngle:Number, angleCos:Number, angleSin:Number, isAngleSwitched:Boolean;
						   
		private static var angleBetweenLines:Number
						   
		private static var startAngleVertice:StrokeVertex;
		private static var previousVertice:StrokeVertex;
		private static var currentVertice:StrokeVertex;
		private static var nextVertice:StrokeVertex;

		private static var dAx:Number;
		private static var dAy:Number;
		private static var dBx:Number;
		private static var dBy:Number;

		private static var cnx:Number;
		private static var cny:Number;

		
		private static var startX:Number;
		private static var startY:Number;
		private static var startNegativeX:Number;
		private static var startNegativeY:Number;

		private static var endX:Number;
		private static var endY:Number;
		private static var endNegativeX:Number;
		private static var endNegativeY:Number;
		
		
		private static var nextStartX:Number;
		private static var nextStartY:Number;
		private static var nextStartNegativeX:Number;
		private static var nextStartNegativeY:Number;

		private static var nextEndX:Number;
		private static var nextEndY:Number;
		private static var nextEndNegativeX:Number;
		private static var nextEndNegativeY:Number;
		
		
		
		private static var prevVerticeAngle:Number;
		private static var angleDifference:Number;
		
		private static var indiceIndex:int, sharedIndice1:int, sharedIndice2:int;
		
		private static var i:int, c:int, clen:int;
		private static var degenerateIndex:int = 0;

		private static var dot:Number;
		private static var arcCosDot:Number;
		
		private static var intersectionPoint:Point = new Point();
		
		private static var doesTopIntersect:Boolean, doesBottomIntersect:Boolean, hasIntersection:Boolean;
		
		private static var topLineIntersectResult:Point = new Point();
		private static var bottomLineIntersectResult:Point = new Point();
		
		private static var isClockWise:Boolean;
		private static var canCalculateAngleBetweenLines:Boolean;
		private static var isSharpAngle:Boolean;
		private static var absAngle:Number;
		
		private static var isPreviousVerticeJoint:Boolean;

		private static var intersectPointX:Number,
						   intersectPointY:Number,
						   
						   intersectPointBottomX:Number,
						   intersectPointBottomY:Number,

						   jointBPointX:Number,
						   jointBPointY:Number,
						   
						   jointCPointX:Number,
						   jointCPointY:Number;
		
		private static var intersectionBPointAngle:Number,
						   intersectionCPointAngle:Number,
						   intersectionAngleDifference:Number, 
						   intersectionBPointAngleIncrement:Number;

		private static var isAngleTooSteepForLineThickness:Boolean;

		private static const ROUND_JOINT_MINIMUM_POINTS:int = 12;
		private static const ROUND_JOINT_MAXIMUM_POINTS:int = 88;
		
		private static var pointAIndiceIndex:int, pointBIndiceIndex:int, roundJointPointCount:int, roundJointIndiceIndex:int;
		
		private static var roundJointRadius:Number, roundJointRadiusCenterX:Number, roundJointRadiusCenterY:Number, miterIntersectionLength:Number;

		private static var isMiterJointBeveled:Boolean, miterJointBAngle:Number, miterJointCAngle:Number;

		///////////////////////////////////
		// Static helper methods
		///////////////////////////////////
		[inline]
		protected static function createPolyLinePreAlloc(strokeData:Vector.<StrokeVertex>, 
														 vertices:Vector.<Number>, 
														 indices:Vector.<uint>,
														 jointType:int):void 
		{
		
			numVertices = strokeData.length;
			lastVerticeIndex = numVertices - 1;

			vertCounter = 0;
			indiciesCounter = 0;
			
			startAngleVertice = null;
			previousVertice = null;

			isFirstVertice = false;
			isLastVertice = false;
			isPreviousVerticeJoint = false;

			verticeAngle = prevVerticeAngle = 0;

			indiceIndex = 0;
			degenerateIndex = 0;

			for(i = 0; i < numVertices; i++, degenerateIndex++)
			{
				currentVertice = strokeData[i];

				if(currentVertice.degenerate)
				{
					if(currentVertice.degenerate == DEGENERATE_START_VERTICE_TYPE)
					{
						previousVertice = null;
						startAngleVertice = null;
						prevVertex = null;
						nextVertice = null;
						isAngleSwitched = false;
						verticeAngle = prevVerticeAngle = 0;
						
						prevVerticeAngle = 0;
						startX = 0;
						startY = 0;
						
						startNegativeX = 0;
						startNegativeY = 0;
						continue;
					}

					if(i == lastVerticeIndex) break;

					isFirstVertice = true;
					isLastVertice = false;
					canCalculateAngleBetweenLines = false;
					degenerateIndex = 0;
				}
				else
				{
					// vertice is not degenerate and has same coordinates as previous vertice so skip it.
					// edge case when moveTo(0, 0,); lineTo(0, 0) or lineTo(100, 100), lineTo(100, 100);
					
					if(previousVertice && currentVertice.x == previousVertice.x && currentVertice.y == previousVertice.y)
					{
						continue;
					}
					
					
					isFirstVertice = degenerateIndex == 0;
					isLastVertice = i == lastVerticeIndex;
					canCalculateAngleBetweenLines = degenerateIndex > 1;
				}

				nextVertice = i+1 < numVertices ? strokeData[i+1] : null;
				
				if(nextVertice && nextVertice.degenerate)
				{
					isLastVertice = nextVertice.degenerate == DEGENERATE_START_VERTICE_TYPE;
				}

				isMiddleVertice = !isFirstVertice && !isLastVertice;

				startAngleVertice = canCalculateAngleBetweenLines ? strokeData[i-2] : null;

				if(!currentVertice.degenerate) halfLineThickness = currentVertice.thickness * 0.5;
					

				// calculate start line with previous angle
				if(!isFirstVertice)
				{
					pointAngle = verticeAngle + MathUtil.HALF_PI;
					angleCos = Math.cos(pointAngle);
					angleSin = Math.sin(pointAngle);
					
					endX = currentVertice.x + (halfLineThickness * angleCos);
					endY = currentVertice.y + (halfLineThickness * angleSin);
					
					pointAngle = verticeAngle - MathUtil.HALF_PI;
					angleCos = Math.cos(pointAngle);
					angleSin = Math.sin(pointAngle);
					
					endNegativeX = currentVertice.x + (halfLineThickness * angleCos);
					endNegativeY = currentVertice.y + (halfLineThickness * angleSin);
				}
				
				if(!isLastVertice)
				{
					cnx = nextVertice.x - currentVertice.x;
					cny = nextVertice.y - currentVertice.y;

					verticeAngle =  Math.atan2(cny, cnx);
				}
				
				// start line with new angle
				pointAngle = verticeAngle + MathUtil.HALF_PI;
				angleCos = Math.cos(pointAngle);
				angleSin = Math.sin(pointAngle);
				
				nextStartX = currentVertice.x + (halfLineThickness * angleCos);
				nextStartY = currentVertice.y + (halfLineThickness * angleSin);
				
				
				pointAngle = verticeAngle - MathUtil.HALF_PI;
				angleCos = Math.cos(pointAngle);
				angleSin = Math.sin(pointAngle);
				
				nextStartNegativeX = currentVertice.x + (halfLineThickness * angleCos);
				nextStartNegativeY = currentVertice.y + (halfLineThickness * angleSin);
				
				angleDifference = prevVerticeAngle - verticeAngle;
				angleDifference = angleDifference < 0 ? -angleDifference : angleDifference; // absolute value

				if(isMiddleVertice && angleDifference != 0 && angleDifference > MIN_ANGLE_BUFFER)
				{
					pointAngle = verticeAngle + MathUtil.HALF_PI;
					angleCos = Math.cos(pointAngle);
					angleSin = Math.sin(pointAngle);

					nextEndX = nextVertice.x + (halfLineThickness * angleCos);
					nextEndY = nextVertice.y + (halfLineThickness * angleSin);

					pointAngle = verticeAngle - MathUtil.HALF_PI;
					angleCos = Math.cos(pointAngle);
					angleSin = Math.sin(pointAngle);

					nextEndNegativeX = nextVertice.x + (halfLineThickness * angleCos);
					nextEndNegativeY = nextVertice.y + (halfLineThickness * angleSin);

					doesBottomIntersect = MathUtil.calculateLineIntersectionPoint(
						startX,
						startY,
						endX,
						endY,
						nextStartX,
						nextStartY,
						nextEndX,
						nextEndY,
						bottomLineIntersectResult
					);

					doesTopIntersect = MathUtil.calculateLineIntersectionPoint(
						startNegativeX,
						startNegativeY,
						endNegativeX,
						endNegativeY,
						nextStartNegativeX,
						nextStartNegativeY,
						nextEndNegativeX,
						nextEndNegativeY,
						topLineIntersectResult
					);

					hasIntersection = doesBottomIntersect || doesTopIntersect;
				}
				else
				{
					hasIntersection = false;
				}

				/***********
				 * 
				 * CREATE VERTICES
				 * 
				 *********/
				
				if(jointType && hasIntersection && isMiddleVertice)
				{
					if(jointType == JOINT_TYPE_MITER)
					{	
						isClockWise = Math.sin(prevVerticeAngle - verticeAngle) > 0;

						// check for clockwise order
						if(isClockWise)
						{	
							jointBPointX = endX;
							jointBPointY = endY;
							
							intersectPointX = topLineIntersectResult.x;
							intersectPointY = topLineIntersectResult.y;
							
							intersectPointBottomX = bottomLineIntersectResult.x;
							intersectPointBottomY = bottomLineIntersectResult.y;
							
							jointCPointX = nextStartX;
							jointCPointY = nextStartY;
							
							miterJointBAngle = prevVerticeAngle;
							miterJointCAngle = verticeAngle + Math.PI;
						}
						else
						{	
							jointBPointX = nextStartNegativeX;
							jointBPointY = nextStartNegativeY;

							intersectPointX = bottomLineIntersectResult.x;
							intersectPointY = bottomLineIntersectResult.y;
							
							intersectPointBottomX = topLineIntersectResult.x;
							intersectPointBottomY = topLineIntersectResult.y;
							
							jointCPointX = endNegativeX;
							jointCPointY = endNegativeY;
							
							miterJointCAngle = prevVerticeAngle;
							miterJointBAngle = verticeAngle - Math.PI;
						}
						
						dAx = intersectPointBottomX - jointBPointX;
						dAy = intersectPointBottomY - jointBPointY;
						
						miterIntersectionLength =  Math.sqrt((dAx*dAx) + (dAy*dAy));
						
						isMiterJointBeveled = miterIntersectionLength > currentVertice.thickness;

						if(isMiterJointBeveled)
						{
							// point B
							vertices[vertCounter++] = jointBPointX + (currentVertice.thickness * Math.cos(miterJointBAngle));
							vertices[vertCounter++] = jointBPointY + (currentVertice.thickness * Math.sin(miterJointBAngle));
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 1;

							// point A
							vertices[vertCounter++] = intersectPointX;
							vertices[vertCounter++] = intersectPointY;
							vertices[vertCounter++] = 1;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 0;
							
							// point C
							vertices[vertCounter++] = jointCPointX + (currentVertice.thickness * Math.cos(miterJointCAngle));
							vertices[vertCounter++] = jointCPointY + (currentVertice.thickness * Math.sin(miterJointCAngle));
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 0;
						}
						else
						{
							// point A
							vertices[vertCounter++] = bottomLineIntersectResult.x;
							vertices[vertCounter++] = bottomLineIntersectResult.y;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 1;
							
							// point B
							vertices[vertCounter++] = topLineIntersectResult.x;
							vertices[vertCounter++] = topLineIntersectResult.y;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 0;	
						}
					}
					else if(jointType == JOINT_TYPE_BEVEL || jointType == JOINT_TYPE_ROUND)
					{
						isClockWise = Math.sin(prevVerticeAngle - verticeAngle) > 0;

						// check for clockwise order
						if(isClockWise)
						{
							jointBPointX = endX;
							jointBPointY = endY;

							intersectPointX = topLineIntersectResult.x;
							intersectPointY = topLineIntersectResult.y;
							
							jointCPointX = nextStartX;
							jointCPointY = nextStartY;
						}
						else
						{
							jointBPointX = nextStartNegativeX;
							jointBPointY = nextStartNegativeY;
							
							intersectPointX = bottomLineIntersectResult.x;
							intersectPointY = bottomLineIntersectResult.y;
							
							jointCPointX = endNegativeX;
							jointCPointY = endNegativeY;
						}

						// point B
						vertices[vertCounter++] = jointBPointX;
						vertices[vertCounter++] = jointBPointY;
						vertices[vertCounter++] = 0;
						vertices[vertCounter++] = currentVertice.r1;
						vertices[vertCounter++] = currentVertice.g1;
						vertices[vertCounter++] = currentVertice.b1;
						vertices[vertCounter++] = currentVertice.a1;
						vertices[vertCounter++] = currentVertice.u;
						vertices[vertCounter++] = 1;

						// point A
						vertices[vertCounter++] = intersectPointX;
						vertices[vertCounter++] = intersectPointY;
						vertices[vertCounter++] = 0;
						vertices[vertCounter++] = currentVertice.r1;
						vertices[vertCounter++] = currentVertice.g1;
						vertices[vertCounter++] = currentVertice.b1;
						vertices[vertCounter++] = currentVertice.a1;
						vertices[vertCounter++] = currentVertice.u;
						vertices[vertCounter++] = 0;

						
						if(jointType == JOINT_TYPE_ROUND)
						{
							if(isClockWise)
							{
								dAx = jointBPointX - currentVertice.x;
								dAy = jointBPointY - currentVertice.y;
								intersectionBPointAngle = Math.atan2(dAy, dAx);

								dAx = jointCPointX - currentVertice.x;
								dAy = jointCPointY - currentVertice.y;

								intersectionCPointAngle = Math.atan2(dAy, dAx);
							}
							else
							{
								dAx = jointCPointX - currentVertice.x;
								dAy = jointCPointY - currentVertice.y;
								intersectionBPointAngle = Math.atan2(dAy, dAx);

								dAx = jointBPointX - currentVertice.x;
								dAy = jointBPointY - currentVertice.y;

								intersectionCPointAngle = Math.atan2(dAy, dAx);
							}

							roundJointRadius = currentVertice.thickness * 0.5;
							roundJointPointCount = Math.round(roundJointRadius);
							
							
							if(roundJointPointCount > ROUND_JOINT_MAXIMUM_POINTS)
							{
								roundJointPointCount = ROUND_JOINT_MAXIMUM_POINTS;
							}
							else if(roundJointPointCount < ROUND_JOINT_MINIMUM_POINTS)
							{
								roundJointPointCount = ROUND_JOINT_MINIMUM_POINTS;	
							}

							intersectionAngleDifference = Math.abs(intersectionBPointAngle - intersectionCPointAngle) % MathUtil.FULL_CIRCLE_ANGLE;
							intersectionAngleDifference = intersectionAngleDifference > Math.PI ? MathUtil.FULL_CIRCLE_ANGLE - intersectionAngleDifference:intersectionAngleDifference;
							
							intersectionBPointAngleIncrement = Math.abs(intersectionAngleDifference / roundJointPointCount);							
							intersectionBPointAngleIncrement = intersectionBPointAngleIncrement < 0 ? -intersectionBPointAngleIncrement : intersectionBPointAngleIncrement;

							if(isClockWise) roundJointPointCount--;

							if(isClockWise) intersectionBPointAngleIncrement *= -1;

							intersectionBPointAngle += intersectionBPointAngleIncrement;

							roundJointRadiusCenterX = (jointBPointX + jointCPointX) * 0.5;
							roundJointRadiusCenterY = (jointBPointY + jointCPointY) * 0.5;							

							for(c = 0; c < roundJointPointCount; c++, intersectionBPointAngle += intersectionBPointAngleIncrement)
							{
								dBx = currentVertice.x + (roundJointRadius * Math.cos(intersectionBPointAngle));
								dBy = currentVertice.y + (roundJointRadius * Math.sin(intersectionBPointAngle));
								
								// point A
								vertices[vertCounter++] = dBx;
								vertices[vertCounter++] = dBy;
								vertices[vertCounter++] = 0;
								vertices[vertCounter++] = currentVertice.r1;
								vertices[vertCounter++] = currentVertice.g1;
								vertices[vertCounter++] = currentVertice.b1;
								vertices[vertCounter++] = currentVertice.a1;
								vertices[vertCounter++] = currentVertice.u;
								vertices[vertCounter++] = Math.cos(intersectionBPointAngle);
							}
						}

						// point C
						vertices[vertCounter++] = jointCPointX;
						vertices[vertCounter++] = jointCPointY;
						vertices[vertCounter++] = 0;
						vertices[vertCounter++] = currentVertice.r1;
						vertices[vertCounter++] = currentVertice.g1;
						vertices[vertCounter++] = currentVertice.b1;
						vertices[vertCounter++] = currentVertice.a1;
						vertices[vertCounter++] = currentVertice.u;
						vertices[vertCounter++] = 0;
					}
				}
				else
				{
					isSharpAngle = false;

					if(canCalculateAngleBetweenLines)
					{
						dAx = startAngleVertice.x - previousVertice.x;
						dAy = startAngleVertice.y - previousVertice.y;
						dBx = currentVertice.x - previousVertice.x;
						dBy = currentVertice.y - previousVertice.y;
						
						angleBetweenLines = Math.atan2((dAx * dBy) - (dAy * dBx), (dAx * dBx) + (dAy * dBy));
						
						absAngle = angleBetweenLines < 0 ? -angleBetweenLines : angleBetweenLines;
						isSharpAngle = absAngle < MathUtil.HALF_PI;
					}

					if(!jointType)
					{
						if(isFirstVertice)
						{
							vertices[vertCounter++] = nextStartX;
							vertices[vertCounter++] = nextStartY;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r2;
							vertices[vertCounter++] = currentVertice.g2;
							vertices[vertCounter++] = currentVertice.b2;
							vertices[vertCounter++] = currentVertice.a2;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 1;
							
							// right thickness point
							vertices[vertCounter++] = nextStartNegativeX;
							vertices[vertCounter++] = nextStartNegativeY;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 0;
						}
						else
						{
							if(canCalculateAngleBetweenLines && ((isSharpAngle && !isAngleSwitched) || (!isSharpAngle && isAngleSwitched)))
							{
								isAngleSwitched = true;
								vertices[vertCounter++] = endNegativeX;
								vertices[vertCounter++] = endNegativeY;
								vertices[vertCounter++] = 0;
								vertices[vertCounter++] = currentVertice.r2;
								vertices[vertCounter++] = currentVertice.g2;
								vertices[vertCounter++] = currentVertice.b2;
								vertices[vertCounter++] = currentVertice.a2;
								vertices[vertCounter++] = currentVertice.u;
								vertices[vertCounter++] = 1;
								
								// right thickness point
								vertices[vertCounter++] = endX;
								vertices[vertCounter++] = endY;
								vertices[vertCounter++] = 0;
								vertices[vertCounter++] = currentVertice.r1;
								vertices[vertCounter++] = currentVertice.g1;
								vertices[vertCounter++] = currentVertice.b1;
								vertices[vertCounter++] = currentVertice.a1;
								vertices[vertCounter++] = currentVertice.u;
								vertices[vertCounter++] = 0;
							}
							else
							{
								vertices[vertCounter++] = endX;
								vertices[vertCounter++] = endY;
								vertices[vertCounter++] = 0;
								vertices[vertCounter++] = currentVertice.r2;
								vertices[vertCounter++] = currentVertice.g2;
								vertices[vertCounter++] = currentVertice.b2;
								vertices[vertCounter++] = currentVertice.a2;
								vertices[vertCounter++] = currentVertice.u;
								vertices[vertCounter++] = 1;
								
								// right thickness point
								vertices[vertCounter++] = endNegativeX;
								vertices[vertCounter++] = endNegativeY;
								vertices[vertCounter++] = 0;
								vertices[vertCounter++] = currentVertice.r1;
								vertices[vertCounter++] = currentVertice.g1;
								vertices[vertCounter++] = currentVertice.b1;
								vertices[vertCounter++] = currentVertice.a1;
								vertices[vertCounter++] = currentVertice.u;
								vertices[vertCounter++] = 0;
								isAngleSwitched = false;
							}
						}
					}
					else 
					{
						if(!isPreviousVerticeJoint && canCalculateAngleBetweenLines && ((isSharpAngle && !isAngleSwitched) || (!isSharpAngle && isAngleSwitched)))
						{
							isAngleSwitched = true;
							vertices[vertCounter++] = nextStartNegativeX;
							vertices[vertCounter++] = nextStartNegativeY;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r2;
							vertices[vertCounter++] = currentVertice.g2;
							vertices[vertCounter++] = currentVertice.b2;
							vertices[vertCounter++] = currentVertice.a2;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 1;
							
							// right thickness point
							vertices[vertCounter++] = nextStartX;
							vertices[vertCounter++] = nextStartY;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 0;
						}
						else
						{
							isAngleSwitched = false;
							vertices[vertCounter++] = nextStartX;
							vertices[vertCounter++] = nextStartY;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r2;
							vertices[vertCounter++] = currentVertice.g2;
							vertices[vertCounter++] = currentVertice.b2;
							vertices[vertCounter++] = currentVertice.a2;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 1;
	
							// right thickness point
							vertices[vertCounter++] = nextStartNegativeX;
							vertices[vertCounter++] = nextStartNegativeY;
							vertices[vertCounter++] = 0;
							vertices[vertCounter++] = currentVertice.r1;
							vertices[vertCounter++] = currentVertice.g1;
							vertices[vertCounter++] = currentVertice.b1;
							vertices[vertCounter++] = currentVertice.a1;
							vertices[vertCounter++] = currentVertice.u;
							vertices[vertCounter++] = 0;
						}
					}
				}

				
				
				/***********
				 * 
				 * DRAW TRIANGLES
				 * 
				 *********/ 
				if(isFirstVertice)
				{
					if(i==0)
					{
						sharedIndice1 = 0;
						sharedIndice2 = 1;
						indiceIndex += 2;
					}
					else
					{
						sharedIndice1 += 2;
						sharedIndice2 += 2;
						indiceIndex += 2;
					}
				}
				else if(jointType && hasIntersection)
				{
					if(jointType == JOINT_TYPE_MITER)
					{
						/*
						trace('First Triangle: ', sharedIndice1, ' ', indiceIndex, ' ', sharedIndice2);
						trace('Second Triangle: : ', sharedIndice2, ' ', indiceIndex, ' ', indiceIndex+1);
						*/
						
						if(isMiterJointBeveled)
						{
							if(isClockWise)
							{
								// first triangle
								indices[indiciesCounter++] = sharedIndice1;
								indices[indiciesCounter++] = indiceIndex;
								indices[indiciesCounter++] = sharedIndice2;
								
								// second triangle
								indices[indiciesCounter++] = sharedIndice2;
								indices[indiciesCounter++] = indiceIndex;
								indices[indiciesCounter++] = indiceIndex+1;
								
								
								// BAC
								indices[indiciesCounter++] = indiceIndex;
								indices[indiciesCounter++] = indiceIndex+1;
								indices[indiciesCounter++] = indiceIndex+2;
								
								sharedIndice1 = indiceIndex + 2;
								sharedIndice2 = indiceIndex + 1;
							}
							else
							{
								// first triangle
								indices[indiciesCounter++] = sharedIndice1;
								indices[indiciesCounter++] = indiceIndex+1;
								indices[indiciesCounter++] = sharedIndice2;
								
								// second triangle
								indices[indiciesCounter++] = indiceIndex+1;
								indices[indiciesCounter++] = sharedIndice2;
								indices[indiciesCounter++] = indiceIndex+2;
								
								// BAC
								indices[indiciesCounter++] = indiceIndex+1;
								indices[indiciesCounter++] = indiceIndex;
								indices[indiciesCounter++] = indiceIndex+2;
								
								sharedIndice1 = indiceIndex+1;
								sharedIndice2 = indiceIndex;
							}
							
							indiceIndex += 3;
						}
						else
						{
							// first triangle
							indices[indiciesCounter++] = sharedIndice1;
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = sharedIndice2;
							
							// second triangle
							indices[indiciesCounter++] = sharedIndice2;
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = indiceIndex+1;
							
							sharedIndice1 = indiceIndex;
							sharedIndice2 = indiceIndex + 1;
							
							indiceIndex += 2;
						}
						
					}
					else if(jointType == JOINT_TYPE_BEVEL)
					{						
						//trace('BEVEL TRIANGLE DRAW');
						if(isClockWise)
						{
							// first triangle
							indices[indiciesCounter++] = sharedIndice1;
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = sharedIndice2;
							
							// second triangle
							indices[indiciesCounter++] = sharedIndice2;
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = indiceIndex+1;
							
							
							// BAC
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = indiceIndex+1;
							indices[indiciesCounter++] = indiceIndex+2;
							
							sharedIndice1 = indiceIndex + 2;
							sharedIndice2 = indiceIndex + 1;
						}
						else
						{
							// first triangle
							indices[indiciesCounter++] = sharedIndice1;
							indices[indiciesCounter++] = indiceIndex+1;
							indices[indiciesCounter++] = sharedIndice2;
							
							// second triangle
							indices[indiciesCounter++] = indiceIndex+1;
							indices[indiciesCounter++] = sharedIndice2;
							indices[indiciesCounter++] = indiceIndex+2;
							
							// BAC
							indices[indiciesCounter++] = indiceIndex+1;
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = indiceIndex+2;
							
							sharedIndice1 = indiceIndex+1;
							sharedIndice2 = indiceIndex;
						}
						
						indiceIndex += 3;
					}
					else
					{
						if(isClockWise)
						{
							// first triangle
							indices[indiciesCounter++] = sharedIndice1;
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = sharedIndice2;
							
							// second triangle
							indices[indiciesCounter++] = sharedIndice2;
							indices[indiciesCounter++] = indiceIndex;
							indices[indiciesCounter++] = indiceIndex+1;
							
							pointBIndiceIndex = indiceIndex;
							pointAIndiceIndex = indiceIndex+1;

							roundJointIndiceIndex = pointAIndiceIndex;

							for(c = 0; c < roundJointPointCount; c++)
							{
								if(c == 0)
								{
									indices[indiciesCounter++] = pointAIndiceIndex;
									indices[indiciesCounter++] = pointBIndiceIndex;
									indices[indiciesCounter++] = ++roundJointIndiceIndex;
								}
								else
								{
									indices[indiciesCounter++] = pointAIndiceIndex;
									indices[indiciesCounter++] = roundJointIndiceIndex;
									indices[indiciesCounter++] = ++roundJointIndiceIndex;
								}

								indiceIndex++;
							}

							sharedIndice1 = roundJointIndiceIndex;
							sharedIndice2 = pointAIndiceIndex;
						}
						else
						{
							// first triangle
							indices[indiciesCounter++] = sharedIndice1;
							indices[indiciesCounter++] = indiceIndex+1;
							indices[indiciesCounter++] = sharedIndice2;

							// second triangle
							indices[indiciesCounter++] = indiceIndex+1;
							indices[indiciesCounter++] = sharedIndice2;
							indices[indiciesCounter++] = indiceIndex+2;

							pointBIndiceIndex = indiceIndex;
							pointAIndiceIndex = indiceIndex+1;

							roundJointIndiceIndex = pointAIndiceIndex;

							for(c = 0; c < roundJointPointCount; c++)
							{
								indices[indiciesCounter++] = pointAIndiceIndex;
								indices[indiciesCounter++] = roundJointIndiceIndex;
								indices[indiciesCounter++] = ++roundJointIndiceIndex;
								
								indiceIndex++;
							}

							sharedIndice1 = pointAIndiceIndex;
							sharedIndice2 = roundJointIndiceIndex;
						}

						indiceIndex += 3;
					}
				}
				else
				{
					// first triangle
					indices[indiciesCounter++] = sharedIndice1;
					indices[indiciesCounter++] = indiceIndex;
					indices[indiciesCounter++] = sharedIndice2;

					// second triangle
					indices[indiciesCounter++] = sharedIndice2;
					indices[indiciesCounter++] = indiceIndex;
					indices[indiciesCounter++] = indiceIndex+1;

					sharedIndice1 = indiceIndex;
					sharedIndice2 = indiceIndex + 1;
					
					indiceIndex += 2;
				}
				
				previousVertice = currentVertice;

				prevVerticeAngle = verticeAngle;
				startX = nextStartX;
				startY = nextStartY;

				startNegativeX = nextStartNegativeX;
				startNegativeY = nextStartNegativeY;

				isPreviousVerticeJoint = hasIntersection && jointType;
			} // end for
		}
		
		///////////////////////////////////
		// Static helper methods - Old version of createPolyLine that does not use pre allocated vectors. Slower.
		///////////////////////////////////
		[inline]
		protected static function createPolyLine( vertices:Vector.<StrokeVertex>, 
												outputVertices:Vector.<Number>, 
												outputIndices:Vector.<uint>, 
												indexOffset:int ):void
		{
			
			var sqrt:Function = Math.sqrt;
			var sin:Function = Math.sin;
			const numVertices:int = vertices.length;
			const PI:Number = Math.PI;
			
			for ( var i:int = 0; i < numVertices; i++ )
			{
				var degenerate:uint = vertices[i].degenerate;
				var idx:uint = i;
				if ( degenerate != 0 ) {
					idx = ( degenerate == DEGENERATE_END_VERTICE_TYPE ) ? ( i - 1 ) : ( i + 1 );
				}
				var treatAsFirst:Boolean = ( idx == 0 ) || ( vertices[ idx - 1 ].degenerate > 0 );
				var treatAsLast:Boolean = ( idx == numVertices - 1 ) || ( vertices[ idx + 1 ].degenerate > 0 );
				var idx0:uint = treatAsFirst ? idx : ( idx - 1 );
				var idx2:uint = treatAsLast ? idx : ( idx + 1 );
				
				var v0:StrokeVertex = vertices[idx0];
				var v1:StrokeVertex = vertices[idx];
				var v2:StrokeVertex = vertices[idx2];
				
				var v0x:Number = v0.x;
				var v0y:Number = v0.y;
				var v1x:Number = v1.x;
				var v1y:Number = v1.y;
				var v2x:Number = v2.x;
				var v2y:Number = v2.y;
				
				var d0x:Number = v1x - v0x;
				var d0y:Number = v1y - v0y;
				var d1x:Number = v2x - v1x;
				var d1y:Number = v2y - v1y;
				
				if ( treatAsLast )
				{
					v2x += d0x;
					v2y += d0y;
					
					d1x = v2x - v1x;
					d1y = v2y - v1y;
				}
				
				if ( treatAsFirst )
				{
					v0x -= d1x;
					v0y -= d1y;
					
					d0x = v1x - v0x;
					d0y = v1y - v0y;
				}
				
				var d0:Number = sqrt( d0x*d0x + d0y*d0y );
				var d1:Number = sqrt( d1x*d1x + d1y*d1y );
				
				var elbowThickness:Number = v1.thickness*0.5;
				if ( !(treatAsFirst || treatAsLast) )
				{
					// Thanks to Tom Clapham for spotting this relationship.
					var dot:Number = (d0x*d1x+d0y*d1y) / (d0*d1);
					elbowThickness /= sin((PI-Math.acos(dot)) * 0.5);
					
					if ( elbowThickness > v1.thickness * 4 )
					{
						elbowThickness = v1.thickness * 4;
					}
					
					if ( isNaN( elbowThickness ) )
					{
						elbowThickness = v1.thickness*0.5;
					}
				}
				
				var n0x:Number = -d0y / d0;
				var n0y:Number =  d0x / d0;
				var n1x:Number = -d1y / d1;
				var n1y:Number =  d1x / d1;
				
				var cnx:Number = n0x + n1x;
				var cny:Number = n0y + n1y;
				var c:Number = (1/sqrt( cnx*cnx + cny*cny )) * elbowThickness;
				cnx *= c;
				cny *= c;
				
				var v1xPos:Number = v1x + cnx;
				var v1yPos:Number = v1y + cny;
				var v1xNeg:Number = ( degenerate ) ? v1xPos : ( v1x - cnx );
				var v1yNeg:Number = ( degenerate ) ? v1yPos : ( v1y - cny );
			
				
				outputVertices.push( v1xPos, v1yPos, 0, v1.r2, v1.g2, v1.b2, v1.a2, v1.u, 1,
								 v1xNeg, v1yNeg, 0, v1.r1, v1.g1, v1.b1, v1.a1, v1.u, 0 );
				
				
				if ( i < numVertices - 1 )
				{
					var i2:int = indexOffset + (i << 1);
					outputIndices.push(i2, i2 + 2, i2 + 1, i2 + 1, i2 + 2, i2 + 3);
				}
			}
		}
		
		override protected function shapeHitTestLocalInternal( localX:Number, localY:Number ):Boolean
		{
			if ( _line == null ) return false;
			if ( _line.length < 2 ) return false;
			
			var numLines:int = _line.length;
			
			for ( var i: int = 1; i < numLines; i++ )
			{
				var v0:StrokeVertex = _line[i - 1];
				var v1:StrokeVertex = _line[i];
				
				var lineLengthSquared:Number = (v1.x - v0.x) * (v1.x - v0.x) + (v1.y - v0.y) * (v1.y - v0.y);
				
				var interpolation:Number = ( ( ( localX - v0.x ) * ( v1.x - v0.x ) ) + ( ( localY - v0.y ) * ( v1.y - v0.y ) ) )  /	( lineLengthSquared );
				if( interpolation < 0.0 || interpolation > 1.0 )
					continue;   // closest point does not fall within the line segment
					
				var intersectionX:Number = v0.x + interpolation * ( v1.x - v0.x );
				var intersectionY:Number = v0.y + interpolation * ( v1.y - v0.y );
				
				var distanceSquared:Number = (localX - intersectionX) * (localX - intersectionX) + (localY - intersectionY) * (localY - intersectionY);
				
				var intersectThickness:Number = (v0.thickness * (1.0 - interpolation) + v1.thickness * interpolation); // Support for varying thicknesses
				
				intersectThickness += _precisionHitTestDistance;
				
				if ( distanceSquared <= intersectThickness * intersectThickness)
					return true;
			}
				
			return false;
		}
		
		/** Transforms a point from the local coordinate system to parent coordinates.
         *  If you pass a 'resultPoint', the result will be stored in this point instead of 
         *  creating a new object. */
        public function localToParent(localPoint:Point, resultPoint:Point=null):Point
        {
            return MatrixUtil.transformCoords(transformationMatrix, localPoint.x, localPoint.y, resultPoint);
        }
		
		
		public static function strokeCollideTest(s1:Stroke, s2:Stroke, intersectPoint:Point, staticLenIntersectPoints:Vector.<Point> = null ) : Boolean
		{
			if ( s1 == null || s2 == null ||  s1._line == null || s1._line == null )
				return false;
				
				
			if ( sCollissionHelper == null )
				sCollissionHelper  = new StrokeCollisionHelper();
			sCollissionHelper.testIntersectPoint.x = 0;
			sCollissionHelper.testIntersectPoint.y = 0;
			intersectPoint.x = 0;
			intersectPoint.y = 0;
			var hasSameParent:Boolean = false;
			if ( s1.parent == s2.parent )
				hasSameParent = true;

			s1.getBounds(hasSameParent ? s1.parent: s1.stage, sCollissionHelper.bounds1);
			s2.getBounds(hasSameParent ? s2.parent: s2.stage, sCollissionHelper.bounds2);
			if ( sCollissionHelper.bounds1.intersects(sCollissionHelper.bounds2) == false )
				return false;
			
		
			if ( intersectPoint == null )
				intersectPoint = new Point();
			var numLinesS1:int = s1._line.length;
			var numLinesS2:int = s2._line.length;
			var hasHit:Boolean = false;
			
			
			if ( sCollissionHelper.s2v0Vector == null || sCollissionHelper.s2v0Vector.length < numLinesS2 )
			{
				sCollissionHelper.s2v0Vector = new Vector.<Point>(numLinesS2, true);
				sCollissionHelper.s2v1Vector = new Vector.<Point>(numLinesS2, true);
			}
			
			var pointCounter:int = 0;
			var maxPointCounter:int = 0;
			if ( staticLenIntersectPoints != null )
				maxPointCounter = staticLenIntersectPoints.length;
			
			for ( var i: int = 1; i < numLinesS1; i++ )
			{
				var s1v0:StrokeVertex = s1._line[i - 1];
				var s1v1:StrokeVertex = s1._line[i];
				
				sCollissionHelper.localPT1.setTo(s1v0.x, s1v0.y);
				sCollissionHelper.localPT2.setTo(s1v1.x, s1v1.y);
				if ( hasSameParent )
				{
					s1.localToParent(sCollissionHelper.localPT1, sCollissionHelper.globalPT1);
					s1.localToParent(sCollissionHelper.localPT2, sCollissionHelper.globalPT2);
				}
				else
				{
					s1.localToGlobal(sCollissionHelper.localPT1, sCollissionHelper.globalPT1);
					s1.localToGlobal(sCollissionHelper.localPT2, sCollissionHelper.globalPT2);
				}
			
			
				for	( var j: int = 1; j < numLinesS2; j++ )
				{
					var s2v0:StrokeVertex = s2._line[j - 1];
					var s2v1:StrokeVertex = s2._line[j];
				
					if ( i == 1 )
					{ // when we do the first loop through this set, we can cache all global points in s2v0Vector and s2v1Vector, to avoid slow localToGlobals on next loop passes
						sCollissionHelper.localPT3.setTo(s2v0.x, s2v0.y);
						sCollissionHelper.localPT4.setTo(s2v1.x, s2v1.y);
						
						if ( hasSameParent )
						{
							s2.localToParent(sCollissionHelper.localPT3, sCollissionHelper.globalPT3);
							s2.localToParent(sCollissionHelper.localPT4, sCollissionHelper.globalPT4);
						}
						else	
						{
							s2.localToGlobal(sCollissionHelper.localPT3, sCollissionHelper.globalPT3);
							s2.localToGlobal(sCollissionHelper.localPT4, sCollissionHelper.globalPT4);
						}
							
						if ( sCollissionHelper.s2v0Vector[j] == null )
						{
							sCollissionHelper.s2v0Vector[j] = new Point(sCollissionHelper.globalPT3.x, sCollissionHelper.globalPT3.y);
							sCollissionHelper.s2v1Vector[j] = new Point(sCollissionHelper.globalPT4.x, sCollissionHelper.globalPT4.y);
						}
						else
						{
							sCollissionHelper.s2v0Vector[j].x = sCollissionHelper.globalPT3.x;
							sCollissionHelper.s2v0Vector[j].y = sCollissionHelper.globalPT3.y;
							sCollissionHelper.s2v1Vector[j].x = sCollissionHelper.globalPT4.x;
							sCollissionHelper.s2v1Vector[j].y = sCollissionHelper.globalPT4.y;
						}
					}
					else
					{
						sCollissionHelper.globalPT3.x = sCollissionHelper.s2v0Vector[j].x;
						sCollissionHelper.globalPT3.y = sCollissionHelper.s2v0Vector[j].y;
						
						sCollissionHelper.globalPT4.x = sCollissionHelper.s2v1Vector[j].x;
						sCollissionHelper.globalPT4.y = sCollissionHelper.s2v1Vector[j].y;
					}
						
					if ( TriangleUtil.lineIntersectLine(sCollissionHelper.globalPT1.x, sCollissionHelper.globalPT1.y, sCollissionHelper.globalPT2.x, sCollissionHelper.globalPT2.y, sCollissionHelper.globalPT3.x, sCollissionHelper.globalPT3.y, sCollissionHelper.globalPT4.x, sCollissionHelper.globalPT4.y, sCollissionHelper.testIntersectPoint) )
					{
						if ( staticLenIntersectPoints != null && pointCounter < (maxPointCounter-1) )
						{
							if ( hasSameParent )
								s1.parent.localToGlobal(sCollissionHelper.testIntersectPoint, staticLenIntersectPoints[pointCounter])
							else
							{
								staticLenIntersectPoints[pointCounter].x = sCollissionHelper.testIntersectPoint.x;
								staticLenIntersectPoints[pointCounter].y = sCollissionHelper.testIntersectPoint.y;
							}
							pointCounter++;
							staticLenIntersectPoints[pointCounter].x = NaN;
							staticLenIntersectPoints[pointCounter].y = NaN;
						}
						
						if ( sCollissionHelper.testIntersectPoint.length > intersectPoint.length )
						{
							if ( hasSameParent )
								s1.parent.localToGlobal(sCollissionHelper.testIntersectPoint, intersectPoint);
							else
							{
								intersectPoint.x = sCollissionHelper.testIntersectPoint.x;
								intersectPoint.y = sCollissionHelper.testIntersectPoint.y;
							}
							
						}
						hasHit = true;
					}
				}
			}
			
			return hasHit;
		}
	}
}

import flash.geom.Point;
import flash.geom.Rectangle;

class StrokeCollisionHelper
{
	public function StrokeCollisionHelper(){};

	public var localPT1:Point = new Point();	
	public var localPT2:Point = new Point();	
	public var localPT3:Point = new Point();	
	public var localPT4:Point = new Point();	
			
	public var globalPT1:Point = new Point();	
	public var globalPT2:Point = new Point();	
	public var globalPT3:Point = new Point();		
	public var globalPT4:Point = new Point();	
	
	public var bounds1:Rectangle = new Rectangle();
	public var bounds2:Rectangle = new Rectangle();
	
	public var testIntersectPoint:Point = new Point();
	public var s1v0Vector:Vector.<Point> = null;
	public var s1v1Vector:Vector.<Point>= null;
	public var s2v0Vector:Vector.<Point>= null;
	public var s2v1Vector:Vector.<Point>= null;
}