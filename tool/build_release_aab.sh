#!/usr/bin/env bash
# Release AAB for Play Store (arm + arm64, no x86 emulator libs).
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build appbundle --release \
  --target-platform android-arm,android-arm64 \
  --split-debug-info=build/debug-info
echo ""
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
