package bobshot;

class SnowFog extends GameChildProcess {
	var fogBitmap : h2d.Bitmap;
	var fogShader : SnowFogShader;

	public function new() {
		super();
		fogBitmap = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFFFF, 1, 1, 0), game.root);
		game.root.add(fogBitmap, Const.DP_FX_FRONT - 1);
		fogBitmap.scaleX = game.stageWid;
		fogBitmap.scaleY = game.stageHei;
		fogBitmap.filter = new h2d.filter.Shader(fogShader = cast new SnowFogShader());
	}

	override function onResize() {
		super.onResize();
		if( fogBitmap!=null ) {
			fogBitmap.scaleX = game.stageWid;
			fogBitmap.scaleY = game.stageHei;
		}
	}

	override function update() {
		super.update();
		fogShader.time += utmod / Const.FPS;
	}

	override function onDispose() {
		super.onDispose();
		fogBitmap.remove();
		fogBitmap = null;
		fogShader = null;
	}
}
