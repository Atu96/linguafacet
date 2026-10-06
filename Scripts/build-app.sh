#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="LinguaFacet"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_DIR="$PROJECT_DIR/dist/$APP_NAME.app"
SDK_26_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [[ -d "$SDK_26_PATH" ]]; then
    SDK_PATH="$SDK_26_PATH"
else
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi
MODULE_CACHE="$PROJECT_DIR/.module-cache-arm64"
SIGN_IDENTITY="${TRANSLATE_QUICK_SIGN_IDENTITY:--}"

cd "$PROJECT_DIR"
mkdir -p "$BUILD_DIR" "$MODULE_CACHE"
"$PROJECT_DIR/Scripts/test-core.sh"

# Compile directly so the project does not require a generated Xcode project.
# Compile against the macOS 26 SDK used by the app. Newer CLT releases may
# make macOS 27 the default while omitting SwiftUI macro plugins needed by
# direct swiftc builds.
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx26.4 \
    -module-cache-path "$MODULE_CACHE" \
    -Xfrontend -interface-compiler-version -Xfrontend 6.3.2 \
    -parse-as-library \
    -O \
    "$PROJECT_DIR"/Sources/TranslateQuick/*.swift \
    -o "$BUILD_DIR/TranslateQuick" \
    -framework AppKit \
    -framework ApplicationServices \
    -framework Carbon \
    -framework Translation \
    -framework Security \
    -framework AVFoundation \
    -framework ServiceManagement \
    -framework NaturalLanguage \
    -framework FoundationModels

# Always assemble a clean bundle so removed resources cannot leak in from an
# earlier build.
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/TranslateQuick" "$APP_DIR/Contents/MacOS/TranslateQuick"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
for localization in "$PROJECT_DIR"/Resources/*.lproj; do
    cp -R "$localization" "$APP_DIR/Contents/Resources/"
done
if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --deep --sign - \
        --requirements '=designated => identifier "com.gemst.translatequick"' \
        "$APP_DIR"
else
    codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"
fi

echo "$APP_DIR"
