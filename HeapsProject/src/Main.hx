package;

import h3d.scene.fwd.DirLight;
import hxd.fs.Convert.Command;
import h3d.shader.ColorAdd;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.col.Plane;
import h2d.Text;
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
	public static final TICK_TIME = 0.2; // one second per tick
	//
	public static var instance(default, null):Main;
	public static var updates(default, null) = new Array<Float->Void>();
	//
#if debug
	public var debugTxt(default, null):Text;
	var layerDebug:h2d.Object;
#end
#if js
    var canvas:CanvasElement;
#end
	var floor:Floor;
	var clouds = new Array<Cloud>();
	// HUD
	var hoveredTile:Tile = null;
	var hoverObject:h3d.scene.Object;
	var compass:Compass;
	// camera
	var camLight:PointLight;
	var cursorLight:PointLight;
	var camInputRotate = new Vector();
	var camInputRotateLastMousePos:Vector = null;
	var camInputMove = new Vector();
	var camInputMoveLastMousePos:Vector = null;
	var camInputZoom = 0.0;
	var camRotation = new Vector(0.5, 0.0, 0.0);
	var camPosition = new Vector(0.0, 0.0, 0.0);
	var camZoom = 20.0;
	// time
	var curTime = 0.0;
	var tickTimer = -2.0;

	//

	override function init() {
		super.init();
		
#if js
  	 	canvas = cast Browser.document.getElementById("webgl");
        Browser.document.ondrag = e -> { e.preventDefault(); }
		hxd.Window.getInstance().propagateKeyEvents = true;
#end

		s2d.defaultSmooth = true;
		engine.backgroundColor = 0x112233;
		engine.autoResize = true;
		hxd.Window.getInstance().addEventTarget(onEvent);

		//Engine.ANTIALIASING = 4;

		// floor
		floor = new Floor(s3d);
		camPosition.x = camPosition.y = floor.gridSize * 0.5;

		// lights
		var directionalLight = new DirLight(new h3d.Vector(-0.3, -0.2, -1), s3d);
		//s3d.lightSystem.ambientLight.set(1, 1, 1, 1);
		//s3d.lightSystem.shadowLight.remove();
		//
		camLight = new PointLight(s3d);
		camLight.color.setColor(0xffffff);
		camLight.z = 2.0;
		//camLight.params.set(0, 0.25, 9.1);
		//
		cursorLight = new PointLight(s3d);
		cursorLight.color.setColor(0x1111ff11);
		cursorLight.z = 3.0;
		cursorLight.params.set(2, 0.1, 0);

#if debug
		// debug information
		layerDebug = new h2d.Object(s2d);
		debugTxt = new Text(Layout.getFont(), layerDebug);
		debugTxt.setPosition(25.0, 25.0);
		debugTxt.setScale(0.5);
#end

		// compass
		//new Compass(s3d);
		compass = new Compass(s3d);

		// hover
		var hoverMesh = new Cube(1.1, 1.1, 0.5, true);
		hoverMesh.addUVs(); hoverMesh.addNormals();
		var hoverMat = Material.create();
		hoverMat.color = new Vector(1, 1, 0, 0.5);
		hoverMat.blendMode = Alpha;
		hoverMat.castShadows = false;
		hoverObject = new h3d.scene.Mesh(hoverMesh, hoverMat, null);

		// TEST
		//floor.addWater(6, 4, 4.0);
		var rain = new Rain(floor.obj);
		rain.parts.x = 6.5;
		rain.parts.y = 4.5;
		rain.parts.z = 8;
		//addCloud(0, 0);
		//addCloud(1, 1);
		for (i in 0...floor.gridSize*floor.gridSize) {
			//floor.tiles[i].addTree();
		}

		//

		onResize();
	}

    //

	override function update(dt:Float) {
#if js
		// automatically resize canvas to browser window size
        if (canvas != null) {
            canvas.style.width = js.Browser.window.innerWidth + "px";
            canvas.style.height = js.Browser.window.innerHeight + "px";
        }
#end

		curTime += dt;
		tickTimer += dt;
		while (tickTimer > TICK_TIME) {
			tickTimer -= TICK_TIME;
			for (c in clouds) { c.tick(1, 0, TICK_TIME); } // TODO
			floor.tick(TICK_TIME);
		}

#if debug
		var dbgStr = "";
		dbgStr += Helpers.floatToStringPrecision(engine.fps, 2) + " fps";
		dbgStr += "\n\n" + Std.int(curTime) + " days";
		//+ | TD" + Main.VERSION + " | " + s2d.width + "x" + s2d.height + " | " + engine.drawCalls + " | "
		//+ " Scale:" + Helpers.floatToStringPrecision(Layout.SCALE, 2) + " | " + Timer.frameCount + " | ";
		//+ "\nPress C to switch between ortho and perspective cam";
		if (hoveredTile != null) { dbgStr += "\n\n" + hoveredTile.info(); }
		debugTxt.text = dbgStr;
#end

		//if (Key.isPressed(Key.C)) {
		//	var aspect = s2d.width / s2d.height;
		//	s3d.camera.orthoBounds = s3d.camera.orthoBounds != null ? null : Bounds.fromValues(-2.5 * aspect, -2.5, 0, 5 * aspect, 5, 80);
		//}

		var ray = s3d.camera.rayFromScreen(s2d.mouseX * Layout.SCALE, s2d.mouseY * Layout.SCALE);
		hoveredTile = floor.rayTile(ray);
		var p = ray.intersect(floor.plane);
		if (p != null) { cursorLight.x = p.x; cursorLight.y = p.y; }

		if (hoveredTile != null) {
			if (Key.isDown(Key.T)) { floor.addWater(hoveredTile.x, hoveredTile.y, dt * 5); }
			if (Key.isDown(Key.G)) { floor.removeWater(hoveredTile.x, hoveredTile.y, dt * 5); }
			if (hoverObject.parent == null) { s3d.addChild(hoverObject); }
			hoverObject.setPosition(hoveredTile.x, hoveredTile.y, hoveredTile.pos.z - 0.24);
		}
		else {
			if (hoverObject.parent != null) { hoverObject.remove(); }
		}
		
		// camera

		if (camInputRotate.length() > 0.0) {
			camRotation.x = hxd.Math.clamp(camRotation.x + camInputRotate.x * dt, Math.PI * 0.5 * 0.2, Math.PI * 0.5 * 0.9); // pitch
			camRotation.y += camInputRotate.y * dt; // yaw
		}
		camInputRotate.x = camInputRotate.y = 0.0;

		if (camInputMove.length() > 0.0) {
			camPosition.x = hxd.Math.clamp(camPosition.x - (Math.sin(camRotation.y) * camInputMove.y + Math.cos(camRotation.y) * camInputMove.x) * dt, 0.0, floor.gridSize);
			camPosition.y = hxd.Math.clamp(camPosition.y - (Math.cos(camRotation.y) * camInputMove.y - Math.sin(camRotation.y) * camInputMove.x) * dt, 0.0, floor.gridSize);
		}
		camLight.x = camPosition.x;
		camLight.y = camPosition.y;
		camInputMove.x = camInputMove.y = 0.0;

		camZoom = hxd.Math.clamp(camZoom + camInputZoom * dt, 5.0, 30.0);
		camInputZoom = 0.0;

		s3d.camera.pos.set(
			camPosition.x + Math.cos(camRotation.x) * Math.sin(camRotation.y) * camZoom,
			camPosition.y + Math.cos(camRotation.x) * Math.cos(camRotation.y) * camZoom,
			camPosition.z + Math.sin(camRotation.x) * camZoom);
		s3d.camera.target.set(camPosition.x, camPosition.y, camPosition.z);

		// other

		for (update in updates) {
			update(dt);
		}

		compass.update(s3d.camera, dt);
	}

	//

	public function addCloud(x:Int, y:Int) {
		var cloud = new Cloud(s3d, floor, x, y);
		clouds.push(cloud);
	}

	//

	function onEvent(event:hxd.Event):Void {
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

		if (event.kind == EventKind.EMove && camInputRotateLastMousePos != null) {
			camInputRotate.x = (event.relY - camInputRotateLastMousePos.y) * 0.25;
			camInputRotate.y = (event.relX - camInputRotateLastMousePos.x) * -0.25;
			camInputRotateLastMousePos.set(event.relX, event.relY);
		}
		if (event.kind == EventKind.EMove && camInputMoveLastMousePos != null) {
			camInputMove.x = (event.relX - camInputMoveLastMousePos.x) * 0.85;
			camInputMove.y = (event.relY - camInputMoveLastMousePos.y) * 0.85;
			camInputMoveLastMousePos.set(event.relX, event.relY);
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