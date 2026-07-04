class Level extends GameChildProcess {
	/** Level grid-based width**/
	public var cWid(default,null): Int;
	/** Level grid-based height **/
	public var cHei(default,null): Int;

	/** Level pixel width**/
	public var pxWid(default,null) : Int;
	/** Level pixel height**/
	public var pxHei(default,null) : Int;

	public var data : World_Level;
	public var totalCompletedPercentage(default,null) = 0.0;
	public var requiredPercentage(default,null) = 100.0;
	var tilesetSource : h2d.Tile;
	var overlayRoot : h2d.Object;
	var nextLevelQueued = false;
	static inline var COLLISION_INTGRID_WALL = 1;
	static inline var COLLISION_INTGRID_PLATFORM = 2;

	public var marks : dn.MarkerMap<LevelMark>;
	var invalidated = true;

	public function new(ldtkLevel:World.World_Level) {
		super();

		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		data = ldtkLevel;
		cWid = data.l_Collisions.cWid;
		cHei = data.l_Collisions.cHei;
		pxWid = cWid * Const.GRID;
		pxHei = cHei * Const.GRID;
		requiredPercentage = readRequiredPercentage();
		tilesetSource = hxd.Res.levels.mitosisWorldTiles.toAseprite().toTile();
		overlayRoot = new h2d.Object();
		Game.ME.scroller.add(overlayRoot, Const.DP_FRONT);

		marks = new dn.MarkerMap(cWid, cHei);
		for(cy in 0...cHei)
		for(cx in 0...cWid) {
			var collisionValue = data.l_Collisions.getInt(cx,cy);
			if( collisionValue==COLLISION_INTGRID_WALL )
				marks.set(M_Coll_Wall, cx,cy);
			else if( collisionValue==COLLISION_INTGRID_PLATFORM )
				marks.set(M_Coll_Platform, cx,cy);
		}

		addInvisibleWallCollisions();
	}

	override function onDispose() {
		super.onDispose();
		data = null;
		tilesetSource = null;
		overlayRoot.removeChildren();
		overlayRoot.remove();
		overlayRoot = null;
		marks.dispose();
		marks = null;
	}

	/** TRUE if given coords are in level bounds **/
	public inline function isValid(cx,cy) return cx>=0 && cx<cWid && cy>=0 && cy<cHei;

	/** Gets the integer ID of a given level grid coord **/
	public inline function coordId(cx,cy) return cx + cy*cWid;

	/** Ask for a level render that will only happen at the end of the current frame. **/
	public inline function invalidate() {
		invalidated = true;
	}

	/** Return TRUE if "Collisions" layer contains a collision value **/
	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : hasWallCollision(cx,cy) || hasPlatformCollision(cx,cy);
	}

	public inline function hasWallCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : marks.has(M_Coll_Wall, cx,cy);
	}

	public inline function hasPlatformCollision(cx,cy) : Bool {
		return isValid(cx,cy) && marks.has(M_Coll_Platform, cx,cy);
	}

	public inline function hasReachedRequiredPercentage() {
		return totalCompletedPercentage >= requiredPercentage;
	}

	public function registerCompletedPercentage(value:Float) {
		totalCompletedPercentage += value;
		game.hud.invalidate();

		if( !nextLevelQueued && hasReachedRequiredPercentage() ) {
			nextLevelQueued = true;
			return true;
		}

		return false;
	}

	function readRequiredPercentage() {
		var rawValue:Dynamic = Reflect.field(data, "f_RequiredPercentage");
		if( rawValue==null )
			return 100.0;

		var value = Std.parseFloat(Std.string(rawValue));
		return Math.isNaN(value) ? 100.0 : value;
	}

	function addInvisibleWallCollisions() {
		var invisibleWalls:Array<Dynamic> = cast Reflect.field(data.l_Entities, "all_InvisibleWall");
		if( invisibleWalls==null )
			return;

		for( wall in invisibleWalls ) {
			var grid = getEntityGrid(wall);
			var wallCx = grid.cx;
			var wallCy = grid.cy;
			var wallCWid = M.imax(1, M.ceil(getEntitySize(wall, "width") / Const.GRID));
			var wallCHei = M.imax(1, M.ceil(getEntitySize(wall, "height") / Const.GRID));

			for( cy in wallCy...wallCy + wallCHei )
				for( cx in wallCx...wallCx + wallCWid )
					if( isValid(cx,cy) )
						marks.set(M_Coll_Wall, cx,cy);
		}
	}

	function getEntityGrid(entity:Dynamic) {
		var cx = readEntityInt(entity, "cx", null);
		var cy = readEntityInt(entity, "cy", null);
		if( cx!=null && cy!=null )
			return { cx:cx, cy:cy };

		var grid:Array<Int> = cast Reflect.field(entity, "__grid");
		return {
			cx: grid!=null && grid.length>0 ? grid[0] : 0,
			cy: grid!=null && grid.length>1 ? grid[1] : 0,
		};
	}

	function getEntitySize(entity:Dynamic, field:String) : Int {
		return readEntityInt(entity, field, Const.GRID);
	}

	function readEntityInt(entity:Dynamic, field:String, defaultValue:Null<Int>) : Null<Int> {
		var value = Reflect.field(entity, field);
		return value==null ? defaultValue : Std.int(value);
	}

	/** Render current level**/
	function render() {
		root.removeChildren();
		overlayRoot.removeChildren();

		var collisionTiles = new h2d.TileGroup(tilesetSource, root);
		data.l_Collisions.render(collisionTiles);

		var decorationTiles = new h2d.TileGroup(tilesetSource, root);
		data.l_DecorationTiles.render(decorationTiles);

		var overlayTiles = new h2d.TileGroup(tilesetSource, overlayRoot);
		data.l_OverlayTiles.render(overlayTiles);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}