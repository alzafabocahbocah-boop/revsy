#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# PANTAU  v1.0 -- rekam terus perubahan berkas satu client.
#                 Buat nangkep apa yang Pandora ubah pas ganti akun,
#                 TANPA harus pas-pasan timing manual.
#
# Pakai:  sh pantau.sh <client> [detik]
#   detik = lama mantau (default 90)
#
# Contoh:
#   sh pantau.sh client 90
#   ( -- selama jalan, ganti akun di Pandora kapan aja -- )
#
# Tiap 3 detik dia foto keadaan, bandingin sama foto sebelumnya. Begitu
# ada berkas yang berubah/muncul, langsung dicatet + jam-nya. Jadi pas
# Pandora inject, lo liat PERSIS berkas apa yang ditulis dan kapan.
#
# CUMA MEMBACA. Gak nulis apa-apa ke client.
# ============================================================

C="$1"
DETIK="${2:-90}"
if [ -z "$C" ]; then
    echo "Pakai: sh pantau.sh <client> [detik]"
    echo "Contoh: sh pantau.sh client 90"
    exit 1
fi
P="com.roblox.$C"
su -c "test -d /data/data/$P" 2>/dev/null || { echo "GAGAL: $P gak ada"; exit 1; }

OUT="$HOME/pantau_${C}.txt"
PREV="$HOME/_pantau_prev.txt"
CUR="$HOME/_pantau_cur.txt"
JEDA=3

foto() {
    su -c "find /data/data/$P -type f \
        -not -path '*/lib/*' -not -path '*/cache/*' -not -path '*/code_cache/*' \
        -exec md5sum {} + 2>/dev/null" \
        | sed "s|/data/data/$P/||" | sort -k2
}

echo "==================================================" | tee "$OUT"
echo " PANTAU $C -- $DETIK detik, cek tiap $JEDA detik" | tee -a "$OUT"
echo " Ganti akun di Pandora sekarang. Perubahan direkam otomatis." | tee -a "$OUT"
echo "==================================================" | tee -a "$OUT"

foto > "$PREV"
AWAL=$(su -c "date +%s")
PUTARAN=0

while :; do
    SKRG=$(su -c "date +%s")
    LEWAT=$((SKRG - AWAL))
    [ "$LEWAT" -ge "$DETIK" ] && break

    sleep "$JEDA"
    PUTARAN=$((PUTARAN + 1))
    foto > "$CUR"

    # ada beda?
    if ! cmp -s "$PREV" "$CUR"; then
        JAM=$(date '+%H:%M:%S')
        echo "" | tee -a "$OUT"
        echo "[$JAM  +${LEWAT}s] ADA PERUBAHAN:" | tee -a "$OUT"

        # nama saja buat cari muncul/hilang
        awk '{print $2}' "$PREV" > "$HOME/_pp.txt"
        awk '{print $2}' "$CUR"  > "$HOME/_pc.txt"

        comm -13 "$HOME/_pp.txt" "$HOME/_pc.txt" | while read -r f; do
            echo "    + BARU    $f" | tee -a "$OUT"
        done
        comm -23 "$HOME/_pp.txt" "$HOME/_pc.txt" | while read -r f; do
            echo "    - HILANG  $f" | tee -a "$OUT"
        done
        # isi berubah (nama sama, hash beda)
        join -j2 "$PREV" "$CUR" 2>/dev/null | awk '$2 != $3 {print $1}' | while read -r f; do
            PUNYA=""
            su -c "grep -la 'WARNING:-DO-NOT-SHARE' '/data/data/$P/$f'" 2>/dev/null >/dev/null \
                && PUNYA="  <<< ADA COOKIE"
            echo "    ~ ISI     $f$PUNYA" | tee -a "$OUT"
        done
        rm -f "$HOME/_pp.txt" "$HOME/_pc.txt"

        cp "$CUR" "$PREV"
    fi
done

rm -f "$PREV" "$CUR"
echo "" | tee -a "$OUT"
echo "==================================================" | tee -a "$OUT"
echo " Selesai. Berkas yang ~ISI dan ADA COOKIE = tempat inject." | tee -a "$OUT"
echo " Hasil: $OUT" | tee -a "$OUT"
echo "==================================================" | tee -a "$OUT"
