package bobshot.projectiles;

import bobshot.enemies.BobshotEnemy;
import bobshot.BobshotPlayer;

interface ProjectileStrategy {
	function update(projectile:Projectile):Void;
	function collidesWithLevelBounds():Bool;
	function onXCollision(projectile:Projectile, dir:Int):Void;
	function onYCollision(projectile:Projectile, dir:Int):Void;
	function onEnemyHit(projectile:Projectile, enemy:BobshotEnemy):Void;
	function onPlayerHit(projectile:Projectile, player:BobshotPlayer):Void;
	function initGraphics(projectile:Projectile):Void;
	function dispose():Void;
}


