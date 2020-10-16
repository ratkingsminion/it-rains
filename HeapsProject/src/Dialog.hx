package;

import h2d.Scene;
import h2d.Interactive;
import h2d.Text;
import h2d.Graphics;
import h2d.Object;

class Dialog {
	var obj:Object;

	//
	
	public function new(text:String, scene:Scene, w:Float, h:Float, firstBtn:Void->Void, secondBtn:Void->Void = null, backColor:Int = 0x000000, backAlpha:Float = 0.8) {
		var x = scene.width * 0.5 / Layout.SCALE;
		var y = scene.height * 0.5 / Layout.SCALE;

		var interact = new Interactive(5000.0, 5000.0, scene);
		interact.cursor = Default;
		
		obj = new Object(scene);
		obj.setPosition(x, y);

		var back = new Graphics(obj);
		back.beginFill(backColor, backAlpha);
		back.drawRect(0, 0, w, h);
		back.setPosition(-w * 0.5, -h * 0.5);
		
		var txt = new Text(Layout.getFont(), back);
		txt.setPosition(20, 20);
		txt.maxWidth = (w - 40) / 0.6;
		txt.text = text;
		txt.scale(0.6);

		if (secondBtn == null) {
			new Button(w * 0.5, h - 30.0, 100, 40, back, e -> { firstBtn(); obj.remove(); interact.remove(); }).setLabel(Lang.ok(), null, 0xffffff, 0xffffff, 0xffffff, 0.6);
		}
		else {
			new Button(w * 0.5 - 55.0, h - 30.0, 100, 40, back, e -> { firstBtn(); obj.remove(); interact.remove(); }).setLabel(Lang.yes(), null, 0xffffff, 0xffffff, 0xffffff, 0.6);
			new Button(w * 0.5 + 55.0, h - 30.0, 100, 40, back, e -> { secondBtn(); obj.remove(); interact.remove(); }).setLabel(Lang.no(), null, 0xffffff, 0xffffff, 0xffffff, 0.6);
		}
	}
}