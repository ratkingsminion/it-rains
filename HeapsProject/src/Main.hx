package;

import h2d.Object;
import h3d.pass.DirShadowMap;
import h3d.scene.fwd.DirLight;
import h3d.mat.Material;
import h3d.prim.Cube;
import h2d.Text;
import h3d.Engine;
import h3d.Vector;
import hxd.Event.EventKind;
import hxd.Key;
#if js
import js.html.CanvasElement;
import js.Browser;
#end

class Main extends hxd.App {
	public static final VERSION = "v0.1";
	public static final TICK_TIME = 0.1; // one second per tick
	public static final TICK_SCALE = 1.0; // TODO
	public static final GRID_SIZE = 10;
	public static final TREES_START_COUNT = 7;
	public static final WIND_CHANGE_AFTER_TICKS = 7.5;
	public static final EVAPORATE_WATER_PER_TILE_AND_TICK = 0.01; // one second per tick

	//

	public static var instance(default, null):Main;
	public var isOnMobileOrTablet(default, null) = false;
	// USER INTERFACE 2D
	var layerUI:h2d.Object;
#if debug
	var debugTxt(default, null):Text;
#end
	var uiDays:Text;
	var uiHoverInfo:Text;
	var uiBtnPause:Button;
	var uiBtnReset:Button;
	var uiBtnHelp:Button;
#if js
    var canvas:CanvasElement;
#end
	// INTERFACE INGAME
	var hoveredTile:Tile = null;
	var hoverObject:h3d.scene.Object;
	var compass:Compass;
	// CAMERA
	var dLightParent:h3d.scene.Object;
	var camInputRotate = new Vector();
	var camInputRotateLastMousePos:Vector = null;
	var camInputMove = new Vector();
	var camInputMoveLastMousePos:Vector = null;
	var camInputZoom = 0.0;
	var camRotation = new Vector(0.65, Math.PI * 0.2);
	var camPosition = new Vector(0.0, 0.0, 0.0);
	var camZoom = 25.0;
	// GAME
	var floor:Floor;
	var clouds = new Array<Cloud>();
	// TIME
	var curTime = 0.0;
	var tickTimer = 0.0;
	var curWindDir = { x:0, y:-1 };
	var windChangeTimer = 0.0;
	var paused = false;
	var dialog:Dialog = null;

	//

