package bobshot;

class BobshotPlayerExit extends Entity {
	static inline var MAX_TAG_VALUE = 100;

	var currentTag : Null<String>;
	var visible : Bool;

	public function new(cx:Int, cy:Int, visible=true, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		this.visible = visible;
		iwid = 16;
		ihei = 16;
		if( !visible ) {
			entityVisible = false;
			spr.visible = false;
			return;
		}
		updateTag();
	}

	function getRoundedTag() {
		return MAX_TAG_VALUE;
	}

	function updateTag() {
		if( !visible )
			return;
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

