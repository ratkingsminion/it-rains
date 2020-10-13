package;

import h3d.mat.Texture;
import h3d.scene.Object;
import h3d.parts.GpuParticles;

class Rain {

	static var color:Texture = null;

	public var parts(default, null):GpuParticles;
	//
	var group:GpuPartGroup;

	//
	
	public function new(parent:Object) {
		parts = new GpuParticles(parent);
		
		group = new GpuPartGroup(parts);


		group.emitMode = Disc;
		group.emitAngle = Math.PI;
		group.emitDist = 0.5;

		group.fadeIn = 0; // 0.8;
		group.fadeOut = 0; // 10.8;
		group.fadePower = 1;
		//group.gravity = 1;
		group.size = 0.35;	
		group.sizeRand = 0.01;

		//group.rotSpeed = 10;

		group.speed = 2;
		//group.speedRand = 0.5;

		group.life = 1;
		group.lifeRand = 0.1;
		group.nparts = 100;

		group.colorGradient = color == null ? (color = Texture.fromColor(0x5555ff, 0.8)) : color;

		parts.addGroup(group);	
	}

	public function destroy() {
		parts.remove();
	}
}