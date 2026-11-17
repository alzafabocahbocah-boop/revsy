-- ============================================================
-- DEBUG COCONUT KG v0.3
-- Cek WeightMulti buah coconut + auto-collect < threshold + auto-sell
-- WeightMulti adalah multiplier berat buah (dari FRUIT_NON_MUTATIONS uplevelnew)
-- ============================================================
local plr = game.Players.LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local CS  = game:GetService("CollectionService")

-- ── RemoteEvents ─────────────────────────────────────────
local gameEvents = RS:WaitForChild("GameEvents", 10)
local _cropsRE, _sellRE = nil, nil

local function getCropsRE()
    if _cropsRE then return _cropsRE end
    if not gameEvents then return nil end
    local crops = gameEvents:FindFirstChild("Crops")
    _cropsRE = crops and crops:FindFirstChild("Collect")
    return _cropsRE
end

local function getSellRE()
    if _sellRE then return _sellRE end
    if not gameEvents then return nil end
    _sellRE = gameEvents:FindFirstChild("Sell_Inventory")
    return _sellRE
end

-- ── cari farm sendiri ─────────────────────────────────────
local _myFarm = nil
local function getMyFarm()
    if _myFarm and _myFarm.Parent then return _myFarm end
    local farmWS = workspace:FindFirstChild("Farm")
    if not farmWS then return nil end
    for _, sf in ipairs(farmWS:GetChildren()) do
        local found = false
        pcall(function()
            if sf.Name == plr.Name then found = true; return end
            -- cek Important/Data/Owner
            local imp  = sf:FindFirstChild("Important")
            local data = imp and imp:FindFirstChild("Data")
            local own  = data and data:FindFirstChild("Owner")
            if own and own.Value == plr.Name then found = true; return end
            -- fallback Sign
            local sign = sf:FindFirstChild("Sign") or sf:FindFirstChild("Sign", true)
            local owner = sign and sign:GetAttribute("_owner")
            if owner == plr.Name then found = true end
        end)
        if found then _myFarm = sf; return sf end
    end
    return nil
end

-- ── cari Plants_Physical ──────────────────────────────────
local function getMyPP()
    local farm = getMyFarm()
    if not farm then return nil, "Farm sendiri tidak ketemu" end
    -- coba Important/Plants_Physical dulu (sama seperti uplevelnew)
    local imp = farm:FindFirstChild("Important")
    if imp then
        local pp = imp:FindFirstChild("Plants_Physical")
        if pp then return pp, nil end
    end
    -- fallback scan descendants
    for _, desc in ipairs(farm:GetDescendants()) do
        if desc.Name == "Plants_Physical" then return desc, nil end
    end
    return nil, "Plants_Physical tidak ditemukan"
end

-- ── SCAN coconut dari Plants_Physical ────────────────────
local function scanCoconutKg()
    local pp, err = getMyPP()
    if not pp then return nil, err end

    local results = {}
    for _, tree in ipairs(pp:GetChildren()) do
        if tree:IsA("Model") then
            local nm = tree.Name:lower()
            if nm:find("coconut", 1, true) or nm:find("cocon", 1, true) then
                local fruits = tree:FindFirstChild("Fruits")
                local buahList = {}
                local wTotal = 0

                if fruits then
                    for _, buah in ipairs(fruits:GetChildren()) do
                        local attrs = {}
                        pcall(function()
                            local a = buah:GetAttributes()
                            for k,v in pairs(a) do attrs[k]=v end
                        end)
                        local wm = tonumber(attrs["WeightMulti"]) or tonumber(attrs["weightmulti"])
                        -- cek juga semua attr numerik kalau WeightMulti nil
                        if not wm then
                            for k, v in pairs(attrs) do
                                if tonumber(v) and not (v == true or v == false) then
                                    wm = tonumber(v)
                                    break
                                end
                            end
                        end
                        if wm then wTotal += wm end
                        table.insert(buahList, {
                            name   = buah.Name,
                            wm     = wm,
                            nightmare = attrs["Nightmare"] == true,
                            allAttrs  = attrs,
                        })
                    end
                end

                table.insert(results, {
                    treeName  = tree.Name,
                    buahCount = #buahList,
                    buahList  = buahList,
                    wTotal    = wTotal,
                    hasFruits = fruits ~= nil,
                })
            end
        end
    end

    return results, nil
