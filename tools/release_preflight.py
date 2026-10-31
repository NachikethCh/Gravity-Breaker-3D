#!/usr/bin/env python3
"""Offline preflight checks for the GRAVITY BREAKER Godot release candidate.

This script does not replace a Godot import, platform export, or playtest. It
checks project structure, literal res:// references, desktop export presets,
required assets, and local availability of Godot 4.7.2/export templates.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import struct
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_GODOT = "4.7.2"
REQUIRED_FILES = (
    "project.godot",
    "export_presets.cfg",
    "scenes/main.tscn",
    "scenes/player.tscn",
    "scenes/player.gd",
    "scripts/moving_hazard.gd",
    "assets/characters/project_catnip_voxel_ninja_run.glb",
    "icon.svg",
    "icon.png",
    "icon.ico",
    "README.md",
    "PLAYER_QUICKSTART.md",
    "CREDITS.md",
    "ASSET_LICENSE_AUDIT.md",
    "RELEASE_CHECKLIST.md",
    "tools/export_release.sh",
    "tools/export_release.bat",
    "tools/package_release.py",
)
EXPECTED_PRESETS = {
    "Windows Desktop": ("Windows Desktop", "build/windows/GRAVITY_BREAKER.exe"),
    "Linux/X11": ("Linux/X11", "build/linux/GRAVITY_BREAKER.x86_64"),
}


def report(status: str, message: str) -> None:
    print(f"[{status}] {message}")


def parse_presets(text: str) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    current: str | None = None
    for line in text.splitlines():
        section = re.fullmatch(r"\[(preset\.\d+)\]", line.strip())
        if section:
            current = section.group(1)
            result[current] = {}
            continue
        if current and "=" in line and not line.lstrip().startswith(";"):
            key, value = line.split("=", 1)
            result[current][key.strip()] = value.strip().strip('"')
    return result


def collect_res_references() -> list[tuple[Path, str]]:
    refs: list[tuple[Path, str]] = []
    patterns = (
        re.compile(r'path\s*=\s*"res://([^"]+)"'),
        re.compile(r'(?<![A-Za-z0-9_])res://([A-Za-z0-9_./ -]+)'),
    )
    for suffix in ("*.tscn", "*.gd", "*.tres", "*.godot"):
        for source in ROOT.rglob(suffix):
            if any(part in {".godot", ".git", "build"} for part in source.parts):
                continue
            try:
                text = source.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            seen: set[str] = set()
            for pattern in patterns:
                for match in pattern.findall(text):
                    path = match.rstrip("'\" ),;]")
                    if path and path not in seen:
                        seen.add(path)
                        refs.append((source.relative_to(ROOT), path))
    return refs


def check_icons() -> bool:
    ok = True
    png = ROOT / "icon.png"
    if png.is_file():
        data = png.read_bytes()[:24]
        if len(data) == 24 and data[:8] == b"\x89PNG\r\n\x1a\n":
            width, height = struct.unpack(">II", data[16:24])
            report("PASS", f"PNG icon valid ({width}x{height})")
        else:
            report("FAIL", "icon.png is not a valid PNG header")
            ok = False
    ico = ROOT / "icon.ico"
    if ico.is_file():
        data = ico.read_bytes()[:6]
        if len(data) == 6 and data[:4] == b"\x00\x00\x01\x00" and data[4] > 0:
            report("PASS", f"Windows ICO container valid ({data[4]} images)")
        else:
            report("FAIL", "icon.ico is not a valid ICO container")
            ok = False
    return ok


def check_audio() -> bool:
    audio_dir = ROOT / "assets/audio"
    files = sorted(audio_dir.glob("*.wav"))
    if len(files) != 8:
        report("FAIL", f"Expected 8 WAV files, found {len(files)}")
        return False
    ok = True
    total_duration = 0.0
    for path in files:
        try:
            with wave.open(str(path), "rb") as wav:
                if wav.getnchannels() < 1 or wav.getframerate() < 8000 or wav.getnframes() < 1:
                    raise ValueError("invalid channel/rate/frame metadata")
                total_duration += wav.getnframes() / wav.getframerate()
        except (wave.Error, OSError, ValueError) as exc:
            report("FAIL", f"{path.relative_to(ROOT)}: {exc}")
            ok = False
    if ok:
        report("PASS", f"All {len(files)} WAV assets decode ({total_duration:.1f}s total)")
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict", action="store_true", help="return non-zero for missing engine/templates/exports/audio clearance")
    parser.add_argument("--structural-only", action="store_true", help="skip engine/templates/export/license release blockers")
    args = parser.parse_args()
    failures = 0
    blockers = 0

    missing = [name for name in REQUIRED_FILES if not (ROOT / name).is_file()]
    if missing:
        failures += len(missing)
        for name in missing:
            report("FAIL", f"Required project file missing: {name}")
    else:
        report("PASS", f"All {len(REQUIRED_FILES)} required project files are present")

    project_text = (ROOT / "project.godot").read_text(encoding="utf-8") if (ROOT / "project.godot").exists() else ""
    main_uid_match = re.search(r'^run/main_scene\s*=\s*"uid://([^" ]+)"', project_text, re.M)
    scene_texts = {p: p.read_text(encoding="utf-8", errors="replace") for p in ROOT.rglob("*.tscn")}
    if main_uid_match and any(f'uid="uid://{main_uid_match.group(1)}"' in text for text in scene_texts.values()):
        report("PASS", "Main-scene UID resolves to a project scene")
    elif 'run/main_scene="res://' in project_text:
        report("PASS", "Main scene is configured by resource path")
    else:
        failures += 1
        report("FAIL", "Could not resolve project run/main_scene UID")

    refs = collect_res_references()
    missing_refs = [(source, path) for source, path in refs if not (ROOT / path).exists()]
    if missing_refs:
        failures += len(missing_refs)
        for source, path in missing_refs:
            report("FAIL", f"Missing res:// reference in {source}: {path}")
    else:
        report("PASS", f"All {len(refs)} literal res:// resource references resolve")

    presets_text = (ROOT / "export_presets.cfg").read_text(encoding="utf-8") if (ROOT / "export_presets.cfg").exists() else ""
    presets = parse_presets(presets_text)
    preset_names = {item.get("name") for item in presets.values()}
    for expected_name, (_, expected_path) in EXPECTED_PRESETS.items():
        if expected_name in preset_names and expected_path in presets_text:
            report("PASS", f"Export preset configured: {expected_name} -> {expected_path}")
        else:
            failures += 1
            report("FAIL", f"Missing or misconfigured export preset: {expected_name}")

    if check_icons() is False:
        failures += 1
    if check_audio() is False:
        failures += 1

    if args.structural_only:
        print("\nStructural preflight summary")
        print(f"  Static failures: {failures}")
        print("  Engine/export/license checks: skipped by request")
        return 2 if failures else 0

    godot_bin = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    version_ok = False
    if godot_bin:
        import subprocess
        try:
            result = subprocess.run([godot_bin, "--version"], capture_output=True, text=True, timeout=20, check=False)
            version = (result.stdout or result.stderr).strip().splitlines()[0]
            version_ok = result.returncode == 0 and EXPECTED_GODOT in version
            if version_ok:
                report("PASS", f"Godot version matches target: {version}")
            else:
                blockers += 1
                report("BLOCKED", f"Godot found ({version}), but project target is {EXPECTED_GODOT}")
        except (OSError, subprocess.SubprocessError) as exc:
            blockers += 1
            report("BLOCKED", f"Could not execute Godot binary: {exc}")
    else:
        blockers += 1
        report("BLOCKED", "Godot 4.7.2 executable not found; engine import/parse and exports cannot run")

    xdg_data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    default_template_root = xdg_data_home / "godot/export_templates"
    template_root = Path(os.environ.get("GODOT_EXPORT_TEMPLATES", default_template_root))
    template_dir = template_root / f"{EXPECTED_GODOT}.stable"
    required_templates = ("windows_release_x86_64.exe", "linux_release.x86_64")
    missing_templates = [name for name in required_templates if not (template_dir / name).is_file()]
    if template_dir.is_dir() and not missing_templates:
        report("PASS", f"Windows and Linux release templates found: {template_dir}")
    else:
        blockers += 1
        report("BLOCKED", f"Matching export templates incomplete at {template_dir}; missing: {', '.join(missing_templates) or 'template directory'}")

    if godot_bin and version_ok:
        import subprocess
        try:
            import_result = subprocess.run(
                [godot_bin, "--headless", "--editor", "--path", str(ROOT), "--quit"],
                capture_output=True, text=True, timeout=300, check=False,
            )
            import_output = (import_result.stdout or "") + "\n" + (import_result.stderr or "")
            import_errors = re.findall(r"(?im)^.*(?:SCRIPT ERROR|Parse Error|ERROR: Failed to load|ERROR: Cannot open).*?$", import_output)
            if import_result.returncode == 0 and not import_errors:
                report("PASS", "Godot headless editor import completed without detected script/resource errors")
            else:
                blockers += 1
                report("BLOCKED", f"Godot headless editor import reported errors (exit {import_result.returncode}); inspect Godot output")
                for line in import_errors[:8]:
                    print("       " + line.strip())
        except (OSError, subprocess.SubprocessError) as exc:
            blockers += 1
            report("BLOCKED", f"Godot headless import could not complete: {exc}")

    outputs = (
        ROOT / "build/windows/GRAVITY_BREAKER.exe",
        ROOT / "build/linux/GRAVITY_BREAKER.x86_64",
    )
    existing = [p for p in outputs if p.is_file() and p.stat().st_size > 0]
    if len(existing) == 2:
        report("PASS", "Both Windows and Linux export artifacts exist and are non-empty")
    else:
        blockers += 1
        missing_names = [str(p.relative_to(ROOT)) for p in outputs if p not in existing]
        report("BLOCKED", "Platform exports still missing: " + ", ".join(missing_names))

    license_text = (ROOT / "ASSET_LICENSE_AUDIT.md").read_text(encoding="utf-8", errors="replace") if (ROOT / "ASSET_LICENSE_AUDIT.md").exists() else ""
    license_lower = license_text.lower()
    if "release blocker until confirmed" in license_lower or "confirm the provenance and permission" in license_lower or "redistribution rights" in license_lower and "confirm" in license_lower:
        blockers += 1
        report("BLOCKED", "Audio redistribution rights are not documented as cleared")
    else:
        report("INFO", "Review ASSET_LICENSE_AUDIT.md and retain permission evidence before release")

    print("\nRelease preflight summary")
    print(f"  Static failures: {failures}")
    print(f"  Release blockers: {blockers}")
    print("  Public release status: " + ("NOT READY" if failures or blockers else "READY FOR HUMAN QA"))
    if failures:
        return 2
    if args.strict and blockers:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
