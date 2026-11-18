-- ============================================================
-- DEBUG WHALE WATERS FOKUS v1.0
-- Fokus: kapan mulai, berapa lama, kapan selesai
-- Trigger yang diketahui: Clam spawn di Workspace jam 13:08:00
-- ============================================================
local WS = workspace
local plr = game.Players.LocalPlayer

-- =====================================================
-- 1. Cek apakah sekarang Whale Waters sedang aktif
--    (ada Clam di Workspace?)
-- =====================================================
print("=== WHALE WATERS DEBUG FOKUS @ "..os.date("%H:%M:%S").." ===")
print("")
print("[WW] === CEK CLAM DI WORKSPACE SEKARANG ===")
local clamCount = 0
for _, obj in ipairs(WS:GetChildren()) do
    local nm = tostring(obj.Name)
    if nm == "Clam" or nm:lower():find("clam",1,true) then
        clamCount = clamCount + 1
        print("[WW-CLAM] ada: "..nm.." @ "..os.date("%H:%M:%S"))
        -- dump atribut
        pcall(function()
            for k,v in pairs(obj:GetAttributes()) do
                print("  ATTR "..tostring(k).."="..tostring(v))
            end
        end)
        -- cek children yang punya TextLabel
        pcall(function()
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextBox") then
                    local t=""; pcall(function() t=tostring(d.Text) end)
                    if #t>0 and #t<80 then
                        print("  TEXT "..tostring(d.Name)..'="'..t..'"')
                    end
                end
            end
        end)
    end
end
if clamCount == 0 then
    print("[WW-CLAM] tidak ada Clam di Workspace sekarang")
end

-- =====================================================
-- 2. Cek semua child Workspace yang berhubungan dengan
--    event laut / whale waters
-- =====================================================
print("")
print("[WW] === SEMUA CHILD WS YANG RELEVAN ===")
for _, obj in ipairs(WS:GetChildren()) do
    local nm = tostring(obj.Name):lower()
    if nm:find("whale",1,true) or nm:find("water",1,true)
       or nm:find("clam",1,true) or nm:find("kelp",1,true)
       or nm:find("fish",1,true) or nm:find("ocean",1,true)
       or nm:find("sea",1,true) or nm:find("tide",1,true)
       or nm:find("weather",1,true) or nm:find("wave",1,true) then
        print("[WW-WS] "..tostring(obj.Name).." ["..tostring(obj.ClassName).."]")
    end
end

-- =====================================================
-- 3. Cek EasterEggHuntUI — semua TextLabel di dalamnya
-- =====================================================
print("")
print("[WW] === EasterEggHuntUI TextLabels ===")
local eeGui = plr.PlayerGui:FindFirstChild("EasterEggHuntUI")
if eeGui then
    for _, d in ipairs(eeGui:GetDescendants()) do
        if d:IsA("TextLabel") then
            local t=""; pcall(function() t=tostring(d.Text) end)
            print("  "..tostring(d.Name)..' vis='..tostring(d.Visible)..' text="'..t..'"')
        end
    end
else
    print("  EasterEggHuntUI tidak ada")
end

-- =====================================================
-- 4. Cek Hud_UI / Top_Notification / Notifications
--    untuk pesan "Whale Waters"
-- =====================================================
print("")
print("[WW] === HUD / NOTIF teks whale/water/tide ===")
for _, guiNm in ipairs({"Hud_UI","Top_Notification","Notifications","Events"}) do
    local g = plr.PlayerGui:FindFirstChild(guiNm)
    if g then
        for _, d in ipairs(g:GetDescendants()) do
            local ok, t = pcall(function() return tostring(d.Text) end)
            if ok and #t > 0 and #t < 120 then
                local tl = t:lower()
                if tl:find("whale",1,true) or tl:find("tide",1,true)
                   or tl:find("water",1,true) or tl:find("clam",1,true) then
                    print("  ["..guiNm.."] "..tostring(d.Name)..'="'..t..'"')
                end
            end
        end
    end
end

