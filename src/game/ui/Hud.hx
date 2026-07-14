package ui;

class Hud extends GameChildProcess {
	var flow : h2d.Flow;
	var invalidated = true;
	var notifications : Array<h2d.Flow> = [];
	var notifTw : dn.Tweenie;

	var completionText : h2d.Text;
	var debugText : h2d.Text;
	var playerHud : HSprite;
	var currentPlayerHudAnim : Null<String>;

	public function new() {
		super();

		notifTw = new Tweenie(Const.FPS);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering

		flow = new h2d.Flow(root);
		notifications = [];

		completionText = new h2d.Text(Assets.fontPixel, root);
		completionText.filter = new dn.heaps.filter.PixelOutline();

		debugText = new h2d.Text(Assets.fontPixel, root);
		debugText.filter = new dn.heaps.filter.PixelOutline();

		playerHud = new HSprite(Assets.playerHud);
		root.addChild(playerHud);
		playerHud.setCenterRatio(0, 0);
		playerHud.visible = false;
		currentPlayerHudAnim = null;
		clearDebug();
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.UI_SCALE);
		updatePlayerHudLayout();
		invalidate();
	}

	/** Clear debug printing **/
	public inline function clearDebug() {
		debugText.text = "";
		debugText.visible = false;
	}

	/** Display a debug string **/
	public inline function debug(v:Dynamic, clear=true) {
		if( clear )
			debugText.text = Std.string(v);
		else
			debugText.text += "\n"+v;
		debugText.visible = true;
		debugText.x = Std.int( stageWid/Const.UI_SCALE - 4 - debugText.textWidth );
	}


	/** Pop a quick s in the corner **/
	public function notify(str:String, color:Col=0x0) {
		// Bg
		var t = Assets.tiles.getTile( D.tiles.uiNotification );
		var f = new dn.heaps.FlowBg(t, 5, root);
		f.colorizeBg(color);
		f.paddingHorizontal = 6;
		f.paddingBottom = 4;
		f.paddingTop = 0;
		f.paddingLeft = 9;
		f.y = 4;

		// Text
		var tf = new h2d.Text(Assets.fontPixel, f);
		tf.text = str;
		tf.maxWidth = 0.6 * stageWid/Const.UI_SCALE;
		tf.textColor = 0xffffff;
		tf.filter = new dn.heaps.filter.PixelOutline( color.toBlack(0.2) );

		// Notification lifetime
		var durationS = 2 + str.length*0.04;
		var p = createChildProcess();
		notifications.insert(0,f);
		p.tw.createS(f.x, -f.outerWidth>-2, TEaseOut, 0.1);
		p.onUpdateCb = ()->{
			if( p.stime>=durationS && !p.cd.hasSetS("done",Const.INFINITE) )
				p.tw.createS(f.x, -f.outerWidth, 0.2).end( p.destroy );
		}
		p.onDisposeCb = ()->{
			notifications.remove(f);
			f.remove();
		}

		// Move existing notifications
		var y = 4;
		for(f in notifications) {
			notifTw.terminateWithoutCallbacks(f.y);
			notifTw.createS(f.y, y, TEaseOut, 0.2);
			y+=f.outerHeight+1;
		}

	}

	public inline function invalidate() invalidated = true;

	function formatPercentage(value:Float) {
		return M.pretty(value, 1) + "%";
	}

	function render() {
		if( level==null ) {
			completionText.visible = false;
			playerHud.visible = false;
			return;
		}

		completionText.visible = true;
		completionText.text = "Completed " + formatPercentage(level.totalCompletedPercentage) + " / " + formatPercentage(level.requiredPercentage);
		completionText.x = 4;
		completionText.y = Std.int(stageHei/Const.UI_SCALE - completionText.textHeight - 4);
	}

	function getFirstAlivePlayer() {
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(bobshot.BobshotPlayer) ) {
				var player = e.as(bobshot.BobshotPlayer);
				if( player.isAlive() )
					return player;
			}

		return null;
	}

	function updatePlayerHudLayout() {
		var uiWidth = stageWid/Const.UI_SCALE;
		var margin = uiWidth * 0.02;
		playerHud.x = margin;
		playerHud.y = margin;

		var frameWidth = playerHud.tile==null ? 0.0 : playerHud.tile.width;
		if( frameWidth>0 ) {
			var targetWidth = uiWidth * 0.10;
			var s = targetWidth / frameWidth;
			playerHud.setScale(s);
		}
	}

	function updatePlayerHudAnim() {
		var player = getFirstAlivePlayer();
		if( player==null ) {
			playerHud.visible = false;
			currentPlayerHudAnim = null;
			return;
		}

		var nextAnim = player.getCurrentAnimTag();
		if( nextAnim==null || !Assets.playerHud.exists(nextAnim) ) {
			playerHud.visible = false;
			currentPlayerHudAnim = null;
			return;
		}

		playerHud.visible = true;
		if( currentPlayerHudAnim==nextAnim )
			return;

		currentPlayerHudAnim = nextAnim;
		playerHud.set(Assets.playerHud, nextAnim, 0);
		updatePlayerHudLayout();
		if( playerHud.group!=null && playerHud.group.anim!=null && playerHud.group.anim.length>0 )
			playerHud.anim.playAndLoop(nextAnim);
		else if( playerHud.animAllocated )
			playerHud.anim.stopWithoutStateAnims(nextAnim, 0);
	}

	public function onLevelStart() {
		invalidate();
	}

	override function preUpdate() {
		super.preUpdate();
		notifTw.update(tmod);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}

		updatePlayerHudAnim();
	}
}
