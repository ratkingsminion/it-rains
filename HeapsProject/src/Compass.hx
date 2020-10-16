package;

import h3d.Camera;
import hxd.Res;
import h3d.scene.Object;
import h3d.Vector;

class Compass {
	public var obj(default, null):Object;
	public var yaw(default, null):Float = 0.0;

	//

	public function new(parent:Object) {
		var cache = new h3d.prim.ModelCache();
		var res = Res.loader.load("models/compass.fbx");
		if (res == null) { trace("ERROR: compass not found"); return; }
		var model = res.toModel();
		obj = cache.loadModel(model);
		parent.addChild(obj);
		obj.scale(0.0003); // TODO

		// materials
		var mat = obj.getMaterials()[0];
		mat.castShadows = false;
		mat.blendMode = Alpha;
		mat.color = new Vector(0.2, 0.9, 1.0, 0.6);

		var mat = obj.getMaterials()[1];
		mat.castShadows = false;
		mat.blendMode = Alpha;
		mat.color = new Vector(0.9, 0.2, 1.0, 0.6);
	}

	public function update(cam:Camera, dt:Float) {
		cam.update();
		var pos = cam.unproject(0.0, -0.8, 0.5);
		obj.setPosition(pos.x, pos.y, pos.z);
	}

	public function changeDir(angle:Float) {
		yaw = hxd.Math.degToRad(angle);
		obj.setRotation(0.0, 0.0, yaw);

		Tweens.tween(0.0, 1.0, 0.4, f -> {
			obj.setRotation(0.0, 0.0, yaw + Math.sin(f * Math.PI * 5.0) * Math.PI * 0.2 * (1 - f));
		});
	}
}