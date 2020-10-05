package;

class Helpers {

	public static inline function randomInt(x:Float):Int {
		//return Std.int((Math.random() * 0.9999999) * x);
		return Std.int(Math.random() * x);
	}

	public static inline function randomRange(min:Float, max:Float) {
		return Math.random() * (max - min) + min;
	}

	public static inline function randomRangeInt(min:Int, max:Int) {
		return randomInt(max - min) + min;
	}

	@:generic
	public static inline function randomElement<T>(array:Array<T>):T {
		return array[randomInt(array.length)];
	}

    public static function randomChar(string:String):String {
        return string.charAt(randomInt(string.length));
    }

	public static function randomIndex(probabilities:Array<Float>):Int {
		if (probabilities == null || probabilities.length == 0) { return -1; }
		var c = probabilities.length;
		var s = 0.0;
		for (i in 0...c) { s += Math.max(0.0, probabilities[i]); }
		var r = Math.random() * s;
		//for (var i = c - 1; i >= 0; --i) {
		var i = c - 1;
        while (i >= 0) {
			s -= Math.max(0.0, probabilities[i]);
			if (r > s) { return i; }
            --i;
		}
		return probabilities.length - 1;
	}

    public static function shuffle<T>(array:Array<T>):Array<T> {
        var l = array.length;
        for (i in 0...(l - 1)) {
            var j = randomRangeInt(i, l);
            var t = array[i];
            array[i] = array[j];
            array[j] = t;
        }
        return array;
    }

	public static inline function clamp(v:Float, min:Float, max:Float):Float {
		return v < min ? min : v > max ? max : v;
	}

	public static inline function clamp01(v:Float):Float {
		return v < 0.0 ? 0.0 : v > 1.0 ? 1.0 : v;
	}

	public static inline function lerp(a:Float, b:Float, t:Float) {
		return (1.0 - t) * a + t * b;
	}

	public static inline function lerpMinMax(v:{ min:Float, max:Float }, t:Float) {
		return (1.0 - t) * v.min + t * v.max;
	}

	public static inline function lerpStartEnd(v:{ start:Float, end:Float }, t:Float) {
		return (1.0 - t) * v.start + t * v.end;
	}

	// frame independent lerping
	public static function frinLerp(a:Float, b:Float, t:Float, dt:Float, hertz = 60.0):Float {
		//t = Math.pow(1.0 - t, dt * hertz);
		//return t * a + (1.0 - t) * b;
		return lerp(a, b, Math.pow(t, dt * hertz));
	}

	// remapping, from https://stackoverflow.com/questions/5294955/how-to-scale-down-a-range-of-numbers-with-a-known-min-and-max-value
	public static function remap(value:Float, oldMin:Float, oldMax:Float, newMin:Float, newMax:Float):Float {
		return ((newMax - newMin) * (value - oldMin) / (oldMax - oldMin)) + newMin;
	}
	public static function remapClamped(value:Float, oldMin:Float, oldMax:Float, newMin:Float, newMax:Float):Float {
		return ((newMax - newMin) * clamp01((value - oldMin) / (oldMax - oldMin))) + newMin;
	}

	public static inline function vectorLerp(a:{ x:Float, y:Float }, b:{ x:Float, y:Float }, t:Float) {
		return {
            x: (1.0 - t) * a.x + t * b.x,
            y: (1.0 - t) * a.y + t * b.y,
        }
	}

     public static function smoothDamp(current:Float, target:Float, currentVelocity:{ ref:Float }, smoothTime:Float, maxSpeed:Float, deltaTime:Float) {
		smoothTime = Math.max(0.0001, smoothTime);
		var num = 2.0 / smoothTime;
		var num2 = num * deltaTime;
		var num3 = 1.0 / (1.0 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2);
		var num4 = current - target;
		var num5 = target;
		var num6 = maxSpeed * smoothTime;
		num4 = clamp(num4, -num6, num6);
		target = current - num4;
		var num7 = (currentVelocity.ref + num * num4) * deltaTime;
		currentVelocity.ref = (currentVelocity.ref - num * num7) * num3;
		var num8 = target + (num4 + num7) * num3;
		if ((num5 - current > 0.0) == (num8 > num5)) {
			num8 = num5;
			currentVelocity.ref = (num8 - num5) / deltaTime;
		}
		return num8;
     }


	public static function vectorFrinLerp(a:{ x:Float, y:Float }, b:{ x:Float, y:Float }, t:Float, dt:Float, hertz = 60.0):{ x:Float, y:Float } {
		t = Math.pow(1.0 - t, dt * hertz);
		return { x:(t * a.x + (1.0 - t) * b.x), y:(t * a.y + (1.0 - t) * b.y) };
	}

	public static inline function vectorLength(v:{ x:Float, y:Float }):Float {
		return Math.sqrt(v.x * v.x + v.y * v.y);
	}

	// https://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
	static function sqr(x:Float) { return x * x; }
	static inline function dist2(vx:Float, vy:Float, wx:Float, wy:Float) { return sqr(vx - wx) + sqr(vy - wy); }
	public static function distToSegmentSquared(px:Float, py:Float, vx:Float, vy:Float, wx:Float, wy:Float):Float {
		var l2 = dist2(vx, vy, wx, wy);
		if (l2 == 0) { return dist2(px, py, vx, vy); }
		var t = ((px - vx) * (wx - vx) + (py - vy) * (wy - vy)) / l2;
		t = hxd.Math.clamp(t);
		return dist2(px, py, vx + t * (wx - vx), vy + t * (wy - vy));
	}
	public static inline function distToSegment(px:Float, py:Float, vx:Float, vy:Float, wx:Float, wy:Float):Float {
		return Math.sqrt(distToSegmentSquared(px, py, vx, vy, wx, wy));
	}
	
	// https://stackoverflow.com/questions/23689001/how-to-reliably-format-a-floating-point-number-to-a-specified-number-of-decimal
	public static function floatToStringPrecision(n:Float, prec:Int) {
		var e = Math.pow(10, prec);
		n = Math.round(n * e) / e;
		var str = Std.string(n);
		var idx = str.indexOf(".");
		if (idx < 0) {
			return str + "." + ([ for(i in 0...prec) "0" ].join(""));
		}
		var fracLen = str.length - idx - 1;
		if (fracLen > prec) { str = str.substring(0, idx + prec + 1); }
		else if (fracLen < prec) { str += ([ for(i in 0...(prec-fracLen)) "0" ].join("")); }
		return str;
	}

	public static function displayScore(score:Int, digits = 7):String {
		var text = "";
		var ts = score;
		do {
			ts = Std.int(ts / 10);
			digits--;
		} while (ts > 0);
		var i = digits - 1;
		while (i-- >= 0) {
			text += "0";
		}
		return text + score;
	}
	public static function displayMinutes(seconds:Float):String {
		var s = Std.int(seconds % 60);
		var m = Std.int(seconds / 60);
		return m + ":" + (s < 10 ? ("0" + s) : Std.string(s));
	}
	
	public inline static function isFirefox():Bool {
#if (js || html5)
		return js.Browser.navigator.userAgent.indexOf("Firefox") != -1;
#else
		return false;
#end
	}
}