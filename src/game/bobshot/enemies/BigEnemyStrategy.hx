package bobshot.enemies;

import bobshot.BobshotPlayer;

class BigEnemyStrategy extends BaseEnemyStrategy {
	static inline var DETECTION_RANGE_TILES = 10.0;
	static inline var MOVE_SPEED = 0.04;

	var hasDetectedPlayer = false;

	public function new() {
		super();
	}

	override public function initHitbox(enemy:BobshotEnemy):Void {
		setHitbox(enemy, 64, 80);
	}

	override public function update(enemy:BobshotEnemy):Void {
		applyGravityIfAirborne(enemy);

		var player = hasDetectedPlayer ? getClosestPlayer(enemy) : getClosestNearbyPlayer(enemy);
		if( player == null )
			return;

		hasDetectedPlayer = true;

		var moveDir = player.centerX >= enemy.centerX ? 1 : -1;
		enemy.dir = moveDir;

		if( isOnGround(enemy) )
			enemy.vBase.addX(moveDir * MOVE_SPEED);
	}

	function getClosestNearbyPlayer(enemy:BobshotEnemy):BobshotPlayer {
		return findClosestPlayer(enemy, function(origin, player) {
			return origin.distCase(player);
		}, DETECTION_RANGE_TILES);
	}

	function getClosestPlayer(enemy:BobshotEnemy):BobshotPlayer {
		return findClosestPlayer(enemy, function(origin, player) {
			return origin.distCase(player);
		});
	}
}
