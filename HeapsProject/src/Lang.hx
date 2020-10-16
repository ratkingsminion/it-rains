package;

enum LangType { English; German; }

class Lang {
	public static var lang:LangType = English;

	public inline static function start():String {
		return switch(lang) {
			default: 		"IT RAINS\n\na sandbox simulation game by ratrogue\nfholio.de | ratking.de\n\nmade for the Climate Change: Trial & Error Game Jam 2020";
			case German:	"IT RAINS\n\neine Sandbox-Simuation von ratrogue\nfholio.de | ratking.de\n\nentstanden für den Climate Change: Trial & Error Game Jam 2020";
		}
	}

	public inline static function lose():String {
		return switch(lang) {
			default:		"There is no more tree in your world.\n\nTry again!";
			case German:	"Es gibt keine Bäume mehr in deiner Welt.\n\nVersuch's noch einmal!";
		}
	}

	public inline static function help():String {
		return switch(lang) {
			default: 		"Try to keep your forest alive as long as possible in this sandbox simulation game. From time to time the wind direction changes.\n\nTo add a cloud for rain, hover a tile and press LMB. Rotate the camera by keeping RMB pressed, and move it with MMB. The scroll wheel zooms in and out. To (un)pause the game, use the button in the top right corner.";
			case German:	"In diesem Sandbox-Simulation-Game musst du deinen Wald so lange wie möglich am Leben halten. Ab und zu ändert sich die Windrichtung.\n\nFüge eine Regenwolke hinzu, indem du ein Stück Erdboden anklickst. Rotiere die Kamera mit dem rechten Mausbutton, bewege sie mit dem mittleren. Mit dem Scrollrad zoomst du rein und raus. Um das Spiel zu pausieren, drücke den Button rechts oben.";
		}
	}

	public inline static function confirmReset():String {
		return switch(lang) {
			default: 		"Do you really want to restart the game?";
			case German:	"Willst du das Spiel wirklich abbrechen und neustarten?";
		}
	}

	public inline static function no():String {
		return switch(lang) {
			default: 		"No";
			case German:	"Nein";
		}
	}

	public inline static function yes():String {
		return switch(lang) {
			default: 		"Yes";
			case German:	"Ja";
		}
	}

	public inline static function ok():String {
		return switch(lang) {
			default: 		"OK";
			case German:	"OK";
		}
	}

	public inline static function days(d:Int, t:Float):String {
		return switch(lang) {
			default: 		"Days: " + d + "\nTree Population: " + Std.int(t * 100.0) + "%";
			case German:	"Tage: " + d + "\nBaumpopulation: " + Std.int(t * 100.0) + "%";
		}
	}

	public inline static function tileInfo(tile:Tile):String {
		var str = "";
		switch(lang) {
			default:
				if (tile.tree != null) {
					str += "\nTree age: " + Std.int(tile.tree.age) + " day(s)";
					str += "\nTree growth: " + Helpers.floatToStringPrecision(tile.tree.growth * 100.0, 1) + "%";
					str += "\nTree health: " + Std.int((1.0 - tile.tree.deathFactor) * 100.0) + "%";
					if (tile.tree.thirstFactor > 0.0) {
						str += " (Thirst: " + Helpers.floatToStringPrecision(tile.tree.thirstFactor * 100.0, 1) + "%)";
					}
					if (tile.tree.drownFactor > 0.0) {
						str += " (Drowning: " + Helpers.floatToStringPrecision(tile.tree.drownFactor * 100.0, 1) + "%)";
					}
					str += "\n";
				}
				str += "Soil humidity: " + Helpers.floatToStringPrecision((tile.curWater / tile.maxWater) * 100.0, 1) + "%";
				if (tile.waterLevel > 0.0) { str += " + " + Helpers.floatToStringPrecision(tile.waterLevel * 100, 1) + " litre(s) water"; }
			
			case German:
				if (tile.tree != null) {
					str += "\nBaumalter: " + Std.int(tile.tree.age) + " Tag(e)";
					str += "\nBaumwachstum: " + Helpers.floatToStringPrecision(tile.tree.growth * 100.0, 1) + "%";
					str += "\nBaumgesundheit: " + Std.int((1.0 - tile.tree.deathFactor) * 100.0) + "%";
					if (tile.tree.thirstFactor > 0.0) {
						str += " (Durst: " + Helpers.floatToStringPrecision(tile.tree.thirstFactor * 100.0, 1) + "%)";
					}
					if (tile.tree.drownFactor > 0.0) {
						str += " (Ertrinken: " + Helpers.floatToStringPrecision(tile.tree.drownFactor * 100.0, 1) + "%)";
					}
					str += "\n";
				}
				str += "Bodenfeuchtigkeit: " + Helpers.floatToStringPrecision((tile.curWater / tile.maxWater) * 100.0, 1) + "%";
				if (tile.waterLevel > 0.0) { str += " + " + Helpers.floatToStringPrecision(tile.waterLevel * 100, 1) + " Liter Wasser"; }
		}
		return str;
	}
}