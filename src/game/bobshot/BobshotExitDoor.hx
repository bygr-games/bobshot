package bobshot;

class BobshotExitDoor extends Entity {
	static inline var IDLE_TAG = "idle";
	static inline var OPEN_TAG = "open";
	static inline var OPEN_IDLE_TAG = "open_idle";
	static inline var TRIGGER_DISTANCE_TILES = 5;

	var currentTag : String;
	var shouldLoopCurrentTag : Bool;
	var shouldReverseCurrentTag : Bool;
	var appliedTag : Null<String>;
	var appliedTagLoop : Null<Bool>;
	var appliedTagReverse : Null<Bool>;

	public function new(cx:Int, cy:Int, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		iwid = 16;
		ihei = 48;
		currentTag = IDLE_TAG;
		shouldLoopCurrentTag = true;
		shouldReverseCurrentTag = false;
		appliedTag = null;
		appliedTagLoop = null;
		appliedTagReverse = null;
		updateTag();
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

	function playTag(tag:String, loop:Bool, reverse:Bool=false) {
		currentTag = tag;
		shouldLoopCurrentTag = loop;
		shouldReverseCurrentTag = reverse;
	}

	function updateState() {
		var nearbyPlayer = hasNearbyPlayer();
		if( nearbyPlayer ) {
			if( currentTag==IDLE_TAG || currentTag==OPEN_TAG && shouldReverseCurrentTag )
				playTag(OPEN_TAG, false);
		}
		else if( currentTag==OPEN_IDLE_TAG )
			playTag(OPEN_TAG, false, true);
	}

	function onOpenComplete() {
		if( currentTag!=OPEN_TAG )
			return;

		if( shouldReverseCurrentTag ) {
			if( hasNearbyPlayer() )
				playTag(OPEN_TAG, false);
			else
				playTag(IDLE_TAG, true);
		}
		else if( hasNearbyPlayer() )
			playTag(OPEN_IDLE_TAG, true);
		else
			playTag(OPEN_TAG, false, true);
	}

	function updateTag() {
		if( appliedTag==currentTag && appliedTagLoop==shouldLoopCurrentTag && appliedTagReverse==shouldReverseCurrentTag )
			return;

		appliedTag = currentTag;
		appliedTagLoop = shouldLoopCurrentTag;
		appliedTagReverse = shouldReverseCurrentTag;
		if( Assets.exitDoor.exists(currentTag) ) {
			spr.set(Assets.exitDoor, currentTag, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 ) {
				if( shouldLoopCurrentTag )
					spr.anim.playAndLoop(currentTag);
				else {
					spr.anim.play(currentTag);
					if( shouldReverseCurrentTag )
						spr.anim.reverse();
					if( currentTag==OPEN_TAG )
						spr.anim.onComplete(onOpenComplete);
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
