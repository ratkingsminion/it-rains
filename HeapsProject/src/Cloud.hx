package;

import h3d.Vector;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.prim.Cube;
import h3d.scene.Object;

class Cloud {

	public static final CLOUD_HEIGHT_OVER_START_TILE = 1.5;

	static var material:Material;

	public var obj(default, null):Object;
	public var curPos(default, null) = { x:0, y:0 };
	//
	var waitTicksBeforeMove = 2.0;
	var amountOfRainPerTick = 1.0;
	var z:Float;
	//
	var floor:Floor;
	var curWait = 0.0;
	var rain:Rain;

	//

	public function togglePause(p:Bool) {
		rain.togglePause(p);
	}

	public function new(parent:Object, floor:Floor, x:Int, y:Int, z:Float) {
		this.floor = floor;
		
		var mesh = new Cube(0.9, 0.9, 0.2, true); // TODO
		mesh.addUVs();
		mesh.addNormals();

		if (material == null) {
			material = Material.create();
			material.blendMode = Alpha;
			material.color = new Vector(1, 1, 1, 0.7);
			material.castShadows = false;
		}

		obj = new Mesh(mesh, material, parent);
		obj.setPosition(x, y, z + CLOUD_HEIGHT_OVER_START_TILE);
		curPos.x = x;
		curPos.y = y;
		this.z = z + CLOUD_HEIGHT_OVER_START_TILE;

		curWait = waitTicksBeforeMove;

		rain = new Rain(obj);

		var scale = 1.0;
		Tweens.tween(0.0, 1.0, 0.5, f -> {
			if (obj != null) {
				obj.z = z + CLOUD_HEIGHT_OVER_START_TILE * f;
				obj.setScale(scale * f);
				//obj.setScale(scale + scale * Math.sin(f * Math.PI * 5.0) * Math.PI * 0.15 * (1 - f));
			}
		});
	}

	public function tick(windX:Int, windY:Int, dt:Float):Bool {
		curWait -= dt;

		var tile = floor.getTile(curPos.x, curPos.y);
		if (curWait <= 0.0) {
			curWait = waitTicksBeforeMove;
			var nTile = floor.getTile(curPos.x + windX, curPos.y + windY);
			if (nTile != null) {
				if (nTile.pos.z < obj.z - 0.1) {
					curPos.x = nTile.x;
					curPos.y = nTile.y;
					// anim
					var startX:Float = obj.x;
					var startY:Float = obj.y;
					Tweens.tween(0.0, 1.0, 0.2, f -> {
						if (obj != null) {
							obj.x = hxd.Math.lerp(startX, nTile.x, f);
							obj.y = hxd.Math.lerp(startY, nTile.y, f);
						}
					});
					tile = nTile;
				}
			}
			else {
				var startX:Float = obj.x, startY:Float = obj.y;
				var endX = startX + windX, endY = startY + windY;
				Tweens.tween(0.0, 1.0, 0.2, f -> {
					if (obj != null) {
						obj.x = hxd.Math.lerp(startX, endX, f);
						obj.y = hxd.Math.lerp(startY, endY, f);
					}
				});
				return false;
			}
		}

		// get destroyed in water
		if (tile.pos.z + tile.waterLevel > z - 0.1) {
			return false;
		}

		return floor.addWater(curPos.x, curPos.y, amountOfRainPerTick * dt);
	}

	public function destroy() {
		rain.destroy();

		var scale = 1.0;
		var wobble = Tweens.tween(0.0, 1.0, 0.4, f -> {
			if (obj != null) {
				obj.setScale(scale * (1.0 - f));
			}
		});
		wobble.onComplete(() -> {
			if (obj != null) {
				obj.remove();
			}
		});
	}
}