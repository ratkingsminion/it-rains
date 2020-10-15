package;

import haxe.ds.IntMap;
import h3d.prim.UV;
import h3d.prim.Quads;
import h3d.col.Point;
import h3d.Vector;
import h3d.scene.Mesh;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.scene.Object;

class Tile {
	
	static var waterQuads:IntMap<Quads> = new IntMap<Quads>();
	static var waterMaterial:Material;

	public var x(default, null):Int;
	public var y(default, null):Int;
	public var pos(default, null):Point;
	public var directNeighbours(default, null):Array<Tile>;
	public var neighbours(default, null):Array<Tile>;
	public var wv:WaterVolume;
	public var tree(default, null):Tree;
	public var curWater(default, null):Float = 0.0;
	public var waterLevel(default, null):Float = 0.0;
	public var maxWater(default, null):Float = 0.5; // 0.5; // TODO;
	//
	var neighbourWVs:Array<WaterVolume>;
	var parent:Object;
	var waterMesh:Mesh;

	//

	public function new(x:Int, y:Int, pos:Point, parent:Object) {
		this.x = x;
		this.y = y;
		this.pos = pos;
		this.parent = parent;
		neighbours = new Array<Tile>();
		directNeighbours = new Array<Tile>();
	}

	public function tick(dt:Float) {
		if (tree != null) {
			tree.tick(dt);
		}
	}

	public function info():String {
		var str = "Tile (" + x + "/" + y + ") with " + Helpers.floatToStringPrecision((curWater / maxWater) * 100.0, 1) + "% water.";
		//str += "\nThere is " + Helpers.floatToStringPrecision(wv.getVolumeAndAbove() * 100, 1) + " litres water above the tile, and " + Helpers.floatToStringPrecision(wv.getVolumeOfCompleteWaterBody() * 100, 1) + " litres overall in the water body.";
		str += "\nThere is " + Helpers.floatToStringPrecision(waterLevel * 100, 1) + " litres water above the tile.";
		//str += "\nThere is " + Helpers.floatToStringPrecision(wv.getVolumeOfCompleteWaterBody() * 100, 1) + " litres overall in the water body.";
		if (tree != null) { return str += "\n\n" + tree.info(); }
		return str;
	}

	//

	public function addTree(fromTree:Tree = null):Bool {
		if (tree != null) { return false; }
		tree = new Tree(this, 0, pos, parent, fromTree);
		return true;
	}

	public function removeTree():Bool {
		if (tree == null) { return false; }
		tree.destroy();
		tree = null;
		return true;
	}

	// returns the rest
	public function addWater(water:Float):Float {
		if (water < 0.0001) {
			return 0.0;
		}
		if (curWater >= maxWater) {
			return water;
		}
		curWater += water;
		if (curWater > maxWater) {
			var diff = curWater - maxWater;
			curWater = maxWater;
			return diff;
		}
		return 0.0;
	}

	// returns the rest
	public function removeWater(water:Float):Float {
		if (water < 0.0001) {
			return 0.0;
		}
		if (curWater <= 0.0) {
			return water;
		}
		curWater -= water;
		if (curWater < 0.0) {
			var diff = -curWater;
			curWater = 0.0;
			return diff;
		}
		return 0.0;
	}

	// this only adds a quad, for visualizing the water
	@:allow(WaterVolume)
	function setWaterLevel(level:Float) {
		waterLevel = Math.max(0.0, level - pos.z);
		if (waterLevel > 0.0) {
			if (waterMesh == null) {
				var idx = 0x0;
				if (x == 0) { idx = idx | 0x01; }
				if (x == Main.GRID_SIZE - 1) { idx = idx | 0x02; }
				if (y == 0) { idx = idx | 0x04; }
				if (y == Main.GRID_SIZE - 1) { idx = idx | 0x08; }
				if (!waterQuads.exists(idx)) {
					var min = -0.5, max = 0.5;
					var wp = [ new Point(min, min, 1.0), new Point(max, min, 1.0), new Point(min, max, 1.0), new Point(max, max, 1.0) ]; // top
					if (x == 0) { wp.push(new Point(min, min, 0.0)); wp.push(new Point(min, min, 1.0)); wp.push(new Point(min, max, 0.0)); wp.push(new Point(min, max, 1.0)); } // left
					if (x == Main.GRID_SIZE - 1) { wp.push(new Point(max, min, 1.0)); wp.push(new Point(max, min, 0.0)); wp.push(new Point(max, max, 1.0)); wp.push(new Point(max, max, 0.0)); } // right
					if (y == 0) { wp.push(new Point(min, min, 1.0)); wp.push(new Point(min, min, 0.0)); wp.push(new Point(max, min, 1.0)); wp.push(new Point(max, min, 0.0)); } // back
					if (y == Main.GRID_SIZE - 1) { wp.push(new Point(min, max, 0.0)); wp.push(new Point(min, max, 1.0)); wp.push(new Point(max, max, 0.0)); wp.push(new Point(max, max, 1.0)); } // front
					var wq = new Quads(wp);
					wq.addNormals();
					wq.addUVs();
					waterQuads.set(idx, wq);
				}
				if (waterMaterial == null) {
					waterMaterial = Material.create();
					waterMaterial.color = Vector.fromColor(0x883333ff);
					waterMaterial.mainPass.addShader(new WaterShader());
					waterMaterial.blendMode = Alpha;
				}
				waterMesh = new Mesh(waterQuads.get(idx), waterMaterial, parent);
				waterMesh.setPosition(pos.x, pos.y, pos.z);
			}
			if (waterMesh.parent == null) { parent.addChild(waterMesh); }
			//waterMesh.scaleZ = level;
			waterMesh.scaleZ = waterLevel + 0.01; // pos.z + level;
			//trace(x + "/" + y + " " + level);
		}
		else {
			waterMesh.remove();
		}
	}
}