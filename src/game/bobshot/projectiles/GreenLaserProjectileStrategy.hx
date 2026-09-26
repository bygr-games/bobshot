package bobshot.projectiles;

class GreenLaserProjectileStrategy extends BaseProjectileStrategy {

	public function new() {
		super(0x55FF66, 0x7DFF8A, 0xC2FF70, false, 0.9, 0.28);
	}

	override public function initGraphics(projectile:Projectile):Void {
		super.initGraphics(projectile);
		projectile.spr.scaleX = 2.4;
		projectile.spr.scaleY = 0.5;
	}
}