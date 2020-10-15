package;

import hxd.Rand;
import h3d.mat.Material;
import h3d.Vector;
import hxd.Res;
import h3d.col.Point;
import hxd.res.Model;
import h3d.scene.Object;
import h3d.prim.ModelCache;

class Tree {
	public static final TWEEN_SECONDS_SEED = 0.5;
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
	public var thirstFactor(default, null) = 0.0;
	public var drownFactor(default, null) = 0.0;
	public var deathFactor(default, null) = 0.0;
	//
	var parchPerTick = 0.05;
	var drownPerTick = 0.05;
	var rejuvenatePerTick = 0.04;
	var growthPerTick = 0.02;
	var drinkNeededPerTick = 0.02;
	var drownToleranceVolumeMin = 0.2;
	var drownToleranceVolumeMax = 0.6;
	var seedMinGrowth = 0.35;
	var seedMaxDeathFactor = 0.8;
	var seedWaitTicks = { min:3.0, max:5.0 };
	//
	//var mat:Material;
	var shader:TreeShader;
	var tile:Tile;
	var parent:Object;
	var rotation:Float;
	var position:Point;
	var seedWait = 0.0;

	//

	public function new(tile:Tile, index:Int, position:Point, parent:Object, fromTree:Tree) {
		this.tile = tile;
		this.index = index;
		this.position = position;
		this.parent = parent;
		rotation = hxd.Math.random(hxd.Math.PI * 2.0);
		setIndex(index);
		seedWait = seedWaitTicks.min + hxd.Math.random(seedWaitTicks.max);
		if (fromTree != null) {
			var start = fromTree.position;
			var pos = new Point();
			Tweens.tween(0.0, 1.0, TWEEN_SECONDS_SEED, f -> {
				if (obj == null) { return; }
				Floor.pointLerp2(pos, start, position, f);
				pos.z += Math.sin(f * Math.PI) * 1.0;
				obj.setPosition(pos.x, pos.y, pos.z);
			}).ease(f -> f);
		}
	}

	public function tick(dt:Float) {
		age += dt;

		var waterToRemove = drinkNeededPerTick * dt;
		var waterNotRemoved = 0.0;
		var nc:Float = tile.neighbours.length;
		for (n in tile.neighbours) { waterNotRemoved += n.removeWater(n.wv.removeWater((waterToRemove * 0.5) / nc)); }
		waterNotRemoved = tile.removeWater(tile.wv.removeWater(waterToRemove * 0.5 + waterNotRemoved));
		
		thirstFactor = waterNotRemoved / waterToRemove; // TODO get water where you can
		drownFactor = hxd.Math.clamp((tile.waterLevel - drownToleranceVolumeMin) / drownToleranceVolumeMax, 0.0, 1.0);
		//drownFactor = waterNotRemoved > 0.0 ? 0.0 : hxd.Math.clamp((tile.waterLevel - drownToleranceVolumeMin) / drownToleranceVolumeMax, 0.0, 1.0);

		var isThirsty = thirstFactor > 0.01;
		var isDrowning = drownFactor > 0.01;

		deathFactor = isThirsty || isDrowning
			? Math.min(deathFactor + (parchPerTick * thirstFactor + drownPerTick * drownFactor) * dt, 1.0)
			: Math.max(deathFactor - rejuvenatePerTick * dt, 0.0);

		//var liveFactor = 1.0 - deathFactor;
		//mat.color = new Vector(1 * liveFactor, 1 * liveFactor, 1 * liveFactor, 1 * liveFactor);
		shader.thirsty = thirstFactor;
		shader.drowning = drownFactor;

		if (deathFactor >= 1.0) {
			tile.removeTree();
			return;
		}

		if (growth < 1.0) {
			//trace("l:" + deathFactor + " t:" + thirstFactor + " d:" + drownFactor);
			growth = Math.min(growth + (1.0 - thirstFactor) * (1.0 - drownFactor) * growthPerTick * dt, 1.0);
			if (index >= 4) { return; }
			else if (index == 3 && growth >= 1.00) { change(4); }
			else if (index == 2 && growth >= 0.75) { change(3); }
			else if (index == 1 && growth >= 0.50) { change(2); }
			else if (index == 0 && growth >= 0.25) { change(1); }
		}

		if (growth >= seedMinGrowth && deathFactor <= seedMaxDeathFactor) {
			seedWait -= dt;
			if (seedWait <= 0.0) {
				var ti = Std.int(hxd.Math.random(tile.directNeighbours.length));
				tile.directNeighbours[ti].addTree(this);
				seedWait += seedWaitTicks.min + hxd.Math.random(seedWaitTicks.max - seedWaitTicks.min);
			}
		}
	}

	public function info():String {
		var str = "The tree on the soil is " + Helpers.floatToStringPrecision(age, 1) + " days old and has " + Helpers.floatToStringPrecision(growth * 100.0, 1) + "% growth.";
		if (deathFactor > 0.0) {
			str += "\nThe tree is at " + Std.int((1.0 - deathFactor) * 100.0) + "% health - it is " + Helpers.floatToStringPrecision(thirstFactor * 100.0, 1) + "% thirsty and " +  Helpers.floatToStringPrecision(drownFactor * 100.0, 1) + "% drowning.";
		}
		else {
			str += "\nThe tree is 100% healthy.";
		}
		return str;
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
		var scale = MODELS[index].scale * 0.01 * 0.8; // TODO?

		parent.addChild(obj);
		obj.setScale(scale);
		obj.setRotation(0, 0, rotation);
		obj.setPosition(position.x, position.y, position.z);
		var mat = obj.getMaterials()[0];
		shader = new TreeShader();
		shader.thirstyTex = Layout.getTexture("Colorsheet Tree Dry");
		shader.drowningTex = Layout.getTexture("Colorsheet Tree Drown");
		mat.mainPass.addShader(shader);
		//var liveFactor = 1.0 - deathFactor;
		//mat.color = new Vector(1 * liveFactor, 1 * liveFactor, 1 * liveFactor, 1 * liveFactor);
		
		var wobble = Tweens.tween(0.0, 1.0, 0.7, f -> {
			if (obj != null) {
				obj.setScale(scale + scale * Math.sin(f * Math.PI * 5.0) * Math.PI * 0.15 * (1 - f));
			}
		});
		if (index == 0) { wobble.setDelay(TWEEN_SECONDS_SEED); }
	}
}