package bobshot.enemies;

import bobshot.BobshotPlayer;

/**
	Flying Enemy Strategy: flies back and forth at its spawn altitude, reversing direction
	on walls and level edges ("run" animation). When a player is detected below it, it dives
	toward that player and keeps chasing ("chase" animation). It never falls: no gravity.
**/
class FlyingEnemyStrategy extends BaseEnemyStrategy {
	static inline var PATROL_SPEED = 0.03;
	static inline var CHASE_SPEED = 0.05;
	static inline var CHASE_VERTICAL_SPEED = 0.02;
	static inline var DETECTION_RANGE_TILES = 7.0;
	static inline var DETECTION_HALF_WIDTH_TILES = 2.5;
	static inline var CHASE_VERTICAL_DEAD_ZONE_PX = 4.0;

	var patrolDir = 1; // 1 for right, -1 for left
	var hasDetectedPlayer = false;

	public function new() {
		super();
	}

	override public function initHitbox(enemy:BobshotEnemy):Void {
		setHitbox(enemy, 16, 16);
	}

	override public function update(enemy:BobshotEnemy):Void {
		// This enemy flies: gravity is intentionally never applied

		if( !hasDetectedPlayer && isPlayerBelow(enemy) )
			hasDetectedPlayer = true;

		if( hasDetectedPlayer )
			chasePlayer(enemy);
		else
			patrol(enemy);
	}

	override public function onYCollision(enemy:BobshotEnemy):Void {
		// Flying enemies simply stop on ground/ceiling contact (velocities are
		// already cleared by the collision code), they never "land"
	}

	override public function onXCollision(enemy:BobshotEnemy, dir:Int):Void {
		// Bounce back on walls (only affects patrol mode: chase re-evaluates direction)
		patrolDir = -patrolDir;
		enemy.dir = patrolDir;
	}

	override public function getAnimState(enemy:BobshotEnemy):Null<String> {
		return hasDetectedPlayer ? enemy.getAnimChaseGroup() : enemy.getAnimRunGroup();
	}

	function patrol(enemy:BobshotEnemy):Void {
		if( enemy.willExitLevelHorizontally(patrolDir, PATROL_SPEED) )
			patrolDir = -patrolDir;

		enemy.dir = patrolDir;
		enemy.vBase.addX(patrolDir * PATROL_SPEED);
	}

	function chasePlayer(enemy:BobshotEnemy):Void {
		var player = getClosestPlayer(enemy);
		if( player==null ) {
			// No living player for now: keep waiting in chase mode
			enemy.dir = patrolDir;
			return;
		}

		var moveDir = player.centerX >= enemy.centerX ? 1 : -1;
		patrolDir = moveDir;
		enemy.dir = moveDir;
		enemy.vBase.addX(moveDir * CHASE_SPEED);

		// Dive toward the player altitude (or rise, if the player got above)
		var dy = player.centerY - enemy.centerY;
		if( dy > CHASE_VERTICAL_DEAD_ZONE_PX )
			enemy.vBase.addY(CHASE_VERTICAL_SPEED);
		else if( dy < -CHASE_VERTICAL_DEAD_ZONE_PX )
			enemy.vBase.addY(-CHASE_VERTICAL_SPEED);
	}

	function isPlayerBelow(enemy:BobshotEnemy):Bool {
		var found = false;
		var maxHalfWidthPx = DETECTION_HALF_WIDTH_TILES * Const.GRID;

		eachAlivePlayer(function(player) {
			if( found )
				return;

			if( player.centerY <= enemy.centerY )
				return;

			if( M.fabs(player.centerX - enemy.centerX) > maxHalfWidthPx )
				return;

			if( enemy.distCase(player) > DETECTION_RANGE_TILES )
				return;

			found = true;
		});

		return found;
	}

	function getClosestPlayer(enemy:BobshotEnemy):Null<BobshotPlayer> {
		return findClosestPlayer(enemy, function(origin, player) {
			return origin.distCase(player);
		});
	}
}
