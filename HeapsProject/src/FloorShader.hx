package;

class FloorShader extends hxsl.Shader {
	static var SRC = {

		@input var input : {
			var position : Vec3;
			var normal : Vec3;
			var color : Vec4;
		};

		var output : {
			var position : Vec4;
			var color : Vec4;
			var depth : Float;
			var normal : Vec3;
			var worldDist : Float;
		};
		
		@param var color : Vec4;

		//var transformedNormal : Vec3;
		//@param var materialColor : Vec4;
		//@param var transformMatrix : Mat4;
		//function vertex() {
		//    output.position = vec4(input.position,1.) * transformMatrix;
		//    transformedNormal = normalize(input.normal * mat3(transformMatrix));
		//}

		function fragment() {
			//output.position.z -= 10.0;
			//output.color = materialColor;sa
			//output.normal = transformedNormal;
			output.color.x *= input.color.x;
			output.color.y *= input.color.y;
			output.color.z *= input.color.z;
			//output.color.w = output.color.w * input.color.w;
		}
    };
}