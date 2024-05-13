package starling.display.shaders.fragment
{
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	
	import starling.display.shaders.AbstractShader;
	import starling.textures.Texture;
	
	/*
	* A pixel shader that multiplies a single texture with constants (the color transform) and vertex color
	*/
	public class TextureVertexColorFragmentShader extends AbstractShader
	{
		private var textureTypeFormat:String;
		
		public function TextureVertexColorFragmentShader(textureType:String = null)
		{
			textureTypeFormat = textureType;
		}
		
		override public function updateTextureAgal(texture:Texture):void
		{
			var formatFlag:String;
			
			switch (textureTypeFormat)
			{
				case Context3DTextureFormat.COMPRESSED:
					formatFlag = "dxt1"; break;
				case Context3DTextureFormat.COMPRESSED_ALPHA:
					formatFlag = "dxt5"; break;
				default:
					formatFlag = "rgba";
			}

			var agal:String = 
				"tex ft1, v1, fs0 <2d, repeat, linear, "+formatFlag+"> \n" +
				"mul ft2, v0, fc0 \n" +
				"mul oc, ft1, ft2";
			
			compileAGAL(Context3DProgramType.FRAGMENT, agal);		
		}
	}
}