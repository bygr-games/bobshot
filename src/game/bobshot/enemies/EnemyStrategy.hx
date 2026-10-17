package bobshot.enemies;

import bobshot.BobshotPlayer;

/**
	Strategy pattern interface for enemy AI and rendering behavior.
	Each enemy type implements this to define its movement and appearance.
**/
interface EnemyStrategy {
	/**
		Initialize the enemy's hitbox and pivots
	**/
	function initHitbox(enemy:BobshotEnemy):Void;

	/**
		Called each fixedUpdate frame to update enemy physics and behavior
	**/
	function update(enemy:BobshotEnemy):Void;

	/**
		Called on Y collision (landing on ground, hitting ceiling, etc)
	**/
	function onYCollision(enemy:BobshotEnemy):Void;

	/**
		Called on X collision (hitting walls)
	**/
	function onXCollision(enemy:BobshotEnemy, dir:Int):Void;

	/**
		Optional animation override: return a resolved animation group name to force it,
		or null to use the default animation logic (idle/run/jump/fall based on physics state)
	**/
	function getAnimState(enemy:BobshotEnemy):Null<String>;

	/**
		Clean up resources
	**/
	function dispose():Void;
}


