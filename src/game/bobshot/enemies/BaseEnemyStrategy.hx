package bobshot.enemies;

import bobshot.BobshotPlayer;

class BaseEnemyStrategy implements EnemyStrategy {
	static inline var GRAVITY = 0.05;

	public function new() {}

	public function initHitbox(enemy:BobshotEnemy):Void {}

	public function update(enemy:BobshotEnemy):Void {}

	public function onYCollision(enemy:BobshotEnemy):Void {
		landIfGrounded(enemy);
	}

	public function onXCollision(enemy:BobshotEnemy, dir:Int):Void {}

	public function dispose():Void {}

	inline function setHitbox(enemy:BobshotEnemy, width:Int, height:Int):Void {
		enemy.iwid = width;
		enemy.ihei = height;
	}

	inline function applyGravityIfAirborne(enemy:BobshotEnemy):Void {
		if( !isOnGround(enemy) )
			enemy.vBase.addY(GRAVITY);
	}

	inline function landIfGrounded(enemy:BobshotEnemy):Void {
		if( enemy.yr > 1 && hasGroundSupport(enemy) ) {
			enemy.vBase.clearY();
			enemy.vBump.clearY();
			enemy.yr = 1;
		}
	}

	inline function isOnGround(enemy:BobshotEnemy):Bool {
		return !enemy.destroyed && enemy.vBase.dy == 0 && hasGroundSupport(enemy);
	}

	inline function hasGroundSupport(enemy:BobshotEnemy):Bool {
		return enemy.hasGroundSupport();
	}

	inline function eachAlivePlayer(cb:BobshotPlayer->Void):Void {
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) )
				cb(e.as(BobshotPlayer));
	}

	function findClosestPlayer(enemy:BobshotEnemy, distanceFn:(BobshotEnemy, BobshotPlayer)->Float, ?maxDistance:Null<Float>):Null<BobshotPlayer> {
		var nearest : Null<BobshotPlayer> = null;
		var nearestDist = maxDistance==null ? 999999.0 : maxDistance;

		eachAlivePlayer(function(player) {
			var dist = distanceFn(enemy, player);
			if( dist <= nearestDist ) {
				nearest = player;
				nearestDist = dist;
			}
		});

		return nearest;
	}

	function hasAnyPlayer(enemy:BobshotEnemy, predicate:(BobshotEnemy, BobshotPlayer)->Bool):Bool {
		var found = false;

		eachAlivePlayer(function(player) {
			if( !found && predicate(enemy, player) )
				found = true;
		});

		return found;
	}
}

