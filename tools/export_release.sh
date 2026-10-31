#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  elif command -v godot4 >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot4)"
  else
    echo "ERROR: Godot was not found. Install Godot 4.7.2 and put it on PATH, or set GODOT_BIN." >&2
    exit 127
  fi
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: GODOT_BIN is not executable: $GODOT_BIN" >&2
  exit 127
fi

mkdir -p "$PROJECT_DIR/build/windows" "$PROJECT_DIR/build/linux"
GODOT_VERSION="$($GODOT_BIN --version)"
echo "Using: $GODOT_VERSION"
if [[ "$GODOT_VERSION" != 4.7.2* ]]; then
  echo "ERROR: this release candidate targets Godot 4.7.2; found $GODOT_VERSION." >&2
  exit 2
fi
echo "Importing project resources..."
"$GODOT_BIN" --headless --editor --path "$PROJECT_DIR" --quit

echo "Exporting Windows Desktop release..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Windows Desktop" "$PROJECT_DIR/build/windows/GRAVITY_BREAKER.exe"

echo "Exporting Linux/X11 release..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Linux/X11" "$PROJECT_DIR/build/linux/GRAVITY_BREAKER.x86_64"
chmod +x "$PROJECT_DIR/build/linux/GRAVITY_BREAKER.x86_64"

for output in "$PROJECT_DIR/build/windows/GRAVITY_BREAKER.exe" "$PROJECT_DIR/build/linux/GRAVITY_BREAKER.x86_64"; do
  if [[ ! -s "$output" ]]; then
    echo "ERROR: expected export missing or empty: $output" >&2
    exit 1
  fi
done

echo "Both exports were created. Launch and test each build outside the editor before distribution."
