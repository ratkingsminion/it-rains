package;

import h3d.mat.Texture;
import h2d.Tile;
import hxd.Res;
import haxe.ds.StringMap;
import h2d.Font;

class Layout {
	public static final RESOLUTION = { x:1024, y:600 };
	//
	public static var SCALE(default, default) = 1.0;

	//

	static var tiles = new StringMap<Tile>();
	static var textures = new StringMap<Texture>();
	static var fonts = new StringMap<Font>();

	//
	
    public static function getTile(file:String, pivotX:Float = 0.5, pivotY:Float = 0.5):Tile {
		if (tiles.exists(file)) {
			return tiles.get(file);
		}
		var res = Res.loader.load("gfx/" + file + ".png");
		if (res == null) {
			trace("ERROR: " + file + " not found");
			return null;
		}
		var tile = res.toTile();
		tile.dx = Std.int(tile.width * -pivotX);
		tile.dy = Std.int(tile.height * -pivotY);
        tiles.set(file, tile);
		return tile;
	}
	
    public static function getTexture(file:String):Texture {
		if (textures.exists(file)) {
			return textures.get(file);
		}
		var res = Res.loader.load("gfx/" + file + ".png");
		if (res == null) {
			trace("ERROR: " + file + " not found");
			return null;
		}
		var texture = res.toTexture();
		texture.wrap = Repeat;
        textures.set(file, texture);
		return texture;
	}
	
	public static function getFont(type:String = "DEFAULT"):Font {
		type = type.toLowerCase();
		if (fonts.exists(type)) {
			return fonts.get(type);
		}
		var font:Font = null;
		font = switch (type) {
			// TODO different types
			default: Res.fonts.oblik_bold.toFont();
		}
        fonts.set(type, font);
		return font;
	}
}