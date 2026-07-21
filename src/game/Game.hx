class Game extends AppChildProcess {
	public static var ME : Game;

	/** Game controller (pad or keyboard) **/
	public var ca : ControllerAccess<GameAction>;

	/** Particles **/
	public var fx : Fx;

	/** Basic viewport control **/
	public var camera : Camera;

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller : h2d.Layers;

	/** Level data **/
	public var level : Level;

	/** UI **/
	public var hud : ui.Hud;

	/** Slow mo internal values**/
	var curGameSpeed = 1.0;
	var slowMos : Map<SlowMoId, { id:SlowMoId, t:Float, f:Float }> = new Map();


	public function new() {
		super();

		ME = this;
		ca = App.ME.controller.createAccess();
		ca.lockCondition = isGameControllerLocked;
		createRootInLayers(App.ME.root, Const.DP_BG);
		dn.Gc.runNow();

		scroller = new h2d.Layers();
		root.add(scroller, Const.DP_BG);
		scroller.filter = new h2d.filter.Nothing(); // force rendering for pixel perfect

		fx = new Fx();
		hud = new ui.Hud();
		camera = new Camera();

		var orderedLevels = getOrderedWorldLevels();
		if( orderedLevels.length>0 )
			startLevel(orderedLevels[0]);
		else
			startLevel(Assets.worldData.all_worlds.BobshotWorld.all_levels.Level_0);
	}


	public static function isGameControllerLocked() {
		return !exists() || ME.isPaused() || App.ME.anyInputHasFocus();
	}


	public static inline function exists() {
		return ME!=null && !ME.destroyed;
	}


	/** Load a level **/
	function startLevel(l:World.World_Level) {
		if( level!=null )
			level.destroy();
		fx.clear();
		for(e in Entity.ALL) // <---- Replace this with more adapted entity destruction (eg. keep the player alive)
			e.destroy();
		garbageCollectEntities();

		level = new Level(l);
		// <---- Here: instanciate your level entities

		camera.centerOnTarget();
		hud.onLevelStart();
		dn.Process.resizeAll();
		dn.Gc.runNow();
	}

	function getRawProjectWorlds() {
		var ldtkRes = hxd.Res.load(Assets.worldData.projectFilePath.substr(4));
		var rawProject:Dynamic = haxe.Json.parse(ldtkRes.entry.getText());
		var worlds:Array<Dynamic> = cast Reflect.field(rawProject, "worlds");
		return worlds==null ? [] : worlds;
	}

	function getWorldRef(worldIdentifier:String) {
		return Reflect.field(Assets.worldData.all_worlds, worldIdentifier);
	}

	function getWorldIdentifierByLevelUid(levelUid:Int) {
		for( world in getRawProjectWorlds() ) {
			var levels:Array<Dynamic> = cast Reflect.field(world, "levels");
			if( levels==null )
				continue;
			for( rawLevel in levels ) {
				var rawUid:Dynamic = Reflect.field(rawLevel, "uid");
				if( rawUid!=null && cast rawUid==levelUid )
					return cast Reflect.field(world, "identifier");
			}
		}
		return null;
	}

	function getLevelFromWorldByUid(worldRef:Dynamic, levelUid:Int) : Null<World.World_Level> {
		if( worldRef==null )
			return null;

		var allLevels:Dynamic = Reflect.field(worldRef, "all_levels");
		if( allLevels==null )
			return null;

		for( levelId in Reflect.fields(allLevels) ) {
			var l:World.World_Level = cast Reflect.field(allLevels, levelId);
			if( l!=null && l.uid==levelUid )
				return l;
		}

		return null;
	}

	function getOrderedWorldLevels(?worldIdentifier="BobshotWorld") : Array<World.World_Level> {
		var orderedLevels : Array<World.World_Level> = [];
		var worldRef:Dynamic = getWorldRef(worldIdentifier);
		if( worldRef==null )
			return orderedLevels;

		for( world in getRawProjectWorlds() ) {
			if( Reflect.field(world, "identifier")!=worldIdentifier )
				continue;
			var levels:Array<Dynamic> = cast Reflect.field(world, "levels");
			if( levels==null )
				break;
			for( rawLevel in levels ) {
				var rawUid:Dynamic = Reflect.field(rawLevel, "uid");
				if( rawUid==null )
					continue;
				var l = getLevelFromWorldByUid(worldRef, cast rawUid);
				if( l!=null )
					orderedLevels.push(l);
			}
			break;
		}
		if( orderedLevels.length>0 )
			return orderedLevels;

		var allLevels:Dynamic = Reflect.field(worldRef, "all_levels");
		for( levelId in Reflect.fields(allLevels) ) {
			var l:World.World_Level = cast Reflect.field(allLevels, levelId);
			if( l!=null )
				orderedLevels.push(l);
		}
		orderedLevels.sort( (a,b)->a.uid-b.uid );
		return orderedLevels;
	}

	public function startNextLevelWrap() {
		if( level==null )
			return;

		var worldIdentifier = getWorldIdentifierByLevelUid(level.data.uid);
		var orderedLevels = getOrderedWorldLevels(worldIdentifier==null ? "BobshotWorld" : worldIdentifier);
		if( orderedLevels.length==0 )
			return;

		var curIdx = -1;
		for( i in 0...orderedLevels.length )
			if( orderedLevels[i].uid==level.data.uid ) {
				curIdx = i;
				break;
			}

		var nextIdx = (curIdx+1) % orderedLevels.length;
		startLevel(orderedLevels[nextIdx]);
	}

	public function restartCurrentLevel() {
		if( level==null )
			return;

		var worldIdentifier = getWorldIdentifierByLevelUid(level.data.uid);
		var worldRef:Dynamic = getWorldRef(worldIdentifier==null ? "BobshotWorld" : worldIdentifier);
		if( worldRef==null )
			return;
		var levelData = getLevelFromWorldByUid(worldRef, level.data.uid);
		if( levelData!=null )
			startLevel(levelData);
	}

	public function startLobbyWorld() {
		var orderedLevels = getOrderedWorldLevels("LobbyWorld");
		if( orderedLevels.length==0 )
			return;
		startLevel(orderedLevels[0]);
	}



	/** Called when either CastleDB or `const.json` changes on disk **/
	@:allow(App)
	function onDbReload() {
		hud.notify("DB reloaded");
	}


	/** Called when LDtk file changes on disk **/
	@:allow(assets.Assets)
	function onLdtkReload() {
		hud.notify("LDtk reloaded");
		if( level!=null ) {
			var worldIdentifier = getWorldIdentifierByLevelUid(level.data.uid);
			var worldRef:Dynamic = getWorldRef(worldIdentifier==null ? "BobshotWorld" : worldIdentifier);
			var levelData = getLevelFromWorldByUid(worldRef, level.data.uid);
			if( levelData!=null )
				startLevel(levelData);
		}
	}

	/** Window/app resize event **/
	override function onResize() {
		super.onResize();
	}


	/** Garbage collect any Entity marked for destruction. This is normally done at the end of the frame, but you can call it manually if you want to make sure marked entities are disposed right away, and removed from lists. **/
	public function garbageCollectEntities() {
		if( Entity.GC==null || Entity.GC.allocated==0 )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC.empty();
	}

	/** Called if game is destroyed, but only at the end of the frame **/
	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		garbageCollectEntities();

		if( ME==this )
			ME = null;
	}


	/**
		Start a cumulative slow-motion effect that will affect `tmod` value in this Process
		and all its children.

		@param sec Realtime second duration of this slowmo
		@param speedFactor Cumulative multiplier to the Process `tmod`
	**/
	public function addSlowMo(id:SlowMoId, sec:Float, speedFactor=0.3) {
		if( slowMos.exists(id) ) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		}
		else
			slowMos.set(id, { id:id, t:sec, f:speedFactor });
	}


	/** The loop that updates slow-mos **/
	final function updateSlowMos() {
		// Timeout active slow-mos
		for(s in slowMos) {
			s.t -= utmod * 1/Const.FPS;
			if( s.t<=0 )
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for(s in slowMos)
			targetGameSpeed*=s.f;
		curGameSpeed += (targetGameSpeed-curGameSpeed) * (targetGameSpeed>curGameSpeed ? 0.2 : 0.6);

		if( M.fabs(curGameSpeed-targetGameSpeed)<=0.001 )
			curGameSpeed = targetGameSpeed;
	}


	/**
		Pause briefly the game for 1 frame: very useful for impactful moments,
		like when hitting an opponent in Street Fighter ;)
	**/
	public inline function stopFrame() {
		ucd.setS("stopFrame", 4/Const.FPS);
	}


	/** Loop that happens at the beginning of the frame **/
	override function preUpdate() {
		super.preUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
	}

	/** Loop that happens at the end of the frame **/
	override function postUpdate() {
		super.postUpdate();

		// Update slow-motions
		updateSlowMos();
		baseTimeMul = ( 0.2 + 0.8*curGameSpeed ) * ( ucd.has("stopFrame") ? 0.1 : 1 );
		Assets.tiles.tmod = tmod;

		// Entities post-updates
		for(e in Entity.ALL) if( !e.destroyed ) e.postUpdate();

		// Entities final updates
		for(e in Entity.ALL) if( !e.destroyed ) e.finalUpdate();

		// Dispose entities marked as "destroyed"
		garbageCollectEntities();
	}


	/** Main loop but limited to 30 fps (so it might not be called during some frames) **/
	override function fixedUpdate() {
		super.fixedUpdate();

		// Entities "30 fps" loop
		for(e in Entity.ALL) if( !e.destroyed ) e.fixedUpdate();
	}

	/** Main loop **/
	override function update() {
		super.update();

		// Entities main loop
		for(e in Entity.ALL) if( !e.destroyed ) e.frameUpdate();


		// Global key shortcuts
		if( !App.ME.anyInputHasFocus() && !ui.Window.hasAnyModal() && !Console.ME.isActive() ) {
			// Exit by pressing ESC twice
			#if hl
			if( ca.isKeyboardPressed(K.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					hud.notify(Lang.t._("Press ESCAPE again to exit."));
				else
					App.ME.exit();
			#end

			// Attach debug drone (CTRL-SHIFT-D)
			#if debug
			if( ca.isPressed(ToggleDebugDrone) )
				new DebugDrone(); // <-- HERE: provide an Entity as argument to attach Drone near it
			#end

			// Restart current level
			if( ca.isPressed(Restart) )
				restartCurrentLevel();

		}
	}
}