end

-- ── collect coconut dengan WeightMulti < threshold ───────
local KG_THRESHOLD = 75  -- default

local _autoRunning  = false
local _autoThread   = nil
local _collectCount = 0
local _sellCount    = 0

local _guiLog = nil  -- di-set setelah GUI siap

local function logMsg(msg)
    print("[COCON] " .. msg)
    if _guiLog then _guiLog(msg) end
end

local function doSell()
    local re = getSellRE()
    if not re then logMsg("⚠ Sell_Inventory RE tidak ada"); return false end
    local ok, err = pcall(function() re:FireServer() end)
    if ok then
        _sellCount += 1
        logMsg("💰 sell fired (" .. _sellCount .. "x)")
        return true
    else
        logMsg("ERR sell: " .. tostring(err))
        return false
    end
end

local function collectCoconutBelow(threshold)
    local re = getCropsRE()
    if not re then logMsg("⚠ Crops.Collect RE tidak ada"); return 0 end

    local myFarm = getMyFarm()
    if not myFarm then logMsg("⚠ Farm sendiri tidak ada"); return 0 end

    local farmWS = workspace:FindFirstChild("Farm")
    local toCollect = {}

    for _, fruit in ipairs(CS:GetTagged("Harvestable")) do
        -- cek di farm sendiri
        local inMyFarm = fruit:IsDescendantOf(myFarm)
        if not inMyFarm and farmWS then
            local p = fruit.Parent
            while p and p ~= farmWS and p ~= workspace do p = p.Parent end
            if p == farmWS then
                local sf = fruit
                while sf and sf.Parent ~= farmWS do sf = sf.Parent end
                if sf then
                    local imp = sf:FindFirstChild("Important")
                    local d   = imp and imp:FindFirstChild("Data")
                    local own = d and d:FindFirstChild("Owner")
                    if own and own.Value == plr.Name then inMyFarm = true end
                end
            end
        end

        if inMyFarm then
            -- cek coconut: cek parent chain sampai ketemu nama pohon
            local isCoconut = false
            local p2 = fruit
            local depth = 0
            while p2 and depth < 6 do
                local n = p2.Name:lower()
                if n:find("coconut",1,true) or n:find("cocon",1,true) then
                    isCoconut = true; break
                end
                p2 = p2.Parent; depth += 1
            end

            if isCoconut then
                -- baca WeightMulti
                local wm = nil
                pcall(function()
                    local a = fruit:GetAttributes()
                    wm = tonumber(a["WeightMulti"]) or tonumber(a["weightmulti"])
                    if not wm then
                        for k, v in pairs(a) do
                            if tonumber(v) and v ~= true and v ~= false then
                                wm = tonumber(v); break
                            end
                        end
                    end
                end)
                -- collect kalau wm nil (tidak tau nilainya, collect aja) ATAU wm < threshold
                if wm == nil or wm < threshold then
                    table.insert(toCollect, fruit)
                end
            end
        end
    end

    if #toCollect == 0 then
        logMsg("tidak ada coconut < " .. threshold .. " WeightMulti")
        return 0
    end

    logMsg("collect " .. #toCollect .. " coconut (WM<" .. threshold .. ")...")

    local collected = 0
    local i = 1
    while i <= #toCollect do
        local batch = {}
        for j = i, math.min(i+39, #toCollect) do
            if toCollect[j] then batch[#batch+1] = toCollect[j] end
        end
        if #batch > 0 then
            local ok, err = pcall(function() re:FireServer(batch) end)
            if ok then collected += #batch
            else logMsg("ERR fire: " .. tostring(err)) end
        end
        i = i + 40
    end

    _collectCount += collected
    logMsg("✅ collected " .. collected .. "/" .. #toCollect)
    return collected
end

local function startAutoCollect(threshold, interval)
    if _autoRunning then return end
    _autoRunning = true
    _autoThread = task.spawn(function()
        logMsg("🔄 auto ON — WM<" .. threshold .. ", interval " .. interval .. "s")
        while _autoRunning do
            pcall(function() collectCoconutBelow(threshold) end)
            pcall(doSell)
            task.wait(interval)
        end
        logMsg("🛑 auto-collect STOP")
    end)
end

local function stopAutoCollect()
    _autoRunning = false
    if _autoThread then pcall(function() task.cancel(_autoThread) end); _autoThread = nil end
end

-- ── GUI ──────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgCoconutKg"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 510)
frame.Position = UDim2.new(0, 10, 0.5, -255)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local strokeMain = Instance.new("UIStroke", frame)
strokeMain.Color = Color3.fromRGB(255, 180, 50); strokeMain.Thickness = 1.5

-- title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28); title.BackgroundColor3 = Color3.fromRGB(30, 20, 5)
title.BorderSizePixel = 0; title.Text = "🥥 Coconut — WeightMulti + Auto Collect + Sell"
title.TextColor3 = Color3.fromRGB(255, 200, 80); title.TextSize = 10
title.Font = Enum.Font.GothamBold; title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- row 1: threshold + scan
local row1 = Instance.new("Frame")
row1.Size = UDim2.new(1,-8,0,24); row1.Position = UDim2.new(0,4,0,30)
row1.BackgroundTransparency = 1; row1.Parent = frame

local function mkLbl(parent, txt, x, w, col)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0,w,1,0); l.Position = UDim2.new(0,x,0,0)
    l.BackgroundTransparency = 1; l.Text = txt
    l.TextColor3 = col or Color3.fromRGB(220,190,100)
    l.TextSize = 10; l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = parent
    return l
end

mkLbl(row1, "WeightMulti <", 0, 90)
local threshBox = Instance.new("TextBox")
threshBox.Size = UDim2.new(0,50,1,-2); threshBox.Position = UDim2.new(0,92,0,1)
threshBox.BackgroundColor3 = Color3.fromRGB(20,15,5); threshBox.BorderSizePixel = 0
threshBox.Text = tostring(KG_THRESHOLD); threshBox.TextColor3 = Color3.fromRGB(255,230,100)
threshBox.TextSize = 11; threshBox.Font = Enum.Font.GothamBold; threshBox.Parent = row1
Instance.new("UICorner", threshBox).CornerRadius = UDim.new(0,4)
Instance.new("UIStroke", threshBox).Color = Color3.fromRGB(180,130,30)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0,76,1,-2); scanBtn.Position = UDim2.new(0,148,0,1)
scanBtn.BackgroundColor3 = Color3.fromRGB(50,35,10); scanBtn.BorderSizePixel = 0
scanBtn.Text = "▶ SCAN"; scanBtn.TextColor3 = Color3.fromRGB(255,210,100)
scanBtn.TextSize = 10; scanBtn.Font = Enum.Font.GothamBold; scanBtn.Parent = row1
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0,4)

