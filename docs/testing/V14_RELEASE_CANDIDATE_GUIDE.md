# GRAVITY BREAKER v14 — Release Candidate Guide

## What's changed

- Camera is modestly closer: 7.5 m behind the player.
- Base FOV is 73.5 degrees; boost FOV is 81 degrees.
- Speed-sensitive forward look-ahead now ranges from 23 to 36 m.
- Player quick-start and repeatable export helper scripts are included.
- Project and Windows product version metadata is 0.14.0.

No intended gameplay systems were modified in this pass.

## 1. Open and import

1. Keep the tested v13 project as a backup.
2. Extract this project to a new directory.
3. Open `project.godot` in Godot 4.7.2.
4. Allow the GLB, texture and audio imports to finish.
5. Check Output and Debugger for parser, import and runtime errors.

## 2. Camera acceptance checks

- At 1152×648 and 1280×720, the ninja should look slightly larger than v13, without becoming an over-the-shoulder view.
- Projectiles and hazards should remain visible early enough to react.
- The camera should remain correctly oriented on floor, both walls and ceiling.
- The camera should not clip through the shaft during flips, jumps, respawns or boost.
- Boost FOV should widen smoothly and return smoothly after boost is released.

## 3. Regression checks

- Play through all five sectors.
- Verify 9→14 units/s cruise progression, boost to 22, brake to 4, stamina drain/recovery.
- Verify gravity switching, 2-second cooldown, jumps and all four surfaces.
- Verify all hazards, projectiles, attack warnings, pickups and checkpoints.
- Destroy all three Guardian cores and complete the finish.
- Test death, checkpoint respawn, Game Over, retry, pause, settings, credits, controls and victory.
- Close and reopen the game; verify best score, volume and fullscreen settings persist.

## 4. Export Windows and Linux

Install export templates matching the exact editor version (Godot 4.7.2). Then:

- Linux/macOS shell: run `bash tools/export_release.sh`.
- Windows Command Prompt: run `tools\export_release.bat`.

The scripts expect a `godot` executable on PATH (`godot4` is also detected by the shell script). You may override it with `GODOT_BIN=/absolute/path/to/godot` on Linux/macOS or `set GODOT_BIN=C:\path\to\godot.exe` on Windows.

Expected output paths:

- `build/windows/GRAVITY_BREAKER.exe`
- `build/linux/GRAVITY_BREAKER.x86_64`

An export is not accepted solely because the command succeeds. Launch each exported game outside the editor, preferably on a clean user account or another machine. Test the entire course and save data on each target OS. After testing, create separate private QA ZIPs with `python3 tools/package_release.py --platform all`. These packages include the executable, player quick-start, credits and an explicit QA-only status note.

## 5. Release blockers

- [ ] Confirm redistribution rights/ownership for all eight WAV files.
- [ ] Verify all third-party credits and keep CC BY 4.0 attribution for the Voxel Ninja model.
- [ ] Run Godot 4.7.2 import and static/runtime error checks.
- [ ] Export and launch Windows 64-bit build.
- [ ] Export and launch Linux 64-bit build.
- [ ] Complete all gameplay regression checks.
- [ ] Profile frame rate and memory in sectors 4–5 and the Guardian fight.
- [ ] Capture genuine screenshots and gameplay footage from the exported build.
- [ ] Prepare separate clean platform ZIPs and verify extraction on another account/device.

## Release status

This is release-candidate preparation, not a verified public release. The Godot executable and export templates were not available during this build pass, so no engine launch, actual export, or exported-build playtest is claimed. Audio redistribution rights are also still unresolved and remain a public-release blocker.
