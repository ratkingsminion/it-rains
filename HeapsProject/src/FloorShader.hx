package;

class FloorShader extends hxsl.Shader {
	static var SRC = {

		@input var input : {
			var color : Vec4;
		};

		var output : {
			var color : Vec4;
		};
		
		@param var color : Vec4;

		function fragment() {
			output.color *= input.color;
		}
    };
}