#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== PocketVibe Bootstrap ==="
echo "Menyiapkan environment..."
echo ""

# Setup storage - perlu persetujuan user
echo "[1/6] Mengatur akses penyimpanan..."
termux-setup-storage 2>/dev/null || true
sleep 3

echo "[2/6] Mengupdate package manager..."
# DEBIAN_FRONTEND=noninteractive suppresses dpkg conffile prompts
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "[3/6] Mengatur izin aplikasi eksternal..."
mkdir -p ~/.termux
if ! grep -q "allow-external-apps" ~/.termux/termux.properties 2>/dev/null; then
  echo "allow-external-apps=true" >> ~/.termux/termux.properties
  echo "  Izin eksternal diaktifkan"
else
  # Pastikan sudah true
  sed -i 's/^allow-external-apps=.*/allow-external-apps=true/' ~/.termux/termux.properties
  echo "  Izin eksternal sudah aktif"
fi

echo "[4/6] Memasang dependensi..."
apt install -y nodejs-lts git ripgrep curl

echo "  Mengunduh script pendukung..."
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

echo "[5/6] Membuat folder project..."
mkdir -p ~/storage/shared/PocketVibeProjects

# Beri tahu PocketVibe bahwa bootstrap selesai
# Tulis di Termux home (diperiksa via bridge checkFileExists)
touch "$HOME/.pocketvibe_ready"
# Juga tulis di shared storage (fallback)
touch ~/storage/shared/.pocketvibe_ready 2>/dev/null || true

echo "[6/6] Membuka izin RUN_COMMAND untuk PocketVibe..."
# Izin ini diperlukan agar PocketVibe bisa mengirim perintah ke Termux
termux-notification-command 2>/dev/null || true
echo ""
echo ">>> NOTICE: Jika ada notifikasi izin, silakan tap 'Allow' <<<"
echo ">>> Jika tidak ada, buka Termux -> tap & tahan notifikasi -> Additional permissions -> izinkan <<<"
sleep 2

echo ""
echo "=== Bootstrap selesai! Kembali ke app PocketVibe. ==="
echo ""
echo "Langkah selanjutnya akan berjalan otomatis."
