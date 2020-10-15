package;

class WaterShader extends hxsl.Shader {
	static var SRC = {

		@input var input : {
			var normal : Vec3;
		};

		//var output : {
		//	var color : Vec4;
		//};
		
		var pixelColor : Vec4;

		function fragment() {
			var side = 1.0 - input.normal.z;
			if (side > 0.1) {
				pixelColor.r *= 0.5;
				pixelColor.g *= 0.5;
				pixelColor.b *= 0.5;
				pixelColor.a *= 1.2;
			}
		}
    };
}