#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# ZENX PASANG  v1.0  --  pintu masuk tunggal buat RF baru
#
# Dipakai:
#   curl -sL <REPO>/pasang.sh | sh -s seed
#   wget -qO- <REPO>/pasang.sh | sh -s seed
#
# Preset: seed / farm / market / gag1
#
# ------------------------------------------------------------
# KENAPA SKRIP INI ADA, bukan satu baris panjang:
#
# 1. MIRROR HARUS DISET DULU. Termux polos gak punya mirror kepilih, jadi
#    `pkg install` narik dari sumber campur dan versinya gak sepadan. Kejadian
#    nyata: libngtcp2 1.25.0 (butuh OpenSSL 3.6) ketemu OpenSSL 3.4.1 ->
#    curl mati total dengan pesan "CANNOT LINK EXECUTABLE ... cannot locate
#    symbol SSL_set_quic_tls_transport_params".
#    Yang bikin susah dilacak: `apt upgrade` bilang "0 upgraded" -- keliatan
#    gak ada masalah, padahal apt cuma gak punya sumber buat narik.
#
# 2. TIAP LANGKAH HARUS BISA BERHENTI DENGAN SEBAB JELAS. Di satu baris
#    ber-&&, kalau langkah ke-3 gagal yang keliatan cuma error langkah ke-5 --
#    dan orangnya ngutak-atik bagian yang salah.
#
# 3. curl DAN wget dua-duanya dicoba. Alat unduh itu jangan jadi titik gagal
#    tunggal -- kalau dua-duanya mati, gak ada jalan masuk lagi ke RF itu.
# ============================================================

REPO="https://raw.githubusercontent.com/alzafabocahbocah-boop/revsy/main"
MIRROR="https://packages-cf.termux.dev/apt/termux-main"

# ---------- warna (dimatiin kalau bukan terminal) ----------
if [ -t 1 ]; then
    M='\033[1;31m'; H='\033[1;32m'; K='\033[1;33m'
    B='\033[1;36m'; A='\033[1m';    N='\033[0m'
else
    M=''; H=''; K=''; B=''; A=''; N=''
fi

langkah=0
TOTAL=6

judul() {
    langkah=$((langkah + 1))
    printf "\n${B}[%d/%d] %s${N}\n" "$langkah" "$TOTAL" "$1"
}
ok()   { printf "  ${H}OK${N}   %s\n" "$1"; }
info() { printf "       %s\n" "$1"; }
warn() { printf "  ${K}!${N}    %s\n" "$1"; }

# gagal() SENGAJA nyebut apa yang harus dilakuin, bukan cuma "gagal".
# Skrip ini jalan di RF yang kadang dipegang orang lain -- pesan tanpa
# tindak lanjut cuma bikin dia nunggu.
gagal() {
    printf "\n  ${M}GAGAL${N}  %s\n" "$1"
    shift
    for baris in "$@"; do printf "         %s\n" "$baris"; done
    printf "\n"
    exit 1
}

# ---------- preset ----------
PRESET="$1"
[ -z "$PRESET" ] && PRESET="seed"

case "$PRESET" in
    seed|farm|market|gag1|hact|panen|campur|seed-arceus|farm-arceus|market-arceus|gag1-arceus|hact-arceus|panen-arceus|campur-arceus|upkg-arceus|hactotomatis-arceus|panen-arceus-market|up-arceus-market|upkg-arceus-market|up6kg-arceus|up6kg-arceus-market|up6kg-arceus-[1-9]|up6kg-arceus-[1-9]-market|uplevel-arceus|uplevel-arceus-[1-9]|uplevel-arceus-[1-9]-market) ;;
    *)
        gagal "Preset '$PRESET' gak dikenal." \
              "Yang ada: seed / farm / market / gag1 / hact / panen / campur  (+ suffix -arceus)" \
              "Contoh:  ... | sh -s campur-arceus"
        ;;
esac

printf "\n${A}=== ZENX PASANG -- preset: %s ===${N}\n" "$PRESET"

# ============================================================
judul "Cek lingkungan"
# ============================================================
if [ -z "$PREFIX" ]; then
    gagal "Ini bukan Termux (PREFIX kosong)." \
          "Skrip ini cuma buat Termux di Android."
fi
ok "Termux: $PREFIX"

# ============================================================
judul "Set mirror"
# ============================================================
# Ini langkah yang paling sering dilewat, dan akibatnya paling nyesatin --
# lihat catatan nomor 1 di atas.
SRC="$PREFIX/etc/apt/sources.list"
if grep -q "packages-cf.termux.dev" "$SRC" 2>/dev/null; then
    ok "Mirror udah keset"
