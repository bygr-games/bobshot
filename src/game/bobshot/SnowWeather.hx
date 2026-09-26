package bobshot;

import dn.heaps.HParticle;

class SnowWeather extends GameChildProcess {
	static inline var SPAWN_RATE = 3.6;
	static inline var FRONT_RATE = 1.2;

	public function new() {
		super();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		var levelPxWid = game.level.pxWid;
		var levelPxHei = game.level.pxHei;
		var count = M.ceil(SPAWN_RATE * game.tmod);
		for( i in 0...count )
			spawnSnow(levelPxWid, levelPxHei, false);

		if( rnd(0, 1) < FRONT_RATE * game.tmod )
			spawnSnow(levelPxWid, levelPxHei, true);
	}

	function spawnSnow(levelPxWid:Int, levelPxHei:Int, front:Bool) {
		var cam = game.camera;
		var left = M.imax(0, Std.int(cam.pxLeft - 220));
		var right = M.imin(levelPxWid, Std.int(cam.pxRight + 220));
		var spawnX = rnd(left, right);
		var spawnY = rnd(M.imax(0, Std.int(cam.pxTop - 70)), M.imax(0, Std.int(cam.pxTop - 20)));
		var p = front
			? fx.allocMain_normal(D.tiles.fxDot, spawnX, spawnY)
			: fx.allocBg_normal(D.tiles.fxDot, spawnX, spawnY);

		p.colorize(front ? 0xFFFFFF : 0xDDF3FF);
		p.alpha = front ? rnd(0.82, 0.98) : rnd(0.4, 0.72);
		p.setScale(front ? rnd(0.7, 1.25) : rnd(0.35, 0.85));
		p.dx = rnd(-0.12, 0.12) + rnd(-0.03, 0.18);
		p.dy = front ? rnd(0.55, 0.95) : rnd(0.4, 0.75);
		p.gx = rnd(-0.0015, 0.0015);
		p.gy = rnd(0.0018, 0.0042);
		p.frict = 0.995;
		p.lifeS = 8;
		p.rotation = rnd(0, 6.28);
		p.dr = rnd(-0.015, 0.015);

		p.onUpdate = function(sp:HParticle) {
			if( sp.y > levelPxHei + 12 || sp.x < -16 || sp.x > levelPxWid + 16 ) {
				sp.kill();
				return;
			}

			if( collides(sp, 0, 1) ) {
				if( front && rnd(0, 1) < 0.35 )
					spawnSettledSnow(sp.x, sp.y);
				sp.kill();
			}
		};
	}

	function spawnSettledSnow(x:Float, y:Float) {
		var p = fx.allocMain_normal(D.tiles.fxDot, x + rnd(-1.2, 1.2), y - rnd(0, 1.2));
		p.colorize(0xF2FBFF);
		p.alpha = rnd(0.25, 0.5);
		p.setScale(rnd(0.35, 0.8));
		p.dx = rnd(-0.015, 0.015);
		p.dy = 0;
		p.frict = 0.97;
		p.lifeS = rnd(0.7, 1.4);
		p.gy = 0;
	}

	inline function collides(p:HParticle, offX=0., offY=0.) {
		return level.hasCollision(Std.int((p.x + offX) / Const.GRID), Std.int((p.y + offY) / Const.GRID));
	}
}
