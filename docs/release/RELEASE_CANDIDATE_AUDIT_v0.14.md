# GRAVITY BREAKER 0.14.0-alpha — Release Candidate Audit

**Audit date:** 2026-10-31  
**Scope:** Source project structure, resource paths, platform export configuration, helper scripts and licensing inventory.  
**Important:** This is a static/preflight audit. It is not a Godot engine import, exported-game test, cross-platform test or public-release approval.

## Checks completed in the build environment

| Check | Result | Evidence |
|---|---|---|
| Required project files | PASS | 18 required files present |
| Main scene UID | PASS | `run/main_scene` UID found in `scenes/main.tscn` |
| Literal `res://` references | PASS | 16 references resolve to existing project paths |
| Windows Desktop preset | PASS | `build/windows/GRAVITY_BREAKER.exe` configured |
| Linux/X11 preset | PASS | `build/linux/GRAVITY_BREAKER.x86_64` configured |
| PNG icon | PASS | Valid 1024×1024 RGBA PNG |
| Windows ICO | PASS | Valid ICO container with 6 images |
| WAV assets | PASS | All 8 files decode as PCM WAV; 12.2 seconds total audio |
| Export helper shell syntax | PASS | `bash -n tools/export_release.sh` |
| Python helper syntax | PASS | `py_compile` for packaging and preflight scripts |
| Private QA package helper | PASS | Isolated smoke test with temporary dummy executable files; not actual game binaries |

## Release blockers still open

1. **Godot 4.7.2 executable unavailable in the build environment.** No engine import, GDScript parse, scene launch or in-engine test was run here.
2. **Matching Godot 4.7.2 export templates unavailable.** No actual Windows or Linux build was created.
3. **Platform binaries do not exist yet.** The project still needs Windows and Linux exports, followed by launches outside the editor.
4. **Audio redistribution rights remain unconfirmed.** The eight WAVs have no embedded author/license metadata. Obtain ownership or redistribution permission before public distribution.
5. **Target-platform QA remains pending.** Complete a full 1500 m run, test the Guardian and settings, and profile performance on real target hardware.

## Exact preflight commands

Structural checks (no Godot required):

```bash
python3 tools/release_preflight.py --structural-only
```

Full release gate (requires Godot 4.7.2 and installed matching templates):

```bash
python3 tools/release_preflight.py --strict
```

The full preflight checks Godot availability/version, editor import, expected Windows/Linux release templates and existence of both exports. It reports unresolved licensing as a blocker. A successful check still does not replace manual playtesting on Windows and Linux.

## Current decision

**NOT READY FOR PUBLIC RELEASE.** The project structure and basic packaging configuration pass static checks, but actual engine validation, platform exports, target-device playtests and audio-license clearance are outstanding.
