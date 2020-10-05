package;

import hxd.Res;
import h3d.col.Point;
import hxd.res.Model;
import h3d.scene.Object;
import h3d.prim.ModelCache;

class Tree {
	public static final AGE_COUNT = 5;
	static final MODELS = [
		{ name:"Tree_01_01", scale:0.48, model:null },
		{ name:"Tree_01_02", scale:0.36, model:null },
		{ name:"Tree_01_03", scale:0.32, model:null },
		{ name:"Tree_01_04", scale:0.34, model:null },
		{ name:"Tree_01_05", scale:0.32, model:null },
	];

	static var cache:ModelCache;
	//
	public var obj(default, null):Object;
	public var index(default, null):Int;
	//
	var parent:Object;
	var rotation:Float;
	var position:Point;

	//

	public function new(index:Int, position:Point, parent:Object) {
		//var idx = Std.int(hxd.Math.random(models.length - 1));
		this.index = index;
		this.position = position;
		this.parent = parent;
		rotation = hxd.Math.random(hxd.Math.PI * 2.0);
		setIndex(index);
	}

	public function change(index:Int) {
		if (this.index == index) {
			return;
		}
		if (obj != null) {
			obj.remove(); // TODO pool?
			obj = null;
		}
		this.index = index;
		setIndex(index);
	}

	//

	function setIndex(index:Int) {
		// https://heaps.io/documentation/fbx-models.html
		if (cache == null) {
			cache = new h3d.prim.ModelCache();
			for (m in MODELS) {
				var res = Res.loader.load("models/" + m.name + ".fbx");
				if (res == null) { trace("ERROR: " + m.name + " not found"); return; }
				m.model = res.toModel();
			}
			// cache.loadLibrary(hxd.Res.models.Tree_01_01);
		}

		obj = cache.loadModel(MODELS[index].model);
		parent.addChild(obj);
		obj.scale(MODELS[index].scale * 0.01); // TODO
		obj.setRotation(0, 0, rotation);
		obj.setPosition(position.x, position.y, position.z);
	}
}