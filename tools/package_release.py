#!/usr/bin/env python3
"""Package existing GRAVITY BREAKER desktop exports into QA ZIP archives."""
from __future__ import annotations

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD_STATUS = (
    "GRAVITY BREAKER 0.14.0-alpha — QA candidate\n\n"
    "This package is intended for private testing only. Do not publish publicly until:\n"
    "- the exported executable has been tested outside the Godot editor;\n"
    "- the complete release checklist has been completed; and\n"
    "- redistribution rights for all included audio files have been confirmed.\n"
)

TARGETS = {
    "windows": (ROOT / "build/windows/GRAVITY_BREAKER.exe", "GRAVITY_BREAKER.exe"),
    "linux": (ROOT / "build/linux/GRAVITY_BREAKER.x86_64", "GRAVITY_BREAKER.x86_64"),
}


def package(target: str) -> Path:
    executable, archive_name = TARGETS[target]
    if not executable.is_file() or executable.stat().st_size == 0:
        raise FileNotFoundError(f"Missing or empty export: {executable}\nRun the matching Godot export first.")

    output_dir = ROOT / "build/packages"
    output_dir.mkdir(parents=True, exist_ok=True)
    output = output_dir / f"GRAVITY_BREAKER_0.14.0-alpha_{target}_x64_QA.zip"

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
        archive.write(executable, archive_name)
        packaged_files: list[tuple[Path, str]] = [(executable, archive_name)]
        for filename, arcname in (
            (ROOT / "PLAYER_QUICKSTART.md", "README.txt"),
            (ROOT / "CREDITS.md", "CREDITS.md"),
        ):
            if not filename.is_file():
                raise FileNotFoundError(f"Required packaging document is missing: {filename}")
            packaged_files.append((filename, arcname))
            archive.write(filename, arcname)
        archive.writestr("BUILD_STATUS.txt", BUILD_STATUS)
        checksum_lines = []
        for source, arcname in packaged_files:
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            checksum_lines.append(f"{digest}  {arcname}")
        archive.writestr("SHA256SUMS.txt", "\n".join(checksum_lines) + "\n")

    # Verify the archive can be read back before reporting success.
    with zipfile.ZipFile(output, "r") as archive:
        bad = archive.testzip()
        if bad is not None:
            raise zipfile.BadZipFile(f"Corrupt member in {output}: {bad}")
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", choices=("windows", "linux", "all"), default="all")
    args = parser.parse_args()
    targets = tuple(TARGETS) if args.platform == "all" else (args.platform,)
    try:
        for target in targets:
            result = package(target)
            print(f"QA package created: {result.relative_to(ROOT)} ({result.stat().st_size:,} bytes)")
    except (OSError, zipfile.BadZipFile) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print("These are private QA packages, not public-release builds.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
