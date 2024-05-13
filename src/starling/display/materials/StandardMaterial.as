package starling.display.materials
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	
	import starling.display.shaders.IShader;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.display.shaders.fragment.VertexColorFragmentShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.RenderUtil;

	public class StandardMaterial implements IMaterial
	{
		public static var COLOR_VERTEX_SHADER:IShader = new StandardVertexShader();
		
		public static var COLOR_FRAGMENT_SHADER:IShader = new VertexColorFragmentShader();
		
		public static var TEXTURE_FRAGMENT_SHADER_COMPRESSED:IShader = new TextureVertexColorFragmentShader(Context3DTextureFormat.COMPRESSED);
		public static var TEXTURE_FRAGMENT_SHADER_COMPRESSED_ALPHA:IShader = new TextureVertexColorFragmentShader(Context3DTextureFormat.COMPRESSED_ALPHA);
		public static var TEXTURE_FRAGMENT_SHADER_COLOR:IShader = new TextureVertexColorFragmentShader();
		
		private var program:Program3D;
		
		private var _vertexShader:IShader;
		private var _fragmentShader:IShader;

		private var _alpha:Number = 1;
		private var _color:uint;
		private var _colorVector:Vector.<Number>;

		private var _materialTexture:Texture;

		public function StandardMaterial()
		{
			_vertexShader = COLOR_VERTEX_SHADER;
			_fragmentShader = COLOR_FRAGMENT_SHADER;

			_colorVector = new Vector.<Number>;
			_color = 0xFFFFFF;
		}

		public function set texture(value:Texture):void
		{
			_materialTexture = value;
			
			if(_materialTexture)
			{
				if(_materialTexture.format === Context3DTextureFormat.COMPRESSED)
				{
					_fragmentShader = TEXTURE_FRAGMENT_SHADER_COMPRESSED;
				}
				else if(_materialTexture.format === Context3DTextureFormat.COMPRESSED_ALPHA)
				{
					_fragmentShader = TEXTURE_FRAGMENT_SHADER_COMPRESSED_ALPHA;	
				}
				else
				{
					_fragmentShader = TEXTURE_FRAGMENT_SHADER_COLOR;
				}
			}
			else
			{
				_fragmentShader = COLOR_FRAGMENT_SHADER;
			}
		}

		public function get texture():Texture
		{
			return _materialTexture;
		}

		public function dispose():void
		{
			if(program)
			{
				Program3DCache.releaseProgram3D(program);
				program = null;
			}
			
			_vertexShader = null;
			_fragmentShader = null;
		}
		
		public function restoreOnLostContext():void
		{
			if(program)
			{
				Program3DCache.releaseProgram3D(program, true);
				program = null;
			}
		}
		
		public function set vertexShader(value:IShader):void
		{
			_vertexShader = value;
			
			if(program)
			{
				Program3DCache.releaseProgram3D(program);
				program = null;
			}
		}
		
		public function get vertexShader():IShader
		{
			return _vertexShader;
		}
		
		public function set fragmentShader( value:IShader ):void
		{
			_fragmentShader = value;
			
			if (program)
			{
				Program3DCache.releaseProgram3D(program);
				program = null;
			}
		}
		
		public function get fragmentShader():IShader
		{
			return _fragmentShader;
		}
		
		
		public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			_alpha = value;
		}
		
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			_color = value;
		}

		private static var finalAlpha:Number;

		public function drawTriangles(context:Context3D,
									  matrix:Matrix3D,
									  vertexBuffer:VertexBuffer3D,
									  indexBuffer:IndexBuffer3D,
									  alpha:Number = 1,
									  numTriangles:int = -1):void
		{
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_4);
			context.setVertexBufferAt(2, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_2);
			
			if(!program)
			{				
				if(_materialTexture)
				{
					_fragmentShader.updateTextureAgal(_materialTexture);
				}

				program = Program3DCache.getProgram3D(context, _vertexShader, _fragmentShader);
			}

			context.setProgram(program);

			/**
			 * 
			 * FOR TEXTURE FILLS
			 */   
			if(_materialTexture)
			{
				RenderUtil.setSamplerStateAt(0, false, TextureSmoothing.TRILINEAR, true);
				context.setTextureAt(0, _materialTexture.base);
			}

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
			_vertexShader.setConstants(context, 4);
			
			// Multiply display obect's alpha by material alpha.
			finalAlpha = _alpha * alpha;

			_colorVector[0] = ((_color >> 16) / 255) * finalAlpha;
			_colorVector[1] = (((_color & 0x00FF00) >> 8) / 255) * finalAlpha;
			_colorVector[2] = ((_color & 0x0000FF) / 255) * finalAlpha;
			_colorVector[3] = finalAlpha;

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _colorVector);

			_fragmentShader.setConstants(context, 1);

			context.drawTriangles(indexBuffer, 0, numTriangles);
		}
	}
}