package;

using tweenxcore.Tools;

@:allow(Tweens)
class Tween {
	var name = "";
	var factor = 0.0;
	var speed = 0.0;
	var start:Float;
	var end:Float;
	var easeFunc:Float->Float;
	var updateFunc:Float->Void;
	var completeFunc:Void->Void;
	var delay:Float;

	public function reset(start:Float, end:Float, speed:Float):Tween {
		name = "";
		factor = 0.0;
		this.start = start;
		this.end = end;
		this.speed = speed;
		this.easeFunc = tweenxcore.Tools.Easing.linear;
		updateFunc = null;
		completeFunc = null;
		return this;
	}

	public function new(start:Float, end:Float, speed:Float) {
		this.start = start;
		this.end = end;
		this.speed = speed;
		this.easeFunc = tweenxcore.Tools.Easing.linear;
	}

	@:inline
	public function ease(func:Float->Float) {
		easeFunc = func;
		return this;
	}

	@:inline
	public function onUpdate(func:Float->Void) {
		updateFunc = func;
		return this;
	}

	@:inline
	public function onComplete(func:Void->Void) {
		completeFunc = func;
		return this;
	}

	@:inline
	public function setName(name:String) {
		this.name = name;
		return this;
	}

	@:inline
	public function setDelay(delay:Float) {
		this.delay = delay;
		return this;
	}
}

class Tweens {
	static var poolTweens = new Array<Tween>();
	static function poolPopTween(start:Float, end:Float, speed:Float):Tween {
		var t = (poolTweens.length == 0) ? new Tween(start, end, speed) : poolTweens.pop().reset(start, end, speed);
		curTweens.push(t);
		return t;
	}
	static function poolPushTween(t:Tween) {
		poolTweens.push(t);
		curTweens.remove(t);
	}
	static var curTweens = new Array<Tween>();

	//

	public static function update(dt:Float) {
		var count = curTweens.length;
		for (i in 0...count) {
			var t = curTweens[count - i - 1];
			if (t.delay > 0.0) {
				t.delay -= dt;
				continue;
			}
			if (t.factor >= 1.0) { // done
				if (t.completeFunc != null) { t.completeFunc(); }
				poolPushTween(t);
				continue;
			}
			t.factor += dt * t.speed;
			if (t.factor >= 1.0) { t.factor = 1.0; } // done
			var value = t.easeFunc(t.factor).lerp(t.start, t.end);
			//var value = t.factor.quintOut().lerp(t.start, t.end);
			if (t.updateFunc != null) { t.updateFunc(value); }
		}
	}

	public static function timer(seconds:Float, completeFunc:Void->Void):Tween {
		var tween = poolPopTween(0.0, 1.0, 1.0 / seconds);
		tween.onComplete(completeFunc);
		return tween;
	}

	public static function tween(start:Float, end:Float, seconds:Float, updateFunc:Float->Void):Tween {
		var tween = poolPopTween(start, end, 1.0 / seconds);
		tween.onUpdate(updateFunc);
		return tween;
	}

	public static function stop(name:String, withComplete = false) {
		var i = curTweens.length;
		while (--i >= 0) {
			var t = curTweens[i];
			if (t.name == name) {
				if (withComplete && t.completeFunc != null) { t.completeFunc(); }
				poolPushTween(t);
				curTweens.splice(i, 1);
			}
		}
	}
}