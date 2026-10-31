# GRAVITY BREAKER

**Version:** 0.15.0-alpha (v15 — Fullscreen-first camera polish)  
**Engine:** Godot 4.7.x, GL Compatibility renderer  
**Targets:** Windows 64-bit and Linux 64-bit

GRAVITY BREAKER is a futuristic four-surface action runner. Run through five themed sectors, switch gravity between the floor, walls and ceiling, manage boost stamina, avoid machinery and enemy fire, then destroy the Tower Guardian's three exposed cores before reaching the finish.

## Camera and visibility

The chase camera follows the player across all four gravity surfaces. In v15 it sits 7.0 m behind the runner, with a 71.5° base field of view and a 79.5° boost field of view. It looks 23–36 m down the shaft depending on speed, balancing a more readable character size with useful warning distance. The Guardian HUD also shows the distance to the next core.

The game now starts in fullscreen on the first v15 launch. The preference is saved; players can switch back to windowed mode in Settings. Existing save data is retained during this one-time preference migration.

## Controls

| Key | Action |
|---|---|
| A / D | Strafe; also choose gravity-flip direction when pressing Q |
| Space | Jump from the current surface |
| Q | Flip gravity to an adjacent surface (2-second cooldown) |
| A + Q | Advance FLOOR → LEFT WALL → CEILING |
| D + Q | Reverse the gravity-surface order |
| W or Shift | Boost while stamina remains |
| S or Ctrl | Brake |
| Esc | Pause / resume; in Settings, return to the previous menu |
| R | Restart after Game Over or Victory |

## Final encounter

The Tower Guardian activates at approximately 1280 m. Destroy its three exposed cores in order: **floor → left wall → ceiling**. Hold **A + Q** to advance from floor → left wall → ceiling; hold **D + Q** to reverse the order. Follow the HUD prompt for the next core. Each core rewards bonus score and stamina. The Guardian increases projectile pressure as its integrity falls. Reaching 1500 m while the Guardian is still active costs a life and returns the player to the latest checkpoint; the remaining core targets stay available for another attempt.

## Player quick-start

See `PLAYER_QUICKSTART.md` for the short player-facing guide. It explains gravity direction, boost/braking, stamina, sector progression and the Guardian core sequence.

## Run in the Godot editor

1. Open this folder (`project.godot`) in Godot 4.7.x.
2. Allow Godot to import the GLB, audio and icon assets.
3. Press **F6/F5** or use **Run Project**.
4. Start from the title screen and test the complete 1500 m route.

## Release preflight

Run the offline project-structure checks before importing or exporting:

```bash
python3 tools/release_preflight.py --structural-only
```

Run the full release gate after installing Godot 4.7.2 and its matching export templates:

```bash
python3 tools/release_preflight.py --strict
```

The full check reports missing engine/templates/exports and unresolved audio redistribution rights as blockers. A successful structural-only check is not an engine parse test or a release approval.

## Export builds

Two desktop export presets are included in `export_presets.cfg`:

- **Windows Desktop** → `build/windows/GRAVITY_BREAKER.exe`
- **Linux/X11** → `build/linux/GRAVITY_BREAKER.x86_64`

Before exporting, install the **export templates matching the exact Godot editor version (for example, 4.7.2)** from the editor's export-template manager. The editor version and template version must match. In Godot, open **Project → Export**, select each preset, check for warnings, and export a release build.

Helper scripts are provided: `tools/export_release.sh` for Linux/macOS shells and `tools/export_release.bat` for Windows Command Prompt. They import the project headlessly and then request both desktop release exports. After successful exports, create separate private QA archives with `python3 tools/package_release.py --platform all` (or select `windows` / `linux`). The packager includes the executable, player quick-start and credits, and labels archives as QA-only until release gates are met. These scripts have been prepared but not executed in this environment; they still require the matching export templates on your machine.

Command-line examples (run from this project directory, using the Godot editor executable):

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/GRAVITY_BREAKER.exe
godot --headless --path . --export-release "Linux/X11" build/linux/GRAVITY_BREAKER.x86_64
```

On Linux, mark the exported executable as runnable before launching:

```bash
chmod +x build/linux/GRAVITY_BREAKER.x86_64
./build/linux/GRAVITY_BREAKER.x86_64
```

Package each target separately for distribution. Include the executable and any separate PCK/data file if you change the export presets to stop embedding project data. Do not upload the Godot project folder as the player-facing build unless you specifically intend to distribute the editable project.

## Save data

Best score, master volume, music volume and fullscreen preference are stored in the user's Godot `user://gravity_breaker_save.cfg` location. They are not stored inside the exported project folder.

## Project contents

- `scenes/main.tscn` — tunnel, camera, lighting and scene root.
- `scenes/player.tscn` / `scenes/player.gd` — player, game flow, UI, hazards, projectiles, boss and scoring.
- `scripts/moving_hazard.gd` — reusable moving hazard helper.
- `assets/characters/` — voxel ninja GLB and its Godot import files.
- `assets/audio/` — music and sound effects.
- `CREDITS.md` — known model attribution.
- In-game **How to Play** and **Credits** pages are accessible from the title menu (and How to Play from Pause).
- `ASSET_LICENSE_AUDIT.md` — third-party asset release checks.
- `RELEASE_CHECKLIST.md` — pre-release QA and publishing checklist.
- `V11_LOCAL_TEST_GUIDE.md` — original Guardian regression checklist.
- `V12_LOCAL_TEST_GUIDE.md` — camera, core visibility, menus and release regression tests.
- `V14_RELEASE_CANDIDATE_GUIDE.md` — final camera, build-script, QA and distribution checks.
- `PLAYER_QUICKSTART.md` — short guide for players.
- `tools/export_release.sh` / `.bat` — helper scripts for Windows and Linux exports.
- `tools/package_release.py` — creates separate private QA ZIPs from completed platform exports.
- `ITCH_IO_PAGE_DRAFT.md` — draft store-page copy; not approved for publication yet.

## Current release status

This is an **alpha / release-candidate preparation build**, not a verified public release. The source project and export presets have been prepared, but actual Godot import, Windows/Linux export, exported-build launch, full-course QA, performance profiling and audio licensing confirmation still need to be completed on a machine with Godot 4.7.x and the matching export templates.
