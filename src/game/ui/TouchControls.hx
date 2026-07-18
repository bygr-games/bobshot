package ui;

private typedef TouchButton = {
	var node : h2d.Object;
	var bg : h2d.Graphics;
	var hit : h2d.Interactive;
	var label : h2d.Text;
}

class TouchControls {
	public static var leftDown(default, null) = false;
	public static var rightDown(default, null) = false;
	public static var upDown(default, null) = false;
	public static var downDown(default, null) = false;
	public static var jumpDown(default, null) = false;
	public static var shootDown(default, null) = false;

	public static var downPressed(default, null) = false;
	public static var jumpPressed(default, null) = false;
	public static var shootPressed(default, null) = false;

	static var prevDown = false;
	static var prevJump = false;
	static var prevShoot = false;

	var root : h2d.Object;
	var leftBtn : TouchButton;
	var rightBtn : TouchButton;
	var upBtn : TouchButton;
	var downBtn : TouchButton;
	var jumpBtn : TouchButton;
	var shootBtn : TouchButton;

	public function new(parent:h2d.Object) {
		root = new h2d.Object(parent);
		leftBtn = createButton("L", (v)->leftDown = v);
		rightBtn = createButton("R", (v)->rightDown = v);
		upBtn = createButton("U", (v)->upDown = v);
		downBtn = createButton("D", (v)->downDown = v);
		jumpBtn = createButton("J", (v)->jumpDown = v);
		shootBtn = createButton("S", (v)->shootDown = v);
	}

	public static function shouldEnable() {
		return true;
	}

	public static function beginFrame(locked:Bool) {
		var allowInput = !locked;
		var curDown = allowInput && downDown;
		var curJump = allowInput && jumpDown;
		var curShoot = allowInput && shootDown;

		downPressed = curDown && !prevDown;
		jumpPressed = curJump && !prevJump;
		shootPressed = curShoot && !prevShoot;

		prevDown = curDown;
		prevJump = curJump;
		prevShoot = curShoot;
	}

	public static function isDown(a:GameAction) {
		return switch a {
			case MoveLeft: leftDown;
			case MoveRight: rightDown;
			case MoveUp: upDown;
			case MoveDown: downDown;
			case Jump: jumpDown;
			case Shoot: shootDown;
			default: false;
		};
	}

	public static function isPressed(a:GameAction) {
		return switch a {
			case MoveDown: downPressed;
			case Jump: jumpPressed;
			case Shoot: shootPressed;
			default: false;
		};
	}

	public static function getMoveX() {
		return (leftDown ? -1.0 : 0.0) + (rightDown ? 1.0 : 0.0);
	}

	public function updateLayout(uiWid:Float, uiHei:Float) {
		var margin = Std.int(M.fmax(8, uiWid*0.025));
		var gap = Std.int(M.fmax(4, uiWid*0.008));
		var size = Std.int(M.fmax(30, uiWid*0.09));

		var dpadX = margin;
		var dpadY = Std.int(uiHei - margin - size*2 - gap);

		layoutButton(upBtn, dpadX + size + gap, dpadY, size);
		layoutButton(leftBtn, dpadX, dpadY + size + gap, size);
		layoutButton(downBtn, dpadX + size + gap, dpadY + size + gap, size);
		layoutButton(rightBtn, dpadX + (size + gap)*2, dpadY + size + gap, size);

		var actionX = Std.int(uiWid - margin - size*2 - gap);
		var actionY = Std.int(uiHei - margin - size*2 - gap);
		layoutButton(shootBtn, actionX + size + gap, actionY, size);
		layoutButton(jumpBtn, actionX, actionY + size + gap, size);
	}

	function createButton(label:String, setDown:Bool->Void) {
		var node = new h2d.Object(root);
		var bg = new h2d.Graphics(node);
		var hit = new h2d.Interactive(1, 1, node);
		var tf = new h2d.Text(Assets.fontPixel, node);
		tf.filter = new dn.heaps.filter.PixelOutline();
		tf.text = label;
		tf.textColor = 0xffffff;

		hit.onPush = (_)->setDown(true);
		hit.onRelease = (_)->setDown(false);
		hit.onReleaseOutside = (_)->setDown(false);
		hit.onOut = (_)->setDown(false);

		return {
			node: node,
			bg: bg,
			hit: hit,
			label: tf,
		};
	}

	function layoutButton(btn:TouchButton, x:Float, y:Float, size:Int) {
		btn.node.x = x;
		btn.node.y = y;
		btn.hit.width = size;
		btn.hit.height = size;
		btn.bg.clear();
		btn.bg.beginFill(0x000000, 0.35);
		btn.bg.drawRect(0, 0, size, size);
		btn.bg.endFill();
		btn.bg.lineStyle(1, 0xffffff, 0.6);
		btn.bg.drawRect(0, 0, size, size);
		btn.label.x = Std.int((size - btn.label.textWidth) * 0.5);
		btn.label.y = Std.int((size - btn.label.textHeight) * 0.5);
	}
}
