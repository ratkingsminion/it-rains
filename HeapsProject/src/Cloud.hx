package;

import h3d.Vector;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.prim.Cube;
import h3d.scene.Object;

class Cloud {

	static var material:Material;

	public var obj(default, null):Object;
	//
	var waitTicksBeforeMove = 2.0;
	var amountOfRainPerTick = 1.0;
	var z = 2;
	//
	var floor:Floor;
	var curPos = { x:0, y:0 };
	var curWait = 0.0;
	var rain:Rain;

	//

	public function new(parent:Object, floor:Floor, x:Int, y:Int) {
		this.floor = floor;
		
		var mesh = new Cube(0.9, 0.6, 0.2, true); // TODO
		mesh.addUVs();
		mesh.addNormals();

		if (material == null) {
			material = Material.create();
			material.blendMode = Alpha;
			material.color = new Vector(1, 1, 1, 0.7);
			material.castShadows = false;
		}

		obj = new Mesh(mesh, material, parent);
		obj.setPosition(x, y, 2.0);
		curPos.x = x;
		curPos.y = y;

		curWait = waitTicksBeforeMove;

		rain = new Rain(obj);
	}

	public function tick(windX:Int, windY:Int, dt:Float):Bool {
		curWait -= dt;

		if (curWait <= 0.0) {
			curWait = waitTicksBeforeMove;
			curPos.x += windX;
			curPos.y += windY;
			obj.x = curPos.x;
			obj.y = curPos.y;
		}

		return floor.addWater(curPos.x, curPos.y, amountOfRainPerTick * dt);
	}

	public function destroy() {
		rain.destroy();
		obj.remove();
	}
}