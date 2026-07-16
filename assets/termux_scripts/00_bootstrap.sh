#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== PocketVibe Bootstrap ==="
echo "Menyiapkan environment..."
echo ""

# Setup storage - perlu persetujuan user
echo "[1/5] Mengatur akses penyimpanan..."
termux-setup-storage 2>/dev/null || true
sleep 3

echo "[2/5] Mengupdate package manager..."
pkg update -y && pkg upgrade -y

echo "[3/5] Memasang dependensi..."
pkg install -y nodejs-lts git ripgrep curl

echo "[4/5] Mengunduh script pendukung..."
mkdir -p ~/.pocketvibe
cd ~/.pocketvibe

BASE_URL="https://raw.githubusercontent.com/Hengki-Setiawan/PocketVibe-IDE/main/assets/termux_scripts"

for script in 01_install_opencode.sh 02_start_server.sh 03_healthcheck.sh; do
  echo "  Downloading $script..."
  for i in $(seq 1 3); do
    if curl -sL --connect-timeout 10 "$BASE_URL/$script" -o "$script"; then
      echo "  $script berhasil diunduh"
      break
    fi
    if [ "$i" -lt 3 ]; then
      echo "  Gagal, coba lagi ($i/3)..."
      sleep 3
    else
      echo "  Gagal mengunduh $script setelah 3 percobaan"
      exit 1
    fi
  done
done

chmod +x *.sh

echo "[5/5] Membuat folder project..."
mkdir -p ~/storage/shared/PocketVibeProjects
touch ~/storage/shared/.pocketvibe_ready

echo ""
echo "=== Bootstrap selesai! Kembali ke app PocketVibe. ==="
echo ""
echo "Langkah selanjutnya akan berjalan otomatis."
