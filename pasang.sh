#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# ZENX — PASANG SEKALI JALAN
#
# Buat RedFinger BARU. Dari Termux polos sampai worker jalan,
# cukup SATU perintah -- gak usah pkg install satu-satu, gak usah
# copy file dari /sdcard manual.
#
# Cara pakai (tempel di Termux):
#   curl -sL https://raw.githubusercontent.com/alzafabocahbocah-boop/revsy/main/pasang.sh | sh
#
# Kalau curl belum ada:
#   pkg install curl -y && curl -sL <url di atas> | sh
# ============================================================

REPO="https://raw.githubusercontent.com/alzafabocahbocah-boop/revsy/main"
WORKER="$HOME/zenx_worker.lua"

H='\033[1;36m'; OK='\033[0;32m'; W='\033[0;33m'; E='\033[0;31m'; N='\033[0m'
lapor()  { printf "${H}==>${N} %s\n" "$1"; }
sukses() { printf "${OK}OK ${N} %s\n" "$1"; }
warn()   { printf "${W}!  ${N} %s\n" "$1"; }
gagal()  { printf "${E}ERR${N} %s\n" "$1"; exit 1; }

printf "\n${H}=== ZENX — PASANG SEKALI JALAN ===${N}\n\n"

# ---------- 1. izin penyimpanan ----------
# Dibutuhin buat nulis autoexec Delta di /sdcard.
if [ ! -d "$HOME/storage" ]; then
    lapor "Minta izin penyimpanan (bakal muncul kotak izin -- tap IZINKAN)"
    termux-setup-storage
    sleep 3
fi
[ -d "$HOME/storage" ] && sukses "Izin penyimpanan ada" || warn "Izin penyimpanan belum -- autoexec mungkin gagal"

# ---------- 2. paket ----------
lapor "Update daftar paket (agak lama di RF, sabar)"
pkg update -y >/dev/null 2>&1
pkg upgrade -y >/dev/null 2>&1

lapor "Pasang lua54, curl, termux-api"
pkg install lua54 curl termux-api -y >/dev/null 2>&1

# beberapa Termux namain 'lua5.4', sebagian 'lua54' -- pastiin salah satu ada
if command -v lua5.4 >/dev/null 2>&1; then
    LUA="lua5.4"
elif command -v lua >/dev/null 2>&1; then
    LUA="lua"
else
    gagal "Lua gagal kepasang. Coba manual: pkg install lua54 -y"
fi
sukses "Lua siap ($LUA)"

command -v curl >/dev/null 2>&1 || gagal "curl gagal kepasang. Coba: pkg install curl -y"
sukses "curl siap"

# mkfifo dipakai buat shell root tetap (yang bikin worker jauh lebih cepet)
if ! command -v mkfifo >/dev/null 2>&1; then
    pkg install coreutils -y >/dev/null 2>&1
fi
command -v mkfifo >/dev/null 2>&1 && sukses "mkfifo siap (shell root tetap bisa dipakai)" \
    || warn "mkfifo gak ada -- shell root tetap bakal balik ke cara lama"

# ---------- 3. cek root ----------
lapor "Cek akses root"
if su -c 'echo ok' >/dev/null 2>&1; then
    sukses "Root jalan"
else
    warn "Root GAK jalan. Worker butuh root buat buka/tutup client Roblox."
    warn "Buka aplikasi root manager di RF, kasih izin buat Termux, terus ulangi."
fi

# ---------- 4. ambil worker ----------
lapor "Ambil zenx_worker.lua dari GitHub"
if curl -fsSL "$REPO/zenx_worker.lua" -o "$WORKER.baru" 2>/dev/null; then
    # pastiin isinya beneran worker, bukan halaman error GitHub
    if head -5 "$WORKER.baru" | grep -q "ZENX WORKER"; then
        mv "$WORKER.baru" "$WORKER"
        sukses "Worker keunduh: $(grep -m1 'local VERSION' "$WORKER" | cut -d'"' -f2)"
    else
        rm -f "$WORKER.baru"
        warn "Yang keunduh bukan file worker (repo/nama file salah?)"
    fi
else
    rm -f "$WORKER.baru"
    warn "Gagal unduh dari GitHub"
fi

# cadangan: ambil dari /sdcard/Download kalau unduhan gagal
if [ ! -f "$WORKER" ]; then
    lapor "Coba ambil dari /sdcard/Download"
    ADA=$(ls -t /sdcard/Download/zenx_worker*.lua* 2>/dev/null | head -1)
    if [ -n "$ADA" ]; then
        cp "$ADA" "$WORKER"
        sukses "Diambil dari: $ADA"
    else
        gagal "Worker gak ketemu. Taruh zenx_worker.lua di /sdcard/Download, terus ulangi."
    fi
fi

# ---------- 5. pintasan ----------
# biar berikutnya cukup ketik: zenx
cat > "$PREFIX/bin/zenx" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
cd "\$HOME" && exec $LUA zenx_worker.lua "\$@"
EOF
chmod +x "$PREFIX/bin/zenx"
sukses "Pintasan dibikin -- lain kali cukup ketik: zenx"

# ---------- 6. jalan ----------
printf "\n${OK}=== SIAP ===${N}\n"
printf "  Jalanin  : ${H}zenx${N}\n"
printf "  Matiin   : ${H}zenx stop${N}\n"
printf "  Diagnosa : ${H}zenx cek${N}\n\n"

printf "Jalanin sekarang? (Y/n): "
read JWB
case "$JWB" in
    [Nn]*) printf "Oke. Ketik ${H}zenx${N} kalau mau mulai.\n\n" ;;
    *)     cd "$HOME" && exec $LUA zenx_worker.lua ;;
esac
