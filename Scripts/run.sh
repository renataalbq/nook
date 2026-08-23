#!/bin/bash
# Quits any running copy, rebuilds, and launches the fresh one.
# `open` alone only focuses an already-running app, so the quit matters.
set -euo pipefail
cd "$(dirname "$0")/.."

killall Nook 2>/dev/null || true
sleep 0.5
./Scripts/bundle.sh "${1:-debug}"
open build/Nook.app
