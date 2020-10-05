package;

import hxsl.Shader;

class BillboardShader extends Shader {
    static var SRC = {
		@global var camera : { proj : Mat4, view : Mat4 };
		@global var global : { @perObject var modelView : Mat4; };
		// https://github.com/HeapsIO/heaps/blob/master/h3d/shader/BaseMesh.hx#L58
       	var relativePosition : Vec3;
       	var projectedPosition : Vec4;
       	var transformedNormal : Vec3;

		//function __init__() {
			// https://github.com/HeapsIO/heaps/blob/5a814afef7263556a105ef373527df7773d26363/h3d/shader/LineShader.hx
			// https://www.geeks3d.com/20140807/billboarding-vertex-shader-glsl/
			// https://github.com/HeapsIO/heaps/blob/5a814afef7263556a105ef373527df7773d26363/h3d/shader/ParticleShader.hx
			// https://en.wikibooks.org/wiki/GLSL_Programming/Unity/Billboards
			// https://github.com/HeapsIO/heaps/blob/5a814afef7263556a105ef373527df7773d26363/h3d/shader/GpuParticle.hx
		//}

		function vertex() {
			var _BillboardSize = 1.0;

            // https://forum.unity.com/threads/problem-with-billboard-shader.681196/
			var vpos = (relativePosition * global.modelView.mat3()) * vec3(_BillboardSize, _BillboardSize, 1.0);
			var worldCoord = vec4(0,0,0,1) * global.modelView;
			var viewPos = worldCoord * camera.view + vec4(vpos, 0.0);
			projectedPosition = viewPos * camera.proj;
		}
    };
}