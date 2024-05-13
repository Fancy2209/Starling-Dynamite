package starling.display.graphics
{
	import flash.geom.Matrix;

	import starling.display.graphics.util.TriangleUtil;
	
	public class Fill extends GraphicRenderer
	{
		public static const VERTEX_STRIDE	:int = 9;
		
		protected var fillVertices	:VertexList;
		protected var _numVertices	:int;
		protected var _isConvex:Boolean = true;

		public function Fill()
		{
			_uvMatrix = new Matrix();
			_uvMatrix.scale(1/256, 1/256);
			
			indices = new Vector.<uint>();
			vertices = new Vector.<Number>(); 
		}
		
		public function get numVertices():int
		{
			return _numVertices;
		}
		
		public function clear():void
		{
			indices.length = 0;
			vertices.length = 0;

			if(minBounds)
			{
				minBounds.x = minBounds.y = 0; 
				maxBounds.x = maxBounds.y = 0;
			}

			_numVertices = 0;

			VertexList.releaseNode(fillVertices);

			fillVertices = null;
			setGeometryInvalid();
			_isConvex = true;
		}
		
		override public function dispose():void
		{
			clear();
			fillVertices = null;
			super.dispose();
		}
		
		private static var lastVertex:Vector.<Number>;
		private static var lastColor:uint;
		
		public function addDegenerates(destX:Number, destY:Number, color:uint = 0xFFFFFF, alpha:Number = 1 ):void
		{
			if(_numVertices < 1)
			{
				return;
			}

			lastVertex = fillVertices.prev.vertex;

			lastColor = uint( lastVertex[3] * 255 ) << 16; // R
			lastColor |= uint( lastVertex[4] * 255 ) << 8; // G
			lastColor |= uint( lastVertex[5] * 255 ); // B

			addVertex(lastVertex[0], lastVertex[1], lastColor, lastVertex[6]);
			addVertex(destX, destY, color, alpha);
		}
		
		public function addVertexInConvexShape(x:Number, y:Number, color:uint = 0xFFFFFF, alpha:Number = 1 ):void
		{
			addVertexInternal(x, y, color, alpha);
		}
		
		public function addVertex( x:Number, y:Number, color:uint = 0xFFFFFF, alpha:Number = 1 ):void
		{
			_isConvex = false;
			addVertexInternal(x, y, color, alpha);
		}
		
		private static var r:Number;
		private static var g:Number;
		private static var b:Number;
		
		private static var node:VertexList;
		
		protected function addVertexInternal(x:Number, y:Number, color:uint = 0xFFFFFF, alpha:Number = 1):void
		{
			r = (color >> 16) / 255;
			g = ((color & 0x00FF00) >> 8) / 255;
			b = (color & 0x0000FF) / 255;

			//var vertex:Vector.<Number> = Vector.<Number>( [ x, y, 0, r, g, b, alpha, x, y ]);
			
			node = VertexList.getNode();

			if ( _numVertices == 0 )
			{
				fillVertices = node;
				node.head = node;
				node.prev = node;
			}
			
			node.next = fillVertices.head;
			node.prev = fillVertices.head.prev;
			node.prev.next = node;
			node.next.prev = node;
			node.index = _numVertices;

			node.vertex[0] = x;
			node.vertex[1] = y;
			node.vertex[2] = 0;
			node.vertex[3] = r;
			node.vertex[4] = g;
			node.vertex[5] = b;
			node.vertex[6] = alpha;
			node.vertex[7] = x;
			node.vertex[8] = y;
			
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
			
			_numVertices++;
			
			setGeometryInvalid();
		}
		
		override protected function buildGeometry():void
		{
			if ( _numVertices < 3) return;
			
			vertices.length = 0;
			indices.length = 0;

			triangulate(fillVertices, _numVertices, vertices, indices, _isConvex);
		}

		override public function shapeHitTest(stageX:Number, stageY:Number):Boolean
		{
			if ( vertices == null ) return false;
			if ( numVertices < 3 ) return false;

			shapeHitTestPoint.x = stageX;
			shapeHitTestPoint.y = stageY;

			globalToLocal(shapeHitTestPoint, shapeHitTestResultPoint);
			wn = windingNumberAroundPoint(fillVertices, shapeHitTestResultPoint.x, shapeHitTestResultPoint.y);

			if(isClockWise(fillVertices))
			{
				return  wn != 0;
			}

			return wn == 0;
		}
		
		override protected function shapeHitTestLocalInternal(localX:Number, localY:Number):Boolean
		{
			// This method differs from shapeHitTest - the isClockWise test is compared with false rather than true. Not sure why, but this yields the correct result for me.
			wn = windingNumberAroundPoint(fillVertices, localX, localY);

			if(isClockWise(fillVertices))
			{
				return  wn != 0;
			}

			return wn == 0;
		}
		
		private static var iter:int;
		private static var flag:Boolean;
		private static var currentNode:VertexList;
		
		private static var n0:VertexList;
		private static var n1:VertexList;
		private static var n2:VertexList;
		
		private static var v0x:Number;
		private static var v0y:Number;
		private static var v1x:Number;
		private static var v1y:Number;
		private static var v2x:Number;
		private static var v2y:Number;
		
		private static var outputIndicesLen:int;		
		private static var currentList:VertexList;
		
		private static var openList:Vector.<VertexList>;
		
		private static var startNode:VertexList;
		private static var n:VertexList;
		private static var found:Boolean;
		
		/**
		 * Takes a list of arbitrary vertices. It will first decompose this list into
		 * non intersecting polygons, via convertToSimple. Then it uses an ear-clipping
		 * algorithm to decompose the polygons into triangles.
		 * @param vertices
		 * @param _numVertices
		 * @return 
		 * 
		 */		
		protected static function triangulate(vertices:VertexList, _numVertices:int, outputVertices:Vector.<Number>, outputIndices:Vector.<uint>, isConvex:Boolean):void
		{
			vertices = VertexList.clone(vertices);

			openList = null;

			if(isConvex == false)
			{
				openList = convertToSimple(vertices);	
			}
			else
			{
				// If the shape is convex, no need to run it through expensive convertToSimple
				openList = new Vector.<VertexList>;
				openList[0] = vertices;
			}

			flatten(openList, outputVertices);

			while(openList.length > 0)
			{
				currentList = openList.pop();

				if(isClockWise(currentList) == false)
				{
					VertexList.reverse(currentList);
				}

				iter = 0;
				flag = false;
				currentNode = currentList.head;

				while(true)
				{
					if ( iter > _numVertices*3 ) break;
					iter++;
					
					n0 = currentNode.prev;
					n1 = currentNode;
					n2 = currentNode.next;
					
					// If vertex list is 3 long.
					if ( n2.next == n0 )
					{
						//trace( "making triangle : " + n0.index + ", " + n1.index + ", " + n2.index );
						outputIndices.push( n0.index, n1.index, n2.index );
						VertexList.releaseNode(n0);
						VertexList.releaseNode(n1);
						VertexList.releaseNode(n2);
						break;
					}
					
					v0x = n0.vertex[0];
					v0y = n0.vertex[1];
					v1x = n1.vertex[0];
					v1y = n1.vertex[1];
					v2x = n2.vertex[0];
					v2y = n2.vertex[1];
					
					// Ignore vertex if not reflect
					//trace( "testing triangle : " + n0.index + ", " + n1.index + ", " + n2.index );
					if ( isReflex( v0x, v0y, v1x, v1y, v2x, v2y ) == false )
					{
						//trace("index is not reflex. Skipping. " + n1.index);
						currentNode = currentNode.next;
						continue;
					}
					
					// Check to see if building a triangle from these 3 vertices
					// would intersect with any other edges.
					startNode = n2.next;
					n = startNode;
					found = false;

					while ( n != n0 )
					{
						//trace("Testing if point is in triangle : " + n.index);
						if ( TriangleUtil.isPointInTriangle(v0x, v0y, v1x, v1y, v2x, v2y, n.vertex[0], n.vertex[1]) )
						{
							found = true;
							break;
						}
						n = n.next;
					}
					if ( found )
					{
						//trace("Point found in triangle. Skipping");
						currentNode = currentNode.next;
						continue;
					}
					
					outputIndicesLen = outputIndices.length;
					
					// Build triangle and remove vertex from list
					//trace( "making triangle : " + n0.index + ", " + n1.index + ", " + n2.index );
					
					//outputIndices.push( n0.index, n1.index, n2.index );
					
					outputIndices[outputIndicesLen++] = n0.index;
					outputIndices[outputIndicesLen++] = n1.index;
					outputIndices[outputIndicesLen++] = n2.index;
					
					//trace( "removing vertex : " + n1.index );
					if ( n1 == n1.head )
					{
						n1.vertex = n2.vertex;
						n1.next = n2.next;
						n1.index = n2.index;
						n1.next.prev = n1;
						VertexList.releaseNode(n2);
					}
					else
					{
						n0.next = n2;
						n2.prev = n0;
						VertexList.releaseNode(n1);
					}
					
					currentNode = n0;
				}

				VertexList.dispose(currentList);
			}
		}
		
		private static var output:Vector.<VertexList>;
		private static var outputLength:int;
		
		private static var headA:VertexList;
		private static var nodeA:VertexList;
		private static var isSimple:Boolean;

		private static var nodeB:VertexList;
	
		private static var temp:VertexList;
						
		private static var isectNodeA:VertexList;

		private static var headB:VertexList;
		private static var isectNodeB:VertexList;

		private static var i:int, len:int;

		/**
		 * Decomposes a list of arbitrarily positioned vertices that may form self-intersecting
		 * polygons, into a list of non-intersecting polygons. This is then used as input
		 * for the triangulator. 
		 * @param vertexList
		 * @return 
		 */		
		protected static function convertToSimple(vertexList:VertexList):Vector.<VertexList>
		{
			output = new Vector.<VertexList>();
			outputLength = 0;

			openList = new Vector.<VertexList>();
			openList.push(vertexList);

			while(openList.length > 0)
			{
				currentList = openList.pop();

				headA = currentList.head;
				nodeA = headA;
				isSimple = true;

				if(nodeA.next == nodeA || nodeA.next.next == nodeA || nodeA.next.next.next == nodeA)
				{
					output[outputLength++] = headA;
					continue;
				}

				do
				{
					nodeB = nodeA.next.next;

					do
					{
						intersecionVector.length = 0;

						if(intersection(nodeA, nodeA.next, nodeB, nodeB.next, intersecionVector))
						{
							isSimple = false;

							temp = nodeA.next;

							isectNodeA = VertexList.getNode();
							
							for(i = 0, len = intersecionVector.length; i < len; i++)
							{
								isectNodeA.vertex[i] = intersecionVector[i];
							}
							
							isectNodeA.prev = nodeA;
							isectNodeA.next = nodeB.next;
							isectNodeA.next.prev = isectNodeA;
							isectNodeA.head = headA;
							nodeA.next = isectNodeA;

							headB = nodeB;
							isectNodeB = VertexList.getNode();							

							for(i = 0, len = intersecionVector.length; i < len; i++)
							{
								isectNodeB.vertex[i] = intersecionVector[i];
							}

							isectNodeB.prev = nodeB;
							isectNodeB.next = temp;
							isectNodeB.next.prev = isectNodeB;
							isectNodeB.head = headB;
							nodeB.next = isectNodeB;

							do
							{
								nodeB.head = headB;
								nodeB = nodeB.next;
							}
							while ( nodeB != headB )

							//openList.push( headA, headB );
							openList[openList.length] = headA;
							openList[openList.length] = headB;							

							break;
						}

						nodeB = nodeB.next;
					}
					while ( nodeB != nodeA.prev && isSimple )

					nodeA = nodeA.next;
				}
				while ( nodeA != headA && isSimple)

				if(isSimple)
				{
					output[outputLength++] = headA;
				}
			}

			return output;
		}

		private static var index:int;
		private static var olen:int;

		private static var vertexList:VertexList;
			
		protected static function flatten(vertexLists:Vector.<VertexList>, output:Vector.<Number>):void
		{
			len = vertexLists.length;
			index = 0;
			olen;
			
			for (i = 0; i < len; i++ )
			{
				vertexList = vertexLists[i];
				node = vertexList.head;

				do
				{
					node.index = index++;
					olen = output.length;

					output[olen] = node.vertex[0];
					output[++olen] = node.vertex[1];
					output[++olen] = node.vertex[2];
					output[++olen] = node.vertex[3];
					output[++olen] = node.vertex[4];
					output[++olen] = node.vertex[5];
					output[++olen] = node.vertex[6];
					output[++olen] = node.vertex[7];
					output[++olen] = node.vertex[8];

					node = node.next;
				}
				while(node != node.head)
			}
		}
		
		private static var wn:int;
		private static var isUp:Boolean;

		protected static function windingNumberAroundPoint(vertexList:VertexList, x:Number, y:Number):int
		{
			wn = 0;
			node = vertexList.head;

			do
			{
				v0y = node.vertex[1];
				v1y = node.next.vertex[1];

				if((y > v0y && y < v1y) || (y > v1y && y < v0y))
				{
					v0x = node.vertex[0];
					v1x = node.next.vertex[0];

					isUp = v1y < y;

					if(isUp)
					{
						//wn += isLeft( v0x, v0y, v1x, v1y, x, y ) ? 1 : 0;
						// Inline version of above
						wn += ((v1x - v0x) * (y - v0y) - (v1y - v0y) * (x - v0x)) < 0 ? 1 : 0
					}
					else
					{
						//wn += isLeft( v0x, v0y, v1x, v1y, x, y ) ? 0 : -1
						// Inline version of above
						wn += ((v1x - v0x) * (y - v0y) - (v1y - v0y) * (x - v0x)) < 0 ? 0 : -1;
					}
				}

				node = node.next;
			}
			while(node != vertexList.head)

			return wn;
		}

		public static function isClockWise( vertexList:VertexList ):Boolean
		{
			wn = 0;
			node = vertexList.head;

			do
			{
				wn += (node.next.vertex[0]-node.vertex[0]) * (node.next.vertex[1]+node.vertex[1]);
				node = node.next;
			}
			while(node != vertexList.head)

			return wn <= 0;
		}
		
		protected static function windingNumber( vertexList:VertexList ):int
		{
			wn = 0;
			node = vertexList.head;

			do
			{
				//wn += isLeft( node.vertex[0], node.vertex[1], node.next.vertex[0], node.next.vertex[1], node.next.next.vertex[0], node.next.next.vertex[1] ) ? -1 : 1;
				
				// Inline version of above
				wn += ((node.next.vertex[0] - node.vertex[0]) * (node.next.next.vertex[1] - node.vertex[1]) - (node.next.next.vertex[0] - node.vertex[0]) * (node.next.vertex[1] - node.vertex[1])) < 0 ? -1 : 1;
				
				node = node.next;
			}
			while ( node != vertexList.head )
			
			return wn;
		}
		
		
		protected static function isReflex( v0x:Number, v0y:Number, v1x:Number, v1y:Number, v2x:Number, v2y:Number ):Boolean
		{
			if ( TriangleUtil.isLeft( v0x, v0y, v1x, v1y, v2x, v2y ) ) return false;
			if ( TriangleUtil.isLeft( v1x, v1y, v2x, v2y, v0x, v0y ) ) return false;
			
			// Inline version of above ( this prevents the fill to be drawn on iOS with AIR > 3.6, so we roll back to isLeft())
			//if ( ((v1x - v0x) * (v2y - v0y) - (v2x - v0x) * (v1y - v0y)) < 0 ) return false;
			//if ( ((v2x - v1x) * (v0y - v1y) - (v0x - v1x) * (v2y - v1y)) < 0 ) return false;
			
			return true;
		}
		
		protected static const EPSILON:Number = 0.000001;

		private static var intersecionVector:Vector.<Number> = new Vector.<Number>;
		private static var intersectionLen:int = 0;
		
		private static var ux:Number;
		private static var uy:Number;
		
		private static var vx:Number;
		private static var vy:Number;
		
		private static var wx:Number;
		private static var wy:Number;
		
		private static var D:Number = ux * vy - uy * vx
	
		
		private static var t:Number;
		private static var t2:Number;

		private static var vertexA:Vector.<Number>;
		private static var vertexB:Vector.<Number>;
		
		static private function intersection(a0:VertexList, a1:VertexList, b0:VertexList, b1:VertexList, result:Vector.<Number>):Boolean
		{
			ux = (a1.vertex[0]) - (a0.vertex[0]);
			uy = (a1.vertex[1]) - (a0.vertex[1]);
			
			vx = (b1.vertex[0]) - (b0.vertex[0]);
			vy = (b1.vertex[1]) - (b0.vertex[1]);
			
			wx = (a0.vertex[0]) - (b0.vertex[0]);
			wy = (a0.vertex[1]) - (b0.vertex[1]);
			
			D = ux * vy - uy * vx
			if ((D < 0 ? -D : D) < EPSILON) return false;
			
			t = (vx * wy - vy * wx) / D
			if (t < 0 || t > 1) return false;
			t2 = (ux * wy - uy * wx) / D
			if (t2 < 0 || t2 > 1) return false;
			
			vertexA = a0.vertex;
			vertexB = a1.vertex;
			
			intersectionLen = 0;
			
			result[intersectionLen++] = vertexA[0] + t * (vertexB[0] - vertexA[0]);
			result[intersectionLen++] = vertexA[1] + t * (vertexB[1] - vertexA[1]); 
			result[intersectionLen++] = 0; 
			result[intersectionLen++] = vertexA[3] + t * (vertexB[3] - vertexA[3]); 
			result[intersectionLen++] = vertexA[4] + t * (vertexB[4] - vertexA[4]); 
			result[intersectionLen++] = vertexA[5] + t * (vertexB[5] - vertexA[5]);
			result[intersectionLen++] = vertexA[6] + t * (vertexB[6] - vertexA[6]); 
			result[intersectionLen++] = vertexA[7] + t * (vertexB[7] - vertexA[7]); 
			result[intersectionLen++] = vertexA[8] + t * (vertexB[8] - vertexA[8]);
			
			return true;
		}
	}
}
