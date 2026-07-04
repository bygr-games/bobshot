package mitosis.enemies;

import mitosis.MitosisPlayer;
import mitosis.projectiles.Projectile;

private typedef EnemyTypeDef = {
	var id : String;
	var createStrategy : Void->EnemyStrategy;
	var spriteLib : Void->SpriteLib;
	var harmless : Bool;
	var hazard : Bool;
	var fallbackColor : Int;
	var useInBoundsWallCollision : Bool;
	var despawnAfterLeavingLevel : Bool;
}

/**
	MitosisEnemy is an Entity that spawns from level data and exhibits different
	behaviors based on its strategy pattern implementation.
	
	Supported types:
	- "saw": walks back and forth, turns on collision/cliff
	- "red": stays in place and jumps constantly
	- "shooting": stays in place, shoots toward player every 3 seconds, and does not hurt on contact
	- "scared": runs away from nearby players and does not hurt them on contact
	- "spike": stays in place and splits players on contact
**/
class MitosisEnemy extends Entity {
	public static inline var COLLISION_EPSILON = 0.001;
	static inline var DEFAULT_ENEMY_TYPE = "saw";
	static final ENEMY_DEFS = initEnemyDefs();

	var strategy : EnemyStrategy;
	var enemyType : String;
	var enemyDef : EnemyTypeDef;
	var enemyLib : SpriteLib;
	var fallbackBitmap : Null<h2d.Bitmap>;

	var animIdle : Null<String>;
	var animRun : Null<String>;
	var animJump : Null<String>;
	var animFall : Null<String>;
	var animShoot : Null<String>;
	var currentAnim : Null<String>;

	static function initEnemyDefs() {
		var defs = new haxe.ds.StringMap<EnemyTypeDef>();

		defs.set("saw", {
			id: "saw",
			createStrategy: function() return new SawEnemyStrategy(),
			spriteLib: function() return Assets.enemySaw,
			harmless: false,
			hazard: true,
			fallbackColor: 0x0000FF,
			useInBoundsWallCollision: false,
			despawnAfterLeavingLevel: false,
		});

		defs.set("red", {
			id: "red",
			createStrategy: function() return new RedEnemyStrategy(),
			spriteLib: function() return Assets.enemyRed,
			harmless: false,
			hazard: false,
			fallbackColor: 0xFF0000,
			useInBoundsWallCollision: false,
			despawnAfterLeavingLevel: false,
		});

		defs.set("shooting", {
			id: "shooting",
			createStrategy: function() return new ShootingEnemyStrategy(),
			spriteLib: function() return Assets.enemyShooting,
			harmless: true,
			hazard: false,
			fallbackColor: 0x008000,
			useInBoundsWallCollision: false,
			despawnAfterLeavingLevel: false,
		});

		defs.set("scared", {
			id: "scared",
			createStrategy: function() return new ScaredEnemyStrategy(),
			spriteLib: function() return Assets.enemyScared,
			harmless: true,
			hazard: false,
			fallbackColor: 0x7A7AFF,
			useInBoundsWallCollision: true,
			despawnAfterLeavingLevel: true,
		});

		defs.set("spike", {
			id: "spike",
			createStrategy: function() return new SpikeEnemyStrategy(),
			spriteLib: function() return Assets.enemySpike,
			harmless: false,
			hazard: true,
			fallbackColor: 0x666666,
			useInBoundsWallCollision: false,
			despawnAfterLeavingLevel: false,
		});

		return defs;
	}

	public inline function isHarmless() {
		return enemyDef.harmless;
	}

	public inline function isHazard() {
		return enemyDef.hazard;
	}

	inline function pxToLevelCoord(v:Float) {
		return Std.int(Math.floor(v / Const.GRID));
	}

	function getSolidColumnOnRight() : Null<Float> {
		var probeCx = pxToLevelCoord(right);
		var topCy = pxToLevelCoord(top + COLLISION_EPSILON);
		var bottomCy = pxToLevelCoord(bottom - COLLISION_EPSILON);
		for( probeCy in topCy...bottomCy+1 )
			if( level.hasWallCollision(probeCx, probeCy) )
				return probeCx * Const.GRID;

		return null;
	}

	function getSolidColumnOnRightInBounds() : Null<Float> {
		var probeCx = pxToLevelCoord(right);
		if( probeCx<0 || probeCx>=level.cWid )
			return null;

		var topCy = pxToLevelCoord(top + COLLISION_EPSILON);
		var bottomCy = pxToLevelCoord(bottom - COLLISION_EPSILON);
		for( probeCy in topCy...bottomCy+1 )
			if( level.isValid(probeCx, probeCy) && level.hasWallCollision(probeCx, probeCy) )
				return probeCx * Const.GRID;

		return null;
	}

	function getSolidColumnOnLeft() : Null<Float> {
		var probeCx = pxToLevelCoord(left - COLLISION_EPSILON);
		var topCy = pxToLevelCoord(top + COLLISION_EPSILON);
		var bottomCy = pxToLevelCoord(bottom - COLLISION_EPSILON);
		for( probeCy in topCy...bottomCy+1 )
			if( level.hasWallCollision(probeCx, probeCy) )
				return (probeCx + 1) * Const.GRID;

		return null;
	}

