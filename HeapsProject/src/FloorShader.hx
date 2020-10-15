package;

class FloorShader extends hxsl.Shader {
	static var SRC = {

		@input var input : {
			var position : Vec3;
		};

		var output : {
			var color : Vec4;
		};
		
		//@param var color : Vec4;
		@param var fertility : Sampler2D;
		@param var gridSize : Float;

		function fragment() {
			//output.color *= input.color;
			var uv = vec2(
				(input.position.x + 0.5) / gridSize,
				(input.position.y + 0.5) / gridSize
			);
			
			output.color *= fertility.get(uv);
		}
    };
}