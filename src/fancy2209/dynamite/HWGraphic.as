package fancy2209.dynamite
{
    import flash.display.IGraphicsData;
    import flash.display.GraphicsSolidFill;
    import flash.display.GraphicsPath;
    import flash.display.GraphicsEndFill;
    import starling.display.Shape;
    import flash.display.GraphicsPathCommand;


    public class HWGraphic
    {
        private var _graphicData:Vector.<IGraphicsData>
        private var _vertices:Vector.<Number>
        private var _indices:Vector.<uint>
        private var _commandData:Vector.<Number>
        private var _commands:Vector.<int>
        private var _winding:String
        private var _fillAlpha:Number
        private var _fillColor:uint
        private var _shape:starling.display.Shape = new starling.display.Shape
        private var _done:Boolean

        public function HWGraphic(graphDatVec:Vector.<IGraphicsData>)
        {
            super()
            _graphicData = graphDatVec
            trace(_graphicData)
            getGraphInfo()
        }

        public function get shape():Shape
        {
            return _shape
        }

        private function getGraphInfo():void
        {
            for each(var graphicsProperties:Object in _graphicData)
			{
				trace(JSON.stringify(graphicsProperties))
                if (graphicsProperties is GraphicsSolidFill)
                    {
                    _fillAlpha = graphicsProperties.alpha				
                    _fillColor = graphicsProperties.color
                    trace("beginFill(" + _fillColor + " " + _fillAlpha  + ")")
                    _shape.graphics.beginFill(_fillColor, _fillAlpha)
                    }
				if (graphicsProperties is GraphicsPath)
                    {
                    /*
                    0 = NO_OP
                    1 = MOVE_TO
                    2 = LINE_TO
                    3 = CURVE_TO
                    4 = WIDE_MOVE_TO
                    5 = WIDE_LINE_TO
                    6 = CUBIC_CURVE
                    */
                    _commands = graphicsProperties.commands
                    _commandData = graphicsProperties.data
                    _winding = graphicsProperties.winding
                    
                    for(var index:Number = 0; index < _commandData.length; index+=2)
                    {
                        for each(var value:int in _commands)
                        {
                            if (value == GraphicsPathCommand.MOVE_TO)
                            {
                                trace("moveTo(" +  _commandData[index] + ", " + _commandData[index+1] + ")")
                                _shape.graphics.moveTo(_commandData[index], _commandData[index+1])
                                index+=2
                            }
                            if (value == GraphicsPathCommand.LINE_TO)
                            {
                                trace("lineTo(" +  _commandData[index] + ", " + _commandData[index+1] + ")")
                                _shape.graphics.lineTo(_commandData[index], _commandData[index+1])
                                index+=2
                            }
                            if (value == GraphicsPathCommand.CURVE_TO)
                            {
                                trace("curveTo(" +  _commandData[index] + ", " + _commandData[index+1] + ", " + _commandData[index+2] + ", " + _commandData[index+3] + ")")
                                _shape.graphics.curveTo(_commandData[index], _commandData[index+1], _commandData[index+2], _commandData[index+3])
                                index+=4
                            }     
                        }
                    }  
                    trace("endFill()")
                    _shape.graphics.endFill()
        }}}

        public function get graphicData():Vector.<IGraphicsData> 
        {
            return _graphicData
        }

        public function get vertices():Vector.<Number>
        {
            return _vertices
        }

        public function get indices():Vector.<uint>
        {
            return _indices
        }

    }
}