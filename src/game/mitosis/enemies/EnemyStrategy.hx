package mitosis.enemies;

import mitosis.MitosisPlayer;

/**
	Strategy pattern interface for enemy AI and rendering behavior.
	Each enemy type implements this to define its movement and appearance.
**/
interface EnemyStrategy {
	/**
		Initialize the enemy's hitbox and pivots
	**/
	function initHitbox(enemy:MitosisEnemy):Void;

	/**
		Called each fixedUpdate frame to update enemy physics and behavior
	**/
	function update(enemy:MitosisEnemy):Void;

	/**
		Called on Y collision (landing on ground, hitting ceiling, etc)
	**/
	function onYCollision(enemy:MitosisEnemy):Void;

	/**
		Called on X collision (hitting walls)
	**/
	function onXCollision(enemy:MitosisEnemy, dir:Int):Void;

	/**
		Clean up resources
	**/
	function dispose():Void;
}


