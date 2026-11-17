-- ============================================================
-- DEBUG COCONUT KG v0.2
-- Cek kg per buah coconut + auto-collect coconut < 75kg
-- ============================================================
local plr = game.Players.LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local CS  = game:GetService("CollectionService")

-- ── RemoteEvent Crops.Collect ─────────────────────────────
local gameEvents = RS:WaitForChild("GameEvents", 10)
local _cropsRE   = nil
local function getCropsRE()
    if _cropsRE then return _cropsRE end
    if not gameEvents then return nil end
    local crops = gameEvents:FindFirstChild("Crops")
    _cropsRE = crops and crops:FindFirstChild("Collect")
    return _cropsRE
end

-- ── cari farm sendiri ────────────────────────────────────
local _myFarm = nil
local function getMyFarm()
    if _myFarm and _myFarm.Parent then return _myFarm end
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return nil end
    for _, sf in ipairs(farm:GetChildren()) do
        local found = false
        pcall(function()
            if sf.Name == plr.Name then found = true; return end
            local sign = sf:FindFirstChild("Sign") or sf:FindFirstChild("Sign", true)
            local owner = sign and sign:GetAttribute("_owner")
            if owner == plr.Name then found = true end
        end)
        if found then _myFarm = sf; return sf end
    end
    return nil
end

-- ── cari Plants_Physical ─────────────────────────────────
local function getMyPP()
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return nil, "workspace.Farm tidak ada" end
    for _, sf in ipairs(farm:GetChildren()) do
        local found = false
        pcall(function()
            if sf.Name == plr.Name then found = true; return end
            local sign = sf:FindFirstChild("Sign") or sf:FindFirstChild("Sign", true)
            local owner = sign and sign:GetAttribute("_owner")
            if owner == plr.Name then found = true end
        end)
        if found then
            for _, desc in ipairs(sf:GetDescendants()) do
                if desc.Name == "Plants_Physical" then return desc, nil end
            end
            return nil, "Plants_Physical tidak ada di subfarm"
        end
    end
    return nil, "Subfarm sendiri tidak ketemu"
end

-- ── ambil nilai kg dari object ────────────────────────────
local function getKg(obj)
    local keys = { "kg", "KG", "weight", "Weight", "value", "Value",
                   "fruitKg", "FruitKg", "fruit_kg", "amount", "Amount",
                   "size", "Size", "mass", "Mass" }
    for _, k in ipairs(keys) do
        local ok, v = pcall(function() return obj:GetAttribute(k) end)
        if ok and v and tonumber(v) then return tonumber(v), k end
    end
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if ok and attrs then
        for k, v in pairs(attrs) do
            if tonumber(v) then return tonumber(v), k end
        end
    end
    return nil, nil
end

-- ── SCAN khusus COCONUT ──────────────────────────────────
local function scanCoconutKg()
    local pp, err = getMyPP()
    if not pp then return nil, err end

    local results = {}

    for _, tree in ipairs(pp:GetChildren()) do
        if tree:IsA("Model") then
            local nm = tree.Name:lower()
            if nm:find("coconut", 1, true) or nm:find("cocon", 1, true) then
                local fruits = tree:FindFirstChild("Fruits")
                local buahCount = 0
                local kgTotal = 0
                local kgSample = nil
                local attrKey = nil
                local buahList = {}

                if fruits then
                    for _, buah in ipairs(fruits:GetChildren()) do
                        buahCount += 1
                        local kg, key = getKg(buah)
                        if not kg then
                            for _, ch in ipairs(buah:GetChildren()) do
                                local kg2, key2 = getKg(ch)
                                if kg2 then kg, key = kg2, key2; break end
                            end
                        end
                        if kg then
                            kgTotal += kg
                            kgSample = kg
                            attrKey = key
                            table.insert(buahList, { name = buah.Name, kg = kg })
                        else
                            table.insert(buahList, { name = buah.Name, kg = nil })
                        end
                    end
                end

                if buahCount == 0 then
                    local tKg, tKey = getKg(tree)
                    if tKg then kgSample = tKg; kgTotal = tKg; attrKey = tKey end
                end

                table.insert(results, {
                    treeName  = tree.Name,
                    buahCount = buahCount,
                    kgSample  = kgSample,
                    kgTotal   = kgTotal,
                    attrKey   = attrKey or "?",
                    buahList  = buahList,
                    hasFruits = fruits ~= nil,
                })
            end
        end
    end

    return results, nil
