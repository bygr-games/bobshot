# Bobshot C (Bobshot Game) — Agent Guide

## Project Overview

2D platformer/puzzle game built in **Haxe 4.3.7** using the **Heaps** framework with **deepnightLibs**. The player controls a cell that splits/shrinks on death (mitosis mechanic), traversing LDtk-designed levels, defeating enemies, collecting percentage completion to reach the exit.

## Essential Commands

```bash
# Build & run (HashLink + OpenGL)
haxe build.opengl.hxml && hl bin/client.hl

# Build & run (HashLink + DirectX on Windows)
haxe build.directx.hxml && hl bin/client.hl

# Build with debug flags
haxe build.dev.hxml && hl bin/client.hl

# Build for web (JS)
haxe build.js.hxml

# Initial setup (install all haxelib dependencies)
haxe setup.hxml

# Language PO file parser tool
haxe tools.langParser.hxml

# Run HashLink binary
hl bin/client.hl
```

Build configs are in `.hxml` files at project root. See `_base.hxml` for shared flags, `build.dev.hxml` adds `-debug`. Output goes to `bin/client.hl` (HashLink) or `bin/client.js` (JS).

## Code Organization

```
src/
  game/                     # Main game source (-cp src/game)
    Boot.hx                 # Entry point (extends hxd.App)
    App.hx                  # Top-level Process, asset/controller init
    Game.hx                 # Main game loop (extends AppChildProcess)
    Const.hx                # Constants: GRID=16, FPS, layers (DP_BG, DP_MAIN, etc.)
    Types.hx                # Abstracts: GameAction, State, Affect, LevelMark, etc.
    Entity.hx               # Base entity class (grid-based, velocity system)
    Level.hx                # LDtk level renderer, collision markers
    Camera.hx               # Viewport, entity tracking, zoom
    Fx.hx                   # Particle system (HParticle-based)
    import.hx               # Global aliases: L=Lang.t, D=AssetsDictionaries, A=Assets, etc.
    mitosis/                # Game-specific code
      MitosisGame.hx        # Spawns entities from LDtk level data
      MitosisPlayer.hx      # Player: keyboard/gamepad, splits on death (shrinks)
      MitosisPlayerExit.hx  # Exit door (animated completion percentage display)
      MitosisRecombobulator.hx # Collectible that spawns new player copies
      FallingObject.hx      # Trap that falls when hit by projectile
      enemies/              # Strategy pattern
        MitosisEnemy.hx     # Enemy base with type-based strategy dispatch
        EnemyStrategy.hx    # Interface
        BaseEnemyStrategy.hx # Shared gravity/ground support helpers
        SawEnemyStrategy.hx # Patrols back and forth, turns on walls/cliffs
        RedEnemyStrategy.hx # Stays in place, jumps periodically
        ShootingEnemyStrategy.hx # Shoots violet projectiles at player
        ScaredEnemyStrategy.hx # Flees from nearby players, climbs steps
        SpikeEnemyStrategy.hx # Stationary hazard that splits players on contact
      projectiles/          # Strategy pattern
        Projectile.hx       # Base projectile (can target player or enemies)
        ProjectileStrategy.hx # Interface
        BaseProjectileStrategy.hx # Shared movement/collision/impact effects
        BasicProjectileStrategy.hx
        VioletProjectileStrategy.hx
    assets/
      Assets.hx             # SpriteLib loading from Aseprite files
      AssetsDictionaries.hx # Slice name dictionaries from Aseprite
      Lang.hx               # i18n via PO files (GetText)
      CastleDb.hx           # CastleDB macro typedef
      ConstDbBuilder.hx     # Macro: builds Const.db from const.json + data.cdb
      World.hx              # LDtk world data typing
    ui/
      Hud.hx                # HUD screen (completion text, debug text, notifications)
      Console.hx            # Debug console (toggle with [²] key)
      UiComponent.hx        # Base h2d.Flow component
      UiGroupController.hx  # Focusable UI navigation
      Window.hx             # Modal window system
      Bar.hx, IconBar.hx    # Health/status bars
      component/            # Button, CheckBox, Text, ControlsHelp
      win/                  # SimpleMenu, DebugWindow
    en/
      DebugDrone.hx         # Debug flycam (CTRL+SHIFT+D)
    tools/
      AppChildProcess.hx    # Process attached to App.ME
      GameChildProcess.hx   # Process attached to Game.ME
      LPoint.hx, LRect.hx   # 2D math helpers
      ChargedAction.hx      # Timed action system
      script/               # Scripting API (hscript integration)
res/
  const.json                # JSON constants (hot-reloadable in debug)
  data.cdb                  # CastleDB data (hot-reloadable in debug)
  atlas/                    # Aseprite files: player, enemy_*, tiles, etc.
  levels/                   # LDtk level files, back/over layers
  fonts/                    # Bitmap fonts (pixel_unicode, pixica_mono)
  lang/                     # PO files (en.po, sourceTexts.pot)
```

