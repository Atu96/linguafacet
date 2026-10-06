#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SDK_26_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [[ -d "$SDK_26_PATH" ]]; then
    SDK_PATH="$SDK_26_PATH"
else
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi
MODULE_CACHE="$PROJECT_DIR/.test-module-cache-arm64"
OUTPUT="$PROJECT_DIR/.build/TranslationCoreSmoke"

mkdir -p "$MODULE_CACHE" "$PROJECT_DIR/.build"

CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx26.4 \
    -module-cache-path "$MODULE_CACHE" \
    -Xfrontend -interface-compiler-version -Xfrontend 6.3.2 \
    "$PROJECT_DIR/Sources/TranslateQuick/Localization.swift" \
    "$PROJECT_DIR/Sources/TranslateQuick/Models.swift" \
    "$PROJECT_DIR/Sources/TranslateQuick/TranslationCore.swift" \
    "$PROJECT_DIR/Tests/TranslationCoreSmoke.swift" \
    -o "$OUTPUT" \
    -framework AppKit \
    -framework NaturalLanguage

"$OUTPUT"