end

-- ── AUTO COLLECT COCONUT < threshold ────────────────────
local KG_THRESHOLD = 75  -- default collect kalau kg < 75

local _autoRunning = false
local _collectCount = 0
local _logLines = {}
local MAX_LOG = 50

local function logMsg(msg)
    local ts = os.date("%H:%M:%S")
    local line = ts .. " " .. msg
    table.insert(_logLines, 1, line)
    if #_logLines > MAX_LOG then table.remove(_logLines) end
    print("[COCON] " .. msg)
end

local function collectCoconutBelow(threshold, logFn)
    local re = getCropsRE()
    if not re then logFn("⚠ Crops.Collect RE tidak ditemukan!"); return 0 end

    local myFarm = getMyFarm()
    if not myFarm then logFn("⚠ Farm sendiri tidak ditemukan!"); return 0 end

    -- scan semua buah Harvestable
    local toCollect = {}
    for _, fruit in ipairs(CS:GetTagged("Harvestable")) do
        -- filter: harus di farm sendiri
        local inMyFarm = fruit:IsDescendantOf(myFarm)
        if not inMyFarm then
            -- fallback: cek parent chain manual
            local p = fruit.Parent
            while p and p ~= workspace do
                if p == myFarm then inMyFarm = true; break end
                p = p.Parent
            end
        end
        if inMyFarm then
            -- cek apakah coconut
            local nm = fruit.Name:lower()
            local parentNm = fruit.Parent and fruit.Parent.Name:lower() or ""
            local isCoconut = nm:find("coconut",1,true) or nm:find("cocon",1,true)
                           or parentNm:find("coconut",1,true) or parentNm:find("cocon",1,true)
            -- fallback: cek treeModel di atasnya
            if not isCoconut then
                local p2 = fruit.Parent
                local depth = 0
                while p2 and depth < 5 do
                    if p2.Name:lower():find("coconut",1,true) or p2.Name:lower():find("cocon",1,true) then
                        isCoconut = true; break
                    end
                    p2 = p2.Parent; depth += 1
                end
            end
            if isCoconut then
                -- cek kg
                local kg = getKg(fruit)
                if not kg then
                    -- cek children
                    for _, ch in ipairs(fruit:GetDescendants()) do
                        local kg2 = getKg(ch)
                        if kg2 then kg = kg2; break end
                    end
                end
                local doCollect = (kg == nil) or (kg < threshold)
                if doCollect then
                    table.insert(toCollect, { fruit = fruit, kg = kg })
                end
            end
        end
    end

    if #toCollect == 0 then
        logFn("tidak ada coconut < " .. threshold .. "kg ditemukan")
        return 0
    end

    logFn("collect " .. #toCollect .. " coconut (threshold <" .. threshold .. "kg)...")

    -- kirim batch 40 per FireServer (sama seperti doCollect di uplevelnew)
    local fruitObjs = {}
    for _, t in ipairs(toCollect) do table.insert(fruitObjs, t.fruit) end

    local collected = 0
    local i = 1
    while i <= #fruitObjs do
        local batch = {}
        for j = i, math.min(i + 39, #fruitObjs) do
            if fruitObjs[j] then batch[#batch+1] = fruitObjs[j] end
        end
        if #batch > 0 then
            local ok, err = pcall(function() re:FireServer(batch) end)
            if ok then
                collected += #batch
            else
                logFn("ERR FireServer: " .. tostring(err))
            end
        end
        i = i + 40
    end

    logFn("✅ collected " .. collected .. "/" .. #toCollect .. " coconut")
    _collectCount += collected
    return collected
end

-- ── auto-collect loop ────────────────────────────────────
local _autoThread = nil

local function startAutoCollect(threshold, intervalSec, logFn)
    if _autoRunning then return end
    _autoRunning = true
    _autoThread = task.spawn(function()
        logFn("🔄 auto-collect ON — threshold <" .. threshold .. "kg, interval " .. intervalSec .. "s")
        while _autoRunning do
            pcall(function() collectCoconutBelow(threshold, logFn) end)
            task.wait(intervalSec)
        end
        logFn("🛑 auto-collect STOP")
    end)
end

local function stopAutoCollect()
    _autoRunning = false
    if _autoThread then
        pcall(function() task.cancel(_autoThread) end)
        _autoThread = nil
    end
end

-- ── GUI ──────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgCoconutKg"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 370, 0, 490)
frame.Position = UDim2.new(0, 10, 0.5, -245)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local strokeMain = Instance.new("UIStroke", frame)
strokeMain.Color = Color3.fromRGB(255, 180, 50)
strokeMain.Thickness = 1.5

-- title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(30, 20, 5)
title.BorderSizePixel = 0
title.Text = "🥥 Coconut KG Debug + Auto Collect"
title.TextColor3 = Color3.fromRGB(255, 200, 80)
title.TextSize = 11; title.Font = Enum.Font.GothamBold
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- row: threshold + scan btn
local row1 = Instance.new("Frame")
row1.Size = UDim2.new(1, -8, 0, 24)
row1.Position = UDim2.new(0, 4, 0, 30)
row1.BackgroundTransparency = 1
row1.Parent = frame

local lblThresh = Instance.new("TextLabel")
lblThresh.Size = UDim2.new(0, 80, 1, 0)
lblThresh.BackgroundTransparency = 1
lblThresh.Text = "Threshold kg:"
lblThresh.TextColor3 = Color3.fromRGB(220, 190, 100)
lblThresh.TextSize = 10; lblThresh.Font = Enum.Font.GothamBold
lblThresh.TextXAlignment = Enum.TextXAlignment.Left
lblThresh.Parent = row1

local threshBox = Instance.new("TextBox")
threshBox.Size = UDim2.new(0, 54, 1, -2)
threshBox.Position = UDim2.new(0, 82, 0, 1)
threshBox.BackgroundColor3 = Color3.fromRGB(20, 15, 5)
threshBox.BorderSizePixel = 0
threshBox.Text = tostring(KG_THRESHOLD)
threshBox.TextColor3 = Color3.fromRGB(255, 230, 100)
threshBox.TextSize = 11; threshBox.Font = Enum.Font.GothamBold
threshBox.PlaceholderText = "75"
threshBox.Parent = row1
Instance.new("UICorner", threshBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", threshBox).Color = Color3.fromRGB(180, 130, 30)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0, 72, 1, -2)
scanBtn.Position = UDim2.new(0, 140, 0, 1)
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 35, 10)
scanBtn.BorderSizePixel = 0
scanBtn.Text = "▶ SCAN"
scanBtn.TextColor3 = Color3.fromRGB(255, 210, 100)
scanBtn.TextSize = 10; scanBtn.Font = Enum.Font.GothamBold
scanBtn.Parent = row1
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 4)

-- row: auto collect controls
local row2 = Instance.new("Frame")
row2.Size = UDim2.new(1, -8, 0, 26)
row2.Position = UDim2.new(0, 4, 0, 56)
row2.BackgroundTransparency = 1
row2.Parent = frame

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 130, 1, -2)
autoBtn.Position = UDim2.new(0, 0, 0, 1)
autoBtn.BackgroundColor3 = Color3.fromRGB(15, 40, 15)
autoBtn.BorderSizePixel = 0
autoBtn.Text = "▶ START AUTO COLLECT"
autoBtn.TextColor3 = Color3.fromRGB(100, 240, 120)
autoBtn.TextSize = 10; autoBtn.Font = Enum.Font.GothamBold
autoBtn.Parent = row2
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 4)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 72, 1, -2)
stopBtn.Position = UDim2.new(0, 134, 0, 1)
stopBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
stopBtn.BorderSizePixel = 0
stopBtn.Text = "■ STOP"
stopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
stopBtn.TextSize = 10; stopBtn.Font = Enum.Font.GothamBold
stopBtn.Parent = row2
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 4)

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(0, 110, 1, -2)
statLbl.Position = UDim2.new(0, 212, 0, 1)
statLbl.BackgroundColor3 = Color3.fromRGB(14, 20, 8)
statLbl.BorderSizePixel = 0
statLbl.Text = "total: 0"
statLbl.TextColor3 = Color3.fromRGB(180, 255, 180)
statLbl.TextSize = 10; statLbl.Font = Enum.Font.GothamBold
statLbl.Parent = row2
Instance.new("UICorner", statLbl).CornerRadius = UDim.new(0, 4)

