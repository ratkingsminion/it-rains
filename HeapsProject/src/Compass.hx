package;

import h3d.Camera;
import hxd.Res;
import h3d.scene.Object;
import h3d.Vector;

class Compass {
	public var objNeedle(default, null):Object;
	public var objRing(default, null):Object;
	public var yaw(default, null):Float = 0.0;

	//

	public function new(parent:Object) {
		var resNeedle = Res.loader.load("models/compass.fbx");
		if (resNeedle == null) { trace("ERROR: compass not found"); return; }
		var resRing = Res.loader.load("models/compass_ring.fbx");
		if (resRing == null) { trace("ERROR: compass ring not found"); return; }

		objNeedle = new h3d.prim.ModelCache().loadModel(resNeedle.toModel());
		parent.addChild(objNeedle);
		objNeedle.scale(0.0003); // TODO

		objRing = new h3d.prim.ModelCache().loadModel(resRing.toModel());
		parent.addChild(objRing);
		objRing.scale(0.0003); // TODO

		// materials
		var matNeedle = objNeedle.getMaterials()[0];
		matNeedle.castShadows = false;
		matNeedle.blendMode = Alpha;
		matNeedle.color = new Vector(0.2, 0.9, 1.0, 0.6);

		var matRing = objRing.getMaterials()[0];
		matRing.castShadows = false;
		matRing.blendMode = Alpha;
		matRing.color = new Vector(0.9, 0.2, 1.0, 0.6);
	}

	public function update(cam:Camera, dt:Float) {
		cam.update();
		var pos = cam.unproject(0.0, -0.8, 0.5);
		objNeedle.setPosition(pos.x, pos.y, pos.z);
		objRing.setPosition(pos.x, pos.y, pos.z);
	}

	public function changeDir(angle:Float) {
		yaw = hxd.Math.degToRad(angle);
		objNeedle.setRotation(0.0, 0.0, yaw);

		Tweens.tween(0.0, 1.0, 0.4, f -> {
			objNeedle.setRotation(0.0, 0.0, yaw + Math.sin(f * Math.PI * 5.0) * Math.PI * 0.2 * (1 - f));
		});
	}
}