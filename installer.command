#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODE="/Applications/Xcode.app/Contents/Developer"

echo "=== StayAwake — Installation ==="
echo ""

# 1. Compilation Release
echo "▶ Compilation en cours..."
DEVELOPER_DIR="$XCODE" xcodebuild \
    -project "$PROJECT_DIR/StayAwake.xcodeproj" \
    -scheme StayAwake \
    -configuration Release \
    build \
    ONLY_ACTIVE_ARCH=YES \
    2>&1 | grep -E "error:|warning:|BUILD"

# 2. Localiser le build
BUILD_DIR=$(DEVELOPER_DIR="$XCODE" xcodebuild \
    -project "$PROJECT_DIR/StayAwake.xcodeproj" \
    -scheme StayAwake \
    -configuration Release \
    -showBuildSettings 2>/dev/null \
    | grep " BUILT_PRODUCTS_DIR" \
    | awk -F' = ' '{print $2}')
APP_SRC="$BUILD_DIR/StayAwake.app"

if [ ! -d "$APP_SRC" ]; then
    echo "❌ App introuvable après le build : $APP_SRC"
    exit 1
fi

# 3. Arrêter l'app si elle tourne
if pgrep -x StayAwake > /dev/null; then
    echo "▶ Arrêt de StayAwake..."
    killall StayAwake
    sleep 1
fi

# 4. Copier dans /Applications
echo "▶ Copie dans /Applications..."
rm -rf /Applications/StayAwake.app
cp -R "$APP_SRC" /Applications/StayAwake.app

# 5. Signature ad-hoc
echo "▶ Signature de l'app..."
codesign --force --deep --sign - /Applications/StayAwake.app

# 6. Lever la quarantaine Gatekeeper
echo "▶ Levée de la quarantaine Gatekeeper..."
xattr -rd com.apple.quarantine /Applications/StayAwake.app 2>/dev/null || true

# 7. Lancer
echo "▶ Lancement de StayAwake..."
open /Applications/StayAwake.app

echo ""
echo "✅ StayAwake installé et lancé avec succès."
