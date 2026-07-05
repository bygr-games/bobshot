package bobshot;

class FlyingPotion extends Entity {
	var currentTag : Null<String>;

	public function new(cx:Int, cy:Int, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);
		iwid = 16;
		ihei = 16;
		currentTag = "idle";
		updateTag();
	}

	function updateTag() {

		if( Assets.potionFlying.exists(currentTag) ) {
			spr.set(Assets.potionFlying, currentTag, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
				spr.anim.playAndLoop(currentTag);
			else if( spr.animAllocated )
				spr.anim.stopWithoutStateAnims(currentTag, 0);
		}
		else
			spr.setEmptyTexture();
	}

	override function postUpdate() {
		super.postUpdate();
		updateTag();
	}
}
