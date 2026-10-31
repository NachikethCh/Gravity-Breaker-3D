# GRAVITY BREAKER release checklist

## Project and imports

- [ ] Validate v15 camera framing at 1152×648 and 1280×720 (7.0 m camera distance; 71.5° base FOV; 79.5° boost FOV).

- [x] Add an offline resource/export-preset preflight (`python3 tools/release_preflight.py --structural-only`).
- [ ] Run the full release gate (`python3 tools/release_preflight.py --strict`) on a machine with Godot 4.7.2 and matching templates.
- [ ] Open the project with the intended Godot 4.7.x release.
- [ ] Wait for a clean asset import; check the Output and Import tabs.
- [ ] Confirm the GLB character and every WAV file load without errors.
- [ ] Confirm no script parser errors or unexpected runtime errors.

## Gameplay QA

- [ ] Complete all five sectors from 0 m to 1500 m.
- [ ] Verify progressive cruise speed (9 to 14 units/s), boost, brake and stamina recovery.
- [ ] Verify gravity switching on all four surfaces and the 2-second cooldown.
- [ ] Verify jumping, hazards, collisions, projectiles and attack warning telegraphs.
- [ ] Verify all checkpoints, lives, respawns and score bonuses.
- [ ] Verify the Tower Guardian activates at 1280 m.
- [ ] Verify the floor, left-wall and ceiling core targets each reduce Guardian integrity.
- [ ] Verify the HUD identifies the next Guardian core surface and the directional Q-flip hint is understandable.
- [ ] Verify the Guardian idle animation, phase announcements and phase-based projectile ramp.
- [ ] Verify reaching 1500 m before defeating the Guardian costs a life and respawns at the latest checkpoint.
- [ ] Verify defeating the Guardian unlocks the finish and the Victory screen.
- [ ] Verify Game Over, retry, Main Menu and saved best score.
- [ ] Verify pause/resume, Settings, master volume, music volume and fullscreen/windowed mode.
- [ ] Verify save settings persist after fully closing and reopening the game.

## Visual, audio and performance QA
- [ ] Verify v15 chase camera previews hazards and Guardian cores clearly at normal and boost speed.
- [ ] Verify camera remains correctly oriented on all four gravity surfaces and after checkpoint respawns.
- [ ] Verify How to Play and Credits pages are accessible from menus and fit smaller window sizes.

- [ ] Test at 1280×720 and at least one lower resolution.
- [ ] Test windowed and fullscreen modes on both target operating systems.
- [ ] Check UI clipping, scaling and readable text.
- [ ] Check grid visibility on floor, ceiling and both walls.
- [ ] Check collision shapes match visible obstacle geometry.
- [ ] Profile frame rate and memory during the busiest final sector.
- [ ] Check music loop, sound levels, warning timing and pause behavior.

## Licensing and packaging

- [ ] Confirm redistribution rights for all audio files.
- [ ] Include `CREDITS.md` and relevant CC BY 4.0 attribution in the player-facing package/page.
- [ ] Review `ITCH_IO_PAGE_DRAFT.md`; replace screenshot placeholders with genuine captures from exported builds.
- [ ] Choose and document a project code/art license, if distributing source.
- [ ] Install export templates matching the exact Godot editor version.
- [ ] Export Windows 64-bit and test on a separate Windows machine/account.
- [ ] Export Linux 64-bit and test outside the editor on a clean Linux user account.
- [ ] Verify no editor-only files, personal paths, debug-only overlays or test data are included.
- [ ] Prepare a clean ZIP per platform with a short `README` and credits.
- [ ] Capture genuine gameplay screenshots and a short trailer for the itch.io page.
- [ ] Upload restricted/private builds first, test downloads and extraction, then publish publicly.

## Release status

Do not mark the project released until every required gameplay, export and license item above has been checked on the actual target builds.


## v15 fullscreen and camera polish

- [x] Default first launch to fullscreen with a one-time save migration; preserve the player's later windowed/fullscreen choice.
- [x] Tighten camera framing slightly while preserving speed-based look-ahead.
- [x] Suppress verbose moving-hazard setup logs in release builds.
- [x] Remove duplicate UIDs from inactive legacy scene copies (active scene UIDs remain unchanged).
- [x] Update product metadata to 0.15.0.
- [ ] Verify fullscreen launch and Settings toggle on Linux and Windows exports.
- [ ] Verify camera framing on all four gravity surfaces.

## v14 release-candidate preparation

- [x] Add Linux/macOS and Windows export helper scripts.
- [x] Add a Python standard-library packager for separate private QA ZIPs.
- [x] Update project and Windows product version metadata to 0.14.0.
- [x] Add player quick-start and v14 release-candidate guide.
- [x] Add release preflight utility and SHA-256 manifests to private QA packages.
- [x] Add Godot 4.7.2 version guards to export helper scripts.
- [x] Record static release-candidate audit and remaining blockers.
- [ ] Execute imports and exports using Godot 4.7.2 and matching templates.
- [ ] Run exported builds outside the editor on Windows and Linux.