	function getSolidColumnOnLeftInBounds() : Null<Float> {
		var probeCx = pxToLevelCoord(left - COLLISION_EPSILON);
		if( probeCx<0 || probeCx>=level.cWid )
			return null;

		var topCy = pxToLevelCoord(top + COLLISION_EPSILON);
		var bottomCy = pxToLevelCoord(bottom - COLLISION_EPSILON);
		for( probeCy in topCy...bottomCy+1 )
			if( level.isValid(probeCx, probeCy) && level.hasWallCollision(probeCx, probeCy) )
				return (probeCx + 1) * Const.GRID;

		return null;
	}

	function getGroundCollisionRow() : Null<Float> {
		var probeCy = pxToLevelCoord(bottom);
		var leftCx = pxToLevelCoord(left + COLLISION_EPSILON);
		var rightCx = pxToLevelCoord(right - COLLISION_EPSILON);
		for( probeCx in leftCx...rightCx+1 )
			if( level.hasCollision(probeCx, probeCy) )
				return probeCy * Const.GRID;

		return null;
	}

	function getCeilingCollisionRow() : Null<Float> {
		var probeCy = pxToLevelCoord(top - COLLISION_EPSILON);
		var leftCx = pxToLevelCoord(left + COLLISION_EPSILON);
		var rightCx = pxToLevelCoord(right - COLLISION_EPSILON);
		for( probeCx in leftCx...rightCx+1 )
			if( level.hasWallCollision(probeCx, probeCy) )
				return (probeCy + 1) * Const.GRID;

		return null;
	}

	public inline function hasGroundSupport() {
		return getGroundCollisionRow()!=null;
	}

	public inline function hasWallInDirection(dir:Int) {
		return dir>0 ? getSolidColumnOnRight()!=null : getSolidColumnOnLeft()!=null;
	}

	public inline function hasWallInDirectionIgnoringLevelBounds(dir:Int) {
		return dir>0 ? getSolidColumnOnRightInBounds()!=null : getSolidColumnOnLeftInBounds()!=null;
	}

	public inline function hasGroundAhead(dir:Int) {
		var probeX = dir>0 ? right + COLLISION_EPSILON : left - COLLISION_EPSILON;
		var probeCx = pxToLevelCoord(probeX);
		var probeCy = pxToLevelCoord(bottom + COLLISION_EPSILON);
		return level.hasCollision(probeCx, probeCy);
	}

	public inline function willExitLevelHorizontally(dir:Int, moveAmount:Float) {
		var offset = M.fabs(moveAmount);
		return dir>0 ? right + offset > level.pxWid : left - offset < 0;
	}

	public inline function hasLeftLevelHorizontally() {
		return right<=0 || left>=level.pxWid;
	}

	/**
		Create an enemy at a specific grid position with a given type
	**/
	public function new(cx:Int, cy:Int, type:String, ?pivotX:Null<Float>, ?pivotY:Null<Float>) {
		super(cx, cy, pivotX, pivotY);

		enemyDef = ENEMY_DEFS.get(type.toLowerCase());
		if( enemyDef==null ) {
			trace('Unknown enemy type: $type, defaulting to $DEFAULT_ENEMY_TYPE');
			enemyDef = ENEMY_DEFS.get(DEFAULT_ENEMY_TYPE);
		}
		enemyType = enemyDef.id;

		// Initialize physics
		vBase.setFricts(0.84, 0.94);

		strategy = enemyDef.createStrategy();

		strategy.initHitbox(this);
		initGraphics();
	}

	function initGraphics() {
		enemyLib = enemyDef.spriteLib();

		var baseNames = [
			enemyType,
			"enemy_" + enemyType,
			enemyType + "Enemy",
			"sample_" + enemyType
		];

		animIdle = resolveFirstExisting(["idle", "enemy_idle", "enemy"]);
		animRun = resolveFirstExisting(["run", "enemy_run"]);
		animJump = resolveFirstExisting(["jump", "enemy_jump"]);
		animFall = resolveFirstExisting(["fall", "enemy_fall"]);
		animShoot = resolveFirstExisting(["shoot", "enemy_shoot"]);

		if( animIdle==null )
			animIdle = resolveStateAnim(baseNames, "idle");
		if( animRun==null )
			animRun = resolveStateAnim(baseNames, "run");
		if( animJump==null )
			animJump = resolveStateAnim(baseNames, "jump");
		if( animFall==null )
			animFall = resolveStateAnim(baseNames, "fall");
		if( animShoot==null )
			animShoot = resolveStateAnim(baseNames, "shoot");

		if( animIdle!=null )
			applyAnim(animIdle);
		else
			createFallbackBitmap();
	}

