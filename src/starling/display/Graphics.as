package starling.display
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import starling.display.graphics.EllipseMesh;
	import starling.display.graphics.RoundRectangleMesh;
	
	import starling.display.graphics.Fill;
	import starling.display.graphics.NGon;
	import starling.display.graphics.RoundedRectangle;
	import starling.display.graphics.Stroke;
	import starling.display.materials.IMaterial;
	import starling.display.util.CurveUtil;
	import starling.textures.Texture;
	
	public class Graphics
	{
		protected static const BEZIER_ERROR:Number = 0.75;

		protected var _container				:DisplayObjectContainer;
		
		// The owner of this Graphics instance.
		protected var _penPosX					:Number;
		protected var _penPosY					:Number;
		
		// Fill state vars
		protected var _currentFill				:Fill;
		protected var _fillStyleSet				:Boolean;
		protected var _fillColor				:uint;
		protected var _fillAlpha				:Number;
		protected var _fillTexture				:Texture;
		protected var _fillMaterial				:IMaterial;
		protected var _fillMatrix				:Matrix;
		protected var _fillDrawInBack			:Boolean;
		
		// Stroke state vars
		protected var _currentStroke			:Stroke;
		protected var _strokeStyleSet			:Boolean;
		protected var _strokeThickness			:Number;
		protected var _strokeColor				:uint;
		protected var _strokeAlpha				:Number;
		protected var _strokeTexture			:Texture;
		protected var _strokeMaterial			:IMaterial;
		protected var _strokeDrawInBack			:Boolean;
		protected var _strokeJointType			:int;
		
		protected var _enableStrokeLineThicknessChange:Boolean;
		protected var _strokeLineThicknessChangeRatio:Number;
		
		protected var _precisionHitTest			:Boolean = false;
		protected var _precisionHitTestDistance	:Number = 0; 
		
		protected var _boundsBuffer:Number = 0;
		
		protected var _boundsBufferX:Number = 0;
		protected var _boundsBufferY:Number = 0;

		// optimization if you want to pause drawing with stroke while drawing fill 
		// so that next time new child is not added when you want to resume drawing with stroke
		protected var _pauseStroke:Boolean;
		protected var _pauseFill:Boolean;
		
		public function Graphics()
		{
			roundedRect = new RoundedRectangle(100, 100, 25, 25, 25, 25, 10);
		}
		
		public function get container():DisplayObjectContainer
		{
			return _container;
		}
		
		public function set container(value:DisplayObjectContainer):void
		{
			_container = value;
		}
		
		public function get boundsBuffer():Number
		{
			return _boundsBuffer;
		}
		
		public function set boundsBuffer(value:Number):void
		{
			_boundsBuffer = value;
			_boundsBufferX = value;
			_boundsBufferY = value;
		}
		
		public function get boundsBufferX():Number
		{
			return _boundsBufferX;
		}
		
		public function set boundsBufferX(value:Number):void
		{
			_boundsBufferX = value;
		}
		
		public function get boundsBufferY():Number
		{
			return _boundsBufferY;
		}
		
		public function set boundsBufferY(value:Number):void
		{
			_boundsBufferY = value;
		}
		
		public function get strokeColor():uint
		{
			return _strokeColor;
		}
		
		public function get strokeTexture():Texture
		{
			return _strokeTexture;
		}

		public function get strokeThickness():Number
		{
			return _strokeThickness;
		}
		
		public function get isFillStyleSet():Boolean
		{
			return _fillStyleSet;
		}
		
		public function get fillColor():uint
		{
			return _fillColor;
		}
		
		public function get fillAlpha():Number
		{
			return _fillAlpha;
		}
		
		public function get fillTexture():Texture
		{
			return _fillTexture;
		}

		public function get penPositionX():Number
		{
			return _penPosX;
		}
		
		public function get penPositionY():Number
		{
			return _penPosY;
		}
		
		public function get strokeStyleSet():Boolean
		{
			return _strokeStyleSet;
		}

		public function set pauseStroke(value:Boolean):void
		{
			_pauseStroke = value;
		}
		
		public function get pauseStroke():Boolean
		{
			return _pauseStroke;
		}
		
		public function set pauseFill(value:Boolean):void
		{
			_pauseFill = value;
		}
		
		public function get pauseFill():Boolean
		{
			return _pauseFill;
		}
		
		public function set enableStrokeLineThicknessChange(value:Boolean):void
		{
			_enableStrokeLineThicknessChange = value;
		}
		
		public function get enableStrokeLineThicknessChange():Boolean
		{
			return _enableStrokeLineThicknessChange;
		}


		public function set strokeLineThicknessChangeRatio(value:Number):void
		{
			_strokeLineThicknessChangeRatio = value;
		}
		
		public function get strokeLineThicknessChangeRatio():Number
		{
			return _strokeLineThicknessChangeRatio;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////
		// PUBLIC
		/////////////////////////////////////////////////////////////////////////////////////////
		
		public function clear():void
		{	
			_enableStrokeLineThicknessChange = false;
			_strokeLineThicknessChangeRatio = 0;

			_penPosX = NaN;
			_penPosY = NaN;
			
			endStroke();
			endFill();

			_container.removeChildren(0, -1, true);
		}
		
		////////////////////////////////////////
		// Fill-style
		////////////////////////////////////////
		
		public function beginFill( color:uint, alpha:Number = 1.0, drawInBack:Boolean = false):Graphics
		{
			endFill();

			_fillStyleSet 	= true;
			_fillColor 		= color;
			_fillAlpha 		= alpha;
			_fillTexture 	= null;
			_fillMaterial 	= null;
			_fillMatrix 	= null;
			_fillDrawInBack = drawInBack;

			return this;
		}
		
		public function beginTextureFill(texture:Texture, uvMatrix:Matrix = null, color:uint = 0xFFFFFF, alpha:Number = 1.0, drawInBack:Boolean = false):Graphics
		{
			endFill();
			
			_fillStyleSet 	= true;
			_fillColor 		= color;
			_fillAlpha 		= alpha;
			_fillTexture 	= texture;
			_fillMaterial 	= null;
			_fillMatrix 	= new Matrix();
			_fillDrawInBack = drawInBack;

			if ( uvMatrix )
			{
				_fillMatrix = uvMatrix.clone();
				_fillMatrix.invert();
			}
			else
			{
				_fillMatrix = new Matrix();
			}
			
			_fillMatrix.scale( 1 / texture.width, 1 / texture.height );
			
			return this;
		}
		
		public function beginMaterialFill( material:IMaterial, uvMatrix:Matrix = null ):Graphics
		{
			endFill();
			
			_fillStyleSet 	= true;
			_fillColor 		= 0xFFFFFF;
			_fillAlpha 		= 1;
			_fillTexture 	= null;
			_fillMaterial 	= material;
			
			if(uvMatrix)
			{
				_fillMatrix = uvMatrix.clone();
				_fillMatrix.invert();
			}
			else
			{
				_fillMatrix = new Matrix();
			}

			return this;
		}
		
		public function endFill():void
		{
			_fillStyleSet 	= false;
			_fillColor 		= NaN;
			_fillAlpha 		= NaN;
			_fillTexture 	= null;
			_fillMaterial 	= null;
			_fillMatrix 	= null;
			_fillDrawInBack = false;
			_pauseFill = false;

			// If we started drawing with a fill, but ended drawing
			// before we did anything visible with it, dispose it here.
			if(_currentFill && _currentFill.numVertices < 3 ) 
			{
				_currentFill.removeFromParent(true);
			}

			_currentFill = null;
		}
		
		////////////////////////////////////////
		// Stroke-style
		////////////////////////////////////////
		
		public function lineStyle(thickness:Number = NaN, color:uint = 0, alpha:Number = 1.0, jointType:int = Stroke.JOINT_TYPE_BEVEL, drawInBack:Boolean = false):Graphics
		{
			endStroke();
			
			_strokeStyleSet			= !isNaN(thickness) && thickness > 0;
			_strokeThickness		= thickness;
			_strokeColor			= color;
			_strokeAlpha			= alpha;
			_strokeTexture 			= null;
			_strokeMaterial			= null;
			_strokeJointType		= jointType;
			_strokeDrawInBack 	    = drawInBack;

			return this;
		}
		
		public function lineTexture(thickness:Number = NaN, texture:Texture = null, color:Number = 0xFFFFFF, alpha:Number = 1, jointType:int = Stroke.JOINT_TYPE_BEVEL, drawInBack:Boolean = false):Graphics
		{
			endStroke();
			
			_strokeStyleSet			= !isNaN(thickness) && thickness > 0 && texture;
			_strokeThickness		= thickness;
			_strokeColor			= color;
			_strokeAlpha			= alpha;
			_strokeTexture 			= texture;
			_strokeMaterial			= null;
			_strokeJointType		= jointType;
			_strokeDrawInBack 	    = drawInBack;

			return this;
		}
		
		public function lineMaterial(thickness:Number = NaN, material:IMaterial = null):Graphics
		{
			endStroke();
			
			_strokeStyleSet			= !isNaN(thickness) && thickness > 0 && material;
			_strokeThickness		= thickness;
			_strokeColor			= 0xFFFFFF;
			_strokeAlpha			= 1;
			_strokeTexture			= null;
			_strokeMaterial			= material;
			
			return this;
		}
		
		public function endStroke():void
		{
			_strokeStyleSet			= false;
			_strokeThickness		= NaN;
			_strokeColor			= NaN;
			_strokeAlpha			= NaN;
			_strokeTexture			= null;
			_strokeMaterial			= null;
			_pauseStroke = false;
			
			// If we started drawing with a stroke, but ended drawing
			// before we did anything visible with it, dispose it here.
			if(_currentStroke && _currentStroke.numVertices < 2)
			{
				_currentStroke.removeFromParent(true);
				_penPosX = NaN;
				_penPosY = NaN;
			}
			
			_currentStroke = null;
		}
		
		
		////////////////////////////////////////
		// Draw commands
		////////////////////////////////////////
		
		public function moveTo(x:Number, y:Number):Graphics
		{
			// Use degenerate methods for moveTo calls.
			// Degenerates allow for better performance as they do not terminate
			// the vertex buffer but instead use zero size polygons to translate
			// from the end point of the last section of the stroke to the
			// start of the new point.
			if (_strokeStyleSet)
			{
				if(!_currentStroke)
				{
					createStroke();
				}

				if(_currentStroke.numVertices == 0)
				{
					_currentStroke.addVertex(x, y, _strokeThickness);
				}
				else
				{
					_currentStroke.addDegenerates(x, y);
				}
			}
			
			if(_fillStyleSet) 
			{
				if(!_currentFill)
				{ // Added to make sure that the first vertex in a shape gets added to the fill as well.
					createFill();
					_currentFill.addVertex(x, y);
				}
				else
				{
					if(_currentFill.numVertices == 0)
					{
						_currentFill.addVertex( x, y );
					}
					else
					{
						_currentFill.addDegenerates( x, y );
					}
				}
			}
			
			if((_strokeStyleSet && _currentStroke) || (_fillStyleSet && _currentFill))
			{
				_penPosX = x;
				_penPosY = y;	
			}

			return this;
		}
		
		public function lineMoveToFillTo(lineX:Number, lineY:Number, fillX:Number, fillY:Number):Graphics
		{
			// Use degenerate methods for moveTo calls.
			// Degenerates allow for better performance as they do not terminate
			// the vertex buffer but instead use zero size polygons to translate
			// from the end point of the last section of the stroke to the
			// start of the new point.
			if (_strokeStyleSet)
			{
				if(!_currentStroke)
				{
					createStroke();
				}

				if(_currentStroke.numVertices == 0)
				{
					_currentStroke.addVertex(lineX, lineY, _strokeThickness);
				}
				else
				{
					_currentStroke.addDegenerates(lineX, lineY);
				}
			}
			
			if(_fillStyleSet) 
			{
				if(!_currentFill)
				{ // Added to make sure that the first vertex in a shape gets added to the fill as well.
					createFill();
					_currentFill.addVertex(fillX, fillY);
				}
				else
				{
					_currentFill.addDegenerates(fillX, fillY);
				}
			}
			
			_penPosX = lineX;
			_penPosY = lineY;
			
			return this;
		}
		
		public function lineTo(x:Number, y:Number, disableThicknessChange:Boolean = false):Graphics
		{
			// if iSNaN
			if(_penPosX != _penPosX || _penPosY != _penPosY)
			{
				moveTo(0, 0);
			}
			
			if(_strokeStyleSet) 
			{
				// Create a new stroke Graphic if this is the first
				// time we've start drawing something with it.
				if(!_currentStroke)
				{
					createStroke();
				}

				_currentStroke.lineTo(x, y, _strokeThickness);

				if(_enableStrokeLineThicknessChange && !disableThicknessChange)
				{
					_strokeThickness += _strokeLineThicknessChangeRatio;
					
					if(_strokeThickness <= 0)
					{
						_strokeThickness = 0.5;
					}
				}
			}

			if(_fillStyleSet)
			{
				if(_currentFill == null)
				{
					createFill();
				}
				
				_currentFill.addVertex(x, y);
			}
			
			_penPosX = x;
			_penPosY = y;

			return this;
		}
		
		public function lineToFillTo(lineX:Number, lineY:Number, fillX:Number, fillY:Number, disableThicknessChange:Boolean = false):Graphics
		{
			// if iSNaN
			if(_penPosX != _penPosX || _penPosY != _penPosY)
			{
				moveTo(0, 0);
			}
			
			if(_strokeStyleSet) 
			{
				// Create a new stroke Graphic if this is the first
				// time we've start drawing something with it.
				if(_currentStroke == null)
				{
					createStroke();
				}
	
				_currentStroke.lineTo(lineX, lineY, _strokeThickness);
				
				if(_enableStrokeLineThicknessChange && !disableThicknessChange)
				{
					_strokeThickness += _strokeLineThicknessChangeRatio;
					
					if(_strokeThickness <= 0)
					{
						_strokeThickness = 0.5;
					}
				}
			}
			
			if(_fillStyleSet)
			{
				if(_currentFill == null)
				{
					createFill();
				}
				
				_currentFill.addVertex(fillX, fillY);
			}
			
			_penPosX = lineX;
			_penPosY = lineY;
			
			return this;
		}
		
		public function curveTo( cx:Number, cy:Number, a2x:Number, a2y:Number, error:Number = BEZIER_ERROR):Graphics
		{
			var startX:Number = _penPosX;
			var startY:Number = _penPosY;
			
			if ( isNaN(startX) )
			{
				startX = 0;
				startY = 0;
			}
			
			var points:Vector.<Number> = CurveUtil.quadraticCurve( startX, startY, cx, cy, a2x, a2y, error );
			
			var L:int = points.length;
			for ( var i:int = 0; i < L; i+=2 )
			{
				var x:Number = points[i];
				var y:Number = points[i+1];
				
				if ( i == 0 && isNaN(_penPosX) )
				{
					moveTo( x, y );
				}
				else
				{
					lineTo( x, y );
				}
			}
			
			_penPosX = a2x;
			_penPosY = a2y;
			
			return this;
		}
		
		public function cubicCurveTo(c1x:Number,
									 c1y:Number,
									 c2x:Number,
									 c2y:Number,
									 a2x:Number,
									 a2y:Number,
									 error:Number = BEZIER_ERROR):Graphics
		{
			var startX:Number = _penPosX;
			var startY:Number = _penPosY;
			
			if(isNaN(startX))
			{
				startX = 0;
				startY = 0;
			}
			
			var points:Vector.<Number> = CurveUtil.cubicCurve( startX, startY, c1x, c1y, c2x, c2y, a2x, a2y, error);
			
			var L:int = points.length;
			
			for(var i:int = 0; i < L; i+=2)
			{
				var x:Number = points[i];
				var y:Number = points[i+1];
				
				if(i == 0 && isNaN(_penPosX))
				{
					moveTo(x, y);
				}
				else
				{
					lineTo(x, y);
				}
			}
			
			_penPosX = a2x;
			_penPosY = a2y;
			
			return this;
		}
		
		public function drawCircle(x:Number, y:Number, radius:Number, precision:Number = 10):Graphics
		{
			drawEllipse(x, y, radius, radius, precision);
			
			return this;
		}
		
		public static function calculateAnglePoint(centerX:Number, centerY:Number, radius:Number, angle:Number, result:Point):void
		{
			result.x = centerX + (radius * Math.cos(angle));
			result.y = centerY + (radius * Math.sin(angle));
		}
		
		private static var numSides:int;
		private static var ellipseMatrix:Matrix = new Matrix();
		private static var nGon:NGon;
		private static var anglePerSide:Number;
		private static var i:int
		
		private static var anglePoint:Point = new Point();
		private static var ellipsePoint:Point = new Point();
		
		private static var currentAngle:Number;
		private static var _storedFill:Fill;
		
		private static var ellipseMesh:EllipseMesh;
		private static var doublePI:Number = Math.PI * 2;
		private static var halfPI:Number = Math.PI / 2;
		private static var threeQuarterCircle:Number = (Math.PI / 2) + halfPI;
		private static var ellipseX:Number, ellipseY:Number;
		private static var minimumStrokeThickness:Number, drawCircleAlign:Boolean;

		public function drawEllipse(x:Number, y:Number, width:Number, height:Number, precision:uint = 0, maxAngle:Number = 2*Math.PI, reverse:Boolean = false, ellipseAngle:Number = 0):Graphics
		{
			// Calculate num-sides based on a blend between circumference of width and circumference of height.
			// Should provide good results for ellipses with similar widths/heights.
			// Will look bad on very thin ellipses.

			if(precision == 0)
			{
				numSides = Math.PI * ( width * 0.5  + height * 0.5 ) * 0.25;
				numSides = numSides < 6 ? 6 : numSides;
			}
			else
			{
				numSides = precision;
			}

			// Use an NGon primitive instead of fill to bypass triangulation.
			if(_fillStyleSet && !_pauseFill)
			{
				ellipseMesh = new EllipseMesh(
					precision,
					width,
					height,
					_fillColor,
					_fillTexture,
					maxAngle,
					reverse
				);

				ellipseMesh.x = x;
				ellipseMesh.y = y;
				ellipseMesh.rotation = ellipseAngle;
				ellipseMesh.alpha = _fillAlpha;

				if(_fillDrawInBack)
				{
					_container.addChildAt(ellipseMesh, 0);
				}
				else
				{
					_container.addChild(ellipseMesh);
				}
			}

			// Draw the stroke
			if (_strokeStyleSet && !_pauseStroke)
			{
				// Null the currentFill after storing it in a local var.
				// This ensures the moveTo/lineTo calls for the stroke below don't
				// end up adding any points to a current fill (as we've already done
				// this in a more efficient manner above).
				_storedFill = _currentFill;

				_currentFill = null;

				anglePerSide = maxAngle / numSides;
				
				currentAngle = anglePerSide;	
				
				
				CurveUtil.calculateAnglePoint(x, y, width, ellipseAngle, anglePoint);
				
				moveTo(anglePoint.x, anglePoint.y);
				
				minimumStrokeThickness = _strokeThickness * 0.2;				
				drawCircleAlign = (_strokeThickness / anglePerSide) < 500;

				if(reverse)
				{
					if(drawCircleAlign)
					{
						if(ellipseAngle == 0)
						{
							anglePoint.y = y - minimumStrokeThickness;
						}
						else
						{
							CurveUtil.calculateAnglePoint(x, y, width, ellipseAngle - 0.0001745329, anglePoint);	
						}
						
						lineTo(anglePoint.x, anglePoint.y);
					}

					currentAngle = (Math.PI * 2) - anglePerSide;
					
					for(i = 0; i < numSides; i++, currentAngle -= anglePerSide)
					{
						ellipseX = Math.cos(currentAngle) * width;
						ellipseY = CurveUtil.calculateElipseY(
							width,
							height,
							ellipseX
						);

						if(currentAngle < Math.PI)
						{
							ellipseY *= -1;
						}

						anglePoint.x = ellipseX * Math.cos(ellipseAngle) + ellipseY * Math.sin(ellipseAngle);
						anglePoint.y = ellipseX * Math.sin(ellipseAngle) - ellipseY * Math.cos(ellipseAngle);
						
						if(drawCircleAlign && currentAngle < anglePerSide && currentAngle < threeQuarterCircle)
						{
							lineTo(
								anglePoint.x + x - (minimumStrokeThickness * Math.sin(ellipseAngle + maxAngle)), 
								anglePoint.y + y + (minimumStrokeThickness * Math.cos(ellipseAngle + maxAngle))
							);
						}

						lineTo(anglePoint.x + x, anglePoint.y + y);
					}
				}
				else
				{
					if(drawCircleAlign)
					{
						if(ellipseAngle == 0)
						{
							anglePoint.y = y + minimumStrokeThickness;
						}
						else
						{
							CurveUtil.calculateAnglePoint(x, y, width, ellipseAngle + 0.0001745329, anglePoint);	
						}
						
						lineTo(anglePoint.x, anglePoint.y);
					}

					currentAngle = anglePerSide;
				
					for(i = 0; i < numSides; i++, currentAngle += anglePerSide)
					{
						ellipseX = Math.cos(currentAngle) * width;
						ellipseY = CurveUtil.calculateElipseY(
							width,
							height,
							ellipseX
						);

						if(currentAngle < Math.PI)
						{
							ellipseY *= -1;
						}

						anglePoint.x = ellipseX * Math.cos(ellipseAngle) + ellipseY * Math.sin(ellipseAngle);
						anglePoint.y = ellipseX * Math.sin(ellipseAngle) - ellipseY * Math.cos(ellipseAngle);

						if(drawCircleAlign && currentAngle > maxAngle - anglePerSide && currentAngle > halfPI)
						{
							lineTo(
								anglePoint.x + x + (minimumStrokeThickness * Math.sin(ellipseAngle + maxAngle)), 
								anglePoint.y + y - (minimumStrokeThickness * Math.cos(ellipseAngle + maxAngle))
							);
						}
					
						lineTo(anglePoint.x + x, anglePoint.y + y);
					}	
				}

				// Reinstate the fill
				_currentFill = _storedFill;
			}

			return this;
		}
		
		private static var halfThickness:Number;
		private static var rectangleQuad:Quad;

		public function drawRect(x:Number, y:Number, width:Number, height:Number, angle:Number = 0, alignPivot:Boolean = false):Graphics
		{
			// Use a Plane primitive instead of fill to side-step triangulation.
			if(_fillStyleSet && !_pauseFill)
			{
				// using Quad to support automatic batching
				rectangleQuad = new Quad(width, height, _fillColor);
				
				if(alignPivot) rectangleQuad.alignPivot();

				rectangleQuad.x = x + rectangleQuad.pivotX;
				rectangleQuad.y = y + rectangleQuad.pivotY;
				rectangleQuad.alpha = _fillAlpha;
				rectangleQuad.rotation = angle;

				if(_fillTexture) rectangleQuad.texture = _fillTexture;

				if(_fillDrawInBack)
				{
					_container.addChildAt(rectangleQuad, 0);
				}
				else
				{
					_container.addChild(rectangleQuad);
				}
			}

			// Draw the stroke
			if(_strokeStyleSet && !_pauseStroke)
			{
				// Null the currentFill after storing it in a local var.
				// This ensures the moveTo/lineTo calls for the stroke below don't
				// end up adding any points to a current fill (as we've already done
				// this in a more efficient manner above).
				_storedFill = _currentFill;
				_currentFill = null;

				halfThickness = _strokeThickness / 2;

				moveTo(x - halfThickness, y);
				lineTo(x + width, y );

				lineTo(x + width, y + height );
				lineTo(x, y + height );
				lineTo(x, y + halfThickness);

				_currentFill = _storedFill;
			}

			return this;
		}

		public function drawRoundRect(x:Number, y:Number, width:Number, height:Number, radius:Number, radiusPrecision:uint = 20, angle:Number = 0):Graphics
		{
			drawRoundRectComplex(x, y, width, height, radius, radius, radius, radius, radiusPrecision, angle);
			
			return this;
		}
		
		private var roundedRect:RoundedRectangle; 
		private var m:Matrix;
		
		private static var storedFill:Fill;
		private static var storedIsFillSet:Boolean;

		private static var strokePoints:Vector.<Number>;

		private static var roundRectangleMesh:RoundRectangleMesh;

		public function drawRoundRectComplex( x:Number, y:Number, width:Number, height:Number, 
											  topLeftRadius:Number, topRightRadius:Number, 
											  bottomLeftRadius:Number, bottomRightRadius:Number,
											  radiusPrecision:uint,
											  angle:Number = 0):Graphics
		{
			// Draw fill
			if(_fillStyleSet && !_pauseFill)
			{
				// using Quad to support automatic batching
				roundRectangleMesh = new RoundRectangleMesh(
					width,
					height,
					topLeftRadius,
					radiusPrecision,
					_fillColor,
					_fillTexture
				);

				roundRectangleMesh.x = x + (width * 0.5);
				roundRectangleMesh.y = y + (height * 0.5);
				roundRectangleMesh.alpha = _fillAlpha;
				roundRectangleMesh.rotation = angle;

				if(_fillDrawInBack)
				{
					_container.addChildAt(roundRectangleMesh, 0);
				}
				else
				{
					_container.addChild(roundRectangleMesh);
				}
			}

			if(_strokeStyleSet && !_pauseStroke)
			{
				// Null the currentFill after storing it in a local var.
				// This ensures the moveTo/lineTo calls for the stroke below don't
				// end up adding any points to a current fill (as we've already done
				// this in a more efficient manner above).
				storedFill = _currentFill;
				storedIsFillSet = _fillStyleSet;

				_currentFill = null;
				_fillStyleSet = false;

				roundedRect.width = width;
				roundedRect.height = height;
				roundedRect.topLeftRadius = topLeftRadius;
				roundedRect.topRightRadius = topRightRadius;
				roundedRect.bottomLeftRadius = bottomLeftRadius;
				roundedRect.bottomRightRadius = bottomRightRadius;

				roundedRect.radiusPrecision = radiusPrecision;

				m = new Matrix();
				m.scale(width, height);

				if(_fillMatrix)
				{
					m.concat(_fillMatrix);
				}

				roundedRect.uvMatrix = m;
				roundedRect.x = x;
				roundedRect.y = y;

				strokePoints = roundedRect.getStrokePoints();

				for(i = 0; i < strokePoints.length; i+=2)
				{
					if (i == 0)
					{
						moveTo(x + strokePoints[i], y + strokePoints[i + 1]);
					}
					else
					{
						lineTo(x + strokePoints[i], y + strokePoints[i + 1]);
					}
				}

				_currentFill = storedFill;
				_fillStyleSet = storedIsFillSet;
			}
			
			return this;
		}
		
		
		/**
		 * Used for geometry level hit tests. 
		 * False gives boundingbox results, True gives geometry level results.
		 * True is a lot more exact, but also slower. 
		 */
		public function set precisionHitTest(value:Boolean):void
		{
			_precisionHitTest = value;
			if ( _currentFill )
			{
				_currentFill.precisionHitTest = value;
			}
			if ( _currentStroke )
			{
				_currentStroke.precisionHitTest = value;
			}
		}
		
		public function get precisionHitTest():Boolean 
		{
			return _precisionHitTest;
		}
		
		public function set precisionHitTestDistance(value:Number):void
		{
			_precisionHitTestDistance = value;
			if ( _currentFill )
			{
				_currentFill.precisionHitTestDistance = value;
			}
			if ( _currentStroke )
			{
				_currentStroke.precisionHitTestDistance = value;
			}
			
		}
		
		public function get precisionHitTestDistance() : Number
		{
			return _precisionHitTestDistance;
		}
		
		
		/////////////////////////////////////////////////////////////////////////////////////////
		// PROTECTED
		/////////////////////////////////////////////////////////////////////////////////////////
		
		////////////////////////////////////////
		// Overridable functions for custom
		// Fill/Stroke types
		////////////////////////////////////////
		
		protected function createStrokeInstance():Stroke
		{
			return new Stroke();
		}
		
		protected function createFillInstance():Fill
		{
			return new Fill();
		}
		
		public function get currentStroke():Stroke
		{
			return _currentStroke;
		}

		public function get currentFill():Fill
		{
			return _currentFill;
		}
		
		/**
		 * Creates a Stroke instance and inits its material based on the
		 * currently set stroke style.
		 * Result is stored in _currentStroke.
		 */
		protected function createStroke():void
		{
			if ( _currentStroke != null )
			{
				throw( new Error( "Current stroke should be disposed via endStroke() first." ) );
			}
			
			_currentStroke = createStrokeInstance();
			_currentStroke.precisionHitTest = _precisionHitTest;
			_currentStroke.precisionHitTestDistance = _precisionHitTestDistance;
			_currentStroke.boundsBufferX = _boundsBufferX;
			_currentStroke.boundsBufferY = _boundsBufferY;

			if(_strokeMaterial)
			{
				_currentStroke.material = _strokeMaterial;
			}
			else if (_strokeTexture)
			{
				_currentStroke.material.texture = _strokeTexture;
			}
			
			_currentStroke.material.color = _strokeColor;
			_currentStroke.material.alpha = _strokeAlpha;
			
			if(_strokeDrawInBack)
			{
				_container.addChildAt(_currentStroke, 0);
			}
			else
			{
				_container.addChild(_currentStroke);
			}
			
			// pen position is valid so that means that it was drawn with stroke before 
			// and now stroke just changed properties(color, texture, thickness, alpha
			if(_penPosX == _penPosX && _penPosY == _penPosY)
			{
				_currentStroke.addVertex(_penPosX, _penPosY, _strokeThickness);
			}

			_currentStroke.jointType = _strokeJointType;
		}
		
		/**
		 * Creates a Fill instance and inits its material based on the
		 * currently set fill style.
		 * Result is stored in _currentFill.
		 */
		protected function createFill():void
		{
			if ( _currentFill != null )
			{
				throw( new Error( "Current stroke should be disposed via endFill() first." ) );
			}
			
			_currentFill = createFillInstance();
	
			_currentFill.boundsBufferX = _boundsBufferX;
			_currentFill.boundsBufferY = _boundsBufferY;
			
			if ( _fillMatrix )
			{
				_currentFill.uvMatrix = _fillMatrix;
			}
			_currentFill.precisionHitTest = _precisionHitTest;
			_currentFill.precisionHitTestDistance = _precisionHitTestDistance;
			

			if(_fillMaterial)
			{
				_currentFill.material = _fillMaterial;
			}
			else if(_fillTexture)
			{
				_currentFill.material.texture = _fillTexture;
			}
			
			if(_fillMatrix)
			{
				_currentFill.uvMatrix = _fillMatrix;
			}
			
			_currentFill.material.color = _fillColor;
			_currentFill.material.alpha = _fillAlpha;
			
			if(_fillDrawInBack)
			{
				_container.addChildAt(_currentFill, 0);	
			}
			else
			{
				_container.addChild(_currentFill);	
			}

			// update fill with current pen position if valid (is not NaN)
			if(_penPosX == _penPosX && _penPosY == _penPosY)
			{
				_currentFill.addVertex(_penPosX, _penPosY);	
			}
		}
	}
}
