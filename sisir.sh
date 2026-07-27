#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# PENYISIR LOGIN  v1.0 -- petakan SEMUA yang beda antara client
#                         login vs kosong. Buat mecahin cara inject.
#
# Pakai:  sh sisir_login.sh <client-login> <client-kosong>
#
# ------------------------------------------------------------
# BEDANYA dari banding.sh: ini GAK NYARING apa-apa.
# banding.sh cuma liat tempat yang udah gua tebak (app_webview, ROBLOSECURITY).
# Yang itu bikin kita kelewat -- karena kalau tebakannya salah, kita gak
# liat yang bener.
#
# Ini nyatet SEMUA: tiap berkas yang cuma ada di yang login, tiap berkas
# yang ukurannya beda, DAN isinya di-hash biar ketauan yang berubah walau
# ukurannya sama. Gak ada yang disaring, gak ada yang ditebak.
#
# Dipakai buat NGUKUR, bukan ngubah. Cuma membaca.
# ============================================================

A="$1"; B="$2"
if [ -z "$A" ] || [ -z "$B" ]; then
    echo "Pakai: sh sisir_login.sh <client-login> <client-kosong>"
    echo "Contoh: sh sisir_login.sh seiyv seiyw"
    exit 1
fi
PA="com.roblox.$A"; PB="com.roblox.$B"
OUT="$HOME/sisir_$A.txt"

for P in "$PA" "$PB"; do
    su -c "test -d /data/data/$P" 2>/dev/null || { echo "GAGAL: $P gak ada"; exit 1; }
done

{
echo "=================================================="
echo " SISIR LOGIN  $A (login)  vs  $B (kosong)"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="

# ---------- daftar semua berkas + ukuran + hash ----------
# lib/ dilewat (72 MB, sama di semua). cache/code_cache dilewat (berubah
# terus, gak nyimpen login). Sisanya SEMUA dicatet.
for TAG in A B; do
    P="$PA"; [ "$TAG" = "B" ] && P="$PB"
    su -c "find /data/data/$P -type f -not -path '*/lib/*' -not -path '*/cache/*' -not -path '*/code_cache/*' -exec md5sum {} + 2>/dev/null" \
        | sed "s|/data/data/$P/||" | sort -k2 > "$HOME/_sis_$TAG.txt"
done

echo ""
echo "--- BERKAS YANG CUMA ADA DI '$A' (login) ---"
# <(...) itu bashism -- gak jalan di sh Termux (dash). Pakai berkas sementara.
awk '{print $2}' "$HOME/_sis_A.txt" > "$HOME/_nm_A.txt"
awk '{print $2}' "$HOME/_sis_B.txt" > "$HOME/_nm_B.txt"
comm -23 "$HOME/_nm_A.txt" "$HOME/_nm_B.txt" \
    | while read -r f; do
        SZ=$(su -c "stat -c %s '/data/data/$PA/$f'" 2>/dev/null)
        echo "    [$SZ B]  $f"
    done

echo ""
echo "--- ADA DI DUA-DUANYA TAPI ISINYA BEDA (hash beda) ---"
# gabung berdasar nama, tandai yang hash-nya beda
join -j2 "$HOME/_sis_A.txt" "$HOME/_sis_B.txt" 2>/dev/null \
    | awk '$2 != $3 {print "    "$1}' | while read -r f; do
        f=$(echo "$f" | xargs)
        SA=$(su -c "stat -c %s '/data/data/$PA/$f'" 2>/dev/null)
        SB=$(su -c "stat -c %s '/data/data/$PB/$f'" 2>/dev/null)
        echo "    $f   login=$SA  kosong=$SB"
    done

echo ""
echo "--- SEMUA TEMPAT TOKEN NONGOL (login) ---"
# --exclude lib: kata ROBLOSECURITY ketanam di kode Roblox, positif palsu
su -c "grep -rla 'WARNING:-DO-NOT-SHARE' /data/data/$PA/ --exclude-dir=lib 2>/dev/null" \
    | while read -r f; do
        SZ=$(su -c "stat -c %s '$f'" 2>/dev/null)
        echo "    [$SZ B]  $(echo "$f" | sed "s|/data/data/$PA/||")"
    done

echo ""
echo "--- CARI DI /sdcard (Delta sering naruh config di sini) ---"
su -c "find /sdcard -maxdepth 4 \( -iname '*delta*' -o -iname '*cookie*' -o -iname '*roblox*' \) 2>/dev/null | head -30" \
    | sed 's/^/    /'

rm -f "$HOME/_sis_A.txt" "$HOME/_sis_B.txt" "$HOME/_nm_A.txt" "$HOME/_nm_B.txt"
echo ""
echo "=================================================="
echo " Hasil ke: $OUT"
echo "=================================================="
} | tee "$OUT"
