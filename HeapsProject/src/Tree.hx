package;

import h3d.mat.Material;
import h3d.Vector;
import hxd.Res;
import h3d.col.Point;
import hxd.res.Model;
import h3d.scene.Object;
import h3d.prim.ModelCache;

class Tree {
	public static final AGE_COUNT = 5;
	static final MODELS = [
		{ name:"Tree_01_01", scale:0.48, model:null },
		{ name:"Tree_01_02", scale:0.36, model:null },
		{ name:"Tree_01_03", scale:0.32, model:null },
		{ name:"Tree_01_04", scale:0.34, model:null },
		{ name:"Tree_01_05", scale:0.32, model:null },
	];

	static var cache:ModelCache;
	//
	public var obj(default, null):Object;
	public var index(default, null):Int;
	public var age(default, null) = 0.0;
	public var growth(default, null) = 0.0;
	public var isThirsty(default, null) = false;
	public var isDrowning(default, null) = false;
	public var deathFactor(default, null) = 0.0;
	//
	var parchPerTick = 0.05;
	var drownPerTick = 0.05;
	var rejuvenatePerTick = 0.01;
	var growthPerTick = 0.02;
	var drinkNeededPerTick = 0.02;
	var drownToleranceVolumeMin = 0.2;
	var drownToleranceVolumeMax = 0.6;
	//
	var mat:Material;
	var tile:Tile;
	var parent:Object;
	var rotation:Float;
	var position:Point;

	//

	public function new(tile:Tile, index:Int, position:Point, parent:Object) {
		this.tile = tile;
		this.index = index;
		this.position = position;
		this.parent = parent;
		rotation = hxd.Math.random(hxd.Math.PI * 2.0);
		setIndex(index);
	}

	public function tick(dt:Float) {
		age += dt;

		var waterToRemove = drinkNeededPerTick * dt;
		var waterNotRemoved = tile.removeWater(tile.wv.removeWater(waterToRemove * 0.35));
		for (n in tile.neighbours) { waterNotRemoved = n.removeWater(n.wv.removeWater((waterToRemove * 0.65) / tile.neighbours.length)); }
		var thirstFactor = (waterNotRemoved / waterToRemove);
		var drownFactor = 0.0;
		if (waterNotRemoved <= 0.0) {
			drownFactor = hxd.Math.clamp((tile.waterLevel - drownToleranceVolumeMin) / drownToleranceVolumeMax, 0.0, 1.0);
		}

		isThirsty = thirstFactor > 0.0;
		isDrowning = drownFactor > 0.0;

		deathFactor = isThirsty || isDrowning
			? Math.min(deathFactor + (parchPerTick * thirstFactor + drownPerTick * drownFactor) * dt, 1.0)
			: Math.max(deathFactor - rejuvenatePerTick * dt, 0.0);

		var liveFactor = 1.0 - deathFactor;
		mat.color = new Vector(1 * liveFactor, 1 * liveFactor, 1 * liveFactor, 1 * liveFactor);


		if (deathFactor >= 1.0) {
			tile.removeTree();
			return;
		}

		if (growth < 1.0) {
			growth = Math.min(growth + (1.0 - thirstFactor) * growthPerTick * dt, 1.0);
			if (index >= 4) { return; }
			else if (index == 3 && growth >= 1.00) { change(4); }
			else if (index == 2 && growth >= 0.75) { change(3); }
			else if (index == 1 && growth >= 0.50) { change(2); }
			else if (index == 0 && growth >= 0.25) { change(1); }
		}
	}

	public function destroy() {
		if (obj != null) {
			obj.remove();
			obj = null;
		}
	}

	public function change(index:Int) {
		if (this.index == index) {
			return;
		}
		if (obj != null) {
			obj.remove(); // TODO pool?
			obj = null;
		}
		this.index = index;
		setIndex(index);
	}

	//

	function setIndex(index:Int) {
		// https://heaps.io/documentation/fbx-models.html
		if (cache == null) {
			cache = new h3d.prim.ModelCache();
			for (m in MODELS) {
				var res = Res.loader.load("models/" + m.name + ".fbx");
				if (res == null) { trace("ERROR: " + m.name + " not found"); return; }
				m.model = res.toModel();
			}
			// cache.loadLibrary(hxd.Res.models.Tree_01_01);
		}

		obj = cache.loadModel(MODELS[index].model);
		parent.addChild(obj);
		obj.scale(MODELS[index].scale * 0.01); // TODO
		obj.setRotation(0, 0, rotation);
		obj.setPosition(position.x, position.y, position.z);
		mat = obj.getMaterials()[0];
	}
}