	override function init() {
		super.init();

		Lang.lang = German;

#if (js || html5)
		isOnMobileOrTablet = untyped __js__("mobileAndTabletCheck()"); // source: https://stackoverflow.com/questions/11381673/detecting-a-mobile-browser
        canvas = cast Browser.document.getElementById("webgl");
        //Browser.document.onkeydown = e -> {
		//	if (e.keyCode >= Key.F1 && e.keyCode <= Key.F12) { return; } // don't block F keys
		//	if (e.keyCode >= Key.NUMBER_0 && e.keyCode <= Key.NUMBER_9) { return; } // don't block numbers
		//	e.preventDefault(); // everything else: yes
		//}
        Browser.document.ondrag = e -> { e.preventDefault(); }
		hxd.Window.getInstance().propagateKeyEvents = true;
#end

		s2d.defaultSmooth = true;
		engine.backgroundColor = 0x112233;
		engine.autoResize = true;
		hxd.Window.getInstance().addEventTarget(onEvent);

		Engine.ANTIALIASING = 4;

		// lights
		dLightParent = new h3d.scene.Object(s3d);
		var dLight = new DirLight(new h3d.Vector(-0.3, -0.25, -0.4), dLightParent);
		var shadow = s3d.renderer.getPass(DirShadowMap);
		shadow.blur.radius = 3;
		shadow.power = 5.0;
		
		// debug information
		layerUI = new h2d.Object(s2d);
		debugTxt = new Text(Layout.getFont(), layerUI);
		debugTxt.setPosition(25.0, 100.0);
		debugTxt.setScale(0.5);
		layerUI.visible = false;

		// USER INTERFACE
		uiDays = new Text(Layout.getFont(), layerUI);
		uiDays.setScale(0.8);
		uiDays.textAlign = Left;
		uiDays.x = uiDays.y = 25.0;

		uiHoverInfo = new Text(Layout.getFont(), layerUI);
		uiHoverInfo.setScale(0.6);
		uiHoverInfo.textAlign = Left;
		uiHoverInfo.x = 25.0;

		uiBtnPause = new Button(0.0, 30 + 25.0, 60, 60, layerUI, e -> {
			paused = !paused;
			uiBtnPause.setLabelText(paused ? ">" : "||");
		}, false).setLabel("||", Layout.getFont(), 0xffffff, 0xffffff, 0xffffff, 0.7);

		uiBtnHelp = new Button(0.0, 30 + 25.0, 60, 60, layerUI, e -> {
			var oldPaused = paused;
			paused = true;
			dialog = new Dialog(Lang.help(), s2d, 500, 400,
				() -> { paused = oldPaused; dialog = null; } );
		}, false).setLabel("?");

		uiBtnReset = new Button(0.0, 30 + 25.0, 60, 60, layerUI, e -> {
			if (curTime < 5.0) {
				resetGame();
			}
			else {
				var oldPaused = paused;
				paused = true;
				dialog = new Dialog(Lang.confirmReset(), s2d, 300, 200,
					() -> { resetGame(); paused = oldPaused; dialog = null; },
					() -> { paused = oldPaused; dialog = null; } );
			}
		}, false).setLabel("R");

		// TODO show how many clouds i have left
		// TODO Button-Grafik Hintergrund
		// TODO Button-Grafik Play/Pause
		// TODO Kompass-Kreis

		// compass
		compass = new Compass(s3d);
		compass.obj.visible = false;

		// hover
		var hoverMesh = new Cube(1.1, 1.1, 0.5, true);
		hoverMesh.addUVs(); hoverMesh.addNormals();
		var hoverMat = Material.create();
		hoverMat.color = new Vector(1, 1, 0, 0.5);
		hoverMat.blendMode = Alpha;
		hoverMat.receiveShadows = hoverMat.castShadows = false;
		hoverObject = new h3d.scene.Mesh(hoverMesh, hoverMat, null);

		resetGame();

		//

		onResize();
		
		//
		
		paused = true;
		dialog = new Dialog(Lang.start(), s2d, 500, 300, () -> {
			paused = false; 
			dialog = null;

			layerUI.visible = true;
			compass.obj.visible = true;
		});
	}

	function resetGame() {
		curTime = 0.0;
		tickTimer = 0.0;
		windChangeTimer = 0.0;
		paused = false;
		camInputZoom = 0.0;
		camRotation = new Vector(0.65, Math.PI * 0.2);
		camPosition = new Vector(0.0, 0.0, 0.0);

		if (floor != null) { floor.obj.remove(); floor = null; }
		for (c in clouds) { c.destroy(); } clouds.splice(0, -1);

		// floor
		floor = new Floor(s3d, GRID_SIZE);
		camPosition.x = camPosition.y = floor.gridSize * 0.5;

		// trees
		var treesCount = Math.min(TREES_START_COUNT, GRID_SIZE * GRID_SIZE);
		var treesStart:Array<Int> = [ ];
		while (treesStart.length < treesCount) {
			var r = treesStart.length > 0 ? Helpers.randomInt(treesStart.length) : -1; // Std.int(hxd.Math.random(floor.gridSize*floor.gridSize));
			var i = r >= 0 ? treesStart[r] : Helpers.randomInt(GRID_SIZE * GRID_SIZE);
			var x = i % GRID_SIZE;
			var y = Std.int(i / GRID_SIZE);
			trace(r + " " + i + " ... " + x + "/" + y);
			switch (Helpers.randomInt(4)) {
				case 0: x--; if (x < 0) { continue; }
				case 1: x++; if (x >= GRID_SIZE) { continue; }
				case 2: y--; if (y < 0) { continue; }
				case 3: y++; if (y >= GRID_SIZE) { continue; }
			}
			i = y * GRID_SIZE + x;
			if (floor.tiles[i].addTree()) {
				floor.tiles[i].addWater(0.25);
				treesStart.push(i);
			}
		}
		changeWindDirRandomly();
	}

	//
	
	function updateWind(dt:Float) {
		windChangeTimer += dt;
		if (windChangeTimer > WIND_CHANGE_AFTER_TICKS) {
			windChangeTimer -= WIND_CHANGE_AFTER_TICKS;
			changeWindDirRandomly();
		}
	}

