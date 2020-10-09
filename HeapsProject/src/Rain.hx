package;

import h3d.scene.Object;
import h3d.parts.GpuParticles;

class Rain {
	public var parts(default, null):GpuParticles;
	//
	var group:GpuPartGroup;

	//
	
	public function new(parent:Object) {
		parts = new GpuParticles(parent);
		
		group = new GpuPartGroup(parts);
		group.emitMode = Disc;
		group.emitAngle = Math.PI;
		group.emitDist = 0.7;

		group.fadeIn = 0.8;
		group.fadeOut = 0.8;
		group.fadePower = 20;
		//group.gravity = 1;
		group.size = 0.25;	
		group.sizeRand = 0.01;

		//group.rotSpeed = 10;

		group.speed = 2;
		//group.speedRand = 0.5;

		group.life = 5;
		group.lifeRand = 0.1;
		group.nparts = 200;

		parts.addGroup(group);	
	}
}