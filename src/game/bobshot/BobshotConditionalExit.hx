package bobshot;

import bobshot.enemies.BobshotEnemy;

class BobshotConditionalExit extends Entity {
	static inline var IDLE_TAG = "idle";
	static inline var CLOSING_TAG = "closing";
	static inline var OPENING_TAG = "opening";
	static inline var TRIGGER_DISTANCE_TILES = 5;

	var currentTag : Null<String>;
	var shouldLoopCurrentTag : Bool;
	var appliedTag : Null<String>;
	var appliedTagLoop : Null<Bool>;

	public function new(cx:Int, cy:Int, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		iwid = 16;
		ihei = 48;
		currentTag = IDLE_TAG;
		shouldLoopCurrentTag = true;
		appliedTag = null;
		appliedTagLoop = null;
		updateTag();
	}

	function hasAliveEnemy() {
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotEnemy) ) {
				var enemy = e.as(BobshotEnemy);
				if( enemy.isAlive() )
					return true;
			}

		return false;
	}

	public inline function blocksPlayers() {
		return hasAliveEnemy() || currentTag!=IDLE_TAG;
	}

	function hasNearbyPlayer() {
		var maxDistance = TRIGGER_DISTANCE_TILES * Const.GRID;
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var player = e.as(BobshotPlayer);
				if( player.isAlive() && M.dist(centerX, centerY, player.centerX, player.centerY) <= maxDistance )
					return true;
			}

		return false;
	}

	function allPlayersAreFarEnough() {
		var maxDistance = TRIGGER_DISTANCE_TILES * Const.GRID;
		var hasAlivePlayer = false;
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var player = e.as(BobshotPlayer);
				if( !player.isAlive() )
					continue;
				hasAlivePlayer = true;
				if( M.dist(centerX, centerY, player.centerX, player.centerY) < maxDistance )
					return false;
			}

		return hasAlivePlayer;
	}

	function playTag(tag:String, loop:Bool) {
		currentTag = tag;
		shouldLoopCurrentTag = loop;
	}

	function updateState() {
		var enemiesAlive = hasAliveEnemy();
		if( !enemiesAlive ) {
			if( currentTag==CLOSING_TAG )
				playTag(OPENING_TAG, false);
			return;
		}

		if( currentTag==IDLE_TAG && hasNearbyPlayer() )
			playTag(CLOSING_TAG, false);
		else if( currentTag==CLOSING_TAG && allPlayersAreFarEnough() )
			playTag(OPENING_TAG, false);
	}

	function updateTag() {
		if( appliedTag==currentTag && appliedTagLoop==shouldLoopCurrentTag )
			return;

		appliedTag = currentTag;
		appliedTagLoop = shouldLoopCurrentTag;
		if( Assets.conditionalExit.exists(currentTag) ) {
			spr.set(Assets.conditionalExit, currentTag, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 ) {
				if( shouldLoopCurrentTag )
					spr.anim.playAndLoop(currentTag);
				else {
					spr.anim.play(currentTag);
					if( currentTag==OPENING_TAG )
						spr.anim.onComplete(()-> playTag(IDLE_TAG, true));
				}
			}
			else if( spr.animAllocated )
				spr.anim.stopWithoutStateAnims(currentTag, 0);
		}
		else
			spr.setEmptyTexture();
	}

	override function postUpdate() {
		super.postUpdate();
		updateState();
		updateTag();
	}
}
