-- debug_swap_test.lua — auto detect equipped pets, test unequip/equip manual
local plr = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")

local function fmtUUID(raw) return "{"..raw:gsub("[{}]","").."}" end

local function getSpawnCF()
    -- cari posisi Center kebun milik player (sama persis dengan uplevelnew farmCenter)
    local farms = workspace:FindFirstChild("Farm")
    if farms then
        for _, f in ipairs(farms:GetChildren()) do
            local imp   = f:FindFirstChild("Important")
            local data  = imp and imp:FindFirstChild("Data")
            local owner = data and data:FindFirstChild("Owner")
            if owner and owner.Value == plr.Name then
                local c = f:FindFirstChild("Center", true)
                if c and c:IsA("BasePart") then
                    return CFrame.new(c.Position.X, 4, c.Position.Z)
                end
            end
        end
    end
    -- fallback HRP
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.CFrame end
    return CFrame.new(-190, 0, 60)
end

-- ── cari RE ───────────────────────────────────────────────────────────────────
local _re = nil
local function findRE()
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name == "PetsService" and v:IsA("RemoteEvent") then return v end
    end
end
_re = findRE()
task.spawn(function()
    for _ = 1, 20 do if _re then break end; task.wait(1); _re = findRE() end
end)

-- ── RC fetch ──────────────────────────────────────────────────────────────────
local function fetchRC()
    local result, err = nil, nil
    local ok, e = pcall(function()
        local RC   = require(RS.Modules.ReplicationClass)
        local inst = RC.new("ActivePetsService_Replicator")
        local data = inst:GetData(plr.Name)
        local tbl  = rawget(data, "Table")
        local ppd  = rawget(tbl, "PlayerPetData")
        local pd   = rawget(ppd, plr.Name)
        local pi   = rawget(pd, "PetInventory")
        local dat  = rawget(pi, "Data")
        local out  = {}
        for uuid, entry in pairs(dat) do
            if type(entry) == "table" then
                out[tostring(uuid):gsub("[{}]","")] = entry
            end
        end
        if next(out) then result = out end
    end)
    if not ok then err = tostring(e) end
    return result, err
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DBG_SWAP_TEST"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = plr:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 480, 0, 500)
panel.Position = UDim2.new(0, 8, 0.1, 0)
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = sg

local function mkLbl(txt, x, y, w, h, col)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, w, 0, h)
    l.Position = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = col or Color3.fromRGB(200,200,200)
    l.TextSize = 11
    l.Font = Enum.Font.Code
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = txt
    l.Parent = panel
    return l
end

local function mkBtn(txt, x, y, w, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 22)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = col
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(230,230,230)
    b.TextSize = 11
    b.Font = Enum.Font.Code
    b.Parent = panel
    return b
end

mkLbl("🔧 SWAP TEST — "..plr.Name, 4, 4, 400, 18, Color3.fromRGB(160,220,255))

local btnRefresh = mkBtn("🔄 SCAN",    4,  26, 70, Color3.fromRGB(30,60,30))
local btnUneq    = mkBtn("⬆ UNEQ",   78,  26, 65, Color3.fromRGB(60,30,20))
local btnEq      = mkBtn("⬇ EQ",    147,  26, 55, Color3.fromRGB(20,50,20))
local btnBoth    = mkBtn("🔄 SWAP",  206,  26, 65, Color3.fromRGB(30,30,70))
local btnCopy    = mkBtn("📋 COPY",  275,  26, 65, Color3.fromRGB(30,50,60))
local btnRejoin  = mkBtn("🔁 REJOIN",344,  26, 75, Color3.fromRGB(60,30,60))
local btnClose   = mkBtn("✕",        443,  26, 28, Color3.fromRGB(60,20,20))

local lbRE = mkLbl("RE: ...", 4, 52, 470, 14, Color3.fromRGB(120,180,120))

-- list equipped pets
local hdr = mkLbl("  # uuid8     tipe           age   kg    status", 4, 68, 470, 14, Color3.fromRGB(80,120,80))

local sfList = Instance.new("ScrollingFrame")
sfList.Size = UDim2.new(0, 472, 0, 160)
sfList.Position = UDim2.new(0, 4, 0, 84)
sfList.BackgroundColor3 = Color3.fromRGB(12,18,12)
sfList.BorderSizePixel = 0
sfList.ScrollBarThickness = 4
sfList.CanvasSize = UDim2.new(0,0,0,0)
sfList.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfList.Parent = panel

