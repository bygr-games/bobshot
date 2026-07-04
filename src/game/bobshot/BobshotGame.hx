package bobshot;

import bobshot.enemies.BobshotEnemy;

/**
	This small class creates game entities (player and enemies) from level data
**/
class BobshotGame extends Game {
	public function new() {
		super();
	}

	function readPivot(spawn:Dynamic, defaultX:Float=0.5, defaultY:Float=1.0) {
		var pivotX = defaultX;
		var pivotY = defaultY;
		var rawPivot:Dynamic = Reflect.field(spawn, "__pivot");
		if( rawPivot!=null ) {
			var pivotArray:Array<Dynamic> = cast rawPivot;
			if( pivotArray.length>0 && pivotArray[0]!=null )
				pivotX = cast pivotArray[0];
			if( pivotArray.length>1 && pivotArray[1]!=null )
				pivotY = cast pivotArray[1];
		}
		else {
			var rawPivotX:Dynamic = Reflect.field(spawn, "pivotX");
			var rawPivotY:Dynamic = Reflect.field(spawn, "pivotY");
			if( rawPivotX!=null )
				pivotX = cast rawPivotX;
			if( rawPivotY!=null )
				pivotY = cast rawPivotY;
		}

		return { x:pivotX, y:pivotY };
	}

	override function startLevel(l:World_Level) {
		super.startLevel(l);

		if( level.data.l_Entities.all_PlayerExit != null ) {
			for( exitSpawn in level.data.l_Entities.all_PlayerExit )
					{
						var pivot = readPivot(exitSpawn, 0.5, 1.0);
						var rawVisible:Dynamic = Reflect.field(exitSpawn, "f_visible");
						var visible = rawVisible == null || rawVisible == true;
						new BobshotPlayerExit(exitSpawn.cx, exitSpawn.cy, visible, pivot.x, pivot.y);
					}
		}

		var recombobulatorSpawns:Array<Dynamic> = cast Reflect.field(level.data.l_Entities, "all_Recombobulator");
		if( recombobulatorSpawns != null ) {
			for( recombobulatorSpawn in recombobulatorSpawns ) {
				var cx:Int = cast Reflect.field(recombobulatorSpawn, "cx");
				var cy:Int = cast Reflect.field(recombobulatorSpawn, "cy");
				var pivot = readPivot(recombobulatorSpawn, 0.5, 1.0);
				var rawRequired:Dynamic = Reflect.field(recombobulatorSpawn, "f_RequiredPercentage");
				if( rawRequired==null )
					rawRequired = Reflect.field(recombobulatorSpawn, "RequiredPercentage");
				var requiredPercentage = rawRequired==null ? 0.0 : cast rawRequired;
				new BobshotRecombobulator(cx, cy, requiredPercentage, pivot.x, pivot.y);
			}
		}
		
		// Spawn player
		new BobshotPlayer();

		// Spawn saw enemies
		if( level.data.l_Entities.all_SawEnemy != null ) {
			for( sawSpawn in level.data.l_Entities.all_SawEnemy )
				{
					var pivot = readPivot(sawSpawn, 0.5, 1.0);
					new BobshotEnemy(sawSpawn.cx, sawSpawn.cy, "saw", pivot.x, pivot.y);
				}
		}

		// Spawn red enemies
		if( level.data.l_Entities.all_RedEnemy != null ) {
			for( redSpawn in level.data.l_Entities.all_RedEnemy )
				{
					var pivot = readPivot(redSpawn, 0.5, 1.0);
					new BobshotEnemy(redSpawn.cx, redSpawn.cy, "red", pivot.x, pivot.y);
				}
		}

		// Spawn shooting enemies
		if( level.data.l_Entities.all_ShootingEnemy != null ) {
			for( shootingSpawn in level.data.l_Entities.all_ShootingEnemy )
				{
					var pivot = readPivot(shootingSpawn, 0.5, 1.0);
					new BobshotEnemy(shootingSpawn.cx, shootingSpawn.cy, "shooting", pivot.x, pivot.y);
				}
		}

		// Spawn scared enemies
		if( level.data.l_Entities.all_ScaredEnemy != null ) {
			for( scaredSpawn in level.data.l_Entities.all_ScaredEnemy )
				{
					var pivot = readPivot(scaredSpawn, 0.5, 1.0);
					new BobshotEnemy(scaredSpawn.cx, scaredSpawn.cy, "scared", pivot.x, pivot.y);
				}
		}

		// Spawn spike enemies
		if( level.data.l_Entities.all_SpikeEnemy != null ) {
			for( spikeSpawn in level.data.l_Entities.all_SpikeEnemy )
				{
					var pivot = readPivot(spikeSpawn, 0.5, 1.0);
					new BobshotEnemy(spikeSpawn.cx, spikeSpawn.cy, "spike", pivot.x, pivot.y);
				}
		}

		// Spawn falling objects
		var fallingObjectSpawns:Array<Dynamic> = cast Reflect.field(level.data.l_Entities, "all_FallingObject");
		if( fallingObjectSpawns != null ) {
			for( fallingObjectSpawn in fallingObjectSpawns ) {
				var cx:Int = cast Reflect.field(fallingObjectSpawn, "cx");
				var cy:Int = cast Reflect.field(fallingObjectSpawn, "cy");
				var rawType:Dynamic = Reflect.field(fallingObjectSpawn, "f_type");
				if( rawType==null )
					rawType = Reflect.field(fallingObjectSpawn, "type");
				var sliceType = rawType==null ? "falling_object" : cast rawType;
				var pivot = readPivot(fallingObjectSpawn, 0.5, 0.0);
				new FallingObject(cx, cy, sliceType, pivot.x, pivot.y);
			}
		}
	}
}



