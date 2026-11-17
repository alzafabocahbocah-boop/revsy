-- ============================================================
-- DEBUG WHALE WEATHER v1.0
-- Cari di mana "Whale Waters" weather/event disimpan di game
-- Dump semua candidates: ReplicatedStorage, workspace, LocalPlayer
-- ============================================================
local plr = game.Players.LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local CS  = game:GetService("CollectionService")

local _lines = {}
local function log(s) table.insert(_lines, s) print("[WW] "..s) end

local function scanForWhale(obj, path, depth)
    if depth <= 0 or not obj then return end
    local ok, children = pcall(function() return obj:GetChildren() end)
    if not ok then return end
    for _, c in ipairs(children) do
        local nm = tostring(c.Name)
        local cn = tostring(c.ClassName)
        local nmL = nm:lower()
        -- cek nama / value mengandung "whale" atau "weather" atau "event" atau "mutation"
        local interesting = nmL:find("whale",1,true)
            or nmL:find("weather",1,true)
            or nmL:find("event",1,true)
            or nmL:find("mutation",1,true)
            or nmL:find("drenched",1,true)
            or nmL:find("active",1,true)
            or nmL:find("season",1,true)
            or nmL:find("effect",1,true)

        -- cek value kalau StringValue/BoolValue
        local valStr = ""
        pcall(function()
            if c:IsA("StringValue") or c:IsA("BoolValue") or c:IsA("NumberValue") or c:IsA("IntValue") then
                local v = tostring(c.Value):lower()
                if v:find("whale",1,true) or v:find("weather",1,true) or v:find("drenched",1,true) then
                    interesting = true
                end
                valStr = " = "..tostring(c.Value)
            end
        end)

        if interesting then
            log(path.."/"..nm.." ["..cn.."]"..valStr)
            -- dump atribut juga
            pcall(function()
                local attrs = c:GetAttributes()
                for k, v in pairs(attrs) do
                    local ks = tostring(k):lower()
                    if ks:find("whale",1,true) or ks:find("weather",1,true) or ks:find("active",1,true) then
                        log("  attr: "..k.." = "..tostring(v))
                    end
                end
            end)
        end

        scanForWhale(c, path.."/"..nm, depth - 1)
    end
end

local function scanAttrsForWhale(obj, path)
    pcall(function()
        local attrs = obj:GetAttributes()
        for k, v in pairs(attrs) do
            local ks = tostring(k):lower()
            local vs = tostring(v):lower()
            if ks:find("whale",1,true) or ks:find("weather",1,true)
               or vs:find("whale",1,true) or vs:find("drenched",1,true) then
                log(path.." attr: "..k.." = "..tostring(v))
            end
        end
    end)
end

