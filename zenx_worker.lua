#!/usr/bin/env lua
-- ============================================================
-- ZENX WORKER  v4.2  (Termux, Redfinger)
-- 1 WORKER = 1 TIM = 1 RedFinger = 6-10 client Roblox.
--
-- Beda dari v3.0 (ntfy) -> v4.0 (Cloudflare Worker):
--   * ntfy DIBUANG. Satu layanan, satu kunci, satu alamat.
--   * Perintah : GET  /perintah?tim=X   (dulu: ntfy.sh/topic/json?poll=1)
--   * Status   : POST /tim              (dulu: ntfy.sh/topic-status)
--   * Kunci beneran (X-Kunci). Topic ntfy itu publik — siapa pun yang tau
--     namanya bisa nembak FORCE ke tim lo.
--   * CPU/RAM jadi keluar di panel.
--
-- v4.1: * Paket Roblox DIPINDAI OTOMATIS dari device. Gak usah ngetik
--         6-10 nama paket satu-satu (gampang typo, susah dicek).
--       * win_mode: OPSIONAL, bawaan 0 = jangan disenggol. Client yang
--         udah auto-freeform gak perlu ini.
--       * BUKA BERGILIR + DIVERIFIKASI. Tiap client ditungguin sampai
--         beneran jalan sebelum lanjut ke berikutnya. Gagal -> diulang,
--         terus dilaporin nama paketnya. Gak lagi tembak-lari.
--
-- v4.2: BISA DIMATIIN. Dulu cuma bisa `pkill` — mati mendadak, notif
--       nyangkut, wake-lock kepegang, panel gak tau.
--         lua5.4 zenx_worker.lua stop     -> berhenti baik-baik
--         lua5.4 zenx_worker.lua status   -> jalan apa nggak
--         KILL dari panel                 -> worker mati (beda dari STANDBY)
--       Plus: gak bisa dobel jalan (2 worker 1 tim = RAM jebol).
--
-- Perintah nempel (sticky) sampai diganti. Di ntfy dulu perlu akal-akalan
-- forceSticky karena pesan kedaluwarsa. Sekarang perintahnya kesimpen di DB,
-- jadi isinya = keadaannya. Lebih simpel & gak bisa "ilang" sendiri.
--
-- v4.17: MASUK GAME DIKONFIRMASI BRIDGE (bukan cuma "proses muncul").
--        Masalah: halaman Home Roblox JUGA pakai ActivityNativeMain, jadi
--        client yg nyangkut di Home (kena popup age-check / PS link gagal)
--        ke-baca "jalan" -> worker lanjut ke client lain, gak ngulang.
--        Fix: setelah proses muncul, worker TUNGGUIN akun lapor BARU ke
--        /stat (sinyal sama kayak auto-rejoin). Lapor baru = script jalan =
--        BENERAN di game. Bridge diem sampai timeout = nyangkut -> ulang buka.
--        Skip "udah jalan" juga dicek bridge, biar Home-stuck gak ke-skip.
--        Default delay dinaikin (stagger 15, tunggu 60) + konfirmasi_sec 90.
--
-- v4.18: ORIENTASI LAYAR + KEEP-ALIVE (anti-FC).
--        * orientasi: kunci RF ke landscape/portrait (opsional, setup).
--        * keep-alive: client Roblox tahan di background (deviceidle whitelist +
--          appops RUN_IN_BACKGROUND + oom_score_adj rendah, di-apply ulang tiap
--          menit karena Android suka reset). Worker DILINDUNGIN LEBIH KUAT dari
--          client -> kalau RAM mentok, yg dikorbanin client (bisa rejoin), bukan
--          worker. CATATAN: di device RAM sesek keep-alive NGURANGIN kill, bukan
--          NGILANGIN -> tetep bisa reboot kalau kepepet. Jaring rejoin tetep jalan.
--
-- v4.19: REJOIN GANTI SERVER: CEPET + NYEROBOT.
--        * REJOIN (dari panel, ganti PS) pakai FAST mode -> skip bridge-confirm
--          (gak nunggu tiap client lapor 90s). alur tetep: tutup semua -> refresh
--          assign-ps (nurut panel) -> buka lagi ke PS baru, tapi CEPET.
--        * REJOIN/CLOSE NYEROBOT FORCE yg lagi jalan -> FORCE dibatalin, perintah
--          panel langsung dikerjain (gak nyangkut nunggu FORCE kelar dulu).
--        FORCE/reopen berkala TETEP pakai bridge-confirm (biar Home-stuck ketangkep).
--
-- v4.20: REJOIN PER-CLIENT bisa BANYAK akun sekaligus.
--        REJOIN:akun1,akun2 -> rejoin per-client masing-masing (tutup 1 buka 1),
--        JANGAN kill all. Buat panel: kalau ganti server cuma sebagian client,
--        yg di-rejoin cuma yg berubah (per-client). Kill all CUMA kalau REJOIN
--        polos (tanpa :akun) = ganti server SEMUA client sekaligus.
--
-- v4.21: FALSE-OFF FIX (client kebekuin Android, keliatan off padahal di server).
--        * MATIIN cached-app freezer (settings + device_config) -> Roblox background
--          gak dibekuin -> loop script tetep jalan -> tetep lapor -> gak dikira off.
--        * wake-lock CPU pas start (worker + client gak ditidurin layar idle).
--        * AUTO-REJOIN pinter: bridge diem TAPI client masih di game (pkg_running) ->
--          cukup DIBANGUNIN (bawa ke depan), JANGAN kill+buka. kill cuma kalau
--          beneran keluar dari layar game.
--
-- v4.22: freezer-disable DICABUT (teorinya salah -- game jalan normal, yg berhenti
--        cuma LAPORAN bridge). akar masalahnya jarak denyut kekencengan vs ambang
--        off panel; dibenerin di script: star_farm v13.10 (denyut 300->120) +
--        market v8.336 (gagal kirim gak lagi dianggap sukses). nudge auto-rejoin
--        (v4.21) TETEP dipake -- itu tetep bener biar client idup gak di-kill.
--
-- v4.23: PINDAH SERVER OTOMATIS (buat suplai pet market <- leveling).
--        * PS berubah di panel/CF -> worker rejoin client itu DOANG ke PS baru.
--          Ini mesin umum: siapa pun yg ubah assign-ps, client nyusul sendiri.
--        * suplai_master (v4.28: OTOMATIS tim-1, gak ditanya lagi) manggil /suplai-cek
--          tiap 60 detik -> CF ngumpulin akun market yg stok nipis ke PS akun
--          leveling yg pet siap-gift-nya banyak, terus mulangin kalau udah cukup.
--          Cuma tim-1 -> mustahil rebutan nulis (dulu bisa bikin akun gak balik).
--
-- v5.25: `zenx cookie` -- ekstrak cookie .ROBLOSECURITY dari akun sendiri buat
--        BACKUP / pindah device. Bukan bypass apa-apa -- cuma baca kredensial
--        milik sendiri dari storage client yang lagi login.
--          zenx cookie          -> cuma client yang LAGI JALAN (yg terkait)
--          zenx cookie <huruf>  -> satu client (com.roblox.clien<huruf>)
--          zenx cookie all      -> semua paket kepasang (jalan atau nggak)
--        "Bukti dulu": lokasi & format simpan cookie di clone App Cloner belum
--        pasti, jadi command ini NAMPILIN file mana yg punya ROBLOSECURITY +
--        ekstrak nilainya. Kalau nihil -> lokasinya beda, kabarin biar disetel.
--        Pakai timeout panjang (grep rekursif lama) -- bukan sh() yg dipatok 8s.
--
-- v5.26: `zenx cookie` sekarang ngasih LABEL NAMA AKUN (baca_username dari
--        prefs.xml, sumber yg sama kayak mapping client<->akun auto-rejoin).
--        Format file jadi: <akun>\t<paket>\t<cookie>. Gampang dicocokin pas
--        restore. Akun '?' = prefs.xml belum punya username (client baru).
--
-- v5.27: `zenx cookie` sekarang AUTO-KIRIM cookie ke panel (CF /cookie-simpan)
--        selain nulis file lokal. Di panel digerbang password (tab Cookie),
--        sesi 24 jam. File /sdcard tetep ditulis sebagai cadangan. Butuh:
--        tabel D1 'cookies' + endpoint /cookie-* di TEMPEL-KE-CLOUDFLARE.js.
--
-- v5.28: `zenx verif` -- daftar client yang BUTUH DICEK MANUAL. Bukan deteksi
--        captcha (mustahil di RF ini -- layar kebaca 0 teks, lihat 5.9/v4.85),
--        tapi penyaring POLA: idup tapi bridge gak pernah lapor = nyangkut
--        sebelum masuk game (verif bot / layar key / popup umur semuanya masuk
--        pola ini). Sekali dumpsys + sekali su + sekali GET /stat. Keputusan
--        (ganti akun / verif manual) tetap di user -- worker gak nyentuh apa2.
--
-- v5.29: SCRIPT PER TIM DARI PANEL. Dulu tiap RF nulis `zenx_loader.lua` dari
--        cfg.script_url LOKAL -- ganti script = edit config di tiap RF satu-satu.
--        Sekarang panel bisa nentuin tim ini jalanin script apa; URL-nya nebeng
--        di respons /perintah (yang emang udah di-poll), jadi NOL request tambahan.
--        Begitu ganti: autoexec ditulis ulang + semua client ditutup (Delta cuma
--        baca Autoexecute pas masuk game, jadi yang lagi jalan masih pakai script
--        lama). Yang buka lagi blok FORCE. Kalau panel gak nentuin apa-apa,
--        jatuh balik ke cfg.script_url lokal -- perilaku lama tetep jalan.
--
-- v5.30: LAPORAN KE PANEL YANG GAGAL SEKARANG KELIATAN.
--        Dulu `api_post(cfg, "/tim", body)` nilai baliknya DIBUANG. Kalau POST
--        ditolak (kunci salah, backend belum deploy, tim kosong), worker tetep
--        keliatan normal -- config kebaca, tim kedeteksi, polling jalan --
--        sementara di panel timnya KOSONG. Gagalnya diem, susah dilacak.
--        Sekarang: baris status di layar ("LAPOR KE PANEL GAGAL: <sebab>")
--        + perintah `zenx panel` yang nguji tiap endpoint satu-satu.
--        Catatan kenapa gejalanya menyesatkan: GET /perintah bisa LOLOS
--        sementara POST /tim ditolak -- dua-duanya endpoint beda.
--
-- v5.31: KUNCI API bypass.vip GAK DITANYA LAGI pas setup. Diisi SEKALI di
--        panel, semua RF narik dari /bypass-key. Dulu ditanyain tiap setup --
--        20 RF = 20 kali ngetik kunci yang sama, dan sekali salah ketik
--        `zenx key` gagal tanpa sebab yang jelas.
--        Urutan: config lokal MENANG (kalau RF ini perlu kunci beda), baru
--        panel. Hasil panel di-cache 10 menit; kalau panel mati, yang udah
--        kepegang tetep kepakai.
--        Tetep GAK masuk GitHub -- kuncinya di D1, bukan di berkas yang
--        di-push.
--
-- v5.32: kunci API DITARIK PAS WORKER NYALA, terus DISIMPEN ke config lokal.
--        Sekali narik, habis itu instan & gak butuh panel lagi. Ini penting
--        karena `zenx key` dipanggil justru pas lisensi Delta abis -- saat
--        paling genting; kalau baru narik di situ dan panel lagi mati,
--        bypass-nya gagal.
--        Hasilnya: gak perlu ngetik manual di tiap RF, TANPA harus naruh
--        kunci di berkas yang di-push ke GitHub.
--
-- v5.33: kunci API DITARUH LANGSUNG di file ini (BYPASS_KEY_BAWAAN), atas
--        permintaan user -- repo `revsy` PRIVAT. Nol delay, gak nanya panel
--        sama sekali. Urutan: config lokal > bawaan > panel.
--        !! KALAU REPO DIJADIIN PUBLIK, KOSONGIN BYPASS_KEY_BAWAAN DULUAN !!
--        Itu kunci langganan berbayar -- siapa pun yang bisa baca file ini
--        bisa ngabisin kuotanya.
--
-- v5.34: nama akun di tabel dipotong dari DEPAN, bukan belakang. Nama akun
--        polanya awalan+nomor (wildnx_12, oliviainvent3) -- yang MEMBEDAKAN
--        ada di ujung belakang. Motong dari belakang bikin 4 akun beda
--        keliatan sama persis, dan itu nyesatin: keliatannya kayak 4 client
--        login ke satu akun yang sama. Kolomnya juga dilebarin 12 -> 14.
--
-- v5.35: SCRIPT AUTOEXEC DIPILIH SENDIRI pas setup: STAR FARM / STAR SEED /
--        MARKET. Dulu kepaksa ngikut game -- GAG 2 selalu dapet `gag2`.
--        Padahal satu tim GAG 2 bisa dipakai buat dua hal beda: farm kebun
--        atau AFK beli seed. Bawaannya nyesuain game, jadi kasus umum
--        tinggal Enter.
--
-- v5.36: pertanyaan "Folder autoexec" DIBUANG dari setup. Jawabannya selalu
--        sama -- 20 RF = 20 kali mencet Enter buat nilai yang gak pernah beda.
--        Nilainya tetep ketulis di config, dan ada cadangan di dua tempat
--        (run + tulis_autoexec), jadi gak ada yang rusak. Kalau suatu saat
--        ada RF yang foldernya beda: edit config -> autoexec_dir="/path/lain"
--
-- v5.37: pertanyaan "Pakai shell root tetap?" DIBUANG, bawaannya jadi NYALA.
--        Dulu bawaannya "n" padahal selalu dijawab y -- dan untungnya besar
--        (tiap 'su' di RF makan ~6 detik, ini bikin root dibuka sekali aja).
--        Aman dipaksa: dites pas nyala, gagal = balik ke cara lama; kalau
--        shell-nya mati di tengah jalan juga kedeteksi. Paling jelek dia cuma
--        balik ke perilaku lama.
--        Config lama yang shell_tetap=false tetep dihormatin.
--
-- v5.38: pertanyaan "Auto grid?" DIBUANG, bawaannya NYALA. Grid itu bukan
--        pilihan gaya -- jendela HARUS ketata biar URL key Delta bisa diambil
--        dari tiap client. Susunannya juga udah otomatis dari dulu:
--        grid_hitung baca ukuran layar sendiri + tabel SUSUNAN (4 client ->
--        2x2). Sekarang hasil hitungannya ditampilin pas setup, biar keliatan
--        gak ada yang perlu diatur.
--
-- v5.39: SETUP NYETEL PERINTAH AWAL SENDIRI = FORCE.
--        Dulu RF yang baru selesai setup NGANGGUR: "perintah: -", semua client
--        off, gak ada yang jalan sampai ada orang mencet "Jalankan semua" di
--        panel. Gejalanya nyesatin -- worker keliatan sehat (nyambung, lapor
--        jalan tiap detik) tapi gak ngapa-ngapain, dan gak ada petunjuk kenapa.
--        Padahal RF yang baru disetup ya jelas mau dijalanin.
--        Mau ditahan dulu? panel -> "Hentikan".
--        Sekalian api_post bisa milih metode (bawaan POST) -- /perintah minta
--        PUT, dan tanpa itu setup gak bisa nyetel perintahnya sendiri.
--
-- v5.40: FIX `up` nyangkut di versi lama. Kejadian nyata: `up` di RF bilang
--        "OK 5.35" berulang-ulang padahal GitHub udah 5.39 -- dan karena dia
--        bilang OK (bukan gagal), gak ada yang curiga.
--        Sebabnya: `up` itu skrip yang dibikin SEKALI pas `pasang`. RF yang
--        dipasang pakai worker lama kebawa skrip lama selamanya.
--        Sekarang worker NULIS ULANG `up` tiap nyala (cuma kalau isinya beda),
--        jadi sekali dapet worker baru, `up`-nya kebetulin sendiri.
--        Plus: header no-cache (jaga-jaga ada proxy di jaringan RF yang gak
--        peduli sama ?t=), dan alamat repo disatuin jadi SATU konstanta --
--        dulu ketulis di dua tempat, bisa beda diam-diam.
--
-- v5.41: FILE LAIN di folder autoexec DIBUANG pas nulis loader.
--        Delta jalanin SEMUA file di folder itu. Jadi sisa script lama
--        (text.txt yang pernah ditaruh manual, loader dari nama lama) bakal
--        jalan BARENGAN sama yang baru -- dua script aktif di satu client,
--        aksi dobel, atau yang bener ketimpa yang salah.
--        Yang dilewat cuma zenx_loader.lua punya kita. Apa aja yang dibuang
--        DILAPORIN, biar gak ada yang ilang diam-diam.
--        Digabung ke panggilan su yang sama -> praktis gratis.
--        Mau dimatiin: config -> autoexec_bersih=false
--
-- v5.42: `zenx panel` diperluas -- sekarang ikut ngecek AKUN, bukan cuma
--        sambungan. Perlu karena ada gejala yang gak kejelasan sebabnya:
--        panel bilang "0 akun di tim ini" padahal client-nya ada dan worker
--        nampilin nama akunnya di tabel.
--        Tiga langkah baru:
--          5. akun yang worker TAU (dari prefs.xml tiap client)
--          6. POST /assign-tim + jawaban mentahnya
--          7. cek di /stat: akun itu kecatat di tim & game APA
--        Langkah 7 yang menentukan: akun cuma nongol di sebuah tab kalau
--        tim DAN game-nya cocok. Kalau game-nya kebawa dari pemakaian lama
--        (mis. akun ini dulu dipakai GAG 1), dia gak akan nongol di tab GAG 2
--        walau timnya bener.
--
-- v5.43: auto-assign sekarang LAPOR apa yang dibetulin, bukan cuma jumlahnya.
--        Pasangannya perubahan di CF (/assign-tim v15-66): kolom `game` DITIMPA
--        dari worker, dan `place` yang nunjuk game lain DIBUANG.
--        Kenapa dua-duanya: panel nentuin game akun dari PLACE[place] DULU,
--        baru kolom game. Jadi betulin `game` aja gak cukup -- place basi
--        masih nutupin, dan akunnya tetep nyangkut di tab game lama.
--        Yang TETEP dijaga: akun milik tim LAIN gak direbut.
-- ============================================================
local CONFIG_FILE = "zenx_worker_config.lua"
local VERSION = "5.43-cf"
local C = { R="\27[31m",G="\27[32m",Y="\27[33m",C="\27[36m",D="\27[90m",N="\27[0m",BOLD="\27[1m" }
local function log(m,c) print((c or "")..os.date("%H:%M:%S").." "..m..C.N) end
-- v4.24/4.26: log + "lagi ngapain" dikirim ke panel, biar gak usah pantengin Termux.
-- warn() ikut kecatet (ditandain "!") supaya ERROR keliatan di panel juga.
local LOG_KIRIM = {}          -- baris log terakhir (maks 20)
-- v5.30: status laporan ke panel. Dipakai buat nampilin kalau lapor GAGAL --
-- dulu gagalnya diem dan panel keliatan kosong tanpa sebab yang jelas.
local LAPOR_OK, LAPOR_SEBAB, LAPOR_WARN, LAPOR_TS = nil, nil, nil, 0
local AKSI_SKRG = "mulai..."  -- lagi ngapain SEKARANG
local LAPOR_KEY_AT = 0        -- v4.86: kapan terakhir ngabarin "butuh key"
local BAWA_SEBAB = nil       -- v5.08: kenapa gagal munculin jendela
local PERTAMA_DIEM = {}      -- v5.04: kapan worker pertama liat client idup tapi bisu
local BYPASS_TERAKHIR = 0   -- v5.02: kapan terakhir nyoba bypass key
local SUDAH_GRID = false      -- v4.30: udah pernah nata grid sejak worker nyala?
local function setAksi(txt)
    AKSI_SKRG = tostring(txt or "")
end
local function catatKirim(baris)
    LOG_KIRIM[#LOG_KIRIM+1] = baris
    while #LOG_KIRIM > 20 do table.remove(LOG_KIRIM, 1) end
end

local function ok(m) log("OK  "..m,C.G) end
local function err(m) log("ERR "..m,C.R) end
local function info(m) log("--  "..m,C.C) end

local function warn(m)
    log("!   "..m,C.Y)
    catatKirim(os.date("%H:%M:%S") .. " ! " .. tostring(m))   -- v4.26: error nongol di panel
end

-- ============================================================
-- v5.40: REPO jadi SATU konstanta, dan skrip `up` DITULIS ULANG tiap worker
-- nyala.
--
-- Kejadian nyata: `up` di RF bilang "OK 5.35" terus-terusan padahal GitHub
-- udah 5.39. Sebabnya `up` itu dibikin SEKALI pas `pasang` -- kalau RF-nya
-- dipasang pakai worker versi lama, skripnya ketinggalan selamanya, dan
-- gejalanya nyesatin: dia bilang OK, bukan gagal.
--
-- Sekarang worker nulis ulang `up` tiap nyala. Jadi sekali dapet worker baru
-- (lewat curl manual), `up`-nya kebetulin sendiri buat seterusnya.
-- Sekalian ditambah header no-cache -- jaga-jaga ada proxy di jaringan RF
-- yang gak peduli sama `?t=`.
-- ============================================================
local REPO_WORKER = "https://raw.githubusercontent.com/alzafabocahbocah-boop/revsy/main"

local function tulis_skrip_up(diam)
    local PREFIX = os.getenv("PREFIX") or "/data/data/com.termux/files/usr"
    local jalur = PREFIX .. "/bin/up"
    local isi = table.concat({
        "#!" .. PREFIX .. "/bin/sh",
        "zenx stop >/dev/null 2>&1",
        'echo "narik versi baru..."',
        'curl -fsSL -H "Cache-Control: no-cache" -H "Pragma: no-cache" \\',
        '  "' .. REPO_WORKER .. '/zenx_worker.lua?v=$(date +%s)" \\',
        '  -o "$HOME/zenx_worker.baru"',
        'if head -5 "$HOME/zenx_worker.baru" 2>/dev/null | grep -q "ZENX WORKER"; then',
        '    mv "$HOME/zenx_worker.baru" "$HOME/zenx_worker.lua"',
        '    echo "OK  $(grep -m1 \'local VERSION\' "$HOME/zenx_worker.lua")"',
        "else",
        '    echo "GAGAL -- yang keunduh bukan worker (belum di-push?)"',
        '    rm -f "$HOME/zenx_worker.baru"',
        "fi",
        "",
    }, "\n")

    -- cuma ditulis kalau BEDA, biar gak nulis-nulis berkas tiap nyala
    local lama = ""
    local fr = io.open(jalur, "r")
    if fr then lama = fr:read("*all") or ""; fr:close() end
    if lama == isi then return false end

    local f = io.open(jalur, "w")
    if not f then
        if not diam then warn("gak bisa nulis " .. jalur) end
        return false
    end
    f:write(isi); f:close()
    os.execute("chmod +x " .. PREFIX .. "/bin/up")
    if not diam then ok("Skrip `up` diperbarui (anti-cache + repo terbaru)") end
    return true
end


-- ============================================================
-- config
-- ============================================================
local function load_config()
    local f=io.open(CONFIG_FILE,"r"); if not f then return nil end
    local s=f:read("*all"); f:close()
    local fn=load("return "..s); if not fn then return nil end
    local o,cfg=pcall(fn); if o then return cfg end; return nil
end

local function save_config(cfg)
    local f=io.open(CONFIG_FILE,"w"); if not f then return false end
    f:write("{\n")
    f:write(string.format("  tim=%q,\n",cfg.tim))
    f:write(string.format("  url=%q,\n",cfg.url))
    f:write(string.format("  kunci=%q,\n",cfg.kunci))
    f:write(string.format("  targets=%q,\n",cfg.targets))
    f:write(string.format("  place_id=%q,\n",cfg.place_id))
    f:write(string.format("  game_label=%q,\n",cfg.game_label or ""))
    f:write(string.format("  script_url=%q,\n",cfg.script_url or ""))
    f:write(string.format("  script_label=%q,\n",cfg.script_label or ""))
    f:write(string.format("  link_code=%q,\n",cfg.link_code or ""))
    f:write(string.format("  autoexec_dir=%q,\n",cfg.autoexec_dir or "/sdcard/Delta/Autoexecute"))
    f:write(string.format("  autoexec_bersih=%s,\n",tostring(cfg.autoexec_bersih ~= false)))
    f:write(string.format("  pkgs=%q,\n",cfg.pkgs))
    f:write(string.format("  poll_sec=%d,\n",cfg.poll_sec))
    f:write(string.format("  reopen_sec=%d,\n",cfg.reopen_sec or 300))
    f:write(string.format("  auto_rejoin=%s,\n",tostring(cfg.auto_rejoin ~= false)))
    f:write(string.format("  auto_rejoin_menit=%d,\n",cfg.auto_rejoin_menit or 8))
    f:write(string.format("  stagger_sec=%d,\n",cfg.stagger_sec or 15))
    f:write(string.format("  status_sec=%d,\n",cfg.status_sec or 20))
    f:write(string.format("  win_mode=%d,\n",cfg.win_mode or 0))
    f:write(string.format("  tunggu_sec=%d,\n",cfg.tunggu_sec or 60))
    f:write(string.format("  konfirmasi_sec=%d,\n",cfg.konfirmasi_sec or 90))
    f:write(string.format("  orientasi=%q,\n",cfg.orientasi or ""))
    f:write(string.format("  keep_alive=%s,\n",tostring(cfg.keep_alive ~= false)))
    f:write(string.format("  auto_grid=%s,\n",tostring(cfg.auto_grid == true)))
    f:write(string.format("  deteksi_longgar=%s,\n",tostring(cfg.deteksi_longgar == true)))
    f:write(string.format("  disconnect_menit=%d,\n",cfg.disconnect_menit or 3))
    f:write(string.format("  jaga_depan_sec=%d,\n",cfg.jaga_depan_sec or 0))
    f:write(string.format("  suplai_sec=%d,\n",cfg.suplai_sec or 20))
    f:write(string.format("  shell_tetap=%s,\n",tostring(cfg.shell_tetap == true)))
    f:write(string.format("  max_coba=%d,\n",cfg.max_coba or 5))
    -- v4.78: kunci API bypass.vip. SENGAJA cuma di config (file lokal tiap RF),
    -- JANGAN dipindah ke zenx_worker.lua -- itu di-push ke GitHub publik, siapa
    -- pun yang tau URL-nya bisa baca kuncinya dan ngabisin kuota.
    f:write(string.format("  bypass_api_key=%q,\n",cfg.bypass_api_key or ""))
    f:write(string.format("  key_tanda=%q,\n",cfg.key_tanda or ""))
    f:write(string.format("  key_jam=%d,\n",cfg.key_jam or 24))
    f:write(string.format("  home_detik=%d,\n",cfg.home_detik or 60))
    f:write(string.format("  auto_key=%s,\n",tostring(cfg.auto_key == true)))
    f:write(string.format("  key_tap=%q,\n",cfg.key_tap or ""))
    f:write("}\n"); f:close(); return true
end

local function ask(p,d)
    io.write(C.Y.."? "..p..C.N)
    if d and d~="" then io.write(C.D.." ["..tostring(d):sub(1,44).."]"..C.N) end
    io.write(": "); io.flush()
    local i=io.read(); if i=="" then return d end; return i
end

-- ============================================================
-- shell
-- ============================================================
local function sh_lama(cmd)
    -- timeout 5s: kalau cmd hang (mis. su nungguin izin), jangan freeze selamanya
    local h=io.popen("timeout 5 "..cmd.." 2>/dev/null"); if not h then return "" end
    local o=h:read("*all") or ""; h:close(); return o
end

-- ============================================================
-- v4.70: SHELL ROOT TETAP (opsional, bawaan MATI)
-- Masalahnya: tiap 'su -c ...' di RedFinger makan ~6 detik cuma buat MINTA
-- izin root. Worker manggil puluhan kali per menit -> sebagian besar waktunya
-- kebuang di situ.
-- Idenya: buka SATU shell root di awal, biarin nyala, lempar perintah ke situ.
-- Ongkos ~6 detik itu cuma dibayar SEKALI.
--
-- Pengaman (biar aman dicoba):
--   * dites dulu pas nyala -- gagal = balik ke cara lama, gak ada yang rusak
--   * tiap perintah dibungkus 'timeout' DI DALAM shell -> satu macet gak nahan
--     antrean di belakangnya
--   * tiap perintah punya penanda unik -> jawaban gak mungkin ketuker
--   * kalau shell-nya mati di tengah jalan, kedeteksi & balik ke cara lama
-- ============================================================
local SHELL_AKTIF   = false      -- lagi kepakai apa nggak
local SHELL_TULIS            -- pipa buat ngirim perintah
-- v4.75: dulu di /data/local/tmp -- itu punya root, Termux gak bisa bikin file
-- di situ, jadi mkfifo gagal diem-diem lalu "gagal buka pipa". Pakai folder
-- Termux sendiri: pasti bisa ditulis, dan root tetep bisa baca.
local RUMAH     = os.getenv("HOME") or "."
local SHELL_IN  = RUMAH .. "/.zenx_in"
local SHELL_OUT = RUMAH .. "/.zenx_out"
local SHELL_URUT = 0

local function shell_matikan()
    if SHELL_TULIS then pcall(function() SHELL_TULIS:close() end) end
    SHELL_TULIS, SHELL_AKTIF = nil, false
    os.execute("rm -f " .. SHELL_IN .. " " .. SHELL_OUT .. "* >/dev/null 2>&1")
end

-- kirim satu perintah ke shell tetap. balikin: keluaran, atau nil kalau gagal
local function shell_jalan(cmd, batas)
    if not SHELL_AKTIF or not SHELL_TULIS then return nil end
    SHELL_URUT = SHELL_URUT + 1

    -- v4.77: tiap perintah nulis ke file SENDIRI, terus bikin file penanda
    -- "selesai". Dulu semua nulis ke satu file yang terus kebuka -- keluarannya
    -- nyangkut di penyangga (shell nulis ke file itu numpuk dulu di memori),
    -- jadi jawabannya gak pernah nyampe. Begitu redirect '>' nutup (perintah
    -- kelar), isinya PASTI ketulis -- gak ada yang nyangkut.
    local fOut  = SHELL_OUT .. "." .. SHELL_URUT
    local fDone = SHELL_OUT .. "." .. SHELL_URUT .. ".ok"
    local aman  = "'" .. tostring(cmd):gsub("'", "'\\''") .. "'"

    local ok = pcall(function()
        SHELL_TULIS:write("timeout " .. (batas or 8) .. " sh -c " .. aman ..
                          " > " .. fOut .. " 2>/dev/null; echo x > " .. fDone .. "\n")
        SHELL_TULIS:flush()
    end)
    if not ok then shell_matikan(); return nil end

    -- tungguin penanda selesai muncul
    local mulai = os.time()
    while (os.time() - mulai) <= (batas or 8) + 3 do
        local d = io.open(fDone, "r")
        if d then
            d:close()
            local hasil = ""
            local f = io.open(fOut, "r")
            if f then hasil = f:read("*all") or ""; f:close() end
            os.remove(fOut); os.remove(fDone)
            return hasil
        end
        os.execute("sleep 0.2")
    end
    os.remove(fOut); os.remove(fDone)
    -- gak ada jawaban -> anggap shell-nya bermasalah, balik ke cara lama
    shell_matikan()
    return nil
end

local function shell_nyalakan()
    -- pastiin su beneran jalan dulu (kalau nggak, jangan nekat buka pipa:
    -- io.open ke FIFO bakal nunggu selamanya kalau gak ada yang baca)
    local tes = sh_lama("su -c 'echo ZENXOK'")
    if not tes:find("ZENXOK", 1, true) then return false, "su gak jalan" end

    os.execute("rm -f " .. SHELL_IN .. " " .. SHELL_OUT .. " >/dev/null 2>&1")
    os.execute("mkfifo " .. SHELL_IN .. " >/dev/null 2>&1")
    os.execute("touch " .. SHELL_OUT .. " >/dev/null 2>&1")
    -- pastiin pipanya beneran kebikin (mkfifo bisa gagal diem-diem)
    local adaPipa = sh_lama("test -p " .. SHELL_IN .. " && echo ADA")
    if not adaPipa:find("ADA", 1, true) then
        return false, "mkfifo gak jalan (pkg install coreutils?)"
    end
    -- shell root nyala di latar, baca dari pipa, tulis ke file keluaran
    os.execute("su -c 'sh < " .. SHELL_IN .. " >> " .. SHELL_OUT .. " 2>&1' >/dev/null 2>&1 &")
    os.execute("sleep 1")

    local f = io.open(SHELL_IN, "w")
    if not f then shell_matikan(); return false, "gagal buka pipa" end
    SHELL_TULIS, SHELL_AKTIF = f, true

    -- tes beneran: harus balik jawaban yang bener
    local uji = shell_jalan("echo ZENXSIAP", 5)
    if not uji or not uji:find("ZENXSIAP", 1, true) then
        shell_matikan(); return false, "shell gak jawab"
    end
    return true
end

-- Perintah yang ada udah dibungkus "su -c '...'". Kalau dijalanin DI DALAM
-- shell yang emang udah root, bungkus itu bakal manggil su LAGI -- percuma,
-- ongkosnya balik kayak semula. Jadi bungkusnya dibuka dulu.
local function buka_bungkus_su(cmd)
    local isi = cmd:match("^su %-c '(.*)'$") or cmd:match('^su %-c "(.*)"$')
    if isi then
        -- balikin escape yang dipakai pas ngebungkus
        isi = isi:gsub('\\"', '"')
        return isi
    end
    return cmd
end

-- pintu masuk tunggal: coba shell tetap dulu, gagal -> cara lama
local function sh(cmd)
    if SHELL_AKTIF then
        local o = shell_jalan(buka_bungkus_su(cmd), 8)
        if o then return o end
        -- shell_jalan udah matiin dirinya kalau bermasalah -> lanjut ke cara lama
    end
    return sh_lama(cmd)
end
local function sh_silent(cmd)
    if SHELL_AKTIF then
        if shell_jalan(buka_bungkus_su(cmd), 8) then return end
    end
    os.execute("timeout 8 "..cmd.." >/dev/null 2>&1")
end

local function split(s,sep)
    local t={}
    for x in tostring(s or ""):gmatch("[^"..(sep or ",").."]+") do
        x=x:gsub("^%s+",""):gsub("%s+$","")
        if x~="" then t[#t+1]=x end
    end
    return t
end

local function shq(s) return "'" .. tostring(s):gsub("'", "'\\''") .. "'" end

-- ============================================================
-- v4.78: BYPASS KEY DELTA (api.bypass.vip)
-- Link key-system Delta (auth.platorelay.com/a?d=...) dilempar ke API, API-nya
-- yang nyelesaiin checkpoint. Jadi gak usah tempel-tempel manual.
--
-- Kenapa gak lewat sh() biasa: sh() dipatok timeout 5-8 detik (emang sengaja --
-- biar 'su' yang hang gak nahan worker). Bypass butuh 30-60 detik. Kalau maksa
-- lewat sh(), hasilnya SELALU kepotong dan keliatan kayak "API-nya gagal".
-- Lagipula curl ke internet gak butuh root, jadi gak usah lewat su sama sekali.
-- ============================================================
local BYPASS_BASE    = "https://api.bypass.vip/premium/bypass?url="
local BYPASS_REFRESH = "https://api.bypass.vip/premium/refresh?url="

-- ============================================================
-- v5.33: KUNCI API BAWAAN, ditaruh langsung di sini.
--
-- KENAPA BOLEH: repo `revsy` itu PRIVAT. Kalau suatu saat repo-nya dijadiin
-- publik, KOSONGIN baris ini duluan -- ini kunci langganan berbayar, siapa
-- pun yang bisa baca file ini bisa ngabisin kuotanya.
--
-- Dipakai LANGSUNG tanpa nanya panel, jadi nol delay. Panel cuma dipakai
-- kalau baris ini dikosongin.
--
-- Mau ganti kunci? Ubah di sini, push, terus `up` di tiap RF.
-- Mau satu RF pakai kunci beda? `zenx key set <APIKEY>` -- config lokal menang.
-- ============================================================
local BYPASS_KEY_BAWAAN = "621eeee7-973c-4789-a605-138214d87873"

local function url_encode(s)
    return (tostring(s or ""):gsub("[^%w%-%._~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- ambil link dari clipboard Termux (butuh termux-api). balikin nil kalau gak ada.
local function clipboard_ambil()
    local h = io.popen("timeout 10 termux-clipboard-get 2>/dev/null")
    if not h then return nil end
    local s = (h:read("*all") or ""):gsub("^%s+", ""):gsub("%s+$", "")
    h:close()
    if s == "" then return nil end
    return s
end

-- v5.31: DEKLARASI MAJU. ambil_apikey butuh api_get & ambil_str yang
-- dideklarasi jauh di bawah, tapi bypass_kunci (di sini) butuh ambil_apikey.
-- Dua-duanya gak bisa ditaruh duluan. Jadi namanya dipesan dulu di sini,
-- isinya diisi setelah api_get ada. Ini pola baku buat lingkaran begini --
-- dan WAJIB, kalau nggak bakal "attempt to call a nil value" pas jalan
-- (jebakan 5.14: luac -p GAK nangkep ini).
local ambil_apikey

-- panggil API bypass. balikin: kunci, pesanError, jawabanMentah
local function bypass_kunci(cfg, link, pakaiRefresh)
    local apikey, asal = ambil_apikey(cfg)
    if apikey == "" then
        return nil, "kunci API bypass.vip belum ada.\n" ..
                    "   Isi BYPASS_KEY_BAWAAN di zenx_worker.lua, atau\n" ..
                    "   per-RF: zenx key set <APIKEY>", nil
    end
    if asal ~= "config" then info("kunci API dari " .. asal) end
    if not link or link == "" then return nil, "link kosong", nil end
    if not link:find("^https?://") then
        return nil, "yang dikasih bukan link (harus mulai http/https)", nil
    end

    local dasar = pakaiRefresh and BYPASS_REFRESH or BYPASS_BASE
    -- timeout 90: API-nya emang lama (dia yang ngerjain checkpoint-nya)
    local cmd = string.format("timeout 90 curl -s -m 85 -H %s %s 2>/dev/null",
        shq("x-api-key: " .. apikey), shq(dasar .. url_encode(link)))
    local h = io.popen(cmd)
    if not h then return nil, "gagal jalanin curl", nil end
    local jawab = h:read("*all") or ""
    h:close()

    if jawab:gsub("%s+", "") == "" then
        return nil, "API gak jawab (internet mati / kelamaan / kuota abis?)", jawab
    end

    -- v4.78: bentuk JSON-nya belum pernah dilihat langsung, jadi JANGAN dikunci
    -- ke satu nama field. Dicoba beberapa nama yang lazim; kalau meleset semua,
    -- jawaban MENTAH-nya dicetak -- dari situ baru dikunci ke bentuk aslinya.
    for _, k in ipairs({ "result", "key", "response", "bypassed", "data" }) do
        local v = jawab:match('"' .. k .. '"%s*:%s*"(.-)"')
        if v and v ~= "" then return v, nil, jawab end
    end

    -- ada pesan error dari API-nya?
    local e = jawab:match('"error"%s*:%s*"(.-)"')
            or jawab:match('"message"%s*:%s*"(.-)"')
    if e and e ~= "" then return nil, "API bilang: " .. e, jawab end

    return nil, "jawaban API gak dikenali bentuknya", jawab
end

-- ============================================================
-- v4.80: TULIS KUNCI KE DELTA
-- Ketemu lewat potret sebelum-sesudah: pas kunci ditempel manual, yang muncul
-- file /sdcard/Delta/Internals/Cache/license -- isinya kunci POLOS, 37 byte
-- (FREE_ + 32 hex), TANPA baris baru dan tanpa bungkus JSON.
-- Letaknya di /sdcard (bukan /data/data/<paket>), jadi SATU file ini kepakai
-- semua client sekaligus -- gak usah per-client.
-- ============================================================
local DELTA_LICENSE = "/sdcard/Delta/Internals/Cache/license"

local function tulis_lisensi(cfg, kunci)
    local path = (cfg and cfg.delta_license) or DELTA_LICENSE
    local dir  = path:match("^(.*)/") or "/sdcard/Delta/Internals/Cache"

    -- 1) coba tulis langsung. Termux yang udah dikasih izin penyimpanan
    -- biasanya boleh nulis di /sdcard, jadi gak usah repot manggil root.
    local f = io.open(path, "w")
    if f then
        f:write(kunci)          -- TANPA baris baru: aslinya emang pas 37 byte
        f:close()
    else
        -- 2) gak boleh nulis langsung -> lewat root. Ditulis ke file sementara
        -- dulu baru disalin, biar gak kejebak neraka tanda kutip di dalam su.
        local tmp = (os.getenv("HOME") or ".") .. "/.zenx_lic.tmp"
        local g = io.open(tmp, "w")
        if not g then return false, "gak bisa bikin file sementara" end
        g:write(kunci); g:close()
        sh("su -c 'mkdir -p " .. dir .. "; cp " .. tmp .. " " .. path ..
           "; chmod 660 " .. path .. "'")
        os.remove(tmp)
    end

    -- 3) BACA ULANG. Nulis "berhasil" gak ada artinya kalau isinya gak nyampe --
    -- dan kalau salah, lo baru sadar pas semua client gagal masuk.
    local isi = nil
    local cek = io.open(path, "r")
    if cek then isi = cek:read("*all"); cek:close() end
    if not isi or isi:gsub("%s+", "") == "" then
        isi = sh("su -c 'cat " .. path .. "'")   -- cadangan: baca pakai root
    end
    isi = (isi or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if isi ~= kunci then
        return false, "ketulis tapi isinya beda (kebaca: '" .. isi:sub(1, 45) .. "')"
    end
    return true, path
end

-- v4.79: tulis kunci API ke config TANPA setup ulang.
-- Sengaja EDIT TERTARGET (baca teksnya, ganti/sisipin satu baris) -- bukan
-- load_config lalu save_config. Alasannya: save_config cuma nulis daftar
-- setelan yang dia kenal, jadi kalau ada setelan yang ditambah manual di
-- config, itu bakal KEHAPUS diem-diem. Cara ini gak nyentuh baris lain.
--
-- v4.81 (PENTING): dulu urutannya TULIS DULU baru dicek. Pas pengecekannya
-- gagal, config-nya udah terlanjur ketimpa rusak -- worker jadi gak mau nyala
-- sama sekali. Sekarang dibalik: hasil editan DITES DI MEMORI dulu, baru
-- ditulis kalau sah. Gagal = config lama gak disentuh sedikit pun.
-- v4.86: KEADAAN LISENSI DELTA.
-- Layar gak bisa dibaca (kebukti: game/key/Home sama-sama 0 teks), jadi "lagi
-- diminta key apa nggak" ditebak dari BERKASNYA -- itu kebaca jelas:
--   /sdcard/Delta/Internals/Cache/license   37 byte, isinya kunci polos
-- Kalau berkasnya HILANG atau UMURNYA lewat batas, hampir pasti Delta minta
-- key lagi. Dalam keadaan itu client JANGAN dibunuh -- restart gak bikin kunci
-- masuk, cuma muter-muter sambil ngabisin RAM.
-- balikin: "ada" / "hilang" / "basi", umur dalam detik (nil kalau hilang)
local function lisensi_keadaan(cfg)
    local path = (cfg and cfg.delta_license) or DELTA_LICENSE
    local batas = (tonumber(cfg and cfg.key_jam) or 24) * 3600

    local o = sh("su -c 'stat -c %Y " .. path .. " 2>/dev/null'") or ""
    local ts = tonumber(o:match("%d+"))
    if not ts then
        -- cadangan: sebagian ROM gak punya 'stat -c'. Minimal cek isinya ada.
        local isi = sh("su -c 'cat " .. path .. " 2>/dev/null'") or ""
        if isi:match("%S") then return "ada", nil end
        return "hilang", nil
    end

    local umur = os.time() - ts
    if umur > batas then return "basi", umur end
    return "ada", umur
end

local function umur_ringkas(detik)
    if not detik then return "?" end
    local j = math.floor(detik / 3600)
    local m = math.floor((detik % 3600) / 60)
    if j > 0 then return j .. "j " .. m .. "m" end
    return m .. "m"
end

-- v4.92: DIPINDAH KE ATAS. Di Lua fungsi lokal gak diangkat ke atas --
-- kalau dideklarasi di bawah tapi dipanggil di atas, isinya masih nil.
-- rekam_sentuh manggil ini, jadi harus kedefinisi duluan.

-- ============================================================
-- v4.25: ATUR GRID — susun jendela freeform biar gak numpuk.
-- Butuh client jalan di mode freeform (win_mode 5). Caranya:
--   1. baca ukuran layar (wm size)
--   2. cari taskId tiap client (dumpsys)
--   3. am task resizeTask <taskId> kiri atas kanan bawah
-- CATATAN: 'am task resizeTask' gak ada di semua ROM. Kalau gagal, dilaporin
-- ke log (gak diem-diem), dan client tetep jalan normal -- cuma gak ketata.
-- ============================================================
local function layar_ukuran()
    -- "Physical size: 720x1280" (kadang ada "Override size:" -> itu yang dipakai)
    local o = sh("su -c 'wm size'") or ""
    local w, h = o:match("Override size:%s*(%d+)x(%d+)")
    if not w then w, h = o:match("Physical size:%s*(%d+)x(%d+)") end
    w, h = tonumber(w) or 0, tonumber(h) or 0
    if w == 0 or h == 0 then return 0, 0, 0 end

    -- v4.27: 'wm size' itu ukuran FISIK, GAK ikut muter pas layar landscape.
    -- Kalau lagi landscape, lebar/tinggi efektifnya KEBALIK -> harus dituker,
    -- kalau nggak grid-nya ngitung pakai bentuk portrait (jendela kepencet /
    -- keluar layar). rotasi: 0=portrait, 1=landscape, 2=portrait kebalik, 3=landscape kebalik.
    local rot = tonumber((sh("su -c 'settings get system user_rotation'") or ""):match("%d+"))
    if not rot then
        -- cadangan: baca dari window manager
        local d = sh("su -c 'dumpsys window | grep -m1 -E \"mCurrentRotation|mRotation\"'") or ""
        rot = tonumber(d:match("[Rr]otation[=:%s]*(%d+)")) or 0
    end
    if rot == 1 or rot == 3 then w, h = h, w end
    return w, h, rot
end

-- v5.14: DIPINDAH KE ATAS. Perintah panjang (nyari tombol, pantau sentuhan)
-- perlu ngecek tanda berhenti, dan mereka dideklarasi jauh di atas sini.
local PID_FILE  = "zenx_worker.pid"
local STOP_FILE = "zenx_worker.stop"

local function ada_stop()
    local f = io.open(STOP_FILE, "r")
    if f then f:close(); return true end
    return false
end

-- v4.89: BAWA JENDELA KE DEPAN TANPA LINK JOIN.
-- Dulu munculinnya pakai 'am start -d <link>'. Itu aman kalau client UDAH di
-- dalam game (link jadi no-op), TAPI kalau lagi di layar key / belum masuk
-- game, link itu BENERAN dieksekusi -> client join & teleport sendiri. Kejadian
-- pas kalibrasi tap: client malah pindah ke market.
-- Sekarang: pindahin task-nya doang, gak nyentuh isi aplikasi sama sekali.
local function bawa_depan(pkg)
    -- 1) lewat taskId. Di RedFinger cuma 'am stack list' yang ngasih taskId
    -- (dumpsys activity gagal). Keluarannya suka ke-wrap, jadi dibaca pakai
    -- posisi, bukan per baris.
    local o = sh("su -c 'am stack list 2>&1'") or ""
    local id, cari = nil, 1
    while true do
        local _, b = o:find("taskId=", cari, true)
        if not b then break end
        local nomor = o:match("^(%d+)", b + 1)
        if nomor and o:sub(b, b + 200):find(pkg, 1, true) then id = nomor break end
        cari = b + 1
    end
    if id then
        local r = sh("su -c 'am task move-task " .. id .. " true 2>&1'") or ""
        if not r:lower():find("unknown") and not r:lower():find("exception") then
            return true, "task " .. id
        end
        BAWA_SEBAB = "move-task ditolak: " .. (r:gsub("%s+", " "):sub(1, 40))
    else
        -- v5.08: kenapa taskId gak ketemu -- ini yang bikin jatuh ke cara cadangan
        BAWA_SEBAB = (o:match("%S") and "taskId gak ada di keluaran 'am stack list'")
                     or "'am stack list' gak ngasih apa-apa"
    end
    -- 2) cadangan: panggil activity-nya langsung, TANPA -d (tanpa link)
    sh_silent("su -c 'am start -f 0x20000000 -n " .. pkg ..
              "/com.roblox.client.startup.MainGameActivity'")
    return true, "activity"
end

-- v4.88: baca KOTAK JENDELA client yang sebenernya (bukan hitungan grid).
-- Dari dump: bounds="[688,167][1089,500]". Semua simpul bounds-nya sama karena
-- isi jendela digambar ke permukaan -- tapi justru itu yang kita mau: kotak
-- luar jendelanya.
-- v5.08: PASTIIN client beneran yang di depan, jangan cuma "udah disuruh naik".
-- Client itu jendela NGAMBANG kecil. Habis baca papan klip, Termux nutupin
-- layar penuh -- kalau 'input tap' ditembak ke koordinat client sementara
-- Termux masih di atas, yang nerima pencetan itu TERMUX. Koordinatnya bener,
-- yang salah urutan tumpukannya.
-- Jadi: disuruh naik -> DIPERIKSA lewat mCurrentFocus -> diulang kalau belum.
local function pastikan_depan(pkg, maks)
    for coba = 1, (maks or 3) do
        bawa_depan(pkg)
        os.execute("sleep 2")
        local fokus = sh("su -c 'dumpsys window | grep mCurrentFocus'") or ""
        if fokus:find(pkg, 1, true) then return true, coba end
    end
    local fokus = sh("su -c 'dumpsys window | grep mCurrentFocus'") or ""
    local siapa = fokus:match("([%w%.]+)/") or "?"
    return false, siapa
end

-- v5.07 (BUG PENTING): dulu fungsi ini cuma motret layar yang lagi DI DEPAN,
-- tanpa mastiin itu beneran client-nya. Padahal di alur nyari tombol, Termux
-- sering lagi di depan (abis baca papan klip) -- jadi yang keukur JENDELA
-- TERMUX, dan semua tap dihitung dari kotak yang salah. Itu sebabnya
-- pencetannya nyasar ke Termux, bukan ke client.
-- Sekarang: client dipaksa ke depan dulu, hasilnya DIVERIFIKASI (dump-nya harus
-- beneran punya paket itu), dan kotaknya cuma diambil dari simpul milik paket
-- itu -- bukan simpul terbesar apa pun yang kebetulan ada.
local function jendela_kotak(pkg)
    local dump = "/sdcard/zenx_kotak.xml"
    for coba = 1, 2 do
        pastikan_depan(pkg)
        -- hapus+dump+baca+hapus digabung jadi SATU panggilan su (tiap 'su' ~6 detik)
        local isi = sh("su -c 'rm -f " .. dump .. "; uiautomator dump " .. dump ..
                       " >/dev/null 2>&1; cat " .. dump .. " 2>/dev/null; rm -f " .. dump .. "'") or ""
        if isi:find("bounds", 1, true) then
            -- dump-nya beneran punya client ini?
            if isi:find('package="' .. pkg .. '"', 1, true) then
                -- ambil kotak TERBESAR DI ANTARA SIMPUL MILIK PAKET INI
                local bL, bT, bR, bB, luasMax = nil, nil, nil, nil, -1
                for simpul in isi:gmatch("<node[^>]*>") do
                    if simpul:find('package="' .. pkg .. '"', 1, true) then
                        local x1, y1, x2, y2 = simpul:match(
                            'bounds="%[(%-?%d+),(%-?%d+)%]%[(%-?%d+),(%-?%d+)%]"')
                        if x1 then
                            x1, y1, x2, y2 = tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2)
                            local luas = (x2 - x1) * (y2 - y1)
                            if luas > luasMax then
                                luasMax = luas; bL, bT, bR, bB = x1, y1, x2, y2
                            end
                        end
                    end
                end
                if bL then return { L = bL, T = bT, R = bR, B = bB } end
            end
        end
        -- yang kepotret bukan client ini -> coba sekali lagi
    end
    return nil, "yang di depan bukan " .. pkg:gsub("com%.roblox%.", "") ..
                " (client-nya jalan? jendelanya nongol?)"
end

-- v4.88: pencet titik di dalam jendela client, ditunjuk pakai PECAHAN (0..1)
-- dari kotak jendelanya -- bukan koordinat layar. Jadi angka yang sama kepakai
-- di semua client, walau petaknya beda-beda.
-- v5.07: 'kotak' boleh dioper dari luar -- kalau udah diukur, gak usah diukur
-- ulang. Ngukur itu 2 panggilan su (~12 detik); pas nyapu 8 titik, itu doang
-- bisa makan 1,5 menit percuma.
local function tap_jendela(cfg, pkg, fx, fy, kali, kotak)
    local sebab
    if not kotak then
        kotak, sebab = jendela_kotak(pkg)
        if not kotak then return nil, sebab end
    end
    local x = math.floor(kotak.L + (kotak.R - kotak.L) * fx)
    local y = math.floor(kotak.T + (kotak.B - kotak.T) * fy)
    local perintah = {}
    for _ = 1, (kali or 1) do
        perintah[#perintah+1] = "input tap " .. x .. " " .. y
    end
    -- digabung jadi SATU panggilan su -- di RedFinger tiap 'su' makan ~6 detik
    sh("su -c '" .. table.concat(perintah, "; sleep 0.4; ") .. " 2>&1'")
    return { x = x, y = y, kotak = kotak }
end

-- v4.90: jalanin perintah yang butuh waktu lama. sh() dipatok 8 detik (sengaja,
-- biar 'su' yang hang gak nahan worker), jadi buat rekam sentuhan perlu jalur
-- sendiri.
local function jalan_lama(cmd, detik)
    local h = io.popen("timeout " .. (detik or 30) .. " " .. cmd .. " 2>/dev/null")
    if not h then return "" end
    local o = h:read("*all") or ""
    h:close()
    return o
end

-- v4.90: REKAM SENTUHAN. Daripada nebak-geser angka, lebih enak: user pencet
-- sendiri tombolnya, worker nyatet koordinatnya.
-- Jebakannya: getevent ngasih koordinat PANEL sentuh (arah aslinya, portrait),
-- sedangkan layar RF dikunci landscape -- jadi sumbunya keputar. Daripada nebak
-- rumus putarannya, dicoba KEEMPAT kemungkinan, terus dipilih yang jatuh DI
-- DALAM kotak jendela client. Cara ini benerin dirinya sendiri.
-- v4.91: ukuran layar APA ADANYA (gak dituker walau landscape). Panel sentuh
-- lapornya dalam arah fisik, jadi pembaginya harus yang ini -- bukan
-- layar_ukuran() yang udah dituker buat landscape.
local function layar_fisik()
    local o = sh("su -c 'wm size'") or ""
    local w, h = o:match("Override size:%s*(%d+)x(%d+)")
    if not w then w, h = o:match("Physical size:%s*(%d+)x(%d+)") end
    return tonumber(w) or 0, tonumber(h) or 0
end


-- v4.98: DAFTAR ARAH YANG MUNGKIN SECARA FISIK.
-- Panel sentuh lapor dalam arah aslinya. Kalau panel TEGAK (720x1280) sedangkan
-- layar REBAH (1280x720), maka "apa adanya" dan "dibalik" MUSTAHIL -- sumbu X
-- panel cuma sampai 720, gak mungkin ngisi lebar layar 1280. Nyisain 2 arah.
-- Dulu keempatnya dicoba, dan yang mustahil sering kepilih (asal jatuh di dalam
-- jendela) -- itu yang bikin hasilnya ngawur pas jendelanya gede.
local function arah_calon(maxX, maxY, W, H)
    local bedaArah = ((maxY > maxX) ~= (H > W))
    if bedaArah then
        return {
            { nama = "diputar kanan", x = function(nx, ny) return 1 - ny end,
                                      y = function(nx, ny) return nx end },
            { nama = "diputar kiri",  x = function(nx, ny) return ny end,
                                      y = function(nx, ny) return 1 - nx end },
        }
    end
    return {
        { nama = "apa adanya", x = function(nx, ny) return nx end,
                               y = function(nx, ny) return ny end },
        { nama = "dibalik",    x = function(nx, ny) return 1 - nx end,
                               y = function(nx, ny) return 1 - ny end },
    }
end

-- v5.16: penengah kalau tap-nya ambigu (dua arah sama-sama jatuh di dalam
-- jendela). Cuma kejadian kalau jendelanya hampir sepenuh layar -- di ukuran
-- grid beneran (226x293 / 610x330) risikonya 0%. Patokannya setelan putaran
-- layar Android: rotasi 1 -> "diputar kiri", rotasi 3 -> "diputar kanan".
local function arah_dari_rotasi(maxX, maxY, W, H)
    local rot = tonumber((sh("su -c 'settings get system user_rotation'") or ""):match("%d+"))
    if not rot then return nil end
    local calon = arah_calon(maxX, maxY, W, H)
    for _, c in ipairs(calon) do
        if (rot == 1 and c.nama == "diputar kiri")
        or (rot == 3 and c.nama == "diputar kanan")
        or ((rot == 0 or rot == 2) and (c.nama == "apa adanya" or c.nama == "dibalik")) then
            return c, rot
        end
    end
    return nil, rot
end

-- v4.98: KUNCI ARAH pakai patokan. Dikasih satu sentuhan yang SUDAH DIKETAHUI
-- mestinya jatuh di mana (mis. tengah jendela), dipilih arah yang hasilnya
-- paling dekat ke situ. Sekali terkunci, dipakai buat semua sentuhan berikutnya
-- -- gak ada tebak-tebakan per sentuhan lagi.
local function kunci_arah(sx, sy, maxX, maxY, W, H, sasX, sasY)
    local nx, ny = sx / maxX, sy / maxY
    local juara, jarakJuara
    for _, c in ipairs(arah_calon(maxX, maxY, W, H)) do
        local X, Y = c.x(nx, ny) * W, c.y(nx, ny) * H
        local d = math.sqrt((X - sasX) ^ 2 + (Y - sasY) ^ 2)
        if not jarakJuara or d < jarakJuara then juara, jarakJuara = c, d end
    end
    return juara, jarakJuara
end

-- v4.97: ubah SATU sentuhan mentah jadi titik layar + pecahan jendela.
-- v4.98: kalau 'arah' dikasih, pakai itu (udah terkunci). Kalau nggak, jatuh ke
-- cara lama: coba yang mungkin, ambil yang jatuh di dalam kotak.
local function sentuh_ke_pecahan(sx, sy, maxX, maxY, W, H, kotak, arah)
    local snx, sny = sx / maxX, sy / maxY
    local coba = arah and { arah } or arah_calon(maxX, maxY, W, H)
    for _, c in ipairs(coba) do
        local X, Y = c.x(snx, sny) * W, c.y(snx, sny) * H
        local didalam = (X >= kotak.L and X <= kotak.R and Y >= kotak.T and Y <= kotak.B)
        if arah or didalam then
            return { X = math.floor(X), Y = math.floor(Y), cara = c.nama, didalam = didalam,
                     fx = (X - kotak.L) / (kotak.R - kotak.L),
                     fy = (Y - kotak.T) / (kotak.B - kotak.T) }
        end
    end
    return nil
end

local function rekam_sentuh(pkg, kotak, detik)
    local berkas = "/sdcard/zenx_ev.txt"
    sh_silent("su -c 'rm -f " .. berkas .. "'")
    jalan_lama("su -c 'timeout " .. (detik or 30) .. " getevent -l > " .. berkas .. "'",
               (detik or 30) + 8)
    local isi = sh("su -c 'cat " .. berkas .. " 2>/dev/null'") or ""
    sh_silent("su -c 'rm -f " .. berkas .. "'")
    if not isi:match("%S") then return nil, "gak ada kejadian kerekam (getevent gagal?)" end

    -- ambil pasangan X/Y TERAKHIR
    -- v4.95: KUMPULIN SEMUA sentuhan, bukan cuma satu.
    -- Dulu diambil yang pertama -- tapi gerakan PINDAH ke jendela client itu
    -- sendiri kecatat sebagai sentuhan, dan itu yang keambil (padahal bukan
    -- tombolnya). Sekarang: semua dikumpulin, dipilih yang pertama JATUH DI
    -- DALAM kotak jendela. Jadi mencet berkali-kali pun aman -- pencetan yang
    -- di luar jendela (pindah aplikasi, browser) kesaring sendiri.
    local xs, ys = {}, {}
    for nilai in isi:gmatch("ABS_MT_POSITION_X%s+(%x+)") do xs[#xs+1] = tonumber(nilai, 16) end
    for nilai in isi:gmatch("ABS_MT_POSITION_Y%s+(%x+)") do ys[#ys+1] = tonumber(nilai, 16) end
    if #xs == 0 then
        for nilai in isi:gmatch("ABS_X%s+(%x+)") do xs[#xs+1] = tonumber(nilai, 16) end
        for nilai in isi:gmatch("ABS_Y%s+(%x+)") do ys[#ys+1] = tonumber(nilai, 16) end
    end
    local px, py = xs[1], ys[1]
    -- v4.93: dijaga SEBELUM diubah. Dulu langsung tonumber(nil,16) -> meledak,
    -- padahal ini keadaan wajar (kelamaan mencet / kelewat waktunya).
    if not px or not py then
        -- bedain "gak kepencet" vs "getevent-nya emang gak ngerekam apa-apa"
        local nBaris = 0
        for _ in isi:gmatch("\n") do nBaris = nBaris + 1 end
        local adaSentuh = isi:find("BTN_TOUCH", 1, true) ~= nil
        if nBaris <= 5 then
            return nil, "getevent gak ngerekam apa-apa (" .. nBaris .. " baris) -- root/izinnya?"
        elseif adaSentuh then
            return nil, "ada sentuhan kerekam tapi koordinatnya gak kebaca (format lain?)"
        end
        return nil, "gak ada sentuhan dalam " .. (detik or 30) ..
                    " detik (" .. nBaris .. " baris kerekam) -- kelewat waktunya?"
    end
    -- v4.96: JANGAN di-tonumber lagi di sini. Sejak v4.95 nilainya udah diubah
    -- jadi bilangan pas dikumpulin ke xs/ys -- konversi kedua bikin error
    -- ("string expected, got number"). Baris pemeriksaan dobel juga dibuang.

    -- batas panel sentuh (buat ngubah ke ukuran layar)
    local prop = sh("su -c 'getevent -p 2>&1'") or ""
    local maxX, maxY
    for a, b in prop:gmatch("0035%s*:%s*value %d+, min %d+, max (%d+)()") do maxX = tonumber(a) end
    for a in prop:gmatch("0036%s*:%s*value %d+, min %d+, max (%d+)") do maxY = tonumber(a) end

    local W, H = layar_ukuran()          -- layar tampilan (udah dituker kalau landscape)
    local fW, fH = layar_fisik()         -- panel sentuh (arah fisik, gak dituker)
    if not maxX or maxX <= 0 then maxX = (fW > 0) and fW or W end
    if not maxY or maxY <= 0 then maxY = (fH > 0) and fH or H end

    -- v4.95: coba tiap sentuhan (urut), tiap arah -- ambil yang pertama jatuh
    -- di dalam kotak jendela.
    for i = 1, math.min(#xs, #ys) do
        local sx, sy = xs[i], ys[i]
        local snx, sny = sx / maxX, sy / maxY
        local arah = {
            { nama = "apa adanya",    x = snx,     y = sny },
            { nama = "diputar kanan", x = 1 - sny, y = snx },
            { nama = "diputar kiri",  x = sny,     y = 1 - snx },
            { nama = "dibalik",       x = 1 - snx, y = 1 - sny },
        }
        for _, c in ipairs(arah) do
            local X, Y = c.x * W, c.y * H
            if X >= kotak.L and X <= kotak.R and Y >= kotak.T and Y <= kotak.B then
                return { fx = (X - kotak.L) / (kotak.R - kotak.L),
                         fy = (Y - kotak.T) / (kotak.B - kotak.T),
                         X = math.floor(X), Y = math.floor(Y),
                         cara = c.nama, mentahX = sx, mentahY = sy,
                         keBerapa = i, total = math.min(#xs, #ys) }
            end
        end
    end
    return nil, (math.min(#xs, #ys) .. " sentuhan kerekam, tapi GAK ADA yang jatuh " ..
                 "di kotak jendela [" .. kotak.L .. "," .. kotak.T .. "]-[" ..
                 kotak.R .. "," .. kotak.B .. "] -- kepencetnya di luar jendela client?")
end

-- ============================================================
-- v5.00: CARI TOMBOL KEY SENDIRI (nyapu + diverifikasi + diinget)
--
-- Kenapa nyapu, bukan dikalibrasi sekali: layar client GAK BISA diintip sama
-- sekali di RedFinger -- uiautomator nol simpul teks, logcat gak nyatet URL-nya,
-- berkas gak nyimpen. Semua jalur udah dicoba, buntu.
--
-- TAPI keberhasilannya BISA diperiksa: habis mencet, papan klip keisi link key
-- atau nggak. Jawabannya pasti. Jadi worker gak perlu tau tombolnya di mana --
-- dia coba beberapa titik, tiap kali diperiksa, berhenti pas kena.
--
-- Diinget PER UKURAN JENDELA. Worker sendiri yang naruh ukuran jendela (lewat
-- prefs App Cloner), jadi ukurannya terbatas: 4 client sekian, 6 client sekian.
-- Sekali ketemu buat satu ukuran, besoknya langsung tembak -- gak nyapu lagi.
-- Ukuran berubah (ganti jumlah client) -> nyapu sekali lagi, terus diinget juga.
-- ============================================================
local TAP_FILE = "zenx_tap.txt"

-- titik sapuan. v5.10: gak cuma garis tengah lagi.
-- Awalnya cuma x=0.5 karena tombolnya panjang -- tapi itu berasumsi dialognya
-- pas di tengah jendela. Di jendela sempit, dialognya bisa mepet/kepotong,
-- jadi garis tengah doang bisa gak pernah kena.
-- Sekarang: garis tengah DULU (paling mungkin), baru melebar kiri-kanan.
-- Urutannya sengaja dari yang paling mungkin -- makin cepet ketemu, makin
-- sedikit ronde yang kepakai.
-- v5.12: titik pinggir (0.22 / 0.78) DICABUT. Dari pengamatan lapangan, dialog
-- Delta gak ngisi penuh jendela client -- sisanya tembus pandang, jadi pencetan
-- di situ NEMBUS ke Termux di belakangnya (kelihatan kayak "Roblox masuk
-- background"). Percuma disapu.
-- Gantinya: garis tengah dirapetin (langkah 0,05), soalnya tombolnya panjang --
-- yang perlu dicari cuma TINGGINYA, bukan kiri-kanannya.
-- v5.17: DIBETULIN PAKAI DATA LAPANGAN. Dulu semua titik ada di garis tengah
-- (x=0.5) -- itu asumsi gua bahwa dialognya di tengah jendela. SALAH: hasil
-- kalibrasi manual nunjukin tombolnya di x=0.81, jauh ke kanan. Makanya sapuan
-- lama gak pernah kena, seberapa rapat pun titik Y-nya.
-- Sekarang: kolom kanan (0.81) didahuluin, baru tengah, baru kiri.
-- v5.21: disusun ulang pakai HASIL KALIBRASI NYATA di tiga bentuk grid:
--   1 baris (610x653) -> 0.844 , 0.713
--   2 baris (396x293) -> 0.823 , 0.723
--   3 baris (348x173) -> 0.833 , 0.808
-- X-nya STABIL di ~0.83 semua -- yang geser cuma Y (makin pendek jendelanya,
-- makin ke bawah). Jadi sapuan difokusin di kolom 0.83, Y-nya yang diayak.
local TITIK_SAPU = {
    -- kolom 0.83, Y persis di tiga titik yang kebukti dulu
    { 0.83, 0.72 }, { 0.83, 0.81 }, { 0.83, 0.71 },
    -- Y di antara & di luar ketiganya
    { 0.83, 0.76 }, { 0.83, 0.66 }, { 0.83, 0.86 }, { 0.83, 0.61 },
    { 0.83, 0.90 }, { 0.83, 0.56 },
    -- geser kiri-kanan sedikit, kalau-kalau tata letaknya beda
    { 0.75, 0.72 }, { 0.90, 0.72 }, { 0.75, 0.81 }, { 0.90, 0.81 },
    -- garis tengah & kiri: jaring terakhir
    { 0.50, 0.72 }, { 0.50, 0.81 }, { 0.25, 0.72 },
}

local function tap_muat()
    local t = {}
    local f = io.open(TAP_FILE, "r")
    if not f then return t end
    for baris in f:lines() do
        local k, fx, fy = baris:match("^(%d+x%d+)%s+([%d.]+)%s+([%d.]+)")
        if k then t[k] = { fx = tonumber(fx), fy = tonumber(fy) } end
    end
    f:close()
    return t
end

local function tap_simpan(kunci, fx, fy)
    local t = tap_muat()
    t[kunci] = { fx = fx, fy = fy }
    local f = io.open(TAP_FILE, "w")
    if not f then return false end
    for k, v in pairs(t) do
        f:write(("%s %.3f %.3f\n"):format(k, v.fx, v.fy))
    end
    f:close()
    return true
end

-- Android 10+ cuma ngizinin baca papan klip kalau aplikasinya LAGI DI DEPAN.
-- Jadi Termux dimunculin sebentar, dibaca, terus balik lagi ke client.
local function baca_klip()
    sh_silent("su -c 'am start -n com.termux/com.termux.app.TermuxActivity'")
    os.execute("sleep 2")
    local h = io.popen("timeout 10 termux-clipboard-get 2>/dev/null")
    local isi = h and (h:read("*all") or "") or ""
    if h then h:close() end
    return (isi:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- link key yang sah? (jangan ketipu sisa salinan lama)
local function klip_link_key(isi)
    if not isi or isi == "" then return nil end
    local link = isi:match("(https?://[^%s\"']+)")
    if not link then return nil end
    if link:find("platorelay", 1, true) or link:find("?d=", 1, true)
       or link:find("&d=", 1, true) then
        return link
    end
    return nil
end

-- balikin: link, fx, fy, keterangan
local function cari_tombol_key(cfg, pkg)
    local kotak, sebab = jendela_kotak(pkg)
    if not kotak then return nil, nil, nil, "gagal baca kotak jendela: " .. tostring(sebab) end
    local lebar  = kotak.R - kotak.L
    local tinggi = kotak.B - kotak.T
    local kunci  = ("%dx%d"):format(lebar, tinggi)

    -- kosongin papan klip dulu, biar sisa salinan lama gak dikira berhasil
    os.execute("printf '' | timeout 10 termux-clipboard-set >/dev/null 2>&1")

    -- urutan coba: yang UDAH KEINGET buat ukuran ini duluan, baru sapuan
    local urut = {}
    local inget = tap_muat()[kunci]
    if inget then
        urut[#urut+1] = { inget.fx, inget.fy, ingetan = true }
    end
    for _, t in ipairs(TITIK_SAPU) do
        if not (inget and math.abs(t[1] - inget.fx) < 0.01 and math.abs(t[2] - inget.fy) < 0.01) then
            urut[#urut+1] = { t[1], t[2] }
        end
    end

    for i, t in ipairs(urut) do
        -- v5.14: bisa DIHENTIKAN. Dulu perintah panjang kayak gini gak pernah
        -- ngecek tanda berhenti -- 'zenx stop' cuma nyetop loop worker, dan
        -- Ctrl+C sering gak nyampe kalau lagi nunggu 'su'. Jadi sapuan yang
        -- lagi jalan gak bisa dibatalin sama sekali.
        if ada_stop() then
            return nil, nil, nil, "dihentikan (zenx stop)"
        end
        -- v5.08: client HARUS beneran di depan sebelum ditembak. Ronde
        -- sebelumnya mindahin fokus ke Termux buat baca papan klip, dan Termux
        -- itu layar penuh -- nutupin jendela client yang ngambang.
        local naik, siapa = pastikan_depan(pkg)
        if not naik then
            return nil, nil, nil, ("gagal munculin " .. pkg:gsub("com%.roblox%.", "") ..
                   " ke depan (yang di depan: " .. tostring(siapa) .. ")" ..
                   (BAWA_SEBAB and (" -- " .. BAWA_SEBAB) or ""))
        end
        io.write(("\r   titik %d/%d  (%.2f, %.2f) ...          "):format(i, #urut, t[1], t[2]))
        io.flush()
        tap_jendela(cfg, pkg, t[1], t[2], 2, kotak)   -- 2x, pakai kotak yang udah diukur
        os.execute("sleep 2")

        local link = klip_link_key(baca_klip())
        if link then
            tap_simpan(kunci, t[1], t[2])
            return link, t[1], t[2],
                   (t.ingetan and "pakai ingatan" or ("ketemu di percobaan ke-" .. i))
                   .. " (" .. kunci .. ")"
        end
    end

    return nil, nil, nil, ("dicoba " .. #urut .. " titik di jendela " .. kunci ..
                           ", papan klip tetep kosong")
end

local function config_set_bypass(apikey)
    local f = io.open(CONFIG_FILE, "r")
    if not f then
        return false, "config gak ada -- jalanin `zenx` dulu buat setup"
    end
    local isi = f:read("*all") or ""
    f:close()

    local baris = string.format('  bypass_api_key=%q,', apikey)
    local baru
    if isi:find("bypass_api_key%s*=") then
        -- ganti yang lama, SATU baris utuh (pakai fungsi, biar '%' di kunci
        -- gak dianggap kode pengganti)
        baru = isi:gsub('[ \t]*bypass_api_key%s*=%s*"[^"]*"[ \t]*,?[ \t]*\r?\n?',
                        function() return baris .. "\n" end, 1)
    else
        -- sisipin sebelum '}' penutup
        local pos = isi:match("^.*()}")
        if not pos then return false, "bentuk config gak dikenali" end
        baru = isi:sub(1, pos - 1) .. baris .. "\n" .. isi:sub(pos)
    end

    -- === DITES DI MEMORI DULU ===
    local uji = load("return " .. baru)
    if not uji then
        return false, "hasil editan gak sah -- config LAMA GAK DISENTUH"
    end
    local sah, hasil = pcall(uji)
    if not sah or type(hasil) ~= "table" then
        return false, "hasil editan gak sah -- config LAMA GAK DISENTUH"
    end
    if (hasil.bypass_api_key or "") ~= apikey then
        return false, "kunci gak kebaca balik -- config LAMA GAK DISENTUH"
    end

    -- cadangan dulu, biar ada jalan pulang kalau ada apa-apa
    local bak = io.open(CONFIG_FILE .. ".bak", "w")
    if bak then bak:write(isi); bak:close() end

    local g = io.open(CONFIG_FILE, "w")
    if not g then return false, "gak bisa nulis config (izin?)" end
    g:write(baru)
    g:close()
    return true
end

-- ============================================================
-- v4.2: BISA DIMATIIN
-- Dulu satu-satunya cara berhenti itu `pkill -f zenx_worker.lua` — mati
-- mendadak: notif nyangkut, wake-lock kepegang, panel gak tau dia mati.
--
-- Lua polos gak bisa nangkep sinyal (kill/Ctrl+C) tanpa luaposix, jadi
-- dipake FLAG FILE: `stop` bikin file, loop utama ngecek tiap putaran,
-- terus keluar baik-baik.
-- ============================================================

local function tulis_pid()
    local pid = tonumber(sh("echo $PPID")) or 0
    local f = io.open(PID_FILE, "w")
    if f then f:write(tostring(pid)); f:close() end
    return pid
end

local function baca_pid()
    local f = io.open(PID_FILE, "r"); if not f then return nil end
    local p = tonumber(f:read("*l")); f:close(); return p
end

local function pid_hidup(pid)
    if not pid then return false end
    return sh("ps -p " .. pid .. " -o comm=") ~= ""
end


local function hapus(f) os.remove(f) end

-- dipanggil pas keluar baik-baik: beresin semua yang nyangkut
local function bersih(cfg, sebab)
    print()
    info("Beres-beres (" .. (sebab or "?") .. ")...")
    sh_silent("termux-notification-remove zenx_worker")
    sh_silent("termux-wake-unlock")
    hapus(PID_FILE)
    hapus(STOP_FILE)
    shell_matikan()   -- v4.70: tutup shell root tetap + bersihin pipa
    ok("Worker berhenti.")
end

-- ============================================================
-- API — Cloudflare Worker
-- ============================================================
local TMP = "/data/data/com.termux/files/usr/tmp/zenx_body.json"

local function api_get(cfg, jalur)
    local cmd = string.format("curl -s -m 10 -H %s %s",
        shq("X-Kunci: " .. cfg.kunci), shq(cfg.url .. jalur))
    return sh(cmd)
end

-- v5.39: metode bisa dipilih (bawaan POST, biar pemakaian lama gak berubah).
-- Perlu karena /perintah minta PUT -- dan tanpa ini setup gak bisa nyetel
-- perintah awal sendiri.
local function api_post(cfg, jalur, body, metode)
    local f = io.open(TMP, "w")
    if not f then TMP = "./zenx_body.json"; f = io.open(TMP, "w") end
    if not f then return "" end
    f:write(body); f:close()
    local cmd = string.format("curl -s -m 10 -X %s -H %s -H %s -d @%s %s",
        (metode or "POST"),
        shq("X-Kunci: " .. cfg.kunci), shq("Content-Type: application/json"),
        TMP, shq(cfg.url .. jalur))
    return sh(cmd)
end

-- JSON kecil doang, cukup pola. gak perlu library.
local function ambil_str(js, k) return tostring(js or ""):match('"'..k..'"%s*:%s*"(.-)"') end
local function ambil_num(js, k) return tonumber(tostring(js or ""):match('"'..k..'"%s*:%s*(-?%d+)')) end
-- v4.32: escape LENGKAP. Dulu cuma \ dan " -- baris baru/tab dari output shell
-- lolos mentah ke JSON -> laporan RUSAK -> Cloudflare nolak -> panel kira worker
-- MATI padahal jalan. Sekarang semua karakter kontrol ikut di-escape.
local function jstr(s)
    s = tostring(s or ""):gsub('\\','\\\\'):gsub('"','\\"')
    s = s:gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
    s = s:gsub('%c', ' ')   -- sisa karakter kontrol lain -> spasi
    return '"'..s..'"'
end

-- ============================================================
-- v5.31: KUNCI API bypass DIAMBIL DARI PANEL kalau config kosong.
--
-- Dulu ditanyain di SETIAP setup RF. 20 RF = 20 kali ngetik kunci yang sama,
-- dan tiap salah ketik = `zenx key` gagal tanpa sebab yang jelas.
--
-- Sekarang urutannya:
--   1. config lokal (kalau diisi manual, itu yang menang -- bisa beda per RF)
--   2. panel (/bypass-key) -- diisi SEKALI di sana, semua RF kebagian
-- Hasil dari panel di-cache di memori; kalau panel mati, yang udah kepegang
-- tetep kepakai sampai worker restart.
--
-- Tetep GAK masuk GitHub: kuncinya ada di D1, bukan di berkas yang di-push.
-- ============================================================
local BYPASS_CACHE, BYPASS_CACHE_TS = nil, 0

ambil_apikey = function(cfg)
    -- 1. config lokal MENANG -- buat RF yang sengaja dikasih kunci beda
    --    (`zenx key set <APIKEY>`)
    local lokal = cfg and cfg.bypass_api_key or ""
    if lokal ~= "" then return lokal, "config" end

    -- 2. bawaan yang ditaruh di file ini. Dipakai LANGSUNG -- gak nanya panel,
    --    jadi nol delay dan gak bergantung panel idup apa nggak.
    if BYPASS_KEY_BAWAAN ~= "" then return BYPASS_KEY_BAWAAN, "bawaan" end

    -- 3. panel -- cuma kepakai kalau BYPASS_KEY_BAWAAN dikosongin
    --    (mis. repo dijadiin publik)
    -- cache masih segar (10 menit) -> pakai itu
    if BYPASS_CACHE and BYPASS_CACHE ~= "" and (os.time() - BYPASS_CACHE_TS) < 600 then
        return BYPASS_CACHE, "panel (cache)"
    end

    local r = api_get(cfg, "/bypass-key") or ""
    if r ~= "" then
        local k = ambil_str(r, "key")
        if k and k ~= "" then
            BYPASS_CACHE, BYPASS_CACHE_TS = k, os.time()
            -- v5.32: SIMPEN KE CONFIG LOKAL. Sekali narik, habis itu gak
            -- pernah butuh panel lagi -- instan, dan tetep jalan walau panel
            -- lagi mati pas lisensi Delta abis (itu justru saat paling
            -- genting). Ini yang bikin gak perlu ngetik manual TANPA harus
            -- naruh kunci di berkas yang di-push ke GitHub.
            if cfg then
                cfg.bypass_api_key = k
                local okS = pcall(function() save_config(cfg) end)
                if okS then ok("Kunci API disimpen ke config RF ini -- gak narik dari panel lagi.") end
            end
            return k, "panel"
        end
        -- endpoint ada tapi kuncinya belum diisi
        if not ambil_str(r, "error") then return "", "panel (kosong)" end
    end
    -- panel gak jawab tapi cache lama masih ada -> lebih baik dipakai
    if BYPASS_CACHE and BYPASS_CACHE ~= "" then
        return BYPASS_CACHE, "panel (cache lama)"
    end
    return "", "gak ada"
end


-- ============================================================
-- deteksi client
-- ============================================================
-- v4.34: JALAN DARURAT. Kalau penanda "ActivityNativeMain" gak cocok lagi
-- (Roblox ganti nama activity / bentuk dumpsys beda), client kebaca OFF terus
-- padahal game jalan. Set deteksi_longgar=true di config -> cukup "ada
-- ActivityRecord" dianggap jalan. Efek samping: Roblox yang nyangkut di Home
-- ikut kebaca "jalan". Bridge (/stat) tetep jadi penentu sebenernya.
local DETEKSI_LONGGAR = false
-- v4.36: Roblox GANTI NAMA activity. Dulu cuma dikenal "ActivityNativeMain";
-- di Roblox baru namanya "com.roblox.client.startup.MainGameActivity". Worker
-- nyari nama lama -> gak pernah ketemu -> client SELALU kebaca off padahal
-- game jalan normal. Sekarang dua-duanya (plus varian *GameActivity) dikenal.
local PENANDA_GAME = { "ActivityNativeMain", "MainGameActivity" }

local function pkg_running(pkg)
    -- "beneran DI GAME" -- bukan cuma "ada ActivityRecord" (Home Roblox,
    -- key system, splash JUGA punya ActivityRecord tapi BUKAN di game).
    local o = sh("su -c 'dumpsys activity activities | grep ActivityRecord | grep " .. pkg .. "'")
    for line in o:gmatch("[^\n]+") do
        if line:find(pkg, 1, true) then
            for _, tanda in ipairs(PENANDA_GAME) do
                if line:find(tanda, 1, true) then return true end
            end
        end
    end
    -- v4.34: mode longgar -> ada ActivityRecord buat paket ini = dianggap jalan
    if DETEKSI_LONGGAR then
        for line in o:gmatch("[^\n]+") do
            if line:find(pkg, 1, true) then return true end
        end
    end
    return false
end

-- v4.29: ID device -- dipakai buat "1 tim = 1 RedFinger".
-- android_id nempel per-device & gak berubah kecuali factory reset.
local DEV_ID_CACHE
-- v4.63: cek status SEMUA client dari SATU dump. Dulu pkg_running dipanggil
-- per client -- tiap panggilan 'su' di RedFinger ~6 detik, jadi 4 client = ~24
-- detik. Padahal ini jalan tiap 10 detik -> worker lebih banyak nunggu su
-- daripada kerja, dan perintah panel jadi telat dieksekusi.
local function pkg_running_semua(pkgs)
    local hasil = {}
    for _, p in ipairs(pkgs) do hasil[p] = false end
    local o = sh("su -c 'dumpsys activity activities | grep ActivityRecord'") or ""
    for baris in o:gmatch("[^\r\n]+") do
        for _, p in ipairs(pkgs) do
            if not hasil[p] and baris:find(p, 1, true) then
                for _, tanda in ipairs(PENANDA_GAME) do
                    if baris:find(tanda, 1, true) then hasil[p] = true break end
                end
                if DETEKSI_LONGGAR then hasil[p] = true end
            end
        end
    end
    return hasil
end

local function dev_id()
    if DEV_ID_CACHE then return DEV_ID_CACHE end
    local id = (sh("su -c 'settings get secure android_id'") or ""):match("%w+")
    if not id or id == "null" or #id < 4 then
        id = (sh("su -c 'getprop ro.serialno'") or ""):match("%S+")
    end
    if not id or id == "" or id == "unknown" then
        id = "rf-" .. tostring(os.time())   -- terakhir banget: acak sekali
    end
    DEV_ID_CACHE = id
    return id
end

-- ============================================================
-- v4.17: konfirmasi BENERAN di game lewat bridge (/stat)
-- Home Roblox = ActivityNativeMain JUGA -> pkg_running gak bisa bedain Home
-- vs in-game. Yg beneran nandain di dalam game + script jalan = akun LAPOR
-- ke /stat (bridge cuma denyut dari dalam game). Sama persis kayak auto-rejoin.
-- ============================================================
local KONFIRMASI_POLL = 3    -- poll /stat tiap brp detik pas nungguin masuk game
-- v4.60 FIX: dulu 45 detik -- padahal script cuma lapor tiap 120 detik kalau
-- gak ada perubahan. Akibatnya client SEHAT sering keliatan basi -> gak dilewat
-- -> DIBUNUH & DIBUKA ULANG percuma, terus ditungguin lapor lagi. Itu yang bikin
-- kerasa "nunggu lama padahal client udah aman".
-- Sekarang 200 detik: lebih longgar dari jarak lapor (120) + toleransi CPU 100%.
-- v4.68: dari 200 -> 300. Script lapor tiap 120 detik, TAPI pas CPU 100% loop
-- script molor bisa 2x -> laporan nyatanya tiap ~240 detik. Ambang 200 nyisain
-- jarak cuma 80 detik: sekali molor, client SEHAT keliatan basi terus ditutup &
-- dibuka ulang percuma. 300 ngasih toleransi 1,5x jarak lapor.
local FRESH_WINDOW    = 300  -- akun "masih di game" kalau lapor <= sekian detik lalu

-- ambil ts (kapan terakhir akun lapor) dari string /stat
local function bridge_ts(stat, akun)
    if not stat or not akun then return nil end
    local blok = stat:match('{[^{}]-"nama"%s*:%s*"' .. akun .. '"[^{}]-}')
    return blok and tonumber(blok:match('"ts"%s*:%s*(%d+)')) or nil
end

-- true kalau akun lapor fresh (masih beneran di game SEKARANG)
local function bridge_fresh(stat, akun)
    local ts = bridge_ts(stat, akun)
    -- v4.53 FIX: "skrg" di /stat itu ANGKA, tapi dulu dibaca pakai ambil_str
    -- (khusus teks berkutip) -> SELALU nil -> fungsi ini SELALU balik false.
    -- Akibatnya: semua client kebaca "beku", dan skip-check di open_all gak
    -- pernah kena (client yang udah jalan tetep dibuka ulang).
    local skrg = ambil_num(stat, "skrg")
    if not ts or not skrg then return false end
    return (skrg - ts) <= FRESH_WINDOW
end

-- tungguin akun lapor BARU (ts > ts0) -> tanda script mulai jalan -> BENERAN masuk game.
-- ts0 = ts sebelum client dibuka (bisa nil kalau belum pernah lapor).
-- return true kalau kedeteksi masuk, false kalau timeout / dibatalin.
-- v4.42: dideklarasi di depan -- tunggu_bridge perlu manggil ini, padahal
-- definisinya jauh di bawah (butuh build_url dll).
local cek_layar

local INTIP_DETIK = 30   -- v4.42: kapan mulai ngintip layar (detik)
local INTIP_ULANG = 10   -- v4.44: jeda sebelum cek ULANG (mastiin beneran nyangkut)
local function tunggu_bridge(cfg, akun, ts0, batas, cek_batal, pkg, mapLink)
    local mulai = os.time()
    local sudahIntip = false
    -- v4.41: kalau client MASIH di layar game, kasih perpanjangan. Pas CPU 100%
    -- rantai "load game -> Delta inject -> script jalan -> lapor pertama" bisa
    -- lewat 90 detik. Dulu langsung divonis nyangkut -> client SEHAT dibunuh ->
    -- ngulang dari nol -> makin lama. Sekarang: selama masih di layar game,
    -- ditungguin (maks 2x batas). Kalau kelempar dari game, langsung nyerah.
    local batasMax = batas * 2
    while (os.time() - mulai) < batasMax do
        if cek_batal and cek_batal() then return false end
        local ts = bridge_ts(api_get(cfg, "/stat"), akun)
        if ts and (not ts0 or ts > ts0) then return true end
        -- v4.42: jangan cuma nungguin bridge diem sampai 90 detik baru sadar.
        -- Setelah INTIP_DETIK, lihat layarnya sekali: kalau nyangkut di Home /
        -- popup umur / ada error, langsung ketauan -- gak usah nunggu penuh.
        if (not sudahIntip) and (os.time() - mulai) >= INTIP_DETIK and pkg and cek_layar then
            sudahIntip = true
            local pesan, sifat, sidik1 = cek_layar(cfg, pkg, mapLink)
            if pesan and (sifat == "home" or sifat == "manual" or sifat == "ulang") then
                -- v4.44: JANGAN langsung divonis. Kadang beberapa detik kemudian
                -- dia lanjut masuk game sendiri (Home cuma numpang lewat).
                os.execute("sleep " .. INTIP_ULANG)
                local ts2 = bridge_ts(api_get(cfg, "/stat"), akun)
                if ts2 and (not ts0 or ts2 > ts0) then return true end   -- ternyata masuk
                local pesan2, sifat2, sidik2 = cek_layar(cfg, pkg, mapLink)
                if pesan2 then
                    -- Home / popup umur / error: itu layar DIEM, gak bakal lanjut
                    -- sendiri -> langsung vonis.
                    if sifat2 == "home" or sifat2 == "manual" or (pesan2:find("Error", 1, true)) then
                        return false, pesan2
                    end
                    -- Loading / layar kosong: cuma dianggap BEKU kalau layarnya
                    -- GAK BERUBAH. Kalau berubah, berarti masih jalan (loading
                    -- berat) -> jangan dibunuh, lanjut ditungguin.
                    if sidik1 and sidik2 and sidik1 == sidik2 then
                        return false, pesan2 .. " (layar gak gerak)"
                    end
                end
                -- udah gak nyangkut / masih gerak -> lanjut nungguin bridge kayak biasa
            end
        end
        if (os.time() - mulai) >= batas then
            -- lewat batas normal: cuma lanjut kalau masih di layar game
            if not (pkg and pkg_running(pkg)) then return false end
        end
        os.execute("sleep " .. KONFIRMASI_POLL)
    end
    return false
end

-- ============================================================
-- v4.18: orientasi layar RF + keep-alive (anti-FC)
-- ============================================================
-- kunci orientasi RF. "landscape"/"portrait" -> set, "" / nil -> jangan disenggol.
-- user_rotation: 0=portrait, 1=landscape, 2=portrait kebalik, 3=landscape kebalik.
local function set_orientasi(cfg)
    local o = (cfg.orientasi or ""):lower()
    if o ~= "landscape" and o ~= "portrait" then return end
    local rot = (o == "landscape") and 1 or 0
    sh("su -c 'settings put system accelerometer_rotation 0 >/dev/null 2>&1; " ..
       "settings put system user_rotation " .. rot .. " >/dev/null 2>&1'")
end

-- keep-alive / anti-FC. bikin client Roblox lebih tahan idup di background:
--   * deviceidle whitelist        -> lepas dari Doze
--   * appops RUN_IN_BACKGROUND     -> boleh jalan di background
--   * oom_score_adj rendah         -> OOM killer segan bunuh
-- Android suka RESET oom_score_adj balik -> makanya di-apply ULANG tiap ~menit.
-- PENTING: worker (Termux) dilindungin LEBIH kuat dari client. jadi kalau RAM
-- mentok, yg dikorbanin CLIENT (bisa di-rejoin), BUKAN worker (biar tetep mantau).
local OOM_CLIENT = -300   -- client: dilindungin, tapi masih bisa dikorbanin kalau kepepet
local OOM_WORKER = -800   -- worker: dilindungin lebih kuat, jangan sampe ke-kill
-- v4.62: SATU panggilan su buat SEMUA paket. Tiap 'su -c' di RedFinger makan
-- ~5 detik; dulu dipanggil per-paket (4 client = 5 panggilan = ~25 detik cuma
-- buat keep-alive). Sekarang digabung -> sekali jalan.
local function keep_alive_apply(cfg)
    if cfg.keep_alive == false then return end
    local bagian = {}
    for _, pkg in ipairs(split(cfg.pkgs)) do
        bagian[#bagian+1] = string.format(
            "dumpsys deviceidle whitelist +%s >/dev/null 2>&1; " ..
            "cmd appops set %s RUN_IN_BACKGROUND allow >/dev/null 2>&1; " ..
            "for p in $(pidof %s); do echo %d > /proc/$p/oom_score_adj 2>/dev/null; done",
            pkg, pkg, pkg, OOM_CLIENT)
    end
    -- lindungin worker sendiri LEBIH kuat (Termux app + proses worker ini)
    local wpid = baca_pid() or ""
    bagian[#bagian+1] = string.format(
        "dumpsys deviceidle whitelist +com.termux >/dev/null 2>&1; " ..
        "for p in $(pidof com.termux) %s; do echo %d > /proc/$p/oom_score_adj 2>/dev/null; done",
        wpid, OOM_WORKER)
    sh("su -c '" .. table.concat(bagian, "; ") .. "'")
end

-- ============================================================
-- buka Roblox
-- ============================================================
-- v4.83: JATAH BUNUH per client. Tanpa ini, client yang masalahnya emang GAK
-- bisa diselesaiin restart (link PS mati, akun kena limit, key belum masuk)
-- bakal dibunuh-buka terus tiap ronde: boros RAM, bikin client lain ikut
-- kesenggol, dan gak pernah kelar. Lewat jatah -> berhenti nyentuh, catet aja
-- biar keliatan di panel dan bisa dibenerin manual.
local KILL_CATAT  = {}
local KILL_MAKS   = 3      -- maks sekian kali bunuh...
local KILL_JENDELA = 1800  -- ...dalam sekian detik (30 menit) per client

local function sisa_jatah_kill(pkg)
    local skrg, sisa = os.time(), {}
    for _, w in ipairs(KILL_CATAT[pkg] or {}) do
        if (skrg - w) < KILL_JENDELA then sisa[#sisa+1] = w end
    end
    KILL_CATAT[pkg] = sisa
    return KILL_MAKS - #sisa
end

local function catat_kill(pkg)
    KILL_CATAT[pkg] = KILL_CATAT[pkg] or {}
    table.insert(KILL_CATAT[pkg], os.time())
end

local DEBUG_OPEN = false

local function build_url(cfg, link_client)
    -- v4.11: link PS PER-CLIENT (dari assign-ps panel). urutan prioritas:
    --   1. link_client (assign per akun dari panel) -- kalau dikasih
    --   2. cfg._ps_override (PS tim dari panel, lama)
    --   3. cfg.link_code (diketik di Termux)
    local lc = link_client
    if lc == nil or lc == "" then lc = cfg._ps_override end
    if lc == nil then lc = cfg.link_code or "" end
    lc = lc or ""
    -- v4.16: LINK SHARE MODERN (share?code=XXX&type=Server) -> code itu BUKAN
    -- linkCode! itu kode share yg harus di-RESOLVE Roblox dulu. dulu worker
    -- ambil code jadi linkCode langsung -> SALAH -> join gagal, nyangkut server
    -- lama. FIX: buka URL share-nya LANGSUNG, biar Roblox sendiri yg resolve+join.
    if lc:find("share%?code=") or lc:find("/share%?") then
        -- pastikan pakai https lengkap, biar am start buka lewat Roblox app
        if lc:sub(1,4) ~= "http" then lc = "https://www.roblox.com/" .. lc:gsub("^/", "") end
        return lc   -- buka URL share apa adanya -> Roblox resolve sendiri
    elseif lc:find("privateServerLinkCode=") then
        -- format lama: linkCode asli beneran ada di sini
        local code = lc:match("privateServerLinkCode=([^&]+)")
        return code and ("roblox://placeId="..cfg.place_id.."&linkCode="..code) or lc
    elseif lc:sub(1,4)=="http" then return lc
    elseif lc~="" then return "roblox://placeId="..cfg.place_id.."&linkCode="..lc
    else return "roblox://placeId="..cfg.place_id end
end

-- v4.1: FREEFORM
-- Pencet ikon di RedFinger = LAUNCHER yang naro Roblox di freeform.
-- `am start` NGELEWATIN launcher -> kebuka fullscreen. Makanya mesti
-- diminta sendiri lewat --windowingMode.
--   5 = freeform (jendela ngambang, bisa digeser)  <- yang dicari
--   6 = multi-window (jalur Android 12+)
--   0 = jangan minta apa-apa (kayak v4.0)
local WIN_OK = nil   -- nil=belum dites, true=didukung, false=ditolak

local function open_one(cfg, pkg, link_client)
    local url = build_url(cfg, link_client)
    local wm = tonumber(cfg.win_mode) or 0

    local function coba(pakai_wm)
        local inner = "am start -a android.intent.action.VIEW -d '"..url.."' -p "..pkg
        if pakai_wm and wm > 0 then
            inner = inner .. " --windowingMode " .. wm
        end
        local cmd = 'su -c "'..inner..'"'
        if DEBUG_OPEN then print("\n"..C.Y.."[DEBUG] "..C.N..cmd) end
        return cmd, sh(cmd)
    end

    if wm == 0 then
        local cmd = coba(false)
        sh_silent(cmd)
        return
    end

    -- sekali doang: cek Android ini nerima --windowingMode apa nggak
    if WIN_OK == nil then
        local _, out = coba(true)
        if out:find("Unknown option") or out:find("Error: Unknown") then
            WIN_OK = false
            warn("Android ini gak dukung --windowingMode "..wm.." -> balik ke fullscreen")
            warn("Client bakal kebuka fullscreen, bukan freeform.")
        else
            WIN_OK = true
            ok("freeform (mode "..wm..") didukung")
        end
        return   -- percobaan barusan udah kehitung buka
    end

    local cmd = coba(WIN_OK)
    sh_silent(cmd)
end

-- ============================================================
-- v4.1: TUNGGU SAMPAI BENERAN JALAN
-- Dulu: buka -> tidur 4 detik -> lanjut. Gak pernah dicek.
-- Kalau client ke-3 gagal, worker tetep lanjut ke ke-4 kayak gak ada apa-apa,
-- terus lapor "8 client" padahal cuma 7 yang hidup.
--
-- Sekarang: buka -> tungguin muncul -> pastiin gak mati lagi -> baru lanjut.
--
-- CATATAN JUJUR: pgrep cuma tau PROSESNYA muncul, bukan "udah masuk game".
-- Roblox masih butuh ~20-40 detik lagi buat loading. Yang tau beneran udah
-- di kebun cuma star_bridge.lua (dari dalam game) -> keliatan di panel.
-- ============================================================
-- v4.31: prosesnya idup gak? (beda dari pkg_running yg nuntut UDAH DI LAYAR GAME)
local function pkg_hidup(pkg)
    return (sh("su -c 'pidof " .. pkg .. "'") or ""):match("%d") ~= nil
end

local function tunggu_jalan(pkg, batas, cek_batal)
    local mulai = os.time()
    local lastKabar = 0   -- v4.72: kabarin tiap 15 detik, biar gak keliatan diem
    -- v4.31: kalau prosesnya UDAH IDUP tapi belum sampai layar game, itu artinya
    -- LAGI LOADING -- bukan gagal. Dulu langsung di-'ulang', dan tiap ulang itu
    -- am start lagi -> loading keinterupsi terus -> gak pernah kelar (muter).
    -- Sekarang: dikasih perpanjangan waktu selama prosesnya masih idup.
    -- v4.59: dulu 3x -- kelamaan. Gabungan sama tunggu bridge bikin satu client
    -- bisa makan 6 menit. 2x udah cukup lega buat CPU 100%.
    local batasMax = batas * 2
    while (os.time() - mulai) < batasMax do
        local lewatBatas = (os.time() - mulai) >= batas
        if lewatBatas and not pkg_hidup(pkg) then
            break   -- lewat batas DAN prosesnya emang gak ada -> beneran gagal
        end
        if cek_batal and cek_batal() then return false, os.time()-mulai, "STANDBY" end
        -- v4.72: dulu bagian ini DIEM total sampai 2x batas -- keliatan kayak
        -- worker nyangkut padahal lagi nungguin Roblox nyala.
        local lewat = os.time() - mulai
        if lewat - lastKabar >= 15 then
            lastKabar = lewat
            io.write(("      %s — nungguin nyala... (%ds)\n"):format(
                pkg:gsub("com%%.roblox%%.",""), lewat))
        end
        if pkg_running(pkg) then
            -- muncul. verifikasi STABIL: cek 2x lagi (5s+5s). Roblox suka muncul
            -- sekejap terus mati pas RAM sesek -> jangan langsung dianggap sukses.
            os.execute("sleep 5")
            if not pkg_running(pkg) then
                return false, os.time() - mulai, "muncul lalu mati (RAM sesek?)"
            end
            os.execute("sleep 5")
            if pkg_running(pkg) then return true, os.time() - mulai end
            return false, os.time() - mulai, "muncul lalu mati (RAM sesek?)"
        end
        os.execute("sleep 2")
    end
    local lama = os.time() - mulai
    if pkg_hidup(pkg) then
        -- proses idup tapi gak nyampe layar game: nyangkut loading / key-system /
        -- kelempar ke Home. am start ulang gak bakal nolong -- laporin apa adanya.
        return false, lama, "prosesnya idup tapi gak nyampe layar game (loading lama / nyangkut)"
    end
    return false, lama, "gak muncul sama sekali (RAM penuh? paket bener?)"
end

-- v4.4: tutup PAKSA semua client Roblox (am force-stop). buat CLOSE & REJOIN dari panel.
-- v4.9: baca username Roblox tiap client dari prefs.xml. buat mapping client<->akun,
-- biar worker tau "clienu = fifinx_5". dipakai auto-rejoin: kalau akun X berhenti
-- lapor (keluar game), worker tau itu client mana -> rejoin client itu.
local function baca_username(pkg)
    local path = "/data/data/" .. pkg .. "/shared_prefs/prefs.xml"
    local o = sh("su -c 'cat " .. path .. "'")
    -- <string name="username">fifinx_5</string>
    local u = o:match('<string name="username">(.-)</string>')
    return u
end

-- v4.8: tulis LOADER ke autoexec Delta (/sdcard/Delta/Autoexecute/).
-- Delta auto-jalanin file di folder ini pas masuk game (SETELAH user verif key).
-- jadi: worker buka client -> user verif key manual -> Delta baca autoexec ->
-- script auto-jalan. user cuma verif key, script masuk sendiri.
-- 1 RF = 1 game, jadi 1 loader (sesuai game tim) buat semua client.
-- v5.29: url bisa DITIMPA panel (script per tim). Kalau urlPanel dikasih,
-- itu yang dipakai; kalau nggak, jatuh ke cfg.script_url lokal RF kayak dulu.
local function tulis_autoexec(cfg, urlPanel)
    local url_script = (urlPanel and urlPanel ~= "") and urlPanel or cfg.script_url
    if not url_script or url_script == "" then
        warn("script_url kosong, autoexec dilewat")
        return false
    end
    local AUTOEXEC_DIR = cfg.autoexec_dir or "/sdcard/Delta/Autoexecute"
    -- loader: narik script dari GitHub. update cukup di GitHub, file autoexec tetap.
    local loader = 'loadstring(game:HttpGet("' .. url_script .. '"))()'
    local path = AUTOEXEC_DIR .. "/zenx_loader.lua"
    -- Tulis lewat file lokal dulu (Termux home, gampang), baru cp ke folder Delta
    -- pakai su. Ini ngehindarin neraka nested-quote (su -c ' ... " ... ').
    local tmp = os.getenv("HOME") .. "/.zenx_loader.tmp"
    local f = io.open(tmp, "w")
    if not f then warn("gagal bikin file tmp loader"); return false end
    f:write(loader); f:close()
    -- ============================================================
    -- v5.41: BERSIHIN FILE LAIN di folder autoexec.
    --
    -- Delta jalanin SEMUA file di folder ini. Jadi sisa script lama (mis.
    -- text.txt yang pernah ditaruh manual, atau loader dari nama lama) bakal
    -- jalan BARENGAN sama yang baru -> dua script aktif di satu client, aksi
    -- dobel, atau yang bener ketimpa yang salah.
    --
    -- Digabung ke panggilan su yang SAMA -- tiap 'su' di RedFinger ~6 detik,
    -- jadi pembersihan ini praktis gratis.
    -- Yang dilewat cuma loader punya kita sendiri.
    -- Mau dimatiin? config -> autoexec_bersih=false
    -- ============================================================
    local bersih = ""
    if cfg.autoexec_bersih ~= false then
        bersih = "for f in " .. AUTOEXEC_DIR .. "/*; do " ..
                 '[ -f "$f" ] || continue; ' ..
                 'case "$f" in */zenx_loader.lua) ;; ' ..
                 '*) echo "HAPUS:$f"; rm -f "$f";; esac; ' ..
                 "done; "
    end

    -- v4.62: mkdir + cp + chmod + verifikasi digabung jadi SATU panggilan su.
    -- Dulu 4 panggilan terpisah -- tiap 'su -c' di RedFinger ~5-7 detik, jadi
    -- bagian ini sendirian makan ~30 detik pas worker nyala.
    local cek = sh("su -c 'mkdir -p " .. AUTOEXEC_DIR .. "; " .. bersih ..
                   "cp " .. tmp .. " " .. path ..
                   "; chmod 664 " .. path ..
                   "; cat " .. path .. "'")

    -- lapor apa aja yang dibuang, biar gak ada yang ilang diam-diam
    local dibuang = {}
    for nm in tostring(cek):gmatch("HAPUS:([^\n]+)") do
        dibuang[#dibuang+1] = nm:match("([^/]+)$") or nm
    end
    if #dibuang > 0 then
        warn("file lain di folder autoexec dibuang: " .. table.concat(dibuang, ", "))
        warn("  (Delta jalanin SEMUA file di situ -- kalau dibiarin, script dobel)")
    end

    if cek:find("loadstring", 1, true) then
        ok("autoexec loader ditulis: " .. ((urlPanel and urlPanel ~= "") and "DARI PANEL" or cfg.game_label)
           .. " -> " .. url_script)
        return true
    else
        warn("gagal nulis autoexec (cek izin folder Delta)")
        return false
    end
end

-- v4.12: bawa SEMUA client freeform ke depan sekaligus. pas pencet Termux/app lain,
-- jendela Roblox ke-belakang. FRONT = am start tiap client yg udah jalan -> window
-- muncul ke depan LAGI (Roblox udah jalan, am start cuma munculin window, gak restart).
-- karena Delta freeform, semua jendela bisa nampil barengan di samping-samping.
local function front_all(cfg, mapLink)
    local list = split(cfg.pkgs)
    local n = 0
    for _, pkg in ipairs(list) do
        if pkg_running(pkg) then
            -- am start dgn flag REORDER_TO_FRONT (0x20000000): bawa window yg UDAH ADA
            -- ke depan, JANGAN restart game. tanpa flag ini am start bisa reload.
            local url = build_url(cfg, mapLink and mapLink[pkg] or nil)
            sh_silent("su -c \"am start -f 0x20000000 -a android.intent.action.VIEW -d '" .. url .. "' -p " .. pkg .. "\"")
            n = n + 1
            os.execute("sleep 1")   -- jeda tipis biar window ketata rapi
        end
    end
    return n
end


-- v4.71: ambil taskId SEMUA client dari SATU dump. Dulu tiap client nyoba 4
-- sumber berbeda -- 4 client = 16 panggilan 'su' = ~96 detik cuma buat nyusun
-- grid. Sekarang: satu dump, dipilah lokal; sumber cadangan cuma dipakai kalau
-- masih ada yang belum ketemu.
local POLA_TASK = {
    "taskId=(%d+)", "Task{%w+%s+#(%d+)", "#(%d+)%s+type=",
    "taskId%s*=%s*(%d+)", "Task%s+id=(%d+)", "id=(%d+)",
}
local function task_id_semua(pkgs)
    local hasil = {}
    local function pungut(o)
        for baris in (o or ""):gmatch("[^\r\n]+") do
            for _, p in ipairs(pkgs) do
                if not hasil[p] and baris:find(p, 1, true) then
                    for _, pat in ipairs(POLA_TASK) do
                        local id = baris:match(pat)
                        if id and tonumber(id) and tonumber(id) > 0 then
                            hasil[p] = tonumber(id); break
                        end
                    end
                end
            end
        end
    end
    -- satu dump dulu; kalau semua udah ketemu, gak usah lanjut
    pungut(sh("su -c 'dumpsys activity activities'"))
    local kurang = false
    for _, p in ipairs(pkgs) do if not hasil[p] then kurang = true break end end
    if kurang then pungut(sh("su -c 'dumpsys activity recents'")) end
    kurang = false
    for _, p in ipairs(pkgs) do if not hasil[p] then kurang = true break end end
    if kurang then pungut(sh("su -c 'am stack list 2>/dev/null'")) end
    return hasil
end

-- ============================================================
-- v4.82: TATA JENDELA LEWAT PREFS APP CLONER
--
-- Kenapa bukan 'am ... resize': jendela ngambang itu DIGAMBAR APP CLONER,
-- bukan Android. Android nganggep semua klon fullscreen (mWindowingMode=
-- fullscreen, bounds=[0,0][layar penuh]) -- App Cloner nggambar kotaknya DI
-- DALAM jendela fullscreen itu. Jadi perintah apa pun ke Android sia-sia:
--   am task resizeTask    -> gak ada di ROM RedFinger
--   am stack resize       -> keterima TAPI gak ngefek
--   am task resize        -> Exception / gak ngefek
--   --windowingMode 5     -> jalan, tapi Android nambah batang judul -> KOTAK DOBEL
-- Yang jalan: tulis koordinat ke shared_prefs klon, terus buka aplikasinya.
--
-- ATURAN YANG GAK BISA DITAWAR:
--   * WAJIB nulis DUA set: current_ DAN original_. Cuma current_ -> balik
--     berantakan (App Cloner pakai original_ pas jendela pertama dibuka).
--   * DITULIS PAS CLIENT MATI, sebelum dibuka. App Cloner baca prefs pas app
--     MULAI, dan NIMPA BALIK pas app DITUTUP.
--   * Petak dihitung dari urutan cfg.pkgs (TETAP), bukan urutan buka -- worker
--     suka ngurutin ulang, kalau ikut itu jendelanya pindah-pindah tiap ronde.
-- ============================================================
local SELA = 15   -- jarak antar jendela = SELA x 2

-- templat dipilih tangan; rumus akar kuadrat boros (8 client jadi 3x3, nganggur 1)
local SUSUNAN = {
    [1]={1,1}, [2]={2,1}, [3]={3,1},  [4]={2,2},
    [5]={3,2}, [6]={3,2}, [7]={4,2},  [8]={4,2},
    [9]={3,3}, [10]={5,2},[11]={4,3}, [12]={4,3},
}

local KUNCI_JENDELA = {
    "app_cloner_current_window_left",   "app_cloner_current_window_top",
    "app_cloner_current_window_right",  "app_cloner_current_window_bottom",
    "app_cloner_original_window_left",  "app_cloner_original_window_top",
    "app_cloner_original_window_right", "app_cloner_original_window_bottom",
}

-- balikin: peta pkg -> {L,T,R,B}, sebab, kol, bar, W, H
-- v5.06: hitung petak buat JUMLAH CLIENT SEMBARANG (bukan cuma yang kepasang).
-- Gunanya: satu client dipakai buat nyoba semua ukuran. Mau tau petaknya kalau
-- nanti 10 client? Set jendela client ini ke ukuran itu, cari tombolnya,
-- simpen. Gak usah beneran buka 10 client.
local function petak_untuk(n, slot)
    local W, H = layar_ukuran()
    if W == 0 or H == 0 then return nil, "gagal baca ukuran layar" end
    if not n or n < 1 then return nil, "jumlah client gak masuk akal" end
    slot = slot or 1

    local kol, bar
    local s = SUSUNAN[n]
    if s then
        kol, bar = s[1], s[2]
    elseif W >= H then
        kol = math.ceil(math.sqrt(n)); bar = math.ceil(n / kol)
    else
        bar = math.ceil(math.sqrt(n)); kol = math.ceil(n / bar)
    end

    local lebar, tinggi = math.floor(W / kol), math.floor(H / bar)
    local c = (slot - 1) % kol
    local r = math.floor((slot - 1) / kol)
    return {
        L = c * lebar + SELA,
        T = r * tinggi + SELA,
        R = (c + 1) * lebar - SELA,
        B = (r + 1) * tinggi - SELA,
    }, kol, bar, W, H
end

-- v5.20 (BUKTI LAPANGAN): grid 3 BARIS gak bisa dipakai bypass key.
-- Di layar 1280x720, 3 baris bikin tinggi jendela cuma ~173px -- dialog key
-- Delta gak muat, tombolnya kepotong. Udah dicoba di 9 client: gagal.
-- Jadi batas aman = 8 client (masih 2 baris, tinggi ~293px). Ini batas LAYAR,
-- beda dari batas RAM -- dua-duanya harus dilewatin.
local function baris_grid(n, W, H)
    local s = SUSUNAN[n]
    if s then return s[2] end
    if W >= H then return math.ceil(n / math.ceil(math.sqrt(n))) end
    return math.ceil(math.sqrt(n))
end

local function grid_hitung(cfg)
    local W, H = layar_ukuran()   -- udah nuker W/H kalau layar landscape
    if W == 0 or H == 0 then return nil, "gagal baca ukuran layar (wm size)" end

    local pkgs = split(cfg.pkgs)
    local n = #pkgs
    if n == 0 then return nil, "gak ada client di config" end

    local kol, bar
    local s = SUSUNAN[n]
    if s then
        kol, bar = s[1], s[2]
    elseif W >= H then
        kol = math.ceil(math.sqrt(n)); bar = math.ceil(n / kol)
    else
        bar = math.ceil(math.sqrt(n)); kol = math.ceil(n / bar)
    end

    local lebar, tinggi = math.floor(W / kol), math.floor(H / bar)
    local peta = {}
    for i, pkg in ipairs(pkgs) do   -- URUTAN CONFIG, jangan urutan buka
        local c = (i - 1) % kol
        local r = math.floor((i - 1) / kol)
        peta[pkg] = {
            L = c * lebar + SELA,
            T = r * tinggi + SELA,
            R = (c + 1) * lebar - SELA,
            B = (r + 1) * tinggi - SELA,
        }
    end
    return peta, nil, kol, bar, W, H
end

local function prefs_path(pkg)
    return "/data/data/" .. pkg .. "/shared_prefs/" .. pkg .. "_preferences.xml"
end

-- tulis koordinat 1 client. balikin: berhasil, keterangan
-- keterangan "udah pas" = gak ada yang ditulis (hemat 1 panggilan su)
local function tata_satu(pkg, kotak)
    local path = prefs_path(pkg)
    -- stderr digabung DI DALAM su -- kalau dibuang, penolakan ROM ikut kebuang
    -- dan kodenya ngira sukses padahal gagal.
    local isi = sh("su -c 'cat " .. path .. " 2>&1'") or ""
    if not isi:find("<map", 1, true) then
        return false, "prefs belum ada (client belum pernah dibuka)"
    end

    local mau = {}
    for _, k in ipairs(KUNCI_JENDELA) do
        local v
        if     k:find("_left$")   then v = kotak.L
        elseif k:find("_top$")    then v = kotak.T
        elseif k:find("_right$")  then v = kotak.R
        else                           v = kotak.B end
        mau[k] = v
    end

    -- udah pas? lewatin nulisnya -- hemat 1 su per client tiap ronde
    local udahPas = true
    for k, v in pairs(mau) do
        local ada = tonumber(isi:match('<int name="' .. k .. '" value="(%-?%d+)"'))
        if ada ~= v then udahPas = false break end
    end
    if udahPas then return true, "udah pas" end

    local baru = isi
    for k, v in pairs(mau) do
        local ganti = string.format('<int name="%s" value="%d" />', k, v)
        if baru:find('<int name="' .. k .. '"', 1, true) then
            baru = baru:gsub('<int name="' .. k .. '"[^/]*/>', function() return ganti end, 1)
        else
            baru = baru:gsub("</map>", function() return "    " .. ganti .. "\n</map>" end, 1)
        end
    end

    -- JANGAN pakai sed di dalam su -- '</map>' kebaca shell sebagai pengalihan
    -- ("syntax error: unexpected '<'"). Jadi: ubah di Lua, tulis lewat berkas
    -- sementara, salin pakai 'cat tmp > target' (bukan cp) biar pemilik & izin
    -- berkas aslinya tetep.
    local tmp = (os.getenv("HOME") or ".") .. "/.zenx_prefs.tmp"
    local f = io.open(tmp, "w")
    if not f then return false, "gagal bikin berkas sementara" end
    f:write(baru); f:close()

    local out = sh("su -c 'cat " .. tmp .. " > " .. path .. " 2>&1'") or ""
    os.remove(tmp)
    if out:match("%S") then return false, "gagal nulis: " .. out:gsub("%s+", " "):sub(1, 60) end
    return true, "ditulis"
end

local function atur_grid_lama(cfg)
    local W, H, rot = layar_ukuran()
    if W == 0 or H == 0 then
        return 0, "gagal baca ukuran layar (wm size)"
    end

    -- kumpulin client yang lagi jalan
    local aktif = {}
    for _, pkg in ipairs(split(cfg.pkgs)) do
        if pkg_running(pkg) then aktif[#aktif+1] = pkg end
    end
    local n = #aktif
    if n == 0 then return 0, "gak ada client jalan" end

    -- v4.27: bentuk grid NGIKUT bentuk layar.
    --   landscape (lebar > tinggi) -> kolom lebih banyak (6 client = 3x2)
    --   portrait  (tinggi > lebar) -> baris lebih banyak (6 client = 2x3)
    -- kalau dipaksa sama, jendelanya jadi kurus/gepeng gak kepake.
    local kol, bar
    if W >= H then
        kol = math.ceil(math.sqrt(n)); bar = math.ceil(n / kol)
    else
        bar = math.ceil(math.sqrt(n)); kol = math.ceil(n / bar)
    end
    local lebar  = math.floor(W / kol)
    local tinggi = math.floor(H / bar)

    -- v4.71: taskId semua client sekali ambil, terus SEMUA resize dikirim dalam
    -- SATU panggilan su. Dulu: 4 sumber x tiap client buat cari id, plus 1 su
    -- per resize -- totalnya bisa 20 panggilan (~2 menit).
    local petaId = task_id_semua(aktif)
    local sukses, gagalPertama = 0, nil
    local perintah = {}
    for i, pkg in ipairs(aktif) do
        local id = petaId[pkg]
        if not id then
            gagalPertama = gagalPertama or ("taskId " .. pkg:gsub("com%.roblox%.","") .. " gak ketemu")
        else
            local c = (i - 1) % kol              -- kolom ke-berapa
            local r = math.floor((i - 1) / kol)  -- baris ke-berapa
            local L, T = c * lebar, r * tinggi
            perintah[#perintah+1] = string.format("am task resizeTask %d %d %d %d %d",
                id, L, T, L + lebar, T + tinggi)
            sukses = sukses + 1
        end
    end
    if #perintah > 0 then
        local out = sh("su -c '" .. table.concat(perintah, "; ") .. "' 2>&1") or ""
        if out:lower():find("unknown command") or out:lower():find("exception") then
            sukses, gagalPertama = 0, "ROM gak dukung 'am task resizeTask'"
        end
    end
    -- v4.27: sertain ukuran+orientasi biar gampang dicek kalau hasilnya meleset
    local info_layar = string.format("%dx%d %s", W, H, (W >= H) and "landscape" or "portrait")
    return sukses, (sukses == 0 and gagalPertama or nil), kol, bar, info_layar
end

local function baca_ram()
    local mi = sh("cat /proc/meminfo")
    local total = tonumber(mi:match("MemTotal:%s+(%d+)")) or 0
    local avail = tonumber(mi:match("MemAvailable:%s+(%d+)")) or 0
    local gb = function(kb) return math.floor(kb/1024/1024*10+0.5)/10 end
    return gb(total-avail), gb(avail), gb(total)
end

-- ============================================================
-- v4.38: BACA DIALOG ERROR ROBLOX (Disconnected / Error Code 277 dst)
-- Kalau Roblox kelempar dari server, dialognya nongol TAPI activity-nya tetep
-- MainGameActivity -- jadi pkg_running tetep bilang "jalan" & worker gak sadar.
-- Satu-satunya cara liat isinya: dump UI. uiautomator cuma bisa baca jendela
-- yang lagi DI DEPAN, makanya client-nya dibawa ke depan dulu.
-- MAHAL (bawa ke depan + dump), jadi cuma dipanggil pas bridge udah CURIGA diem.
-- ============================================================
-- v4.39: SEMUA kode error Roblox ketangkep (formatnya selalu "Error Code: NNN"),
-- tapi penanganannya BEDA-BEDA. Asal masuk ulang buat semua error itu bahaya:
-- kode 268 justru artinya "kebanyakan nyoba" -- diulang malah makin diblok.
local ERROR_SIFAT = {
    -- masuk ulang langsung: koneksi putus / kelempar biasa
    [260]="ulang", [261]="ulang", [262]="ulang", [269]="ulang", [270]="ulang",
    [272]="ulang", [273]="ulang", [277]="ulang", [279]="ulang", [280]="ulang",
    [291]="ulang", [292]="ulang",
    -- backoff dulu: server/akun lagi dibatesin, buru-buru = makin parah
    [264]="tunggu",   -- akun yang sama join di tempat lain
    [268]="tunggu",   -- kebanyakan percobaan (rate limit)
    [529]="tunggu",   -- layanan Roblox lagi ngadat
    [517]="tunggu",   -- server lagi dimatiin
    -- percuma diulang: butuh dibenerin manual
    [267]="manual",   -- di-kick script game
    [524]="manual",   -- gak diizinin masuk private server (link salah/expired)
    [522]="manual",   -- place dibatesin
    [523]="manual",
}
local ERROR_TANDA = {
    "Error Code", "Disconnected", "Reconnect",
    "lost connection", "kicked", "Please check your internet",
}
-- v4.40: Delta/loader BEKU. Bukan kode error, tapi sama macetnya: script gak
-- pernah jalan -> bridge diem selamanya -> dibangunin berkali-kali gak nolong.
-- AMAN dari salah tangkap: pengecekan ini CUMA jalan kalau bridge udah diem
-- bermenit-menit. Layar loading yang normal gak akan pernah kesini.
-- v4.42: penanda LAYAR HOME Roblox / popup verifikasi umur. Ini yang bikin
-- client "jalan" tapi gak pernah masuk game. Dikenali langsung dari layar,
-- jadi gak usah nunggu bridge diem 90 detik baru sadar.
-- v4.83: penanda LAYAR KEY SYSTEM Delta. Ini WAJIB dikenali sendiri, karena
-- dibunuh pun gak nyelesaiin apa-apa -- kuncinya tetep harus masuk. Dulu layar
-- key kebaca "Home"/"nyangkut" -> client di-kill terus, dan kalau lagi ngerjain
-- `zenx key` bisa kepotong di tengah jalan.
-- CATATAN: daftar ini masih SEMENTARA (belum dicocokin ke dump layar asli).
-- Tambahin sendiri lewat config: key_tanda="Kata A,Kata B"
local KEY_TANDA = {
    "platorelay", "Key System", "KeySystem", "Get Key", "Getting Key",
    "Copy Key", "Enter Key", "Paste Key", "Checkpoint", "key expired",
    "Delta Key", "Verify Key",
}
local HOME_TANDA = {
    "Access to popular games", "check your age",
    "Discover", "Charts", "Marketplace",
    -- v4.83: "Unlock" DICABUT dari sini. Itu tombol yang lazim di halaman key,
    -- jadi layar key kebaca Home -> client dibunuh percuma.
}
local NYANGKUT_TANDA = {
    "Loading", "Injecting", "Please wait", "Checking", "Verifying",
}
-- balikin: pesan, sifat ("ulang"/"tunggu"/"manual")
-- v4.84: bagian PENILAIAN dipisah dari bagian AMBIL DUMP.
-- Alasannya: perintah `zenx intip` harus nunjukin penilaian yang PERSIS SAMA
-- kayak yang dipakai worker. Kalau logikanya disalin dua kali, cepat atau
-- lambat dua-duanya beda -- dan diagnosa jadi nyesatin.
local function klasifikasi_layar(isi)
    -- sidik layar: buat banding "berubah apa nggak" antar-intipan
    local sidik = #isi
    for t in isi:gmatch('text="([^"]+)"') do sidik = sidik + #t end

    -- LAYAR KEY dicek PALING DULU. Halaman key sering nampilin kata yang sama
    -- kayak layar lain ("Verifying", "Unlock", "Checking") -- kalau dicek
    -- belakangan, keburu keklasifikasi salah terus dibunuh percuma.
    for _, tanda in ipairs(KEY_TANDA) do
        if isi:lower():find(tanda:lower(), 1, true) then
            return ("layar KEY Delta ('" .. tanda .. "')"), "manual", sidik
        end
    end

    local kode = tonumber(isi:match("[Ee]rror [Cc]ode:?%s*(%d+)"))
    if kode then
        return ("Error Code " .. kode), (ERROR_SIFAT[kode] or "ulang"), sidik
    end
    for _, tanda in ipairs(ERROR_TANDA) do
        if isi:lower():find(tanda:lower(), 1, true) then
            return tanda, "ulang", sidik
        end
    end
    for _, tanda in ipairs(NYANGKUT_TANDA) do
        if isi:find(tanda, 1, true) then
            return ("nyangkut di '" .. tanda .. "'"), "ulang", sidik
        end
    end
    for _, tanda in ipairs(HOME_TANDA) do
        if isi:find(tanda, 1, true) then
            local kenapa = (tanda == "Access to popular games" or tanda == "check your age")
                and "popup verifikasi umur" or "layar Home Roblox"
            return ("nyangkut di " .. kenapa), "home", sidik
        end
    end

    -- LAYAR KOSONG (putih polos / cuma logo): gak ada teks yang bisa dibaca ->
    -- bukan layar game (game selalu punya tombol/label).
    local nTeks = 0
    for t in isi:gmatch('text="([^"]+)"') do
        if t:match("%S") then nTeks = nTeks + 1 end
    end
    if nTeks <= 2 then
        -- v4.85 (BUKTI LAPANGAN): di RedFinger, layar Roblox NGGAK PERNAH nyisain
        -- teks yang kebaca uiautomator -- game, layar key, Home, loading, semuanya
        -- kebaca 0 teks. Dua potret dibanding (client bermasalah vs client SEHAT)
        -- hasilnya nyaris identik: 3497 vs 3487 byte, class & resource-id sama
        -- persis, dua-duanya punya web_overlay_layout. Roblox nggambar semuanya ke
        -- permukaan GL, uiautomator cuma liat cangkangnya.
        --
        -- Dulu keadaan ini divonis "loading beku" -> KILL. Artinya TIAP kali worker
        -- ngintip, vonisnya selalu sama, termasuk buat client yang lagi sehat --
        -- ngintipnya gak nambah informasi apa pun, cuma nambah keyakinan palsu.
        -- Itu sumber utama client kebunuh percuma.
        --
        -- Sekarang: GAK TAU ya bilang GAK TAU. Keputusannya diserahin ke jalur yang
        -- emang kebukti jalan -- bridge (script lapor apa nggak), didorong dulu 2x,
        -- baru dibunuh, dan itu pun kena jatah 3x/30 menit.
        return nil, nil, sidik
    end
    return nil, nil, sidik
end

-- ambil dump layar 1 client. balikin isi XML, atau nil + sebab.
local function ambil_dump(cfg, pkg, mapLink, lewatiFokus)
    local dump = "/sdcard/zenx_ui.xml"
    -- v4.89: dulu munculinnya pakai 'am start -d <link>'. Kalau client lagi GAK
    -- di dalam game (mis. layar key), link itu dieksekusi beneran -> client join
    -- sendiri. Sekarang cuma mindahin task, gak nyentuh isi aplikasinya.
    bawa_depan(pkg)
    os.execute("sleep 3")
    if not lewatiFokus then
        local fokus = sh("su -c 'dumpsys window | grep mCurrentFocus'") or ""
        if not fokus:find(pkg, 1, true) then return nil, "yang di depan bukan client ini" end
    end
    sh_silent("su -c 'rm -f " .. dump .. "'")
    sh_silent("su -c 'uiautomator dump " .. dump .. "'")
    local isi = sh("su -c 'cat " .. dump .. " 2>/dev/null'") or ""
    sh_silent("su -c 'rm -f " .. dump .. "'")
    if not isi:match("%S") then return nil, "dump gagal / kosong" end
    return isi
end

local function cek_error_ui(cfg, pkg, mapLink)
    -- v4.84: tinggal ngerangkai dua bagian di atas. Dulu ambil-dump dan
    -- penilaian nyampur di sini, jadi `zenx intip` gak bisa makai penilaian
    -- yang sama tanpa nyalin kodenya.
    local isi = ambil_dump(cfg, pkg, mapLink)
    if not isi then return nil end
    return klasifikasi_layar(isi)
end

-- sambungin ke deklarasi maju di atas (dipakai tunggu_bridge)
cek_layar = cek_error_ui

-- v4.52: JAGA DEPAN. Delta Lite kadang nguncup sendiri jadi gelembung; kalau
-- dibiarin, Roblox di dalemnya disconnect ~15 detik kemudian. 'am start' dengan
-- REORDER_TO_FRONT cuma MUNCULIN window yang udah ada (gak restart game), jadi
-- aman dipanggil berkala -- kalau window-nya udah nongol, ini gak ngefek apa-apa.
-- v4.63: satu panggilan su buat semua client (dulu satu-satu, tiap 10 detik).
-- 'cekJalan' dioper dari cache biar gak dumpsys ulang.
-- v4.89: JANGAN pakai link join di sini. Fungsi ini jalan tiap 15 detik; kalau
-- ada client yang lagi di layar key (belum masuk game), link-nya dieksekusi
-- beneran -> client join sendiri, berulang tiap 15 detik. Sekarang cuma
-- mindahin task ke depan: 1 panggilan su buat baca taskId semua client,
-- 1 lagi buat mindahin semuanya sekaligus.
local function jaga_depan(cfg, mapLink, cekJalan)
    local mau = {}
    for _, pkg in ipairs(split(cfg.pkgs)) do
        local jalan = cekJalan and cekJalan[pkg]
        if jalan == nil then jalan = pkg_running(pkg) end
        if jalan then mau[#mau+1] = pkg end
    end
    if #mau == 0 then return 0 end

    -- taskId semua client sekali baca ('am stack list' -- satu-satunya yang
    -- ngasih taskId di RedFinger)
    local o = sh("su -c 'am stack list 2>&1'") or ""
    local bagian, n = {}, 0
    for _, pkg in ipairs(mau) do
        local id, cari = nil, 1
        while true do
            local _, b = o:find("taskId=", cari, true)
            if not b then break end
            local nomor = o:match("^(%d+)", b + 1)
            if nomor and o:sub(b, b + 200):find(pkg, 1, true) then id = nomor break end
            cari = b + 1
        end
        if id then
            bagian[#bagian+1] = "am task move-task " .. id .. " true"
            n = n + 1
        end
    end
    if n > 0 then
        sh_silent("su -c '" .. table.concat(bagian, "; ") .. "'")
    end
    return n
end

-- v4.61: 'only' sekarang boleh: nil (semua), string (1 paket), atau TABEL
-- (beberapa paket sekaligus). Nutup itu murah -- nutup 3 client barengan
-- makan waktu sama kayak nutup 1. Dulu dipanggil satu-satu -> tiap panggilan
-- nunggu verifikasi mati sendiri-sendiri -> lambat banget kalau banyak.
local function close_all(cfg, only, mapLink, tanpaMunculin)
    local list = split(cfg.pkgs)
    local mau = nil
    if type(only) == "table" then
        mau = {}
        for _, p in ipairs(only) do mau[p] = true end
    end
    local target = {}
    for _, pkg in ipairs(list) do
        if (not only) or (mau and mau[pkg]) or (type(only) == "string" and pkg == only) then
            target[#target+1] = pkg
        end
    end
    if #target == 0 then return 0 end
    setAksi(#target == #list and "nutup semua client"
            or ("nutup " .. #target .. " client"))
    -- v4.19: FASE 1 -> force-stop SEMUA sekaligus (gak nunggu satu-satu dulu).
    for _, pkg in ipairs(target) do
        sh_silent("am force-stop " .. pkg)
        sh_silent("su -c 'am force-stop " .. pkg .. "'")
        info("tutup paksa: " .. pkg)
    end
    -- v4.19: FASE 2 -> tungguin SEMUA beneran mati PARALEL (bukan per-client 8s).
    -- penting buat pindah server: am start pas app masih idup -> Roblox abaikan
    -- (udah di server lama, gak pindah). tunggu sampai proses beneran mati.
    local belum = {}
    for _, pkg in ipairs(target) do belum[pkg] = true end
    for _ = 1, 8 do   -- max ~8 detik TOTAL (bukan per-client)
        os.execute("sleep 1")
        local adaHidup = false
        for pkg in pairs(belum) do
            local o = sh("su -c 'pidof " .. pkg .. "'")
            if not o:match("%d") then
                belum[pkg] = nil
            else
                adaHidup = true
                sh_silent("su -c 'am force-stop " .. pkg .. "'")   -- gedor lagi
            end
        end
        if not adaHidup then break end
    end
    local gagalTutup = 0
    for pkg in pairs(belum) do
        warn(pkg .. " MASIH IDUP setelah force-stop")
        gagalTutup = gagalTutup + 1
    end
    -- v4.56: kalau semua beneran mati, bilang -- biar gak dikira gagal diem-diem
    if gagalTutup == 0 and #target > 0 then
        info(("beneran ketutup: %d client"):format(#target))
    end
    os.execute("sleep 1")   -- napas ekstra biar sistem bersih

    -- v4.65: nutup SEBAGIAN bikin Android nyusun ulang tumpukan jendela --
    -- client yang GAK ditutup ikut kepental ke belakang (nyisa gelembung doang).
    -- Jadi begitu selesai nutup, langsung munculin balik yang selamat.
    -- v4.72: 'tanpaMunculin' dipakai kalau abis ini client-nya mau DIBUKA lagi.
    -- Munculin jendela lain di situ percuma -- beberapa detik kemudian ketimpa
    -- lagi sama client yang baru kebuka.
    if only ~= nil and #target < #list and not tanpaMunculin then
        local sisa = {}
        for _, pkg in ipairs(list) do
            local ikutDitutup = false
            for _, t in ipairs(target) do
                if t == pkg then ikutDitutup = true break end
            end
            if not ikutDitutup then sisa[#sisa+1] = pkg end
        end
        if #sisa > 0 then
            local hidup = pkg_running_semua(sisa)
            local bagian = {}
            for _, pkg in ipairs(sisa) do
                if hidup[pkg] then
                    local url = build_url(cfg, mapLink and mapLink[pkg] or nil)
                    bagian[#bagian+1] = "am start -f 0x20000000 -a android.intent.action.VIEW -d '"
                                        .. url .. "' -p " .. pkg
                end
            end
            if #bagian > 0 then
                sh_silent('su -c "' .. table.concat(bagian, "; ") .. '"')
                info(("%d client lain dimunculin balik"):format(#bagian))
            end
        end
    end
    return #target
end

-- cek_batal: dipanggil di sela-sela client. Buka 10 client bisa makan
-- 5-10 menit; tanpa ini, STANDBY dari panel gak kebaca sampe semuanya kelar.
local TERAKHIR_BUKA = {}   -- v4.68: pkg -> kapan terakhir dibuka worker
local function open_all(cfg, only, cek_batal, lapor_fn, mapLink, mapAkun, fast)
    local list = split(cfg.pkgs)
    local hasil = { ok = 0, gagal = 0, lewat = 0, nama_gagal = {} }
    local urut = 0
    -- v4.17: /stat sekali di awal, buat cek "beneran di game" pas skip client.
    -- v4.19: fast=true (buat REJOIN ganti server) -> skip bridge-confirm biar CEPET,
    -- gak nunggu tiap client lapor 90s. cukup mastiin proses muncul.
    local stat0 = (not fast) and api_get(cfg, "/stat") or ""
    -- v4.82: petak dihitung SEKALI di awal, dari urutan cfg.pkgs (tetap) --
    -- bukan urutan buka, yang suka diacak (client stok habis didahuluin).
    local petaGrid = nil
    if cfg.auto_grid == true then
        local p, sebabGrid = grid_hitung(cfg)
        if p then petaGrid = p
        else warn("tata jendela dilewat: " .. tostring(sebabGrid)) end
    end
    local stat0Ts = os.time()   -- v4.67: kapan potret /stat itu diambil
    local potretJalan = pkg_running_semua(list)   -- v4.71: sekali dumpsys buat semua
    local potretTs = os.time()
    local tunda = {}   -- v4.59: client yang nunggu konfirmasi bridge (dicek di akhir)
    set_orientasi(cfg)   -- v4.18: pastiin orientasi pas buka (jaga-jaga ke-reset)

    -- v4.64: DAHULUIN YANG STOKNYA HABIS. Client yang pet-nya tinggal dikit itu
    -- yang paling butuh masuk gudang leveling -- makin cepet dia masuk, makin
    -- cepet diisi. Yang stoknya masih tebal boleh belakangan; dia gak lagi
    -- nunggu apa-apa. Urutan dibaca dari /stat (petrule per akun).
    if not only and stat0 ~= "" then
        local stok = {}
        for pkg in pairs(mapAkun or {}) do
            local ak = mapAkun[pkg]
            local blok = ak and stat0:match('{[^{}]-"nama"%s*:%s*"' .. ak .. '"[^{}]-}')
            stok[pkg] = blok and tonumber(blok:match('"petrule"%s*:%s*(%d+)')) or nil
        end
        table.sort(list, function(a, b)
            local sa = stok[a] or math.huge      -- gak ketauan -> taro belakangan
            local sb = stok[b] or math.huge
            if sa ~= sb then return sa < sb end   -- paling kosong DULUAN
            return a < b                          -- biar urutannya tetap
        end)
    end

    for _, pkg in ipairs(list) do
        if (not only) or (pkg == only) then
            urut = urut + 1

            if cek_batal and cek_batal() then
                warn("perintah baru nyerobot -> berhenti buka (sisa dilewat)")
                break
            end

            local akun = (mapAkun and mapAkun[pkg]) or baca_username(pkg)

            -- v4.17: skip cuma kalau BENERAN di game = proses ADA + akun lapor fresh.
            -- dulu: skip kalau pkg_running aja -> client nyangkut di Home ke-skip
            -- selamanya (Home JUGA ActivityNativeMain). sekarang bridge yg mutusin.
            -- v4.67: SEGERIN data sebelum mutusin. Dulu potret /stat diambil
            -- SEKALI di awal open_all, padahal buka 4 client bisa makan menit-
            -- menitan -- pas giliran client ke-3/4, potretnya udah basi, jadi
            -- client yang BARU MULAI lapor tetep keliatan mati -> ditutup &
            -- dibuka ulang percuma.
            if (not fast) and (os.time() - stat0Ts) >= 30 then
                stat0 = api_get(cfg, "/stat")
                stat0Ts = os.time()
            end
            if (os.time() - potretTs) >= 30 then
                potretJalan = pkg_running_semua(list)
                potretTs = os.time()
            end
            -- v4.68: REM. Client yang BARU AJA dibuka-tutup jangan disentuh lagi
            -- dalam waktu dekat -- kasih dia kesempatan lapor dulu. Tanpa ini,
            -- client sehat yang laporannya telat dikit bisa kena buka-tutup
            -- berulang tiap siklus.
            local baruDisentuh = TERAKHIR_BUKA[pkg] and
                                 (os.time() - TERAKHIR_BUKA[pkg]) < (cfg.konfirmasi_sec or 90)
            -- v4.71: status dibaca dari potret gabungan (satu dumpsys buat semua),
            -- bukan dumpsys per client. Dulu 4 client = 4 panggilan su tiap
            -- open_all -- ~24 detik cuma buat mutusin "perlu disentuh nggak".
            local lagiJalan = potretJalan and potretJalan[pkg]
            if lagiJalan == nil then lagiJalan = pkg_running(pkg) end
            if lagiJalan and (not akun or bridge_fresh(stat0, akun) or baruDisentuh) then
                hasil.lewat = hasil.lewat + 1
                -- v4.6: JANGAN print tiap client yg udah jalan (bikin spam log).
            else
                local sukses, lama, sebab = false, 0, nil
                local maxc = cfg.max_coba or 5
                for coba = 1, maxc do
                    local link_c = mapLink and mapLink[pkg] or nil
                    setAksi(string.format("buka client %d/%d: %s%s", urut, #list,
                        (mapAkun and mapAkun[pkg]) or pkg:gsub("com%.roblox%.",""),
                        coba > 1 and (" (ulang "..coba.."/"..maxc..")") or ""))
                    io.write(string.format("[%d/%d] %s — buka%s...\n",
                        urut, #list, pkg, coba > 1 and (" (ulang ke-"..coba.."/"..maxc..")") or ""))
                    -- v4.17: catat ts SEBELUM buka -> nanti tunggu lapor BARU (ts naik)
                    local ts0 = (akun and not fast) and bridge_ts(api_get(cfg, "/stat"), akun) or nil
                    -- v4.58: kalau prosesnya UDAH JALAN, TUTUP DULU. 'am start' ke
                    -- Roblox yang lagi jalan itu NO-OP -- dia bakal nangkring di
                    -- server LAMA dan gak pernah pindah walau linknya udah ganti.
                    -- Sampai sini artinya client-nya emang gak lolos saringan
                    -- (bukan yang "udah jalan & lapor sehat"), jadi aman ditutup.
                    if pkg_hidup(pkg) then
                        info("   " .. pkg:gsub("com%.roblox%.","") .. " masih jalan -> ditutup dulu biar bisa pindah")
                        close_all(cfg, pkg, mapLink, true)   -- v4.72: gak usah munculin yang lain
                        os.execute("sleep 2")
                    end
                    -- v4.82: TULIS POSISI JENDELA DI SINI -- pas client MATI, sebelum
                    -- dibuka. App Cloner baca prefs pas app mulai; kalau ditulis
                    -- setelah kebuka, gak ngefek DAN ketimpa balik pas app ditutup.
                    if petaGrid and petaGrid[pkg] then
                        local tok, tket = tata_satu(pkg, petaGrid[pkg])
                        if tok then
                            if tket ~= "udah pas" then
                                info("   posisi jendela " .. pkg:gsub("com%.roblox%.","") .. ": " .. tket)
                            end
                        else
                            warn("posisi jendela " .. pkg:gsub("com%.roblox%.","") .. " gagal: " .. tostring(tket))
                        end
                    end
                    open_one(cfg, pkg, link_c)
                    TERAKHIR_BUKA[pkg] = os.time()   -- v4.68: buat rem di atas
                    -- v4.73: munculin SEMUA jendela SETELAH buka, bukan sebelum.
                    -- 'am force-stop' bikin jendela lain nguncup jadi gelembung;
                    -- buka satu client cuma munculin JENDELA ITU -- yang lain tetep
                    -- nguncup. Jadi urutan yang bener: tutup -> buka -> munculin semua.
                    jaga_depan(cfg, mapLink)
                    sukses, lama, sebab = tunggu_jalan(pkg, cfg.tunggu_sec or 45, cek_batal)
                    -- v4.59: JANGAN blokir antrean buat nungguin bridge tiap client.
                    -- Dulu tiap client bisa makan 6+ menit (nunggu proses 3x batas +
                    -- nunggu bridge 2x batas) -> 4 client = 25 menit. Sekarang:
                    -- proses nongol = cukup buat lanjut, konfirmasi bridge-nya
                    -- dilakuin SEKALIGUS di akhir buat semua client.
                    if sukses and akun and not fast then
                        tunda[#tunda+1] = { pkg = pkg, akun = akun, ts0 = ts0 }
                        break
                    elseif sukses then
                        break
                    end
                    -- v4.36b: bedain DUA jenis kegagalan, penanganannya beda:
                    --   A. bridge bilang GAK di game (nyangkut Home/age-check)
                    --      -> BUNUH client-nya, buka ulang. WAJIB dibunuh dulu:
                    --         'am start' ke app yang udah jalan itu no-op, jadi
                    --         tanpa dibunuh dia bakal nyangkut di Home selamanya.
                    --   B. gak ketauan (gak ada akun kepetakan / fast mode)
                    --      -> lanjut aja, biar client lain kebagian.
                    local nyangkut = (sebab or ""):find("nyangkut", 1, true) ~= nil
                    if nyangkut then
                        warn(string.format("[%d/%d] %s — nyangkut di Home; DIBUNUH terus dibuka ulang",
                            urut, #list, pkg))
                        close_all(cfg, pkg, mapLink)
                        os.execute("sleep 2")
                    elseif pkg_hidup(pkg) then
                        warn(string.format("[%d/%d] %s — prosesnya idup tapi gak kedeteksi di layar game; LANJUT ke client berikutnya",
                            urut, #list, pkg))
                        sukses = true   -- dihitung di blok bawah (jangan nambah di sini: dobel)
                        break
                    end
                    warn(string.format("[%d/%d] %s — %s (%ds), ulang...", urut, #list, pkg, sebab, lama))
                    if lapor_fn then pcall(lapor_fn) end   -- v4.33: segerin tabel tiap percobaan
                    if cek_batal and cek_batal() then break end   -- v4.16: STANDBY di tengah retry
                    if coba < maxc then
                        -- jeda naik: 5, 10, 15... biar RF sempet lega sebelum coba lagi
                        os.execute("sleep " .. (coba * 5))
                    end
                end
                if cek_batal and cek_batal() then
                    warn("STANDBY masuk -> berhenti (di tengah buka)")
                    break
                end

                if sukses then
                    hasil.ok = hasil.ok + 1
                    ok(string.format("[%d/%d] %s — jalan (%ds)", urut, #list, pkg, lama))
                else
                    hasil.gagal = hasil.gagal + 1
                    hasil.nama_gagal[#hasil.nama_gagal + 1] = pkg
                    err(string.format("[%d/%d] %s — GAGAL: %s", urut, #list, pkg, sebab or "?"))
                end

                -- lapor ke panel di sela-sela, biar gak "ilang" bermenit-menit
                if lapor_fn then pcall(lapor_fn) end

                -- napas sebelum client berikutnya (RAM sempet settle)
                if cek_batal and cek_batal() then break end   -- v4.16: STANDBY sebelum jeda
                if cfg.stagger_sec > 0 then os.execute("sleep "..cfg.stagger_sec) end
            end
        end
    end

    -- v4.59: KONFIRMASI BERSAMA. Semua client udah kebuka; sekarang tungguin
    -- mereka lapor -- SEKALIGUS, bukan satu-satu. Satu jendela waktu dipakai
    -- bareng, jadi total waktunya nyaris sama kayak nungguin SATU client.
    if #tunda > 0 and not (cek_batal and cek_batal()) then
        local batas = cfg.konfirmasi_sec or 90
        setAksi(("nunggu %d client masuk game (bareng, %ds)"):format(#tunda, batas))
        io.write(("      nunggu %d client masuk game (bareng, maks %ds)...\n"):format(#tunda, batas))
        local mulai = os.time()
        local belum = {}
        for _, t in ipairs(tunda) do belum[t.akun] = t end
        while (os.time() - mulai) < batas do
            if cek_batal and cek_batal() then break end
            local st = api_get(cfg, "/stat")
            local sisa = 0
            for akun, t in pairs(belum) do
                local ts = bridge_ts(st, akun)
                -- v4.60: dianggap masuk kalau lapor BARU (ts naik) ATAU laporannya
                -- masih segar. Yang kedua penting: script cuma lapor tiap 120 detik
                -- kalau gak ada perubahan -- ngotot nunggu "lapor baru" bikin client
                -- yang jelas-jelas aktif tetep ditungguin lama.
                if ts and ((not t.ts0 or ts > t.ts0) or bridge_fresh(st, akun)) then
                    belum[akun] = nil            -- beneran masuk game
                else
                    sisa = sisa + 1
                end
            end
            if sisa == 0 then break end
            os.execute("sleep " .. KONFIRMASI_POLL)
        end
        local nBelum = 0
        for akun, t in pairs(belum) do
            nBelum = nBelum + 1
            warn(("%s belum lapor -- mungkin nyangkut, auto-rejoin yang nangani"):format(akun))
        end
        if nBelum == 0 then
            ok(("semua %d client kekonfirmasi masuk game"):format(#tunda))
        end
    end

    -- v4.82: blok AUTO GRID lama (am ... resize setelah client kebuka) DICABUT.
    -- Cara itu gak pernah ngefek di ROM RedFinger -- jendelanya digambar App
    -- Cloner, bukan Android, jadi Android gak pegang posisinya. Penggantinya
    -- udah jalan di atas: koordinat ditulis ke prefs TIAP SEBELUM client dibuka.
    if petaGrid and hasil.ok > 0 then
        SUDAH_GRID = true
        catatKirim(os.date("%H:%M:%S") .. " GRID: posisi jendela ditulis buat "
                   .. hasil.ok .. " client yang baru dibuka")
    end

    return hasil
end

-- ============================================================
-- notifikasi
-- ============================================================
local NOTIF_ID="zenx_worker"
local function notify(title,content)
    local function e(s) return (s or ""):gsub('"','\\"') end
    sh_silent(string.format('termux-notification --id %s --title "%s" --content "%s" --ongoing --priority low --alert-once',
        NOTIF_ID, e(title), e(content)))
end
local function notify_clear() sh_silent("termux-notification-remove "..NOTIF_ID) end

-- ============================================================
-- lapor status -> POST /tim
-- ============================================================
local function baca_cpu()
    local l1 = tonumber(sh("cat /proc/loadavg"):match("^([%d%.]+)")) or 0
    local ncpu = tonumber(sh("nproc")) or 4
    local pct = math.floor(l1/ncpu*100+0.5)
    return pct > 100 and 100 or pct
end

-- v4.66: 'cache' = status client yang udah dibaca barusan. Dulu lapor()
-- manggil pkg_running SENDIRI per client -- 4 client = 4 panggilan su (~24
-- detik) TIAP LAPOR. Itu yang bikin panel telat banget update-nya, sekaligus
-- bikin satu putaran loop jadi panjang.
local function lapor(cfg, isi_perintah, cache)
    local used, free, total = baca_ram()
    local list = split(cfg.pkgs)
    local parts, jalan = {}, 0
    local semua = cache
    if not semua then semua = pkg_running_semua(list) end   -- cadangan: sekali dump
    for _, pkg in ipairs(list) do
        local run = semua[pkg] and true or false
        if run then jalan = jalan + 1 end
        parts[#parts+1] = string.format('{"pkg":%s,"run":%s}', jstr(pkg), tostring(run))
    end

    -- v4.24: ikut kirim "lagi ngapain" + log terakhir
    local logParts = {}
    for _, l in ipairs(LOG_KIRIM) do logParts[#logParts+1] = jstr(l) end

    local body = string.format(
        '{"tim":%s,"cpu":%d,"ram_used":%.1f,"ram_free":%.1f,"ram_total":%.1f,'..
        '"jalan":%d,"total":%d,"sticky":%s,"sig":%s,"clients":[%s],'..
        '"aksi":%s,"log":[%s],"ver":%s,"dev":%s}',
        jstr(cfg.tim), baca_cpu(), used, free, total,
        jalan, #list, tostring((isi_perintah or ""):upper():find("FORCE") ~= nil),
        jstr(isi_perintah), table.concat(parts, ","),
        jstr(AKSI_SKRG), table.concat(logParts, ","), jstr(VERSION), jstr(dev_id())
    )

    -- v5.30: HASIL LAPORAN DICATAT. Dulu `api_post(...)` nilai baliknya
    -- dibuang -- kalau POST /tim ditolak (kunci salah, tabel belum ada, jalur
    -- gak dikenal), worker tetep keliatan normal sementara panel KOSONG.
    -- Gagalnya diem, dan itu bikin susah dilacak.
    local resp = api_post(cfg, "/tim", body) or ""
    if resp == "" then
        LAPOR_OK, LAPOR_SEBAB = false, "gak nyambung"
    else
        local salah = ambil_str(resp, "error")
        if salah then
            LAPOR_OK, LAPOR_SEBAB = false, salah
            -- cetak sekali aja per sebab, biar log gak kebanjiran
            if LAPOR_WARN ~= salah then
                LAPOR_WARN = salah
                err("LAPOR KE PANEL DITOLAK: " .. salah)
                if salah:find("kunci") then
                    err("  -> KUNCI di config beda sama `wrangler secret put KUNCI`")
                elseif salah:find("jalur") then
                    err("  -> backend Cloudflare belum di-deploy / versinya lama")
                end
                err("  -> makanya tim ini KOSONG di panel")
            end
        else
            if not LAPOR_OK then ok("Lapor ke panel: nyambung lagi") end
            LAPOR_OK, LAPOR_SEBAB, LAPOR_WARN = true, nil, nil
            LAPOR_TS = os.time()
        end
    end
    return jalan, #list
end

-- ============================================================
-- perintah -> GET /perintah?tim=X
-- ============================================================
local function is_target(w, targets)
    if not w or w == "" then return false end
    local wl = w:lower()
    for _, tgt in ipairs(split(targets)) do
        if tgt ~= "" and wl:find(tgt:lower(), 1, true) then return true end
    end
    return false
end

-- ============================================================
-- v4.1: pindai paket Roblox yang kepasang di device ini
-- Ngetik 6-10 nama paket manual itu gampang typo, dan typo-nya diem —
-- pgrep gak nemu, client gak kebuka, gak ada error. Mending dipindai.
-- ============================================================
local function pindai_pkgs()
    local out = sh("su -c 'pm list packages'")
    if out == "" then out = sh("pm list packages") end
    local t = {}
    for baris in out:gmatch("[^\n]+") do
        local p = baris:match("^package:(%S+)")
        if p and p:lower():find("roblox", 1, true) then t[#t+1] = p end
    end
    table.sort(t)
    return t
end

-- ============================================================
-- setup
-- ============================================================
local function setup_wizard()
    print(C.BOLD..C.C.."\n=== ZENX WORKER v"..VERSION.." — SETUP ===\n"..C.N)
    local cfg={}
    -- v4.29: URL + kunci DIDULUIN, biar pas milih tim bisa langsung dicek ke
    -- server: nomor itu udah dipegang RedFinger lain apa belum.
    print(C.D.."  Alamat Cloudflare Worker (hasil `npx wrangler deploy`)."..C.N)
    cfg.url=ask("URL panel","https://dry-glitter-63e4.petagee5.workers.dev")
    print(C.D.."  Kunci yang sama kayak `npx wrangler secret put KUNCI`."..C.N)
    cfg.kunci=ask("Kunci","nfSUwzy6aXTFF0a546iQ2tizIVBeTF3T2Z1Xx0rb")

    print("")
    print(C.D.."  1 tim = 1 RedFinger. Nama HARUS sama kayak TIM di star_bridge.lua."..C.N)
    -- Isi ANGKA doang, prefiks "tim-" ditempel otomatis -- sama persis kayak
    -- kolom Tim di star_farm.lua. Prefiks yang beda ("tim1"/"Tim-1") bikin akun
    -- gak nempel ke tim ini dan panel keliatan kosong TANPA error apa pun.
    local DEV = dev_id()
    local tn
    while true do
        tn = tonumber((ask("Nomor tim (angka aja)","1") or ""):match("%d+") or "")
        if not tn or tn < 1 then
            warn("Isi angka, minimal 1.")
        else
            local calon = "tim-" .. tn
            cfg.tim = calon
            local r = api_get(cfg, "/tim-klaim?tim=" .. calon .. "&dev=" .. DEV)
            local boleh = ambil_str(r, "boleh")
            if boleh == nil then
                -- server gak kejawab (URL/kunci salah, atau lagi offline).
                -- jangan ngunci setup: kasih tau, terus terusin.
                warn("Gak bisa ngecek ke server (URL/kunci bener? internet nyala?)")
                warn("Lanjut pakai " .. calon .. " -- pastiin sendiri gak dipake RF lain.")
                break
            elseif boleh == "ya" then
                break
            else
                local sebab = ambil_str(r, "sebab") or (calon .. " udah dipegang device lain")
                warn("DITOLAK: " .. sebab)
                local dipakai = r and r:match('"terpakai"%s*:%s*%[(.-)%]') or ""
                dipakai = dipakai:gsub('"', ''):gsub("tim%-", "")
                if dipakai ~= "" then
                    info("Nomor yang udah kepake: " .. dipakai)
                end
                info("Pilih nomor lain.")
            end
        end
    end
    cfg.tim = "tim-" .. tn
    ok("Tim: " .. cfg.tim)
    -- pasang klaim: mulai sekarang RF lain gak bisa ambil nomor ini
    local rk = api_post(cfg, "/tim-klaim", string.format('{"tim":%s,"dev":%s}',
        jstr(cfg.tim), jstr(DEV)))
    if ambil_str(rk, "boleh") == "ya" then ok("Nomor tim ini kekunci buat RF ini") end
    -- v4.5: pemicu di-hardcode FORCE (cuma itu yg dikirim panel). gak usah nanya.
    cfg.targets="FORCE"
    -- v4.5: pilih game -> otomatis isi Place ID (gak usah ketik manual)
    print(C.D.."  Pilih game buat tim ini:"..C.N)
    print(C.D.."    1) GAG 2  (farm/garden)      -> 97598239454123"..C.N)
    print(C.D.."    2) GAG 1  (garden)           -> 126884695634066"..C.N)
    print(C.D.."    3) GAG 1 MARKET (TradeWorld) -> 129954712878723"..C.N)
    local pil = ask("Pilih (1/2/3)","1")
    local GH = "https://raw.githubusercontent.com/alzafabocahbocah-boop/ronihub/main/"
    if pil == "2" then
        cfg.place_id = "126884695634066"; cfg.game_label = "GAG 1"
    elseif pil == "3" then
        cfg.place_id = "129954712878723"; cfg.game_label = "GAG 1 MARKET"
    else
        cfg.place_id = "97598239454123"; cfg.game_label = "GAG 2"
    end
    print(C.G.."  -> "..cfg.game_label.." (place "..cfg.place_id..")"..C.N)

    -- ============================================================
    -- v5.35: SCRIPT DIPILIH SENDIRI, gak lagi kepaksa ngikut game.
    --
    -- Dulu GAG 2 SELALU dapet `gag2` (star farm). Padahal satu tim GAG 2 bisa
    -- dipakai buat dua hal beda: farm kebun (star farm) ATAU AFK beli
    -- seed/gear/pet (star seed). Jadi pilihannya dipisah.
    --
    -- Bawaannya nyesuain game biar tinggal Enter buat kasus umum:
    --   GAG 2 -> STAR FARM,  GAG 1 / market -> MARKET
    -- ============================================================
    local SCRIPT_PILIHAN = {
        { "STAR FARM", "gag2",   "farm kebun: tanam, collect, jual" },
        { "STAR SEED", "seed",   "AFK beli seed + gear + pet, terima gift" },
        { "MARKET",    "market", "akun market / TradeWorld" },
    }
    print("")
    print(C.D.."  Script yang dijalanin client tim ini:"..C.N)
    for i, sc in ipairs(SCRIPT_PILIHAN) do
        print(C.D..string.format("    %d) %-10s -> %-7s  %s", i, sc[1], sc[2], sc[3])..C.N)
    end
    local bawaanScript = (cfg.game_label == "GAG 2") and "1" or "3"
    local ps = ask("Pilih script (1/2/3)", bawaanScript)
    local sc = SCRIPT_PILIHAN[tonumber(ps) or 0] or SCRIPT_PILIHAN[tonumber(bawaanScript)]
    cfg.script_url = GH .. sc[2]
    cfg.script_label = sc[1]
    print(C.G.."  -> "..sc[1].."  "..cfg.script_url..C.N)
    print(C.D.."  Link join: paste share-URL ATAU linkCode. kosong=public."..C.N)
    cfg.link_code=ask("Link/code (Enter=public)","")
    -- v5.36: pertanyaan "Folder autoexec" DIBUANG. Jawabannya selalu sama --
    -- 20 RF = 20 kali mencet Enter buat nilai yang gak pernah beda. Nilainya
    -- tetep ada di config (ada cadangan juga di run() & tulis_autoexec), jadi
    -- kalau suatu saat ada RF yang foldernya beda, tinggal edit config-nya:
    --   autoexec_dir="/path/lain"
    cfg.autoexec_dir = cfg.autoexec_dir or "/sdcard/Delta/Autoexecute"

    -- ===== paket: dipindai, bukan diketik =====
    print()
    info("Mindai paket Roblox di device ini...")
    local ada = pindai_pkgs()
    if #ada == 0 then
        warn("Gak nemu paket Roblox. Root jalan? Client kepasang?")
        cfg.pkgs = ask("Paket Roblox (ketik manual, pisah koma)","com.roblox.client")
    else
        ok("Ketemu "..#ada.." client:")
        print("")
        for i, p in ipairs(ada) do
            local jalan = pkg_running(p) and " [jalan]" or ""
            -- tanpa warna ANSI biar gak ke-wrap berantakan di layar RF sempit
            print("   " .. i .. ". " .. p .. jalan)
        end
        print("")
        print("  Enter = pakai SEMUA")
        print("  atau ketik nomor pisah koma, misal: 1,3,5")
        print("")
        local j = ask("Pakai yang mana","")

        if j == "" or j:lower() == "semua" then
            cfg.pkgs = table.concat(ada, ",")
        elseif j:find("com%.") then
            cfg.pkgs = j
        else
            local pilih = {}
            for n in j:gmatch("%d+") do
                local p = ada[tonumber(n)]
                if p then pilih[#pilih+1] = p end
            end
            if #pilih == 0 then
                warn("Gak ada nomor yang cocok -> pakai semua")
                cfg.pkgs = table.concat(ada, ",")
            else
                cfg.pkgs = table.concat(pilih, ",")
            end
        end
    end

    cfg.poll_sec=tonumber(ask("Cek perintah tiap brp detik","5")) or 5
    print(C.D.."  Jeda minimal antar buka Roblox (biar gak spam)."..C.N)
    cfg.reopen_sec=tonumber(ask("Jeda cek-ulang client (detik)","300")) or 300
    local ar = ask("Auto-rejoin kalau akun keluar game? (y/n)","y")
    cfg.auto_rejoin = (ar:lower() ~= "n")
    cfg.auto_rejoin_menit = tonumber(ask("Auto-rejoin kalau script off berapa menit","8")) or 8
    print(C.D.."  Nunggu berapa lama sampai 1 client dianggap gagal."..C.N)
    print(C.D.."  Roblox di RedFinger biasanya 10-30 detik sampai proses muncul."..C.N)
    cfg.tunggu_sec=tonumber(ask("Batas tunggu per client (detik)","60")) or 60
    print(C.D.."  Nunggu bridge konfirmasi BENERAN masuk game (bukan nyangkut Home)."..C.N)
    print(C.D.."  Script lapor tiap ~20 detik; kasih ruang loading + verif. 90 aman."..C.N)
    cfg.konfirmasi_sec=tonumber(ask("Batas konfirmasi masuk game (detik)","90")) or 90
    print(C.D.."  Kalau gagal, diulang berapa kali sebelum nyerah."..C.N)
    cfg.max_coba=tonumber(ask("Coba ulang max per client","5")) or 5
    print(C.D.."  Napas setelah 1 client jalan, sebelum buka berikutnya."..C.N)
    cfg.stagger_sec=tonumber(ask("Jeda antar client (detik)","15")) or 15
    print(C.D.."  Tiap brp detik lapor CPU/RAM ke panel."..C.N)
    cfg.status_sec=tonumber(ask("Kirim status tiap (detik)","20")) or 20
    print(C.D.."  Mode jendela. Kalau client lo udah auto-freeform, biarin 0."..C.N)
    print(C.D.."    0 = jangan disenggol (bawaan)  |  5 = paksa freeform"..C.N)
    cfg.win_mode=tonumber(ask("Mode jendela","0")) or 0
    -- v5.37: pertanyaan shell root tetap DIBUANG, dan bawaannya jadi NYALA.
    -- Dulu ditanya dengan bawaan "n" -- padahal ini selalu dijawab y, dan
    -- untungnya besar: tiap 'su' di RedFinger makan ~6 detik, ini bikin izin
    -- root dibuka SEKALI aja.
    -- Aman dipaksa nyala karena cadangannya lengkap: dites pas nyala (gagal =
    -- balik ke cara lama), dan kalau shell-nya mati di tengah jalan kedeteksi
    -- juga. Jadi paling jelek dia cuma balik ke perilaku lama.
    -- Mau matiin di RF tertentu? edit config -> shell_tetap=false
    if cfg.shell_tetap == nil then cfg.shell_tetap = true end

    print(C.D.."  Delta Lite suka nguncup jadi gelembung sendiri. Kalau dibiarin,"..C.N)
    print(C.D.."  Roblox di dalemnya disconnect ~15 detik kemudian. Worker bisa"..C.N)
    print(C.D.."  munculin ulang jendelanya berkala. Isi 0 = mati, 10 = tiap 10 detik."..C.N)
    cfg.jaga_depan_sec = tonumber(ask("Jaga jendela tetep nongol tiap (detik)","10")) or 0

    -- v5.38: pertanyaan "Auto grid?" DIBUANG, bawaannya NYALA.
    -- Grid itu bukan pilihan gaya -- jendela HARUS ketata biar URL key Delta
    -- bisa diambil dari tiap client. Jadi nanya y/n itu gak masuk akal.
    -- Susunannya juga udah otomatis: grid_hitung baca ukuran layar sendiri dan
    -- ngitung dari jumlah client (4 client -> 2x2, lihat tabel SUSUNAN).
    -- Mau matiin di RF tertentu? edit config -> auto_grid=false
    if cfg.auto_grid == nil then cfg.auto_grid = true end
    do
        local n = #split(cfg.pkgs or "")
        local sus = SUSUNAN[n]
        if sus then
            info(("Auto grid nyala -- %d client -> %dx%d (otomatis dari jumlah client)")
                :format(n, sus[1], sus[2]))
        elseif n > 0 then
            info(("Auto grid nyala -- %d client, susunan dihitung dari ukuran layar")
                :format(n))
        else
            info("Auto grid nyala")
        end
    end
    print(C.D.."  Kunci orientasi layar RF. Kosongin kalau gak mau disenggol."..C.N)
    print(C.D.."    landscape / portrait / (Enter = jangan disenggol)"..C.N)
    local ori = ask("Orientasi layar",""):lower()
    cfg.orientasi = (ori == "landscape" or ori == "portrait") and ori or ""
    print(C.D.."  Keep-alive: bikin client tahan di background (anti force-close)."..C.N)
    print(C.D.."  Di RAM sesek ini NGURANGIN kill, bukan ngilangin. Worker tetep aman."..C.N)
    local ka = ask("Keep-alive (anti-FC)? (y/n)","y")
    cfg.keep_alive = (ka:lower() ~= "n")

    -- v5.31: GAK DITANYA LAGI. Kuncinya diisi SEKALI di panel, semua RF
    -- narik dari sana. Dulu ditanyain tiap setup -- 20 RF = 20 kali ngetik
    -- kunci yang sama, dan sekali salah ketik `zenx key` gagal tanpa sebab
    -- yang jelas. Kalau RF ini butuh kunci BEDA (jarang), isi manual:
    --   zenx key set <APIKEY>
    cfg.bypass_api_key = cfg.bypass_api_key or ""
    if cfg.bypass_api_key ~= "" then
        info("Kunci API bypass: pakai yang udah ada di config RF ini.")
    else
        info("Kunci API bypass: diambil dari panel (isi sekali di tab Seed).")
        info("  Kalau RF ini perlu kunci sendiri: zenx key set <APIKEY>")
    end

    local n = #split(cfg.pkgs)
    save_config(cfg)
    ok("Config disimpan: "..CONFIG_FILE)

    -- ============================================================
    -- v5.39: PERINTAH AWAL DISETEL SENDIRI = FORCE.
    --
    -- Dulu RF yang baru selesai setup NGANGGUR: `perintah: -`, semua client
    -- off, dan gak ada yang jalan sampai ada orang mencet "Jalankan semua" di
    -- panel. Gejalanya nyesatin -- worker keliatan normal (nyambung, lapor
    -- jalan) tapi gak ngapa-ngapain, dan gak ada petunjuk kenapa.
    --
    -- Padahal RF yang baru disetup ya jelas mau dijalanin. Jadi setup nyetel
    -- FORCE sendiri buat timnya. Mau ditahan dulu? panel -> "Hentikan".
    -- ============================================================
    do
        local r = api_post(cfg, "/perintah",
            string.format('{"tim":%s,"isi":"FORCE"}', jstr(cfg.tim)), "PUT")
        local salah = ambil_str(r or "", "error")
        if r == "" then
            warn("Perintah awal gak kekirim (panel gak nyambung).")
            warn("  Nanti pencet 'Jalankan semua' di panel, atau setup ulang.")
        elseif salah then
            warn("Perintah awal ditolak panel: " .. salah)
            warn("  Nanti pencet 'Jalankan semua' di panel.")
        else
            ok("Perintah awal disetel: FORCE -- client bakal langsung dibuka.")
            info("  Mau ditahan dulu? panel -> tim ini -> Hentikan.")
        end
    end

    -- v5.22: pasang.sh nanya kunci API SEBELUM config ada, jadi dia nyimpen
    -- sementara. Sekarang config-nya udah kebentuk -- pasang kuncinya, terus
    -- berkas sementaranya dihapus (biar kunci gak nyangkut di dua tempat).
    do
        local jalur = (os.getenv("HOME") or ".") .. "/.zenx_apikey_sementara"
        local f = io.open(jalur, "r")
        if f then
            local k = (f:read("*l") or ""):gsub("%s+", "")
            f:close()
            if k ~= "" then
                local sukses, sebab = config_set_bypass(k)
                if sukses then ok("Kunci API bypass.vip dipasang dari pasang.sh")
                else warn("Gagal masang kunci API: " .. tostring(sebab)) end
            end
            os.remove(jalur)
        end
    end
    info("Tim '"..cfg.tim.."' pegang "..n.." client:")
    for _, p in ipairs(split(cfg.pkgs)) do print(C.D.."   - "..p..C.N) end
    if n == 1 then warn("Baru 1 paket. Yakin? Biasanya 1 tim isinya 6-10.") end
    return cfg
end

-- ============================================================
-- jalan
-- ============================================================
local function run(cfg)
    cfg.reopen_sec  = cfg.reopen_sec or 300
    if cfg.auto_rejoin == nil then cfg.auto_rejoin = true end
    cfg.auto_rejoin_menit = cfg.auto_rejoin_menit or 8
    cfg.disconnect_menit  = cfg.disconnect_menit or 3   -- v4.38: ngintip dialog error
    -- v4.73: bawaan NYALA (dulu 0/mati). Jendela nguncup jadi gelembung itu
    -- kejadian terus, dan sejak v4.63 ongkosnya cuma 1 panggilan su gabungan
    -- -- jadi murah. Isi 0 di config kalau mau dimatiin.
    cfg.jaga_depan_sec    = cfg.jaga_depan_sec or 15
    cfg.suplai_sec        = cfg.suplai_sec or 20        -- v4.54: jadwal cek suplai
    -- v5.37: bawaan NYALA (dulu mati). Cadangannya lengkap -- lihat catatan
    -- di setup. Config lama yang shell_tetap=false tetep dihormatin.
    if cfg.shell_tetap == nil then cfg.shell_tetap = true end
    cfg.autoexec_dir = cfg.autoexec_dir or "/sdcard/Delta/Autoexecute"
    cfg.poll_sec    = cfg.poll_sec or 5
    cfg.stagger_sec = cfg.stagger_sec or 15
    cfg.status_sec  = cfg.status_sec or 20
    cfg.win_mode    = cfg.win_mode or 0   -- config lama gak punya -> fullscreen, gak berubah perilaku
    -- v4.34: nyalain mode deteksi longgar kalau diminta di config
    if cfg.deteksi_longgar == true then
        DETEKSI_LONGGAR = true
        warn("Deteksi LONGGAR nyala: ada ActivityRecord = dianggap jalan")
    end
    cfg.tunggu_sec  = cfg.tunggu_sec or 60
    -- v4.83: penanda layar KEY bisa ditambah dari config tanpa nyentuh worker:
    --   key_tanda="Kata A,Kata B"
    -- Berguna kalau Delta ganti tampilan -- gak usah nunggu worker diperbarui.
    if cfg.key_tanda and cfg.key_tanda ~= "" then
        local n = 0
        for _, t in ipairs(split(cfg.key_tanda)) do
            KEY_TANDA[#KEY_TANDA+1] = t; n = n + 1
        end
        if n > 0 then ok("Penanda layar KEY tambahan dari config: " .. n) end
    end
    -- v4.31: batas bawah. Di bawah 30 detik, Roblox di RF belum kelar loading ->
    -- tiap "ulang" nginterupsi loading yg lagi jalan -> gak pernah selesai (muter).
    if cfg.tunggu_sec < 30 then
        warn("tunggu_sec=" .. cfg.tunggu_sec .. " kekecilan buat RedFinger -> dipakai 30")
        cfg.tunggu_sec = 30
    end
    cfg.konfirmasi_sec = cfg.konfirmasi_sec or 90   -- v4.17: batas tunggu bridge konfirmasi masuk game
    cfg.orientasi   = cfg.orientasi or ""            -- v4.18: "" = jangan senggol orientasi
    if cfg.keep_alive == nil then cfg.keep_alive = true end   -- v4.18: config lama -> nyalain
    -- v4.28: suplai otomatis diatur TIM-1, dihitung sendiri dari nama tim.
    -- Gak usah ditanya pas setup, gak usah diinget di config -- jadi mustahil
    -- ada 2 RF yang rebutan ngatur (dulu itu bisa bikin akun gak balik ke PS asal).
    local timRingkas = (cfg.tim or ""):lower():gsub("[%s%-_]", "")
    cfg.suplai_master = (timRingkas == "tim1")
    -- v4.32: default NYALA. Kalau ternyata jendelanya fullscreen, atur_grid cuma
    -- gagal & kecatet di log -- gak ngerusak apa-apa.
    if cfg.auto_grid == nil then cfg.auto_grid = true end
    cfg.max_coba    = cfg.max_coba or 5
    cfg.tim         = cfg.tim or "tim-1"
    cfg.pkgs        = cfg.pkgs or cfg.roblox_pkg or "com.roblox.client"
    -- v5.24: nilai bawaan buat setelan yang bisa hilang kalau config disunting
    -- tangan. Tanpa ini, satu field kelupaan = worker mati pas nyala.
    cfg.targets     = cfg.targets or "FORCE"

    if not cfg.url or cfg.url:find("GANTI") or not cfg.kunci or cfg.kunci == "" then
        err("URL/Kunci belum diisi. Jalanin ulang, pilih E.")
        return
    end

    local list = split(cfg.pkgs)
    print(C.BOLD..C.G.."\n=== ZENX WORKER v"..VERSION.." — RUNNING ===\n"..C.N)
    info("Tim   : "..cfg.tim.." ("..#list.." client)")
    -- v5.21: peringatan "3 baris gak muat" DICABUT -- ternyata SALAH.
    -- Kalibrasi manual di 9 client emang gagal (tombolnya susah dilihat/dipencet
    -- tangan di jendela ~173px), tapi sapuan otomatis KENA: 0.833, 0.808.
    -- Jadi 3 baris tetep bisa dipakai bypass. Yang batesin cuma RAM.
    info("Panel : "..cfg.url)
    info("Pemicu: "..cfg.targets.." | poll "..cfg.poll_sec.."s")

    -- v4.1: freeform butuh setelan sistem. Kalau ini mati, --windowingMode 5
    -- DITERIMA tapi diem-diem gak ngefek -> kebuka fullscreen, gak ada error.
    -- Ini jebakan paling nyebelin: keliatan jalan padahal nggak.
    local wm = tonumber(cfg.win_mode) or 0
    if wm == 5 then
        local ff = sh("su -c 'settings get global enable_freeform_support'"):gsub("%s+","")
        if ff ~= "1" then
            warn("enable_freeform_support = "..(ff == "" and "null" or ff).." -> freeform MATI di sistem")
            info("Nyalain...")
            sh_silent("su -c 'settings put global enable_freeform_support 1'")
            local cek = sh("su -c 'settings get global enable_freeform_support'"):gsub("%s+","")
            if cek == "1" then
                ok("freeform dinyalain")
                warn("Sebagian device baru ngefek abis restart.")
            else
                err("Gagal nyalain. Root beneran jalan?")
            end
        else
            ok("enable_freeform_support = 1")
        end

        local fr = sh("su -c 'settings get global force_resizable_activities'"):gsub("%s+","")
        if fr ~= "1" then
            info("force_resizable_activities = "..(fr == "" and "null" or fr))
            info("Kalau Roblox nolak freeform, coba: settings put global force_resizable_activities 1")
        end
    end

    info("Window: "..(wm == 5 and "freeform (5)" or wm == 6 and "multi-window (6)" or "fullscreen (bawaan)"))

    -- tes sambungan dulu, biar gak diem-diem gagal berjam-jam
    local tes = api_get(cfg, "/perintah?tim=" .. cfg.tim)
    if tes == "" then
        err("Gak nyambung ke panel. Cek URL / internet.")
        return
    end
    local kesalahan = ambil_str(tes, "error")
    if kesalahan then
        err("Panel nolak: " .. kesalahan)
        if kesalahan:find("kunci") then err("Kunci beda sama `wrangler secret put KUNCI`.") end
        return
    end
    ok("Nyambung ke panel")

    -- v5.40: benerin skrip `up` kalau ketinggalan. Ini yang bikin RF lama
    -- nyangkut di versi tua: `up`-nya dibikin sekali pas pasang, terus gak
    -- pernah diperbarui -- dan dia bilang "OK", bukan gagal.
    pcall(tulis_skrip_up)

    -- v5.32: TARIK KUNCI API SEKARANG, bukan nanti pas dibutuhin.
    -- Alasannya: `zenx key` dipanggil justru pas lisensi Delta abis -- saat
    -- paling genting. Kalau baru narik di situ dan panel lagi mati, bypass
    -- gagal. Ditarik di awal + disimpen ke config = pas dibutuhin udah lokal,
    -- instan, dan gak bergantung panel sama sekali.
    do
        local k, asal = ambil_apikey(cfg)
        if k ~= "" then
            info("Kunci API bypass siap (dari " .. asal .. ")")
        else
            warn("Kunci API bypass belum ada -- `zenx key` bakal gagal.")
            warn("  Isi BYPASS_KEY_BAWAAN di worker, atau: zenx key set <APIKEY>")
        end
    end

    tulis_autoexec(cfg)   -- v4.8: pasang loader ke autoexec Delta

    -- v4.18: kunci orientasi (kalau diset) + keep-alive awal
    if cfg.orientasi == "landscape" or cfg.orientasi == "portrait" then
        set_orientasi(cfg); ok("Orientasi dikunci: " .. cfg.orientasi)
    end
    -- v4.70: nyalain shell root tetap (kalau diminta). Gagal = lanjut cara lama.
    if cfg.shell_tetap == true then
        local ok2, sebab = shell_nyalakan()
        if ok2 then
            ok("Shell root tetap NYALA -- 'su' cuma dibuka sekali")
        else
            warn("Shell root tetap gagal (" .. (sebab or "?") .. ") -> pakai cara lama")
        end
    end

    -- v4.21: wake-lock CPU (biar worker gak ditidurin pas layar idle)
    sh_silent("termux-wake-lock")
    if cfg.suplai_master then
        ok("tim-1 -> RF ini yang mancing suplai otomatis")
    end
    -- v4.30: kasih tau kenapa auto grid mati, biar gak bingung nunggu-nunggu
    if cfg.auto_grid ~= true then
        warn("AUTO GRID mati di config. Nyalain: setup ulang (rm zenx_worker_config.lua)")
    else
        ok("Auto grid nyala")
    end
    if cfg.keep_alive ~= false then
        keep_alive_apply(cfg)
        -- v4.22: freezer-disable DICABUT. dulu dikira client "off" karena Android
        -- bekuin proses -- SALAH: game-nya jalan normal, yg berhenti cuma LAPORAN
        -- (bug jarak denyut di bridge, udah dibenerin di star_farm v13.10 +
        -- market v8.336). matiin freezer malah nambah beban CPU -> task.wait di
        -- script makin molor -> laporan makin telat. jadi jangan disenggol.
        ok("Keep-alive (anti-FC) nyala")
    end

    -- v4.9: cache mapping client<->akun (baca prefs.xml sekali di awal, refresh berkala).
    -- prefs.xml jarang berubah (akun tetap per client), jadi gak usah baca tiap loop.
    local mapAkun = {}   -- pkg -> username
    -- v4.62: baca username SEMUA client dalam SATU panggilan su. Dulu satu-satu
    -- (4 client = 4 x ~5 detik = ~20 detik tiap refresh).
    local function refresh_map()
        local pkgs = split(cfg.pkgs)
        local perintah = {}
        for _, pkg in ipairs(pkgs) do
            perintah[#perintah+1] = string.format(
                'echo "@@%s"; cat /data/data/%s/shared_prefs/prefs.xml 2>/dev/null', pkg, pkg)
        end
        local o = sh("su -c '" .. table.concat(perintah, "; ") .. "'") or ""
        -- pisah per penanda @@<paket>
        local skrgPkg = nil
        for baris in o:gmatch("[^\r\n]+") do
            local tanda = baris:match("^@@(%S+)")
            if tanda then
                skrgPkg = tanda
            elseif skrgPkg then
                local u = baris:match('<string name="username">(.-)</string>')
                if u then mapAkun[skrgPkg] = u; skrgPkg = nil end
            end
        end
        -- cadangan: kalau ada yang gak kebaca, ambil satu-satu (jarang)
        for _, pkg in ipairs(pkgs) do
            if not mapAkun[pkg] then
                local u = baca_username(pkg)
                if u then mapAkun[pkg] = u end
            end
        end
    end
    refresh_map()
    local lastMapRefresh = os.time()

    -- v4.14: auto-assign akun ke tim. worker kirim daftar akun yg dia pegang
    -- (dari mapAkun) ke panel -> panel tau akun ini di tim mana OTOMATIS.
    -- mode isi_kosong: gak nimpa assign manual di panel.
    local function auto_assign_tim()
        local akun = {}
        for _, ak in pairs(mapAkun) do akun[#akun+1] = ak end
        if #akun == 0 then return end
        local body = '{"tim":"' .. cfg.tim .. '","game":"' .. (cfg.game_label or "") ..
                     '","isi_kosong":true,"akun":['
        for i, a in ipairs(akun) do
            body = body .. '"' .. a .. '"'
            if i < #akun then body = body .. "," end
        end
        body = body .. "]}"
        local r = ""
        pcall(function()
            r = api_post(cfg, "/assign-tim", body) or ""
        end)
        -- v5.43: lapor apa yang DIBETULIN, bukan cuma jumlahnya.
        -- Perlu karena akun bekas game lain itu masalah yang membingungkan:
        -- timnya bener tapi gak nongol di tab yang bener, dan gak ada tanda
        -- apa pun. Sekarang keliatan pas dibetulin.
        local nG = tonumber((r or ""):match('"gameDiperbarui"%s*:%s*(%d+)')) or 0
        local nP = tonumber((r or ""):match('"placeDibersihin"%s*:%s*(%d+)')) or 0
        if nG > 0 or nP > 0 then
            ok(("auto-assign %d akun ke %s  (%d game dibetulin, %d place basi dibuang)")
                :format(#akun, cfg.tim, nG, nP))
            info("  akun ini bekas game lain -- sekarang kecatat di " .. (cfg.game_label or "?"))
        else
            ok("auto-assign " .. #akun .. " akun ke " .. cfg.tim)
        end
    end
    auto_assign_tim()
    local lastAssign = os.time()

    -- v4.11: assign PS per-client. narik dari panel /assign-ps?tim=X.
    -- hasilnya: mapLink[pkg]=link (buat buka client ke PS-nya),
    --           mapPsNama[pkg]=nama (buat tampil di tabel).
    local mapLink, mapPsNama = {}, {}
    local function refresh_ps()
        local r = api_get(cfg, "/assign-ps?tim=" .. cfg.tim)
        -- format: {"assign":[{"akun":"fifinx_5","ps_nama":"leveling 1","link":"..."},...]}
        -- cocokin akun -> pkg (lewat mapAkun kebalik)
        local akun2pkg = {}
        for pkg, ak in pairs(mapAkun) do akun2pkg[ak] = pkg end
        mapLink, mapPsNama = {}, {}
        -- parse tiap objek assign
        for obj in (r or ""):gmatch('{.-}') do
            local akun = obj:match('"akun"%s*:%s*"(.-)"')
            local psn  = obj:match('"ps_nama"%s*:%s*"(.-)"')
            local link = obj:match('"link"%s*:%s*"(.-)"')
            if akun and akun2pkg[akun] then
                local pkg = akun2pkg[akun]
                if link and link ~= "" then mapLink[pkg] = link end
                if psn and psn ~= "" then mapPsNama[pkg] = psn end
            end
        end
    end
    refresh_ps()
    local lastPsRefresh = os.time()

    -- v4.10: tampilan TABEL (clear screen + redraw kiri atas, gak scroll spam).
    -- log penting (auto-rejoin/error) ditaro di buffer, muncul di bawah tabel.
    local logBuf = {}   -- ring buffer log terakhir
    local function tambahLog(msg)
        local baris = os.date("%H:%M:%S") .. " " .. msg
        logBuf[#logBuf+1] = baris
        while #logBuf > 6 do table.remove(logBuf, 1) end   -- simpan 6 terakhir
        catatKirim(baris)   -- v4.24: ikut dikirim ke panel
    end

    -- v4.16: CACHE status client + ram/cpu. dulu gambar_tabel manggil pkg_running
    -- (dumpsys, LAMBAT) buat tiap client TIAP redraw -> tabel lelet. sekarang status
    -- di-refresh berkala di background, tabel cuma baca cache -> redraw INSTAN.
    local cacheRun = {}    -- pkg -> true/false (jalan?)
    local runSebelum = {}  -- v4.46: status ronde lalu, buat nangkep yang MATI MENDADAK
    local cacheBridge = {} -- v4.49: script beneran lapor apa nggak (bukan cuma window ada)
    local cacheRam = {0,0,0}
    local cacheCpu = 0
    local lastStatusCek = 0
    local function refresh_status()
        -- v4.63: satu dump buat semua client (dulu satu-satu -> ~24 detik)
        local semua = pkg_running_semua(split(cfg.pkgs))
        for _, pkg in ipairs(split(cfg.pkgs)) do
            cacheRun[pkg] = semua[pkg]
        end
        -- v4.49: "ada di layar game" BEDA sama "script beneran jalan". Jendela
        -- yang dikuncupin jadi gelembung tetep punya activity -> ke-baca jalan
        -- padahal diem. Yang tau sebenernya cuma bridge (script lapor apa nggak).
        local st = api_get(cfg, "/stat")
        for _, pkg in ipairs(split(cfg.pkgs)) do
            local ak = mapAkun[pkg]
            cacheBridge[pkg] = ak and bridge_fresh(st, ak) or false
        end
        local u, f, t = baca_ram()
        cacheRam = {u, f, t}
        cacheCpu = baca_cpu()
    end
    -- v4.16: JANGAN refresh_status blocking di awal (dumpsys semua client = lama).
    -- biarin cache kosong dulu -> tabel langsung muncul (status "cek..."), status
    -- nyusul di loop pertama. jadi tabel muncul INSTAN, gak nunggu dumpsys.
    for _, pkg in ipairs(split(cfg.pkgs)) do cacheRun[pkg] = nil end
    local function gambar_tabel(isi, statusPerintah)
        io.write("\27[2J\27[H")   -- clear screen + kursor ke kiri atas
        local used, free, total = cacheRam[1], cacheRam[2], cacheRam[3]
        local cpu = cacheCpu
        -- header
        -- v5.35: script yang aktif ikut ditampilin. Perlu karena satu tim GAG 2
        -- bisa jalanin STAR FARM atau STAR SEED -- tanpa ini gak keliatan yang
        -- mana, dan salah script itu gejalanya membingungkan (client jalan tapi
        -- gak ngapa-ngapain).
        local scLabel = cfg.script_label or ""
        if scLabel == "" and (cfg.script_url or "") ~= "" then
            scLabel = tostring(cfg.script_url):match("([^/]+)$") or ""
        end
        io.write(C.BOLD..C.G.."  ZENX WORKER v"..VERSION.."  ·  "..cfg.tim.."  ·  "..(cfg.game_label or "")..C.N
            ..(scLabel ~= "" and (C.D.."  ·  "..C.C..scLabel..C.N) or "").."\n")
        io.write(C.D.."  "..os.date("%H:%M:%S").."  ·  perintah: "..(isi ~= "" and isi or "-").."\n"..C.N)
        io.write("\n")
        -- tabel
        local list = split(cfg.pkgs)
        local jalan = 0
        io.write(C.D.."  ┌──────────┬────────────────┬────────────┬──────────┐\n"..C.N)
        io.write(C.D.."  │ "..C.N.."CLIENT   "..C.D.."│ "..C.N.."AKUN           "..C.D.."│ "..C.N.."SERVER     "..C.D.."│ "..C.N.."STATUS   "..C.D.."│\n"..C.N)
        io.write(C.D.."  ├──────────┼────────────────┼────────────┼──────────┤\n"..C.N)
        local beku = 0
        for _, pkg in ipairs(list) do
            local run = cacheRun[pkg]
            -- v4.49: yang kehitung "jalan" cuma yang script-nya BENERAN lapor.
            -- window ada tapi diem (dikuncupin/beku) dihitung terpisah.
            if run and cacheBridge[pkg] == false and mapAkun[pkg] then
                beku = beku + 1
            elseif run then jalan = jalan + 1 end
            local short = pkg:gsub("com%.roblox%.", "")   -- clienu
            local akun = mapAkun[pkg] or "?"
            local srv = mapPsNama[pkg] or "public"
            local st, warna
            if run == nil then st, warna = "◌ cek...", C.D      -- belum kecek
            elseif run and cacheBridge[pkg] == false and mapAkun[pkg] then
                -- window-nya ada tapi script gak lapor -> dikuncupin / beku
                st, warna = "◐ beku", C.Y
            elseif run then st, warna = "● jalan", C.G
            else st, warna = "○ off", C.Y end
            -- v5.34: nama akun dipotong dari DEPAN, bukan belakang.
            -- Pola nama akun itu awalan+nomor (wildnx_12, oliviainvent3), jadi
            -- yang MEMBEDAKAN ada di ujung belakang. Motong dari belakang bikin
            -- 4 akun beda keliatan sama persis ("oliviainvent" itu pas 12
            -- huruf) -- dan itu nyesatin: keliatannya kayak 4 client login ke
            -- satu akun yang sama, padahal cuma kepotong.
            local akunTampil = akun
            if #akunTampil > 14 then akunTampil = "…" .. akunTampil:sub(-13) end
            io.write(string.format("  "..C.D.."│ "..C.N.."%-8s "..C.D.."│ "..C.N.."%-14s "..C.D.."│ "..C.C.."%-10s"..C.D.." │ "..warna.."%-8s"..C.D.." │\n"..C.N,
                short:sub(1,8), akunTampil, srv:sub(1,10), st))
        end
        io.write(C.D.."  └──────────┴────────────────┴────────────┴──────────┘\n"..C.N)
        io.write("\n")
        -- ringkas
        io.write(string.format("  "..C.G.."%d/%d jalan"..C.N.."%s  ·  CPU %d%%  ·  RAM %.1f/%.1fGB\n",
            jalan, #list,
            beku > 0 and (C.Y.."  ·  "..beku.." beku"..C.N) or "",
            cpu, used, total))
        -- v5.30: status laporan ke panel. Kalau ini GAGAL, tim bakal keliatan
        -- KOSONG di panel walau worker-nya sendiri jalan normal.
        if LAPOR_OK == false then
            io.write("  "..C.R.."LAPOR KE PANEL GAGAL: "..tostring(LAPOR_SEBAB or "?")..C.N.."\n")
            io.write("  "..C.D.."   -> makanya tim ini kosong di panel"..C.N.."\n")
        elseif LAPOR_OK == true then
            local umur = os.time() - (LAPOR_TS or 0)
            io.write("  "..C.D.."panel: kekirim "..umur.."s lalu"..C.N.."\n")
        else
            io.write("  "..C.D.."panel: belum pernah lapor"..C.N.."\n")
        end
        -- log
        if #logBuf > 0 then
            io.write("\n"..C.D.."  ── log ──\n"..C.N)
            for _, l in ipairs(logBuf) do io.write(C.D.."  "..l.."\n"..C.N) end
        end
        io.flush()
    end

    notify("ZenX "..cfg.tim, "Standby — nungguin: "..cfg.targets)

    local lastOpen, lastStatus = 0, 0
    local lastAutoRejoin = 0   -- v4.9: kapan terakhir cek auto-rejoin
    local lastKeepAlive = os.time()   -- v4.18: kapan terakhir apply keep-alive
    local psGantiKerjakan = 0   -- v4.51: psGanti terakhir yang UDAH dikerjain
    -- v5.29: script per tim dari panel
    local SCRIPT_KERJAKAN  = 0    -- scriptGanti terakhir yang udah dikerjain
    local SCRIPT_URL_AKHIR = ""   -- url terakhir yang beneran ditulis ke autoexec
    local lastJagaDepan = 0     -- v4.52: kapan terakhir munculin ulang jendela
    local lastSuplaiCek = 0     -- v4.54: kapan terakhir minta CF ngerencanain suplai
    local nudgeCnt = {}   -- v4.21: berapa kali client di-nudge (bangunin) tanpa sembuh
    local lastIsi = nil

    while true do
        -- ===== v4.2: pintu keluar =====
        if ada_stop() then
            bersih(cfg, "diminta stop")
            return
        end

        local resp = api_get(cfg, "/perintah?tim=" .. cfg.tim)
        local isi  = ambil_str(resp, "isi") or ""
        -- v4.16: refresh status (dumpsys, berat) cuma tiap 10 detik, bukan tiap redraw.
        if (os.time() - lastStatusCek) >= 10 then refresh_status(); lastStatusCek = os.time() end
        gambar_tabel(isi)   -- v4.10: redraw tabel dari cache (instan)
        local now  = os.time()

        -- v4.3: narik link private server dari panel. kalau panel udah pernah set
        -- (ts>0), pakai link panel (walau kosong = public). kalau panel belum
        -- pernah set, biarin cfg._ps_override nil -> build_url pakai link lokal.
        do
            local rps = api_get(cfg, "/ps?tim=" .. cfg.tim)
            local psTs = ambil_num(rps, "ts") or 0   -- v4.53: angka, bukan teks
            if psTs > 0 then
                local link = ambil_str(rps, "link") or ""
                -- _ps_last nyimpen link terakhir dari panel biar gak spam log.
                -- pakai flag terpisah, bukan _ps_override, biar "" (public) kebedain
                -- dari nil (panel belum set).
                if link ~= cfg._ps_last then
                    cfg._ps_last = link
                    cfg._ps_override = link
                    info("PS dari panel: " .. (link ~= "" and link or "(public)"))
                end
            end
        end

        -- v4.4: CLOSE = tutup paksa semua client (Roblox ketutup, akun keluar).
        -- REJOIN = tutup paksa DULU, terus buka lagi (fresh). beda dari FORCE yg
        -- cuma mastiin kebuka (client yg udah jalan dibiarin).
        -- pakai penanda biar gak loop terus (perintah nyangkut di DB).
        -- v4.4: CLOSE / REJOIN ditangani dulu. skip_sisa=true -> lewati blok
        -- FORCE/STANDBY di bawah biar gak dobel-buka. (pakai flag, bukan goto,
        -- karena goto gak boleh lompatin deklarasi lokal di Luau.)
        local skip_sisa = false
        local U = isi:upper()
        if U:find("REJOIN") then
            if isi ~= lastIsi then
                lastIsi = isi
                -- v4.15: REJOIN:namaakun = rejoin CLIENT tertentu (bukan semua).
                -- v4.20: bisa BANYAK akun, pisah koma: REJOIN:akun1,akun2 -> rejoin
                -- per-client masing-masing (tutup 1, buka 1). JANGAN kill all.
                -- REJOIN doang (tanpa :akun) = rejoin SEMUA (kill all) -- buat ganti
                -- server SEMUA client sekaligus.
                local akunTarget = isi:match("REJOIN:(.+)")
                if akunTarget then
                    -- parse daftar akun (pisah koma)
                    local daftarAkun = {}
                    for nm in akunTarget:gmatch("[^,]+") do
                        nm = nm:gsub("%s+", "")
                        if nm ~= "" then daftarAkun[#daftarAkun+1] = nm end
                    end
                    refresh_ps()   -- ambil PS terbaru sekali di awal
                    -- v4.61: kumpulin dulu, TUTUP BARENGAN, baru buka bertahap.
                    -- Perintah dari panel jadi kerasa langsung -- bukan nunggu
                    -- client 1 kelar dulu baru nyentuh client 2.
                    local pkgRejoin, namaRejoin = {}, {}
                    for _, namaAkun in ipairs(daftarAkun) do
                        local pkgTarget = nil
                        for pkg, ak in pairs(mapAkun) do
                            if ak == namaAkun then pkgTarget = pkg break end
                        end
                        if pkgTarget then
                            pkgRejoin[#pkgRejoin+1]   = pkgTarget
                            namaRejoin[#namaRejoin+1] = namaAkun
                        else
                            tambahLog("REJOIN: akun " .. namaAkun .. " gak ketemu di RF ini")
                        end
                    end
                    if #pkgRejoin > 0 then
                        -- semua client tim ikut? tutup sekalian (lebih bersih)
                        local semua = (#pkgRejoin == #split(cfg.pkgs))
                        tambahLog(("REJOIN %d akun: %s"):format(#pkgRejoin, table.concat(namaRejoin, ", ")))
                        close_all(cfg, semua and nil or pkgRejoin, mapLink)
                        os.execute("sleep 2")
                        for i, pkg in ipairs(pkgRejoin) do
                            open_one(cfg, pkg, mapLink[pkg])
                            if i < #pkgRejoin then os.execute("sleep " .. (cfg.stagger_sec or 10)) end
                        end
                        notify("ZenX "..cfg.tim, "rejoin " .. #pkgRejoin .. " akun")
                    end
                else
                    warn("REJOIN dari panel -> tutup semua, buka lagi")
                    close_all(cfg)
                    os.execute("sleep 3")
                    local function batal_r()
                        if ada_stop() then return true end
                        local r = api_get(cfg, "/perintah?tim=" .. cfg.tim)
                        return (ambil_str(r, "isi") or ""):upper():find("STANDBY") ~= nil
                    end
                    refresh_ps()
                    local function lapor_rejoin()
                        refresh_status(); lastStatusCek = os.time()
                        gambar_tabel(isi)
                        lapor(cfg, isi, cacheRun)
                    end
                    local h = open_all(cfg, nil, batal_r, lapor_rejoin, mapLink, mapAkun, true)
                    ok(string.format("REJOIN kelar: %d jalan, %d gagal", h.ok, h.gagal))
                    notify("ZenX "..cfg.tim, "REJOIN -> "..h.ok.." client")
                    lastOpen = os.time()
                    lastStatus = 0
                end
            end
            skip_sisa = true
        elseif U:find("FRONT") then
            if isi ~= lastIsi then
                lastIsi = isi
                local n = front_all(cfg, mapLink)
                tambahLog("FRONT: " .. n .. " client dibawa ke depan")
                notify("ZenX "..cfg.tim, "semua client ke depan")
            end
            skip_sisa = true
        elseif U:find("TUGAS") then
            -- v4.55: panel minta rincian "tim ini lagi ngapain & mau ngapain".
            -- Semua ditulis lewat tambahLog biar ikut kekirim ke panel juga.
            if isi ~= lastIsi then
                lastIsi = isi
                setAksi("nyusun laporan tugas")
                local st  = api_get(cfg, "/stat")
                local sup = api_get(cfg, "/suplai")
                local skrgSrv = ambil_num(st, "skrg") or os.time()

                tambahLog("=== TUGAS " .. cfg.tim .. " ===")
                local nJalan, nBeku, nOff = 0, 0, 0
                for _, pkg in ipairs(split(cfg.pkgs)) do
                    local short = pkg:gsub("com%.roblox%.", "")
                    local akun  = mapAkun[pkg] or "?"
                    local ps    = mapPsNama[pkg] or "public"
                    local ada   = pkg_running(pkg)
                    local lapor = akun ~= "?" and bridge_ts(st, akun) or nil
                    local umur  = lapor and (skrgSrv - lapor) or nil
                    local kead
                    if not ada then kead = "OFF (window gak ada)"; nOff = nOff + 1
                    elseif umur and umur <= FRESH_WINDOW then
                        kead = "jalan (lapor " .. umur .. "s lalu)"; nJalan = nJalan + 1
                    else
                        kead = "BEKU (" .. (umur and (umur .. "s gak lapor") or "belum pernah lapor") .. ")"
                        nBeku = nBeku + 1
                    end
                    tambahLog(short .. " | " .. akun .. " | " .. ps .. " | " .. kead)
                end
                tambahLog(("ringkas: %d jalan, %d beku, %d off"):format(nJalan, nBeku, nOff))

                -- tugas suplai yang lagi nyangkut di tim ini
                local nAktif = ambil_num(sup, "jumlahAktif") or 0
                local alasan = ambil_str(sup, "alasan") or ""
                local psTuju = ambil_str(sup, "psTujuan") or ""
                if nAktif > 0 then
                    tambahLog("suplai: " .. nAktif .. " akun lagi dirutein"
                              .. (psTuju ~= "" and (" (tujuan " .. psTuju .. ")") or ""))
                else
                    tambahLog("suplai: gak ada yang lagi dirutein"
                              .. (alasan ~= "" and (" -- " .. alasan) or ""))
                end
                tambahLog("perintah aktif: " .. (isi ~= "" and isi or "-"))
                notify("ZenX "..cfg.tim, "laporan tugas siap")
            end
            skip_sisa = true
        elseif U:find("GRID") then
            if isi ~= lastIsi then
                lastIsi = isi
                -- v4.82: nata ulang HARUS lewat restart client. App Cloner cuma
                -- baca posisi pas app MULAI, dan nimpa balik pas app DITUTUP --
                -- jadi nulis ke client yang lagi jalan itu percuma dua kali.
                -- Alurnya: tutup semua -> tulis semua -> buka satu-satu.
                setAksi("nata jendela (tutup -> tulis posisi -> buka)")
                local peta, sebabGrid, kol, bar, W, H = grid_hitung(cfg)
                if not peta then
                    tambahLog("GRID gagal: " .. tostring(sebabGrid))
                    warn("GRID gagal: " .. tostring(sebabGrid))
                else
                    tambahLog(string.format("GRID: nata %dx%d di layar %dx%d -- client ditutup dulu",
                        kol or 0, bar or 0, W or 0, H or 0))
                    close_all(cfg)
                    os.execute("sleep 2")

                    local nTulis, nGagal = 0, 0
                    for _, pkg in ipairs(split(cfg.pkgs)) do
                        local tok, tket = tata_satu(pkg, peta[pkg])
                        if tok then nTulis = nTulis + 1
                        else
                            nGagal = nGagal + 1
                            tambahLog("   " .. pkg:gsub("com%.roblox%.","") .. ": " .. tostring(tket))
                        end
                    end
                    tambahLog(("GRID: posisi ketulis %d client%s"):format(
                        nTulis, nGagal > 0 and (", " .. nGagal .. " gagal") or ""))

                    refresh_ps()
                    local function batal_g()
                        if ada_stop() then return true end
                        local r = api_get(cfg, "/perintah?tim=" .. cfg.tim)
                        local i = (ambil_str(r, "isi") or ""):upper()
                        return i:find("STANDBY") ~= nil or i:find("STOP") ~= nil
                            or i:find("KILL") ~= nil or i:find("CLOSE") ~= nil
                    end
                    local function lapor_g()
                        refresh_status(); lastStatusCek = os.time()
                        gambar_tabel(isi)
                        lapor(cfg, isi, cacheRun)
                    end
                    local h = open_all(cfg, nil, batal_g, lapor_g, mapLink, mapAkun, true)
                    tambahLog(("GRID: kelar -- %d client kebuka lagi"):format(h.ok))
                    notify("ZenX "..cfg.tim, "grid: " .. nTulis .. " jendela ditata")
                    lastOpen = os.time()
                    lastStatus = 0
                end
            end
            skip_sisa = true
        elseif U:find("CLOSE") then
            if isi ~= lastIsi then
                warn("CLOSE dari panel -> tutup semua client")
                lastIsi = isi
                local n = close_all(cfg)
                ok("CLOSE: " .. n .. " client ditutup")
                notify("ZenX "..cfg.tim, "CLOSE -> "..n.." client ditutup")
                lapor(cfg, isi, cacheRun)
                lastStatus = os.time()
            end
            skip_sisa = true
        end

        if not skip_sisa then

        -- KILL dari panel: beda sama STANDBY.
        -- STANDBY = berhenti buka client, worker tetep jalan.
        -- KILL    = worker-nya sendiri yang mati.
        if isi:upper():find("KILL") then
            warn("KILL dari panel")
            lapor(cfg, "MATI")   -- kabarin panel dulu, biar gak nunggu 7 menit
            bersih(cfg, "KILL dari panel")
            return
        end

        if isi ~= lastIsi and isi ~= "" then
            info("perintah baru: " .. isi)
            lastIsi = isi
        end

        -- Perintah kesimpen di DB, jadi isinya = keadaannya.
        -- Gak perlu forceSticky kayak jaman ntfy (pesan kedaluwarsa).
        local mati = isi:upper():find("STANDBY") or isi:upper():find("STOP")
        local hit  = (not mati) and is_target(isi, cfg.targets)

        -- v4.24: status dasar buat panel (nanti ditimpa aksi spesifik kalau lagi kerja)
        if mati then
            setAksi("standby — gak buka client")
        else
            local nJalan = 0
            for _, p in ipairs(split(cfg.pkgs)) do if cacheRun[p] then nJalan = nJalan + 1 end end
            setAksi(string.format("mantau %d/%d client jalan", nJalan, #split(cfg.pkgs)))
        end

        -- ============================================================
        -- v5.02: BYPASS KEY OTOMATIS -- dikerjain SAMPAI KELAR, yang lain nunggu.
        --
        -- Kenapa harus eksklusif: nyari tombol itu butuh jendela client di depan
        -- + baca papan klip (yang butuh Termux di depan sebentar). Kalau barengan
        -- sama jaga-jendela / buka client / auto-rejoin, fokusnya kerebut terus
        -- dan urutan tap-nya kacau. Karena Lua di sini jalan satu-satu, blok ini
        -- otomatis nahan yang lain selama dia jalan.
        --
        -- CUKUP SATU CLIENT: berkas lisensinya di /sdcard, dipakai BARENG semua
        -- client. Sekali ketulis, clienu sampai clienz kebagian -- gak usah
        -- diulang per client.
        -- ============================================================
        local lewatiRonde = false
        -- v5.13: sapuan otomatis BAWAANNYA MATI. Nyapu itu mindah-mindahin
        -- jendela terus -- ganggu banget kalau user lagi mau tap manual, dan
        -- keberhasilannya belum kebukti di semua ukuran jendela.
        -- Nyalain sendiri kalau mau:  auto_key=true  di config.
        if hit and cfg.auto_key == true and lisensi_keadaan(cfg) == "hilang"
           and (now - (BYPASS_TERAKHIR or 0)) > 300 then
            BYPASS_TERAKHIR = now
            setAksi("BYPASS KEY -- fokus ke sini dulu")
            tambahLog("BYPASS: lisensi Delta hilang -> cari key lewat 1 client, yang lain nunggu")

            -- pilih 1 client: yang lagi jalan diutamakan (layar key-nya udah nongol)
            local pilih
            for _, p in ipairs(split(cfg.pkgs)) do
                if cacheRun[p] then pilih = p break end
            end
            pilih = pilih or split(cfg.pkgs)[1]
            tambahLog("BYPASS: pakai " .. pilih:gsub("com%.roblox%.", ""))

            local link, _, _, ket = cari_tombol_key(cfg, pilih)
            if link then
                tambahLog("BYPASS: dapet link (" .. tostring(ket) .. ") -> kirim ke API")
                local kunci, sebab = bypass_kunci(cfg, link, false)
                if kunci then
                    local wok, wket = tulis_lisensi(cfg, kunci)
                    if wok then
                        tambahLog("BYPASS: BERES -- kunci ketulis, kepakai SEMUA client")
                        lastOpen = 0   -- langsung buka ulang client ronde berikutnya
                    else
                        tambahLog("BYPASS: kunci dapet TAPI gagal nulis -- " .. tostring(wket))
                    end
                else
                    tambahLog("BYPASS: API gagal -- " .. tostring(sebab))
                end
            else
                tambahLog("BYPASS: gagal nemu tombol -- " .. tostring(ket))
                tambahLog("   (coba manual: zenx cari " .. pilih:gsub("com%.roblox%.", "") .. ")")
            end
            setAksi("bypass selesai")
            lewatiRonde = true   -- sisa ronde ini dilewat, biar keadaannya settle dulu
        end

        if not lewatiRonde then   -- v5.02: ronde bypass gak ngerjain yang lain

        -- v4.46: CLIENT MATI MENDADAK (ditutup manual / di-swipe / crash).
        -- Dulu nunggu siklus reopen_sec (5 MENIT) baru kebuka lagi. Sekarang
        -- ketahuan dalam ~10 detik: banding status ronde ini sama ronde lalu.
        -- Cuma pas FORCE aktif -- kalau STANDBY/CLOSE ya emang sengaja ditutup.
        if hit then
            for _, pkg in ipairs(split(cfg.pkgs)) do
                if runSebelum[pkg] == true and cacheRun[pkg] == false then
                    tambahLog("MATI MENDADAK: " .. (mapAkun[pkg] or pkg:gsub("com%.roblox%.",""))
                              .. " -> dibuka lagi")
                    setAksi("buka lagi " .. (mapAkun[pkg] or pkg:gsub("com%.roblox%.","")))
                    open_one(cfg, pkg, mapLink[pkg])
                    os.execute("sleep 3")
                    refresh_status(); lastStatusCek = os.time()
                    gambar_tabel(isi)
                end
            end
        end
        for _, pkg in ipairs(split(cfg.pkgs)) do runSebelum[pkg] = cacheRun[pkg] end

        if hit then
            local only = isi:match("FORCE:([%w%.%_]+)")
            if (now - lastOpen) >= cfg.reopen_sec then
                -- dipanggil di sela-sela client: STANDBY dari panel langsung kebaca,
                -- gak nunggu 10 client kelar dulu
                -- v4.53: catat penanda assign-PS pas MULAI. Kalau berubah di
                -- tengah jalan (panel/suplai mindahin akun), berhenti aja --
                -- instruksi panel lebih penting daripada nerusin sesi lama.
                -- v4.56: PANEL SELALU DIDULUIN. Patokannya: apa pun yang berubah
                -- di panel (perintah baru, assign PS baru) -> berhenti, kerjain
                -- yang baru. Dulu cuma daftar perintah tertentu yang bisa nyerobot,
                -- jadi instruksi lain nunggu sesi lama kelar (bisa bermenit-menit).
                -- v4.57: JANGAN pakai potret lokal. Dulu psAwal dipotret pas mulai
                -- dan gak pernah diperbarui -> perubahan yang SAMA bikin batal
                -- berulang-ulang, worker gak pernah kelar buka client (kerasa lemot
                -- banget). Sekarang pembandingnya psGantiKerjakan -- yang di-update
                -- pas perubahan itu BENERAN dikerjain.
                local cmdAwal   = (isi or ""):upper()
                -- v4.57: REM. Sekali batal karena PS berubah, kasih jeda sebelum
                -- boleh batal lagi karena alasan yang sama -- biar gak muter
                -- "batal -> mulai -> batal" dalam hitungan detik.
                local batalTerakhir = 0
                local function batal()
                    if ada_stop() then return true end   -- stop lokal juga ngebatalin
                    local r = api_get(cfg, "/perintah?tim=" .. cfg.tim)

                    -- assign PS berubah (panel / suplai otomatis mindahin akun)
                    local psSkrg = tonumber((r or ""):match('"psGanti"%s*:%s*(%d+)')) or 0
                    if psGantiKerjakan > 0 and psSkrg > psGantiKerjakan
                       and (os.time() - batalTerakhir) >= 30 then
                        batalTerakhir = os.time()
                        warn("assign PS berubah dari panel -> berhenti, ngerjain yang baru")
                        return true
                    end

                    -- perintah dari panel. FORCE SENGAJA dikecualiin: panel suka
                    -- ngirim FORCE otomatis abis REJOIN/FRONT/GRID -- kalau itu
                    -- dianggap "perintah baru", worker malah motong kerjaannya
                    -- sendiri. Selain FORCE = instruksi beneran -> didahulukan.
                    local i = (ambil_str(r, "isi") or ""):upper()
                    if i ~= "" and i ~= cmdAwal and not i:find("^FORCE$") then
                        warn("perintah baru dari panel: " .. i .. " -> berhenti, itu duluan")
                        return true
                    end
                    -- jaring lama: perintah yang WAJIB nyerobot walau sama isinya
                    return i:find("STANDBY") ~= nil
                        or i:find("STOP") ~= nil
                        or i:find("KILL") ~= nil
                        or i:find("REJOIN") ~= nil
                        or i:find("CLOSE") ~= nil
                end
                -- v4.33: tabel ikut ke-update PAS lagi buka client. Dulu redraw
                -- cuma di loop utama, sedangkan open_all ngeblok bermenit-menit ->
                -- tabel nampilin data LAMA (client udah nyala tapi ketulis "off").
                local function lapor_sela()
                    refresh_status(); lastStatusCek = os.time()
                    gambar_tabel(isi)
                    lapor(cfg, isi, cacheRun)
                end

                local h = open_all(cfg, only, batal, lapor_sela, mapLink, mapAkun)

                if h.ok > 0 or h.gagal > 0 then
                    local ringkas = string.format("%d jalan, %d gagal, %d dilewat",
                        h.ok, h.gagal, h.lewat)
                    if h.gagal > 0 then
                        err("Kelar: " .. ringkas)
                        err("Gagal: " .. table.concat(h.nama_gagal, ", "))
                        notify("ZenX "..cfg.tim, "GAGAL "..h.gagal.." client — cek Termux")
                    else
                        ok("Kelar: " .. ringkas)
                        notify("ZenX "..cfg.tim, isi.." -> "..h.ok.." client jalan")
                    end
                else
                    info("'"..isi.."' -> semua client udah jalan")
                end
                lastOpen = os.time()
                lastStatus = 0   -- paksa lapor abis buka
            else
                -- v4.10: status ditampilin lewat tabel, gak print baris ini lagi
            end
        else
            -- v4.10: status standby ditampilin lewat tabel
        end

        if (now - lastStatus) >= cfg.status_sec then
            local jalan, total = lapor(cfg, isi, cacheRun)
            notify("ZenX "..cfg.tim, jalan.."/"..total.." client jalan"..(hit and " · FORCE" or ""))
            lastStatus = now
        end


        -- ============================================================
        -- v5.29: SCRIPT PER TIM DARI PANEL.
        -- Panel nentuin tim ini jalanin script apa; URL-nya nebeng di /perintah
        -- (yang emang udah di-poll), jadi gak nambah request.
        -- Ganti script = tulis ulang autoexec + REJOIN. Rejoin-nya WAJIB:
        -- Delta cuma baca folder Autoexecute pas aplikasi masuk game, jadi
        -- client yang lagi jalan bakal tetep pakai script lama sampai join ulang.
        -- ============================================================
        do
            local scrUrl   = ambil_str(resp, "scriptUrl") or ""
            local scrNama  = ambil_str(resp, "scriptNama") or ""
            local scrGanti = tonumber((resp or ""):match('"scriptGanti"%s*:%s*(%d+)')) or 0
            if scrUrl ~= "" and scrGanti > 0 and scrGanti ~= SCRIPT_KERJAKAN then
                if scrUrl ~= SCRIPT_URL_AKHIR then
                    tambahLog("PANEL: script diganti -> " .. (scrNama ~= "" and scrNama or scrUrl))
                    if tulis_autoexec(cfg, scrUrl) then
                        SCRIPT_URL_AKHIR = scrUrl
                        -- Client yang lagi jalan masih megang script LAMA -- Delta
                        -- cuma baca Autoexecute pas masuk game. Jadi ditutup;
                        -- yang buka lagi biar blok FORCE di bawah (kalau STANDBY,
                        -- ya emang sengaja gak dibuka).
                        tambahLog("Tutup semua client -- script baru kepakai pas join ulang")
                        close_all(cfg, nil, mapLink)
                    else
                        tambahLog("! gagal nulis autoexec buat script baru")
                    end
                end
                SCRIPT_KERJAKAN = scrGanti
            end
        end

        -- v4.9: AUTO-REJOIN per client. cek tiap akun (dari mapping client<->akun)
        -- apakah masih lapor ke panel. akun yg keluar game -> script off -> berhenti
        -- lapor. kalau > auto_rejoin_menit -> rejoin client itu doang (bukan semua).
        -- cuma jalan kalau auto_rejoin nyala (FORCE aktif, gak STANDBY).
        -- v4.51: kalau panel BARU AJA mindahin/mulangin akun, jangan nunggu
        -- giliran 60 detik -- langsung masuk blok ini dan kerjain.
        local psGantiPeek = tonumber((resp or ""):match('"psGanti"%s*:%s*(%d+)')) or 0
        local adaTitahBaru = (psGantiPeek > 0 and psGantiPeek ~= psGantiKerjakan)
        if cfg.auto_rejoin ~= false and hit and ((now - lastAutoRejoin) >= 60 or adaTitahBaru) then
            lastAutoRejoin = now
            -- refresh mapping tiap 10 menit (akun bisa ganti kalau setup ulang client)
            if (now - lastMapRefresh) >= 600 then refresh_map(); lastMapRefresh = now end
            if (now - lastAssign) >= 600 then auto_assign_tim(); lastAssign = now end
            -- v4.51: keputusan panel LANGSUNG dikerjain. psGanti dibaca dari
            -- /perintah yang emang udah di-poll tiap beberapa detik -- jadi begitu
            -- panel mindahin/mulangin akun, worker nyusul dalam hitungan detik,
            -- gak nunggu giliran 60 detik.
            local psBaruDariPanel = adaTitahBaru
            if psBaruDariPanel then
                psGantiKerjakan = psGantiPeek
                tambahLog("PANEL: ada perubahan server -> langsung dikerjain")
            end
            if psBaruDariPanel or (now - lastPsRefresh) >= 60 then
                -- v4.23: PS pindah? -> rejoin client itu doang, biar masuk PS baru.
                local psLama = {}
                for k, v in pairs(mapPsNama) do psLama[k] = v end
                refresh_ps()
                lastPsRefresh = now
                -- v4.61: KUMPULIN dulu semua yang pindah, TUTUP BARENGAN, baru
                -- buka satu-satu. Dulu tiap client ditutup+dibuka sendiri-sendiri
                -- -> 3 client bisa makan semenit lebih cuma buat nutup.
                local pindahPkg = {}
                for _, pkg in ipairs(split(cfg.pkgs)) do
                    local baru = mapPsNama[pkg] or ""
                    local lama = psLama[pkg]
                    -- lama == nil = baru pertama kali kebaca (jangan rejoin, itu bukan pindah)
                    if lama ~= nil and baru ~= lama then
                        tambahLog(string.format("PINDAH SERVER: %s  %s -> %s",
                            (mapAkun[pkg] or pkg:gsub("com%.roblox%.","")),
                            (lama ~= "" and lama or "public"),
                            (baru ~= "" and baru or "public")))
                        pindahPkg[#pindahPkg+1] = pkg
                    end
                end
                if #pindahPkg > 0 then
                    close_all(cfg, pindahPkg, mapLink)   -- SEKALI JALAN buat semuanya
                    os.execute("sleep 2")
                    for i, pkg in ipairs(pindahPkg) do
                        open_one(cfg, pkg, mapLink[pkg])
                        tambahLog("   -> " .. (mapAkun[pkg] or pkg:gsub("com%.roblox%.",""))
                                  .. " dibuka lagi di " .. ((mapPsNama[pkg] or "") ~= "" and mapPsNama[pkg] or "public"))
                        -- jeda cuma ANTAR buka (biar RAM gak kaget), bukan tiap tutup
                        if i < #pindahPkg then os.execute("sleep " .. (cfg.stagger_sec or 15)) end
                    end
                end
            end
            -- ambil semua status akun dari panel sekali
            local stat = api_get(cfg, "/stat")
            local ambang = (tonumber(cfg.auto_rejoin_menit) or 8) * 60
            -- v4.38: ambang CEPAT khusus buat ngintip dialog error (disconnect).
            -- Nungguin 8 menit kelamaan kalau cuma kena "Error Code 277".
            local ambangDc = (tonumber(cfg.disconnect_menit) or 3) * 60
            -- v4.86: cek lisensi SEKALI per ronde (berkasnya dipakai bareng semua
            -- client, jadi gak usah dicek per client). Kalau hilang/basi, client
            -- yang diem JANGAN dibunuh -- yang kurang itu kunci, bukan restart.
            local licKead, licUmur = lisensi_keadaan(cfg)
            -- v5.01: cuma "hilang" yang bikin worker berhenti nyentuh client.
            -- "basi" (lewat umur) TIDAK -- karena Delta cuma meriksa kunci pas
            -- aplikasi MULAI. Client yang udah jalan tetep aman walau lisensinya
            -- udah 28 jam, selama dia gak keluar. Kalau umur doang dipakai buat
            -- berhenti ngurus, client yang cuma putus koneksi biasa jadi gak
            -- pernah di-rejoin -- farm macet gara-gara umur berkas.
            local butuhKey = (licKead == "hilang")
            local licTua   = (licKead == "basi")
            if butuhKey and (os.time() - (LAPOR_KEY_AT or 0)) > 600 then
                LAPOR_KEY_AT = os.time()
                if cfg.auto_key == true then
                    tambahLog("BUTUH KEY: lisensi Delta HILANG -- worker bakal nyari sendiri")
                else
                    tambahLog("BUTUH KEY: lisensi Delta HILANG -- tap tombolnya manual (2x), terus: zenx key")
                end
            end
            for _, pkg in ipairs(split(cfg.pkgs)) do
                local akun = mapAkun[pkg]
                if akun then
                    -- cari "ts" akun ini di /stat. format: ..."nama":"fifinx_5"...,"ts":123...
                    local blok = stat:match('{[^{}]-"nama"%s*:%s*"' .. akun .. '"[^{}]-}')
                    local ts = blok and tonumber(blok:match('"ts"%s*:%s*(%d+)')) or nil
                    local skrgSrv = ambil_num(stat, "skrg") or now   -- v4.53: dulu selalu nil -> pakai jam LOKAL

                    -- v5.04: BERAPA LAMA DIEM. Dulu semua tindakan digantung ke 'ts'
                    -- (kapan terakhir lapor). Masalahnya client yang nyangkut di Home
                    -- BELUM PERNAH lapor sama sekali -> ts kosong -> SELURUH blok ini
                    -- dilewat -> worker diem selamanya. Itu persis keluhan "kalau udah
                    -- nyangkut, gak ngapa-ngapain lagi".
                    -- Sekarang: kalau belum pernah lapor, umur diemnya dihitung dari
                    -- kapan worker PERTAMA liat dia idup tapi bisu.
                    local diem
                    if ts then
                        diem = skrgSrv - ts
                        PERTAMA_DIEM[pkg] = nil
                    elseif cacheRun[pkg] then
                        PERTAMA_DIEM[pkg] = PERTAMA_DIEM[pkg] or now
                        diem = now - PERTAMA_DIEM[pkg]
                    end

                    if diem and butuhKey then
                        -- v4.86: lisensi hilang/basi -> script emang GAK BAKAL jalan
                        -- sampai kunci masuk. Dibunuh/dibuka ulang cuma muter-muter
                        -- sambil ngabisin RAM. Diemin aja, nunggu `zenx key`.
                        nudgeCnt[pkg] = nil
                    -- v5.05: client yang BELUM PERNAH lapor itu PASTI nyangkut
                    -- (Home / layar key) -- gak mungkin sehat. Jadi ambangnya
                    -- pendek: 60 detik. Client yang PERNAH lapor tetep pakai
                    -- ambang lama, soalnya normalnya dia emang cuma lapor tiap
                    -- ~120 detik -- kalau ikut 60 detik, client SEHAT bakal
                    -- ditembakin terus percuma.
                    elseif diem and diem > (ts and math.min(ambangDc, ambang)
                                                or (tonumber(cfg.home_detik) or 60)) then
                        -- v4.21: bridge diem > ambang. TAPI cek dulu client masih di
                        -- game apa nggak (pkg_running). Android suka BEKUIN Roblox bg
                        -- (proses idup, script beku, gak lapor) -> keliatan "off"
                        -- padahal masih di server. jangan asal kill.
                        if pkg_running(pkg) then
                            -- v4.38: sebelum nebak-nebak, INTIP layarnya dulu. Kalau
                            -- ada dialog error Roblox (Disconnected / Error 277), itu
                            -- BUKAN beku -- dibangunin gak bakal nolong. Harus dibunuh
                            -- terus dibuka ulang biar join dari awal.
                            local errUi, errSifat = cek_error_ui(cfg, pkg, mapLink)
                            if errUi and errSifat == "manual" then
                                -- percuma diulang (layar KEY, link PS salah, di-kick
                                -- script, place dibatesin). Diulang cuma muter-muter ->
                                -- catet aja, biar keliatan di panel & dibenerin manual.
                                tambahLog(string.format("PERLU DICEK: %s kena '%s' -- masuk ulang gak bakal nolong", akun, errUi))
                                nudgeCnt[pkg] = nil
                                errUi = nil   -- jangan diapa-apain lagi ronde ini
                            elseif errUi and errSifat == "tunggu" then
                                -- lagi dibatesin (kebanyakan nyoba / server ngadat).
                                -- Buru-buru masuk ulang malah makin diblok -> tutup
                                -- aja, biarin adem; ronde berikutnya baru dibuka.
                                tambahLog(string.format("DIBATESIN: %s kena '%s' -> ditutup dulu, adem ~1 menit", akun, errUi))
                                close_all(cfg, pkg, mapLink)
                                nudgeCnt[pkg] = nil
                                errUi = nil
                            elseif errUi and errSifat == "home" then
                                -- v5.04: nyangkut di Home -> LANGSUNG TEMBAK LINK PS,
                                -- JANGAN dibunuh dulu. Di layar Home, Roblox BELUM di
                                -- dalam game, jadi 'am start -d <link>' beneran jalan --
                                -- ini kebukti gak sengaja waktu kalibrasi tap: client
                                -- yang lagi di layar key kena link, terus beneran join.
                                -- (Beda sama client yang UDAH di dalam game: di situ
                                -- link jadi no-op, makanya dulu mesti ditutup dulu.)
                                -- Dicoba sampai 4x -- murah, gak destruktif, gak
                                -- ngilangin progress. Bunuh cuma pilihan terakhir.
                                -- v5.05: nyangkut di Home -> REJOIN TERUS, GAK PERNAH DIBUNUH.
                                -- Nembak link itu murah & gak ngilangin apa-apa; kalau
                                -- 10x pun belum masuk, dibunuh juga gak bakal nolong
                                -- (kasus layar key ditangani jalur bypass sendiri).
                                nudgeCnt[pkg] = (nudgeCnt[pkg] or 0) + 1
                                tambahLog(string.format("HOME: %s %s -> rejoin ke PS (percobaan %d), GAK dibunuh",
                                    akun, errUi, nudgeCnt[pkg]))
                                open_one(cfg, pkg, mapLink[pkg])
                                os.execute("sleep 5")   -- kasih waktu join
                                errUi = nil             -- jangan jatuh ke blok bunuh
                            end
                            if errUi then
                                -- v4.83: kill DIJATAH. Kalau client ini udah dibunuh
                                -- berkali-kali dalam waktu dekat, berarti restart bukan
                                -- obatnya -- berhenti, catet, biar diurus manual.
                                if sisa_jatah_kill(pkg) <= 0 then
                                    tambahLog(string.format("PERLU DICEK: %s kena '%s' -- udah dibunuh %dx/30menit, DISTOP dulu",
                                        akun, errUi, KILL_MAKS))
                                    nudgeCnt[pkg] = nil
                                else
                                catat_kill(pkg)
                                tambahLog(string.format("DISCONNECT: %s kena '%s' -> tutup & masuk ulang", akun, errUi))
                                close_all(cfg, pkg, mapLink)
                                os.execute("sleep 2")
                                open_one(cfg, pkg, mapLink[pkg])
                                notify("ZenX "..cfg.tim, akun .. " " .. errUi .. " -> masuk ulang")
                                nudgeCnt[pkg] = nil
                                os.execute("sleep " .. (cfg.stagger_sec or 10))
                                end
                            elseif diem > ambang then
                            -- gak ada dialog error, dan udah lewat ambang penuh
                            nudgeCnt[pkg] = (nudgeCnt[pkg] or 0) + 1
                            if nudgeCnt[pkg] <= 4 then
                                -- v5.04: dari 2x jadi 4x. 'am start -d <link>' itu murah
                                -- dan gak destruktif: kalau client UDAH di dalam game,
                                -- link-nya diabaikan (cuma jendelanya naik ke depan);
                                -- kalau BELUM (nyangkut Home/key), link-nya beneran
                                -- jalan dan dia join. Dua-duanya gak ngilangin apa-apa,
                                -- jadi gak ada alasan buru-buru bunuh.
                                tambahLog(string.format("DIEM: %s %dm gak lapor -> tembak link PS (%d/4), gak dibunuh",
                                    akun, math.floor(diem/60), nudgeCnt[pkg]))
                                open_one(cfg, pkg, mapLink[pkg])
                                os.execute("sleep 5")
                            else
                                -- udah dibangunin 2x masih diem -> script beneran mati -> rejoin penuh
                                -- v4.85: ikut kena JATAH. Sejak layar gak bisa dibaca lagi,
                                -- jalur inilah yang paling sering kepakai -- kalau gak dijatah,
                                -- client bermasalah balik dibunuh tiap ronde kayak dulu.
                                if sisa_jatah_kill(pkg) <= 0 then
                                    tambahLog(string.format("PERLU DICEK: %s diem terus -- udah di-rejoin %dx/30menit, DISTOP dulu",
                                        akun, KILL_MAKS))
                                    nudgeCnt[pkg] = nil
                                else
                                catat_kill(pkg)
                                -- v5.01: lisensi tua + client gak mau idup lagi = curiga
                                -- nyangkut di layar key. Delta baru minta kunci pas
                                -- MULAI, jadi curiganya baru masuk akal DI SINI --
                                -- pas client-nya emang lagi dibuka ulang.
                                if licTua then
                                    tambahLog(("   (lisensi Delta umur %s -- kalau abis ini tetep diem, kemungkinan nyangkut di layar key: jalanin `zenx cari %s`)")
                                        :format(umur_ringkas(licUmur), pkg:gsub("com%%.roblox%%.", "")))
                                end
                                tambahLog(string.format("AUTO-REJOIN: %s dibangunin 2x masih diem -> rejoin penuh", akun))
                                close_all(cfg, pkg, mapLink)
                                os.execute("sleep 2")
                                open_one(cfg, pkg, mapLink[pkg])
                                notify("ZenX "..cfg.tim, "auto-rejoin "..akun.." (nudge gagal)")
                                nudgeCnt[pkg] = nil
                                os.execute("sleep " .. (cfg.stagger_sec or 10))
                                end
                            end
                            end   -- v4.38: tutup cabang "gak ada dialog error"
                        elseif diem > ambang then
                            -- beneran keluar game (proses gak di layar game) -> rejoin penuh
                            tambahLog(string.format("AUTO-REJOIN: %s off %dm -> rejoin",
                                akun, math.floor(diem/60)))
                            close_all(cfg, pkg, mapLink)  -- tutup client ini doang
                            os.execute("sleep 2")
                            open_one(cfg, pkg, mapLink[pkg])   -- buka lagi ke PS-nya
                            notify("ZenX "..cfg.tim, "auto-rejoin "..akun.." (keluar game)")
                            nudgeCnt[pkg] = nil
                            os.execute("sleep " .. (cfg.stagger_sec or 10))  -- jeda sebelum cek berikutnya
                        end
                    elseif ts then
                        nudgeCnt[pkg] = nil   -- v4.21: client lapor sehat -> reset counter nudge
                        PERTAMA_DIEM[pkg] = nil
                    end
                end
            end
        end

        -- v4.54: SUPLAI punya jadwal SENDIRI, lepas dari gerbang auto-rejoin.
        -- Dulu nebeng di situ -> keputusan "akun ini udah cukup, pulang" baru
        -- DIBIKIN tiap 60 detik, terus nunggu giliran lagi buat dikerjain.
        -- Sekarang dicek tiap suplai_sec (bawaan 20 detik).
        if cfg.suplai_master == true and hit
           and (now - lastSuplaiCek) >= (cfg.suplai_sec or 20) then
            lastSuplaiCek = now
            local rs = api_get(cfg, "/suplai-cek")
            local nb  = ambil_num(rs, "nBerangkat") or 0
            local np  = ambil_num(rs, "nPulang") or 0
            local npd = ambil_num(rs, "nPindah") or 0
            if nb > 0 then tambahLog("SUPLAI: " .. nb .. " akun market dikumpulin ke PS leveling") end
            if np > 0 then tambahLog("SUPLAI: " .. np .. " akun market dipulangin (stok cukup)") end
            if npd > 0 then tambahLog("SUPLAI: " .. npd .. " akun market pindah gudang (leveling abis)") end
        end

        -- v4.52: jaga jendela tetep nongol. Delta nguncup -> Roblox disconnect
        -- ~15 detik kemudian, jadi jedanya mesti di bawah itu.
        if cfg.jaga_depan_sec and cfg.jaga_depan_sec > 0 and hit
           and (now - lastJagaDepan) >= cfg.jaga_depan_sec then
            lastJagaDepan = now
            jaga_depan(cfg, mapLink, cacheRun)   -- v4.63: pakai cache, gak dumpsys ulang
        end

        end  -- v5.02: tutup 'if not lewatiRonde' (ronde bypass gak ngerjain sisanya)

        -- v4.18: keep-alive re-apply tiap 60 detik (Android suka reset oom_score_adj)
        if cfg.keep_alive ~= false and (now - lastKeepAlive) >= 60 then
            lastKeepAlive = now
            keep_alive_apply(cfg)
        end

        end  -- if not skip_sisa

        os.execute("sleep "..cfg.poll_sec)
    end
end

-- ============================================================
-- v4.2: subperintah
--   lua5.4 zenx_worker.lua          -> jalan
--   lua5.4 zenx_worker.lua stop     -> berhenti baik-baik
--   lua5.4 zenx_worker.lua status   -> jalan apa nggak
--   v4.78: key [link|refresh]       -> bypass key Delta lewat api.bypass.vip
--   v4.79: key set <APIKEY>         -> isi kunci API ke config (tanpa setup ulang)
-- ============================================================
local PERINTAH = (arg and arg[1] or ""):lower()

-- v4.78: `zenx key` -- salin link key-system Delta, terus jalanin ini.
--   zenx key                -> ambil link dari clipboard (termux-clipboard-get)
--   zenx key <link>         -> pakai link yang diketik
--   zenx key refresh        -> link dari clipboard, tapi paksa proses ulang
--   zenx key refresh <link> -> link diketik + paksa proses ulang
-- refresh JANGAN dipakai sembarangan -- itu ngelewatin hasil simpanan, buat
-- link yang emang sering ganti doang.
-- v4.84: `zenx intip <client> [jeda]` -- potret teks di layar client, buat
-- nyocokin penanda (layar key / Home / error) ke tampilan ASLI, bukan tebakan.
--   zenx intip              -> daftar client
--   zenx intip clienu       -> potret sekarang (jeda bawaan 5 detik)
--   zenx intip clienu 20    -> nunggu 20 detik dulu, baru dipotret
-- Jeda itu buat ngasih waktu lo mindahin layar ke keadaan yang mau direkam.
-- v4.87: `zenx lisensi` -- liat keadaan kunci Delta + apa yang bakal worker
-- lakuin. Aman, cuma baca. Dipakai buat mastiin deteksinya bener tanpa harus
-- nunggu kuncinya beneran kedaluwarsa.
-- v4.88: `zenx tap <client> <x> <y> [kali]` -- kalibrasi letak tombol.
-- x & y itu PECAHAN 0..1 dari kotak jendela (0.5 0.5 = tengah). Dipakai buat
-- nyari letak tombol "Copied link" di layar key Delta: coba, liat kepencet apa
-- nggak, geser angkanya, ulangi. Begitu ketemu, simpen di config:
--   key_tap="0.5,0.62"
-- Angka pecahan kepakai di SEMUA client -- petaknya beda-beda, ukurannya sama.
-- v4.90: `zenx rekam <client> [detik]` -- lo yang pencet, worker yang nyatet.
-- Jauh lebih akurat daripada nebak-geser angka.
-- v4.97: `zenx pantau <client> [detik]` -- TIAP kali lo pencet, koordinatnya
-- langsung nongol. Gak ada balapan sama waktu kayak `zenx rekam`: pencet
-- sesukanya, liat angkanya, pilih sendiri yang bener.
-- v5.00: `zenx cari <client>` -- worker nyari sendiri tombol key-nya, sampai
-- papan klip keisi link. Ketemu -> diinget buat ukuran jendela itu -> langsung
-- diproses jadi kunci Delta sekalian.
-- v5.11: `zenx uji <client>` -- tembak beberapa titik menyebar sekaligus, buat
-- mastiin pencetannya NYAMPE ke client apa nggak. Gak butuh tau letak tombol:
-- kalau nyampe, PASTI ada yang bereaksi (papan ketik muncul / tombol nyala /
-- dialog ketutup / browser kebuka). Kalau nol reaksi dari semua titik, berarti
-- jalur pencetannya yang bermasalah -- dan nyapu 20 titik cuma buang waktu.
-- v5.15: `zenx catat <client> <jumlah> [detik]` -- SATU perintah buat kalibrasi
-- manual: jendela diset ke ukuran N client, client dibuka ulang, terus LO yang
-- nunjukin tombolnya (tap beberapa kali). Rata-ratanya disimpen otomatis.
-- Bedanya sama `zenx ukur`: itu worker yang nyapu nebak-nebak; ini lo yang
-- nunjukin -- jauh lebih cepet dan pasti.
-- v5.18: `zenx set <client> <jumlah> [slot]` -- CUMA atur ukuran jendela ke
-- petak N client, terus buka ulang. Gak nyapu, gak minta tap.
-- Gunanya buat NGUJI: set ukuran lain, terus tembak pakai pecahan yang udah
-- ada (`zenx tap`). Kalau kena juga, berarti satu angka cukup buat semua ukuran.
if PERINTAH == "set" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end
    local target = arg and arg[2] or ""
    local jumlah = math.floor(tonumber(arg and arg[3] or "") or 0)
    local slot   = math.floor(tonumber(arg and arg[4] or "") or 1)
    if target == "" or jumlah < 1 then
        err("Cara pakai:  zenx set <client> <jumlah-client> [slot]")
        info("   contoh:  zenx set clienu 2    -> jendela jadi ukuran kalau 2 client")
        return
    end
    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config."); info("Yang ada: " .. cfg.pkgs); return
    end

    local petak, kol, bar, W, H = petak_untuk(jumlah, slot)
    if not petak then err("Gagal: " .. tostring(kol)); return end

    print(C.BOLD..C.C.."\n=== SET UKURAN buat " .. jumlah .. " CLIENT ==="..C.N)
    info(("Layar %dx%d, susunan %dx%d"):format(W, H, kol, bar))

    info(("Petak %d: [%d,%d]-[%d,%d]  ->  %dx%d"):format(
        slot, petak.L, petak.T, petak.R, petak.B, petak.R - petak.L, petak.B - petak.T))

    close_all(cfg, pkg, nil, true)
    os.execute("sleep 2")
    local tok, tket = tata_satu(pkg, petak)
    if not tok then err("Gagal nulis posisi: " .. tostring(tket)); return end
    ok("Posisi ketulis: " .. tket)
    open_one(cfg, pkg, nil)
    for sisa = 40, 1, -1 do
        io.write(("\r   nunggu client nyala... %2ds"):format(sisa))
        io.flush(); os.execute("sleep 1")
    end
    io.write("\r" .. string.rep(" ", 45) .. "\r"); io.flush()

    local nyata = jendela_kotak(pkg)
    if nyata then
        ok(("Jendela sekarang: [%d,%d]-[%d,%d]  %dx%d"):format(
            nyata.L, nyata.T, nyata.R, nyata.B, nyata.R - nyata.L, nyata.B - nyata.T))
        local simpan = tap_muat()[("%dx%d"):format(nyata.R - nyata.L, nyata.B - nyata.T)]
        if simpan then
            info(("Ukuran ini UDAH kecatat: %.3f , %.3f"):format(simpan.fx, simpan.fy))
        else
            info("Ukuran ini BELUM kecatat.")
        end
    end
    print()
    info("Uji pakai pecahan dari ukuran lain:")
    info("   zenx tap " .. target .. " 0.823 0.723 2 5")
    info("Terus cek papan klipnya:  zenx key")
    print()
    return
end

if PERINTAH == "catat" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end
    local target = arg and arg[2] or ""
    local jumlah = math.floor(tonumber(arg and arg[3] or "") or 0)
    local detik  = math.floor(tonumber(arg and arg[4] or "") or 90)
    if target == "" or jumlah < 1 then
        err("Cara pakai:  zenx catat <client> <jumlah-client> [detik]")
        info("   contoh:  zenx catat clienu 10")
        info("            zenx catat clienu 4 120")
        return
    end
    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config."); info("Yang ada: " .. cfg.pkgs); return
    end

    local petak, kol, bar, W, H = petak_untuk(jumlah, 1)
    if not petak then err("Gagal: " .. tostring(kol)); return end

    print(C.BOLD..C.C.."\n=== CATAT TOMBOL buat " .. jumlah .. " CLIENT ==="..C.N)
    info(("Layar %dx%d, susunan %dx%d -> petak %dx%d"):format(
        W, H, kol, bar, petak.R - petak.L, petak.B - petak.T))
    if bar >= 3 then
        info("Jendelanya pendek -- kalau susah nge-tap tangan, pakai sapuan otomatis:")
        info("   zenx set " .. target .. " " .. jumlah .. "   lalu   zenx cari " .. target)
    end

    info("Tutup client, tulis ukuran, buka lagi...")
    close_all(cfg, pkg, nil, true)
    os.execute("sleep 2")
    local tok, tket = tata_satu(pkg, petak)
    if not tok then err("Gagal nulis posisi: " .. tostring(tket)); return end
    open_one(cfg, pkg, nil)
    for sisa = 40, 1, -1 do
        io.write(("\r   nunggu client nyala & layar key nongol... %2ds"):format(sisa))
        io.flush(); os.execute("sleep 1")
    end
    io.write("\r" .. string.rep(" ", 60) .. "\r"); io.flush()

    local kotak, sebabK = jendela_kotak(pkg)
    if not kotak then err("Gagal baca kotak jendela: " .. tostring(sebabK)); return end
    local lebar, tinggi = kotak.R - kotak.L, kotak.B - kotak.T
    local kunci = ("%dx%d"):format(lebar, tinggi)
    ok(("Jendela: [%d,%d]-[%d,%d]  %s"):format(kotak.L, kotak.T, kotak.R, kotak.B, kunci))

    local maxX = (select(1, layar_fisik()) > 0) and select(1, layar_fisik()) or W
    local maxY = (select(2, layar_fisik()) > 0) and select(2, layar_fisik()) or H

    local berkas = "/sdcard/zenx_catat.txt"
    sh_silent("su -c 'rm -f " .. berkas .. "'")
    os.execute("su -c 'timeout " .. (detik + 20) .. " getevent -l > " .. berkas .. "' >/dev/null 2>&1 &")

    print()
    print(C.BOLD..C.Y.."   TAP TOMBOL 'Copied link' -- 3-5 kali"..C.N)
    print(C.D.."   jangan geser/ubah ukuran jendela sampai selesai."..C.N)
    print()

    -- v5.16: gak usah tap tengah dulu. Arah layar ditentuin dari TAP LO SENDIRI:
    -- dari dua arah yang mungkin (panel tegak, layar rebah), cuma satu yang bakal
    -- jatuh DI DALAM jendela. Jendelanya kecil dibanding layar, jadi hampir
    -- mustahil dua-duanya cocok -- dan kalau kebetulan cocok dua-duanya, tap itu
    -- dilewat aja, nunggu tap berikutnya yang jelas.
    local arahKunci, sudah, mulai = nil, 0, os.time()
    local kumpul = {}
    while (os.time() - mulai) < detik do
        if ada_stop() then break end
        os.execute("sleep 2")
        local isi = sh("su -c 'cat " .. berkas .. " 2>/dev/null'") or ""
        local xs, ys = {}, {}
        for n in isi:gmatch("ABS_MT_POSITION_X%s+(%x+)") do xs[#xs+1] = tonumber(n, 16) end
        for n in isi:gmatch("ABS_MT_POSITION_Y%s+(%x+)") do ys[#ys+1] = tonumber(n, 16) end
        local ada = math.min(#xs, #ys)
        for i = sudah + 1, ada do
            if not arahKunci then
                -- arah mana yang bikin tap ini jatuh di dalam jendela?
                local cocok = {}
                for _, c in ipairs(arah_calon(maxX, maxY, W, H)) do
                    local t = sentuh_ke_pecahan(xs[i], ys[i], maxX, maxY, W, H, kotak, c)
                    if t and t.didalam then cocok[#cocok+1] = { c = c, t = t } end
                end
                if #cocok == 1 then
                    arahKunci = cocok[1].c
                    ok("Arah layar terkunci: " .. arahKunci.nama)
                    kumpul[#kumpul+1] = { fx = cocok[1].t.fx, fy = cocok[1].t.fy }
                    print(("  %s#1  layar(%4d,%4d)  ->  %.3f , %.3f%s"):format(
                        C.G, cocok[1].t.X, cocok[1].t.Y, cocok[1].t.fx, cocok[1].t.fy, C.N))
                elseif #cocok > 1 then
                    -- dua-duanya cocok -> putusin lewat setelan putaran layar
                    local c, rot = arah_dari_rotasi(maxX, maxY, W, H)
                    if c then
                        arahKunci = c
                        ok(("Arah layar terkunci: %s (dari setelan putaran = %d)"):format(c.nama, rot or -1))
                        local t = sentuh_ke_pecahan(xs[i], ys[i], maxX, maxY, W, H, kotak, c)
                        if t and t.didalam then
                            kumpul[#kumpul+1] = { fx = t.fx, fy = t.fy }
                            print(("  %s#1  layar(%4d,%4d)  ->  %.3f , %.3f%s"):format(
                                C.G, t.X, t.Y, t.fx, t.fy, C.N))
                        end
                    else
                        print(C.D.."  --  arahnya ambigu, tap sekali lagi"..C.N)
                    end
                else
                    print(C.D.."  --  di LUAR jendela (abaikan)"..C.N)
                end
            else
                local t = sentuh_ke_pecahan(xs[i], ys[i], maxX, maxY, W, H, kotak, arahKunci)
                if t and t.didalam then
                    kumpul[#kumpul+1] = { fx = t.fx, fy = t.fy }
                    print(("  %s#%d  layar(%4d,%4d)  ->  %.3f , %.3f%s")
                        :format(C.G, #kumpul, t.X, t.Y, t.fx, t.fy, C.N))
                elseif t then
                    print(("  %s--  di LUAR jendela (abaikan)%s"):format(C.D, C.N))
                end
            end
        end
        sudah = ada
    end
    sh_silent("su -c 'rm -f " .. berkas .. "'")
    sh_silent("su -c 'pkill -9 getevent'")

    print()
    if #kumpul == 0 then
        err("Gak ada tap yang kecatat di dalam jendela.")
        info("Pastiin tap-nya di dalam jendela client, terus ulangi.")
        return
    end

    -- v5.19: JANGAN pakai rata-rata polos. Satu tap nyasar langsung narik
    -- hasilnya, dan rata-ratanya bisa jatuh di ANTARA dua elemen -- bukan di
    -- tombolnya. Gantinya: cari KELOMPOK TAP PALING RAPAT (yang Y-nya
    -- berdekatan), sisanya dibuang. Tombolnya panjang, jadi yang dipakai
    -- ngelompokin cuma Y; X-nya boleh nyebar.
    local RAPAT = 0.04   -- beda Y masih dianggap tombol yang sama
    local juara = {}
    for _, pusat in ipairs(kumpul) do
        local anggota = {}
        for _, k in ipairs(kumpul) do
            if math.abs(k.fy - pusat.fy) <= RAPAT then anggota[#anggota+1] = k end
        end
        if #anggota > #juara then juara = anggota end
    end

    local function ringkas(t)
        local sx, sy, minx, maxx, miny, maxy = 0, 0, 9, -9, 9, -9
        for _, k in ipairs(t) do
            sx = sx + k.fx; sy = sy + k.fy
            if k.fx < minx then minx = k.fx end
            if k.fx > maxx then maxx = k.fx end
            if k.fy < miny then miny = k.fy end
            if k.fy > maxy then maxy = k.fy end
        end
        return sx / #t, sy / #t, minx, maxx, miny, maxy
    end

    local _, _, amx, aax, amy, aay = ringkas(kumpul)
    info(("%d tap kecatat -- sebaran semua: x %.3f-%.3f | y %.3f-%.3f"):format(
        #kumpul, amx, aax, amy, aay))

    local rx, ry, kmx, kax, kmy, kay = ringkas(juara)
    if #juara < #kumpul then
        info(("%d tap nyasar dibuang, kepakai %d yang paling rapat"):format(
            #kumpul - #juara, #juara))
    end
    ok(("Hasil: %.3f , %.3f   (dari %d tap, sebaran y %.3f-%.3f)"):format(
        rx, ry, #juara, kmy, kay))

    if #juara < 2 then
        warn("Cuma 1 tap yang kepakai -- tap-tap lo kejauhan satu sama lain.")
        warn("Ulangi, pastiin nge-tap TOMBOL YANG SAMA tiap kali.")
    elseif (kay - kmy) > 0.05 then
        warn("Sebaran Y masih lebar -- hasilnya belum tentu pas di tombol.")
        warn("Uji dulu sebelum dipakai.")
    end

    if tap_simpan(kunci, rx, ry) then
        ok(("Kesimpen: %s -> %.3f , %.3f  (di %s)"):format(kunci, rx, ry, TAP_FILE))
    else
        err("Gagal nyimpen ke " .. TAP_FILE)
    end
    print()
    info("Uji balik:  zenx tap " .. target .. (" %.3f %.3f 2 5"):format(rx, ry))
    info("Ukuran lain:  zenx catat " .. target .. " 6")
    info("Liat semua:  cat ~/" .. TAP_FILE)
    print()
    return
end

if PERINTAH == "uji" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end
    local target = arg and arg[2] or ""
    if target == "" then
        err("Cara pakai:  zenx uji <client>")
        return
    end
    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config."); info("Yang ada: " .. cfg.pkgs); return
    end

    print(C.BOLD..C.C.."\n=== UJI PENCETAN ==="..C.N)
    local naik, siapa = pastikan_depan(pkg)
    if not naik then
        err("Gagal munculin client ke depan (yang di depan: " .. tostring(siapa) .. ")")
        if BAWA_SEBAB then info("Sebab: " .. BAWA_SEBAB) end
        return
    end
    local kotak, sebab = jendela_kotak(pkg)
    if not kotak then err("Gagal baca kotak jendela: " .. tostring(sebab)); return end
    ok(("Jendela: [%d,%d]-[%d,%d]  (%dx%d)"):format(
        kotak.L, kotak.T, kotak.R, kotak.B, kotak.R - kotak.L, kotak.B - kotak.T))
    print()
    print(C.BOLD..C.Y.."   LIATIN LAYAR CLIENT -- 6 titik ditembak berurutan"..C.N)
    print(C.D.."   Yang gua tanya cuma: ADA perubahan apa pun nggak?"..C.N)
    print()

    -- semua titik dikirim dalam SATU panggilan su -- tiap 'su' di RF ~6 detik,
    -- kalau satu-satu jadi lama banget dan susah diliatin.
    local titik = { {0.5,0.20}, {0.5,0.35}, {0.5,0.50}, {0.5,0.65}, {0.5,0.80}, {0.5,0.92} }
    local bagian = {}
    for _, t in ipairs(titik) do
        local x = math.floor(kotak.L + (kotak.R - kotak.L) * t[1])
        local y = math.floor(kotak.T + (kotak.B - kotak.T) * t[2])
        bagian[#bagian+1] = "input tap " .. x .. " " .. y
        info(("   titik %.2f -> layar (%d, %d)"):format(t[2], x, y))
    end
    sh("su -c '" .. table.concat(bagian, "; sleep 1.2; ") .. " 2>&1'")

    print()
    ok("Selesai -- 6 titik ketembak.")
    info("ADA reaksi (apa pun)  -> pencetan NYAMPE, lanjut:  zenx cari " .. target)
    info("NOL reaksi semua      -> pencetan gak nyampe, kabarin gua")
    print()
    return
end

-- v5.06: `zenx ukur <client> <jumlah> [slot]` -- pakai SATU client buat nyoba
-- ukuran jendela yang nanti kepakai kalau client-nya ada sekian.
-- Jendelanya diset ke ukuran itu, client dibuka ulang, terus tombol key-nya
-- dicari + disimpen. Jadi pas nanti beneran jalan 10 client, ukurannya udah
-- pernah dikenali -- gak usah nyapu lagi.
--   zenx ukur clienu 4     -> ukuran kalau 4 client
--   zenx ukur clienu 10    -> ukuran kalau 10 client
if PERINTAH == "ukur" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end

    local target = arg and arg[2] or ""
    local jumlah = math.floor(tonumber(arg and arg[3] or "") or 0)
    local slot   = math.floor(tonumber(arg and arg[4] or "") or 1)
    if target == "" or jumlah < 1 then
        err("Cara pakai:  zenx ukur <client> <jumlah-client> [slot]")
        info("   contoh:  zenx ukur clienu 4     -> ukuran kalau nanti 4 client")
        info("            zenx ukur clienu 10    -> ukuran kalau nanti 10 client")
        return
    end
    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config.")
        info("Yang ada: " .. cfg.pkgs)
        return
    end

    local kotak, kol, bar, W, H = petak_untuk(jumlah, slot)
    if not kotak then err("Gagal: " .. tostring(kol)); return end
    local lebar, tinggi = kotak.R - kotak.L, kotak.B - kotak.T

    print(C.BOLD..C.C.."\n=== UKUR BUAT " .. jumlah .. " CLIENT ==="..C.N)
    info(("Layar   : %dx%d   susunan %dx%d"):format(W, H, kol, bar))
    info(("Petak %d : [%d,%d]-[%d,%d]  ->  %dx%d"):format(
        slot, kotak.L, kotak.T, kotak.R, kotak.B, lebar, tinggi))
    print()

    -- App Cloner baca posisi jendela pas app MULAI, dan nimpa balik pas app
    -- DITUTUP. Jadi urutannya harga mati: tutup -> tulis -> buka.
    info("Tutup client dulu...")
    close_all(cfg, pkg, nil, true)
    os.execute("sleep 2")

    info("Tulis ukuran jendela ke prefs App Cloner...")
    local tok, tket = tata_satu(pkg, kotak)
    if not tok then
        err("Gagal nulis posisi: " .. tostring(tket))
        info("(prefs baru kebentuk kalau client-nya pernah dibuka sekali)")
        return
    end
    ok("Posisi ketulis: " .. tket)

    info("Buka lagi client-nya...")
    open_one(cfg, pkg, nil)

    -- tungguin dia nyala + nyampe layar key
    local tunggu = 45
    for sisa = tunggu, 1, -1 do
        io.write(("\r   nunggu client nyala & nampilin layar key... %2ds"):format(sisa))
        io.flush()
        os.execute("sleep 1")
    end
    io.write("\r" .. string.rep(" ", 60) .. "\r"); io.flush()

    -- pastiin ukurannya beneran kepakai
    local nyata = jendela_kotak(pkg)
    if nyata then
        local nl, nt = nyata.R - nyata.L, nyata.B - nyata.T
        if math.abs(nl - lebar) > 8 or math.abs(nt - tinggi) > 8 then
            warn(("Jendelanya jadi %dx%d, bukan %dx%d -- App Cloner gak nurut?"):format(
                nl, nt, lebar, tinggi))
            info("Lanjut aja, yang dipakai ukuran NYATA-nya.")
        else
            ok(("Jendela sekarang: [%d,%d]-[%d,%d]  %dx%d  (sesuai)"):format(
                nyata.L, nyata.T, nyata.R, nyata.B, nl, nt))
        end
    end

    print()
    info("Sekarang cari tombol key-nya...")
    local link, fx, fy, ket = cari_tombol_key(cfg, pkg)
    if not link then
        err("Gagal: " .. tostring(ket))
        info("Pastiin client-nya emang lagi minta key (lisensi udah dihapus?).")
        return
    end
    ok(("Ketemu!  %s"):format(ket))
    ok(("Titik tombol: %.3f , %.3f  -- kesimpen di %s"):format(fx, fy, TAP_FILE))
    print()
    info("Ulangi buat ukuran lain:  zenx ukur " .. target .. " 6")
    info("Liat semua yang udah kesimpen:  cat ~/" .. TAP_FILE)
    print()

    -- link-nya sekalian dipakai, sayang kalau kebuang
    info("Sekalian diproses jadi kunci...")
    local kunci, sebab = bypass_kunci(cfg, link, false)
    if kunci then
        ok("KUNCI: " .. kunci)
        local wok, wket = tulis_lisensi(cfg, kunci)
        if wok then ok("Ditulis ke Delta: " .. wket)
        else warn("Gagal nulis lisensi: " .. tostring(wket)) end
    else
        warn("Bypass gagal: " .. tostring(sebab))
    end
    print()
    return
end

if PERINTAH == "cari" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end

    local target = arg and arg[2] or ""
    if target == "" then
        err("Cara pakai:  zenx cari <client>")
        info("   contoh:  zenx cari clienu")
        return
    end
    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config.")
        info("Yang ada: " .. cfg.pkgs)
        return
    end

    print(C.BOLD..C.C.."\n=== CARI TOMBOL KEY ==="..C.N)
    do
        local kead, umur = lisensi_keadaan(cfg)
        info("Lisensi sekarang: " .. kead ..
             (umur and ("  (umur " .. umur_ringkas(umur) .. ")") or ""))
    end
    info("Nyoba beberapa titik, tiap kali diperiksa papan klipnya.")
    info("Bisa makan beberapa menit -- jangan disentuh dulu.")
    print()

    local link, fx, fy, ket = cari_tombol_key(cfg, pkg)
    if not link then
        err("Gagal: " .. tostring(ket))
        info("Kemungkinan: layar key lagi gak nongol, atau tombolnya di luar garis tengah.")
        info("Pastiin client-nya emang lagi minta key, terus coba lagi.")
        return
    end

    ok(("Dapet link!  [%s]"):format(ket))
    ok(("Titik tombol: %.3f , %.3f  -- diinget di %s"):format(fx, fy, TAP_FILE))
    info("Link: " .. link:sub(1, 55) .. "...")
    print()

    info("Proses ke API bypass... (30-60 detik)")
    local kunci, sebab, mentah = bypass_kunci(cfg, link, false)
    if not kunci then
        err("Bypass gagal: " .. tostring(sebab))
        if mentah and mentah:gsub("%s+", "") ~= "" then
            info("Jawaban mentah API:")
            print(C.D .. mentah:sub(1, 400) .. C.N)
        end
        return
    end
    ok("KUNCI: " .. kunci)

    local wok, wket = tulis_lisensi(cfg, kunci)
    if wok then
        ok("Ditulis ke Delta: " .. wket)
        info("Kepakai SEMUA client. Restart client yang minta key:")
        info("   su -c 'am force-stop " .. pkg .. "'")
    else
        warn("Gagal nulis ke Delta: " .. tostring(wket))
    end
    print()
    return
end

if PERINTAH == "pantau" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end

    local target = arg and arg[2] or ""
    local detik = math.floor(tonumber(arg and arg[3] or "") or 120)
    if target == "" then
        err("Cara pakai:  zenx pantau <client> [detik]")
        info("   contoh:  zenx pantau clienu 120")
        return
    end
    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config.")
        info("Yang ada: " .. cfg.pkgs)
        return
    end

    print(C.BOLD..C.C.."\n=== PANTAU SENTUHAN ==="..C.N)
    info("Bawa " .. pkg:gsub("com%.roblox%.","") .. " ke depan (tanpa link join)...")
    bawa_depan(pkg)
    os.execute("sleep 3")

    local kotak, sebabK = jendela_kotak(pkg)
    if not kotak then err("Gagal baca kotak jendela: " .. tostring(sebabK)); return end
    ok(("Jendela: [%d,%d]-[%d,%d]  (%dx%d)"):format(
        kotak.L, kotak.T, kotak.R, kotak.B, kotak.R - kotak.L, kotak.B - kotak.T))

    local W, H = layar_ukuran()
    local fW, fH = layar_fisik()
    local maxX = (fW > 0) and fW or W
    local maxY = (fH > 0) and fH or H

    local berkas = "/sdcard/zenx_pantau.txt"
    sh_silent("su -c 'rm -f " .. berkas .. "'")
    -- getevent jalan di latar, nulis ke berkas. Kita baca berkalanya.
    os.execute("su -c 'timeout " .. detik .. " getevent -l > " .. berkas .. "' >/dev/null 2>&1 &")

    -- v4.98: LANGKAH 1 -- kunci arah putaran pakai patokan.
    local tengahX = (kotak.L + kotak.R) / 2
    local tengahY = (kotak.T + kotak.B) / 2
    print()
    print(C.BOLD..C.Y.."   LANGKAH 1: TAP TEPAT DI TENGAH JENDELA CLIENT"..C.N)
    -- v4.99: dibulatin dulu -- (124+1153)/2 = 638.5, dan %d nolak bilangan pecahan
    print(C.D..("   (kira-kira aja, buat ngunci arah layar. tengahnya di %d,%d)")
        :format(math.floor(tengahX), math.floor(tengahY))..C.N)
    print()

    local arahKunci, sudah, mulai = nil, 0, os.time()
    while (os.time() - mulai) < detik do
        if ada_stop() then info("dihentikan (zenx stop)"); break end   -- v5.14
        os.execute("sleep 2")
        local isi = sh("su -c 'cat " .. berkas .. " 2>/dev/null'") or ""
        local xs, ys = {}, {}
        for n in isi:gmatch("ABS_MT_POSITION_X%s+(%x+)") do xs[#xs+1] = tonumber(n, 16) end
        for n in isi:gmatch("ABS_MT_POSITION_Y%s+(%x+)") do ys[#ys+1] = tonumber(n, 16) end
        local ada = math.min(#xs, #ys)

        for i = sudah + 1, ada do
            if not arahKunci then
                -- sentuhan pertama = patokan
                local pilih, jarak = kunci_arah(xs[i], ys[i], maxX, maxY, W, H, tengahX, tengahY)
                arahKunci = pilih
                ok("Arah layar terkunci: " .. pilih.nama ..
                   ("  (meleset %.0f px dari tengah)"):format(jarak))
                print()
                print(C.BOLD..C.Y.."   LANGKAH 2: SEKARANG TAP TOMBOLNYA -- boleh berkali-kali"..C.N)
                print(C.D.."   JANGAN geser/ubah ukuran jendela sampai selesai."..C.N)
                print()
            else
                local t = sentuh_ke_pecahan(xs[i], ys[i], maxX, maxY, W, H, kotak, arahKunci)
                if t and t.didalam then
                    print(("  %s#%d  layar(%4d,%4d)  ->  PECAHAN %.3f , %.3f%s")
                        :format(C.G, i, t.X, t.Y, t.fx, t.fy, C.N))
                elseif t then
                    print(("  %s#%d  layar(%4d,%4d)  -> di LUAR jendela (abaikan)%s")
                        :format(C.D, i, t.X, t.Y, C.N))
                end
            end
        end
        sudah = ada
    end

    sh_silent("su -c 'rm -f " .. berkas .. "'")
    print()
    if sudah == 0 then
        warn("Gak ada sentuhan kerekam sama sekali.")
    else
        info("Selesai. Ambil PECAHAN dari baris yang pas, terus simpen di config:")
        info('   key_tap="<x>,<y>",')
        info("Uji dulu:  zenx tap " .. target .. " <x> <y> 2 5")
    end
    print()
    return
end

if PERINTAH == "rekam" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end

    local target = arg and arg[2] or ""
    -- v4.91: bawaan 30 detik (dulu 15). Kudu cukup buat baca tulisannya, geser
    -- ke jendela client, terus mencet -- 15 detik kesempitan.
    local detik = math.floor(tonumber(arg and arg[3] or "") or 30)
    if target == "" then
        err("Cara pakai:  zenx rekam <client> [detik]")
        info("   contoh:  zenx rekam clienu 20")
        return
    end
    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config.")
        info("Yang ada: " .. cfg.pkgs)
        return
    end

    print(C.BOLD..C.C.."\n=== REKAM SENTUHAN ==="..C.N)
    info("Bawa " .. pkg:gsub("com%.roblox%.","") .. " ke depan (tanpa link join)...")
    bawa_depan(pkg)
    os.execute("sleep 3")

    local kotak, sebabK = jendela_kotak(pkg)
    if not kotak then err("Gagal baca kotak jendela: " .. tostring(sebabK)); return end
    ok(("Jendela: [%d,%d]-[%d,%d]  (%dx%d)"):format(
        kotak.L, kotak.T, kotak.R, kotak.B, kotak.R - kotak.L, kotak.B - kotak.T))
    print()
    print(C.BOLD..C.Y.."   >>> PENCET TOMBOLNYA SEKARANG <<<"..C.N)
    print(C.D..("   direkam " .. detik .. " detik. Geser ke jendela client, pencet SEKALI.")..C.N)
    print()

    local hasil, sebab = rekam_sentuh(pkg, kotak, detik)
    if not hasil then
        err("Gagal: " .. tostring(sebab))
        info("Coba lagi, pastiin mencetnya di dalam jendela client itu.")
        return
    end

    ok(("Kerekam di layar (%d, %d)  [arah: %s]"):format(hasil.X, hasil.Y, hasil.cara))
    if hasil.total and hasil.total > 1 then
        info(("   dari %d sentuhan, yang kepakai sentuhan ke-%d (yang jatuh di jendela)")
            :format(hasil.total, hasil.keBerapa or 1))
    end
    ok(("PECAHAN-nya: %.3f , %.3f"):format(hasil.fx, hasil.fy))
    print()
    info("Uji balik -- harusnya kepencet tombol yang sama:")
    info(("   zenx tap %s %.3f %.3f 2 5"):format(target, hasil.fx, hasil.fy))
    print()
    info("Kalau bener, simpen di zenx_worker_config.lua:")
    info(('   key_tap="%.3f,%.3f",'):format(hasil.fx, hasil.fy))
    print()
    return
end

if PERINTAH == "tap" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end

    local target = arg and arg[2] or ""
    local fx = tonumber(arg and arg[3] or "")
    local fy = tonumber(arg and arg[4] or "")
    local kali = math.floor(tonumber(arg and arg[5] or "") or 1)
    -- v4.94: jeda sebelum mencet -- biar sempet liat layarnya pas kepencet
    local jeda = math.floor(tonumber(arg and arg[6] or "") or 0)

    if target == "" or not fx or not fy then
        err("Cara pakai:  zenx tap <client> <x> <y> [kali] [jeda-detik]")
        info("   x & y = pecahan 0..1 dari kotak jendela")
        info("   contoh:  zenx tap clienu 0.5 0.62 2 5   (pencet 2x, tunggu 5 detik dulu)")
        info("   (0.5 0.5 = tengah jendela; 0.5 0.62 = tengah, agak ke bawah)")
        return
    end
    if fx < 0 or fx > 1 or fy < 0 or fy > 1 then
        err("x & y harus antara 0 dan 1 (itu PECAHAN, bukan piksel).")
        return
    end

    local pkg = nil
    for _, p in ipairs(split(cfg.pkgs)) do
        if p == target or p:find(target, 1, true) then pkg = p break end
    end
    if not pkg then
        err("Client '" .. target .. "' gak ada di config.")
        info("Yang ada: " .. cfg.pkgs)
        return
    end

    print(C.BOLD..C.C.."\n=== TAP KALIBRASI ==="..C.N)
    info("Bawa " .. pkg:gsub("com%.roblox%.","") .. " ke depan (tanpa link join)...")
    local _, caraDepan = bawa_depan(pkg)
    info("   lewat: " .. tostring(caraDepan))
    os.execute("sleep 3")

    if jeda > 0 then
        for sisa = jeda, 1, -1 do
            io.write(("\r   mencet dalam %2d detik... (liatin layarnya)"):format(sisa))
            io.flush()
            os.execute("sleep 1")
        end
        io.write("\r" .. string.rep(" ", 55) .. "\r"); io.flush()
    end

    local hasil, sebab = tap_jendela(cfg, pkg, fx, fy, kali)
    if not hasil then
        err("Gagal: " .. tostring(sebab))
        return
    end
    local k = hasil.kotak
    ok(("Jendela: [%d,%d]-[%d,%d]  (%dx%d)"):format(
        k.L, k.T, k.R, k.B, k.R - k.L, k.B - k.T))
    ok(("Dipencet %dx di (%d, %d)  = pecahan %.2f, %.2f"):format(kali, hasil.x, hasil.y, fx, fy))
    print()
    info("Kepencet tombolnya? Kalau meleset, geser angkanya:")
    info("   kegedean ke bawah -> kecilin y   |  kurang ke bawah -> gedein y")
    info("   contoh:  zenx tap " .. target .. " " .. fx .. " " .. (fy - 0.05) .. " " .. kali)
    print()
    info("Kalau PAS: cek papan klip udah keisi link key belum, terus simpen di config:")
    info(('   key_tap="%.2f,%.2f"'):format(fx, fy))
    print()
    return
end

if PERINTAH == "lisensi" or PERINTAH == "license" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu."); return end

    local path  = cfg.delta_license or DELTA_LICENSE
    local batas = tonumber(cfg.key_jam) or 24
    local kead, umur = lisensi_keadaan(cfg)

    print(C.BOLD..C.C.."\n=== LISENSI DELTA ==="..C.N)
    info("Berkas : " .. path)
    info("Batas  : " .. batas .. " jam (atur lewat key_jam di config)")

    local isi = (sh("su -c 'cat " .. path .. " 2>/dev/null'") or ""):gsub("%s+$", "")
    if isi ~= "" then
        -- cuma tampilin sebagian -- ini kunci, gak usah kepampang utuh
        info("Kunci  : " .. isi:sub(1, 12) .. "..." .. isi:sub(-4) .. "  (" .. #isi .. " byte)")
    else
        info("Kunci  : (kosong / gak kebaca)")
    end

    if kead == "ada" then
        ok("Keadaan: MASIH BERLAKU" .. (umur and ("  (umur " .. umur_ringkas(umur) .. ")") or ""))
        if umur then
            local sisa = (batas * 3600) - umur
            if sisa > 0 then info("Sisa   : ~" .. umur_ringkas(sisa) .. " lagi sebelum dianggap basi") end
        end
        info("Worker : jalan normal -- client yang diem tetep diurus kayak biasa")
    elseif kead == "hilang" then
        warn("Keadaan: HILANG -- berkasnya gak ada")
        info("Worker : client yang diem GAK disentuh -- restart gak bikin kunci masuk")
        info("Langkah: zenx cari <client>   (worker cari tombolnya sendiri)")
    else
        warn("Keadaan: LEWAT UMUR" .. (umur and ("  (" .. umur_ringkas(umur) .. ")") or ""))
        -- v5.01: ini yang dulu bikin salah paham. Umur lisensi TIDAK bikin client
        -- yang lagi jalan tiba-tiba diminta kunci -- Delta cuma meriksa pas MULAI.
        info("Client yang LAGI JALAN tetep AMAN -- Delta cuma meriksa kunci pas app MULAI.")
        info("Mau 28 jam pun gak apa-apa, selama client-nya gak keluar.")
        info("Yang kena cuma client yang DIBUKA ULANG: dia bakal nyangkut di layar key.")
        info("Worker : tetep ngurus client kayak biasa (rejoin dll)")
        info("Langkah: kalau ada client yang gak mau idup lagi -> zenx cari <client>")
    end
    print()
    return
end

if PERINTAH == "intip" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin `zenx` dulu buat setup."); return end

    local daftar = split(cfg.pkgs)
    local pilih  = arg and arg[2] or ""
    local jeda   = tonumber(arg and arg[3] or "") or 5

    if pilih == "" then
        print(C.BOLD..C.C.."\n=== INTIP LAYAR CLIENT ===\n"..C.N)
        info("Client di tim ini:")
        for _, p in ipairs(daftar) do
            print("   " .. p:gsub("com%.roblox%.", "") ..
                  (pkg_running(p) and (C.G.."  [jalan]"..C.N) or (C.Y.."  [off]"..C.N)))
        end
        print()
        info("Contoh:  zenx intip clienu 20")
        info("         (nunggu 20 detik, baru dipotret -- sempet pindah layar dulu)")
        return
    end

    -- boleh ketik pendek (clienu) atau lengkap (com.roblox.clienu)
    local pkg = nil
    for _, p in ipairs(daftar) do
        if p == pilih or p:gsub("com%.roblox%.", "") == pilih then pkg = p break end
    end
    if not pkg then
        err("Client '" .. pilih .. "' gak ada di config.")
        info("Liat daftarnya:  zenx intip")
        return
    end

    print(C.BOLD..C.C.."\n=== INTIP: " .. pkg:gsub("com%.roblox%.", "") .. " ===\n"..C.N)
    if jeda > 0 then
        info("Nunggu " .. jeda .. " detik -- siapin layarnya sekarang.")
        for sisa = jeda, 1, -1 do
            io.write(C.D .. "   " .. sisa .. "...   \r" .. C.N); io.flush()
            os.execute("sleep 1")
        end
        print()
    end

    info("Motret layar...")
    -- lewatiFokus=true: pas diagnosa, mending dapet dump apa adanya daripada
    -- nolak diem-diem cuma gara-gara pengecekan fokus meleset.
    local isi, sebab = ambil_dump(cfg, pkg, nil, true)
    if not isi then err("Gagal: " .. tostring(sebab)); return end

    -- teks unik, urut -- ini yang dipakai buat nyusun penanda
    local liat, unik = {}, {}
    for t in isi:gmatch('text="([^"]+)"') do
        if t:match("%S") and not liat[t] then liat[t] = true; unik[#unik+1] = t end
    end
    table.sort(unik)

    print()
    ok("Teks di layar (" .. #unik .. " potong):")
    if #unik == 0 then
        print(C.D .. "   (kosong -- gak ada satu pun node teks)" .. C.N)
        print(C.D .. "   Ini NORMAL di RedFinger: Roblox nggambar semuanya ke" .. C.N)
        print(C.D .. "   permukaan GL, uiautomator cuma liat cangkangnya. Jadi" .. C.N)
        print(C.D .. "   layar game / key / Home kebacanya SAMA-SAMA kosong --" .. C.N)
        print(C.D .. "   penanda berbasis teks emang gak bisa dipakai di sini." .. C.N)
    end
    for _, t in ipairs(unik) do print("   " .. t) end

    -- penilaian yang PERSIS sama kayak yang dipakai worker
    local pesan, sifat = klasifikasi_layar(isi)
    print()
    ok("Kata worker: " .. (pesan or "gak dikenali (dibiarin)"))
    local tindakan = ({
        manual = "CUMA DICATET -- client gak disentuh",
        tunggu = "ditutup, didiemin dulu",
        home   = "didorong 2x, baru dibunuh kalau bandel",
        ulang  = "dibunuh + dibuka lagi (jatah 3x/30 menit)",
    })[sifat or ""] or "gak ngapa-ngapain"
    ok("Tindakannya: " .. tindakan)
    print()
    info("Kalau penilaiannya SALAH, kirim daftar teks di atas ke Claude.")
    info("Atau tambah sendiri:  key_tanda=\"Kata A,Kata B\"  di config")
    print()
    return
end


if PERINTAH == "key" then
    local a2 = arg and arg[2] or ""

    -- v4.81: `key set` DIDULUIN, sebelum config divalidasi. Kalau config-nya
    -- rusak gara-gara baris kunci, ini yang bisa benerin -- percuma dihadang
    -- duluan. Aman: config_set_bypass nolak nulis kalau hasilnya gak sah.
    if a2:lower() == "set" then
        local apikey = arg and arg[3] or ""
        if apikey == "" then
            err("Kuncinya mana? Contoh:")
            err("   zenx key set <kunci-api-bypass.vip>")
            return
        end
        local sukses, sebab = config_set_bypass(apikey)
        if sukses then
            ok("Kunci API kesimpen di " .. CONFIG_FILE)
            info("Cek: zenx key <link>")
        else
            err("Gagal: " .. tostring(sebab))
        end
        return
    end

    local cfg = load_config()
    if not cfg then
        -- v4.81: bedain "belum pernah setup" vs "ada tapi rusak". Dulu dua-duanya
        -- dibilang "belum ada" -- bikin salah langkah (setup ulang padahal cuma
        -- perlu benerin satu baris).
        local adaFile = io.open(CONFIG_FILE, "r")
        if adaFile then
            adaFile:close()
            err("Config ADA tapi RUSAK: " .. CONFIG_FILE)
            local bak = io.open(CONFIG_FILE .. ".bak", "r")
            if bak then
                bak:close()
                info("Ada cadangannya. Balikin pakai:")
                info("   cp " .. CONFIG_FILE .. ".bak " .. CONFIG_FILE)
            else
                info("Liat isinya:  cat " .. CONFIG_FILE)
                info("Atau setup ulang:  rm " .. CONFIG_FILE .. " && zenx")
            end
        else
            err("Config belum ada. Jalanin `zenx` dulu buat setup.")
        end
        return
    end

    local pakaiRefresh = (a2:lower() == "refresh")
    local link = pakaiRefresh and (arg and arg[3] or "") or a2

    if link == "" then
        link = clipboard_ambil()
        if link then
            info("Link diambil dari clipboard")
        else
            err("Gak ada link. Salin dulu link key-nya, atau ketik:")
            err("   lua5.4 zenx_worker.lua key <link>")
            info("(clipboard butuh paket termux-api: pkg install termux-api)")
            return
        end
    end

    print(C.BOLD..C.C.."\n=== BYPASS KEY DELTA ==="..C.N)
    do  -- v4.86: kabarin keadaan lisensi sekarang, biar keliatan perlu apa nggak
        local kead, umur = lisensi_keadaan(cfg)
        local warna = (kead == "ada") and C.G or C.Y
        info("Lisensi sekarang: " .. warna .. kead .. C.N ..
             (umur and ("  (umur " .. umur_ringkas(umur) .. ")") or ""))
    end
    info("Link  : " .. link:sub(1, 60) .. (#link > 60 and "..." or ""))
    info("Mode  : " .. (pakaiRefresh and "refresh (proses ulang)" or "biasa"))
    info("Proses... (bisa 30-60 detik, jangan ditutup)")

    local kunci, sebab, mentah = bypass_kunci(cfg, link, pakaiRefresh)
    print()
    if kunci then
        ok("KUNCI: " .. kunci)
        -- disimpen juga, biar gak ilang kalau layar Termux ke-clear
        local f = io.open((os.getenv("HOME") or ".") .. "/zenx_key.txt", "w")
        if f then
            f:write(kunci .. "\n"); f:close()
            info("Disimpen di ~/zenx_key.txt")
        end
        -- taro ke clipboard kalau termux-api ada -- tinggal tempel di Delta
        os.execute("printf %s " .. shq(kunci) .. " | timeout 10 termux-clipboard-set >/dev/null 2>&1")
        -- v4.80: langsung tulis ke file lisensi Delta -- gak usah tempel manual.
        local wok, wket = tulis_lisensi(cfg, kunci)
        if wok then
            ok("Ditulis ke Delta: " .. wket)
            info("Semua client kepakai (file ini dipakai bareng). Buka ulang Delta.")
        else
            warn("Gagal nulis ke Delta: " .. tostring(wket))
            warn("Kuncinya udah di clipboard -- tempel manual aja dulu.")
        end
    else
        err("GAGAL: " .. tostring(sebab))
        if mentah and mentah:gsub("%s+", "") ~= "" then
            print()
            info("Jawaban mentah dari API (kirim ini ke Claude kalau bentuknya beda):")
            print(C.D .. mentah:sub(1, 900) .. C.N)
        end
    end
    print()
    return
end

if PERINTAH == "status" then
    local pid = baca_pid()
    if pid_hidup(pid) then
        ok("Jalan (pid " .. pid .. ")")
        print(sh("ps -p " .. pid .. " -o pid,etime,cmd="))
    else
        warn("Gak jalan.")
        if pid then info("PID file basi (" .. pid .. ") -> dihapus"); hapus(PID_FILE) end
    end
    return
end

-- v4.34: `lua zenx_worker.lua cek` -> tunjukin APA yang worker liat per client.
-- Buat nyari tau kenapa client kebaca "off" padahal game-nya jalan.
if PERINTAH == "cek" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin setup dulu."); return end
    print(C.BOLD..C.C.."\n=== DIAGNOSA DETEKSI CLIENT ===\n"..C.N)
    for _, pkg in ipairs(split(cfg.pkgs)) do
        print(C.BOLD..pkg..C.N)
        local pid = sh("su -c 'pidof " .. pkg .. "'") or ""
        print("  proses idup : " .. (pid:match("%d") and (C.G.."YA ("..pid:gsub("%s+$","")..")"..C.N) or (C.Y.."NGGAK"..C.N)))
        local o = sh("su -c 'dumpsys activity activities | grep ActivityRecord | grep " .. pkg .. "'") or ""
        if o:match("%S") then
            print("  baris ActivityRecord:")
            for line in o:gmatch("[^\n]+") do
                print("    " .. C.D .. line:gsub("^%s+",""):sub(1,150) .. C.N)
            end
        else
            print("  " .. C.Y .. "gak ada baris ActivityRecord sama sekali" .. C.N)
        end
        print("  dibaca worker: " .. (pkg_running(pkg) and (C.G.."JALAN"..C.N) or (C.Y.."OFF"..C.N)))
        print("")
    end
    print(C.D.."Kalau 'proses idup: YA' tapi 'dibaca worker: OFF', kirim baris"..C.N)
    print(C.D.."ActivityRecord di atas -- dari situ ketauan penanda yang bener."..C.N)
    return
end

if PERINTAH == "stop" then
    local pid = baca_pid()
    if not pid_hidup(pid) then
        warn("Gak ada yang jalan.")
        hapus(PID_FILE); hapus(STOP_FILE)
        -- jaga-jaga ada yatim piatu dari sesi lama
        local yatim = sh("pgrep -f zenx_worker.lua")
        if #yatim > 1 then
            warn("Tapi ada proses nyangkut. Dibunuh...")
            sh_silent("pkill -f 'lua.*zenx_worker.lua'")
        end
        sh_silent("termux-notification-remove zenx_worker")
        sh_silent("termux-wake-unlock")
        return
    end

    -- v5.14: perintah panjang (cari/ukur/pantau) itu proses TERPISAH dari worker.
    -- Kasih tau caranya, biar gak bingung pas 'zenx stop' keliatan gak mempan.
    do
        local lain = sh("pgrep -f 'zenx_worker.lua' | wc -l") or ""
        local n = tonumber(lain:match("%d+")) or 0
        if n > 1 then
            warn("Ada " .. n .. " proses zenx jalan (mungkin `cari`/`ukur`/`pantau`).")
            info("Kalau gak mati juga:  pkill -9 -f zenx_worker.lua")
        end
    end
    info("Minta berhenti ke pid " .. pid .. "...")
    local f = io.open(STOP_FILE, "w"); if f then f:write(tostring(os.time())); f:close() end

    -- worker ngecek flag tiap putaran (poll_sec, bawaan 5 detik).
    -- Kasih waktu lebih, siapa tau lagi di tengah buka client.
    for i = 1, 30 do
        os.execute("sleep 2")
        if not pid_hidup(pid) then
            ok("Berhenti baik-baik.")
            hapus(STOP_FILE)
            return
        end
        io.write(C.D.."   nungguin... "..(i*2).."s\r"..C.N); io.flush()
    end

    print()
    warn("60 detik gak mati juga. Dipaksa.")
    sh_silent("kill -9 " .. pid)
    sh_silent("pkill -9 -f 'lua.*zenx_worker.lua'")
    sh_silent("termux-notification-remove zenx_worker")
    sh_silent("termux-wake-unlock")
    hapus(PID_FILE); hapus(STOP_FILE)
    ok("Dimatiin paksa.")
    return
end

-- ============================================================
-- v4.84: perintah yang GAK DIKENAL jangan diem-diem nyalain worker. Dulu
-- `zenx intip ...` di worker versi lama malah bikin worker nyala -- keliatan
-- kayak perintahnya "gagal aneh", padahal cuma belum ada di versi itu.
-- v5.23: `zenx pasang` -- SEMUA isi pasang.sh dipindah ke sini, biar cuma ada
-- SATU berkas yang perlu di-push & diurus.
--
-- Yang gak bisa dipindah cuma satu: masang `lua` itu sendiri. Di Termux polos
-- Lua belum ada, jadi berkas .lua gak bisa jalan buat masang Lua. Makanya
-- perintah pemasangannya jadi satu baris:
--
--   pkg install lua54 curl -y && curl -sL <REPO>/zenx_worker.lua -o ~/zenx_worker.lua && lua5.4 ~/zenx_worker.lua pasang
--
-- Sisanya (izin penyimpanan, paket lain, cek root, pintasan, kalibrasi tombol,
-- kunci API, auto-jalan) dikerjain di sini.
if PERINTAH == "pasang" then
    -- v5.40: pakai konstanta yang sama kayak tulis_skrip_up -- biar gak ada
    -- dua alamat repo yang bisa beda diam-diam.
    local REPO = REPO_WORKER
    local RUMAH = os.getenv("HOME") or "."
    local PREFIX = os.getenv("PREFIX") or "/data/data/com.termux/files/usr"

    local function jalan(cmd) os.execute(cmd) end
    local function baca(cmd)
        local h = io.popen(cmd .. " 2>/dev/null")
        if not h then return "" end
        local o = h:read("*all") or ""
        h:close()
        return o
    end
    local function ada_perintah(nama)
        return baca("command -v " .. nama):match("%S") ~= nil
    end
    local function tanya(teks, bawaan)
        io.write(C.Y .. "? " .. teks .. C.N)
        if bawaan and bawaan ~= "" then io.write(C.D .. " [" .. bawaan .. "]" .. C.N) end
        io.write(": "); io.flush()
        local j = io.read()
        if j == nil or j == "" then return bawaan or "" end
        return j
    end

    print(C.BOLD .. C.C .. "\n=== ZENX PASANG (v" .. VERSION .. ") ===\n" .. C.N)

    -- 1. izin penyimpanan -- buat nulis autoexec Delta + baca berkas lisensi
    local adaStorage = baca("ls -d " .. RUMAH .. "/storage"):match("%S")
    if not adaStorage then
        info("Minta izin penyimpanan (bakal muncul kotak izin -- tap IZINKAN)")
        jalan("termux-setup-storage")
        jalan("sleep 3")
    end
    if baca("ls -d " .. RUMAH .. "/storage"):match("%S") then ok("Izin penyimpanan ada")
    else warn("Izin penyimpanan belum -- autoexec mungkin gagal") end

    -- 2. paket sisanya (lua & curl udah ada, kan dipakai buat nyampe sini)
    info("Pasang termux-api + coreutils (agak lama di RF, sabar)")
    jalan("pkg install termux-api coreutils -y >/dev/null 2>&1")
    if ada_perintah("mkfifo") then ok("mkfifo siap (shell root tetap bisa dipakai)")
    else warn("mkfifo gak ada -- shell root tetap bakal balik ke cara lama") end
    if ada_perintah("termux-clipboard-get") then ok("termux-api siap (papan klip kebaca)")
    else warn("termux-api gak ada -- `zenx key` gak bisa ambil link dari papan klip") end

    -- 3. root
    if baca("su -c 'echo ok'"):find("ok", 1, true) then
        ok("Root jalan")
    else
        warn("Root GAK jalan. Worker butuh root buat buka/tutup client Roblox.")
        warn("Buka root manager di RF, kasih izin buat Termux, terus ulangi.")
    end

    -- 4. kalibrasi tombol key -- ini yang paling ngirit waktu.
    -- Isinya pecahan per UKURAN JENDELA, jadi kalau semua RF layarnya sama,
    -- satu berkas kepakai di semua RF. Push sekali, RF baru langsung bisa.
    local jalurTap = RUMAH .. "/" .. TAP_FILE
    if not io.open(jalurTap, "r") then
        info("Ambil kalibrasi tombol key (" .. TAP_FILE .. ") -- opsional")
        jalan(("curl -fsSL '%s/%s?t=%d' -o '%s.baru' 2>/dev/null")
            :format(REPO, TAP_FILE, os.time(), jalurTap))
        local f = io.open(jalurTap .. ".baru", "r")
        local isi = f and f:read("*all") or ""
        if f then f:close() end
        if isi:match("%d+x%d+%s+[%d.]+%s+[%d.]+") then
            os.rename(jalurTap .. ".baru", jalurTap)
            local n = 0
            for _ in isi:gmatch("[^\n]+") do n = n + 1 end
            ok("Kalibrasi keunduh (" .. n .. " ukuran jendela)")
        else
            os.remove(jalurTap .. ".baru")
            warn("Belum ada " .. TAP_FILE .. " di GitHub -- nanti kalibrasi sendiri:")
            warn("   zenx catat clienu <jumlah-client>")
        end
    else
        ok("Kalibrasi udah ada")
    end

    -- 5. pintasan: zenx + up
    local LUA = ada_perintah("lua5.4") and "lua5.4" or "lua"
    local f1 = io.open(PREFIX .. "/bin/zenx", "w")
    if f1 then
        f1:write("#!" .. PREFIX .. "/bin/sh\n")
        f1:write('cd "$HOME" && exec ' .. LUA .. ' zenx_worker.lua "$@"\n')
        f1:close()
        jalan("chmod +x " .. PREFIX .. "/bin/zenx")
    end
    -- `up`: dibikin lewat fungsi yang sama kayak yang dipanggil pas worker
    -- nyala -- biar isinya gak pernah beda antara RF baru dan RF lama.
    tulis_skrip_up(true)
    ok("Pintasan dibikin: zenx (jalanin) + up (update worker)")

    -- 6. kunci API bypass.vip. SENGAJA ditanya di sini, bukan ditulis di worker
    -- -- worker di-push ke GitHub publik, kalau kuncinya di dalam situ siapa pun
    -- bisa baca & ngabisin kuota.
    print()
    info("Kunci API bypass.vip (buat `zenx key` -- bypass key Delta)")
    info("Enter = lewat, bisa diisi nanti: zenx key set <APIKEY>")
    local apikey = tanya("Kunci API", "")
    if apikey ~= "" then
        if io.open(CONFIG_FILE, "r") then
            local sukses, sebab = config_set_bypass(apikey)
            if sukses then ok("Kunci API kesimpen di " .. CONFIG_FILE)
            else err("Gagal: " .. tostring(sebab)) end
        else
            -- config belum ada (setup belum jalan) -- simpen dulu, dipasang
            -- otomatis begitu wizard selesai
            local t = io.open(RUMAH .. "/.zenx_apikey_sementara", "w")
            if t then t:write(apikey); t:close()
                ok("Kunci disimpen sementara -- dipasang otomatis abis setup") end
        end
    end

    -- 7. auto-jalan pas RF nyala (opsional, butuh app Termux:Boot)
    print()
    local jb = tanya("Jalanin worker otomatis tiap RF nyala? (y/N)", "n")
    if jb:lower():sub(1, 1) == "y" then
        jalan("mkdir -p " .. RUMAH .. "/.termux/boot")
        local fb = io.open(RUMAH .. "/.termux/boot/zenx", "w")
        if fb then
            fb:write("#!" .. PREFIX .. "/bin/sh\n")
            fb:write("termux-wake-lock\n")
            fb:write("export ZENX_AUTO=1\n")
            fb:write('cd "$HOME" && ' .. LUA .. ' zenx_worker.lua\n')
            fb:close()
            jalan("chmod +x " .. RUMAH .. "/.termux/boot/zenx")
            ok("Auto-jalan dipasang")
            warn("Pastiin app Termux:Boot kepasang & pernah dibuka sekali.")
        end
    end

    print()
    print(C.BOLD .. C.G .. "=== SIAP ===" .. C.N)
    info("Jalanin  : zenx")
    info("Matiin   : zenx stop")
    info("Update   : up")
    info("Diagnosa : zenx cek")
    info("Kunci key: zenx lisensi  /  zenx key")
    print()
    -- v5.24: gak usah nanya "jalanin sekarang?" -- langsung lanjut ke alur
    -- normal. Di situ udah ada pilihannya sendiri (Y=run / E=edit), atau
    -- langsung masuk wizard kalau config belum ada. Dulu ditanya dua kali
    -- padahal jawabannya sama.
    PERINTAH = ""
end

-- ============================================================
-- v5.25: `zenx cookie` -- ekstrak .ROBLOSECURITY dari akun SENDIRI (backup /
-- pindah device). Baca kredensial milik sendiri dari storage client yg login.
-- ============================================================
if PERINTAH == "cookie" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin setup dulu."); return end

    -- Satu panggilan su per client (inget 5.3: su ~6 detik/panggilan). Timeout
    -- panjang -- grep rekursif se-data-dir bisa lama; sh() dipatok 8s -> kepotong.
    -- @FILES = bukti file mana yg punya cookie. @COOKIE = nilai yg diekstrak.
    -- Pola cookie: "_|WARNING..." lalu token [huruf/angka/_ | . : -].
    local function ambil_cookie(pkg)
        local skrip =
            'd=/data/data/' .. pkg .. '; ' ..
            'echo @FILES; ' ..
            'grep -rla "ROBLOSECURITY" "$d" 2>/dev/null; ' ..
            'echo @COOKIE; ' ..
            'grep -rhoaE "_[|]WARNING[A-Za-z0-9_|.:-]+" "$d" 2>/dev/null | sort -u | head -1'
        local cmd = "timeout 45 su -c " .. shq(skrip) .. " 2>/dev/null"
        local h = io.popen(cmd)
        if not h then return {}, nil end
        local raw = h:read("*all") or ""; h:close()
        local files, cookie, mode = {}, nil, nil
        for baris in raw:gmatch("[^\n]+") do
            if baris == "@FILES" then mode = "f"
            elseif baris == "@COOKIE" then mode = "c"
            elseif mode == "f" then files[#files+1] = baris
            elseif mode == "c" and not cookie and baris:match("_[|]WARNING") then
                cookie = baris
            end
        end
        return files, cookie
    end

    -- tentuin target
    local arg2 = (arg[2] or ""):lower()
    local targets = {}
    if arg2 == "all" then
        targets = split(cfg.pkgs)
    elseif arg2 ~= "" then
        if #arg2 == 1 then targets = { "com.roblox.clien" .. arg2 }
        else targets = { arg2 } end
    else
        for _, pkg in ipairs(split(cfg.pkgs)) do
            if pkg_running(pkg) then targets[#targets+1] = pkg end
        end
        if #targets == 0 then
            warn("Gak ada client yang kebaca jalan.")
            info("Paksa satu client   :  zenx cookie <huruf>   (mis. zenx cookie u)")
            info("Paksa semua kepasang:  zenx cookie all")
            return
        end
    end

    print(C.BOLD .. C.C .. "\n=== EKSTRAK COOKIE (backup akun sendiri) ===\n" .. C.N)
    local OUT = "/sdcard/zenx_cookies.txt"
    local hasil = {}
    for _, pkg in ipairs(targets) do
        -- v5.26: label nama akun dari prefs.xml (baca_username, sumber yg sama
        -- kayak mapping client<->akun auto-rejoin). Kalau kosong -> "?".
        local akun = baca_username(pkg) or ""
        if akun == "" then akun = "?" end
        io.write(C.BOLD .. pkg .. C.N .. "  " .. C.C .. akun .. C.N .. "  ")
        local files, cookie = ambil_cookie(pkg)
        if cookie then
            local pendek = cookie:sub(1, 28) .. "..." .. cookie:sub(-6)
            print(C.G .. "OK" .. C.N .. "  (" .. #cookie .. " char)  " .. C.D .. pendek .. C.N)
            if #files > 0 then
                print("   " .. C.D .. "dari: " .. files[1] .. (#files > 1 and (" (+" .. (#files-1) .. " file lain)") or "") .. C.N)
            end
            -- format: <akun>\t<paket>\t<cookie>  -- akun didulukan biar gampang dicocokin
            hasil[#hasil+1] = akun .. "\t" .. pkg .. "\t" .. cookie
        else
            print(C.Y .. "GAK KETEMU" .. C.N)
            if #files > 0 then
                -- ada file ber-ROBLOSECURITY tapi pola cookie gak match -> format beda
                print("   " .. C.Y .. "ada file ber-ROBLOSECURITY tapi nilainya gak ke-ekstrak:" .. C.N)
                for i = 1, math.min(#files, 3) do
                    print("   " .. C.D .. files[i] .. C.N)
                end
                print("   " .. C.D .. "kirim salah satu path ini -- formatnya beda, perlu disetel." .. C.N)
            else
                print("   " .. C.D .. "gak ada jejak ROBLOSECURITY di /data/data/" .. pkg .. C.N)
                print("   " .. C.D .. "(client login? root jalan? mungkin token disimpen beda)" .. C.N)
            end
        end
    end

    print("")
    if #hasil > 0 then
        local f = io.open(OUT, "w")
        if f then
            f:write(table.concat(hasil, "\n") .. "\n"); f:close()
            ok("Kesimpen: " .. OUT .. "  (" .. #hasil .. " cookie, format: <akun>\\t<paket>\\t<cookie>)")
            info("File ada di /sdcard -- tinggal tarik lewat RedFinger file manager / adb pull.")
            print("   " .. C.D .. "Akun '?' = prefs.xml belum ada username-nya (client baru / belum login penuh)." .. C.N)

            -- v5.27: KIRIM ke panel (CF) biar bisa diliat + copy dari panel.
            -- Di panel digerbang password; di sini worker cuma nyetor (X-Kunci).
            -- Gak fatal kalau gagal -- file lokal tetep ada sebagai cadangan.
            print("")
            info("Ngirim ke panel...")
            local kirim_ok, kirim_gagal = 0, 0
            for _, baris in ipairs(hasil) do
                local akun2, paket2, cookie2 = baris:match("^(.-)\t(.-)\t(.*)$")
                if cookie2 and cookie2 ~= "" then
                    local body = '{"akun":"' .. jstr(akun2) .. '","paket":"' .. jstr(paket2) ..
                                 '","cookie":"' .. jstr(cookie2) .. '"}'
                    local resp = api_post(cfg, "/cookie-simpan", body) or ""
                    if resp:find('"ok"%s*:%s*true') then
                        kirim_ok = kirim_ok + 1
                    elseif resp:find("belumSiap") then
                        err("Tabel 'cookies' belum ada di D1. Buat dulu:")
                        err("  CREATE TABLE IF NOT EXISTS cookies (akun TEXT PRIMARY KEY, paket TEXT, cookie TEXT, ts INTEGER);")
                        kirim_gagal = kirim_gagal + 1
                        break
                    else
                        kirim_gagal = kirim_gagal + 1
                    end
                end
            end
            if kirim_ok > 0 then ok("Kekirim ke panel: " .. kirim_ok .. " cookie -> buka tab Cookie di panel (password)") end
            if kirim_gagal > 0 then warn("Gagal kirim " .. kirim_gagal .. " (cek koneksi / endpoint /cookie-simpan udah dideploy?)") end
        else
            err("Gagal nulis " .. OUT .. " (izin /sdcard? jalanin: termux-setup-storage)")
        end
    else
        warn("Gak ada cookie keambil.")
    end
    return
end

-- ============================================================
-- v5.28: `zenx verif` -- DAFTAR CLIENT YANG BUTUH DICEK MANUAL.
--
-- KENAPA BUKAN "DETEKSI CAPTCHA": di RF ini layar Roblox GAK BISA DIBACA
-- (5.9 / v4.85 -- game, layar key, Home, loading semuanya kebaca 0 teks).
-- Jadi mustahil tau "ini lagi nampilin captcha" dari layar. Yang bisa cuma
-- kenali POLA: proses idup tapi bridge gak pernah lapor = nyangkut sebelum
-- masuk game. Verif bot, layar key, popup umur, semuanya masuk pola itu.
-- Command ini nyaring daftarnya, keputusan (ganti akun / verif manual) di lo.
-- ============================================================
if PERINTAH == "verif" or PERINTAH == "cekverif" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin setup dulu."); return end

    local list = split(cfg.pkgs)
    print(C.BOLD .. C.C .. "\n=== CLIENT YANG BUTUH DICEK ===\n" .. C.N)
    info("Ngumpulin data (sekali dumpsys + sekali baca prefs)...")

    -- 1. siapa yang idup -- SEKALI dumpsys buat semua (v4.71)
    local jalan = pkg_running_semua(list) or {}

    -- 2. username semua client dalam SATU panggilan su (inget 5.3: su ~6 detik)
    local nama_pkg = {}
    do
        local bagian = {}
        for _, pkg in ipairs(list) do
            bagian[#bagian+1] = "echo @@" .. pkg .. "; cat /data/data/" .. pkg ..
                                "/shared_prefs/prefs.xml 2>/dev/null | grep -o '<string name=\"username\">[^<]*' | head -1"
        end
        local skrip = table.concat(bagian, "; ")
        local h = io.popen("timeout 60 su -c " .. shq(skrip) .. " 2>/dev/null")
        if h then
            local raw = h:read("*all") or ""; h:close()
            local kini
            for baris in raw:gmatch("[^\n]+") do
                local p = baris:match("^@@(%S+)")
                if p then kini = p
                elseif kini then
                    local u = baris:match('<string name="username">(.*)')
                    if u and u:match("%S") then nama_pkg[kini] = u end
                end
            end
        end
    end

    -- 3. bridge: kapan tiap akun terakhir lapor (sekali GET /stat)
    local stat = api_get(cfg, "/stat") or ""
    local now = os.time()

    local perlu, sehat, mati = {}, 0, 0
    for _, pkg in ipairs(list) do
        local hidup = jalan[pkg]
        local akun = nama_pkg[pkg]
        local ts = akun and bridge_ts(stat, akun) or nil
        local umur = ts and (now - ts) or nil

        if not hidup then
            mati = mati + 1
            perlu[#perlu+1] = { pkg = pkg, akun = akun, kelas = "mati",
                sebab = "proses gak jalan", saran = "dibuka worker (bukan verif)" }
        elseif not ts then
            -- idup tapi BELUM PERNAH lapor = nyangkut sebelum masuk game.
            -- Ini pola paling khas buat verif bot / layar key / popup umur.
            perlu[#perlu+1] = { pkg = pkg, akun = akun, kelas = "curiga",
                sebab = "idup tapi BELUM PERNAH lapor ke bridge",
                saran = "CEK LAYARNYA -- kemungkinan verif bot / layar key / popup umur" }
        elseif umur > 900 then
            perlu[#perlu+1] = { pkg = pkg, akun = akun, kelas = "curiga",
                sebab = ("lapor terakhir %d menit lalu"):format(math.floor(umur/60)),
                saran = "CEK LAYARNYA -- keluar game & gak balik, bisa kena verif pas rejoin" }
        elseif umur > 300 then
            perlu[#perlu+1] = { pkg = pkg, akun = akun, kelas = "pantau",
                sebab = ("lapor terakhir %d menit lalu"):format(math.floor(umur/60)),
                saran = "belum tentu masalah -- pantau dulu" }
        else
            sehat = sehat + 1
        end
    end

    print("")
    local nCuriga = 0
    for _, x in ipairs(perlu) do if x.kelas == "curiga" then nCuriga = nCuriga + 1 end end

    if nCuriga > 0 then
        print(C.BOLD .. C.Y .. "  PERLU DILIHAT (" .. nCuriga .. ")" .. C.N)
        for _, x in ipairs(perlu) do
            if x.kelas == "curiga" then
                print("  " .. C.BOLD .. x.pkg .. C.N .. "  " .. C.C .. (x.akun or "?") .. C.N)
                print("     " .. C.Y .. x.sebab .. C.N)
                print("     " .. C.D .. x.saran .. C.N)
            end
        end
        print("")
    end

    local nPantau = 0
    for _, x in ipairs(perlu) do if x.kelas == "pantau" then nPantau = nPantau + 1 end end
    if nPantau > 0 then
        print(C.D .. "  pantau dulu (" .. nPantau .. "):" .. C.N)
        for _, x in ipairs(perlu) do
            if x.kelas == "pantau" then
                print("     " .. x.pkg .. "  " .. (x.akun or "?") .. "  -- " .. C.D .. x.sebab .. C.N)
            end
        end
        print("")
    end

    if mati > 0 then
        print(C.D .. "  gak jalan (" .. mati .. "): " .. C.N)
        for _, x in ipairs(perlu) do
            if x.kelas == "mati" then
                print("     " .. C.D .. x.pkg .. "  " .. (x.akun or "?") .. C.N)
            end
        end
        print("")
    end

    print(C.G .. "  sehat: " .. sehat .. C.N .. C.D .. " (lapor < 5 menit lalu)" .. C.N)
    print("")
    if nCuriga > 0 then
        info("Buat liat layarnya: bawa client ke depan, terus liat sendiri di RF.")
        info("Kalau emang kena verif bot -> verif manual, atau ganti akunnya.")
    else
        ok("Gak ada yang mencurigakan.")
    end
    print("")
    print(C.D .. "  Catatan: worker GAK BISA baca layar di RF ini (lihat 5.9), jadi ini" .. C.N)
    print(C.D .. "  tebakan dari POLA, bukan bacaan captcha. Keputusan tetap di lo." .. C.N)
    return
end

-- ============================================================
-- v5.30: `zenx panel` -- UJI SAMBUNGAN KE PANEL, endpoint per endpoint.
--
-- Perlu karena gejalanya menyesatkan: worker keliatan jalan normal (config
-- kebaca, tim kedeteksi, polling jalan) tapi di panel timnya KOSONG. Itu
-- kejadian kalau GET /perintah lolos sementara POST /tim ditolak -- dan dulu
-- hasil POST-nya dibuang, jadi gak ada tanda apa pun.
-- Di sini tiap endpoint dites sendiri dan jawaban mentahnya ditampilin.
-- ============================================================
if PERINTAH == "panel" or PERINTAH == "uji" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin setup dulu."); return end

    print(C.BOLD .. C.C .. "\n=== UJI SAMBUNGAN PANEL ===\n" .. C.N)
    info("URL  : " .. tostring(cfg.url))
    info("tim  : " .. tostring(cfg.tim))
    info("kunci: " .. (cfg.kunci and (cfg.kunci:sub(1, 6) .. "..." .. cfg.kunci:sub(-4)) or "KOSONG"))
    print("")

    local function potong(t, n)
        t = tostring(t or ""):gsub("%s+", " ")
        if #t > (n or 150) then return t:sub(1, n or 150) .. "..." end
        return t
    end

    -- 1. GET /perintah -- ini yang biasanya lolos
    io.write(C.BOLD .. "1. GET /perintah" .. C.N .. "  ")
    local r1 = api_get(cfg, "/perintah?tim=" .. cfg.tim) or ""
    if r1 == "" then
        print(C.R .. "GAK NYAMBUNG" .. C.N)
        err("   URL salah / internet mati / Cloudflare gak balesin")
    else
        local e1 = ambil_str(r1, "error")
        if e1 then print(C.R .. "DITOLAK: " .. e1 .. C.N)
        else print(C.G .. "OK" .. C.N .. "  " .. C.D .. potong(r1) .. C.N) end
    end

    -- 2. POST /tim -- INI yang nentuin tim muncul di panel apa nggak
    io.write(C.BOLD .. "2. POST /tim" .. C.N .. "     ")
    local body = string.format(
        '{"tim":%s,"cpu":0,"ram_used":0,"ram_free":0,"ram_total":0,' ..
        '"jalan":0,"total":0,"sticky":false,"sig":"","clients":[],' ..
        '"aksi":%s,"log":[],"ver":%s,"dev":%s}',
        jstr(cfg.tim), jstr("uji sambungan"), jstr(VERSION), jstr(dev_id()))
    local r2 = api_post(cfg, "/tim", body) or ""
    if r2 == "" then
        print(C.R .. "GAK NYAMBUNG" .. C.N)
    else
        local e2 = ambil_str(r2, "error")
        if e2 then
            print(C.R .. "DITOLAK: " .. e2 .. C.N)
            err("   INI SEBABNYA tim kosong di panel.")
            if e2:find("kunci") then
                err("   Kunci di config beda sama `wrangler secret put KUNCI`.")
            elseif e2:find("jalur") then
                err("   Backend Cloudflare belum di-deploy / versinya lama.")
            elseif e2:find("kosong") then
                err("   Nama tim kosong di config. Setup ulang.")
            end
        else
            print(C.G .. "OK" .. C.N .. "  " .. C.D .. potong(r2) .. C.N)
        end
    end

    -- 3. GET /stat -- cek tim ini BENERAN kecatat
    io.write(C.BOLD .. "3. GET /stat" .. C.N .. "     ")
    local r3 = api_get(cfg, "/stat") or ""
    if r3 == "" then
        print(C.R .. "GAK NYAMBUNG" .. C.N)
    else
        local e3 = ambil_str(r3, "error")
        if e3 then print(C.R .. "DITOLAK: " .. e3 .. C.N)
        else
            -- cari nama tim ini di jawaban
            local ada = r3:find('"nama"%s*:%s*"' .. cfg.tim:gsub("%-", "%%-") .. '"') ~= nil
            if ada then
                print(C.G .. "OK" .. C.N .. "  " .. cfg.tim .. " KECATAT di panel")
            else
                print(C.Y .. "OK tapi " .. cfg.tim .. " GAK ADA di daftar" .. C.N)
                warn("   Panel nerima permintaan, tapi tim ini belum kecatat.")
                warn("   Kalau langkah 2 OK, tunggu ~15 detik terus ulangi.")
            end
        end
    end

    -- 4. klaim tim -- 1 tim = 1 device
    io.write(C.BOLD .. "4. klaim tim" .. C.N .. "     ")
    local r4 = api_get(cfg, "/tim-klaim?tim=" .. cfg.tim .. "&dev=" .. dev_id()) or ""
    if r4 == "" then
        print(C.D .. "gak kebaca (gak fatal)" .. C.N)
    else
        local boleh = ambil_str(r4, "boleh")
        local sebab = ambil_str(r4, "sebab")
        if boleh == "ya" then
            print(C.G .. "OK" .. C.N .. "  tim ini punya kita")
        else
            print(C.R .. "DIPEGANG DEVICE LAIN" .. C.N)
            err("   " .. tostring(sebab or "?"))
            err("   Pakai nomor tim lain, atau tunggu klaim lamanya basi (15 menit).")
        end
    end

    -- 5. akun: apa yang worker TAU vs apa yang panel PUNYA
    -- Ini yang nentuin kenapa panel bisa bilang "0 akun" padahal client-nya ada.
    print("")
    io.write(C.BOLD .. "5. akun yang worker tau" .. C.N .. "  ")
    local mapA = {}
    do
        local pkgs = split(cfg.pkgs)
        local perintah = {}
        for _, pkg in ipairs(pkgs) do
            perintah[#perintah+1] = string.format(
                'echo "@@%s"; cat /data/data/%s/shared_prefs/prefs.xml 2>/dev/null', pkg, pkg)
        end
        local o = sh("su -c '" .. table.concat(perintah, "; ") .. "'") or ""
        local kini
        for baris in o:gmatch("[^\r\n]+") do
            local t = baris:match("^@@(%S+)")
            if t then kini = t
            elseif kini then
                local u = baris:match('<string name="username">(.-)</string>')
                if u then mapA[kini] = u; kini = nil end
            end
        end
        local n = 0
        for _ in pairs(mapA) do n = n + 1 end
        print(n .. " dari " .. #pkgs .. " client")
        for _, pkg in ipairs(pkgs) do
            print("     " .. C.D .. pkg:gsub("com%.roblox%.", "") .. C.N .. "  " ..
                  (mapA[pkg] and (C.C .. mapA[pkg] .. C.N)
                   or (C.Y .. "prefs.xml gak kebaca (client belum pernah login?)" .. C.N)))
        end
    end

    -- 6. daftarin akun itu ke tim (assign-tim), tampilin jawabannya
    io.write(C.BOLD .. "6. POST /assign-tim" .. C.N .. "  ")
    do
        local daftar = {}
        for _, ak in pairs(mapA) do daftar[#daftar+1] = '"' .. ak .. '"' end
        if #daftar == 0 then
            print(C.Y .. "DILEWAT -- gak ada akun yang kebaca" .. C.N)
            err("   Ini sebabnya panel bilang 0 akun: worker sendiri gak tau akunnya.")
            err("   Buka tiap client sekali & login, biar prefs.xml kebentuk.")
        else
            local body = '{"tim":"' .. cfg.tim .. '","game":"' .. (cfg.game_label or "") ..
                         '","isi_kosong":true,"akun":[' .. table.concat(daftar, ",") .. "]}"
            local r6 = api_post(cfg, "/assign-tim", body) or ""
            local e6 = ambil_str(r6, "error")
            if r6 == "" then print(C.R .. "GAK NYAMBUNG" .. C.N)
            elseif e6 then print(C.R .. "DITOLAK: " .. e6 .. C.N)
            else print(C.G .. "OK" .. C.N .. "  " .. C.D .. potong(r6) .. C.N) end
        end
    end

    -- 7. cek di /stat: akun itu kecatat di tim mana & game apa
    io.write(C.BOLD .. "7. cek di /stat" .. C.N .. "      ")
    do
        local r7 = api_get(cfg, "/stat") or ""
        if r7 == "" then
            print(C.R .. "GAK NYAMBUNG" .. C.N)
        else
            print("")
            for _, ak in pairs(mapA) do
                -- cari blok akun ini, ambil tim & game-nya
                local pola = '"nama"%s*:%s*"' .. ak:gsub("([%.%-%+%*%?%[%]%^%$%(%)%%])", "%%%1") .. '"(.-)}'
                local blok = r7:match(pola)
                if blok then
                    local tim = blok:match('"tim"%s*:%s*"(.-)"') or "(kosong)"
                    local game = blok:match('"game"%s*:%s*"(.-)"') or "(kosong)"
                    local cocok = (tim == cfg.tim)
                    print("     " .. (cocok and C.G or C.Y) .. ak .. C.N ..
                          "  tim=" .. tim .. "  game=" .. game ..
                          (cocok and "" or (C.Y .. "  <- BEDA dari " .. cfg.tim .. C.N)))
                else
                    print("     " .. C.R .. ak .. C.N .. "  GAK ADA di panel")
                end
            end
            print("     " .. C.D .. "tim harus = " .. cfg.tim ..
                  " dan game harus = " .. (cfg.game_label or "?") ..
                  " biar nongol di tab itu" .. C.N)
        end
    end

    print("")
    print(C.D .. "  Kalau langkah 2 DITOLAK -> itu akar masalahnya." .. C.N)
    print(C.D .. "  Kalau semua OK tapi panel masih kosong -> panel-nya yang" .. C.N)
    print(C.D .. "  belum di-refresh, atau tab-nya nyaring game yang beda." .. C.N)
    print("")
    return
end

-- ============================================================
-- v5.35: `zenx script` -- ganti script autoexec tanpa setup ulang.
-- Tanpa ini, mau tuker STAR FARM <-> STAR SEED harus ngulang setup dari nol
-- (nomor tim, game, scan paket, dst) -- padahal yang mau diubah satu baris.
-- ============================================================
if PERINTAH == "script" or PERINTAH == "sc" then
    local cfg = load_config()
    if not cfg then err("Config belum ada. Jalanin setup dulu."); return end

    local GH = "https://raw.githubusercontent.com/alzafabocahbocah-boop/ronihub/main/"
    local PILIHAN = {
        { "STAR FARM", "gag2",   "farm kebun: tanam, collect, jual" },
        { "STAR SEED", "seed",   "AFK beli seed + gear + pet, terima gift" },
        { "MARKET",    "market", "akun market / TradeWorld" },
    }

    print(C.BOLD .. C.C .. "\n=== GANTI SCRIPT AUTOEXEC ===\n" .. C.N)
    info("tim      : " .. tostring(cfg.tim))
    info("game     : " .. tostring(cfg.game_label or "-"))
    info("sekarang : " .. tostring(cfg.script_label or "-") ..
         "  (" .. tostring(cfg.script_url or "-") .. ")")
    print("")

    -- boleh langsung: zenx script seed
    local minta = (arg[2] or ""):lower()
    local sc
    if minta ~= "" then
        for _, x in ipairs(PILIHAN) do
            if minta == x[2] or minta == x[1]:lower():gsub("%s", "")
               or minta == x[1]:lower() then sc = x break end
        end
        if not sc then
            err("'" .. minta .. "' gak dikenal. Pilihannya: gag2 / seed / market")
            return
        end
    else
        for i, x in ipairs(PILIHAN) do
            print(C.D .. string.format("  %d) %-10s -> %-7s  %s", i, x[1], x[2], x[3]) .. C.N)
        end
        print("")
        local ps = ask("Pilih (1/2/3, Enter=batal)", "")
        if ps == "" then info("Dibatalin."); return end
        sc = PILIHAN[tonumber(ps) or 0]
        if not sc then err("Pilihan gak ada."); return end
    end

    if cfg.script_url == (GH .. sc[2]) then
        info("Udah pakai " .. sc[1] .. " -- gak ada yang diubah.")
        return
    end

    cfg.script_url = GH .. sc[2]
    cfg.script_label = sc[1]
    save_config(cfg)
    ok("Config disimpen: " .. sc[1] .. " -> " .. cfg.script_url)

    -- tulis ulang autoexec biar langsung kepakai
    if tulis_autoexec(cfg) then
        print("")
        warn("Client yang LAGI JALAN masih pakai script LAMA.")
        warn("Delta cuma baca autoexec pas masuk game -- jadi harus join ulang:")
        info("  panel -> tim ini -> Rejoin   (atau: zenx stop terus jalanin lagi)")
    end
    print("")
    return
end

if PERINTAH ~= "" then
    err("Perintah '" .. PERINTAH .. "' gak dikenal di v" .. VERSION)
    print()
    info("Yang ada:")
    info("   zenx                    -> jalanin worker")
    info("   zenx stop               -> berhenti baik-baik")
    info("   zenx status             -> jalan apa nggak")
    info("   zenx cek                -> diagnosa deteksi client")
    info("   zenx intip <client> [d] -> potret teks di layar client")
    info("   zenx lisensi            -> keadaan kunci Delta")
    info("   zenx set <cl> <jumlah>  -> cuma atur ukuran jendela (buat nguji)")
    info("   zenx catat <cl> <jumlah>-> set ukuran, LO yang tap, kesimpen otomatis")
    info("   zenx uji <client>       -> tembak 6 titik, cek pencetan nyampe apa nggak")
    info("   zenx ukur <cl> <jumlah> -> set jendela ke ukuran N client, cari tombolnya")
    info("   zenx pasang             -> pasang/atur RF baru (gantiin pasang.sh)")
    info("   zenx cari <client>      -> worker cari sendiri tombol key + bypass sekalian")
    info("   zenx pantau <client>    -> tiap dipencet, koordinatnya langsung nongol")
    info("   zenx rekam <client>     -> rekam sekali, ambil satu koordinat")
    info("   zenx tap <cl> <x> <y>   -> pencet titik (pecahan 0..1)")
    info("   zenx key                -> bypass key Delta (link dari clipboard)")
    info("   zenx key <link>         -> bypass key dari link yang diketik")
    info("   zenx key set <APIKEY>   -> isi kunci API bypass.vip")
    info("   zenx cookie             -> ekstrak cookie akun sendiri (yg lagi jalan) buat backup")
    info("   zenx cookie <huruf>     -> ekstrak dari satu client (mis. zenx cookie u)")
    info("   zenx cookie all         -> ekstrak dari semua paket kepasang")
    info("   zenx verif              -> daftar client yang butuh dicek manual (nyangkut/verif bot)")
    info("   zenx panel              -> UJI sambungan ke panel (kalau tim kosong di panel)")
    info("   zenx script             -> ganti script autoexec (STAR FARM / STAR SEED / MARKET)")
    info("   zenx script seed        -> langsung ke STAR SEED, tanpa nanya")
    print()
    info("Kalau perintahnya harusnya ada, versi di RF ini ketinggalan -- tarik ulang:")
    info("   curl -fsSL <repo>/zenx_worker.lua -o ~/zenx_worker.lua")
    return
end

print(C.BOLD..C.C.."ZenX Worker v"..VERSION.." (Termux)\n"..C.N)

-- jangan dobel: 2 worker di 1 tim = client dibuka barengan, RAM jebol
local pid_lama = baca_pid()
if pid_hidup(pid_lama) then
    err("Udah ada worker jalan (pid " .. pid_lama .. ").")
    info("Matiin dulu:  lua5.4 zenx_worker.lua stop")
    return
end
hapus(STOP_FILE)   -- sisa dari sesi sebelumnya

local cfg=load_config()

-- v4.2: dijalanin Termux:Boot? Gak ada yang bisa ngetik jawaban wizard.
-- Tanpa penjaga ini, worker nyangkut diem-diem nungguin io.read() selamanya.
local NON_INTERAKTIF = (os.getenv("ZENX_AUTO") == "1")

if not cfg then
    if NON_INTERAKTIF then
        err("Config gak ada, dan lagi mode auto (ZENX_AUTO=1).")
        err("Wizard butuh diketik. Jalanin manual dulu:")
        err("   lua5.4 zenx_worker.lua")
        return
    end
    -- config ntfy lama?
    local lama = io.open("zenx_worker_ntfy_config.lua","r")
    if lama then
        lama:close()
        warn("Ketemu config ntfy lama. v4.x pakai Cloudflare Worker, bukan ntfy.")
        warn("Setup ulang — siapin URL Worker + kunci.")
    else
        warn("Config kosong - setup dulu")
    end
    cfg=setup_wizard()
elseif NON_INTERAKTIF then
    ok("Config loaded (mode auto — langsung jalan)")
else
    ok("Config loaded")
    io.write(C.Y.."Run sekarang? (Y=run / E=edit ulang): "..C.N); io.flush()
    local c=io.read()
    if c=="E" or c=="e" then cfg=setup_wizard() end
end
local pid = tulis_pid()
info("pid " .. pid .. " (matiin: lua5.4 zenx_worker.lua stop)")

local okrun,e=pcall(run,cfg)

-- kalau run() keluar sendiri, bersih() udah dipanggil di dalem.
-- Ini jaring pengaman buat error/Ctrl+C.
if not okrun then
    err("Berhenti: "..tostring(e))
    bersih(cfg, "error")
elseif io.open(PID_FILE, "r") then
    bersih(cfg, "selesai")
end
