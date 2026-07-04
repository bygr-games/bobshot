package mitosis.enemies;

/**
	Saw Enemy Strategy: walks back and forth like a Koopa Troopa from Super Mario Bros.
	Moves in one direction until hitting a collision or cliff, then turns around.
**/
class SawEnemyStrategy extends BaseEnemyStrategy {
	var walkSpeed = 0.045;
	var currentDir = 1; // 1 for right, -1 for left

	public function new() {
		super();
	}

	override public function initHitbox(enemy:MitosisEnemy):Void {
		setHitbox(enemy, 16, 16);
	}

	override public function update(enemy:MitosisEnemy):Void {
		applyGravityIfAirborne(enemy);

		// Turn before moving if there is a wall ahead or a cliff ahead
		if( isOnGround(enemy) && ( isCollisionInDirection(enemy, currentDir) || isCliff(enemy, currentDir) ) ) {
			currentDir *= -1;
			enemy.dir = currentDir;
		}

		// Walk in current direction
		enemy.vBase.addX(currentDir * walkSpeed);
	}

	override public function onXCollision(enemy:MitosisEnemy, dir:Int):Void {
		// If collision happened, force a turn around
		currentDir *= -1;
		enemy.dir = currentDir;
	}

	private function isCollisionInDirection(enemy:MitosisEnemy, dir:Int):Bool {
		return enemy.hasWallInDirection(dir);
	}

	private function isCliff(enemy:MitosisEnemy, dir:Int):Bool {
		// A cliff is when there's ground below current position but no ground ahead
		return hasGroundSupport(enemy) && !enemy.hasGroundAhead(dir);
	}
}

