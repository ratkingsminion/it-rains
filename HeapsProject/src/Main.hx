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
	var floor:Floor;
	var hoveredTile:Tile = null;
	var camInputRotate = new Vector();
	var camInputRotateLastMousePos:Vector = null;
	var camInputMove = new Vector();
	var camInputMoveLastMousePos:Vector = null;
	var camInputZoom = 0.0;
	var camRotation = new Vector(0.5, 0.0, 0.0);
	var camPosition = new Vector(0.0, 0.0, 0.0);
	var camZoom = 15.0;
	var isAddingWater = false;

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
		
		//var floorTextures = [ for (i in 1...5) Layout.getTexture("floor" + i) ];
		//for (t in floorTextures) { t.filter	= Filter.Nearest; } // make it pixely
		//var floorMaterials = [ for (t in floorTextures) Material.create(t) ];

		floor = new Floor(s3d);

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

		var ray = s3d.camera.rayFromScreen(s2d.mouseX * Layout.SCALE, s2d.mouseY * Layout.SCALE);
		hoveredTile = floor.rayTile(ray);

		if (hoveredTile != null && isAddingWater) {
			floor.addWater(hoveredTile.x, hoveredTile.y, dt * 2.5);
		}
		
		// camera

		if (camInputRotate.length() > 0.0) {
			camRotation.x = hxd.Math.clamp(camRotation.x + camInputRotate.x * dt, Math.PI * 0.5 * 0.2, Math.PI * 0.5 * 0.9); // pitch
			camRotation.y += camInputRotate.y * dt; // yaw
		}
		camInputRotate.x = camInputRotate.y = 0.0;

		if (camInputMove.length() > 0.0) {
			camPosition.x = hxd.Math.clamp(camPosition.x - (Math.sin(camRotation.y) * camInputMove.y + Math.cos(camRotation.y) * camInputMove.x) * dt, -floor.gridSize * 0.5, floor.gridSize * 0.5);
			camPosition.y = hxd.Math.clamp(camPosition.y - (Math.cos(camRotation.y) * camInputMove.y - Math.sin(camRotation.y) * camInputMove.x) * dt, -floor.gridSize * 0.5, floor.gridSize * 0.5);
		}
		camInputMove.x = camInputMove.y = 0.0;

		camZoom = hxd.Math.clamp(camZoom + camInputZoom * dt, 5.0, 20.0);
		camInputZoom = 0.0; // TODO

		s3d.camera.pos.set(
			camPosition.x + Math.cos(camRotation.x) * Math.sin(camRotation.y) * camZoom,
			camPosition.y + Math.cos(camRotation.x) * Math.cos(camRotation.y) * camZoom,
			camPosition.z + Math.sin(camRotation.x) * camZoom);
		s3d.camera.target.set(camPosition.x, camPosition.y, camPosition.z);

		// other

		for (update in updates) {
			update(dt);
		}
	}

	//

	function onEvent(event:hxd.Event):Void {
		isAddingWater = false;

		if (event.button == 0) {
			if (event.kind == EventKind.EPush) {
				var ray = s3d.camera.rayFromScreen(event.relX, event.relY);
				var tile = floor.rayTile(ray);
				if (tile != null) { tile.addTree(); }
			}
		}
		else if (event.button == 1) {
			// camera rotation
			if (event.kind == EventKind.EPush) { camInputRotateLastMousePos = new Vector(event.relX, event.relY); }
			else if (event.kind == EventKind.ERelease) { camInputRotateLastMousePos = null; }
		}
		else if (event.button == 2) {
			// camera movement
			if (event.kind == EventKind.EPush) { camInputMoveLastMousePos = new Vector(event.relX, event.relY); }
			else if (event.kind == EventKind.ERelease) { camInputMoveLastMousePos = null; }
		}

		if (event.kind == EventKind.EWheel) {
			// camera zoom
			camInputZoom = event.wheelDelta * 35.0;
		}

		if (event.kind == EventKind.EMove && camInputMoveLastMousePos != null) {
			camInputMove.x = (event.relX - camInputMoveLastMousePos.x) * 0.85;
			camInputMove.y = (event.relY - camInputMoveLastMousePos.y) * 0.85;
			camInputMoveLastMousePos.set(event.relX, event.relY);
		}
		if (event.kind == EventKind.EMove && camInputRotateLastMousePos != null) {
			camInputRotate.x = (event.relY - camInputRotateLastMousePos.y) * 0.85;
			camInputRotate.y = (event.relX - camInputRotateLastMousePos.x) * -0.85;
			camInputRotateLastMousePos.set(event.relX, event.relY);
		}

		// TEST
		if (event.kind == EventKind.EKeyDown) {
			if (event.keyCode >= Key.F1 && event.keyCode <= Key.F12) { return; } // don't block F keys
			if (event.keyCode >= Key.NUMBER_0 && event.keyCode <= Key.NUMBER_9) { return; } // don't block numbers
			switch (event.keyCode) {
				case Key.W, Key.UP: camInputZoom = -1;
				case Key.S, Key.DOWN: camInputZoom = 1;
				case Key.A, Key.LEFT: camInputRotate.y = -2; // yaw
				case Key.D, Key.RIGHT: camInputRotate.y = 2;
				case Key.Q: camInputRotate.x = -3; // pitch
				case Key.E: camInputRotate.x = 3;
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