package mitosis;

class MitosisRecombobulator extends Entity {
	static inline var TAG_STEP = 10;
	static inline var MAX_TAG_VALUE = 100;
	static inline var REQUIRED_EPSILON = 0.001;
	static inline var PULL_SPEED = 0.22;
	static inline var PULL_DESTROY_RADIUS = 6.0;

	public var completePercentage(default,null) = 0.0;
	public var requiredPercentage(default,null) : Float;

	var hasSpawnedPlayer = false;
	var currentTag : Null<String>;
	var pullStarted = false;

	public function new(cx:Int, cy:Int, requiredPercentage:Float, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		iwid = 16;
		ihei = 48;
		this.requiredPercentage = M.fmax(0, requiredPercentage);
		updateTag();
	}

	inline function getDisplayValue() {
		return (MAX_TAG_VALUE - requiredPercentage) + completePercentage;
	}

	function getRoundedTag() {
		var steppedValue = Std.int(Math.floor(getDisplayValue() / TAG_STEP)) * TAG_STEP;
		return M.iclamp(steppedValue, 0, MAX_TAG_VALUE);
	}

	function updateTag() {
		var nextTag = Std.string(getRoundedTag());
		if( currentTag==nextTag )
			return;

		currentTag = nextTag;
		if( Assets.recombobulator.exists(nextTag) ) {
			spr.set(Assets.recombobulator, nextTag, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
				spr.anim.playAndLoop(nextTag);
			else if( spr.animAllocated )
				spr.anim.stopWithoutStateAnims(nextTag, 0);
		}
		else
			spr.setEmptyTexture();
	}

	inline function isComplete() {
		return completePercentage + REQUIRED_EPSILON >= requiredPercentage;
	}

	public inline function isDeactivated() {
		return isComplete();
	}

	function hasPendingPulledPlayers() {
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(MitosisPlayer) ) {
				var player = e.as(MitosisPlayer);
				if( player.isBeingPulledInto(this) )
					return true;
			}

		return false;
	}

	function trySpawnPlayer() {
		if( hasSpawnedPlayer || !isComplete() || hasPendingPulledPlayers() )
			return;

		hasSpawnedPlayer = true;
		var spawnX = right + Const.GRID * 0.5;
		var spawnY = attachY;
		new MitosisPlayer(spawnX, spawnY, true);
	}

	function startPullSequence() {
		if( pullStarted )
			return;

		pullStarted = true;
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(MitosisPlayer) ) {
				var player = e.as(MitosisPlayer);
				if( !player.isAlive() )
					continue;

				player.startPullInto(this);
			}
	}

	function updatePulledPlayers() {
		if( !pullStarted )
			return;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(MitosisPlayer) ) {
				var player = e.as(MitosisPlayer);
				if( !player.isBeingPulledInto(this) )
					continue;

				var dist = M.dist(player.attachX, player.attachY, attachX, attachY);
				if( dist <= PULL_DESTROY_RADIUS ) {
					player.destroy();
					continue;
				}

				var step = M.fmin(dist, PULL_SPEED * Const.GRID * tmod);
				var dx = (attachX - player.attachX) / dist;
				var dy = (attachY - player.attachY) / dist;
				player.setPosPixel(player.attachX + dx * step, player.attachY + dy * step);
				player.dir = dx>=0 ? 1 : -1;
			}
	}

	public function absorbPercentage(value:Float) {
		if( isDeactivated() || value<=0 )
			return;

		completePercentage = M.fmin(requiredPercentage, completePercentage + value);
		updateTag();
		if( isComplete() )
			startPullSequence();
		trySpawnPlayer();
	}

	override function postUpdate() {
		super.postUpdate();
		updatePulledPlayers();
		trySpawnPlayer();
		updateTag();
	}
}

