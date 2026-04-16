#!/bin/bash

set -e

echo "Building NotchDrop..."
swift build -c release

APP_NAME="NotchDrop"
APP_BUNDLE="$APP_NAME.app"

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/"

echo "App bundle created: $APP_BUNDLE"
echo ""
echo "To install, run:"
echo "  cp -r $APP_BUNDLE /Applications/"
echo ""
echo "To run now:"
echo "  open $APP_BUNDLE"
