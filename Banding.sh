#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# BANDING  v1.0 -- bandingin data client yang LOGIN vs yang KOSONG
#
# Pakai:  sh banding.sh <client-login> <client-kosong>
# Contoh: sh banding.sh seiyr seiyq
#
# ------------------------------------------------------------
# KENAPA INI DULU, sebelum nyoba nyuntik:
#
# `zenx cookie` nemu token di lib/libroblox.so -- tapi berkas itu 72 MB dan
# isinya data internal Roblox, BUKAN penyimpanan cookie. Jadi token yang
# aktif ada di suatu tempat yang belum ketauan.
#
# Nyuntik ke tempat yang salah itu dua-duanya buruk: gak bikin login, DAN
# bisa ngerusak client. Jadi mendingan liat dulu login itu NGUBAH APA.
#
# Skrip ini CUMA MEMBACA. Gak ada yang ditulis, disalin, atau dihapus.
# ============================================================

A="$1"   # client yang UDAH login
B="$2"   # client yang KOSONG

if [ -z "$A" ] || [ -z "$B" ]; then
    echo "Pakai: sh banding.sh <client-login> <client-kosong>"
    echo "Contoh: sh banding.sh seiyr seiyq"
    exit 1
fi

PA="com.roblox.$A"
PB="com.roblox.$B"

echo "=========================================="
echo " BANDING  $A (login)  vs  $B (kosong)"
echo "=========================================="

for P in "$PA" "$PB"; do
    if ! su -c "test -d /data/data/$P" 2>/dev/null; then
        echo "GAGAL: /data/data/$P gak ada (root jalan? nama client bener?)"
        exit 1
    fi
done

# ---------- 1. folder tingkat atas ----------
echo ""
echo "--- FOLDER TINGKAT ATAS ---"
echo "  $A:"
su -c "ls /data/data/$PA/" 2>/dev/null | sed 's/^/    /'
echo "  $B:"
su -c "ls /data/data/$PB/" 2>/dev/null | sed 's/^/    /'

# ---------- 2. berkas yang CUMA ADA di yang login ----------
# Ini inti pengukurannya: berkas yang muncul HANYA setelah login itu
# kandidat kuat tempat tokennya. lib/ dan cache/ dilewat -- lib itu isi
# aplikasi (sama di semua client), cache berubah terus dan gak nyimpen login.
echo ""
echo "--- BERKAS YANG CUMA ADA DI '$A' (login) ---"
su -c "find /data/data/$PA -type f -not -path '*/lib/*' -not -path '*/cache/*' 2>/dev/null" \
    | sed "s|/data/data/$PA/||" | sort > /tmp/_a.txt
su -c "find /data/data/$PB -type f -not -path '*/lib/*' -not -path '*/cache/*' 2>/dev/null" \
    | sed "s|/data/data/$PB/||" | sort > /tmp/_b.txt
comm -23 /tmp/_a.txt /tmp/_b.txt | head -40 | sed 's/^/    /'
NA=$(wc -l < /tmp/_a.txt); NB=$(wc -l < /tmp/_b.txt)
echo "    ($NA berkas di $A, $NB di $B)"

# ---------- 3. yang ada di dua-duanya tapi ISINYA beda ukuran ----------
echo ""
echo "--- ADA DI DUA-DUANYA, TAPI UKURAN BEDA ---"
comm -12 /tmp/_a.txt /tmp/_b.txt | while read -r f; do
    SA=$(su -c "stat -c %s '/data/data/$PA/$f'" 2>/dev/null)
    SB=$(su -c "stat -c %s '/data/data/$PB/$f'" 2>/dev/null)
    [ "$SA" != "$SB" ] && echo "    $f   $A=$SA  $B=$SB"
done | head -25

# ---------- 4. di mana token ROBLOSECURITY nongol ----------
# Dipisah dari daftar di atas: yang penting bukan cuma "berkas apa yang beda",
# tapi "berkas mana yang BENERAN NYIMPEN token".
echo ""
echo "--- BERKAS BER-ROBLOSECURITY di '$A' ---"
su -c "grep -rla ROBLOSECURITY /data/data/$PA/ 2>/dev/null" | while read -r f; do
    SZ=$(su -c "stat -c %s '$f'" 2>/dev/null)
    echo "    $f  ($SZ byte)"
done

echo ""
echo "--- BERKAS BER-ROBLOSECURITY di '$B' ---"
HASIL=$(su -c "grep -rla ROBLOSECURITY /data/data/$PB/ 2>/dev/null")
if [ -z "$HASIL" ]; then
    echo "    (gak ada -- wajar kalau belum pernah login)"
else
    echo "$HASIL" | sed 's/^/    /'
fi

# ---------- 5. shared_prefs: paling sering dipakai nyimpen sesi ----------
echo ""
echo "--- shared_prefs ---"
echo "  $A:"
su -c "ls -la /data/data/$PA/shared_prefs/ 2>/dev/null" | tail -n +2 | awk '{print "    "$5" B  "$NF}'
echo "  $B:"
su -c "ls -la /data/data/$PB/shared_prefs/ 2>/dev/null" | tail -n +2 | awk '{print "    "$5" B  "$NF}'

rm -f /tmp/_a.txt /tmp/_b.txt
echo ""
echo "=========================================="
echo " Selesai. Yang paling penting: bagian 2 & 4."
echo " Berkas yang CUMA ada di client login DAN ngandung"
echo " ROBLOSECURITY -- itu kandidat tempat tokennya."
echo "=========================================="