local function doScan()
    log("=== WHALE WEATHER DEBUG START ===")

    -- 1. CS tags mengandung "whale" atau "weather"
    log("--- CS:GetTags scan ---")
    local tagTargets = {
        workspace, RS, plr,
        workspace:FindFirstChild("Farm"),
        workspace:FindFirstChild("Weather"),
        workspace:FindFirstChild("Events"),
        workspace:FindFirstChild("Seasons"),
        workspace:FindFirstChild("GameEvents"),
        RS:FindFirstChild("Weather"),
        RS:FindFirstChild("Events"),
        RS:FindFirstChild("GameData"),
        RS:FindFirstChild("Data"),
    }
    for _, obj in ipairs(tagTargets) do
        if obj then
            local ok, tags = pcall(function() return CS:GetTags(obj) end)
            if ok and tags then
                for _, t in ipairs(tags) do
                    if t:lower():find("whale",1,true) or t:lower():find("weather",1,true) then
                        log("CS tag: "..obj.Name.." -> "..t)
                    end
                end
            end
        end
    end

    -- 2. scan workspace children langsung (depth 3) cari "whale"/"weather"
    log("--- workspace scan ---")
    local wsChildren = workspace:GetChildren()
    for _, c in ipairs(wsChildren) do
        local nm = c.Name:lower()
        if nm:find("weather",1,true) or nm:find("event",1,true) or nm:find("season",1,true)
           or nm:find("game",1,true) or nm:find("active",1,true) or nm:find("mutation",1,true) then
            log("WS child: "..c.Name.." ["..c.ClassName.."]")
            scanForWhale(c, "WS/"..c.Name, 3)
            scanAttrsForWhale(c, "WS/"..c.Name)
        end
    end

    -- 3. scan RS depth 3 cari "whale"/"weather"
    log("--- ReplicatedStorage scan ---")
    local rsChildren = RS:GetChildren()
    for _, c in ipairs(rsChildren) do
        local nm = c.Name:lower()
        if nm:find("weather",1,true) or nm:find("event",1,true) or nm:find("season",1,true)
           or nm:find("game",1,true) or nm:find("active",1,true) or nm:find("mutation",1,true) then
            log("RS child: "..c.Name.." ["..c.ClassName.."]")
            scanForWhale(c, "RS/"..c.Name, 3)
            scanAttrsForWhale(c, "RS/"..c.Name)
        end
    end

    -- 4. scan LocalPlayer atribut + children
    log("--- LocalPlayer scan ---")
    scanAttrsForWhale(plr, "plr")
    scanForWhale(plr, "plr", 3)

    -- 5. brute force: semua CS tagged object — cari tag mengandung "whale"/"weather"
    log("--- CS all tags brute force ---")
    local allTagged = {}
    pcall(function()
        -- ambil semua instance dgn CS dan cek tagnya
        local function tryTagged(tag)
            local ok2, list = pcall(function() return CS:GetTagged(tag) end)
            if ok2 and list and #list > 0 then
                log("CS:GetTagged('"..tag.."') -> "..#list.." objects")
                for i, obj in ipairs(list) do
                    if i <= 5 then
                        log("  ["..i.."] "..obj.Name.." path="..obj:GetFullName())
                    end
                end
            end
        end
        tryTagged("WhaleWaters")
        tryTagged("Whale_Waters")
        tryTagged("WhaleWeather")
        tryTagged("WeatherEvent")
        tryTagged("ActiveWeather")
        tryTagged("Weather")
        tryTagged("Drenched")
        tryTagged("WhaleBound")
        tryTagged("Whalebound")
        tryTagged("ActiveEvent")
        tryTagged("GameEvent")
    end)

    -- 6. dump SEMUA nama children workspace (1 level) biar tau struktur game
    log("--- WS children list ---")
    local wsNames = {}
    for _, c in ipairs(workspace:GetChildren()) do
        table.insert(wsNames, c.Name.."["..c.ClassName.."]")
    end
    log(table.concat(wsNames, ", "))

    -- 7. dump SEMUA nama children RS (1 level)
    log("--- RS children list ---")
    local rsNames = {}
    for _, c in ipairs(RS:GetChildren()) do
        table.insert(rsNames, c.Name)
    end
    log(table.concat(rsNames, ", "))

    log("=== SCAN SELESAI — "..#_lines.." baris ===")
end

-- GUI
local sg = Instance.new("ScreenGui")
sg.Name = "WhaleDgb"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,280,0,70)
frame.Position = UDim2.new(0,10,0,100)
frame.BackgroundColor3 = Color3.fromRGB(5,15,30)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(50,180,255)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1,0,0,22); ttl.BackgroundColor3 = Color3.fromRGB(5,20,40)
ttl.BorderSizePixel = 0; ttl.Text = "🐋 DEBUG WHALE WEATHER"
ttl.TextColor3 = Color3.fromRGB(50,200,255); ttl.TextSize = 10
ttl.Font = Enum.Font.GothamBold; ttl.Parent = frame
Instance.new("UICorner", ttl).CornerRadius = UDim.new(0,8)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0,120,0,26); scanBtn.Position = UDim2.new(0,4,0,26)
scanBtn.BackgroundColor3 = Color3.fromRGB(10,30,55); scanBtn.BorderSizePixel = 0
scanBtn.Text = "▶ SCAN"; scanBtn.TextColor3 = Color3.fromRGB(50,200,255)
scanBtn.TextSize = 11; scanBtn.Font = Enum.Font.GothamBold; scanBtn.Parent = frame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0,4)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0,120,0,26); copyBtn.Position = UDim2.new(0,138,0,26)
copyBtn.BackgroundColor3 = Color3.fromRGB(15,15,35); copyBtn.BorderSizePixel = 0
copyBtn.Text = "📋 Copy Log"; copyBtn.TextColor3 = Color3.fromRGB(160,180,255)
copyBtn.TextSize = 11; copyBtn.Font = Enum.Font.GothamBold; copyBtn.Parent = frame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,4)

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(1,-8,0,16); statLbl.Position = UDim2.new(0,4,0,52)
statLbl.BackgroundTransparency = 1; statLbl.Text = "belum scan"
statLbl.TextColor3 = Color3.fromRGB(120,120,120); statLbl.TextSize = 9
statLbl.Font = Enum.Font.Code; statLbl.Parent = frame

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "scanning..."; _lines = {}
    task.spawn(function()
        pcall(doScan)
        scanBtn.Text = "▶ SCAN"
        statLbl.Text = "✅ done — "..(#_lines).." baris"
        statLbl.TextColor3 = Color3.fromRGB(100,255,100)
    end)
end)

copyBtn.MouseButton1Click:Connect(function()
    if #_lines == 0 then
        copyBtn.Text = "⚠ scan dulu!"; task.delay(2, function() copyBtn.Text = "📋 Copy Log" end); return
    end
    local txt = table.concat(_lines, "\n")
    local ok = pcall(function() setclipboard(txt) end)
    if ok then
        copyBtn.Text = "✅ Copied! ("..(#_lines)..")"
    else
        print("[WW LOG]===START===")
        for _, l in ipairs(_lines) do print(l) end
        print("[WW LOG]===END===")
        copyBtn.Text = "⚠ cek console"
    end
    task.delay(3, function() copyBtn.Text = "📋 Copy Log" end)
end)

print("[WW DEBUG] loaded — klik SCAN pas Whale Waters aktif, lalu Copy Log")
