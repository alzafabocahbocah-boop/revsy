#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# PANTAU WINDOW  v1.0 -- rekam perubahan state jendela client tiap 2 detik.
#                        Buat nangkep APA yang berubah pas bubble di-pencet
#                        manual sampai expand.
#
# Pakai:  sh pantau_window.sh <client> [detik]
#   client = huruf/nama (mis. seiyr atau r)
#   detik  = lama pantau (default 30)
#
# Cara: jalanin ini, TERUS pencet bubble-nya manual. Alat ini rekam
# bounds + stack + visible tiap 2 detik. Begitu bubble expand, keliatan
# nilai APA yang berubah (bounds? stack? visible?) -- itu petunjuk perintah
# yang bikin expand.
#
# CUMA MEMBACA. Gak ngutak-atik apa-apa.
# ============================================================

C="$1"; DETIK="${2:-30}"
[ -z "$C" ] && { echo "Pakai: sh pantau_window.sh <client> [detik]"; exit 1; }
# terima huruf tunggal (seiy<huruf>) atau nama penuh
case "$C" in
  *.*) PKG="$C" ;;
  ?)   PKG="com.roblox.seiy$C" ;;
  *)   PKG="com.roblox.$C" ;;
esac

echo "=================================================="
echo " PANTAU WINDOW  $PKG  -- $DETIK detik, cek tiap 2s"
echo " SEKARANG: pencet bubble-nya manual. Perubahan direkam."
echo "=================================================="

potret() {
  # baris stack list buat client ini -- ambil bounds, stackId, visible
  su -c 'am stack list 2>&1' | grep "$PKG" | head -1 \
    | grep -oE 'bounds=\[[0-9,]+\]\[[0-9,]+\]|StackId=[0-9]+|visible=[a-z]+'
}

AWAL=$(su -c 'date +%s')
LAST=""
while :; do
  NOW=$(su -c 'date +%s')
  LEWAT=$((NOW - AWAL))
  [ "$LEWAT" -ge "$DETIK" ] && break

  CUR=$(potret | tr '\n' ' ')
  if [ "$CUR" != "$LAST" ]; then
    echo "[+${LEWAT}s] $CUR"
    LAST="$CUR"
  fi
  sleep 2
done
echo "=================================================="
echo " selesai. Baris yang BERUBAH pas lo pencet = petunjuk."
echo "=================================================="#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# PANTAU WINDOW  v1.0 -- rekam perubahan state jendela client tiap 2 detik.
#                        Buat nangkep APA yang berubah pas bubble di-pencet
#                        manual sampai expand.
#
# Pakai:  sh pantau_window.sh <client> [detik]
#   client = huruf/nama (mis. seiyr atau r)
#   detik  = lama pantau (default 30)
#
# Cara: jalanin ini, TERUS pencet bubble-nya manual. Alat ini rekam
# bounds + stack + visible tiap 2 detik. Begitu bubble expand, keliatan
# nilai APA yang berubah (bounds? stack? visible?) -- itu petunjuk perintah
# yang bikin expand.
#
# CUMA MEMBACA. Gak ngutak-atik apa-apa.
# ============================================================

C="$1"; DETIK="${2:-30}"
[ -z "$C" ] && { echo "Pakai: sh pantau_window.sh <client> [detik]"; exit 1; }
# terima huruf tunggal (seiy<huruf>) atau nama penuh
case "$C" in
  *.*) PKG="$C" ;;
  ?)   PKG="com.roblox.seiy$C" ;;
  *)   PKG="com.roblox.$C" ;;
esac

echo "=================================================="
echo " PANTAU WINDOW  $PKG  -- $DETIK detik, cek tiap 2s"
echo " SEKARANG: pencet bubble-nya manual. Perubahan direkam."
echo "=================================================="

potret() {
  # baris stack list buat client ini -- ambil bounds, stackId, visible
  su -c 'am stack list 2>&1' | grep "$PKG" | head -1 \
    | grep -oE 'bounds=\[[0-9,]+\]\[[0-9,]+\]|StackId=[0-9]+|visible=[a-z]+'
}

AWAL=$(su -c 'date +%s')
LAST=""
while :; do
  NOW=$(su -c 'date +%s')
  LEWAT=$((NOW - AWAL))
  [ "$LEWAT" -ge "$DETIK" ] && break

  CUR=$(potret | tr '\n' ' ')
  if [ "$CUR" != "$LAST" ]; then
    echo "[+${LEWAT}s] $CUR"
    LAST="$CUR"
  fi
  sleep 2
done
echo "=================================================="
echo " selesai. Baris yang BERUBAH pas lo pencet = petunjuk."
echo "=================================================="