-- row 2: auto btn + stop + stat
local row2 = Instance.new("Frame")
row2.Size = UDim2.new(1,-8,0,26); row2.Position = UDim2.new(0,4,0,56)
row2.BackgroundTransparency = 1; row2.Parent = frame

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0,138,1,-2); autoBtn.Position = UDim2.new(0,0,0,1)
autoBtn.BackgroundColor3 = Color3.fromRGB(15,40,15); autoBtn.BorderSizePixel = 0
autoBtn.Text = "▶ START AUTO COLLECT"; autoBtn.TextColor3 = Color3.fromRGB(100,240,120)
autoBtn.TextSize = 10; autoBtn.Font = Enum.Font.GothamBold; autoBtn.Parent = row2
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0,4)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0,66,1,-2); stopBtn.Position = UDim2.new(0,142,0,1)
stopBtn.BackgroundColor3 = Color3.fromRGB(40,10,10); stopBtn.BorderSizePixel = 0
stopBtn.Text = "■ STOP"; stopBtn.TextColor3 = Color3.fromRGB(255,100,100)
stopBtn.TextSize = 10; stopBtn.Font = Enum.Font.GothamBold; stopBtn.Parent = row2
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0,4)

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(0,120,1,-2); statLbl.Position = UDim2.new(0,214,0,1)
statLbl.BackgroundColor3 = Color3.fromRGB(14,20,8); statLbl.BorderSizePixel = 0
statLbl.Text = "col:0 sell:0"; statLbl.TextColor3 = Color3.fromRGB(180,255,180)
statLbl.TextSize = 10; statLbl.Font = Enum.Font.GothamBold; statLbl.Parent = row2
Instance.new("UICorner", statLbl).CornerRadius = UDim.new(0,4)

