#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# JEPRET  v1.0 -- foto keadaan SATU client, buat lacak apa yang
#                 berubah pas Pandora ganti akun.
#
# Ide: satu client, dua waktu. Foto pas akun A, Pandora pindah ke
# akun B, foto lagi. Yang BEDA di antara dua foto = tempat cookie ditulis.
# Gak perlu client kedua, gak ada bentrok akun.
#
# Pakai:
#   sh jepret.sh <client> sebelum     # SEBELUM Pandora ganti akun
#   ( -- pindah akun di Pandora, tunggu signed in -- )
#   sh jepret.sh <client> sesudah     # SESUDAH ganti
#   sh jepret.sh <client> beda        # tampilin apa yang berubah
#
# Contoh:
#   sh jepret.sh clienu sebelum
#   sh jepret.sh clienu sesudah
#   sh jepret.sh clienu beda
#
# CUMA MEMBACA. Gak nulis apa-apa ke client.
# ============================================================

C="$1"; FASE="$2"
if [ -z "$C" ] || [ -z "$FASE" ]; then
    echo "Pakai:"
    echo "  sh jepret.sh <client> sebelum"
    echo "  sh jepret.sh <client> sesudah"
    echo "  sh jepret.sh <client> beda"
    exit 1
fi
P="com.roblox.$C"
su -c "test -d /data/data/$P" 2>/dev/null || { echo "GAGAL: $P gak ada"; exit 1; }

SNAP="$HOME/jepret_${C}"

ambil() {
    # tiap berkas + ukuran + hash + waktu-ubah. lib/cache dilewat.
    # Yang penting: HASH -- biar ketauan isi berubah walau ukuran & nama sama.
    su -c "find /data/data/$P -type f \
        -not -path '*/lib/*' -not -path '*/cache/*' -not -path '*/code_cache/*' \
        -exec md5sum {} + 2>/dev/null" \
        | sed "s|/data/data/$P/||" | sort -k2
}

case "$FASE" in
  sebelum)
    ambil > "${SNAP}_sebelum.txt"
    N=$(wc -l < "${SNAP}_sebelum.txt")
    echo "Foto SEBELUM diambil: $N berkas."
    echo "Sekarang pindah akun di Pandora, tunggu 'signed in'."
    echo "Terus jalanin:  sh jepret.sh $C sesudah"
    ;;
  sesudah)
    if [ ! -f "${SNAP}_sebelum.txt" ]; then
        echo "GAGAL: foto 'sebelum' belum ada. Jalanin dulu:"
        echo "  sh jepret.sh $C sebelum"
        exit 1
    fi
    ambil > "${SNAP}_sesudah.txt"
    N=$(wc -l < "${SNAP}_sesudah.txt")
    echo "Foto SESUDAH diambil: $N berkas."
    echo "Liat bedanya:  sh jepret.sh $C beda"
    ;;
  beda)
    if [ ! -f "${SNAP}_sebelum.txt" ] || [ ! -f "${SNAP}_sesudah.txt" ]; then
        echo "GAGAL: butuh dua foto dulu (sebelum & sesudah)."
        exit 1
    fi
    {
    echo "=================================================="
    echo " BEDA di $C -- sebelum vs sesudah ganti akun"
    echo "=================================================="

    # nama berkas saja, buat cari yang muncul/hilang
    awk '{print $2}' "${SNAP}_sebelum.txt" > "${SNAP}_nb.txt"
    awk '{print $2}' "${SNAP}_sesudah.txt" > "${SNAP}_na.txt"

    echo ""
    echo "--- BERKAS BARU (cuma ada SESUDAH) ---"
    comm -13 "${SNAP}_nb.txt" "${SNAP}_na.txt" | sed 's/^/    + /'

    echo ""
    echo "--- BERKAS HILANG (cuma ada SEBELUM) ---"
    comm -23 "${SNAP}_nb.txt" "${SNAP}_na.txt" | sed 's/^/    - /'

    echo ""
    echo "--- ISINYA BERUBAH (nama sama, hash beda) ---"
    # ini bagian PALING PENTING: berkas yang ditimpa pas ganti akun
    join -j2 "${SNAP}_sebelum.txt" "${SNAP}_sesudah.txt" 2>/dev/null \
        | awk '$2 != $3 {print $1}' | while read -r f; do
            SZ=$(su -c "stat -c %s '/data/data/$P/$f'" 2>/dev/null)
            echo "    ~ [$SZ B]  $f"
        done

    echo ""
    echo "--- DARI YANG BERUBAH, MANA YANG NGANDUNG COOKIE ---"
    join -j2 "${SNAP}_sebelum.txt" "${SNAP}_sesudah.txt" 2>/dev/null \
        | awk '$2 != $3 {print $1}' | while read -r f; do
            if su -c "grep -la 'WARNING:-DO-NOT-SHARE' '/data/data/$P/$f'" 2>/dev/null >/dev/null; then
                echo "    >>> $f  <-- INI kemungkinan tempat cookie ditulis"
            fi
        done

    rm -f "${SNAP}_nb.txt" "${SNAP}_na.txt"
    echo ""
    echo "=================================================="
    echo " Yang penting: bagian 'ISINYA BERUBAH' + 'NGANDUNG COOKIE'."
    echo " Berkas yang ditimpa DAN punya cookie = tempat inject."
    echo "=================================================="
    } | tee "$HOME/jepret_${C}_hasil.txt"
    ;;
  *)
    echo "Fase gak dikenal: $FASE (pakai: sebelum / sesudah / beda)"
    exit 1
    ;;
esac
