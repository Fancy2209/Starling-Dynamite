/*
    Basically all the code is here is from AwayJS Graphics
	Credits to The Away Foundation and Away Studios
    Original: https://github.com/awayjs/graphics/blob/40ab7386c22146e72b5fca8d1b28e207ef2fcf8e/lib/draw/GraphicsPath.ts#L150-L316
*/
package fancy2209.dynamite.utils
{
    import flash.display.GraphicsPathCommand;
    import fancy2209.dynamite.utils.awayjs.GraphicsFactoryHelper;

    public class AJSGraphicsPath
    {
        public function AJSGraphicsPath()
        {
            super()
        }
        

        public static function prepare(graphicsPathData:Object, qualityScale:Number = 1, forceClose:Boolean = false):Vector.<Number>
        {
            const eps:Number = 1 / (100 * qualityScale);

            var contour:Vector.<Number>;

            const commands:Vector.<int> = graphicsPathData.commands,
            data:Vector.<Number> = graphicsPathData.data,
            winding:String = graphicsPathData.winding;
            
            var len:int = commands.length,
            positions:Array = []

            var d:int = 0,
            p:int = 0;

            var prev_x:Number, 
            prev_y:Number, 
            ctrl_x:Number, 
            ctrl_y:Number, 
            ctrl_x2:Number, 
            ctrl_y2:Number, 
            end_x:Number,
            end_y:Number;

            // If we don't start with a moveTo command, ensure origin is added to positions
            if (len === 1 && !commands[0])
            {
                return null;
            }

            for(var c:Number = 0; c < len; c++)
            {
                switch (commands[c]){
				case GraphicsPathCommand.MOVE_TO:
					if (c) {
						//overwrite last command if it was a moveTo
						if (contour.length == 1) {
							positions[p] = contour = new <Number>[prev_x = data[d++], prev_y = data[d++]];
							
							break;
						}

						// check if the last contour is closed.
						// if its not closed, we optionally close it by adding the first point to the end of the contour
						if (forceClose
							&& Math.abs(contour[0] - contour[contour.length - 2])
							+ Math.abs(contour[1] - contour[contour.length - 1]) > eps)
							contour.push(contour[0], contour[1]);
					    }
					
					positions[p++] = contour = new <Number>[prev_x = data[d++], prev_y = data[d++]];

					break;
				case GraphicsPathCommand.LINE_TO:
					end_x = data[d++];
					end_y = data[d++];

					if (_minimumCheck(prev_x - end_x, prev_y - end_y))
						break;

					contour.push(prev_x = end_x, prev_y = end_y);
					break;
				case GraphicsPathCommand.CURVE_TO:
					ctrl_x = data[d++];
					ctrl_y = data[d++];
					end_x = data[d++];
					end_y = data[d++];

					if (_minimumCheck(ctrl_x - end_x, ctrl_y - end_y)) {
						// if all points are less than miniumum draw distance, ignore
						if (_minimumCheck(prev_x - end_x, prev_y - end_y))
							break;

						//if control is end, substitute lineTo command
						contour.push(prev_x = end_x, prev_y = end_y);
						break;
					} else if (_minimumCheck(prev_x - ctrl_x, prev_y - ctrl_y)) {
						//if prev point is control, substitute lineTo command
						contour.push(prev_x = end_x, prev_y = end_y);
						break;
					}

					GraphicsFactoryHelper.tesselateCurve(
						prev_x, prev_y,
						ctrl_x, ctrl_y,
						prev_x = end_x, prev_y = end_y,
						contour, false,
						0, qualityScale
					);

					break;
				case GraphicsPathCommand.CUBIC_CURVE_TO:
					ctrl_x = data[d++];
					ctrl_y = data[d++];
					ctrl_x2 = data[d++];
					ctrl_y2 = data[d++];
					end_x = data[d++];
					end_y = data[d++];

					if (_minimumCheck(ctrl_x2 - end_x, ctrl_y2 - end_y)) {
						if (_minimumCheck(ctrl_x - end_x, ctrl_y - end_y)) {
							// if all points are less than miniumum draw distance, ignore
							if (_minimumCheck(prev_x - end_x, prev_y - end_y))
								break;

							//if control and control2 are end, substitute lineTo command
							contour.push(prev_x = end_x, prev_y = end_y);
							break;
						} else if (_minimumCheck(prev_x - ctrl_x, prev_y - ctrl_y)) {
							//if prev point is control and control2 is end, substitute lineTo command
							contour.push(prev_x = end_x, prev_y = end_y);
							break;
						}

						//if control2 is end substitute curveTo command
						GraphicsFactoryHelper.tesselateCurve(
							prev_x, prev_y,
							ctrl_x, ctrl_y,
							prev_x = end_x, prev_y = end_y,
							contour, false,
							0, qualityScale
						);
						break;
					} else if (_minimumCheck(ctrl_x - ctrl_x2, ctrl_y - ctrl_y2)) {
						if (_minimumCheck(prev_x - ctrl_x2, prev_y - ctrl_y2)) {
							//if prev point and control are control2, substitute lineTo command
							contour.push(prev_x = end_x, prev_y = end_y);
							break;
						}

						//if control is control2 substitute curveTo command
						GraphicsFactoryHelper.tesselateCurve(
							prev_x, prev_y,
							ctrl_x, ctrl_y,
							prev_x = end_x, prev_y = end_y,
							contour, false,
							0, qualityScale
						);

						contour.push(prev_x = end_x, prev_y = end_y);
						break;
					} else if (_minimumCheck(prev_x - ctrl_x, prev_y - ctrl_y)) {
						//if prev point is control, substitute curveTo command
						GraphicsFactoryHelper.tesselateCurve(
							prev_x, prev_y,
							ctrl_x2, ctrl_y2,
							prev_x = end_x, prev_y = end_y,
							contour, false,
							0, qualityScale
						);
						break;
					}

					//console.log("CURVE_TO ", i, ctrl_x, ctrl_y, end_x, end_y);
					GraphicsFactoryHelper.tesselateCubicCurve(
						prev_x, prev_y,
						ctrl_x, ctrl_y,
						ctrl_x2, ctrl_y2,
						prev_x = end_x, prev_y = end_y,
						contour,
						0, qualityScale
					);
					break;
			    }
            }

            return contour
        }
        
        private static const MINIMUM_DRAWING_DISTANCE:Number = 0.1
        
        private static const lensq:Number = MINIMUM_DRAWING_DISTANCE * MINIMUM_DRAWING_DISTANCE;

        private static function _minimumCheck(lenx: Number, leny: Number): Boolean {
		    return (lenx * lenx + leny * leny) < lensq;
	}
        
    }
}