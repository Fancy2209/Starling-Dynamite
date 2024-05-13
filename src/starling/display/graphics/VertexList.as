package starling.display.graphics
{
	import starling.display.util.GPool;

	public final class VertexList
	{
		public var vertex:Vector.<Number>;
		public var next:VertexList;
		public var prev:VertexList;
		public var index:int;
		public var head	:VertexList;

		public function VertexList()
		{
			vertex = GPool.getNumberVector();
		}
		
		private static var temp:VertexList;
		
		static public function insertAfter( nodeA:VertexList, nodeB:VertexList ):VertexList
		{
			temp = nodeA.next;
			nodeA.next = nodeB;
			nodeB.next = temp;
			nodeB.prev = nodeA;
			nodeB.head = nodeA.head;
			
			return nodeB;
		}
		
		private static var newHead:VertexList;
		private static var currentVertexNode:VertexList;
		private static var currentClonedNode:VertexList;
		private static var newClonedNode:VertexList;

		private static var i:int, len:int;

		static public function clone(vertexList:VertexList):VertexList
		{
			newHead = null;

			currentVertexNode = vertexList.head;
			currentClonedNode = null;

			do
			{
				if(newHead == null)
				{
					newClonedNode = newHead = getNode();
				}
				else
				{
					newClonedNode = getNode();
				}

				newClonedNode.head = newHead;
				newClonedNode.index = currentVertexNode.index;

				//newClonedNode.vertex = currentVertexNode.vertex;

				for(i = 0, len = currentVertexNode.vertex.length; i < len; i++)
				{
					newClonedNode.vertex[i] = currentVertexNode.vertex[i];
				}
				
				newClonedNode.prev = currentClonedNode;

				if(currentClonedNode)
				{
					currentClonedNode.next = newClonedNode;
				}

				currentClonedNode = newClonedNode;
				currentVertexNode = currentVertexNode.next;
			}
			while (currentVertexNode != currentVertexNode.head)

			currentClonedNode.next = newHead;
			newHead.prev = currentClonedNode;

			return newHead;
		}
		
		private static var vertexListTemp:VertexList;
		private static var vertexListNode:VertexList;
		
		static public function reverse( vertexList:VertexList ):void
		{
			vertexListNode = vertexList.head;

			do
			{
				vertexListTemp = vertexListNode.next;
				vertexListNode.next = vertexListNode.prev;
				vertexListNode.prev = vertexListTemp;
				
				vertexListNode = vertexListTemp;
			}
			while (vertexListNode != vertexList.head)
		}

		static public function dispose(node:VertexList):void
		{
			while(node && node.head)
			{
				if(node.vertex)
				{
					node.vertex.length = 0;
					GPool.putNumberVector(node.vertex);
					node.vertex = null;	
				}

				releaseNode(node);

				vertexListTemp = node.next;
				
				node.next = null;
				node.prev = null;
				node.head = null;

				node = node.next;
			}
		}
		
		private static var nodePool:Vector.<VertexList> = new Vector.<VertexList>;
		private static var nodePoolLength:int = 0;
		
		static public function getNode():VertexList
		{
			if(nodePoolLength > 0)
			{
				nodePoolLength--;
				vertexListNode = nodePool.pop();

				if(!vertexListNode.vertex)
				{
					vertexListNode.vertex = GPool.getNumberVector();
				}
				
				return vertexListNode;
			}

			return new VertexList();
		}

		static public function releaseNode(node:VertexList):void
		{
			node.prev = node.next = node.head = null;

			node.vertex = null;
			node.index = -1;

			nodePool[nodePoolLength++] = node;
		}
	}
}