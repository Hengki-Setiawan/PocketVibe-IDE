#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== Memasang OpenCode AI ==="
echo ""
echo "PERHATIAN: Proses ini membutuhkan:"
echo "  - ~2GB ruang kosong"
echo "  - Koneksi internet stabil"
echo "  - Waktu 3-10 menit"
echo ""

echo "[1/3] Memasang proot-distro..."
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" proot-distro

echo "[2/3] Menginstall Ubuntu environment..."
proot-distro install ubuntu 2>&1 || {
  echo "proot-distro install ubuntu gagal."
  echo "Coba metode alternatif..."
  proot-distro install ubuntu 2>&1
  exit 1
}

echo "[3/3] Memasang OpenCode di Ubuntu..."
proot-distro login ubuntu -- bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt update -qq 2>/dev/null
  apt install -y -qq -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' curl unzip > /dev/null 2>&1
  curl -fsSL https://opencode.ai/install | bash 2>&1
"

echo ""
echo "=== OpenCode AI berhasil terpasang! ==="
