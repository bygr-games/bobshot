package bobshot.enemies;

import bobshot.BobshotPlayer;
import bobshot.projectiles.Projectile;

class AlienEnemyStrategy extends BaseEnemyStrategy {
	static inline var DETECTION_RANGE_TILES = 10.0;
	static inline var MOVE_SPEED = 0.04;
	static inline var SHOOT_INTERVAL_S = 3.0;

	var hasDetectedPlayer = false;

	public function new() {
		super();
	}

	override public function initHitbox(enemy:BobshotEnemy):Void {
		setHitbox(enemy, 16, 32);
		enemy.cd.setS("alienShoot", enemy.rnd(0, SHOOT_INTERVAL_S));
	}

	override public function update(enemy:BobshotEnemy):Void {
		applyGravityIfAirborne(enemy);

		var chasePlayer = hasDetectedPlayer ? getClosestPlayer(enemy) : getClosestNearbyPlayer(enemy);
		if( chasePlayer!=null ) {
			hasDetectedPlayer = true;
			var moveDir = chasePlayer.centerX >= enemy.centerX ? 1 : -1;
			enemy.dir = moveDir;

			if( isOnGround(enemy) )
				enemy.vBase.addX(moveDir * MOVE_SPEED);
		}

		var linePlayer = getClosestPlayerInSameHorizontalLine(enemy);
		if( linePlayer!=null && !enemy.cd.has("alienShoot") ) {
			enemy.cd.setS("alienShoot", SHOOT_INTERVAL_S);
			enemy.cd.setS("enemyShootAnim", 0.12);
			enemy.dir = linePlayer.centerX >= enemy.centerX ? 1 : -1;
			new Projectile(enemy.centerX + enemy.dir * 8, enemy.centerY - 4, enemy.dir, "alienLaser", "player");
		}
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

	function getClosestPlayerInSameHorizontalLine(enemy:BobshotEnemy):Null<BobshotPlayer> {
		return findClosestPlayerFiltered(enemy, function(origin, player) {
			return M.fabs(player.centerX - origin.centerX);
		}, null, function(origin, player) {
			return isInSameHorizontalLine(origin, player);
		});
	}

	function isInSameHorizontalLine(enemy:BobshotEnemy, player:BobshotPlayer):Bool {
		return player.bottom > enemy.top + 4
			&& player.top < enemy.bottom - 4;
	}

	function findClosestPlayerFiltered(enemy:BobshotEnemy, distanceFn:(BobshotEnemy, BobshotPlayer)->Float, ?maxDistance:Null<Float>, ?predicate:Null<(BobshotEnemy, BobshotPlayer)->Bool>):Null<BobshotPlayer> {
		var nearest : Null<BobshotPlayer> = null;
		var nearestDist = maxDistance==null ? 999999.0 : maxDistance;

		eachAlivePlayer(function(player) {
			if( predicate!=null && !predicate(enemy, player) )
				return;

			var dist = distanceFn(enemy, player);
			if( dist <= nearestDist ) {
				nearest = player;
				nearestDist = dist;
			}
		});

		return nearest;
	}
}