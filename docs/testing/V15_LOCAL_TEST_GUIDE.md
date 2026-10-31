# GRAVITY BREAKER v0.15 — Local test guide

## Install

1. Extract this project into a new folder. Keep v0.14 untouched as a rollback copy.
2. Open `project.godot` in Godot 4.7.2 and allow imports to finish.
3. Run the project once. The first v0.15 launch should switch to fullscreen automatically.

## Fullscreen preference migration

- Existing v0.14 save data is preserved.
- The first v0.15 launch writes `settings.fullscreen=true` and `settings.fullscreen_default_v15_applied=true` to `user://gravity_breaker_save.cfg`.
- In Settings, turn Fullscreen Mode off; confirm the window returns to windowed mode.
- Quit and relaunch. The game should remain windowed because the player's explicit preference is now stored.
- Turn it on again and relaunch; it should remain fullscreen.
- Reset Settings should restore fullscreen.

## Camera

Check the ninja at normal cruise and boost speed on:
- floor
- left wall
- ceiling
- right wall

Confirm the runner is slightly larger than v0.14 but incoming projectiles, lasers and Guardian cores remain visible early enough. The camera remains 7.0 m behind the player; FOV is 71.5 degrees normal and 79.5 degrees at max boost.

## Release log check

Run the exported Linux build from a terminal. The long list of `MOVING HAZARD configured` setup messages should no longer print in a release build. Debug/editor builds intentionally retain the diagnostic messages.

## Regression checks

- Title menu, How to Play, Credits, Settings and Quit.
- Pause/resume and settings persistence.
- Gravity flips and 2-second cooldown on all four surfaces.
- Speed progression, boost stamina and braking.
- Five sector transitions, hazards, projectiles and checkpoints.
- Tower Guardian three-core sequence and finish/victory.
- Game Over, retry, best-score persistence.
- Linux export launch and Windows export launch on a Windows machine.

Do not publish until the audio redistribution audit is resolved and both exported builds have been tested on their target operating systems.
