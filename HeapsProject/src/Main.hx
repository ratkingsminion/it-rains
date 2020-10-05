package;

import h3d.Engine;
import h3d.scene.fwd.PointLight;
import h3d.Vector;
import hxd.Event.EventKind;
import hxd.Key;
import hxd.Timer;
#if js
import js.html.CanvasElement;
import js.Browser;
#end

class Main extends hxd.App {
	public static final VERSION = "v0.0.1";
	//
	public static var instance(default, null):Main;
	public static var updates(default, null) = new Array<Float->Void>();
	//
#if debug
	public var debugTxt(default, null):Text;
	var layerDebug:Object;
#end
#if js
    var canvas:CanvasElement;
#end
	var light:PointLight;

	var input_movement : Vector;
	var input_deadzone : Float = 0.2;
	var floor:Floor;
	var camYaw = 0.0;
	var camPitch = 0.5;
	var camZoom = 15.0;
	var isAddingWater:Bool;
	var addWaterX:Float;
	var addWaterY:Float;

	//

	override function init() {
		super.init();

#if js
  	 	canvas = cast Browser.document.getElementById("webgl");
        Browser.document.ondrag = e -> { e.preventDefault(); }
		hxd.Window.getInstance().propagateKeyEvents = true;
#end

		s2d.defaultSmooth = true;
		hxd.Window.getInstance().addEventTarget(onEvent);
		engine.backgroundColor = 0x112233;
		engine.autoResize = true;

		Engine.ANTIALIASING = 4;

		input_movement = new Vector(0, 0, 0, 0);
		
		//var floorTextures = [ for (i in 1...5) Layout.getTexture("floor" + i) ];
		//for (t in floorTextures) { t.filter	= Filter.Nearest; } // make it pixely
		//var floorMaterials = [ for (t in floorTextures) Material.create(t) ];

		floor = new Floor( s3d);

		// create the light		
		light = new PointLight(s3d);
		light.color.setColor(0xccffdd);
		light.params.set(0, 0.25, 0.1);
		light.setPosition(1.0, 0.5, 2.0);
		//new DirLight(new h3d.Vector(0.5, 0.5, -0.5), s3d);
		s3d.lightSystem.ambientLight.set(0.3, 0.3, 0.3);

#if debug
		// debug information
		layerDebug = new Object(s2d);
		debugTxt = new Text(Layout.getFont(), layerDebug);
		debugTxt.setScale(0.5);
		debugTxt.setPositi
#end

		//

        onResize();
	}

    //

	override function update(dt:Float) {
		var time = Timer.frameCount * 0.02;

		//s3d.camera.pos.set(Math.cos(time) * 1, 8.0, 4 + 0.7 * Math.sin(time));
		//s3d.camera.pos.set(Math.cos(time) * 7, Math.sin(time) * 7, 4 + 0.7 * Math.sin(time));
		//s3d.camera.target.set(avatar.x, avatar.y, avatar.z);
		//light.setPosition(Math.sin(time * 1.1) * 1.0, Math.cos(time * 1.11) * 0.5, 2.0);

#if js
		// automatically resize canvas to browser window size
        if (canvas != null) {
            canvas.style.width = js.Browser.window.innerWidth + "px";
            canvas.style.height = js.Browser.window.innerHeight + "px";
        }
#end

#if debug
		debugTxt.text = "CCJ 2020 " + Main.VERSION + " | " + s2d.width + "x" + s2d.height + " | " + engine.drawCalls + " | "
			+ " Scale:" + Helpers.floatToStringPrecision(Layout.SCALE, 2) + " | " + Timer.frameCount + " | " + Helpers.floatToStringPrecision(engine.fps, 1)
			+ "\nPress C to switch between ortho and perspective cam";
#end

		//if (Key.isPressed(Key.C)) {
		//	var aspect = s2d.width / s2d.height;
		//	s3d.camera.orthoBounds = s3d.camera.orthoBounds != null ? null : Bounds.fromValues(-2.5 * aspect, -2.5, 0, 5 * aspect, 5, 80);
		//}

		//Move camera
		if (input_movement.length() > input_deadzone) {
			var movement : Vector = input_movement.clone();
			movement.scale3(dt);

			camYaw += movement.x * 2.0;

			camZoom = hxd.Math.clamp(camZoom + movement.y * 10.0, 5.0, 20.0);
			input_movement.y = 0.0;

			camPitch = hxd.Math.clamp(camPitch + movement.z * 3.0, Math.PI * 0.5 * 0.1, Math.PI * 0.5 * 0.9);
		}

		if (isAddingWater) {
			addWater(dt);
		}
		
		s3d.camera.pos.set(Math.cos(camPitch) * Math.sin(camYaw) * camZoom, Math.cos(camPitch) * Math.cos(camYaw) * camZoom, Math.sin(camPitch) * camZoom);
		s3d.camera.target.set(0, 0, 0);

		for (update in updates) {
			update(dt);
		}
	}