local lbList = Instance.new("TextLabel")
lbList.Size = UDim2.new(1,-4,0,0)
lbList.AutomaticSize = Enum.AutomaticSize.Y
lbList.BackgroundTransparency = 1
lbList.TextColor3 = Color3.fromRGB(140,220,140)
lbList.TextSize = 10
lbList.Font = Enum.Font.Code
lbList.TextXAlignment = Enum.TextXAlignment.Left
lbList.TextWrapped = false
lbList.Text = "(klik SCAN)"
lbList.Parent = sfList

-- selected uuid label
local lbSel = mkLbl("selected: (klik baris)", 4, 248, 470, 14, Color3.fromRGB(220,220,80))

-- log
local sfLog = Instance.new("ScrollingFrame")
sfLog.Size = UDim2.new(0, 472, 0, 220)
sfLog.Position = UDim2.new(0, 4, 0, 265)
sfLog.BackgroundColor3 = Color3.fromRGB(8,8,15)
sfLog.BorderSizePixel = 0
sfLog.ScrollBarThickness = 4
sfLog.CanvasSize = UDim2.new(0,0,0,0)
sfLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfLog.Parent = panel

local lbLog = Instance.new("TextLabel")
lbLog.Size = UDim2.new(1,-4,0,0)
lbLog.AutomaticSize = Enum.AutomaticSize.Y
lbLog.BackgroundTransparency = 1
lbLog.TextColor3 = Color3.fromRGB(180,220,180)
lbLog.TextSize = 10
lbLog.Font = Enum.Font.Code
lbLog.TextXAlignment = Enum.TextXAlignment.Left
lbLog.TextWrapped = false
lbLog.Text = "(log)"
lbLog.Parent = sfLog

-- ── state ─────────────────────────────────────────────────────────────────────
local logLines = {}
local _selectedUUID = nil
local _rows = {}  -- {uuid, u8, tipe, age, kg}

local function addLog(msg, col)
    table.insert(logLines, 1, string.format("%.1f", os.clock()%1000).." "..msg)
    if #logLines > 80 then logLines[#logLines] = nil end
    lbLog.Text = table.concat(logLines, "\n")
    if col then lbLog.TextColor3 = col end
end

local function updateREStatus()
    if not _re then _re = findRE() end
    if _re and _re.Parent then
        lbRE.Text = "RE: ✓ " .. _re:GetFullName()
        lbRE.TextColor3 = Color3.fromRGB(80,220,80)
    else
        lbRE.Text = "RE: ✗ tidak ditemukan"
        lbRE.TextColor3 = Color3.fromRGB(220,80,80)
    end
end