## Application Architecture & Control Flow

**Process hierarchy** (from deepnightLibs `dn.Process`):
```
Boot (hxd.App)
  └── App (dn.Process)           — root process, assets, controller
       ├── Console (h2d.Console)  — debug overlay
       ├── FocusHelper            — click-to-continue screen
       └── Game (AppChildProcess) — main game
            ├── Fx (GameChildProcess) — particles
            ├── Camera (GameChildProcess) — viewport
            ├── Level (GameChildProcess) — LDtk rendering + collisions
            ├── Hud (GameChildProcess) — overlay UI
            └── Entity instances — game objects in FixedArray
                 ├── MitosisPlayer
                 ├── MitosisEnemy (strategy pattern)
                 ├── MitosisPlayerExit
                 ├── MitosisRecombobulator
                 ├── FallingObject
                 └── Projectile (strategy pattern)
```

**Frame loop**: `Boot.update()` → `dn.Process.updateAll(tmod)` → each process's update chain.

**Fixed update loop**: `dn.Process.FIXED_UPDATE_FPS = 30`. Gameplay physics runs here. Sprite positions are interpolated between fixed updates for smooth 60+ FPS rendering.

**Game flow**: Boot → App.initAssets() → App.initController() → App.startGame() → MitosisGame.new() → Game.startLevel() → MitosisGame.startLevel() creates entities from LDtk data.

## Key Patterns & Conventions

### Entity System
- All entities live in `Entity.ALL` (FixedArray, max 1024)
- Mark for removal: `e.destroy()`, then call `Game.ME.garbageCollectEntities()`
- Grid position: `cx`, `cy` (integer coords), `xr`, `yr` (0.0–1.0 sub-grid offset)
- Pixel position helpers: `attachX`, `attachY`, `left`, `right`, `top`, `bottom`, `centerX`, `centerY`
- Velocity: `vBase` (base movement), `vBump` (external forces), accessed via `dxTotal`/`dyTotal`
- Pivots: `pivotX` (0–1), `pivotY` (0–1) — defines where the entity attaches to its grid position. Default: (0.5, 1.0) — center X, bottom Y
- Sprite interpolation: `interpolateSprPos = true` — sprite renders at interpolated position between fixed updates
- Direction: `dir` is always `-1` (left) or `1` (right)
- Cooldowns: `cd` (affected by slow-mo), `ucd` (real-time always)
- Affects: time-limited status effects via `affects` map
- Killing: `entity.kill(sourceEntity)` — sets `lastDmgSource`, plays hit effects

### Strategy Pattern
Used for both enemies and projectiles. Enemies: `EnemyStrategy` interface with `initHitbox()`, `update()`, `onXCollision()`, `dispose()`. Base class `BaseEnemyStrategy` provides gravity/ground helpers. Projectiles: `ProjectileStrategy` with `update()`, `initGraphics()`, `onXCollision()`, `onPlayerHit()`, etc.

### Velocity & Physics
- `vBase.addX(val)` / `vBase.addY(val)` — apply acceleration
- `vBase.setFricts(hFric, vFric)` — set horizontal/vertical friction (applied per fixed update)
- `vBump` — external knockback, decays independently
- All physics runs in `fixedUpdate()` (30 FPS). Use `tmod`-multiplied values for time-dependent logic

### Asset Loading
- Aseprite files in `res/atlas/` loaded via `dn.heaps.assets.Aseprite.convertToSLib(FPS, asepriteTile)` in `Assets.hx`
- Frame/animation tags from Aseprite are available as animation names
- Slice names from Aseprite accessible via `AssetsDictionaries` (aliased as `D`)
- Hot-reload: CastleDB, const.json, and LDtk file all auto-watch and reload in debug mode

### Level Design (LDtk)
- Level data lives in `res/levels/mitosisWorld.ldtk`
- Collision layer: int-grid with value 1 (wall) and 2 (platform)
- Entity layer: read by `MitosisGame.startLevel()` — entity-specific arrays like `all_PlayerExit`, `all_SawEnemy`, `all_Recombobulator`, etc.
- Custom level field: `f_RequiredPercentage` (Float, default 100.0)
- `Level.totalCompletedPercentage` tracks how much the player has collected
- When percentages reach level's required, door opens and recombobulators pull players in

