package;

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
	public var wv:WaterVolume;
	public var maxWater(default, null):Float = 0.5; // TODO;
	public var curWater(default, null):Float = 0.0;
	//
	var neighbourWVs:Array<WaterVolume>;
	var parent:Object;
	var waterMesh:Mesh;
	var tree:Tree;

	//

	public function new(x:Int, y:Int, pos:Point, parent:Object) {
		this.x = x;
		this.y = y;
		this.pos = pos;
		this.parent = parent;
	}

	public function addTree() {
		if (tree != null) {
			if (tree.index == Tree.AGE_COUNT - 1) { return; }
			tree.change(tree.index + 1);
		}
		else {
			tree = new Tree(0, new Point(pos.x + 0.5, pos.y + 0.5, pos.z), parent);
		}
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

	public function setWaterLevel(level:Float) {
		//level = level - pos.z;
		if (level - pos.z > 0.0) {
			if (waterMesh == null) {
				if (waterQuad == null) {
					var min = 0.0;
					var max = 1.0;
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
			else {
				parent.addChild(waterMesh);
			}
			//waterMesh.scaleZ = level;
			waterMesh.z = level; // pos.z + level;
		}
		else {
			waterMesh.remove();
		}
	}
}