-- =====================================================
-- 5. Cek folder Events di PlayerGui (ada di scan sebelumnya)
--    descendants=10126 — kemungkinan ada WeatherEvent di sana
-- =====================================================
print("")
print("[WW] === Events folder children ===")
local evFolder = plr.PlayerGui:FindFirstChild("Events")
if evFolder then
    for _, c in ipairs(evFolder:GetChildren()) do
        print("  - "..tostring(c.Name).." ["..tostring(c.ClassName).."] desc="..#c:GetDescendants())
    end
    -- cari yang ada kata whale/water/tide
    print("[WW] Events descendants teks whale/water/tide:")
    for _, d in ipairs(evFolder:GetDescendants()) do
        local nm = tostring(d.Name):lower()
        local ok, t = pcall(function() return tostring(d.Text) end)
        local tx = ok and t or ""
        if nm:find("whale",1,true) or nm:find("water",1,true) or nm:find("tide",1,true)
           or (ok and #tx>0 and tx:lower():find("whale",1,true))
           or (ok and #tx>0 and tx:lower():find("tide",1,true)) then
            print("  > "..tostring(d:GetFullName())..' text="'..tx..'"')
        end
    end
else
    print("  Events folder tidak ada")
end

-- =====================================================
-- 6. MONITOR: ChildAdded WS — catat SEMUA yang spawn
--    + timestamp + hapus kapan (ChildRemoved)
-- =====================================================
print("")
print("[WW] === MONITOR ChildAdded/Removed WS ===")
print("[WW] Catat semua object yang spawn/despawn di Workspace")
print("[WW] Fokus: Clam, Whale, WeatherVisuals, dll")

local wwStart = nil  -- tick() saat event mulai

WS.ChildAdded:Connect(function(c)
    local nm = tostring(c.Name)
    local nml = nm:lower()
    -- log SEMUA yang bukan terrain/baseplate/NPC biasa
    if nml:find("clam",1,true) or nml:find("whale",1,true)
       or nml:find("water",1,true) or nml:find("kelp",1,true)
       or nml:find("fish",1,true) or nml:find("ocean",1,true)
       or nml:find("tide",1,true) or nml:find("weather",1,true)
       or nml:find("wave",1,true) or nml:find("sea",1,true) then
        if not wwStart then wwStart = tick() end
        local elapsed = wwStart and string.format("%.1f", tick()-wwStart) or "0"
        print("[WW-SPAWN +"..elapsed.."s @ "..os.date("%H:%M:%S").."] "..nm.." ["..tostring(c.ClassName).."]")
        -- cek atribut
        pcall(function()
            for k,v in pairs(c:GetAttributes()) do
                print("  ATTR "..tostring(k).."="..tostring(v))
            end
        end)
    end
end)

WS.ChildRemoved:Connect(function(c)
    local nm = tostring(c.Name)
    local nml = nm:lower()
    if nml:find("clam",1,true) or nml:find("whale",1,true)
       or nml:find("water",1,true) or nml:find("kelp",1,true)
       or nml:find("tide",1,true) or nml:find("weather",1,true) then
        local elapsed = wwStart and string.format("%.1f", tick()-wwStart) or "?"
        print("[WW-REMOVED +"..elapsed.."s @ "..os.date("%H:%M:%S").."] "..nm)
        -- kalau semua Clam hilang, event selesai
        local clamLeft = 0
        for _, obj in ipairs(WS:GetChildren()) do
            if tostring(obj.Name) == "Clam" then clamLeft = clamLeft + 1 end
        end
        if clamLeft == 0 and nml:find("clam",1,true) then
            local dur = wwStart and string.format("%.0f", tick()-wwStart) or "?"
            print("[WW-END] Semua Clam hilang! Durasi event: ~"..dur.."s")
            wwStart = nil
        end
    end
end)

-- =====================================================
-- 7. Poll tiap 1s — baca EasterEggHuntUI countdown
--    + cek jumlah Clam di WS
-- =====================================================
task.spawn(function()
    local lastText = ""
    local lastClam = -1
    while true do
        task.wait(1)
        -- baca countdown text
        local ct = ""
        pcall(function()
            local gui = plr.PlayerGui:FindFirstChild("EasterEggHuntUI")
            if gui then
                -- coba semua TextLabel
                for _, d in ipairs(gui:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local t=""; pcall(function() t=tostring(d.Text) end)
                        -- yang ada angka dan "ends" / "until" / ":" (format timer)
                        if t:match("%d+:%d+") or t:match("%d+ minute") or t:match("%d+ second") then
                            ct = tostring(d.Name)..'="'..t..'"'
                        end
                    end
                end
            end
        end)
        -- hitung Clam
        local nc = 0
        for _, obj in ipairs(WS:GetChildren()) do
            if tostring(obj.Name) == "Clam" then nc = nc + 1 end
        end
        -- print kalau ada perubahan
        if ct ~= lastText or nc ~= lastClam then
            local elapsed = wwStart and " +"..string.format("%.0f",tick()-wwStart).."s" or ""
            print("[WW-POLL @ "..os.date("%H:%M:%S")..elapsed.."] Clam="..nc.." | "..ct)
            lastText = ct
            lastClam = nc
        end
    end
end)

print("[WW] Script aktif. Tunggu Whale Waters event mulai...")
print("[WW] Kalau Clam=0 sekarang, jalankan saat mau event (ada countdown di layar).")
