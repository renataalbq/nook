#!/bin/bash
# Redraws the icon art and packs variant A into Resources/AppIcon.icns.
set -euo pipefail
cd "$(dirname "$0")/.."

swift Scripts/make_icon.swift Icons >/dev/null

SET="Icons/AppIcon.iconset"
rm -rf "$SET"; mkdir -p "$SET"

for size in 16 32 128 256 512; do
    sips -z $size $size Icons/icon-a.png --out "$SET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z $double $double Icons/icon-a.png --out "$SET/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$SET" -o Resources/AppIcon.icns
rm -rf "$SET"
echo "built Resources/AppIcon.icns"
