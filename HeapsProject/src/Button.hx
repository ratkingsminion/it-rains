package;

import h2d.TileGroup;
import hxd.Cursor;
import h2d.Font;
import h3d.Vector;
import hxd.Event;
import h2d.Tile;
import h2d.Object;
import h2d.Interactive;
import h2d.Text;
import h2d.Bitmap;

class Button {
	var bmpBack:Bitmap;
	var tgBack:TileGroup;
	//
	public var obj(default, null):Object;
	public var label(default, null):Text;
	public var interact(default, null):Interactive;
	//
	var onClick:Event->Void;
	var color:Vector;
	var colorHover:Vector;
	var colorPress:Vector;
	var labelColor:Int;
	var labelColorHover:Int;
	var labelColorPress:Int;
	var pressed:Bool;
	var hovered:Bool;
	var onHover:Bool->Void = null;
	//
	static var backTile:Tile;
	static var backSubTiles = new Array<Tile>();

	//

	public function new(x:Float, y:Float, w:Int, h:Int, parent:Object, onClick:Event->Void, unhoverOnClick = true, color = 0x377eb7, colorHover = 0xffaaff, colorPress = 0xffffaa) {
		this.onClick = onClick;

		var interactW = w;
		w -= h;

		if (backTile == null) {
			backTile = Layout.getTile("ui/button_back");
			backSubTiles.push(backTile.sub(0.0, 0.0, backTile.width * 0.5, backTile.height));
			backSubTiles.push(backTile.sub(backTile.width * 0.5, 0.0, backTile.width * 0.5, backTile.height));
		}

		obj = bmpBack = new Bitmap(Tile.fromColor(0xffffff, w, h), parent);
		bmpBack.color = this.color = Vector.fromColor(color + (0xff << 24));
		
		tgBack = new TileGroup(backTile, bmpBack);
		var tgScale = h / backTile.height;
		tgBack.setScale(tgScale);
		tgBack.add((w * -0.5 - h * 0.5) / tgScale, (h * -0.5) / tgScale, backSubTiles[0]);
		tgBack.add((w * 0.5) / tgScale, (h * -0.5) / tgScale, backSubTiles[1]);
		tgBack.color = this.color;

		this.colorHover = Vector.fromColor(colorHover + (0xff << 24));
		this.colorPress = Vector.fromColor(colorPress + (0xff << 24));
		bmpBack.tile.dx = -Std.int(w * 0.5);
		bmpBack.tile.dy = -Std.int(h * 0.5);
		interact = new Interactive(interactW, h, bmpBack);
		interact.x = -Std.int(interactW * 0.5);
		interact.y = -Std.int(h * 0.5);
		interact.cursor = Cursor.Button;
		if (!Main.instance.isOnMobileOrTablet) {
			// BROWSER / DESKTOP
			interact.onRelease = function(event:Event) {
				if (!hovered) { return; }
				if (onClick != null) { onClick(event); }
				if (unhoverOnClick) {
					if (!pressed) { bmpBack.color = this.color; if (tgBack != null) { tgBack.color = this.color; } label.textColor = labelColor; }
					hovered = false;
				}
			}
			interact.onOver = function(event:Event) {
				if (!pressed) { bmpBack.color = this.colorHover; if (tgBack != null) { tgBack.color = this.colorHover; } label.textColor = labelColorHover; }
				if (onHover != null) { onHover(true); }
				hovered = true;
			}
			interact.onOut = function(event:Event) {
				if (!pressed) { bmpBack.color = this.color; if (tgBack != null) { tgBack.color = this.color; } label.textColor = labelColor; }
				if (onHover != null) { onHover(false); }
				hovered = false;
			}
		}
		else {
			// MOBILE
			interact.onPush = function(event:Event) {
				if (onClick != null) { onClick(event); }
			}
		}
		
		bmpBack.x = x;
		bmpBack.y = y;
	}

	public function click() {
		if (onClick != null) { onClick(null); }
	}

	public function setLabel(text:String, labelFont:Font = null, ?labelColor = 0xffffff, ?labelColorHover = 0xffffff, labelColorPress = 0xffffff, scale = 1.0):Button {
		if (label == null) {
			label = new Text(labelFont == null ? Layout.getFont("button") : labelFont, bmpBack);
			label.textAlign = Align.Center;
		}
		label.text = text;
		label.setScale(scale);
		this.labelColor = labelColor != null ? labelColor : 0xffffff;
		this.labelColorHover = labelColorHover != null ? labelColorHover : 0xffffff;
		this.labelColorPress = labelColorPress;
		if (!pressed) { if (hovered) { label.textColor = this.labelColorHover; }
						else { label.textColor = this.labelColor; } }
		else { label.textColor = labelColorPress; }
		 
		label.y = label.textHeight * -0.5 * label.scaleY;
		return this;
	}

	public function setLabelText(text:String):Button {
		if (label == null) { return this; }
		label.text = text;
		return this;
	}

	public function setLabelAlign(align:Align, xOffset:Float = 0.0):Button {
		if (label == null) { return this; }
		label.textAlign = align;
		switch (align) {
			default: label.x = xOffset;
			case Left: label.x = -bmpBack.tile.width * 0.5 + 10 + xOffset;
			case Right: label.x = bmpBack.tile.width * 0.5 - 10 + xOffset;
		}
		return this;
	}

	public function setOnHover(onHover:Bool->Void):Button {
		this.onHover = onHover;
		return this;
	}

	public function setPressed(pressed:Bool):Button {
		if (!pressed) {
			if (hovered) {
				bmpBack.color = colorHover;
				if (tgBack != null) { tgBack.color = colorHover; } 
				label.textColor = labelColorHover;
			}
			else {
				bmpBack.color = color;
				if (tgBack != null) { tgBack.color = color; } 
				label.textColor = labelColor;
			}
		}
		else {
			bmpBack.color = colorPress;
			if (tgBack != null) { tgBack.color = colorPress; } 
			label.textColor = labelColorPress;
		}
		this.pressed = pressed;
		return this;
	}

	public function unhover(onlyOnMobile = true) { // used for mobile only?
		if ((onlyOnMobile && !Main.instance.isOnMobileOrTablet) || !hovered) { return; }
		if (!pressed) { bmpBack.color = this.color; if (tgBack != null) { tgBack.color = this.color; } label.textColor = labelColor; }
		if (onHover != null) { onHover(false); }
		hovered = false;
	}
}