-- summary bar
local sumBar = Instance.new("TextLabel")
sumBar.Size = UDim2.new(1, -8, 0, 20)
sumBar.Position = UDim2.new(0, 4, 0, 85)
sumBar.BackgroundColor3 = Color3.fromRGB(24, 18, 5)
sumBar.BorderSizePixel = 0
sumBar.Text = "tekan SCAN untuk lihat pohon coconut"
sumBar.TextColor3 = Color3.fromRGB(255, 220, 120)
sumBar.TextSize = 10; sumBar.Font = Enum.Font.GothamBold
sumBar.Parent = frame
Instance.new("UICorner", sumBar).CornerRadius = UDim.new(0, 4)

-- divider label
local divScan = Instance.new("TextLabel")
divScan.Size = UDim2.new(1, -8, 0, 14)
divScan.Position = UDim2.new(0, 4, 0, 107)
divScan.BackgroundColor3 = Color3.fromRGB(18, 14, 4)
divScan.BorderSizePixel = 0
divScan.Text = "── Info Pohon ─────────────────────────────"
divScan.TextColor3 = Color3.fromRGB(150, 120, 50)
divScan.TextSize = 9; divScan.Font = Enum.Font.Code
divScan.TextXAlignment = Enum.TextXAlignment.Left
divScan.Parent = frame
local dp = Instance.new("UIPadding", divScan); dp.PaddingLeft = UDim.new(0,4)

