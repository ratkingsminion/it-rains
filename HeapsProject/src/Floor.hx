package;

import hxd.fmt.grd.Data.Color;
import haxe.ds.Vector;
import hxd.BitmapData;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import hxd.Pixels;
import h3d.mat.Texture;
import h3d.col.Plane;
import h3d.prim.UV;
import hxd.IndexBuffer;
import h3d.col.Point;
import h3d.prim.Polygon;
import h3d.scene.Object;
import h3d.col.Collider;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.col.Ray;
import hxd.Perlin;

class Floor {

	public static final COLOR_GREEN = h3d.Vector.fromColor(0xff44dd22);
	public static final COLOR_BROWN = h3d.Vector.fromColor(0xff954535);

	public var gridSize(default, null):Int;
	public var tiles(default, null) = new Array<Tile>();
	public var obj(default, null):Object;
	public var plane(default, null) = Plane.Z();
	public var fs(default, null):FloorShader;
	//
	final mountainLimit = 0.3;
	final mountainMaxHeight = 2.0;
	final valleyLimit = 0.6;
	final valleyMaxDepth = 0.8;
	//
	var perlin = new Perlin();
	var grid:Polygon;
	var meshFloor:Mesh;
	var collFloor:Collider;
	var meshWalls:Mesh;
	var collWall:Collider;
	var perlinSeed:Int;
	var fertility:Texture;
	var fertilityPixels:Pixels;

	//

	public function tick(dt:Float) {
		// vaporizing water
		var col = new h3d.Vector();
		for (t in tiles) {
			if (t.curWater > 0.0) {
				var rest = t.wv.removeWater(Main.EVAPORATE_WATER_PER_TILE_AND_TICK * dt);
				if (rest > 0.0) { t.removeWater(rest); }
			}
			// colorize the floor
			col.set(1.0, 1.0, 1.0, 1.0);
			vectorLerp(col, COLOR_GREEN, t.curWater / t.maxWater); // green when it has water
			vectorLerp(col, COLOR_BROWN, hxd.Math.clamp(t.waterLevel / 0.3, 0.0, 1.0)); // brown if it's under water
			fertilityPixels.setPixel(t.x, t.y, col.toColor());
		}

		fertility.uploadPixels(fertilityPixels);

		// probably growing trees
		// TODO shuffling?
		for (t in tiles) {
			t.tick(dt);
		}
	}

	//

