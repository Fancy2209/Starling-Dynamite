package fancy2209.dynamite
{
    import flash.display.IGraphicsData;
    import flash.display.GraphicsSolidFill;
    import flash.display.GraphicsPath;
    import starling.display.Canvas;
    import starling.geom.Polygon;
    import fancy2209.dynamite.utils.AJSGraphicsPath;
    import com.codeazur.libtess2.Tesselator;
    import flash.display.GraphicsPathWinding;
    import fancy2209.dynamite.utils.VectorUtil;


    public class DynamiteCanvas extends Canvas
    {
        private var _graphicData:Vector.<IGraphicsData>
        private var _vertices:Vector.<Number>
        private var _done:Boolean
        private var tess:Tesselator = new Tesselator()


        public function DynamiteCanvas(graphicsData:Vector.<IGraphicsData>, tesselate:Boolean = true)
        {
            super()
            this._graphicData = graphicsData
            trace(_graphicData)
            storeGraphicData(tesselate)

        }


        private function storeGraphicData(tesselate:Boolean = true):void
        {
            var _countours:Vector
            for each(var graphicsProperties:Object in _graphicData)
			{
				trace(JSON.stringify(graphicsProperties))
                if (graphicsProperties is GraphicsSolidFill)
                    {
                    var _fillAlpha:Number = graphicsProperties.alpha				
                    var _fillColor:int = graphicsProperties.color
                    trace("beginFill(" + _fillColor + ", " + _fillAlpha  + ")")
                    this.beginFill(_fillColor, _fillAlpha)
                    }
				if (graphicsProperties is GraphicsPath)
                    {

                    var winding:String = graphicsProperties.winding;

                    var unprocessedContour:Vector.<Number> = AJSGraphicsPath.prepare(graphicsProperties)
                    trace(unprocessedContour + "\n")

                    var processedContour:Vector.<Number> = tesselate2(unprocessedContour, winding)
                    trace(processedContour + "\n")
                    this.drawPolygon(new Polygon((new VectorUtil(processedContour)).toArray()))
                    }
                this.endFill() 
            }            
        }

        private function tesselate2(contour:Vector.<Number>, winding:String):Vector.<Number>
        {
                        var w:int
                        tess.newTess(Math.pow(1024, 2))
                        if (winding == GraphicsPathWinding.EVEN_ODD)
                        {
                            w = Tesselator.WINDING_ODD
                        }
                        else if (winding == GraphicsPathWinding.NON_ZERO)
                        {
                            w = Tesselator.WINDING_NONZERO 
                        }
                        else
                        {
                            trace("INVALID WINDING")
                        }
                        tess.addContour(contour, contour.length / 2, 2)
                        tess.tesselate(w, Tesselator.ELEMENT_TYPE_POLYGONS, 3, 2)
                        var returnVar:Vector.<Number> = tess.getVertices()
                        tess.deleteTess()
                        return returnVar
        }
    }
}