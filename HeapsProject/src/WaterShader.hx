package;

class WaterShader extends hxsl.Shader {
	static var SRC = {

		@input var input : {
			var normal : Vec3;
		};

		var output : {
			var color : Vec4;
		};

		function fragment() {
			var side = 1.0 - input.normal.z;
			if (side > 0.1) {
				output.color.r *= 0.5;
				output.color.g *= 0.5;
				output.color.b *= 0.5;
				output.color.a *= 1.2;
			}
		}
    };
}