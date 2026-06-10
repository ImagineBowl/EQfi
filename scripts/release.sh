#!/usr/bin/env bash
# Build, notarize, and package EQfi for GitHub Release.
#
# Prerequisites:
#   1. "Developer ID Application" certificate in Keychain (Xcode → Settings → Accounts → Manage Certificates)
#   2. Notary credentials stored once:
#        xcrun notarytool store-credentials EQfi-Notary \
#          --apple-id YOUR_APPLE_ID \
#          --team-id GLDH2T9TP5 \
#          --password YOUR_APP_SPECIFIC_PASSWORD
#   3. gh CLI authenticated: gh auth login
#
# Usage:
#   ./scripts/release.sh 1.0.0

set -euo pipefail

VERSION="${1:-1.0.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
EXPORT_DIR="$BUILD_DIR/export"
APP_PATH="$EXPORT_DIR/EQfi.app"
DMG_PATH="$ROOT/EQfi-${VERSION}.dmg"
NOTARY_PROFILE="${NOTARY_PROFILE:-EQfi-Notary}"
ARCHIVE_PATH="$BUILD_DIR/EQfi.xcarchive"

cd "$ROOT"

echo "==> Archiving EQfi ${VERSION}..."
xcodebuild \
  -project EQfi.xcodeproj \
  -scheme EQfi \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo "==> Exporting with Developer ID..."
rm -rf "$EXPORT_DIR"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist ExportOptions.plist

echo "==> Notarizing..."
ZIP_PATH="$BUILD_DIR/EQfi-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
spctl -a -vv -t install "$APP_PATH"

echo "==> Creating DMG..."
STAGING="/tmp/EQfi-dmg-${VERSION}"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG_PATH"
hdiutil create -volname "EQfi" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH"
rm -rf "$STAGING"

echo ""
echo "Done: $DMG_PATH"
echo ""
echo "GitHub release:"
echo "  git tag v${VERSION}"
echo "  git push origin v${VERSION}"
echo "  gh release create v${VERSION} \"$DMG_PATH\" --title \"EQfi v${VERSION}\" --notes-file RELEASE_NOTES.md"