	function changeWindDirRandomly() {
		switch (Std.int(hxd.Math.random(4.0))) {
			case 0: curWindDir.x =  0; curWindDir.y =  1; compass.changeDir(180.0);
			case 1: curWindDir.x =  1; curWindDir.y =  0; compass.changeDir(90.0);
			case 2: curWindDir.x =  0; curWindDir.y = -1; compass.changeDir(0.0);
			case 3: curWindDir.x = -1; curWindDir.y =  0; compass.changeDir(270.0);
		}
	}

	function updateClouds(dt:Float) {
		var i = clouds.length - 1;
		while (i >= 0) {
			var c = clouds[i];
			if (!c.tick(curWindDir.x, curWindDir.y, dt)) {
				c.destroy();
				clouds.remove(c);
			}
			--i;
		}
	}

	override function update(dt:Float) {
#if js
		// automatically resize canvas to browser window size
        if (canvas != null) {
            canvas.style.width = js.Browser.window.innerWidth + "px";
            canvas.style.height = js.Browser.window.innerHeight + "px";
        }
#end

		if (!paused) {
			curTime += dt;
			tickTimer += dt;
			while (tickTimer > TICK_TIME) {
				tickTimer -= TICK_TIME;
				var tick = TICK_TIME * TICK_SCALE;
				updateWind(tick);
				updateClouds(tick);
				floor.tick(tick);
			}
		}

		var treeCount = 0;
		for (t in floor.tiles) { if (t.tree != null) { treeCount++; }}
		uiDays.text = Lang.days(Std.int(curTime), treeCount / (GRID_SIZE * GRID_SIZE));
		if (!paused && treeCount == 0) {
			paused = true;
			layerUI.visible = false;
			dialog = new Dialog(Lang.lose(), s2d, 300, 300, () -> {
				dialog = null;
				layerUI.visible = true;
				resetGame();
			});
			return;
		}

		//var size = 10;
		//var pixels = floor.fs.fertility.capturePixels();
		//for (t in floor.tiles) {
		//	dbgGfx.beginFill(pixels.getPixel(t.x, t.y), 1);
		//	dbgGfx.drawRect(t.x * size, t.y * size, size, size);
		//}

#if debug
		//+ | TD" + Main.VERSION + " | " + s2d.width + "x" + s2d.height + " | " + engine.drawCalls + " | "
		//+ " Scale:" + Helpers.floatToStringPrecision(Layout.SCALE, 2) + " | " + Timer.frameCount + " | ";
		//+ "\nPress C to switch between ortho and perspective cam";
		debugTxt.text = Helpers.floatToStringPrecision(engine.fps, 2) + " fps";
#end

		if (hoveredTile != null && dialog == null) {
			uiHoverInfo.text = hoveredTile.info();
			uiHoverInfo.y = s2d.height / Layout.SCALE - 25.0 - uiHoverInfo.textHeight * uiHoverInfo.scaleY;
		}
		else {
			uiHoverInfo.text = "";
		}

		//if (Key.isPressed(Key.C)) {
		//	var aspect = s2d.width / s2d.height;
		//	s3d.camera.orthoBounds = s3d.camera.orthoBounds != null ? null : Bounds.fromValues(-2.5 * aspect, -2.5, 0, 5 * aspect, 5, 80);
		//}

		var ray = s3d.camera.rayFromScreen(s2d.mouseX * Layout.SCALE, s2d.mouseY * Layout.SCALE);
		hoveredTile = camInputRotateLastMousePos == null && camInputMoveLastMousePos == null ? floor.rayTile(ray) : null;
		var p = ray.intersect(floor.plane);
		//if (p != null) { cursorLight.x = p.x; cursorLight.y = p.y; }

		if (hoveredTile != null && dialog == null) {
			//if (Key.isDown(Key.T)) { floor.addWater(hoveredTile.x, hoveredTile.y, dt * 5); }
			//if (Key.isDown(Key.G)) { floor.removeWater(hoveredTile.x, hoveredTile.y, dt * 5); }
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
			camPosition.x = hxd.Math.clamp(camPosition.x - (Math.sin(camRotation.y) * camInputMove.y + Math.cos(camRotation.y) * camInputMove.x) * dt, -0.5, floor.gridSize-0.5);
			camPosition.y = hxd.Math.clamp(camPosition.y - (Math.cos(camRotation.y) * camInputMove.y - Math.sin(camRotation.y) * camInputMove.x) * dt, -0.5, floor.gridSize-0.5);
		}
		//camLight.x = camPosition.x;
		//camLight.y = camPosition.y;
		camInputMove.x = camInputMove.y = 0.0;

		camZoom = hxd.Math.clamp(camZoom + camInputZoom * dt, 5.0, 35.0);
		camInputZoom = 0.0;

		s3d.camera.pos.set(
			camPosition.x + Math.cos(camRotation.x) * Math.sin(camRotation.y) * camZoom,
			camPosition.y + Math.cos(camRotation.x) * Math.cos(camRotation.y) * camZoom,
			camPosition.z + Math.sin(camRotation.x) * camZoom);
		s3d.camera.target.set(camPosition.x, camPosition.y, camPosition.z);

		dLightParent.setRotation(0, 0, -camRotation.y);

		// other

		compass.update(s3d.camera, dt);

		// tweens
		if (!paused) {
			Tweens.update(dt);
		}
	}

