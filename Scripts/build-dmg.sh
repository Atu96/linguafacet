#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$PROJECT_DIR/dist/LinguaFacet.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Resources/Info.plist")"
DMG_PATH="$PROJECT_DIR/dist/LinguaFacet-$VERSION-arm64.dmg"
STAGING_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$PROJECT_DIR/Scripts/build-app.sh" >/dev/null
cp -R "$APP_PATH" "$STAGING_DIR/LinguaFacet.app"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create -volname "LinguaFacet" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null
echo "$DMG_PATH"
