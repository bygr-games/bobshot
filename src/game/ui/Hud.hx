package ui;

class Hud extends GameChildProcess {
	var flow : h2d.Flow;
	var invalidated = true;
	var notifications : Array<h2d.Flow> = [];
	var notifTw : dn.Tweenie;

	var debugText : h2d.Text;
	var playerHud : HSprite;
	var currentPlayerHudAnim : Null<String>;
	var pointsLabel : h2d.Text;
	var pointsRoot : h2d.Object;
	var pointsDigits : Array<HSprite>;
	var displayedPoints : Null<Int>;

	public function new() {
		super();

		notifTw = new Tweenie(Const.FPS);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering

		flow = new h2d.Flow(root);
		notifications = [];


		debugText = new h2d.Text(Assets.fontPixel, root);
		debugText.filter = new dn.heaps.filter.PixelOutline();

		playerHud = new HSprite(Assets.playerHud);
		root.addChild(playerHud);
		playerHud.setCenterRatio(0, 0);
		playerHud.visible = false;
		currentPlayerHudAnim = null;

		pointsLabel = new h2d.Text(Assets.fontPixel, root);
		pointsLabel.filter = new dn.heaps.filter.PixelOutline();
		pointsLabel.textColor = 0xffffff;
		pointsLabel.text = "POINTS";

		pointsRoot = new h2d.Object(root);
		pointsDigits = [];
		displayedPoints = null;

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

	function render() {
		if( level==null ) {
			playerHud.visible = false;
			return;
		}
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

		pointsLabel.x = margin;
		pointsLabel.y = margin + uiWidth * 0.12;
		pointsRoot.x = margin;
		pointsRoot.y = pointsLabel.y + pointsLabel.textHeight + 2;
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

	function getDigitTag(d:Int) {
		return Std.string(d);
	}

	function updatePointsText() {
		var total = bobshot.enemies.BobshotEnemy.getTotalPoints();
		if( displayedPoints!=null && displayedPoints==total )
			return;
		displayedPoints = total;

		pointsRoot.removeChildren();
		pointsDigits = [];

		var scoreStr = Std.string(total);
		if( scoreStr.charAt(0)=="-" )
			scoreStr = scoreStr.substr(1);
		if( scoreStr.length==0 )
			scoreStr = "0";

		var x = 0.0;
		if( total<0 ) {
			var minus = new h2d.Text(Assets.fontPixel, pointsRoot);
			minus.filter = new dn.heaps.filter.PixelOutline();
			minus.textColor = 0xffffff;
			minus.text = "-";
			minus.x = x;
			x += minus.textWidth + 2;
		}

		for( i in 0...scoreStr.length ) {
			var digit = Std.parseInt(scoreStr.charAt(i));
			if( digit==null )
				digit = 0;
			var tag = getDigitTag(digit);
			var spr = new HSprite(Assets.numbers, pointsRoot);
			spr.setCenterRatio(0, 0);
			spr.set(Assets.numbers, tag, 0);
			if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
				spr.anim.playAndLoop(tag);
			else if( spr.animAllocated )
				spr.anim.stopWithoutStateAnims(tag, 0);
			spr.x = x;
			x += spr.tile==null ? 8 : spr.tile.width + 1;
			pointsDigits.push(spr);
		}
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
		updatePointsText();
	}
}
