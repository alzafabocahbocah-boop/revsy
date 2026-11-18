-- ============================================================
-- DEBUG WHALE WATERS COUNTDOWN v2.0
-- Berdasarkan hasil scan GUI: EasterEggHuntUI punya TextLabel countdown
-- Pattern yang sama kemungkinan ada untuk Whale Waters
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local WS = workspace
local plr = game.Players.LocalPlayer

-- =====================================================
-- BAGIAN 1: Scan PlayerGui — cari TextLabel dengan kata
-- "whale", "water", "weather", "ends", "starts", "until"
-- (sama kayak GlobalEasterEggHuntCountdown)
-- =====================================================
local function scanGuiCountdown()
    print("[WW-GUI] === Scan PlayerGui untuk countdown text ===")
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then print("[WW-GUI] PlayerGui nil"); return end

    for _, gui in ipairs(pg:GetDescendants()) do
        local ok, tx = pcall(function() return tostring(gui.Text) end)
        if ok and #tx > 0 and #tx < 120 then
            local txl = tx:lower()
            if txl:find("whale",1,true) or txl:find("water",1,true)
               or txl:find("ends!",1,true) or txl:find("until",1,true)
               or txl:find("starts in",1,true) or txl:find("weather",1,true) then
                local vis = "?"; pcall(function() vis = tostring(gui.Visible) end)
                print("[WW-GUI] "..tostring(gui:GetFullName()).." vis="..vis..' text="'..tx..'"')
            end
        end
    end

    -- cek khusus ScreenGui yang namanya mengandung "whale"/"weather"/"event"
    for _, sg in ipairs(pg:GetChildren()) do
        local nm = tostring(sg.Name):lower()
        if nm:find("whale",1,true) or nm:find("weather",1,true) or nm:find("event",1,true) then
            local en = "?"; pcall(function() en = tostring(sg.Enabled) end)
            print("[WW-GUI-SG] ScreenGui: "..tostring(sg.Name).." enabled="..en)
            -- dump semua descendants dengan text
            pcall(function()
                for _, d in ipairs(sg:GetDescendants()) do
                    local t = ""; pcall(function() t = tostring(d.Text) end)
                    if #t > 0 then
                        print("  > "..tostring(d.Name).." ["..d.ClassName..'] text="'..t..'"')
                    end
                end
            end)
        end
    end
end

-- =====================================================
-- BAGIAN 2: Scan Workspace.Interaction untuk WeatherTimer
-- (pola dari AnubisWeatherTimer)
-- =====================================================
local function scanWSInteraction()
    print("[WW-WS] === Scan Workspace.Interaction untuk WeatherTimer ===")
    local interaction = WS:FindFirstChild("Interaction")
    if not interaction then print("[WW-WS] Workspace.Interaction tidak ada"); return end

    for _, child in ipairs(interaction:GetChildren()) do
        local nm = tostring(child.Name):lower()
        if nm:find("whale",1,true) or nm:find("water",1,true)
           or nm:find("weather",1,true) or nm:find("timer",1,true) then
            print("[WW-WS] ketemu: "..tostring(child.Name))
            -- dump descendants untuk cari timer text
            pcall(function()
                for _, d in ipairs(child:GetDescendants()) do
                    local t = ""; pcall(function() t = tostring(d.Text) end)
                    if #t > 0 then
                        print("  > "..tostring(d:GetFullName())..' text="'..t..'"')
                    end
                    -- cek atribut timer
                    local ok, attrs = pcall(function() return d:GetAttributes() end)
                    if ok then
                        for k, v in pairs(attrs) do
                            print("  > ATTR "..tostring(d.Name).."."..tostring(k).."="..tostring(v))
                        end
                    end
                end
            end)
        end
    end

    -- juga print semua child Interaction yang belum kita kenal
    print("[WW-WS] Semua child Workspace.Interaction:")
    for _, child in ipairs(interaction:GetChildren()) do
        print("  - "..tostring(child.Name).." ["..tostring(child.ClassName).."]")
    end
end

-- =====================================================
-- BAGIAN 3: Cari BillboardGui berteks "Whale" / "Water"
-- =====================================================
local function scanBillboard()
    print("[WW-BB] === Scan BillboardGui di Workspace ===")
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("BillboardGui") then
            local tx = ""
            pcall(function()
                for _, c in ipairs(obj:GetDescendants()) do
                    local t = ""; pcall(function() t = tostring(c.Text) end)
                    if #t > 0 then tx = tx..t.." | " end
                end
            end)
            local txl = tx:lower()
            if txl:find("whale",1,true) or txl:find("water",1,true)
               or txl:find("weather",1,true) or txl:find("until",1,true) then
                print("[WW-BB] "..tostring(obj:GetFullName())..' text="'..tx..'"')
            end
        end
    end
end

