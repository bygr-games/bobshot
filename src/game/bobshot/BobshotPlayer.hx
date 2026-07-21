package bobshot;

import bobshot.enemies.BobshotEnemy;
import bobshot.projectiles.Projectile;

/**
	BobshotPlayer is an Entity with some extra functionalities:
	- user controlled (using gamepad or keyboard)
	- falls with gravity
	- has basic level collisions
	- some squash animations, because it's cheap and they do the job
**/

class BobshotPlayer extends Entity {
	static inline var BASE_WIDTH = 16;
	static inline var BASE_HEIGHT = 32;
	static inline var COLLISION_EPSILON = 0.001;
	static inline var SPAWN_IMMUNITY_S = 1.0;
	static inline var CAMERA_FIT_PADDING_X = 30.0;
	static inline var CAMERA_FIT_PADDING_Y = 32.0;
	static inline var CAMERA_DEFAULT_ZOOM = 1;
	static var SIZE_LEVELS = [
		{ wid:16, hei:32, per: 100, hAcc: 0.045, hFric: 0.84, vAcc: 0.05, vFric: 0.96 },
		{ wid:12, hei:24, per: 100 / 2, hAcc: 0.045, hFric: 0.852, vAcc: 0.05, vFric: 0.956 },
		{ wid:8, hei:16, per: 100 / 4, hAcc: 0.045, hFric: 0.864, vAcc: 0.05, vFric: 0.952 },
		{ wid:6, hei:12, per: 100 / 8, hAcc: 0.045, hFric: 0.876, vAcc: 0.05, vFric: 0.948 },
		{ wid:4, hei:8, per: 100 / 16, hAcc: 0.045, hFric: 0.888, vAcc: 0.05, vFric: 0.944 },
		{ wid:3, hei:6, per: 100 / 32, hAcc: 0.045, hFric: 0.9, vAcc: 0.05, vFric: 0.94 },
	];

	var ca : ControllerAccess<GameAction>;
	var immunityShader : NegativeColorShader;
	var walkSpeed = 0.;
	var ignoredPlatformRow : Null<Int>;
	static var levelStartByUid : Map<Int,{ cx:Int, cy:Int }>;
	var fallbackBitmap : Null<h2d.Bitmap>;
	var sizeLevel(default,null) : Int;
	var pullTarget : Null<BobshotRecombobulator>;
	var flyingMode = false;
	static var currentSkin = 1;

	var animIdle : Null<String>;
	var animRun : Null<String>;
	var animJump : Null<String>;
	var animFall : Null<String>;
	var animShoot : Null<String>;
	var currentAnim : Null<String>;

	// This is TRUE if the player is not falling
	var onGround(get,never) : Bool;
		inline function get_onGround() return !destroyed && vBase.dy==0 && hasGroundSupport();

	inline function pxToLevelCoord(v:Float) {
		return Std.int(Math.floor(v / Const.GRID));
	}

	inline function isSolidPlayer(other:BobshotPlayer) {
		return other!=this && !other.destroyed && other.isAlive();
	}

	inline function isSolidEnemy(other:BobshotEnemy) {
		return !other.destroyed && other.isAlive();
	}

	inline function isSpawnImmune() {
		return ucd.has("spawnImmunity");
	}

	inline function collidesWithEnemies() {
		return isSpawnImmune();
	}

	public inline function hasFlyingMode() {
		return flyingMode;
	}

	public function enableFlyingMode() {
		if( !flyingMode ) {
			flyingMode = true;
			currentAnim = null;
		}
	}

	public function clearFlyingMode() {
		if( flyingMode ) {
			flyingMode = false;
			currentAnim = null;
		}
	}

	inline function getBaseSkinLib() {
		return currentSkin==2 ? Assets.player2 : Assets.player;
	}

	inline function getFlyingSkinLib() {
		return currentSkin==2 ? Assets.player2Flying : Assets.playerFlying;
	}

	inline function switchSkin(v:Int) {
		if( currentSkin!=v ) {
			currentSkin = v;
			currentAnim = null;
		}
	}

	inline function overlapsPlayerX(other:BobshotPlayer) {
		return right > other.left + COLLISION_EPSILON && left < other.right - COLLISION_EPSILON;
	}

	inline function overlapsPlayerY(other:BobshotPlayer) {
		return bottom > other.top + COLLISION_EPSILON && top < other.bottom - COLLISION_EPSILON;
	}

	inline function overlapsEnemyX(other:BobshotEnemy) {
		return right > other.left + COLLISION_EPSILON && left < other.right - COLLISION_EPSILON;
	}

	inline function overlapsEnemyY(other:BobshotEnemy) {
		return bottom > other.top + COLLISION_EPSILON && top < other.bottom - COLLISION_EPSILON;
	}

	inline function isSolidRecombobulator(other:BobshotRecombobulator) {
		if( isBeingPulledInto(other) )
			return false;
		return !other.destroyed && other.isDeactivated();
	}

	inline function isSolidConditionalExit(other:BobshotConditionalExit) {
		return !other.destroyed && other.blocksPlayers();
	}

