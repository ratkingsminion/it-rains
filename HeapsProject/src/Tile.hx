package;

import format.abc.Data.ABCData;
import h3d.prim.UV;
import h3d.prim.Quads;
import h3d.col.Point;
import h3d.Vector;
import h3d.scene.Mesh;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.scene.Object;

class Tile {
	
	static var waterQuad:Quads;
	static var waterMaterial:Material;

	public var x(default, null):Int;
	public var y(default, null):Int;
	public var pos(default, null):Point;
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
		if (tree != null) {
			str += "\n\nThe tree on the soil is " + Helpers.floatToStringPrecision(tree.age, 1) + " days old and has " + Helpers.floatToStringPrecision(tree.growth * 100.0, 1) + "% growth.";
			if (tree.deathFactor > 0.0) {
				str += "\nThe tree is at " + Std.int((1.0 - tree.deathFactor) * 100.0) + "% health - it is " + (tree.isThirsty ? "thirsty" : tree.isDrowning ? "drowning" : "rejuvenating");
			}
			else {
				str += "\nThe tree is 100% healthy.";
			}
		}
		return str;
	}

	//

	public function addTree():Bool {
		if (tree != null) { return false; }
		tree = new Tree(this, 0, pos, parent);
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

	// this oly adds a quad, for visualizing the water
	@:allow(WaterVolume)
	function setWaterLevel(level:Float) {
		waterLevel = Math.max(0.0, level - pos.z);
		if (waterLevel > 0.0) {
			if (waterMesh == null) {
				if (waterQuad == null) {
					var min = -0.5;
					var max = 0.5;
					waterQuad = new Quads(
						//[ new Point(-0.5, -0.5, 0.0), new Point(0.5, -0.5, 0.0), new Point(-0.5, 0.5, 0.0), new Point(0.5, 0.5, 0.0) ], // points
						[ new Point(min, min), new Point(max, min), new Point(min, max), new Point(max, max) ], // points
						[ new UV(0, 0), new UV(1, 0), new UV(0, 1), new UV(1, 1) ], // uvs
						[ new Point(0, 0, 1), new Point(0, 0, 1), new Point(0, 0, 1), new Point(0, 0, 1) ] // normals
					);
					//cube.addNormals();
					//cube.addUVs();
				}
				if (waterMaterial == null) {
					waterMaterial = Material.create();
					waterMaterial.color = Vector.fromColor(0x990000ff);
					waterMaterial.blendMode = Alpha;
				}
				waterMesh = new Mesh(waterQuad, waterMaterial, parent);
				waterMesh.setPosition(pos.x, pos.y, 0.0);
			}
			if (waterMesh.parent == null) { parent.addChild(waterMesh); }
			//waterMesh.scaleZ = level;
			waterMesh.z = level; // pos.z + level;
			//trace(x + "/" + y + " " + level);
		}
		else {
			waterMesh.remove();
		}
	}
}