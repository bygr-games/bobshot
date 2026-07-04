package mitosis;

class MitosisPlayerExit extends Entity {
	static inline var TAG_STEP = 10;
	static inline var MAX_TAG_VALUE = 100;

	var currentTag : Null<String>;

	public function new(cx:Int, cy:Int, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		iwid = 16;
		ihei = 48;
		updateTag();
	}

	function getRoundedTag() {
		var frameValue = (MAX_TAG_VALUE - level.requiredPercentage) + level.totalCompletedPercentage;
		var steppedValue = Std.int(Math.floor(frameValue / TAG_STEP)) * TAG_STEP;
		return M.iclamp(steppedValue, 0, MAX_TAG_VALUE);
	}

	function updateTag() {
		var nextTag = Std.string(getRoundedTag());
		if( currentTag==nextTag )
			return;

		currentTag = nextTag;
		if( Assets.playerExit.exists(nextTag) ) {
			spr.set(Assets.playerExit, nextTag, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
				spr.anim.playAndLoop(nextTag);
			else if( spr.animAllocated )
				spr.anim.stopWithoutStateAnims(nextTag, 0);
		}
		else
			spr.setEmptyTexture();
	}

	override function postUpdate() {
		super.postUpdate();
		updateTag();
	}
}

