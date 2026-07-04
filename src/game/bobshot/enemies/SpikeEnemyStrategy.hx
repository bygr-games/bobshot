package bobshot.enemies;

class SpikeEnemyStrategy extends BaseEnemyStrategy {
	public function new() {
		super();
	}

	override public function initHitbox(enemy:BobshotEnemy):Void {
		setHitbox(enemy, 16, 16);
	}

	override public function update(enemy:BobshotEnemy):Void {
		applyGravityIfAirborne(enemy);
	}
}