-- scroll SCAN
local scrollScan = Instance.new("ScrollingFrame")
scrollScan.Size = UDim2.new(1, -8, 0, 170)
scrollScan.Position = UDim2.new(0, 4, 0, 122)
scrollScan.BackgroundTransparency = 1
scrollScan.BorderSizePixel = 0
scrollScan.ScrollBarThickness = 3
scrollScan.CanvasSize = UDim2.new(0,0,0,0)
scrollScan.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollScan.Parent = frame
local layoutScan = Instance.new("UIListLayout", scrollScan)
layoutScan.SortOrder = Enum.SortOrder.LayoutOrder
layoutScan.Padding = UDim.new(0,2)

-- divider log
local divLog = Instance.new("TextLabel")
divLog.Size = UDim2.new(1, -8, 0, 14)
divLog.Position = UDim2.new(0, 4, 0, 295)
divLog.BackgroundColor3 = Color3.fromRGB(8, 18, 8)
divLog.BorderSizePixel = 0
divLog.Text = "── Log Auto Collect ───────────────────────"
divLog.TextColor3 = Color3.fromRGB(80, 160, 80)
divLog.TextSize = 9; divLog.Font = Enum.Font.Code
divLog.TextXAlignment = Enum.TextXAlignment.Left
divLog.Parent = frame
local dlp = Instance.new("UIPadding", divLog); dlp.PaddingLeft = UDim.new(0,4)

-- scroll LOG
local scrollLog = Instance.new("ScrollingFrame")
scrollLog.Size = UDim2.new(1, -8, 0, 155)
scrollLog.Position = UDim2.new(0, 4, 0, 311)
scrollLog.BackgroundTransparency = 1
scrollLog.BorderSizePixel = 0
scrollLog.ScrollBarThickness = 3
scrollLog.CanvasSize = UDim2.new(0,0,0,0)
scrollLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollLog.Parent = frame
local layoutLog = Instance.new("UIListLayout", scrollLog)
layoutLog.SortOrder = Enum.SortOrder.LayoutOrder
layoutLog.Padding = UDim.new(0,1)