### Constants & Config
- `Const.GRID = 16` — base grid unit
- `Const.db` — hot-reloadable constants from `res/const.json` + `res/data.cdb` (CastleDB), built via macro
- Depth layers: `Const.DP_BG`, `DP_FX_BG`, `DP_MAIN`, `DP_FRONT`, `DP_FX_FRONT`, `DP_TOP`, `DP_UI`
- Scaling: `Const.SCALE` (game), `Const.UI_SCALE` (UI) — auto-computed with bestFit

### Controller / Input
- `GameAction` abstract enum in `Types.hx`
- `App.controller` creates `ControllerAccess<GameAction>` instances
- Keyboard/gamepad bindings in `App.initControllerBindings()`
- `ca.isPressed(action)` — single press, `ca.isDown(action)` — held
- Important: `ca.lockCondition` should return true when input should be ignored (console active, modal open, game paused)

### Localization
- PO files in `res/lang/` (GetText format)
- Access via `L("string_id")` (the `L` alias from `import.hx` — `assets.Lang.t`)
- `Lang.init("en")` in App startup, auto-detects system language
- `L.untranslated(str)` for dynamic strings not in PO files

## Gotchas & Non-Obvious Patterns

- **Global aliases** in `import.hx`: `L = Lang.t`, `D = AssetsDictionaries`, `A = Assets`, `P = LPoint`, `K = hxd.Key`, `DB = Const.db`, `MM = dn.debug.MemTrack.measure`, `R = dn.RandomTools`. These are available everywhere without explicit import.
- **`cd.hasSetS(key, seconds)`** is a common pattern — sets a cooldown AND returns false if already set. Used like `if( !enemy.cd.hasSetS("jumpCd", 0.8) )`.
- **Process hierarchy matters**: `AppChildProcess` extends `dn.Process` with `App.ME` as parent. `GameChildProcess` uses `Game.ME` as parent. Processes not properly parented won't receive updates.
- **`tmod` vs `utmod`** — `tmod` is the time multiplier (affected by slow-mo, pause). `utmod` is real-time. Always use `tmod` for gameplay timings.
- **Sprite interpolation** means entity `spr.x`/`spr.y` are calculated between fixed updates. For accurate pixel positions in collision logic, use `attachX`/`attachY` (not sprite position directly).
- **Player split**: on death, `MitosisPlayer` is not destroyed but **shrinks** to the next size level. New player instances spawn from `MitosisRecombobulator`. This is the core "mitosis" mechanic.
- **Collision epsilon**: `COLLISION_EPSILON = 0.001` used everywhere to prevent floating-point edge overlap issues.
- **`isAlive()` vs `!destroyed`**: Check `isAlive()` on Entity — it may be alive even if `destroyed=false` (e.g., player can be "dead" but entity still exists during split animation). Check the actual `life` stat.
- **Debug drone**: Toggle with CTRL+SHIFT+D. Arrow keys to fly. Controls camera directly.
- **Console flags**: Open with `²` (tilde) key, then `/flags` command for togglable debug overlays (camera bounds, hitboxes, etc.)
- **FixedArray** instead of standard Haxe arrays. Must push entities manually: `ALL.push(this)` in constructor. GC works by marking+collecting at frame end.
- **`hasPrevFrame`**: Entity tracks `prevFrameAttachX`/`prevFrameAttachY`. Check `hasPrevFrame()` to know if the entity has existed for at least one full frame.
- **JSON const hot-reload**: `Const.db.myValue` updates live when `const.json` changes on disk — but **only in debug builds**.
- **No explicit unit test framework** is present. Testing is manual/in-game.
- **Entity constructor** accepts `(cx, cy, ?pivotX, ?pivotY)`. Empty constructor `new()` places at (0,0).
- **Enemy hazard flag**: `enemyDef.hazard` — hazard enemies (like saw) kill player on contact even when the player is on top. Non-hazard enemies can be stomped.
- **Scared enemy** is the only enemy that can climb one-tile steps — uses `tryClimbStep()` in `ScaredEnemyStrategy`.

## Data Flow: New Enemy Type

To add a new enemy type:
1. Add entity in LDtk (All_SomethingEnemy)
2. Create strategy class implementing `EnemyStrategy` in `mitosis/enemies/`
3. Register in `MitosisEnemy.initEnemyDefs()` with sprite lib, hitbox, and flags
4. Add spawn loop in `MitosisGame.startLevel()` reading from `level.data.l_Entities.all_SomethingEnemy`
5. Add to `Assets.hx` sprite lib loading + `Assets.update()`
