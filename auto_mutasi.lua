-- auto_mutasi.lua v6
-- Full pipeline Mutation Machine + lineup swap
-- Sesi 1 (timer running): equip 7 Mimic Octopus + 1 Golem  → reduce timer
-- Sesi 2 (mesin SIAP):    equip 2 Gremlin                  → jackpot mutasi saat claim
-- Flow: submit pet → start → equip sesi1 → tunggu SIAP → equip sesi2 → claim → repeat

-- ══════════════════════════════════════════
local AUTO_LOOP  = true   -- true = loop | false = sekali
local JUMLAH     = 5      -- berapa pet
local EQUIP_WAIT = 10     -- detik tunggu user equip pet baru tiap loop
local DELAY_PP   = 0.6
local DELAY_STEP = 0.6

-- lineup sesi 1 (reduce timer) — sama dengan MTS_LINEUP_DEF di uplevelnew
local SESI1_DEF = (type(MTS_LINEUP_DEF)=="table" and MTS_LINEUP_DEF) or {
    {nama="Mimic Octopus", jml=7},
    {nama="Golem",         jml=1},
}
-- lineup sesi 2 (jackpot claim)
local SESI2_DEF = {
    {nama="Gremlin", jml=2},
}
-- ══════════════════════════════════════════

local RS   = game:GetService("ReplicatedStorage")
local plr  = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

local RE = RS.GameEvents.PetMutationMachineService_RE

-- ── log ke tab AUTO MTS + console ──
local function mtsLog(txt, col)
    print("[AutoMutasi] " .. txt)
    if type(_G.ZenxMtsAddLog) == "function" then
        pcall(_G.ZenxMtsAddLog, txt, col)
    end
end

-- ── update fase di UI tab AUTO MTS ──
local function setFase(fase)
    if type(_G.ZenxMtsSetFase) == "function" then
        pcall(_G.ZenxMtsSetFase, fase)
    end
end

-- ── pakai equipSesi/unequipAll dari uplevelnew kalau tersedia ──
local function swapLineup(def, label, fase)
    if type(unequipAll) == "function" and type(equipSesi) == "function" then
        mtsLog("👕 Swap → " .. label)
        setFase(fase or label)
        pcall(unequipAll)
        task.wait(1.5)
        pcall(equipSesi, 99, def)
        task.wait(1.0)
        mtsLog("✓ Lineup aktif: " .. label)
    else
        warn("[AutoMutasi] ⚠ equipSesi/unequipAll tidak tersedia (jalankan uplevelnew dulu?)")
    end
end

-- ── timer label ──
local function getTimerLabel()
    local ok, lbl = pcall(function()
        return game.Workspace.NPCS.PetMutationMachine
            .Model.Part.BillboardPart.BillboardGui.TimerTextLabel
    end)
    return (ok and lbl and lbl:IsA("TextLabel")) and lbl or nil
end

local function parseTimer(txt)
    if not txt then return nil end
    local m, s = txt:match("^(%d+):(%d+)$")
    return (m and s) and (tonumber(m)*60 + tonumber(s)) or nil
end

-- ── tunggu timer selesai (jadi "SIAP" / non-angka) ──
local function waitMachineDone()
    local lbl = getTimerLabel()
    if not lbl then warn("[AutoMutasi] Timer label tidak ditemukan") return end

    local secs = parseTimer(lbl.Text)
    if not secs or secs <= 0 then
        print("[AutoMutasi] ✓ Mesin sudah SIAP")
        return
    end

    print(string.format("[AutoMutasi] ⏳ Mesin running... sisa %d:%02d", math.floor(secs/60), secs%60))

    local done = false
    local conn
    conn = lbl:GetPropertyChangedSignal("Text"):Connect(function()
        local s2 = parseTimer(lbl.Text)
        if not s2 or s2 <= 0 then
            done = true
            pcall(function() conn:Disconnect() end)
            print("[AutoMutasi] ✓ Timer habis! Status: " .. tostring(lbl.Text))
        elseif s2 % 60 == 0 then
            print(string.format("[AutoMutasi] ⏳ Sisa %d:%02d", math.floor(s2/60), s2%60))
        end
    end)

    while not done do
        task.wait(2)
        local s3 = parseTimer(lbl.Text)
        if not s3 or s3 <= 0 then
            done = true
            pcall(function() conn:Disconnect() end)
            print("[AutoMutasi] ✓ Mesin SIAP (poll)")
        end
    end
end

-- ── cari PP mesin mutasi ──
local function getMutasiPP()
    local ok, part = pcall(function()
        return game.Workspace.NPCS.PetMutationMachine.Model.ProxPromptPart
    end)
    if ok and part then
        local pp = part:FindFirstChildOfClass("ProximityPrompt")
        if pp then return pp, part end
    end
    return nil, nil
end

-- ── nama pet yang ada di dalam mesin ──
local function getPetDalamMesin()
    local ok, pml = pcall(function()
        return game.Workspace.NPCS.PetMutationMachine.PetModelLocation
    end)
    if ok and pml then
        for _, child in ipairs(pml:GetChildren()) do
            if child:IsA("Model") then return child.Name end
        end
    end
    return "?"
end

