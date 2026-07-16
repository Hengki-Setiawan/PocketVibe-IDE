#!/bin/bash
set -e

echo "=== CI: Verify Termux Pipeline ==="

adb push assets/termux_scripts/00_bootstrap.sh /sdcard/pocketvibe_bootstrap.sh

adb shell am startservice \
  -n com.termux/com.termux.app.RunCommandService \
  -a com.termux.RUN_COMMAND \
  --es com.termux.RUN_COMMAND_PATH '/data/data/com.termux/files/usr/bin/bash' \
  --esa com.termux.RUN_COMMAND_ARGUMENTS '/sdcard/pocketvibe_bootstrap.sh' \
  --ez com.termux.RUN_COMMAND_BACKGROUND true

echo "Menunggu bootstrap (polling)..."
adb forward tcp:4096 tcp:4096

MAX_RETRIES=30
RETRY_DELAY=5

for i in $(seq 1 $MAX_RETRIES); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:4096/doc 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "Server HTTP status: $HTTP_CODE"
    echo "=== Pipeline verifikasi BERHASIL ==="
    exit 0
  fi
  echo "Percobaan $i/$MAX_RETRIES - Server belum siap (HTTP $HTTP_CODE), menunggu ${RETRY_DELAY}s..."
  sleep $RETRY_DELAY
done

echo "=== Pipeline verifikasi GAGAL setelah $MAX_RETRIES percobaan ==="
echo "Logcat dump:"
adb logcat -d | grep -i "RunCommand" | tail -30
adb logcat -d | grep -i "termux" | tail -30
exit 1
