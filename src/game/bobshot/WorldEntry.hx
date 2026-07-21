package bobshot;

class WorldEntry extends Entity {
	static inline var IDLE_TAG = "idle";

	public var worldName(default,null) : String;
	var idleTagApplied = false;

	public function new(cx:Int, cy:Int, worldName:String, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		this.worldName = worldName;
		iwid = 16;
		ihei = 16;
		updateTag();
	}

	function updateTag() {
		if( idleTagApplied )
			return;

		idleTagApplied = true;
		if( Assets.worldEntry.exists(IDLE_TAG) ) {
			spr.set(Assets.worldEntry, IDLE_TAG, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
				spr.anim.playAndLoop(IDLE_TAG);
			else if( spr.animAllocated )
				spr.anim.stopWithoutStateAnims(IDLE_TAG, 0);
		}
		else
			spr.setEmptyTexture();
	}

	override function postUpdate() {
		super.postUpdate();
		updateTag();
	}
}