-- sumBar
local sumBar = Instance.new("TextLabel")
sumBar.Size = UDim2.new(1,-8,0,20); sumBar.Position = UDim2.new(0,4,0,85)
sumBar.BackgroundColor3 = Color3.fromRGB(24,18,5); sumBar.BorderSizePixel = 0
sumBar.Text = "tekan SCAN untuk lihat pohon coconut"
sumBar.TextColor3 = Color3.fromRGB(255,220,120); sumBar.TextSize = 10
sumBar.Font = Enum.Font.GothamBold; sumBar.Parent = frame
Instance.new("UICorner", sumBar).CornerRadius = UDim.new(0,4)

-- divider info pohon
local function mkDiv(parent, txt, y, bgCol, textCol)
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1,-8,0,14); d.Position = UDim2.new(0,4,0,y)
    d.BackgroundColor3 = bgCol or Color3.fromRGB(18,14,4); d.BorderSizePixel = 0
    d.Text = txt; d.TextColor3 = textCol or Color3.fromRGB(150,120,50)
    d.TextSize = 9; d.Font = Enum.Font.Code
    d.TextXAlignment = Enum.TextXAlignment.Left; d.Parent = parent
    local p = Instance.new("UIPadding",d); p.PaddingLeft = UDim.new(0,4)
    return d
end
mkDiv(frame, "── Info Pohon (WeightMulti) ───────────────────", 107)

local scrollScan = Instance.new("ScrollingFrame")
scrollScan.Size = UDim2.new(1,-8,0,175); scrollScan.Position = UDim2.new(0,4,0,122)
scrollScan.BackgroundTransparency = 1; scrollScan.BorderSizePixel = 0
scrollScan.ScrollBarThickness = 3; scrollScan.CanvasSize = UDim2.new(0,0,0,0)
scrollScan.AutomaticCanvasSize = Enum.AutomaticSize.Y; scrollScan.Parent = frame
local layoutScan = Instance.new("UIListLayout",scrollScan)
layoutScan.SortOrder = Enum.SortOrder.LayoutOrder; layoutScan.Padding = UDim.new(0,2)

mkDiv(frame, "── Log ────────────────────────────────────────", 300, Color3.fromRGB(8,18,8), Color3.fromRGB(80,160,80))

local scrollLog = Instance.new("ScrollingFrame")
scrollLog.Size = UDim2.new(1,-8,0,170); scrollLog.Position = UDim2.new(0,4,0,315)
scrollLog.BackgroundTransparency = 1; scrollLog.BorderSizePixel = 0
scrollLog.ScrollBarThickness = 3; scrollLog.CanvasSize = UDim2.new(0,0,0,0)
scrollLog.AutomaticCanvasSize = Enum.AutomaticSize.Y; scrollLog.Parent = frame
local layoutLog = Instance.new("UIListLayout",scrollLog)
layoutLog.SortOrder = Enum.SortOrder.LayoutOrder; layoutLog.Padding = UDim.new(0,1)

-- helper rows
local scanOrder, logOrder = 0, 0

