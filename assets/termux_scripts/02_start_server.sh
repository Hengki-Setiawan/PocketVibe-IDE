#!/data/data/com.termux/files/usr/bin/bash

PORT="${POCKETVIBE_PORT:-4096}"

# Cek apakah server sudah berjalan
if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/doc" 2>/dev/null | grep -q "200"; then
  echo "Server sudah berjalan di port $PORT."
  exit 0
fi

# Cek apakah port sudah dipakai
if command -v lsof > /dev/null 2>&1; then
  if lsof -i ":$PORT" > /dev/null 2>&1; then
    echo "Port $PORT sudah dipakai oleh proses lain."
  fi
fi

echo "Memulai opencode serve di port $PORT..."

proot-distro login ubuntu -- bash -c "
  cd ~/storage/shared/PocketVibeProjects 2>/dev/null || cd ~
  nohup opencode serve --hostname 127.0.0.1 --port $PORT > ~/opencode.log 2>&1 &
  disown
" 2>&1

echo "Server dimulai di background. Tunggu beberapa saat..."
