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

	//

	public function new(parent:Object, floor:Floor, x:Int, y:Int) {
		this.floor = floor;
		
		var mesh = new Cube(0.9, 0.6, 0.2, true);
		mesh.addUVs();
		mesh.addNormals();

		if (material == null) {
			material = Material.create();
			material.blendMode = Alpha;
			material.color = new Vector(1, 1, 1, 0.4);
			material.castShadows = false;
		}

		obj = new Mesh(mesh, material, parent);
		obj.setPosition(x, y, 2.0);
		curPos.x = x;
		curPos.y = y;

		curWait = waitTicksBeforeMove;

		
		//floor.addWater(6, 4, 4.0);
		var rain = new Rain(obj);
		//rain.parts.x = 6.5;
		//rain.parts.y = 4.5;
		//rain.parts.z = 8;
	}

	public function tick(windX:Int, windY:Int, dt:Float) {
		curWait -= dt;

		if (curWait <= 0.0) {
			curWait = waitTicksBeforeMove;
			curPos.x += windX;
			curPos.y += windY;
			obj.x = curPos.x;
			obj.y = curPos.y;
		}

		floor.addWater(curPos.x, curPos.y, amountOfRainPerTick * dt);
	}
}