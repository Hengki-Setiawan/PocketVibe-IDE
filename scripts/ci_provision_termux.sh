#!/bin/bash
set -e

echo "=== CI: Provision Termux ==="

# Install Termux & Termux:API from F-Droid (direct APK download)
TERMUX_APK_URL="https://f-droid.org/repo/com.termux_118.apk"
TERMUX_API_APK_URL="https://f-droid.org/repo/com.termux.api_51.apk"

if command -v jq &> /dev/null; then
  echo "jq tersedia, mengambil APK terbaru dari API F-Droid..."
  TERMUX_APK_URL=$(curl -s https://f-droid.org/api/v1/packages/com.termux | jq -r '.packages[0].apkName' | xargs -I{} echo "https://f-droid.org/repo/{}")
  TERMUX_API_APK_URL=$(curl -s https://f-droid.org/api/v1/packages/com.termux.api | jq -r '.packages[0].apkName' | xargs -I{} echo "https://f-droid.org/repo/{}")
else
  echo "jq tidak tersedia, menggunakan URL APK fallback..."
fi

echo "Downloading Termux APK..."
curl -sL -o termux.apk "$TERMUX_APK_URL"
echo "Downloading Termux:API APK..."
curl -sL -o termux-api.apk "$TERMUX_API_APK_URL"

adb install -r termux.apk 2>/dev/null || adb install termux.apk
adb install -r termux-api.apk 2>/dev/null || adb install termux-api.apk

# Grant permissions
adb shell pm grant com.termux android.permission.READ_EXTERNAL_STORAGE 2>/dev/null || true
adb shell pm grant com.termux android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null || true

adb shell appops set --uid com.termux MANAGE_EXTERNAL_STORAGE allow 2>/dev/null || true
adb shell appops set com.termux SYSTEM_ALERT_WINDOW allow 2>/dev/null || true

# Seed termux.properties
adb shell "mkdir -p /data/data/com.termux/files/home/.termux" 2>/dev/null || true
echo "allow-external-apps=true" > /tmp/termux.properties
adb push /tmp/termux.properties /data/data/com.termux/files/home/.termux/termux.properties
adb shell "chown -R $(adb shell stat -c %u /data/data/com.termux/files/home 2>/dev/null || echo 0) /data/data/com.termux/files/home/.termux" 2>/dev/null || true
adb shell am force-stop com.termux 2>/dev/null || true

echo "=== Termux provisioned ==="
