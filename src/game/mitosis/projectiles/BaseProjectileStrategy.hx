package mitosis.projectiles;

import mitosis.enemies.MitosisEnemy;
import mitosis.MitosisPlayer;

class BaseProjectileStrategy implements ProjectileStrategy {
	var speed : Float;
	var projectileColor : Col;
	var hitImpactColor : Col;
	var targetImpactColor : Col;
	var collideWithBounds : Bool;
	var lifetimeS : Null<Float>;

	public function new(projectileColor:Col, hitImpactColor:Col, targetImpactColor:Col, collideWithBounds:Bool, ?lifetimeS:Null<Float>, ?speed:Float) {
		this.projectileColor = projectileColor;
		this.hitImpactColor = hitImpactColor;
		this.targetImpactColor = targetImpactColor;
		this.collideWithBounds = collideWithBounds;
		this.lifetimeS = lifetimeS;
		this.speed = speed==null ? 0.16 : speed;
	}

	public function initGraphics(projectile:Projectile):Void {
		projectile.iwid = 8;
		projectile.ihei = 4;
		projectile.setPivots(0.5, 0.5);

		projectile.vBase.setFricts(0.82, 1);
		if( lifetimeS!=null )
			projectile.cd.setS("projectileLife", lifetimeS);

		var b = new h2d.Bitmap(h2d.Tile.fromColor(projectileColor, projectile.iwid, projectile.ihei), projectile.spr);
		b.tile.setCenterRatio(0.5, 0.5);
	}

	public function update(projectile:Projectile):Void {
		if( lifetimeS!=null && !projectile.cd.has("projectileLife") ) {
			emitImpact(projectile.centerX, projectile.centerY, hitImpactColor);
			projectile.destroy();
			return;
		}

		projectile.vBase.addX(projectile.shotVelX * speed);
		projectile.vBase.addY(projectile.shotVelY * speed);

		if( !projectile.cd.hasSetS("projectileTrail", 0.03) ) {
			var p = projectile.fx.allocMain_add(D.tiles.fxDot, projectile.centerX, projectile.centerY);
			p.setCenterRatio(0.5, 0.5);
			p.setScale(0.45);
			p.alpha = 0.7;
			p.lifeS = 0.15;
			p.colorize(projectileColor);
		}
	}

	public function collidesWithLevelBounds():Bool {
		return collideWithBounds;
	}

	public function onXCollision(projectile:Projectile, dir:Int):Void {
		emitImpact(projectile.centerX, projectile.centerY, hitImpactColor);
		projectile.destroy();
	}

	public function onYCollision(projectile:Projectile, dir:Int):Void {
		emitImpact(projectile.centerX, projectile.centerY, hitImpactColor);
		projectile.destroy();
	}

	public function onEnemyHit(projectile:Projectile, enemy:MitosisEnemy):Void {
		emitImpact(enemy.centerX, enemy.centerY, targetImpactColor);
		projectile.destroy();
	}

	public function onPlayerHit(projectile:Projectile, player:MitosisPlayer):Void {
		emitImpact(player.centerX, player.centerY, targetImpactColor);
		projectile.destroy();
	}

	public function dispose():Void {}

	function emitImpact(x:Float, y:Float, color:Col):Void {
		for( i in 0...8 ) {
			var p = Game.ME.fx.allocMain_add(D.tiles.fxDot, x, y);
			p.setCenterRatio(0.5, 0.5);
			p.alpha = 1;
			p.setScale(0.7);
			p.lifeS = 0.18;
			p.frict = 0.86;
			p.moveAwayFrom(x, y, Lib.rnd(0.5, 1.3));
			p.colorize(color);
		}
	}
}

