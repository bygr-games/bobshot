package mitosis.projectiles;

import mitosis.enemies.MitosisEnemy;
import mitosis.MitosisPlayer;

class Projectile extends Entity {
	var strategy : ProjectileStrategy;
	public var projectileType(default, null) : String;
	public var targetType(default, null) : String;
	public var shotVelX(default, null) : Float;
	public var shotVelY(default, null) : Float;

	public function new(x:Float, y:Float, shotDir:Int, type:String, target:String = "enemy", ?shotVelX:Null<Float>, ?shotVelY:Null<Float>) {
		super(0, 0);

		projectileType = type;
		targetType = target.toLowerCase();
		dir = shotDir;
		this.shotVelX = shotVelX==null ? shotDir : shotVelX;
		this.shotVelY = shotVelY==null ? 0 : shotVelY;
		setPosPixel(x, y);
		vBase.setFricts(0.82, 1);

		strategy = switch( type.toLowerCase() ) {
			case "basic": new BasicProjectileStrategy();
			case "violet": new VioletProjectileStrategy();
			default:
				trace('Unknown projectile type: $type, defaulting to basic');
				new BasicProjectileStrategy();
		}

		strategy.initGraphics(this);
	}

	override function dispose() {
		super.dispose();
		if( strategy!=null ) {
			strategy.dispose();
			strategy = null;
		}
	}

	override function onPreStepX() {
		super.onPreStepX();

		if( xr > 0.8 && hasLevelCollision(cx + 1, cy) ) {
			xr = 0.8;
			strategy.onXCollision(this, 1);
		}

		if( xr < 0.2 && hasLevelCollision(cx - 1, cy) ) {
			xr = 0.2;
			strategy.onXCollision(this, -1);
		}
	}

	override function onPreStepY() {
		super.onPreStepY();

		if( yr > 0.8 && hasLevelCollision(cx, cy + 1) ) {
			yr = 0.8;
			strategy.onYCollision(this, 1);
		}

		if( yr < 0.2 && hasLevelCollision(cx, cy - 1) ) {
			yr = 0.2;
			strategy.onYCollision(this, -1);
		}
	}

	override function fixedUpdate() {
		if( destroyed )
			return;

		strategy.update(this);
		super.fixedUpdate();

		if( destroyed )
			return;

		if( hasLeftLevel() ) {
			destroy();
			return;
		}

		switch( targetType ) {
			case "player":
				for( e in Entity.ALL ) {
					if( e.destroyed || !e.is(MitosisPlayer) )
						continue;

					if( Lib.rectangleOverlaps(left, top, wid, hei, e.left, e.top, e.wid, e.hei) ) {
						var player = e.as(MitosisPlayer);
						player.kill(this);
						strategy.onPlayerHit(this, player);
						break;
					}
				}

			default:
				for( e in Entity.ALL ) {
					if( e.destroyed || !e.is(MitosisEnemy) )
						continue;

					if( Lib.rectangleOverlaps(left, top, wid, hei, e.left, e.top, e.wid, e.hei) ) {
						var enemy = e.as(MitosisEnemy);
						enemy.kill(this);
						strategy.onEnemyHit(this, enemy);
						break;
					}
				}
		}

		// Check for falling object collisions (affects any projectile)
		for( e in Entity.ALL ) {
			if( e.destroyed || !e.is(mitosis.FallingObject) )
				continue;

			if( Lib.rectangleOverlaps(left, top, wid, hei, e.left, e.top, e.wid, e.hei) ) {
				var fallingObject = e.as(mitosis.FallingObject);
				fallingObject.startFalling();
				break;
			}
		}
	}

	inline function hasLevelCollision(testCx:Int, testCy:Int):Bool {
		if( !level.isValid(testCx, testCy) )
			return strategy.collidesWithLevelBounds();

		return level.hasCollision(testCx, testCy);
	}

	inline function hasLeftLevel():Bool {
		return right < 0 || left > level.pxWid || bottom < 0 || top > level.pxHei;
	}
}