-- helper rows ─────────────────────────────────────────────
local scanOrder = 0
local function clearScanRows()
    for _, c in ipairs(scrollScan:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    scanOrder = 0
end

local function addScanRow(txt, col, bg, bold)
    scanOrder += 1
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -6, 0, 18)
    row.BackgroundColor3 = bg or Color3.fromRGB(14, 10, 2)
    row.BackgroundTransparency = bg and 0 or 0.5
    row.BorderSizePixel = 0
    row.TextColor3 = col or Color3.fromRGB(220, 200, 150)
    row.TextSize = 10
    row.Font = bold and Enum.Font.GothamBold or Enum.Font.Code
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextWrapped = false; row.Text = txt
    row.LayoutOrder = scanOrder; row.Parent = scrollScan
    local rp = Instance.new("UIPadding", row); rp.PaddingLeft = UDim.new(0,4)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,3)
end

local logOrder = 0
local function addLogRow(txt, col)
    logOrder += 1
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -6, 0, 16)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.TextColor3 = col or Color3.fromRGB(180, 240, 180)
    row.TextSize = 10; row.Font = Enum.Font.Code
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextWrapped = false; row.Text = txt
    row.LayoutOrder = logOrder; row.Parent = scrollLog
    local rp = Instance.new("UIPadding", row); rp.PaddingLeft = UDim.new(0,4)
    -- auto scroll ke bawah
    task.defer(function()
        scrollLog.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

local function guiLog(msg)
    logMsg(msg)
    local col = Color3.fromRGB(180, 240, 180)
    if msg:find("✅") then col = Color3.fromRGB(100, 255, 100) end
    if msg:find("⚠") or msg:find("ERR") or msg:find("tidak") then col = Color3.fromRGB(255, 160, 80) end
    if msg:find("🔄") then col = Color3.fromRGB(100, 200, 255) end
    if msg:find("🛑") then col = Color3.fromRGB(255, 100, 100) end
    addLogRow(msg, col)
    -- update stat
    statLbl.Text = "total: " .. _collectCount
end

-- ── SCAN button ─────────────────────────────────────────
scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "..."
    clearScanRows()
    sumBar.Text = "scanning..."
    sumBar.TextColor3 = Color3.fromRGB(255, 220, 120)

    task.spawn(function()
        local res, err = scanCoconutKg()
        if not res then
            sumBar.Text = "ERROR: " .. tostring(err)
            sumBar.TextColor3 = Color3.fromRGB(255, 100, 100)
            addScanRow(tostring(err), Color3.fromRGB(255, 100, 100))
            scanBtn.Text = "▶ SCAN"
            return
        end

        if #res == 0 then
            sumBar.Text = "⚠ Tidak ada pohon coconut ditemukan!"
            sumBar.TextColor3 = Color3.fromRGB(255, 150, 50)
            addScanRow("Pohon coconut tidak ada di Plants_Physical", Color3.fromRGB(255, 150, 50))
            scanBtn.Text = "▶ SCAN"
            return
        end

        local totalPohon = #res
        local totalBuah, totalKg = 0, 0
        for _, r in ipairs(res) do
            totalBuah += r.buahCount
            totalKg   += r.kgTotal
        end
        local avgKg = totalBuah > 0 and (totalKg / totalBuah) or 0

        sumBar.Text = string.format("🥥 %d pohon | %d buah | %.2f kg/buah avg | %.1f kg total",
            totalPohon, totalBuah, avgKg, totalKg)
        sumBar.TextColor3 = Color3.fromRGB(255, 220, 100)

        for i, r in ipairs(res) do
            local kpb = r.buahCount > 0 and (r.kgTotal / r.buahCount) or (r.kgSample or 0)
            addScanRow(string.format("🌴 Pohon #%d: %s", i, r.treeName),
                Color3.fromRGB(255, 210, 80), Color3.fromRGB(28, 20, 5), true)
            addScanRow(string.format("   buah=%d | kg/buah=%.2f | total=%.1f kg",
                r.buahCount, kpb, r.kgTotal),
                Color3.fromRGB(220, 200, 140), Color3.fromRGB(18, 14, 4))
            if r.attrKey ~= "?" then
                addScanRow("   attr key: [" .. r.attrKey .. "]",
                    Color3.fromRGB(100, 180, 255), Color3.fromRGB(10, 12, 20))
            end
            if not r.hasFruits then
                addScanRow("   ⚠ tidak ada folder Fruits",
                    Color3.fromRGB(255, 150, 50), Color3.fromRGB(20, 12, 4))
            elseif r.buahCount == 0 then
                addScanRow("   ⚠ Fruits kosong (buah belum tumbuh?)",
                    Color3.fromRGB(255, 150, 50), Color3.fromRGB(20, 12, 4))
            else
                local shown = 0
                for _, buah in ipairs(r.buahList) do
                    if shown >= 4 then
                        addScanRow(string.format("   ...+%d buah lagi", r.buahCount - shown),
                            Color3.fromRGB(150, 150, 150))
                        break
                    end
                    local kgTxt = buah.kg and string.format("%.2f kg", buah.kg) or "(kg ?)"
                    local belowThresh = buah.kg and buah.kg < KG_THRESHOLD
                    local col = belowThresh and Color3.fromRGB(255, 180, 60)
                             or (buah.kg and Color3.fromRGB(180, 240, 160) or Color3.fromRGB(255, 130, 80))
                    local mark = belowThresh and " ← akan di-collect" or ""
                    addScanRow(string.format("   • %s — %s%s", buah.name, kgTxt, mark), col,
                        Color3.fromRGB(14, 18, 10))
                    shown += 1
                end
            end
        end

        print("[COCONUT KG] ===== HASIL =====")
        print(string.format("[COCONUT KG] %d pohon, %d buah, %.2f kg/buah avg, %.1f kg total",
            totalPohon, totalBuah, avgKg, totalKg))
        for i, r in ipairs(res) do
            local kpb = r.buahCount > 0 and (r.kgTotal / r.buahCount) or (r.kgSample or 0)
            print(string.format("[COCONUT KG] #%d %s — buah=%d kgPerBuah=%.2f totalKg=%.1f attrKey=%s",
                i, r.treeName, r.buahCount, kpb, r.kgTotal, r.attrKey))
        end

        scanBtn.Text = "▶ SCAN"
    end)
end)