-- ── 1 siklus penuh ──
local function doSiklus(skipSubmit)
    if not skipSubmit then
        local pp, part = getMutasiPP()
        if not pp then
            warn("[AutoMutasi] ✗ PP Mutation Machine tidak ditemukan!")
            return false
        end

        print("[AutoMutasi] [1/3] fireproximityprompt...")
        local ok1 = pcall(fireproximityprompt, pp)
        if not ok1 then warn("[AutoMutasi] ✗ fireproximityprompt gagal") return false end
        task.wait(DELAY_PP)

        print("[AutoMutasi] [2/3] SubmitHeldPet...")
        local ok2, e2 = pcall(function() RE:FireServer("SubmitHeldPet") end)
        if not ok2 then warn("[AutoMutasi] ✗ SubmitHeldPet: "..tostring(e2)) return false end
        task.wait(DELAY_STEP)

        print("[AutoMutasi] [3/3] StartMachine...")
        local ok3, e3 = pcall(function() RE:FireServer("StartMachine") end)
        if not ok3 then warn("[AutoMutasi] ✗ StartMachine: "..tostring(e3)) return false end
        task.wait(DELAY_STEP)

        print("[AutoMutasi] ✓ Pet masuk mesin: " .. getPetDalamMesin())
    end

    -- sesi 1: swap ke Mimic+Golem selama mesin running
    swapLineup(SESI1_DEF, "7 Mimic + 1 Golem", "Fase 1: Mimic+Golem ⏳")

    -- tunggu mesin selesai
    waitMachineDone()
    task.wait(0.5)

    -- sesi 2: swap ke Gremlin sebelum claim
    swapLineup(SESI2_DEF, "2 Gremlin", "Fase 2: Gremlin 🎰")
    task.wait(1.0)

    -- claim
    mtsLog("🎁 ClaimMutatedPet...")
    setFase("Claim...")
    local ok4, e4 = pcall(function() RE:FireServer("ClaimMutatedPet") end)
    if not ok4 then warn("[AutoMutasi] ✗ ClaimMutatedPet: "..tostring(e4)) return false end
    task.wait(DELAY_STEP)

    mtsLog("✓ Claim selesai!", Color3.fromRGB(60,200,80))
    setFase("—")
    return true
end

-- ══════════════════════════════════════════════════
--  MAIN
-- ══════════════════════════════════════════════════
print("╔═════════════════════════════════════════════╗")
print("║  auto_mutasi.lua v6                         ║")
print("║  Submit → Sesi1(Mimic+Golem) → SIAP →      ║")
print("║  Sesi2(Gremlin) → Claim → Repeat            ║")
print("╚═════════════════════════════════════════════╝")

-- cek state awal
local lbl0  = getTimerLabel()
local txt0  = lbl0 and lbl0.Text or "?"
local secs0 = parseTimer(txt0)
print(string.format("[AutoMutasi] State mesin: %q", txt0))

if not AUTO_LOOP then
    -- SINGLE RUN
    print("[AutoMutasi] Mode: SINGLE RUN")
    if secs0 and secs0 > 0 then
        print("[AutoMutasi] Mesin running → langsung tunggu + swap sesi2 + claim")
        -- sudah running, equip sesi1 dulu sisa timer, lalu tunggu
        swapLineup(SESI1_DEF, "Sesi 1 (lanjut)")
        waitMachineDone()
        task.wait(0.5)
        swapLineup(SESI2_DEF, "Sesi 2 (2 Gremlin)")
        task.wait(1.0)
        pcall(function() RE:FireServer("ClaimMutatedPet") end)
        print("[AutoMutasi] ✓ Claim selesai!")
    else
        print("[AutoMutasi] Mesin SIAP. Equip pet sekarang! Mulai 3 detik...")
        task.wait(3)
        doSiklus(false)
    end
else
    -- AUTO LOOP
    print(string.format("[AutoMutasi] Mode: AUTO LOOP (%d pet)", JUMLAH))
    local berhasil, gagal = 0, 0

    -- kalau mesin lagi running: ikut dari tengah (sesi1 → tunggu → sesi2 → claim)
    if secs0 and secs0 > 0 then
        print("[AutoMutasi] Mesin masih running! Ikut dari sesi 1...")
        swapLineup(SESI1_DEF, "Sesi 1 (lanjut)")
        waitMachineDone()
        task.wait(0.5)
        swapLineup(SESI2_DEF, "Sesi 2 (2 Gremlin)")
        task.wait(1.0)
        local okC = pcall(function() RE:FireServer("ClaimMutatedPet") end)
        print(okC and "[AutoMutasi] ✓ Claim awal OK" or "[AutoMutasi] ✗ Claim awal gagal")
        task.wait(1)
    end

    for i = 1, JUMLAH do
        print(string.format("\n━━━ Pet %d/%d ━━━", i, JUMLAH))
        print(string.format("[AutoMutasi] Equip pet yang mau dimutasi! (%d detik)", EQUIP_WAIT))
        for t = EQUIP_WAIT, 1, -1 do
            task.wait(1)
            if t <= 5 then print(string.format("[AutoMutasi] Mulai dalam %d...", t)) end
        end

        local ok = doSiklus(false)
        if ok then berhasil = berhasil + 1 else gagal = gagal + 1 end
    end

    print(string.format("\n[AutoMutasi] ══ Selesai: %d berhasil, %d gagal ══", berhasil, gagal))
end