	inline function overlapsRecombobulatorX(other:BobshotRecombobulator) {
		return right > other.left + COLLISION_EPSILON && left < other.right - COLLISION_EPSILON;
	}

	inline function overlapsRecombobulatorY(other:BobshotRecombobulator) {
		return bottom > other.top + COLLISION_EPSILON && top < other.bottom - COLLISION_EPSILON;
	}

	inline function overlapsConditionalExitX(other:BobshotConditionalExit) {
		return right > other.left + COLLISION_EPSILON && left < other.right - COLLISION_EPSILON;
	}

	inline function overlapsConditionalExitY(other:BobshotConditionalExit) {
		return bottom > other.top + COLLISION_EPSILON && top < other.bottom - COLLISION_EPSILON;
	}

	inline function recombobulatorGridsOverlapVertically(other:BobshotRecombobulator) : Bool {
		var playerTopCy = pxToLevelCoord(top + COLLISION_EPSILON);
		var playerBottomCy = pxToLevelCoord(bottom - COLLISION_EPSILON);
		var recombTopCy = pxToLevelCoord(other.top + COLLISION_EPSILON);
		var recombBottomCy = pxToLevelCoord(other.bottom - COLLISION_EPSILON);

		return playerBottomCy >= recombTopCy && playerTopCy <= recombBottomCy;
	}

	inline function recombobulatorLeftGridColumn(other:BobshotRecombobulator) : Int {
		return pxToLevelCoord(other.left + COLLISION_EPSILON);
	}

	inline function recombobulatorRightGridColumn(other:BobshotRecombobulator) : Int {
		return pxToLevelCoord(other.right - COLLISION_EPSILON);
	}

	function updateIgnoredPlatformRow() {
		if( ignoredPlatformRow!=null && bottom > (ignoredPlatformRow + 1) * Const.GRID + COLLISION_EPSILON )
			ignoredPlatformRow = null;
	}

	function getGroundPlatformRow() : Null<Int> {
		var probeCy = pxToLevelCoord(bottom);
		var leftCx = pxToLevelCoord(left + COLLISION_EPSILON);
		var rightCx = pxToLevelCoord(right - COLLISION_EPSILON);

		for( probeCx in leftCx...rightCx+1 )
			if( level.hasPlatformCollision(probeCx, probeCy) )
				return probeCy;

		return null;
	}