local function clearScanRows()
    for _, c in ipairs(scrollScan:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end; scanOrder = 0
end

local function addScanRow(txt, col, bg, bold)
    scanOrder += 1
    local r = Instance.new("TextLabel")
    r.Size = UDim2.new(1,-6,0,18); r.BackgroundColor3 = bg or Color3.fromRGB(14,10,2)
    r.BackgroundTransparency = bg and 0 or 0.5; r.BorderSizePixel = 0
    r.TextColor3 = col or Color3.fromRGB(220,200,150); r.TextSize = 10
    r.Font = bold and Enum.Font.GothamBold or Enum.Font.Code
    r.TextXAlignment = Enum.TextXAlignment.Left; r.TextWrapped = false; r.Text = txt
    r.LayoutOrder = scanOrder; r.Parent = scrollScan
    local p = Instance.new("UIPadding",r); p.PaddingLeft = UDim.new(0,4)
    Instance.new("UICorner",r).CornerRadius = UDim.new(0,3)
end

local function addLogRow(txt, col)
    logOrder += 1
    local r = Instance.new("TextLabel")
    r.Size = UDim2.new(1,-6,0,16); r.BackgroundTransparency = 1; r.BorderSizePixel = 0
    r.TextColor3 = col or Color3.fromRGB(180,240,180); r.TextSize = 10; r.Font = Enum.Font.Code
    r.TextXAlignment = Enum.TextXAlignment.Left; r.TextWrapped = false; r.Text = txt
    r.LayoutOrder = logOrder; r.Parent = scrollLog
    local p = Instance.new("UIPadding",r); p.PaddingLeft = UDim.new(0,4)
    task.defer(function() scrollLog.CanvasPosition = Vector2.new(0, math.huge) end)
end

-- set guiLog setelah GUI siap
_guiLog = function(msg)
    local col = Color3.fromRGB(180,240,180)
    if msg:find("✅") then col = Color3.fromRGB(100,255,100) end
    if msg:find("💰") then col = Color3.fromRGB(255,220,80) end
    if msg:find("⚠") or msg:find("ERR") then col = Color3.fromRGB(255,160,80) end
    if msg:find("🔄") then col = Color3.fromRGB(100,200,255) end
    if msg:find("🛑") then col = Color3.fromRGB(255,100,100) end
    addLogRow(msg, col)
    statLbl.Text = "col:" .. _collectCount .. " sell:" .. _sellCount
end

-- SCAN
scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "..."; clearScanRows()
    sumBar.Text = "scanning..."; sumBar.TextColor3 = Color3.fromRGB(255,220,120)

    task.spawn(function()
        local res, err = scanCoconutKg()
        if not res then
            sumBar.Text = "ERROR: " .. tostring(err)
            sumBar.TextColor3 = Color3.fromRGB(255,100,100)
            addScanRow(tostring(err), Color3.fromRGB(255,100,100))
            scanBtn.Text = "▶ SCAN"; return
        end

        if #res == 0 then
            sumBar.Text = "⚠ Tidak ada pohon coconut ditemukan!"
            sumBar.TextColor3 = Color3.fromRGB(255,150,50)
            addScanRow("Pohon coconut tidak ada (cari nama berisi 'coconut'/'cocon')", Color3.fromRGB(255,150,50))
            scanBtn.Text = "▶ SCAN"; return
        end

        local thresh = tonumber(threshBox.Text) or KG_THRESHOLD
        local totalPohon = #res
        local totalBuah, totalWM = 0, 0
        for _, r in ipairs(res) do
            totalBuah += r.buahCount
            totalWM   += r.wTotal
        end
        local avgWM = totalBuah > 0 and (totalWM/totalBuah) or 0

        sumBar.Text = string.format("🥥 %d pohon | %d buah | WM avg=%.1f | total WM=%.1f",
            totalPohon, totalBuah, avgWM, totalWM)
        sumBar.TextColor3 = Color3.fromRGB(255,220,100)

        for i, r in ipairs(res) do
            local avgR = r.buahCount > 0 and (r.wTotal/r.buahCount) or 0
            addScanRow(string.format("🌴 Pohon #%d: %s", i, r.treeName),
                Color3.fromRGB(255,210,80), Color3.fromRGB(28,20,5), true)
            addScanRow(string.format("   buah=%d | WM avg=%.1f | WM total=%.1f",
                r.buahCount, avgR, r.wTotal),
                Color3.fromRGB(220,200,140), Color3.fromRGB(18,14,4))

            if not r.hasFruits then
                addScanRow("   ⚠ tidak ada folder Fruits", Color3.fromRGB(255,150,50), Color3.fromRGB(20,12,4))
            elseif r.buahCount == 0 then
                addScanRow("   ⚠ Fruits kosong", Color3.fromRGB(255,150,50), Color3.fromRGB(20,12,4))
            else
                -- dump semua attribute dari buah pertama
                local b0 = r.buahList[1]
                if b0 then
                    local attrStrs = {}
                    for k, v in pairs(b0.allAttrs) do
                        table.insert(attrStrs, k.."="..tostring(v))
                    end
                    if #attrStrs > 0 then
                        addScanRow("   [attrs buah1] " .. table.concat(attrStrs, " | "),
                            Color3.fromRGB(100,180,255), Color3.fromRGB(10,12,20))
                    else
                        addScanRow("   ⚠ buah1 tidak punya attribute apapun",
                            Color3.fromRGB(255,150,50))
                    end
                end
                -- list buah (max 4)
                local shown = 0
                for _, buah in ipairs(r.buahList) do
                    if shown >= 4 then
                        addScanRow(string.format("   ...+%d buah lagi", r.buahCount-shown),
                            Color3.fromRGB(150,150,150)); break
                    end
                    local wmTxt  = buah.wm and string.format("WM=%.1f", buah.wm) or "WM=(?)"
                    local nmMark = buah.nightmare and " 💀NM" or ""
                    local below  = buah.wm and buah.wm < thresh
                    local mark   = below and " ← collect" or ""
                    local col    = below and Color3.fromRGB(255,180,60)
                                or (buah.wm and Color3.fromRGB(180,240,160) or Color3.fromRGB(200,200,200))
                    addScanRow(string.format("   • %s — %s%s%s", buah.name, wmTxt, nmMark, mark),
                        col, Color3.fromRGB(14,18,10))
                    shown += 1
                end
            end
        end

        -- console
        print("[COCONUT] ===== SCAN =====")
        print(string.format("[COCONUT] %d pohon, %d buah, WM avg=%.1f", totalPohon, totalBuah, avgWM))
        for _, r in ipairs(res) do
            for _, b in ipairs(r.buahList) do
                local attrArr = {}
                for k,v in pairs(b.allAttrs) do table.insert(attrArr, k.."="..tostring(v)) end
                print(string.format("[COCONUT] %s / %s — WM=%s attrs: %s",
                    r.treeName, b.name, tostring(b.wm), table.concat(attrArr," | ")))
            end
        end

        scanBtn.Text = "▶ SCAN"
    end)
end)