	function createFallbackBitmap() {
		if( fallbackBitmap!=null )
			return;

		fallbackBitmap = new h2d.Bitmap(h2d.Tile.fromColor(enemyDef.fallbackColor, Std.int(iwid), Std.int(ihei)), spr);
		fallbackBitmap.tile.setCenterRatio(0.5, 1);
	}

	function resolveFirstExisting(candidates:Array<String>) : Null<String> {
		for( id in candidates )
			if( enemyLib.exists(id) )
				return id;
		return null;
	}

	function resolveStateAnim(baseNames:Array<String>, state:String) : Null<String> {
		var candidates = new Array<String>();
		for( base in baseNames ) {
			candidates.push(base + "_" + state);
			candidates.push(base + state.substr(0,1).toUpperCase() + state.substr(1));
		}
		for( base in baseNames )
			candidates.push(base);

		return resolveFirstExisting(candidates);
	}

	inline function isOnGroundNow() {
		return !destroyed && vBase.dy==0 && hasGroundSupport();
	}

	function applyAnim(group:Null<String>) {
		if( group==null || currentAnim==group )
			return;

		currentAnim = group;
		spr.set(enemyLib, group, 0);

		if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
			spr.anim.playAndLoop(group);
		else if( spr.animAllocated )
			spr.anim.stopWithoutStateAnims(group, 0);
	}

	function updateAnimState() {
		var next : Null<String>;

		if( cd.has("enemyShootAnim") && animShoot!=null )
			next = animShoot;
		else if( !isOnGroundNow() )
			next = dyTotal<0 ? (animJump!=null ? animJump : animIdle) : (animFall!=null ? animFall : animIdle);
		else if( M.fabs(dxTotal)>0.03 )
			next = animRun!=null ? animRun : animIdle;
		else
			next = animIdle;

		applyAnim(next);
	}

	override function onDie() {
		fx.enemyBloodBurst(centerX, centerY, 256);
		super.onDie();
	}

	override function dispose() {
		super.dispose();
		if( strategy != null ) {
			strategy.dispose();
			strategy = null;
		}
	}

	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();

		// Right collision
		var rightCollisionX = dxTotal>0
			? enemyDef.useInBoundsWallCollision
				? getSolidColumnOnRightInBounds()
				: getSolidColumnOnRight()
			: null;
		if( rightCollisionX!=null ) {
			xr = rightCollisionX / Const.GRID - ( (1-pivotX) * wid ) / Const.GRID - cx;
			strategy.onXCollision(this, 1);
		}

		// Left collision
		var leftCollisionX = dxTotal<0
			? enemyDef.useInBoundsWallCollision
				? getSolidColumnOnLeftInBounds()
				: getSolidColumnOnLeft()
			: null;
		if( leftCollisionX!=null ) {
			xr = leftCollisionX / Const.GRID + ( pivotX * wid ) / Const.GRID - cx;
			strategy.onXCollision(this, -1);
		}
	}

	/** Y collisions **/
	override function onPreStepY() {
		super.onPreStepY();

		// Land on ground or hit ceiling
		var groundCollisionY = dyTotal>0 ? getGroundCollisionRow() : null;
		if( groundCollisionY!=null ) {
			vBase.clearY();
			vBump.clearY();
			yr = groundCollisionY / Const.GRID - ( (1-pivotY) * hei ) / Const.GRID - cy;
			onPosManuallyChangedY();
			strategy.onYCollision(this);
		}

		// Ceiling collision
		var ceilingCollisionY = dyTotal<0 ? getCeilingCollisionRow() : null;
		if( ceilingCollisionY!=null ) {
			vBase.clearY();
			vBump.clearY();
			yr = ceilingCollisionY / Const.GRID + ( pivotY * hei ) / Const.GRID - cy;
			onPosManuallyChangedY();
		}
	}

	/**
		Update is called at variable framerate (before/after fixedUpdate).
		We store strategy update logic in fixedUpdate instead.
	**/
	override function preUpdate() {
		super.preUpdate();
	}

	/**
		FixedUpdate is called at constant 30 FPS. All physics calculations happen here.
	**/
	override function fixedUpdate() {
		if( destroyed )
			return;

		super.fixedUpdate();

		if( destroyed )
			return;

		if( enemyDef.despawnAfterLeavingLevel && hasLeftLevelHorizontally() ) {
			destroy();
			return;
		}

		// Apply strategy behavior
		strategy.update(this);
		if( destroyed )
			return;

		if( !isHazard() ) {
			for( e in Entity.ALL )
				if( !e.destroyed && e!=this && e.is(MitosisEnemy) ) {
					var other = e.as(MitosisEnemy);
					if( !other.isAlive() || !other.isHazard() )
						continue;

					var overlapsX = right > other.left + COLLISION_EPSILON && left < other.right - COLLISION_EPSILON;
					var overlapsY = bottom > other.top + COLLISION_EPSILON && top < other.bottom - COLLISION_EPSILON;
					if( overlapsX && overlapsY ) {
						kill(other);
						break;
					}
				}

			if( destroyed )
				return;
		}

		updateAnimState();
	}
}


