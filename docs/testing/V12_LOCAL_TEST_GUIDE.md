# GRAVITY BREAKER v12 — Local Test Guide

## Camera / visibility tests
1. Start a fresh run at 0 m. Confirm the ninja remains in the lower-middle portion of the frame and the camera previews substantially more track ahead than v11.
2. Hold W to boost. Confirm the FOV widens smoothly (not abruptly) and returns after releasing boost.
3. Flip from floor to left wall, ceiling, and right wall. Confirm the camera rotates with gravity, remains behind the runner, and keeps the track ahead visible.
4. Test jumping and checkpoint respawns. Confirm the camera does not snap to an incorrect orientation or clip through the tunnel surfaces.
5. At 1280 m+, confirm the Guardian HUD shows the next core distance; verify the larger core orb/ring is visible approaching each target.

## Menu and HUD tests
- Title menu: Play, How to Play, Settings, Credits, Quit.
- Pause menu: Resume, Main Menu, Settings, How to Play. ESC resumes and ESC from Settings returns to the previous menu.
- Confirm the controls and credit copy wrap correctly at 1280x720 and 1152x648.
- Confirm the HUD wraps onto two readable lines without hiding the stamina/cooldown bars.
- Confirm Guardian status and attack warnings do not overlap the top-left HUD.

## Regression tests
- Complete 0–1500 m and verify all five sectors, checkpoints, score, lives, collectibles, boss cores, and victory.
- Test death/retry and checkpoint respawn with camera reset.
- Test audio sliders/fullscreen persistence, high-score persistence and pause/resume.
- Test on all four surfaces at normal speed, boost and brake.

## Release blocking items still pending
- Run the project in Godot 4.7.2 and resolve any engine parser/import/runtime errors.
- Export Windows 64-bit and Linux 64-bit using matching export templates.
- Launch both exports outside the editor and test on clean user accounts.
- Profile performance in sectors 4–5 and the Guardian fight.
- Confirm redistribution rights for every WAV file before public distribution.

## v13 camera zoom check

The chase camera is intentionally only slightly closer than v12 (8.3 m behind instead of 9.0 m) and uses a 76-degree base FOV / 83.5-degree boost FOV. Compare player size and visible track preview at normal speed and while boosting. The intended change is modest, not a tight over-the-shoulder camera.


## v14 camera framing check

V14 moves the camera to 7.5 m behind the player, with a 73.5-degree base FOV and 81-degree boost FOV. Look-ahead ranges from 23 to 36 m. Confirm the ninja is visibly larger than v13 while the track preview remains sufficient for projectiles and the Guardian cores.