-- START AUTO
autoBtn.MouseButton1Click:Connect(function()
    if _autoRunning then logMsg("⚠ sudah jalan"); return end
    local thresh = tonumber(threshBox.Text) or KG_THRESHOLD
    KG_THRESHOLD = thresh
    autoBtn.BackgroundColor3 = Color3.fromRGB(8,50,8)
    autoBtn.Text = "🔄 AUTO ON"
    autoBtn.TextColor3 = Color3.fromRGB(80,255,100)
    strokeMain.Color = Color3.fromRGB(80,255,100)
    startAutoCollect(thresh, 5)
end)

-- STOP
stopBtn.MouseButton1Click:Connect(function()
    stopAutoCollect()
    autoBtn.BackgroundColor3 = Color3.fromRGB(15,40,15)
    autoBtn.Text = "▶ START AUTO COLLECT"
    autoBtn.TextColor3 = Color3.fromRGB(100,240,120)
    strokeMain.Color = Color3.fromRGB(255,180,50)
    logMsg("🛑 dihentikan manual")
end)

-- refresh stat
task.spawn(function()
    while true do
        task.wait(1)
        statLbl.Text = "col:" .. _collectCount .. " sell:" .. _sellCount
        if _autoRunning then autoBtn.Text = "🔄 AUTO ON" end
    end
end)

print("[COCONUT] debug_coconut_kg v0.3 — panel kuning, WeightMulti threshold default 75")
