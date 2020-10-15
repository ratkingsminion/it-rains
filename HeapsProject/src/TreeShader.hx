package;

class TreeShader extends hxsl.Shader {
	static var SRC = {

		@input var input : {
			var uv : Vec2;
		};

		var output : {
			var color : Vec4;
		};
		
		//@param var color : Vec4;
		@param var thirsty : Float;
		@param var drowning : Float;
		@param var thirstyTex : Sampler2D;
		@param var drowningTex : Sampler2D;

		function lerp(a:Vec4, b:Vec4, d:Float):Vec4 {
			return a * (1.0 - d) + b * d;
		}

		function fragment() {
			var thirst = lerp(output.color, thirstyTex.get(input.uv), thirsty);
			output.color = lerp(thirst, drowningTex.get(input.uv), drowning);
		}
    };
}