-- ── AUTO COLLECT button ───────────────────────────────────
autoBtn.MouseButton1Click:Connect(function()
    if _autoRunning then guiLog("⚠ auto-collect sudah jalan"); return end
    local thresh = tonumber(threshBox.Text) or KG_THRESHOLD
    KG_THRESHOLD = thresh
    autoBtn.BackgroundColor3 = Color3.fromRGB(8, 50, 8)
    autoBtn.Text = "🔄 AUTO ON"
    autoBtn.TextColor3 = Color3.fromRGB(80, 255, 100)
    strokeMain.Color = Color3.fromRGB(80, 255, 100)
    startAutoCollect(thresh, 5, guiLog)
end)

stopBtn.MouseButton1Click:Connect(function()
    stopAutoCollect()
    autoBtn.BackgroundColor3 = Color3.fromRGB(15, 40, 15)
    autoBtn.Text = "▶ START AUTO COLLECT"
    autoBtn.TextColor3 = Color3.fromRGB(100, 240, 120)
    strokeMain.Color = Color3.fromRGB(255, 180, 50)
    guiLog("🛑 auto-collect dihentikan manual")
end)

-- refresh stat tiap detik
task.spawn(function()
    while true do
        task.wait(1)
        statLbl.Text = "total: " .. _collectCount
        if _autoRunning then
            autoBtn.Text = "🔄 AUTO ON"
        end
    end
end)

print("[COCONUT KG] debug_coconut_kg v0.2 — panel kuning, threshold default 75kg")
