#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/Input Translator.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"

rm -rf "$APP_DIR"
rm -rf "$ICONSET_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"

cp "$ROOT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

PYTHON_BIN="${PYTHON_BIN:-/Users/apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3}"
"$PYTHON_BIN" "$ROOT_DIR/generate_icon.py" "$ICONSET_DIR" "$RESOURCES_DIR/AppIcon.icns"

swiftc \
  -O \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -framework AppKit \
  -framework Carbon \
  -framework ApplicationServices \
  -framework Security \
  "$ROOT_DIR/main.swift" \
  -o "$MACOS_DIR/InputTranslator"

echo "$APP_DIR"
