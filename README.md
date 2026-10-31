# GRAVITY BREAKER

> **Defy gravity. Survive the tower.**

GRAVITY BREAKER is a fast-paced 3D action runner set inside a futuristic
tower. Switch gravity between surfaces, dodge hazards, manage your boost
stamina, and fight your way through five increasingly dangerous sectors.

## Game Overview

The tower is a 1,500-metre challenge divided into five sectors. Gravity
is your main survival tool: move across the current surface, jump over
hazards, and switch to adjacent surfaces to avoid danger.

As you progress, your running speed increases. Use boost strategically,
brake when necessary, collect energy shards, activate checkpoints, and
face the Tower Guardian near the finish.

## Features

-   A 1,500-metre course divided into five sectors.
-   Gravity switching between the floor, walls, and ceiling.
-   A two-second gravity-switch cooldown.
-   Auto-running speed that increases as you progress.
-   Stamina-based boost and braking.
-   Hazards including moving lasers, spikes, crushers, rotating blades,
    energy mines, and enemy projectiles.
-   Checkpoints, collectibles, scoring, and a saved best score.
-   A Tower Guardian encounter featuring three cores.

## Controls

  Input           Action
  --------------- --------------------------------------
  **A / D**       Strafe across the current surface
  **Space**       Jump
  **Q**           Flip gravity to an adjacent surface
  **A + Q**       Advance through the surface sequence
  **D + Q**       Reverse through the surface sequence
  **W / Shift**   Boost while stamina remains
  **S / Ctrl**    Brake
  **Esc**         Pause or resume

Gravity switching has a two-second cooldown. The surface sequence for
advancing is **Floor → Left Wall → Ceiling**; the reverse input moves in
the opposite direction.

## Download and Run

The game targets **64-bit Windows** and **64-bit Linux**.

Download the archive matching your operating system from the game's
itch.io page, extract it, and run the game executable.

**Important for the maintainer:** When Godot's **Embed PCK** option is
disabled, distribute the executable together with its matching `.pck`
file if Godot generated one. Do not package only the executable unless
you have confirmed that the build contains all required game resources.
Test the extracted archive on the target operating system before
publishing.

-   Windows archive: `GRAVITY_BREAKER_Windows_v15.zip`
-   Linux archive: `GRAVITY_BREAKER_Linux_v15.zip`

> Replace or remove these filenames if the published release uses
> different names.

## Development

The game is built with **Godot Engine 4.7** using GDScript.

To work on the source project:

1.  Clone or download this repository.
2.  Open the project in Godot 4.7.
3.  Import the project when prompted.
4.  Open `project.godot` and run the project from the editor.

Generated build output and Godot's local editor cache should generally
not be committed to the source repository. Keep the playable exports on
itch.io and the source code and documentation on GitHub.

## Credits and Asset Licensing

The voxel ninja character model is **\[Project Catnip\] Voxel Ninja
Run** by Raushen, licensed under **Creative Commons Attribution 4.0 (CC
BY 4.0)**. Include the full asset source and attribution in
`CREDITS.md`.

Before distributing a public build, verify the redistribution rights for
**all included audio and other third-party assets**. Do not publish
assets whose redistribution permissions have not been confirmed.

## Project Status

GRAVITY BREAKER is a work in progress. Features, balance, compatibility,
and release packaging may change.

## Feedback

Please report bugs and suggestions through the repository's Issues page.
