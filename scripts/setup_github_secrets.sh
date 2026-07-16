#!/bin/bash
# ============================================================
# Setup GitHub Secrets untuk PocketVibe IDE Release Build
# Jalankan setelah repo dibuat di GitHub.
# ============================================================
set -e

REPO="Hengki-Setiawan/PocketVibe-IDE"
KEYSTORE_PATH="$1"

if [ -z "$KEYSTORE_PATH" ]; then
  echo "Usage: $0 <path-to-keystore>"
  echo "Example: $0 D:\\pocketvibe-release.jks"
  exit 1
fi

if [ ! -f "$KEYSTORE_PATH" ]; then
  echo "Error: Keystore not found at $KEYSTORE_PATH"
  exit 1
fi

# Baca password dari user
read -sp "Keystore password: " STORE_PASS
echo
read -sp "Key alias: " KEY_ALIAS
echo
read -sp "Key password: " KEY_PASS
echo

gh secret set ANDROID_KEYSTORE_BASE64 --body "$(base64 -w0 "$KEYSTORE_PATH")" --repo "$REPO"
gh secret set ANDROID_KEYSTORE_PASSWORD --body "$STORE_PASS" --repo "$REPO"
gh secret set ANDROID_KEY_ALIAS --body "$KEY_ALIAS" --repo "$REPO"
gh secret set ANDROID_KEY_PASSWORD --body "$KEY_PASS" --repo "$REPO"

echo "✅ Secrets berhasil diset ke GitHub"
echo "   - ANDROID_KEYSTORE_BASE64: dari file '$KEYSTORE_PATH'"
echo "   - ANDROID_KEYSTORE_PASSWORD: [tersembunyi]"
echo "   - ANDROID_KEY_ALIAS: $KEY_ALIAS"
echo "   - ANDROID_KEY_PASSWORD: [tersembunyi]"
