package;

import format.abc.Data.ABCData;

class WaterVolume {
	public var parentWV(default, null):WaterVolume;
	public var childWVs(default, null):Array<WaterVolume>;
	public var childTiles(default, default):Array<Tile>;
	public var deeperTiles(default, default):Array<Tile>;
	public var minHeight(default, null):Float;
	public var maxHeight(default, null):Float;
	// water inside:
	//public var maxVolumeTotal(default, null):Float;
	// public var curVolumeTotal(default, null):Float = 0.0;
	public var maxVolume(default, null):Float;
	public var curVolume(default, null):Float = 0.0;
	public var curVolumeNormalized(default, null):Float = 0.0;
	//
	static var tempTilesToAddWater = new Array<Tile>();
	var tempChildrenToFill = new Array<WaterVolume>();

	//

	public function new(parent:WaterVolume) {
		parentWV = parent;
		childWVs = new Array<WaterVolume>();
		childTiles = new Array<Tile>();
		deeperTiles = new Array<Tile>();
	}

	public function setHeights(min:Float, max:Float) {
		minHeight = min;
		maxHeight = max;
		maxVolume = (maxHeight - minHeight) * (childTiles.length + deeperTiles.length);
		//trace("Water Volume with " + childTiles.length + " child tiles and " + deeperTiles.length + " deeper tiles has " + maxVolume + " volume");
	}

	//public function setTotalMaxVolume() {
	//	maxVolumeTotal = maxVolume;
	//	for (c in childWVs) { maxVolumeTotal += c.maxVolumeTotal; }
	//	//trace("Water Volume with " + childTiles.length + " child tiles and " + deeperTiles.length + " deeper tiles has " + maxVolumeTotal + " TOTAL volume and " + maxVolume + " volume");
	//}

	public function getVolumeAndBelow() {
		var volume = curVolume;
		for (c in childWVs) { volume += c.getVolumeAndBelow(); }
		return volume;
	}

	public function getVolumeOfCompleteWaterBody():Float {
		if (curVolume <= 0.0001) { return 0.0; }
		var tmp = this;
		while (tmp.curVolume >= tmp.maxVolume) { tmp = parentWV; }
		return tmp.getVolumeAndBelow();
	}

	function addVolume(water:Float, total:Float) {
		curVolume += water;
		curVolumeNormalized = curVolume / maxVolume;
		//curVolumeTotal += total;
		//if (parentWV != null) { parentWV.addVolume(0.0, water);}
	}

	function getDistanceToTile(sourceTile:Tile):Float {
		var curDist = 1000000000.0;
		for (ct in childTiles) {
			var dist = Math.abs(sourceTile.x - ct.x) + Math.abs(sourceTile.y - ct.y);
			if (curDist > dist) { curDist = dist; }
		}
		for (ct in deeperTiles) {
			var dist = Math.abs(sourceTile.x - ct.x) + Math.abs(sourceTile.y - ct.y);
			if (curDist > dist) { curDist = dist; }
		}
		return curDist;
	}

	function getNearestTempWV(sourceTile:Tile):WaterVolume {
		if (sourceTile == null || tempChildrenToFill.length == 0) { return null; }
		if (tempChildrenToFill.length == 1) { return tempChildrenToFill[0]; }
		var curDist = 1000000000.0;
		var curWV = null;
		for (c in tempChildrenToFill) {
			var dist = c.getDistanceToTile(sourceTile);
			if (curDist > dist) { curDist = dist; curWV = c; }
		}
		return curWV;
	}

	// returns the water volume that was not used up
	public function addWater(water:Float, sourceTile:Tile):Float {
		if (water < 0.00001) {
			return 0.0;
		}
		if (curVolumeNormalized >= 1.0) {
			if (parentWV != null) { return parentWV.addWater(water, sourceTile); }
			return water;
		}

		// give the tiles (soil) water

		while (true) {
			tempTilesToAddWater.resize(0);
			for (ct in childTiles) { if (ct.curWater < ct.maxWater) { tempTilesToAddWater.push(ct); } }
			for (dt in deeperTiles) { if (dt.curWater < dt.maxWater) { tempTilesToAddWater.push(dt); } }
			var i = tempTilesToAddWater.length - 1;
			if (i < 0) { break; }
			//var nearest = getNearestTempWV(sourceTile);
			//if (nearest != null) {
			//	water = tempTilesToAddWater[i].addWater(water, sourceTile);
			//	tempTilesToAddWater.remove(nearest);
			//	--i;
			//}
			if (water < 0.0001) { break; } // return 0.0; }
			var distributeWater = water > 0.001 ? water / (i + 1.0) : water;
			while (i >= 0) {
				//trace (i + ") add water to " + tempTilesToAddWater[i].x + "/" + tempTilesToAddWater[i].y);
				water += tempTilesToAddWater[i].addWater(distributeWater) - distributeWater;
				--i;
			}
			if (water < 0.0001) { break; } // return 0.0; }
		}

		while (true) {
			tempChildrenToFill.resize(0);
			for (c in childWVs) { if (c.curVolumeNormalized < 1.0) { tempChildrenToFill.push(c); } }
			var i = tempChildrenToFill.length - 1;
			if (i < 0) { break; }

			var nearest = getNearestTempWV(sourceTile);
			if (nearest != null) {
				water = tempChildrenToFill[i].addWater(water, sourceTile);
				tempChildrenToFill.remove(nearest);
				--i;
			}
			if (water < 0.0001) { return 0.0; }

			var distributeWater = water > 0.01 ? water / (i + 1.0) : water; // don't spread too thin
			while (i >= 0) {
				water += tempChildrenToFill[i].addWater(distributeWater, sourceTile) - distributeWater;
				--i;
			}
			if (water < 0.0001) { return 0.0; }
		}

		if (curVolume + water > maxVolume) {
			var diff = maxVolume - curVolume;
			water -= diff;
			addVolume(diff, diff);
			if (parentWV != null) { return parentWV.addWater(water, sourceTile); }
			return water;
		}

		// set the height

		addVolume(water, water);
		var level = minHeight + curVolumeNormalized * (maxHeight - minHeight);

		for (ct in childTiles) {
			ct.setWaterLevel(level);
		}

		for (ct in deeperTiles) {
			ct.setWaterLevel(level);
		}

		return 0.0;
	}

	// returns the water volume that was not removed
	public function removeWater(water:Float):Float {
		if (water < 0.00001) {
			return 0.0;
		}
		
		if (curVolumeNormalized >= 1.0) {
			water = parentWV.removeWater(water);
			if (water < 0.0001) { return 0.0; }
		}

		if (water >= curVolume) {
			for (ct in childTiles) {
				ct.setWaterLevel(-100000.0);
			}
			if (water == curVolume) {
				for (ct in deeperTiles) {
					ct.setWaterLevel(minHeight);
				}
			}
			
			water -= curVolume;
			addVolume(-curVolume, -curVolume);

			return water;
		}

		addVolume(-water, -water);
		var level = minHeight + curVolumeNormalized * (maxHeight - minHeight);

		for (ct in childTiles) {
			ct.setWaterLevel(level);
		}

		for (ct in deeperTiles) {
			ct.setWaterLevel(level);
		}
		
		return 0.0;
	}
}