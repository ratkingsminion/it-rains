package;

import h3d.scene.Object;
import h3d.mat.BlendMode;
import h3d.prim.UV;
import h3d.col.Point;
import h3d.scene.Mesh;
import h3d.mat.Material;

class Billboard {
	public function new(file:String, parent:Object, x:Float, y:Float, z:Float = 0.0) {
		//var quad = new h3d.prim.Quads(
		//	[ new Point(0.5, -0.5, 0.0), new Point(-0.5, -0.5, 0.0), new Point(0.5, 0.5, 0.0), new Point(-0.5, 0.5, 0.0) ], // points
		//	[ new UV(0, 1), new UV(1, 1), new UV(0, 0), new UV(1, 0) ], // uvs
		//	[ new Point(0, 0, 1), new Point(0, 0, 1), new Point(0, 0, 1), new Point(0, 0, 1) ] // normals
		//);
		var quad = new h3d.prim.Quads( // pivot on bottom
			[ new Point(0.5,0.0, 0.0), new Point(-0.5, 0.0, 0.0), new Point(0.5, 1.0, 0.0), new Point(-0.5, 1.0, 0.0) ], // points
			[ new UV(0, 1), new UV(1, 1), new UV(0, 0), new UV(1, 0) ], // uvs
			[ new Point(0, 0, 1), new Point(0, 0, 1), new Point(0, 0, 1), new Point(0, 0, 1) ] // normals
		);
		var mat = Material.create(Layout.getTexture(file));
		mat.blendMode = BlendMode.Alpha;
		var mesh = new Mesh(quad, mat, parent);
		mat.shadows = false;
		var bs = new BillboardShader();
		mat.mainPass.addShader(bs);
		mesh.setPosition(x, y, z);

		//var time = 0.0;
		//Main.updates.push((dt:Float) -> {
		//	time += dt;
		//	mesh.rotate(0.0, 0.0, dt);
		//	//mesh.z = z + Math.sin(time * 2.0) * 0.1;
		//});
	}
}