-- =====================================================
-- BAGIAN 4: Scan Event_Notification di RS
-- =====================================================
local function scanRS()
    print("[WW-RS] === Scan ReplicatedStorage Event_Notification ===")
    local en = RS:FindFirstChild("Event_Notification")
    if not en then print("[WW-RS] Event_Notification tidak ada"); return end

    -- atribut
    local ok, attrs = pcall(function() return en:GetAttributes() end)
    if ok then
        for k, v in pairs(attrs) do
            print("[WW-RS-ATTR] "..tostring(k).."="..tostring(v))
        end
    end

    -- children
    for _, c in ipairs(en:GetChildren()) do
        local val = ""; pcall(function() val = tostring(c.Value) end)
        print("[WW-RS-CHILD] "..tostring(c.Name).." ["..c.ClassName.."] = "..val)
    end
end

-- =====================================================
-- RUN SCAN
-- =====================================================
print("=== DEBUG WHALE WATERS v2.0 @ "..os.date("%H:%M:%S").." ===")
scanGuiCountdown()
print("")
scanWSInteraction()
print("")
scanBillboard()
print("")
scanRS()

-- =====================================================
-- MONITOR: Poll tiap 3s untuk perubahan countdown
-- =====================================================
print("\n[WW] === MONITOR LOOP (poll 3s) ===")
print("[WW] Jalankan saat Whale Waters countdown aktif!")

local function getCountdownText()
    local result = {}
    -- cek semua TextLabel di PlayerGui
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return result end
    for _, gui in ipairs(pg:GetDescendants()) do
        local ok, tx = pcall(function() return tostring(gui.Text) end)
        if ok and #tx > 0 and #tx < 120 then
            local txl = tx:lower()
            if txl:find("whale",1,true) or txl:find("water",1,true)
               or (txl:find("until",1,true) and txl:find("end",1,true))
               or txl:find("weather ends",1,true) then
                table.insert(result, tostring(gui:GetFullName())..'="'..tx..'"')
            end
        end
    end
    -- cek Workspace.Interaction BillboardGui
    local interaction = WS:FindFirstChild("Interaction")
    if interaction then
        for _, obj in ipairs(interaction:GetDescendants()) do
            if obj:IsA("BillboardGui") then
                for _, c in ipairs(obj:GetDescendants()) do
                    local ok2, tx2 = pcall(function() return tostring(c.Text) end)
                    if ok2 and #tx2 > 0 then
                        local txl2 = tx2:lower()
                        if txl2:find("whale",1,true) or txl2:find("water",1,true) then
                            table.insert(result, tostring(obj:GetFullName())..'="'..tx2..'"')
                        end
                    end
                end
            end
        end
    end
    return result
end

local lastResults = {}
task.spawn(function()
    while true do
        task.wait(3)
        local cur = getCountdownText()
        -- bandingkan
        local curStr = table.concat(cur, " | ")
        local lastStr = table.concat(lastResults, " | ")
        if curStr ~= lastStr then
            if #cur > 0 then
                print("[WW-TICK @ "..os.date("%H:%M:%S").."] "..curStr)
            end
            lastResults = cur
        end
    end
end)

-- ChildAdded WS — tangkap kapan Whale/WeatherVisuals spawn
WS.ChildAdded:Connect(function(c)
    local nm = tostring(c.Name):lower()
    if nm:find("whale",1,true) or nm:find("water",1,true) or nm:find("weather",1,true)
       or nm:find("kelp",1,true) or nm:find("clam",1,true) then
        print("[WW-SPAWN @ "..os.date("%H:%M:%S").."] ChildAdded WS: "..tostring(c.Name))
        pcall(function()
            for k, v in pairs(c:GetAttributes()) do
                print("  ATTR "..tostring(k).."="..tostring(v))
            end
            for _, ch in ipairs(c:GetChildren()) do
                local val = ""; pcall(function() val = tostring(ch.Value) end)
                print("  CHILD "..tostring(ch.Name).." ["..ch.ClassName.."] = "..val)
            end
        end)
        -- dump descendants TextLabel
        pcall(function()
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextBox") then
                    local t = ""; pcall(function() t = tostring(d.Text) end)
                    if #t > 0 then print("  TEXT "..tostring(d.Name)..'="'..t..'"') end
                end
            end
        end)
    end
end)

-- listener ScreenGui baru di PlayerGui (kalau ada WhaleWatersUI yang muncul)
local pg2 = plr:FindFirstChild("PlayerGui")
if pg2 then
    pg2.ChildAdded:Connect(function(c)
        local nm = tostring(c.Name):lower()
        if nm:find("whale",1,true) or nm:find("water",1,true) or nm:find("weather",1,true) then
            print("[WW-GUI-NEW @ "..os.date("%H:%M:%S").."] ScreenGui baru: "..tostring(c.Name))
            pcall(function()
                for _, d in ipairs(c:GetDescendants()) do
                    local t = ""; pcall(function() t = tostring(d.Text) end)
                    if #t > 0 then print("  "..tostring(d.Name)..'="'..t..'"') end
                end
            end)
        end
    end)
end

print("[WW] listener aktif. Jalankan saat Whale Waters countdown keliatan di layar!")
print("[WW] Countdown akan muncul di output setiap 3 detik kalau ketemu.")