	//

	function addWater(dt:Float) {
		var ray = s3d.camera.rayFromScreen(addWaterX, addWaterY);
		//var p = new Plane(0.0, 0.0, 1.0, 0.0);
		//var i = ray.intersect(p);
		//if (i != null) { new Billboard("tree1", s3d, i.x, i.y, 0.0); }

		//var res = floor.rayIntersection(ray);
		//if (res >= 0.0) {
		//	var hit = ray.getPoint(res);
		//	trace(hit);
		//	new Billboard("tree1", floor.mesh, hit.x, hit.y, hit.z); //, hit.x - gridSize * 0.5, hit.y - gridSize * 0.5, hit.z);
		//}

		var tile = floor.rayTile(ray);
		if (tile != null) {
			//for (t in floor.tiles) { t.setWaterLevel(-1000.0);}
			//floor.addWater(tile.x, tile.y, event.button == 0 ? 1.0 : 0.0);
			floor.addWater(tile.x, tile.y, dt * 1.5);
		}
		//if (tile != null) { tile.setWaterLevel(event.button == 0 ? 0.5 : 0.0); } // 
	}

	function onEvent(event:hxd.Event):Void {
		isAddingWater = false;

		if (event.kind == EventKind.EPush && event.button == 1) { isAddingWater = true; }
		else if (event.kind == EventKind.ERelease && event.button == 1) { isAddingWater = false; }
		if (isAddingWater) {
			addWaterX = event.relX;
			addWaterY = event.relY;
		}

		if (event.kind == EventKind.EPush && event.button == 0) {
			var ray = s3d.camera.rayFromScreen(event.relX, event.relY);
			var tile = floor.rayTile(ray);
			trace("found tile? " + tile);
			if (tile != null) { tile.addTree(); }
		}

		if (event.kind == EventKind.EWheel) { input_movement.y = event.wheelDelta; }
	
		if (event.kind == EventKind.EKeyDown) {
			if (event.keyCode >= Key.F1 && event.keyCode <= Key.F12) { return; } // don't block F keys
			if (event.keyCode >= Key.NUMBER_0 && event.keyCode <= Key.NUMBER_9) { return; } // don't block numbers
			switch( event.keyCode ){
				case Key.W, Key.UP: input_movement.y = -1;
				case Key.S | Key.DOWN: input_movement.y = 1;
				case Key.A | Key.LEFT: input_movement.x = -1;
				case Key.D | Key.RIGHT: input_movement.x = 1;
				case Key.Q: input_movement.z = -1;
				case Key.E: input_movement.z = 1;
			}
		}
		else if ( event.kind == EventKind.EKeyUp ){
			switch( event.keyCode ){
				case Key.W | Key.UP | Key.S | Key.DOWN: input_movement.y = 0;
				case Key.A | Key.LEFT | Key.D | Key.RIGHT: input_movement.x = 0;
				case Key.Q | Key.E: input_movement.z = 0;
			}
		}
	}

	override function onResize():Void {
		// automatic resize content to fit to virtual resolution
		var factor = (s2d.height / Layout.RESOLUTION.y);
		Layout.SCALE = 1.0 * factor;
		if (s2d.width / factor < Layout.RESOLUTION.x) { Layout.SCALE *= (s2d.width / factor) / Layout.RESOLUTION.x; }
		s2d.setScale(Layout.SCALE);
    }

	// 

	static function main() {
		hxd.Res.initEmbed();
		instance = new Main();
	}
}