-- ── scan RC untuk pet yang equipped ──────────────────────────────────────────
local function doScan()
    lbList.Text = "⟳ scanning..."
    updateREStatus()
    local container, err = fetchRC()
    if not container then
        lbList.Text = "❌ RC gagal: "..(err or "?")
        lbList.TextColor3 = Color3.fromRGB(220,80,80)
        return
    end

    _rows = {}
    for rawUuid, entry in pairs(container) do
        local uuid = rawUuid:gsub("[{}]","")
        local u8 = uuid:sub(1,8)
        local age, kg, tipe, equipped = "?","?","?", false
        pcall(function()
            local pd = entry.PetData or entry
            if type(pd)=="table" then
                local a = pd.Level or pd.Age or pd.level or pd.age
                if a~=nil then age=tostring(a) end
                local k = pd.BaseWeight or pd.Weight or pd.kg or pd.baseWeight
                if k~=nil then kg=string.format("%.2f",k) end
                local eq = pd.Equipped or pd.IsEquipped or pd.equipped
                equipped = (eq==true or eq==1)
            end
            local t = entry.PetType or entry.PetId or entry.Type or entry.petType
            if t~=nil then tipe=tostring(t):sub(1,14) end
        end)
        table.insert(_rows, {uuid=uuid, u8=u8, tipe=tipe, age=age, kg=kg, equipped=equipped})
    end

    -- sort: equipped dulu, lalu by age desc
    table.sort(_rows, function(a,b)
        if a.equipped ~= b.equipped then return a.equipped end
        return (tonumber(a.age) or 0) > (tonumber(b.age) or 0)
    end)

    -- buat tombol per baris
    -- hapus tombol lama
    for _, c in ipairs(sfList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end

    local lineH = 18
    for i, r in ipairs(_rows) do
        local eqMark = r.equipped and "✓EQ" or "   "
        local line = string.format(" %-3d %-8s  %-14s  %4s  %5s  %s", i, r.u8, r.tipe, r.age, r.kg, eqMark)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, lineH)
        btn.Position = UDim2.new(0, 2, 0, (i-1)*lineH)
        btn.BackgroundColor3 = r.equipped and Color3.fromRGB(20,50,20) or Color3.fromRGB(14,14,22)
        btn.BorderSizePixel = 0
        btn.Text = line
        btn.TextColor3 = r.equipped and Color3.fromRGB(100,255,100) or Color3.fromRGB(160,200,160)
        btn.TextSize = 10
        btn.Font = Enum.Font.Code
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = sfList
        local uuid = r.uuid
        btn.MouseButton1Click:Connect(function()
            _selectedUUID = uuid
            lbSel.Text = "selected: "..uuid.." ("..r.tipe.." a="..r.age..")"
            lbSel.TextColor3 = Color3.fromRGB(255,230,80)
            addLog("→ pilih "..uuid:sub(1,8).." "..r.tipe)
        end)
    end

    sfList.CanvasSize = UDim2.new(0, 0, 0, #_rows * lineH + 4)
    addLog("✓ scan: "..(#_rows).." pet")
end

-- ── aksi equip/unequip ────────────────────────────────────────────────────────
local function ensureRE()
    if not _re or not _re.Parent then _re = findRE() end
    if not _re then addLog("✗ RE tidak ditemukan", Color3.fromRGB(220,80,80)); return false end
    return true
end

btnRefresh.MouseButton1Click:Connect(function() task.spawn(doScan) end)

btnUneq.MouseButton1Click:Connect(function()
    if not _selectedUUID then addLog("⚠ pilih pet dulu"); return end
    if not ensureRE() then return end
    addLog("→ UNEQ "..fmtUUID(_selectedUUID):sub(1,12).."...")
    local ok, err = pcall(function() _re:FireServer("UnequipPet", fmtUUID(_selectedUUID)) end)
    addLog(ok and "✓ UNEQ sent" or "✗ "..tostring(err):sub(1,80),
        ok and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,100,100))
    task.wait(0.3); task.spawn(doScan)
end)

btnEq.MouseButton1Click:Connect(function()
    if not _selectedUUID then addLog("⚠ pilih pet dulu"); return end
    if not ensureRE() then return end
    local cf = getSpawnCF()
    addLog("→ EQ "..fmtUUID(_selectedUUID):sub(1,12).."...")
    local ok, err = pcall(function() _re:FireServer("EquipPet", fmtUUID(_selectedUUID), cf) end)
    addLog(ok and "✓ EQ sent" or "✗ "..tostring(err):sub(1,80),
        ok and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,100,100))
    task.wait(0.3); task.spawn(doScan)
end)

btnBoth.MouseButton1Click:Connect(function()
    if not _selectedUUID then addLog("⚠ pilih pet dulu"); return end
    if not ensureRE() then return end
    local uuid = _selectedUUID
    task.spawn(function()
        addLog("→ UNEQ "..uuid:sub(1,8).."...")
        local ok1, e1 = pcall(function() _re:FireServer("UnequipPet", fmtUUID(uuid)) end)
        addLog(ok1 and "✓ UNEQ sent" or "✗ UNEQ: "..tostring(e1):sub(1,60),
            ok1 and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,100,100))
        task.wait(0.15)
        addLog("→ EQ "..uuid:sub(1,8).."...")
        local ok2, e2 = pcall(function() _re:FireServer("EquipPet", fmtUUID(uuid), getSpawnCF()) end)
        addLog(ok2 and "✓ EQ sent" or "✗ EQ: "..tostring(e2):sub(1,60),
            ok2 and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,100,100))
        task.wait(0.3); task.spawn(doScan)
    end)
end)

btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    local ok = pcall(function() setclipboard(txt) end)
    if ok then
        btnCopy.Text = "✓ OK"
        task.delay(1.5, function() btnCopy.Text = "📋 COPY" end)
    end
end)

btnRejoin.MouseButton1Click:Connect(function()
    btnRejoin.Text = "⟳..."
    task.spawn(function()
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, plr) end)
    end)
end)

btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- auto-scan saat start
task.spawn(doScan)
print("[debug_swap_test] aktif")