	public function new(parent:Object, gridSize:Int) {
		var matFloor = Material.create(Layout.getTexture("floor3"));
		fs = new FloorShader();
		var bmpData = new BitmapData(gridSize, gridSize);
		for (x in 0...gridSize) { for (y in 0...gridSize) { bmpData.setPixel(x, y, 0xffffff); } }
		fertilityPixels = bmpData.getPixels();
		fs.fertility = fertility = Texture.fromPixels(fertilityPixels);
		fertility.filter = Nearest;
		fertility.mipMap = None;
		fertility.wrap = Clamp;
		fs.gridSize = gridSize;
		matFloor.mainPass.addShader(fs);

		var matWalls = Material.create(Layout.getTexture("floor4"));

		perlinSeed = Std.int(hxd.Math.srand(100000.0));
		perlin.normalize = true;
		this.gridSize = gridSize;

		var pointsFloor = new Array<Point>();
		var uvsFloor= new Array<UV>();
		//var colorsFloor = new Array<Point>();
		var idxBufferFloor = new IndexBuffer();
		var pointsWalls = new Array<Point>();
		var uvsWalls = new Array<UV>();
		//var colorsWalls = new Array<Point>();
		var idxBufferWalls = new IndexBuffer();

		var offset = new Point();

		// create the grid and the tiles:

		var g = gridSize - 1;

		for (y in 0...gridSize) {
			for (x in 0...gridSize) {
				offset.set(x - 0.5, y - 0.5, 0.0);
				var m  = getHeight(x + 0, y + 0);
				addQuad4(pointsFloor, uvsFloor, offset, 0.0, 0.0, 1.0, 1.0, idxBufferFloor, m, m, m, m); // middle quad

				//

				var min = -valleyMaxDepth - 0.2;
				var l = x > 0 ? getHeight(x - 1, y + 0) : min; // m;
				var r = x < g ? getHeight(x + 1, y + 0) : min; // m;
				var b = y > 0 ? getHeight(x + 0, y - 1) : min; // m;
				var f = y < g ? getHeight(x + 0, y + 1) : min; // m;
				if (m - l > 0.0) {
					addQuad4(pointsWalls, null, offset, 0.0, 1.0,  0.0, -1.0, idxBufferWalls, m, m, l, l);
					uvsWalls.push(new UV(0.0, 0.0)); uvsWalls.push(new UV(1.0, 0.0)); uvsWalls.push(new UV(1.0, m - l)); uvsWalls.push(new UV(0.0, m - l));
				}
				if (m - r > 0.0) {
					addQuad4(pointsWalls, null, offset, 1.0, 0.0,  0.0,  1.0, idxBufferWalls, m, m, r, r);
					uvsWalls.push(new UV(0.0, 0.0)); uvsWalls.push(new UV(1.0, 0.0)); uvsWalls.push(new UV(1.0, m - r)); uvsWalls.push(new UV(0.0, m - r));
				}
				if (m - b > 0.0) {
					addQuad4(pointsWalls, null, offset, 0.0, 0.0,  1.0,  0.0, idxBufferWalls, m, b, b, m);
					uvsWalls.push(new UV(1.0, 0.0)); uvsWalls.push(new UV(1.0, m - b)); uvsWalls.push(new UV(0.0, m - b)); uvsWalls.push(new UV(0.0, 0.0));
				}
				if (m - f > 0.0) {
					addQuad4(pointsWalls, null, offset, 1.0, 1.0, -1.0,  0.0, idxBufferWalls, m, f, f, m);
					uvsWalls.push(new UV(1.0, 0.0)); uvsWalls.push(new UV(1.0, m - f)); uvsWalls.push(new UV(0.0, m - f)); uvsWalls.push(new UV(0.0, 0.0));
				}

				//

				tiles.push(new Tile(x, y, new Point(x, y, m), parent));
			}
		}

		for (y in 0...gridSize) {
			for (x in 0...gridSize) {
				var t = tiles[y * gridSize + x];
				for (yy in (y-1)...(y+2)) {
					if (yy < 0 || yy >= gridSize) { continue; }
					for (xx in (x-1)...(x+2)) {
						if (xx == x && yy == y) { continue; }
						if (xx < 0 || xx >= gridSize) { continue; }
						var n = tiles[yy * gridSize + xx];
						t.neighbours.push(n);
						if (Math.abs(x - xx) != Math.abs(y - yy)) {
							t.directNeighbours.push(n);
						}
					}
				}
			}
		}

		obj = new Object(parent);

		grid = new Polygon(pointsFloor, idxBufferFloor);
		//grid.colors = colorsFloor;
		grid.uvs = uvsFloor;
		grid.addNormals();
		meshFloor = new Mesh(grid, matFloor, obj);
		collFloor = grid.getCollider();

		var walls = new Polygon(pointsWalls, idxBufferWalls);
		//walls.colors = colorsWalls;
		walls.uvs = uvsWalls;
		walls.addNormals();
		meshWalls = new Mesh(walls, matWalls, obj);
		collWall = walls.getCollider();

		// define water volumes:

		createWaterVolume(null, tiles.copy(), 10000.0);
	}

	inline function add(a:Point, x:Float, y:Float, z:Float = 0.0):Point {
		return a.add(new Point(x, y, z));
	}

	function addQuad4(points:Array<Point>, uvs:Array<UV>, offset:Point, x:Float, y:Float, w:Float, h:Float, idxBuffer:IndexBuffer, z0:Float = 0.0, z1:Float = 0.0, z2:Float = 0.0, z3:Float = 0.0) {
		var idx = points.length;
		points.push(add(offset, x + 0.0 * w, y + 1.0 * h, z0));
		points.push(add(offset, x + 0.0 * w, y + 0.0 * h, z1));
		points.push(add(offset, x + 1.0 * w, y + 0.0 * h, z2));
		points.push(add(offset, x + 1.0 * w, y + 1.0 * h, z3));
		if (uvs != null) {
			uvs.push(new UV(0.0, 1.0));
			uvs.push(new UV(0.0, 0.0));
			uvs.push(new UV(1.0, 0.0));
			uvs.push(new UV(1.0, 1.0));
		}
		idxBuffer.push(idx + 0); idxBuffer.push(idx + 1); idxBuffer.push(idx + 2);
		idxBuffer.push(idx + 2); idxBuffer.push(idx + 3); idxBuffer.push(idx + 0);
	}

	inline function getHeight(x:Float, y:Float):Float {
		var pl = perlin.gradient(perlinSeed, x * 0.35, y * 0.35);

		if (pl < 0.0) { pl *= valleyMaxDepth; }
		else if (pl > 0.0) { pl *= mountainMaxHeight; }

		//if (pl < mountainLimit && pl > -valleyLimit) { pl = 0.0; }
		//else if (pl <= -valleyLimit) { pl = valleyMaxDepth * (pl + valleyLimit) / (1.0 - valleyLimit); }
		//else if (pl >= mountainLimit) { pl = mountainMaxHeight * (pl - mountainLimit) / (1.0 - mountainLimit); }
		return pl;
		//return pl > 0 ? 1 :  pl < 0 ? -1 : 0;
	}

	inline function middle2(a:Float, b:Float):Float {
		return (a + b) * 0.5;
	}
	inline function middle4(a:Float, b:Float, c:Float, d:Float):Float {
		return (a + b + c + d) * 0.25;
		//return if (a > b && a > c && a > d) a else if (b > a && b > c && b > d) b else if (c > a && c > b && c > d) c else d;
	}

