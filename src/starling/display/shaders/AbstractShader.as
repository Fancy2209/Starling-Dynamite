package starling.display.shaders
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.utils.ByteArray;
	
	import starling.textures.Texture;
	
	public class AbstractShader implements IShader
	{
		private static var assembler:AGALMiniAssembler;

		protected var _opCode:ByteArray;
		
		public function AbstractShader()
		{
		}
		
		public function get opCode():ByteArray
		{
			return _opCode;
		}
		
		protected function compileAGAL(shaderType:String, agal:String):void
		{
			if(!assembler) assembler = new AGALMiniAssembler();

			assembler.assemble(shaderType, agal);
			_opCode = assembler.agalcode;
		}
		
		public function updateTextureAgal(texture:Texture):void
		{
		}
		
		public function setConstants( context:Context3D, firstRegister:int ):void
		{
			
		}
	}

}