	//

	public function addCloud(x:Int, y:Int):Cloud {
		for (c in clouds) { if (c.curPos.x == x && c.curPos.y == y) { return null; }}
		var tile = floor.getTile(x, y);
		if (tile == null) { return null; }
		var cloud = new Cloud(s3d, floor, x, y, tile.pos.z + tile.waterLevel);
		clouds.push(cloud);
		return cloud;
	}

	//

	function onEvent(event:hxd.Event):Void {
		if (event.button == 0) {
			if (event.kind == EventKind.EPush && dialog == null) {
				var ray = s3d.camera.rayFromScreen(event.relX, event.relY);
				var tile = floor.rayTile(ray);
				if (tile != null) {
					// tile.addTree();
					addCloud(tile.x, tile.y);
				}
			}
		}
		else if (event.button == 1 && dialog == null) {
			// camera rotation
			if (event.kind == EventKind.EPush) { camInputRotateLastMousePos = new Vector(event.relX, event.relY); }
			else if (event.kind == EventKind.ERelease) { camInputRotateLastMousePos = null; }
		}
		else if (event.button == 2 && dialog == null) {
			// camera movement
			if (event.kind == EventKind.EPush) { camInputMoveLastMousePos = new Vector(event.relX, event.relY); }
			else if (event.kind == EventKind.ERelease) { camInputMoveLastMousePos = null; }
		}

		if (event.kind == EventKind.EWheel && dialog == null) {
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
			if (event.keyCode == Key.SPACE) { uiBtnPause.click(); }
			if (event.keyCode == Key.R && dialog == null) { uiBtnReset.click(); }
			
			//switch (event.keyCode) {
			//	case Key.W, Key.UP: camInputZoom = -1;
			//	case Key.S, Key.DOWN: camInputZoom = 1;
			//	case Key.A, Key.LEFT: camInputRotate.y = -2; // yaw
			//	case Key.D, Key.RIGHT: camInputRotate.y = 2;
			//	case Key.Q: camInputRotate.x = -3; // pitch
			//	case Key.E: camInputRotate.x = 3;
			//}
		}
	}

	override function onResize():Void {
		// automatic resize content to fit to virtual resolution
		var factor = (s2d.height / Layout.RESOLUTION.y);
		Layout.SCALE = 1.0 * factor;
		if (s2d.width / factor < Layout.RESOLUTION.x) { Layout.SCALE *= (s2d.width / factor) / Layout.RESOLUTION.x; }
		s2d.setScale(Layout.SCALE);

		// UI
		var sw = s2d.width / Layout.SCALE;
		//var sh = s2d.height / Layout.SCALE;
		uiBtnPause.obj.x = sw - 30 - 25.0;
		uiBtnHelp.obj.x = uiBtnPause.obj.x - 60 - 15.0;
		uiBtnReset.obj.x = uiBtnHelp.obj.x - 60 - 15.0;
    }

	// 

	static function main() {
		hxd.Res.initEmbed();
		instance = new Main();
	}
}