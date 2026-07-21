package bobshot;

class BobshotExitDoor extends Entity {
	static inline var IDLE_TAG = "idle";

	public function new(cx:Int, cy:Int, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		iwid = 16;
		ihei = 48;
		applyIdleTag();
	}

	function applyIdleTag() {
		if( Assets.exitDoor.exists(IDLE_TAG) ) {
			spr.set(Assets.exitDoor, IDLE_TAG, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
				spr.anim.playAndLoop(IDLE_TAG);
			else if( spr.animAllocated )
				spr.anim.stopWithoutStateAnims(IDLE_TAG, 0);
		}
		else
			spr.setEmptyTexture();
	}
}
