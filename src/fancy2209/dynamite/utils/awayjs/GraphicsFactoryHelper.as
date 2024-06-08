/*
    This code is basically all from AwayJS
    Credits to The Away Foundation and Away Studios
    See: https://github.com/awayjs/graphics/blob/dev/lib/draw/GraphicsFactoryHelper.ts
*/

package fancy2209.dynamite.utils.awayjs
{
    public class GraphicsFactoryHelper
    {
        public static const RADIANS_TO_DEGREES: Number = 180 / Math.PI;


        public static const DEGREES_TO_RADIANS: Number = Math.PI / 180;

        private static const CURVE_TESSELATION_COUNT:int = 6

        public function GraphicsFactoryHelper()
        {
            super()
        }
    

    public static function tesselateCurve(
		startx: Number,
		starty: Number,
		cx: Number,
		cy: Number,
		endx: Number,
		endy: Number,
		array_out: Vector.<Number>,
		filled: Boolean = false,
		iterationCnt: Number = 0,
		qualityScale: Number = 1
	): void {

		const maxIterations: Number = CURVE_TESSELATION_COUNT;
		const minAngle: Number = 1 / Math.sqrt(qualityScale);
            const minLengthSqr: Number = 1 / qualityScale;

            // subdivide the curve
            const c1x: Number = (startx + cx) * 0.5;// new controlpoint 1
            const c1y: Number = (starty + cy) * 0.5;
            const c2x: Number = (cx + endx) * 0.5;// new controlpoint 2
            const c2y: Number = (cy + endy) * 0.5;
            const ax: Number = (c1x + c2x) * 0.5;// new middlepoint 1
            const ay: Number = (c1y + c2y) * 0.5;

            // if "filled" is true, we are collecting final vert positions in the array,
            // ready to use for rendering. (6-position values for each tri)
            // if "filled" is false, we are collecting vert positions for a path (we do not need the start-position).

            // stop tesselation on maxIteration level. Set it to 0 for no tesselation at all.
            if (iterationCnt >= maxIterations) {
                if (filled) {
                    array_out.push(startx, starty, ax, ay, endx, endy);
                    return;
                }
                array_out.push(ax, ay, endx, endy);
                return;
            }

            // calculate length of segment
            // this does not include the crtl-point position
            const diff_x: Number = endx - startx;
            const diff_y: Number = endy - starty;
            const lenSq: Number = diff_x * diff_x + diff_y * diff_y;

            // stop subdividing if the angle or the length is to small
            if (lenSq < minLengthSqr) {
                if (filled) {
                    array_out.push(startx, starty, ax, ay, endx, endy);
                } else {
                    array_out.push(endx, endy);
                }
                return;
            }

            // calculate angle between segments
            const angle_1: Number = Math.atan2(cy - starty, cx - startx) * RADIANS_TO_DEGREES;
            const angle_2: Number = Math.atan2(endy - cy, endx - cx) * RADIANS_TO_DEGREES;
            var angle_delta: Number = angle_2 - angle_1;

            // make sure angle is in range -180 - 180
            while (angle_delta > 180) {
                angle_delta -= 360;
            }
            while (angle_delta < -180) {
                angle_delta += 360;
            }

            angle_delta = angle_delta < 0 ? -angle_delta : angle_delta;

            // stop subdividing if the angle or the length is to small
            if (angle_delta <= minAngle) {
                if (filled) {
                    array_out.push(startx, starty, ax, ay, endx, endy);
                } else {
                    array_out.push(endx, endy);
                }
                return;
            }

            // if the output should be directly in valid tris, we always must create a tri,
            // even when we will keep on subdividing.
            if (filled) {
                array_out.push(startx, starty, ax, ay, endx, endy);
            }

            iterationCnt++;

            tesselateCurve(
                startx, starty, c1x, c1y, ax, ay, array_out, filled, iterationCnt, qualityScale);
            tesselateCurve(
                ax, ay, c2x, c2y, endx, endy, array_out, filled, iterationCnt, qualityScale);
        }

        public static function tesselateCubicCurve(

            startx: Number,
            starty: Number,
            cx: Number,
            cy: Number,
            cx2: Number,
            cy2: Number,
            endx: Number,
            endy: Number,
            array_out: Vector.<Number>,
            iterationCnt: Number = 0,
            qualityScale: Number = 1
        ): void {

            const maxIterations: Number = CURVE_TESSELATION_COUNT;
            const minAngle: Number = 1 / Math.sqrt(qualityScale);
            const minLengthSqr: Number = 1 / qualityScale;

            // calculate length of segment
            // this does not include the crtl-point positions
            const diff_x: Number = endx - startx;
            const diff_y: Number = endy - starty;
            const lenSq: Number = diff_x * diff_x + diff_y * diff_y;

            // stop subdividing if the angle or the length is to small
            if (lenSq < minLengthSqr) {
                array_out.push(endx, endy);
                return;
            }

            // subdivide the curve
            const c1x: Number = (startx + cx) * 0.5;// new controlpoint 1
            const c1y: Number = (starty + cy) * 0.5;
            const c2x: Number = (cx + cx2) * 0.5;// new controlpoint 2
            const c2y: Number = (cy + cy2) * 0.5;
            const c3x: Number = (cx2 + endx) * 0.5;// new controlpoint 3
            const c3y: Number = (cy2 + endy) * 0.5;

            const d1x: Number = (c1x + c2x) * 0.5;// new controlpoint 1
            const d1y: Number = (c1y + c2y) * 0.5;
            const d2x: Number = (c2x + c3x) * 0.5;// new controlpoint 2
            const d2y: Number = (c2y + c3y) * 0.5;

            const ax: Number = (d1x + d2x) * 0.5;// new middlepoint 1
            const ay: Number = (d1y + d2y) * 0.5;

            // stop tesselation on maxIteration level. Set it to 0 for no tesselation at all.
            if (iterationCnt >= maxIterations) {
                array_out.push(ax, ay, endx, endy);
                return;
            }

            // calculate angle between segments
            const angle_1: Number = Math.atan2(cy - starty, cx - startx) * RADIANS_TO_DEGREES;
            const angle_2: Number = Math.atan2(endy - cy, endx - cx) * RADIANS_TO_DEGREES;
            var angle_delta: Number = angle_2 - angle_1;

            // make sure angle is in range -180 - 180
            while (angle_delta > 180) {
                angle_delta -= 360;
            }
            while (angle_delta < -180) {
                angle_delta += 360;
            }

            angle_delta = angle_delta < 0 ? -angle_delta : angle_delta;

            // stop subdividing if the angle or the length is to small
            if (angle_delta <= minAngle) {
                array_out.push(endx, endy);
                return;
            }

        }
    }
}