	function createWaterVolume(parent:WaterVolume, tilesBelow:Array<Tile>, curTileMaxHeight:Float):WaterVolume {
		var wv = new WaterVolume(parent);
		if (parent != null) { parent.childWVs.push(wv); }

		// 0 step: for parentless - find highest tiles, those are direct children
		tilesBelow.sort((a, b) -> a.pos.z < b.pos.z ? 1 : a.pos.z > b.pos.z ? -1 : 0);
		wv.deeperTiles = tilesBelow.copy();
		var floorTileHeight = tilesBelow[0].pos.z; // this is the highest tile, because tiles are sorted top to bottom
		var count = tilesBelow.length;
		var i = 0;
		while (i < count) {
			var cur = tilesBelow[i];
			cur.wv = wv;
			if (cur.pos.z < floorTileHeight) { break; }
			wv.childTiles.push(cur);
			wv.deeperTiles.remove(cur);
			++i;
		}

		wv.setHeights(floorTileHeight, curTileMaxHeight);

		// get sub volumes
		if (wv.deeperTiles.length > 0) {
			var tilesToCheck = wv.deeperTiles.copy();
			while (tilesToCheck.length > 0) {
				var newDeeperTiles = new Array<Tile>();
				newDeeperTiles.push(tilesToCheck.pop());
				var nim = 0;
				var foundNeighbour = false;
				do {
					foundNeighbour = false;
					var ni = newDeeperTiles.length - 1;
					while (ni >= nim) {
						var nt = newDeeperTiles[ni];
						var ci = tilesToCheck.length - 1;
						while (ci >= 0) {
							var ct = tilesToCheck[ci];
							if (((ct.x + 1 == nt.x || ct.x - 1 == nt.x) && ct.y == nt.y) || ((ct.y + 1 == nt.y || ct.y - 1 == nt.y) && ct.x == nt.x)) {
								newDeeperTiles.push(ct);
								tilesToCheck.splice(ci, 1);
								foundNeighbour = true;
							}
							--ci;
						}
						--ni;
					}
					++nim;
				} while (foundNeighbour);

				// 4th step: make a new watervolume for each batch of tiles (recursive)
				createWaterVolume(wv, newDeeperTiles, floorTileHeight);
			}
		}

		//wv.setTotalMaxVolume();

		return wv;
	}

	//

	public function addWater(x:Int, y:Int, water:Float):Bool {
		if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
			trace("coords " + x + "/" + y + " are not valid to add water!");
			return false;
		}
		var t = tiles[y * gridSize + x];
		water = t.addWater(water);
		if (water > 0.0) { t.wv.addWater(water, t); }
		return true;
	}

	// returns the amount of water that was not removed
	public function removeWater(x:Int, y:Int, water:Float):Float {
		if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
			trace("coords " + x + "/" + y + " are not valid to remove water!");
			return -1.0;
		}
		var t = tiles[y * gridSize + x];
		water = t.wv.removeWater(water);
		return t.removeWater(water);
	}

	//

	public function rayIntersection(ray:Ray):Float {
		if (collWall != null &&  collWall.rayIntersection(ray, true) >= 0.0) { return -1.0; }
		return collFloor.rayIntersection(ray, true);
	}

	public function rayTile(ray:Ray):Tile {
		var dist = rayIntersection(ray);
		if (dist < 0) { return null; }
		var point = ray.getPoint(dist);
		var x = hxd.Math.round(point.x);
		var y = hxd.Math.round(point.y);
		return tiles[y * gridSize + x];
	}

	// HELPERS

	public static inline function pointLerp(a:Point, b:Point, f:Float) {
		a.x = a.x * (1.0 - f) + b.x * f;
		a.y = a.y * (1.0 - f) + b.y * f;
		a.z = a.z * (1.0 - f) + b.z * f;
	}

	public static inline function pointLerp2(target:Point, a:Point, b:Point, f:Float) {
		target.x = a.x * (1.0 - f) + b.x * f;
		target.y = a.y * (1.0 - f) + b.y * f;
		target.z = a.z * (1.0 - f) + b.z * f;
	}

	public static inline function vectorLerp(a:h3d.Vector, b:h3d.Vector, f:Float) {
		a.x = a.x * (1.0 - f) + b.x * f;
		a.y = a.y * (1.0 - f) + b.y * f;
		a.z = a.z * (1.0 - f) + b.z * f;
		a.w = a.w * (1.0 - f) + b.w * f;
	}

	public static inline function vectorLerp2(target:h3d.Vector, a:h3d.Vector, b:h3d.Vector, f:Float) {
		target.x = a.x * (1.0 - f) + b.x * f;
		target.y = a.y * (1.0 - f) + b.y * f;
		target.z = a.z * (1.0 - f) + b.z * f;
		target.w = a.w * (1.0 - f) + b.w * f;
	}
}