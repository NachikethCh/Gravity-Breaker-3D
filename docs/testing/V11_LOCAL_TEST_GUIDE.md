# GRAVITY BREAKER v11 — Local Test Guide

Use this checklist in Godot 4.7.2 before treating v11 as a release candidate. This build was statically checked but not run in an engine in the preparation environment.

## Quick controls

- A / D: Strafe.
- Space: Jump.
- Q: Gravity flip (2-second cooldown).
- A + Q: Advance FLOOR → LEFT WALL → CEILING.
- D + Q: Reverse that order.
- W / Shift: Boost while stamina remains.
- S / Ctrl: Brake.
- Esc: Pause / resume.

## Tower Guardian test (last 220 m)

1. Start a fresh run and reach approximately **1280 m**. Confirm the Guardian appears and the HUD shows `NEXT: FLOOR`.
2. Stay on the floor and keep near the centre lane. Pass through the glowing floor core at approximately **1328 m**. Confirm Guardian integrity changes from 3/3 to 2/3 and the HUD says `NEXT: LEFT WALL (A+Q)`.
3. Hold **A + Q** to move from the floor onto the left wall. Allow the 2-second cooldown to complete before another flip. Contact the left-wall core at approximately **1392 m**. Confirm integrity changes to 1/3 and the HUD says `NEXT: CEILING (A+Q)`.
4. Hold **A + Q** again to move from the left wall onto the ceiling. Contact the ceiling core at approximately **1458 m**. Confirm Guardian integrity reaches 0/3 and the finish is unlocked.
5. Reach **1500 m** and confirm the victory screen, final score, best score and run time.

## Failure / retry test

- Deliberately reach 1500 m without destroying all cores. Confirm one life is lost and the player returns to the latest checkpoint.
- Confirm already-destroyed cores stay destroyed after a checkpoint respawn; only a fresh run should reset all three.
- Confirm the game-over screen appears after lives are exhausted and Retry starts a fresh run with all boss cores restored.

## Pause and settings test

- Press Esc during gameplay. Confirm world motion, hazards, projectiles, animation and music pause.
- Resume and confirm everything continues.
- Open Settings from the pause menu, change master/music volume, toggle fullscreen, then return to the paused game.
- Close and reopen the game; confirm settings and best score persist.

## Export test

- Open Project → Export and ensure Windows Desktop and Linux/X11 presets load without preset errors.
- Install matching 4.7.2 export templates. Export both platforms.
- Launch each exported build outside the editor and test the title screen, audio, save path, pause/settings, a complete run and the Guardian fight.
