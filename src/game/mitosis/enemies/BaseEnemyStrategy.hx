package mitosis.enemies;

import mitosis.MitosisPlayer;

class BaseEnemyStrategy implements EnemyStrategy {
	static inline var GRAVITY = 0.05;

	public function new() {}

	public function initHitbox(enemy:MitosisEnemy):Void {}

	public function update(enemy:MitosisEnemy):Void {}

	public function onYCollision(enemy:MitosisEnemy):Void {
		landIfGrounded(enemy);
	}

	public function onXCollision(enemy:MitosisEnemy, dir:Int):Void {}

	public function dispose():Void {}

	inline function setHitbox(enemy:MitosisEnemy, width:Int, height:Int):Void {
		enemy.iwid = width;
		enemy.ihei = height;
	}

	inline function applyGravityIfAirborne(enemy:MitosisEnemy):Void {
		if( !isOnGround(enemy) )
			enemy.vBase.addY(GRAVITY);
	}

	inline function landIfGrounded(enemy:MitosisEnemy):Void {
		if( enemy.yr > 1 && hasGroundSupport(enemy) ) {
			enemy.vBase.clearY();
			enemy.vBump.clearY();
			enemy.yr = 1;
		}
	}

	inline function isOnGround(enemy:MitosisEnemy):Bool {
		return !enemy.destroyed && enemy.vBase.dy == 0 && hasGroundSupport(enemy);
	}

	inline function hasGroundSupport(enemy:MitosisEnemy):Bool {
		return enemy.hasGroundSupport();
	}

	inline function eachAlivePlayer(cb:MitosisPlayer->Void):Void {
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(MitosisPlayer) )
				cb(e.as(MitosisPlayer));
	}

	function findClosestPlayer(enemy:MitosisEnemy, distanceFn:(MitosisEnemy, MitosisPlayer)->Float, ?maxDistance:Null<Float>):Null<MitosisPlayer> {
		var nearest : Null<MitosisPlayer> = null;
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

	function hasAnyPlayer(enemy:MitosisEnemy, predicate:(MitosisEnemy, MitosisPlayer)->Bool):Bool {
		var found = false;

		eachAlivePlayer(function(player) {
			if( !found && predicate(enemy, player) )
				found = true;
		});

		return found;
	}
}

