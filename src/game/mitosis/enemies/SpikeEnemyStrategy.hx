package mitosis.enemies;

class SpikeEnemyStrategy extends BaseEnemyStrategy {
	public function new() {
		super();
	}

	override public function initHitbox(enemy:MitosisEnemy):Void {
		setHitbox(enemy, 16, 16);
	}

	override public function update(enemy:MitosisEnemy):Void {
		applyGravityIfAirborne(enemy);
	}
}

