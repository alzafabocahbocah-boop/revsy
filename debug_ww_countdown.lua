-- ============================================================
-- DEBUG WHALE WATERS COUNTDOWN v1.0
-- Monitor timer Whale Waters event secara realtime
-- Print kapan mulai, sisa detik, kapan selesai
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local WS = workspace

-- cari sumber countdown — cek beberapa kandidat
local function getWWTimer()
    -- kandidat 1: Event_Notification/Event_String + atribut timer
    local en = RS:FindFirstChild("Event_Notification")
    if en then
        -- cek atribut langsung
        local ok, attrs = pcall(function() return en:GetAttributes() end)
        if ok then
            for k, v in pairs(attrs) do
                if tostring(k):lower():find("time",1,true) or tostring(k):lower():find("timer",1,true)
                   or tostring(k):lower():find("duration",1,true) or tostring(k):lower():find("end",1,true) then
                    print("[WW-ATTR] Event_Notification."..tostring(k).." = "..tostring(v))
                end
            end
        end
        -- cek children
        for _, c in ipairs(en:GetChildren()) do
            local nm = tostring(c.Name):lower()
            print("[WW-EN] "..tostring(c.Name).." ["..c.ClassName.."] = "..tostring(pcall(function() return c.Value end) and c.Value or "?"))
        end
    end

    -- kandidat 2: WeatherClient / WeatherData di RS
    for _, nm in ipairs({"WeatherData","WeatherClient","WeatherService","ActiveWeather","CurrentWeather","EventData","Events"}) do
        local obj = RS:FindFirstChild(nm, true)
        if obj then
            print("[WW-RS] ketemu: "..tostring(obj:GetFullName()))
            pcall(function()
                for _, c in ipairs(obj:GetDescendants()) do
                    local cn = tostring(c.Name):lower()
                    if cn:find("whale",1,true) or cn:find("time",1,true) or cn:find("timer",1,true)
                       or cn:find("end",1,true) or cn:find("active",1,true) or cn:find("duration",1,true) then
                        local val = ""
                        pcall(function() val = tostring(c.Value) end)
                        print("[WW-RS-child] "..tostring(c:GetFullName()).." ["..c.ClassName.."] = "..val)
                    end
                end
            end)
        end
    end

    -- kandidat 3: scan WS atribut
    local ok2, wsAttrs = pcall(function() return WS:GetAttributes() end)
    if ok2 then
        for k, v in pairs(wsAttrs) do
            local ks = tostring(k):lower()
            if ks:find("whale",1,true) or ks:find("weather",1,true) or ks:find("event",1,true)
               or ks:find("time",1,true) or ks:find("timer",1,true) then
                print("[WW-WS-ATTR] WS."..tostring(k).." = "..tostring(v))
            end
        end
    end

    -- kandidat 4: cek GUI player — badge "Whale Waters" biasanya ada di PlayerGui
    local plr = game.Players.LocalPlayer
    pcall(function()
        for _, gui in ipairs(plr.PlayerGui:GetDescendants()) do
            local nm = tostring(gui.Name):lower()
            local tx = ""
            pcall(function() tx = tostring(gui.Text):lower() end)
            if (nm:find("whale",1,true) or nm:find("weather",1,true) or nm:find("event",1,true)
                or tx:find("whale",1,true) or tx:find("2m",1,true)) then
                local fullTx = ""
                pcall(function() fullTx = tostring(gui.Text) end)
                print("[WW-GUI] "..tostring(gui:GetFullName()).." text="..fullTx)
            end
        end
    end)
end

print("[WW] === SCAN AWAL ===")
getWWTimer()

-- monitor loop — print tiap 5s kalau ada perubahan
print("\n[WW] === MONITOR LOOP (tiap 5s) ===")
local lastVal = ""
task.spawn(function()
    while true do
        task.wait(5)
        -- cek Event_String berubah
        local cur = ""
        pcall(function()
            local en = RS:FindFirstChild("Event_Notification")
            if en then
                local es = en:FindFirstChild("Event_String")
                if es then cur = tostring(es.Value) end
            end
        end)
        if cur ~= lastVal then
            print("[WW-CHANGE] Event_String: '"..lastVal.."' -> '"..cur.."'")
            lastVal = cur
        end

        -- cek _G._wwAktif
        local aktif = _G._wwAktif == true
        local flag  = _G._wwActiveFlag == true
        print("[WW-STATUS] aktif="..tostring(aktif).." flag="..tostring(flag).." Event_String='"..cur.."'")
    end
end)

-- ChildAdded WS — tangkap kapan Whale/WeatherVisuals spawn
WS.ChildAdded:Connect(function(c)
    local nm = tostring(c.Name):lower()
    if nm:find("whale",1,true) or nm:find("weather",1,true) or nm:find("kelp",1,true) or nm:find("clam",1,true) then
        print("[WW-SPAWN] ChildAdded WS: "..tostring(c.Name).." @ "..os.date("%H:%M:%S"))
        -- dump atribut object ini
        pcall(function()
            for k, v in pairs(c:GetAttributes()) do
                print("[WW-SPAWN-ATTR] "..tostring(c.Name).."."..tostring(k).." = "..tostring(v))
            end
            for _, ch in ipairs(c:GetChildren()) do
                local val = ""; pcall(function() val = tostring(ch.Value) end)
                print("[WW-SPAWN-CHILD] "..tostring(ch.Name).." ["..ch.ClassName.."] = "..val)
            end
        end)
    end
end)

WS.ChildRemoved:Connect(function(c)
    local nm = tostring(c.Name):lower()
    if nm:find("whale",1,true) or nm:find("weather",1,true) then
        print("[WW-REMOVED] ChildRemoved WS: "..tostring(c.Name).." @ "..os.date("%H:%M:%S"))
    end
end)

print("[WW] listener aktif — tunggu event Whale Waters...")
