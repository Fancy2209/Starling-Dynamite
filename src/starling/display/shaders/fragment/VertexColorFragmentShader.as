package starling.display.shaders.fragment
{
	import flash.display3D.Context3DProgramType;
	
	import starling.display.shaders.AbstractShader;
	
	/*
	* A pixel shader that multiplies the vertex color by the material color transform.
	*/
	public class VertexColorFragmentShader extends AbstractShader
	{
		public function VertexColorFragmentShader()
		{
			compileAGAL( Context3DProgramType.FRAGMENT, "mul oc, v0, fc0");
		}
	}
}