	function isPlacementFreeAt(targetAttachX:Float, targetAttachY:Float) {
		var targetLeft = targetAttachX - pivotX * wid;
		var targetRight = targetAttachX + (1-pivotX) * wid;
		var targetTop = targetAttachY - pivotY * hei;
		var targetBottom = targetAttachY + (1-pivotY) * hei;
		var leftCx = pxToLevelCoord(targetLeft + COLLISION_EPSILON);
		var rightCx = pxToLevelCoord(targetRight - COLLISION_EPSILON);
		var topCy = pxToLevelCoord(targetTop + COLLISION_EPSILON);
		var bottomCy = pxToLevelCoord(targetBottom - COLLISION_EPSILON);

		for( probeCy in topCy...bottomCy+1 )
			for( probeCx in leftCx...rightCx+1 )
				if( level.hasCollision(probeCx, probeCy) )
					return false;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var other = e.as(BobshotPlayer);
				if( !isSolidPlayer(other) )
					continue;

				var overlapsX = targetRight > other.left + COLLISION_EPSILON && targetLeft < other.right - COLLISION_EPSILON;
				var overlapsY = targetBottom > other.top + COLLISION_EPSILON && targetTop < other.bottom - COLLISION_EPSILON;
				if( overlapsX && overlapsY )
					return false;
			}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotEnemy) ) {
				var other = e.as(BobshotEnemy);
				if( !isSolidEnemy(other) )
					continue;

				var overlapsX = targetRight > other.left + COLLISION_EPSILON && targetLeft < other.right - COLLISION_EPSILON;
				var overlapsY = targetBottom > other.top + COLLISION_EPSILON && targetTop < other.bottom - COLLISION_EPSILON;
				if( overlapsX && overlapsY )
					return false;
			}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotRecombobulator) ) {
				var other = e.as(BobshotRecombobulator);
				if( !isSolidRecombobulator(other) )
					continue;

				var overlapsX = targetRight > other.left + COLLISION_EPSILON && targetLeft < other.right - COLLISION_EPSILON;
				var overlapsY = targetBottom > other.top + COLLISION_EPSILON && targetTop < other.bottom - COLLISION_EPSILON;
				if( overlapsX && overlapsY )
					return false;
			}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotConditionalExit) ) {
				var other = e.as(BobshotConditionalExit);
				if( !isSolidConditionalExit(other) )
					continue;

				var overlapsX = targetRight > other.left + COLLISION_EPSILON && targetLeft < other.right - COLLISION_EPSILON;
				var overlapsY = targetBottom > other.top + COLLISION_EPSILON && targetTop < other.bottom - COLLISION_EPSILON;
				if( overlapsX && overlapsY )
					return false;
			}

		return true;
	}

	function placeAtNearestSafeSplitPosition(baseAttachX:Float, baseAttachY:Float, preferredDir:Int) {
		var step = 2.0;
		var radius = 48.0;
		var height = 32.0;
		var horizontalSteps = M.ceil(radius / step);
		var verticalSteps = M.ceil(height / step);

		for( horizontalStep in 0...horizontalSteps+1 ) {
			var preferredOffsetX = preferredDir * horizontalStep * step;
			var alternateOffsetX = -preferredOffsetX;

			for( verticalStep in 0...verticalSteps+1 ) {
				var offsetY = -verticalStep * step;

				if( isPlacementFreeAt(baseAttachX + preferredOffsetX, baseAttachY + offsetY) ) {
					setPosPixel(baseAttachX + preferredOffsetX, baseAttachY + offsetY);
					return;
				}

				if( horizontalStep>0 && isPlacementFreeAt(baseAttachX + alternateOffsetX, baseAttachY + offsetY) ) {
					setPosPixel(baseAttachX + alternateOffsetX, baseAttachY + offsetY);
					return;
				}
			}
		}

		var fallbackStep = Const.GRID * 0.5;
		var fallbackStepsX = M.ceil(level.pxWid / fallbackStep);
		var fallbackStepsY = M.ceil(level.pxHei / fallbackStep);
		var bestDist:Float = Const.INFINITE;
		var bestX:Float = baseAttachX;
		var bestY:Float = baseAttachY;

		for( stepY in 0...fallbackStepsY+1 )
			for( stepX in 0...fallbackStepsX+1 ) {
				var candidateX = stepX * fallbackStep;
				var candidateY = stepY * fallbackStep;
				if( !isPlacementFreeAt(candidateX, candidateY) )
					continue;

				var dist = M.dist(baseAttachX, baseAttachY, candidateX, candidateY);
				if( dist<bestDist ) {
					bestDist = dist;
					bestX = candidateX;
					bestY = candidateY;
				}
			}

		if( bestDist<Const.INFINITE )
			setPosPixel(bestX, bestY);
	}

	function  getSolidColumnOnRight() : Null<Float> {
		var probeCx = pxToLevelCoord(right);
		var topCy = pxToLevelCoord(top + COLLISION_EPSILON);
		var bottomCy = pxToLevelCoord(bottom - COLLISION_EPSILON);
		var best:Null<Float> = null;
		for( probeCy in topCy...bottomCy+1 )
			if( level.hasWallCollision(probeCx, probeCy) )
				best = probeCx * Const.GRID;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var other = e.as(BobshotPlayer);
				if( !isSolidPlayer(other) || !overlapsPlayerY(other) )
					continue;

				if( right > other.left && left < other.left && centerX <= other.centerX )
					if( best==null || other.left<best )
						best = other.left;
			}

		if( collidesWithEnemies() )
			for( e in Entity.ALL )
				if( !e.destroyed && e.is(BobshotEnemy) ) {
					var other = e.as(BobshotEnemy);
					if( !isSolidEnemy(other) || !overlapsEnemyY(other) )
						continue;

					if( right > other.left && left < other.left && centerX <= other.centerX )
						if( best==null || other.left<best )
							best = other.left;
				}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotRecombobulator) ) {
				var other = e.as(BobshotRecombobulator);
				if( !isSolidRecombobulator(other) || !recombobulatorGridsOverlapVertically(other) )
					continue;

				var recombLeftCx = recombobulatorLeftGridColumn(other);
				var recombRightCx = recombobulatorRightGridColumn(other);
				if( probeCx >= recombLeftCx && probeCx <= recombRightCx ) {
					if( best==null || other.left<best )
						best = other.left;
				}
			}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotConditionalExit) ) {
				var other = e.as(BobshotConditionalExit);
				if( !isSolidConditionalExit(other) || !overlapsConditionalExitY(other) )
					continue;

				if( right > other.left && left < other.left && centerX <= other.centerX )
					if( best==null || other.left<best )
						best = other.left;
			}

		return best;
	}

	function getSolidColumnOnLeft() : Null<Float> {
		var probeCx = pxToLevelCoord(left - COLLISION_EPSILON);
		var topCy = pxToLevelCoord(top + COLLISION_EPSILON);
		var bottomCy = pxToLevelCoord(bottom - COLLISION_EPSILON);
		var best:Null<Float> = null;
		for( probeCy in topCy...bottomCy+1 )
			if( level.hasWallCollision(probeCx, probeCy) )
				best = (probeCx + 1) * Const.GRID;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var other = e.as(BobshotPlayer);
				if( !isSolidPlayer(other) || !overlapsPlayerY(other) )
					continue;

				if( left < other.right && right > other.right && centerX >= other.centerX )
					if( best==null || other.right>best )
						best = other.right;
			}

		if( collidesWithEnemies() )
			for( e in Entity.ALL )
				if( !e.destroyed && e.is(BobshotEnemy) ) {
					var other = e.as(BobshotEnemy);
					if( !isSolidEnemy(other) || !overlapsEnemyY(other) )
						continue;

					if( left < other.right && right > other.right && centerX >= other.centerX )
						if( best==null || other.right>best )
							best = other.right;
				}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotRecombobulator) ) {
				var other = e.as(BobshotRecombobulator);
				if( !isSolidRecombobulator(other) || !recombobulatorGridsOverlapVertically(other) )
					continue;

				var recombLeftCx = recombobulatorLeftGridColumn(other);
				var recombRightCx = recombobulatorRightGridColumn(other);
				if( probeCx >= recombLeftCx && probeCx <= recombRightCx ) {
					if( best==null || other.right>best )
						best = other.right;
				}
			}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotConditionalExit) ) {
				var other = e.as(BobshotConditionalExit);
				if( !isSolidConditionalExit(other) || !overlapsConditionalExitY(other) )
					continue;

				if( left < other.right && right > other.right && centerX >= other.centerX )
					if( best==null || other.right>best )
						best = other.right;
			}

		return best;
	}

	function getGroundCollisionRow() : Null<Float> {
		updateIgnoredPlatformRow();
		var probeCy = pxToLevelCoord(bottom);
		var leftCx = pxToLevelCoord(left + COLLISION_EPSILON);
		var rightCx = pxToLevelCoord(right - COLLISION_EPSILON);
		var best:Null<Float> = null;
		var ignorePlatformRow = ignoredPlatformRow!=null && ignoredPlatformRow==probeCy;
		for( probeCx in leftCx...rightCx+1 )
			if( level.hasWallCollision(probeCx, probeCy) || level.hasPlatformCollision(probeCx, probeCy) && !ignorePlatformRow )
				best = probeCy * Const.GRID;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var other = e.as(BobshotPlayer);
				if( !isSolidPlayer(other) || !overlapsPlayerX(other) )
					continue;

				if( bottom > other.top && top < other.top && centerY <= other.centerY )
					if( best==null || other.top<best )
						best = other.top;
			}

		if( collidesWithEnemies() )
			for( e in Entity.ALL )
				if( !e.destroyed && e.is(BobshotEnemy) ) {
					var other = e.as(BobshotEnemy);
					if( !isSolidEnemy(other) || !overlapsEnemyX(other) )
						continue;

					if( bottom > other.top && top < other.top && centerY <= other.centerY )
						if( best==null || other.top<best )
							best = other.top;
				}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotRecombobulator) ) {
				var other = e.as(BobshotRecombobulator);
				if( !isSolidRecombobulator(other) || !overlapsRecombobulatorX(other) )
					continue;

				if( bottom > other.top && top < other.top && centerY <= other.centerY )
					if( best==null || other.top<best )
						best = other.top;
			}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotConditionalExit) ) {
				var other = e.as(BobshotConditionalExit);
				if( !isSolidConditionalExit(other) || !overlapsConditionalExitX(other) )
					continue;

				if( bottom > other.top && top < other.top && centerY <= other.centerY )
					if( best==null || other.top<best )
						best = other.top;
			}

		return best;
	}

	function getCeilingCollisionRow() : Null<Float> {
		var probeCy = pxToLevelCoord(top - COLLISION_EPSILON);
		var leftCx = pxToLevelCoord(left + COLLISION_EPSILON);
		var rightCx = pxToLevelCoord(right - COLLISION_EPSILON);
		var best:Null<Float> = null;
		for( probeCx in leftCx...rightCx+1 )
			if( level.hasWallCollision(probeCx, probeCy) )
				best = (probeCy + 1) * Const.GRID;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var other = e.as(BobshotPlayer);
				if( !isSolidPlayer(other) || !overlapsPlayerX(other) )
					continue;

				if( top < other.bottom && bottom > other.bottom && centerY >= other.centerY )
					if( best==null || other.bottom>best )
						best = other.bottom;
			}

		if( collidesWithEnemies() )
			for( e in Entity.ALL )
				if( !e.destroyed && e.is(BobshotEnemy) ) {
					var other = e.as(BobshotEnemy);
					if( !isSolidEnemy(other) || !overlapsEnemyX(other) )
						continue;

					if( top < other.bottom && bottom > other.bottom && centerY >= other.centerY )
						if( best==null || other.bottom>best )
							best = other.bottom;
				}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotRecombobulator) ) {
				var other = e.as(BobshotRecombobulator);
				if( !isSolidRecombobulator(other) || !overlapsRecombobulatorX(other) )
					continue;

				if( top < other.bottom && bottom > other.bottom && centerY >= other.centerY )
					if( best==null || other.bottom>best )
						best = other.bottom;
			}

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotConditionalExit) ) {
				var other = e.as(BobshotConditionalExit);
				if( !isSolidConditionalExit(other) || !overlapsConditionalExitX(other) )
					continue;

				if( top < other.bottom && bottom > other.bottom && centerY >= other.centerY )
					if( best==null || other.bottom>best )
						best = other.bottom;
			}

		return best;
	}

	function hasGroundSupport() {
		if( getGroundCollisionRow()!=null )
			return true;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var other = e.as(BobshotPlayer);
				if( !isSolidPlayer(other) )
					continue;

				if( right > other.left + COLLISION_EPSILON && left < other.right - COLLISION_EPSILON && M.fabs(bottom - other.top) <= COLLISION_EPSILON*4 )
					return true;
			}

		if( collidesWithEnemies() )
			for( e in Entity.ALL )
				if( !e.destroyed && e.is(BobshotEnemy) ) {
					var other = e.as(BobshotEnemy);
					if( !isSolidEnemy(other) )
						continue;

					if( right > other.left + COLLISION_EPSILON && left < other.right - COLLISION_EPSILON && M.fabs(bottom - other.top) <= COLLISION_EPSILON*4 )
						return true;
				}

		return false;
	}

	function getCurrentLevelStart() {
		var starts:Array<Dynamic> = cast Reflect.field(level.data.l_Entities, "all_PlayerStart");
		if( starts!=null && starts.length>0 ) {
			var start = starts[0];
			var cx:Dynamic = Reflect.field(start, "cx");
			var cy:Dynamic = Reflect.field(start, "cy");
			if( cx!=null && cy!=null )
				return { cx:cast cx, cy:cast cy };
		}
		return null;
	}

	static function resolveSurvivorsMidpoint(out:LPoint) {
		var bounds = getSurvivorBounds();
		if( bounds==null )
			return false;

		out.levelX = (bounds.minX - CAMERA_FIT_PADDING_X + bounds.maxX + CAMERA_FIT_PADDING_X) * 0.5;
		out.levelY = (bounds.minY + bounds.maxY) * 0.5;
		return true;
	}

	static function getSurvivorBounds() {
		var minX = 9999999.0;
		var minY = 9999999.0;
		var maxX = -9999999.0;
		var maxY = -9999999.0;
		var count = 0;

		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var player = e.as(BobshotPlayer);
				if( !player.isAlive() )
					continue;

				minX = M.fmin(minX, player.left);
				minY = M.fmin(minY, player.top);
				maxX = M.fmax(maxX, player.right);
				maxY = M.fmax(maxY, player.bottom);
				count++;
			}

		if( count==0 )
			return null;

		return {
			minX:minX,
			minY:minY,
			maxX:maxX,
			maxY:maxY,
		};
	}

	static function updateSurvivorCameraZoom() {
		if( !Game.exists() )
			return;

		var bounds = getSurvivorBounds();
		if( bounds==null )
			return;

		var fitLeft = bounds.minX - CAMERA_FIT_PADDING_X;
		var fitRight = bounds.maxX + CAMERA_FIT_PADDING_X;
		var fitTop = bounds.minY - CAMERA_FIT_PADDING_Y;
		var fitBottom = bounds.maxY + CAMERA_FIT_PADDING_Y;
		var fitWidth = M.fmax(Const.GRID*2, fitRight-fitLeft);
		var fitHeight = M.fmax(Const.GRID*2, fitBottom-fitTop);
		var zoomX = Game.ME.stageWid / Const.SCALE / fitWidth;
		var zoomY = Game.ME.stageHei / Const.SCALE / fitHeight;
		var desiredZoom = M.fmin(CAMERA_DEFAULT_ZOOM, M.fmin(zoomX, zoomY));

		var camera = Game.ME.camera;
		camera.zoomTo(desiredZoom);
	}


	public function new(?spawnX:Float, ?spawnY:Float, trackCamera=true, sizeLevel=0) {
		super(5,5);
		this.sizeLevel = M.iclamp(sizeLevel, 0, SIZE_LEVELS.length-1);
		applySizeLevel();

		if( spawnX!=null && spawnY!=null )
			setPosPixel(spawnX, spawnY);
		else {
			// Start point using level entity "PlayerStart"
			var start = getCurrentLevelStart();
			if( start!=null )
				setPosCase(start.cx, start.cy);
		}

		// Misc inits
		if( trackCamera )
			camera.trackPoint(resolveSurvivorsMidpoint, false);
		camera.clampToLevelBounds = true;

		// Init controller
		ca = App.ME.controller.createAccess();
		ca.lockCondition = Game.isGameControllerLocked;
		ucd.setS("spawnImmunity", SPAWN_IMMUNITY_S);
		immunityShader = new NegativeColorShader();
		spr.addShader(immunityShader);

		initGraphics();
	}

	inline function getSizeData() {
		return SIZE_LEVELS[sizeLevel];
	}

	inline function getCompletionPercentage() {
		return getSizeData().per;
	}

	inline function getHorizontalAcceleration() {
		return getSizeData().hAcc;
	}

	inline function getHorizontalFriction() {
		return getSizeData().hFric;
	}

	inline function getVerticalAcceleration() {
		return getSizeData().vAcc;
	}

	inline function getVerticalFriction() {
		return getSizeData().vFric;
	}

	function applySizeLevel() {
		var size = getSizeData();
		iwid = size.wid;
		ihei = size.hei;
		sprScaleX = wid / BASE_WIDTH;
		sprScaleY = hei / BASE_HEIGHT;
		vBase.setFricts(getHorizontalFriction(), getVerticalFriction());
	}

	override public function hit(dmg:Int, from:Null<Entity>) {
		if( isSpawnImmune() )
			return;

		// Set invulnerability
		ucd.setS("spawnImmunity", SPAWN_IMMUNITY_S);
		bobshot.enemies.BobshotEnemy.addPoints(-50);

		// Push back away from damage source
		var pushDir = from == null ? dir : (centerX < from.centerX ? -1 : 1);
		cancelVelocities();
		bump(pushDir * 0.8, -0.35);
		setSquashX(0.6);

		fx.dotsExplosionExample(centerX, centerY, 0xff0000);
		ca.rumble(0.2, 0.15);
	}

	override function postUpdate() {
		super.postUpdate();
		immunityShader.intensity = isSpawnImmune() ? 1 : 0;
	}

	function initGraphics() {
		animIdle = resolveFirstExisting([
			"idle",
			"player_idle",
			"samplePlayer_idle",
			"sample_player_idle",
			"player"
		]);
		animRun = resolveFirstExisting([
			"run",
			"player_run",
			"samplePlayer_run",
			"sample_player_run"
		]);
		animJump = resolveFirstExisting([
			"jump",
			"player_jump",
			"samplePlayer_jump",
			"sample_player_jump"
		]);
		animFall = resolveFirstExisting([
			"fall",
			"player_fall",
			"samplePlayer_fall",
			"sample_player_fall"
		]);
		animShoot = resolveFirstExisting([
			"shoot",
			"player_shoot"
		]);

		if( animIdle!=null )
			applyAnim(animIdle);
		else
			createFallbackBitmap();
	}

	function createFallbackBitmap() {
		if( fallbackBitmap!=null )
			return;
		fallbackBitmap = new h2d.Bitmap( h2d.Tile.fromColor(0x00ff00, iwid, ihei), spr );
		fallbackBitmap.tile.setCenterRatio(0.5,1);
	}

	inline function getPlayerLib() {
		return flyingMode ? getFlyingSkinLib() : getBaseSkinLib();
	}

	function resolveFirstExisting(candidates:Array<String>) : Null<String> {
		var playerLib = getPlayerLib();
		for( id in candidates )
			if( playerLib.exists(id) )
				return id;
		return null;
	}

	inline function isOnGroundNow() {
		return !destroyed && vBase.dy==0 && hasGroundSupport();
	}

	public inline function isBeingPulled() {
		return pullTarget!=null && !destroyed && isAlive();
	}

	public inline function isBeingPulledInto(target:BobshotRecombobulator) {
		return pullTarget==target && isBeingPulled();
	}

	public inline function getCurrentAnimTag() {
		return currentAnim;
	}

	public function startPullInto(target:BobshotRecombobulator) {
		if( target==null || destroyed || !isAlive() )
			return;

		pullTarget = target;
		cancelVelocities();
		cd.unset("recentlyOnGround");
		ignoredPlatformRow = null;
	}

	public function stopPull() {
		pullTarget = null;
	}

	function applyAnim(group:Null<String>) {
		if( group==null || currentAnim==group )
			return;

		currentAnim = group;
		spr.set(getPlayerLib(), group, 0);

		if( spr.group!=null && spr.group.anim!=null && spr.group.anim.length>0 )
			spr.anim.playAndLoop(group);
		else if( spr.animAllocated )
			spr.anim.stopWithoutStateAnims(group, 0);
	}

	function updateAnimState() {
		var next : Null<String>;

		if( cd.has("shootAnim") && animShoot!=null )
			next = animShoot;
		else if( !isOnGroundNow() )
			next = dyTotal<0 ? (animJump!=null ? animJump : animIdle) : (animFall!=null ? animFall : animIdle);
		else if( M.fabs(dxTotal)>0.03 )
			next = animRun!=null ? animRun : animIdle;
		else
			next = animIdle;

		applyAnim(next);
	}


	override function dispose() {
		super.dispose();
		ca.dispose(); // don't forget to dispose controller accesses
	}


	override function onDie() {
		destroy();
	}

	function resolveEnemyPush(enemy:BobshotEnemy) {
		var overlapLeft = right - enemy.left;
		var overlapRight = enemy.right - left;
		var overlapUp = bottom - enemy.top;
		var overlapDown = enemy.bottom - top;
		var pushX = centerX < enemy.centerX ? -overlapLeft : overlapRight;
		var pushY = centerY < enemy.centerY ? -overlapUp : overlapDown;

		function tryResolve(targetAttachX:Float, targetAttachY:Float) {
			if( !isPlacementFreeAt(targetAttachX, targetAttachY) )
				return false;

			setPosPixel(targetAttachX, targetAttachY);
			return true;
		}

		if( M.fabs(pushX) <= M.fabs(pushY) ) {
			if( !tryResolve(attachX + pushX, attachY) ) {
				if( !tryResolve(attachX, attachY + pushY) ) {
					placeAtNearestSafeSplitPosition(attachX, attachY, pushX<0 ? -1 : 1);
					return;
				}
			}
			vBase.clearX();
			vBump.clearX();
			bump(pushX<0 ? -0.03 : 0.03, 0);
		}
		else {
			if( !tryResolve(attachX, attachY + pushY) ) {
				if( !tryResolve(attachX + pushX, attachY) ) {
					placeAtNearestSafeSplitPosition(attachX, attachY, pushX<0 ? -1 : 1);
					return;
				}
			}
			vBase.clearY();
			vBump.clearY();
			bump(0, pushY<0 ? -0.03 : 0.03);
		}
	}

	function resolvePlayerPush(other:BobshotPlayer) {
		var overlapLeft = right - other.left;
		var overlapRight = other.right - left;
		var overlapUp = bottom - other.top;
		var overlapDown = other.bottom - top;
		var pushX = centerX < other.centerX ? -overlapLeft : overlapRight;
		var pushY = centerY < other.centerY ? -overlapUp : overlapDown;

		function tryResolve(targetAttachX:Float, targetAttachY:Float) {
			if( !isPlacementFreeAt(targetAttachX, targetAttachY) )
				return false;

			setPosPixel(targetAttachX, targetAttachY);
			return true;
		}

		if( M.fabs(pushX) <= M.fabs(pushY) ) {
			if( !tryResolve(attachX + pushX, attachY) ) {
				if( !tryResolve(attachX, attachY + pushY) ) {
					placeAtNearestSafeSplitPosition(attachX, attachY, pushX<0 ? -1 : 1);
					return;
				}
			}
			vBase.clearX();
			vBump.clearX();
		}
		else {
			if( !tryResolve(attachX, attachY + pushY) ) {
				if( !tryResolve(attachX + pushX, attachY) ) {
					placeAtNearestSafeSplitPosition(attachX, attachY, pushX<0 ? -1 : 1);
					return;
				}
			}
			vBase.clearY();
			vBump.clearY();
		}
	}


	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();

		// Right collision
		var rightCollisionX = dxTotal>0 ? getSolidColumnOnRight() : null;
		if( rightCollisionX!=null )
			xr = rightCollisionX / Const.GRID - ( (1-pivotX) * wid ) / Const.GRID - cx;

		// Left collision
		var leftCollisionX = dxTotal<0 ? getSolidColumnOnLeft() : null;
		if( leftCollisionX!=null )
			xr = leftCollisionX / Const.GRID + ( pivotX * wid ) / Const.GRID - cx;
	}


	/** Y collisions **/
	override function onPreStepY() {
		super.onPreStepY();

		// Land on ground
		var groundCollisionY = dyTotal>0 ? getGroundCollisionRow() : null;
		if( groundCollisionY!=null ) {
			setSquashY(0.5);
			vBase.clearY();
			vBump.clearY();
			yr = groundCollisionY / Const.GRID - ( (1-pivotY) * hei ) / Const.GRID - cy;
			ca.rumble(0.2, 0.06);
			onPosManuallyChangedY();
		}

		// Ceiling collision
		var ceilingCollisionY = dyTotal<0 ? getCeilingCollisionRow() : null;
		if( ceilingCollisionY!=null )
			yr = ceilingCollisionY / Const.GRID + ( pivotY * hei ) / Const.GRID - cy;
	}


	/**
		Control inputs are checked at the beginning of the frame.
		VERY IMPORTANT NOTE: because game physics only occur during the `fixedUpdate` (at a constant 30 FPS), no physics increment should ever happen here! What this means is that you can SET a physics value (eg. see the Jump below), but not make any calculation that happens over multiple frames (eg. increment X speed when walking).
	**/
	override function preUpdate() {
		super.preUpdate();

		if( isBeingPulled() ) {
			walkSpeed = 0;
			return;
		}

		walkSpeed = 0;
		if( onGround )
			cd.setS("recentlyOnGround",0.1); // allows "just-in-time" jumps

		var touchDownPressed = ui.TouchControls.isPressed(MoveDown);
		var touchJumpPressed = ui.TouchControls.isPressed(Jump);
		var touchShootPressed = ui.TouchControls.isPressed(Shoot);
		var touchLeftDown = ui.TouchControls.isDown(MoveLeft);
		var touchRightDown = ui.TouchControls.isDown(MoveRight);
		var touchUpDown = ui.TouchControls.isDown(MoveUp);
		var touchDownDown = ui.TouchControls.isDown(MoveDown);
		var touchMoveX = ui.TouchControls.getMoveX();

		if( onGround && (ca.isPressed(MoveDown) || touchDownPressed) ) {
			var platformRow = getGroundPlatformRow();
			if( platformRow!=null ) {
				ignoredPlatformRow = platformRow;
				cd.unset("recentlyOnGround");
				vBase.clearY();
				vBase.addY(0.12);
			}
		}


		// Jump
		if( (cd.has("recentlyOnGround") || flyingMode) && (ca.isPressed(Jump) || touchJumpPressed) ) {
			vBase.addY(-0.85);
			setSquashX(0.6);
			if( !flyingMode )
				cd.unset("recentlyOnGround");
			fx.dotsExplosionExample(centerX, centerY, 0xffcc00);
			ca.rumble(0.05, 0.06);
		}

		if( ca.isKeyboardPressed(K.NUMBER_1) )
			switchSkin(1);
		if( ca.isKeyboardPressed(K.NUMBER_2) )
			switchSkin(2);

		// Shoot
		if( (ca.isPressed(Shoot) || touchShootPressed) && !cd.hasSetS("playerShoot", 0.3) ) {
			var rawAimX = ca.isDown(MoveRight) || touchRightDown ? 1 : ca.isDown(MoveLeft) || touchLeftDown ? -1 : 0;
			var rawAimY = ca.isDown(MoveDown) || touchDownDown ? 1 : ca.isDown(MoveUp) || touchUpDown ? -1 : 0;
			var aimX:Float = rawAimX != 0 || rawAimY == 0 ? (rawAimX != 0 ? rawAimX : dir) : 0;
			var aimY:Float = rawAimY;
			if( rawAimX != 0 && rawAimY != 0 ) {
				aimX = rawAimX * 0.7071;
				aimY = rawAimY * 0.7071;
			}
			new Projectile(centerX + aimX * 10, centerY + aimY * 10 - 2, aimX > 0 ? 1 : -1, "basic", "enemy", aimX, aimY);
			cd.setS("shootAnim", 0.1);
		}

		// Walk
		var analogMoveX = ca.getAnalogDist2(MoveLeft,MoveRight)>0 ? ca.getAnalogValue2(MoveLeft,MoveRight) : 0.0;
		var requestedMoveX = analogMoveX!=0 ? analogMoveX : touchMoveX;
		if( !isChargingAction() && requestedMoveX!=0 ) {
			// As mentioned above, we don't touch physics values (eg. `dx`) here. We just store some "requested walk speed", which will be applied to actual physics in fixedUpdate.
			walkSpeed = requestedMoveX; // -1 to 1
			dir = walkSpeed>0 ? 1 : -1;
		}
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		var triggerExitDoorRestart = false;
		if( ca.isDown(MoveUp) || ui.TouchControls.isDown(MoveUp) )
			triggerExitDoorRestart = !cd.hasSetS("exitDoorRestart", 0.2);

		if( isBeingPulled() ) {
			cancelVelocities();
			updateAnimState();
			return;
		}

		// Gravity
		if( !onGround )
			vBase.addY(getVerticalAcceleration());

		// Apply requested walk movement
		if( walkSpeed!=0 )
			vBase.addX( walkSpeed*getHorizontalAcceleration() );

		// Player body contact
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayer) ) {
				var other = e.as(BobshotPlayer);
				if( !isSolidPlayer(other) )
					continue;

				if( !Lib.rectangleOverlaps(left, top, wid, hei, other.left, other.top, other.wid, other.hei) )
					continue;

				resolvePlayerPush(other);
			}

		if( triggerExitDoorRestart )
			for( e in Entity.ALL )
				if( !e.destroyed && e.is(BobshotExitDoor) ) {
					var exitDoor = e.as(BobshotExitDoor);
					if( !Lib.rectangleOverlaps(left, top, wid, hei, exitDoor.left, exitDoor.top, exitDoor.wid, exitDoor.hei) )
						continue;

					game.restartCurrentLevel();
					return;
				}

		// Start next level when touching a PlayerExit entity
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotPlayerExit) ) {
				var exit = e.as(BobshotPlayerExit);
				if( !Lib.rectangleOverlaps(left, top, wid, hei, exit.left, exit.top, exit.wid, exit.hei) )
					continue;

				if( !cd.hasSetS("levelExit", 0.2) ) {
					clearFlyingMode();
					destroy();
					app.delayer.nextFrame( ()->game.startNextLevelWrap() );
				}
				return;
			}

		// Feed Recombobulators when touched
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotRecombobulator) ) {
				var recombobulator = e.as(BobshotRecombobulator);
				if( !Lib.rectangleOverlaps(left, top, wid, hei, recombobulator.left, recombobulator.top, recombobulator.wid, recombobulator.hei) )
					continue;
				if( recombobulator.isDeactivated() )
					continue;

				recombobulator.absorbPercentage(getCompletionPercentage());
				destroy();
				return;
			}

		// Collect flying potion
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(bobshot.FlyingPotion) ) {
				var potion = e.as(bobshot.FlyingPotion);
				if( !Lib.rectangleOverlaps(left, top, wid, hei, potion.left, potion.top, potion.wid, potion.hei) )
					continue;

				enableFlyingMode();
				potion.destroy();
			}

		// Enemy body contact
		for( e in Entity.ALL )
			if( !e.destroyed && e.is(BobshotEnemy) ) {
				var enemy = e.as(BobshotEnemy);
				if( !Lib.rectangleOverlaps(left, top, wid, hei, enemy.left, enemy.top, enemy.wid, enemy.hei) )
					continue;

				if( isSpawnImmune() || enemy.isHarmless() )
					resolveEnemyPush(enemy);
				else {
					kill(enemy);
					break;
				}
			}

		updateSurvivorCameraZoom();

		updateAnimState();
	}
}