else
    echo "deb $MIRROR stable main" > "$SRC" 2>/dev/null \
        || gagal "Gak bisa nulis $SRC" "Cek izin / ruang penyimpanan."
    ok "Mirror diset: packages-cf.termux.dev"
fi

# ============================================================
judul "Upgrade paket (agak lama, sabar)"
# ============================================================
apt update -y >/dev/null 2>&1 || warn "apt update ada keluhan -- dilanjut"

# full-upgrade, BUKAN upgrade: dia boleh buang paket yang bentrok. Itu yang
# dibutuhin buat kasus libngtcp2-vs-OpenSSL -- `upgrade` biasa nolak nyentuh
# paket yang perlu dibuang, jadi bentroknya gak pernah kelar.
# DEBIAN_FRONTEND + force-confnew: pertanyaan berkas config gak dijawab sama
# `-y`, dan kalau gak dijawab prosesnya nyangkut diem -- keliatan kayak hang.
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y \
    -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1

SISA=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
if [ "$SISA" -gt 1 ] 2>/dev/null; then
    warn "$SISA paket masih bisa diupgrade -- biasanya gak masalah"
else
    ok "Paket udah terkini"
fi

# ============================================================
judul "Pasang lua54 + alat unduh"
# ============================================================
apt install -y lua54 >/dev/null 2>&1
if ! command -v lua5.4 >/dev/null 2>&1; then
    gagal "lua5.4 gak kepasang." \
          "Coba manual:  apt install lua54 -y" \
          "Kalau nolak, mirror-nya mungkin gak kejangkau."
fi
ok "lua5.4 siap"

# curl & wget dua-duanya dipasang. Bukan boros -- satu bisa rusak sendiri
# (libngtcp2/OpenSSL), dan kalau gak ada cadangannya RF-nya gak bisa
# diapa-apain dari jauh.
apt install -y curl wget openssl >/dev/null 2>&1

# sqlite3: WAJIB buat fitur cookie (zenx login, auto-setor cookie ke panel).
# Tanpa ini, worker baca cookie -> "sqlite3 not found" -> cookie gak masuk panel.
apt install -y sqlite >/dev/null 2>&1

# ---- dites BENERAN JALAN, bukan cuma dicek ada berkasnya ----
# Kasus lapangan persisnya begitu: berkasnya ada, `command -v` nemu, tapi
# begitu dijalanin langsung gagal link. Jadi `command -v` gak cukup.
#
# Polanya SPESIFIK ("curl <angka>" / "Wget <angka>"), bukan cuma nyari kata
# "curl"/"wget". Percobaan pertama pakai `grep -qi wget` -- dan itu KENA sama
# pesan error `CANNOT LINK EXECUTABLE ".../bin/wget"`, karena kata "wget" ada
# di jalur berkasnya. Jadi wget rusak dianggap sehat, lalu gagal di langkah
# berikutnya dengan pesan yang gak nyambung ("unduhan kosong").
UNDUH=""
if curl --version 2>&1 | grep -q "^curl [0-9]"; then
    UNDUH="curl"
    ok "curl jalan: $(curl --version 2>/dev/null | head -1 | cut -d' ' -f1-2)"
elif wget --version 2>&1 | grep -q "Wget [0-9]"; then
    UNDUH="wget"
    warn "curl RUSAK -> pakai wget"
    info "$(curl --version 2>&1 | head -1 | cut -c1-70)"
    ok "wget jalan"
else
    gagal "curl DAN wget dua-duanya gak jalan." \
          "Biasanya OpenSSL ketinggalan versi. Coba:" \
          "  apt install -y --reinstall openssl libnghttp3 libngtcp2 curl" \
          "Kalau tetep, install ulang Termux (config ada di panel, gak ilang)."
fi

# ============================================================
judul "Unduh worker"
# ============================================================
BARU="$HOME/zenx_worker.baru"
URL="$REPO/zenx_worker.lua?v=$(date +%s)"   # ?v= biar gak kena cache GitHub

rm -f "$BARU"
if [ "$UNDUH" = "curl" ]; then
    curl -fsSL -H "Cache-Control: no-cache" "$URL" -o "$BARU" 2>/dev/null
else
    wget -q --no-cache -O "$BARU" "$URL" 2>/dev/null
fi

# Isinya diperiksa, bukan cuma "unduhannya sukses". GitHub bisa balikin
# halaman 404 dengan status 200 -- dan berkas HTML yang disimpen sebagai .lua
# itu gagal belakangan, di tempat yang jauh dari sebabnya.
if [ ! -s "$BARU" ]; then
    gagal "Unduhan kosong." \
          "URL: $URL" \
          "Cek internet, atau worker-nya belum di-push ke repo."
