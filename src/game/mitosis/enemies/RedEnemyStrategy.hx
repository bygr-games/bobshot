package mitosis.enemies;

/**
	Red Enemy Strategy: stays in place and jumps constantly.
	Similar to a jumping enemy pattern found in many 2D platformers.
**/
class RedEnemyStrategy extends BaseEnemyStrategy {
	var jumpInterval = 0.8; // seconds between jumps

	public function new() {
		super();
	}

	override public function initHitbox(enemy:MitosisEnemy):Void {
		setHitbox(enemy, 16, 16);
	}

	override public function update(enemy:MitosisEnemy):Void {
		applyGravityIfAirborne(enemy);

		// Try to jump
		if( isOnGround(enemy) && !enemy.cd.hasSetS("redEnemyJump", jumpInterval) ) {
			enemy.vBase.addY(-0.85);
		}
	}
}


