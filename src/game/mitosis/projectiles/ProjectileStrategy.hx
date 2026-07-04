package mitosis.projectiles;

import mitosis.enemies.MitosisEnemy;
import mitosis.MitosisPlayer;

interface ProjectileStrategy {
	function update(projectile:Projectile):Void;
	function collidesWithLevelBounds():Bool;
	function onXCollision(projectile:Projectile, dir:Int):Void;
	function onYCollision(projectile:Projectile, dir:Int):Void;
	function onEnemyHit(projectile:Projectile, enemy:MitosisEnemy):Void;
	function onPlayerHit(projectile:Projectile, player:MitosisPlayer):Void;
	function initGraphics(projectile:Projectile):Void;
	function dispose():Void;
}


