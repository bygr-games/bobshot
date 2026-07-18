package bobshot;

import bobshot.enemies.BobshotEnemy;
import bobshot.BobshotPlayer;

class FallingObject extends Entity {
	static inline var GRAVITY = 0.05;

	var isFalling = false;
	var sliceType : String;
	var grantsPlayerCredit = false;

	public function new(cx:Int, cy:Int, sliceType:String, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		this.sliceType = sliceType;
		
		// Set size based on slice dimensions
		applyHitboxByType();
		
		// Set the sprite using the slice
		updateSprite();
	}

	function applyHitboxByType() {
		switch( sliceType.toLowerCase() ) {
			case "lamp":
				iwid = 48;
				ihei = 48;

			default:
				iwid = 16;
				ihei = 16;
		}
	}

	function updateSprite() {
		if( Assets.tiles.exists(sliceType) ) {
			spr.set(Assets.tiles, sliceType, 0);
		} else {
			trace('Warning: FallingObject slice "$sliceType" not found in tiles atlas');
			spr.setEmptyTexture();
		}
	}

	public function startFalling() {
		isFalling = true;
	}

	function hasGroundSupport():Bool {
		var probeCy = Std.int(Math.floor(bottom / Const.GRID));
		var leftCx = Std.int(Math.floor((left + 0.001) / Const.GRID));
		var rightCx = Std.int(Math.floor((right - 0.001) / Const.GRID));
		
		for( probeCx in leftCx...rightCx+1 )
			if( level.hasCollision(probeCx, probeCy) )
				return true;
		
		return false;
	}

	function crushCollidingPlayers() {
		for( e in Entity.ALL ) {
			if( e.destroyed || !e.is(BobshotPlayer) )
				continue;

			var player = e.as(BobshotPlayer);
			if( Lib.rectangleOverlaps(left, top, wid, hei, player.left, player.top, player.wid, player.hei) )
				player.kill(this);
		}
	}

	function crushCollidingEnemies() {
		for( e in Entity.ALL ) {
			if( e.destroyed || !e.is(BobshotEnemy) )
				continue;

			var enemy = e.as(BobshotEnemy);
			if( Lib.rectangleOverlaps(left, top, wid, hei, enemy.left, enemy.top, enemy.wid, enemy.hei) ) {
				grantsPlayerCredit = true;
				enemy.kill(this);
				grantsPlayerCredit = false;
			}
		}
	}

	public inline function grantsPlayerKillCredit() {
		return grantsPlayerCredit;
	}

	override function fixedUpdate() {
		if( destroyed )
			return;
		
		if( isFalling ) {
			// Apply gravity
			vBase.addY(GRAVITY);
			
			// Check if we've landed
			if( dyTotal > 0 && hasGroundSupport() ) {
				vBase.clearY();
				vBump.clearY();
				yr = 1;
				isFalling = false;
				// Object has reached the ground - destroy it
				destroy();
				return;
			}
		}
		
		super.fixedUpdate();

		if( !destroyed && isFalling ) {
			crushCollidingPlayers();
			crushCollidingEnemies();
		}
	}
}
