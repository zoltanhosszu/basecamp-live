#!/bin/bash
# Builds BasecampLive.app next to this script. Pass --install to copy it to
# ~/Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

APP=BasecampLive.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O -o "$APP/Contents/MacOS/BasecampLive" main.swift

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>BasecampLive</string>
  <key>CFBundleIdentifier</key><string>com.37signals.basecamp-live-menubar</string>
  <key>CFBundleExecutable</key><string>BasecampLive</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x BasecampLive || true
  mkdir -p ~/Applications
  rm -rf ~/Applications/"$APP"
  cp -R "$APP" ~/Applications/
  open ~/Applications/"$APP"
  echo "Installed and launched ~/Applications/$APP"
fi