fi
if ! head -20 "$BARU" 2>/dev/null | grep -q "ZENX WORKER"; then
    gagal "Yang keunduh BUKAN worker." \
          "Kemungkinan: berkasnya belum ada di repo (GitHub balikin halaman 404)." \
          "Cek: $REPO/zenx_worker.lua" \
          "Isi awal yang keunduh:" \
          "  $(head -1 "$BARU" | cut -c1-60)"
fi

mv "$BARU" "$HOME/zenx_worker.lua"
VER=$(grep -m1 'local VERSION' "$HOME/zenx_worker.lua" | cut -d'"' -f2)
ok "Worker keunduh: ${VER:-?}"

# ============================================================
# v9.263: preset *-arceus -> tulis loader ke Autoexec Arceus SEKALI di sini.
# Arceus auto-run file .lua di /sdcard/Arceus X/Autoexec/ tiap join (kebukti).
# Isinya 1 baris: fetch market dari ronihub + loadstring. Statis, gak berubah.
# ============================================================
case "$PRESET" in
    *arceus*)
        printf "\n${B}[+] Tulis loader Arceus (auto-exe script)${N}\n"
        AX_DIR="/sdcard/Arceus X/Autoexec"
        AX_LOADER="$AX_DIR/zenx.lua"
        # v9.291: pilih script ronihub sesuai preset. hact-arceus -> hact,
        # panen-arceus -> panen, sisanya -> market.
        case "$PRESET" in
            hact-arceus)   RONIHUB_SC="hact" ;;
            panen-arceus)  RONIHUB_SC="panen" ;;
            panen-arceus-market)  RONIHUB_SC="panen" ;;
            up-arceus-market)     RONIHUB_SC="upkg" ;;
            upkg-arceus-market)   RONIHUB_SC="upkg" ;;
            up6kg-arceus)         RONIHUB_SC="up6kg" ;;
            up6kg-arceus-market)  RONIHUB_SC="up6kg" ;;
            up6kg-arceus-[1-9])         RONIHUB_SC="up6kg" ;;
            up6kg-arceus-[1-9]-market)  RONIHUB_SC="up6kg" ;;
            uplevel-arceus)         RONIHUB_SC="uplevel" ;;
            uplevel-arceus-[1-9])   RONIHUB_SC="uplevel" ;;
            uplevel-arceus-[1-9]-market)  RONIHUB_SC="uplevel" ;;
            upkg-arceus)   RONIHUB_SC="upkg" ;;
            hactotomatis-arceus) RONIHUB_SC="hact" ;;
            campur-arceus) RONIHUB_SC="__campur__" ;;
            *)             RONIHUB_SC="market" ;;
        esac
        # campur: loader pinter dari revsy (pilih script per akun via /sc-get panel). else: script fixed ronihub.
        if [ "$RONIHUB_SC" = "__campur__" ]; then
            MARKET_URL="https://raw.githubusercontent.com/alzafabocahbocah-boop/revsy/main/zenx-loader.lua"
            SC_LABEL="campur (loader pinter -- script per akun dari panel)"
        else
            MARKET_URL="https://raw.githubusercontent.com/alzafabocahbocah-boop/ronihub/main/$RONIHUB_SC"
            SC_LABEL="$RONIHUB_SC"
        fi
        su -c "mkdir -p \"$AX_DIR\"; printf 'loadstring(game:HttpGet(\"%s\"))()' \"$MARKET_URL\" > \"$AX_LOADER\"" 2>/dev/null
        # cek beneran ketulis
        AX_CEK=$(su -c "cat \"$AX_LOADER\" 2>/dev/null" 2>/dev/null)
        if printf '%s' "$AX_CEK" | grep -q "HttpGet"; then
            ok "Loader Arceus ketulis: $AX_LOADER ($SC_LABEL)"
            info "$SC_LABEL auto-nyala tiap Arceus join."
        else
            warn "Loader Arceus GAGAL ketulis (cek akses su / folder Arceus X ada)."
            info "Manual:  su -c 'echo ... > \"$AX_LOADER\"'"
        fi
        ;;
esac

# ============================================================
judul "Setup otomatis"
# ============================================================
info "Preset '$PRESET' -- nol pertanyaan."
info "Nomor tim ditarik dari panel, jadi gak bentrok sama RF lain."
printf "\n"

exec lua5.4 "$HOME/zenx_worker.lua" pasang "$PRESET"