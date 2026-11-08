-- debug_garden_uuid.lua — UUID pet di garden + DS swap events (filter mine only)
-- RC: RS.Modules.ReplicationClass → ActivePetsService_Replicator → PlayerPetData → plr.Name → PetInventory → Data

local plr = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")

-- cari equipRE sendiri (PetsService RemoteEvent) — tidak depend ke uplevelnew
local _equipRE = nil
local function findEquipRE()
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name == "PetsService" and v:IsA("RemoteEvent") then return v end
    end
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name == "PetsService" then return v end
    end
    return nil
end
_equipRE = findEquipRE()
if not _equipRE then
    task.spawn(function()
        for _ = 1, 10 do task.wait(2); _equipRE = findEquipRE(); if _equipRE then break end end
    end)
end

local function fmtUUID(raw) return "{"..raw:gsub("[{}]","").."}" end

local _swapLog = {}
local function swapDbg(msg)
    table.insert(_swapLog, 1, msg)
    if #_swapLog > 30 then _swapLog[#_swapLog] = nil end
end

local function getSpawnCF()
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
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.CFrame end
    return CFrame.new(-190, 0, 60)
end

local function doEquip(raw)
    if _equipRE then
        if not _equipRE.Parent then
            swapDbg("EQUIP-ERR: RE orphan, refind...")
            _equipRE = findEquipRE()
            if not _equipRE then swapDbg("EQUIP-ERR: RE not found!"); return false end
        end
        local cf = getSpawnCF()
        local ok, err = pcall(function() _equipRE:FireServer("EquipPet", fmtUUID(raw), cf) end)
        if ok then swapDbg("EQUIP-OK "..raw:sub(1,8))
        else swapDbg("EQUIP-ERR "..raw:sub(1,8)..": "..tostring(err):sub(1,40)) end
        return ok
    end
    local eFn = _G and _G.ZenxEquipPet
    if eFn then
        local ok, err = pcall(eFn, raw)
        swapDbg(ok and "EQUIP-G-OK "..raw:sub(1,8) or "EQUIP-G-ERR: "..tostring(err):sub(1,40))
        return ok
    end
    swapDbg("EQUIP-SKIP: no RE no _G fn")
    return false
end

local function doUnequip(raw)
    if _equipRE then
        if not _equipRE.Parent then
            _equipRE = findEquipRE()
            if not _equipRE then swapDbg("UNEQ-ERR: RE not found!"); return false end
        end
        local ok, err = pcall(function() _equipRE:FireServer("UnequipPet", fmtUUID(raw)) end)
        if ok then swapDbg("UNEQ-OK "..raw:sub(1,8))
        else swapDbg("UNEQ-ERR "..raw:sub(1,8)..": "..tostring(err):sub(1,40)) end
        return ok
    end
    local uFn = _G and _G.ZenxUnequipPet
    if uFn then pcall(uFn, raw); return true end
    swapDbg("UNEQ-SKIP: no RE no _G fn")
    return false
end


-- ── RC fetch (sama persis dengan findMemoryContainer di uplevelnew) ───────────
local function fetchRC()
    local result = nil
    local err = nil
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
                out[tostring(uuid)] = entry
            end
        end
        if next(out) then result = out end
    end)
    if not ok then err = tostring(e) end
    return result, err
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DBG_GARDEN_UUID"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = plr:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 660, 0, 520)
panel.Position = UDim2.new(0, 8, 0.05, 0)
panel.BackgroundColor3 = Color3.fromRGB(10, 14, 10)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
title.BorderSizePixel = 0
title.Text = "  🌿 GARDEN UUID — " .. plr.Name
title.TextColor3 = Color3.fromRGB(160, 230, 160)
title.TextSize = 11
title.Font = Enum.Font.Code
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local function mkBtn(txt, x, w, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 20)
    b.Position = UDim2.new(0, x, 0, 24)
    b.BackgroundColor3 = col
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(220, 220, 220)
    b.TextSize = 11
    b.Font = Enum.Font.Code
    b.Parent = panel
    return b
end

local btnRefresh = mkBtn("🔄 REFRESH",  4,   88, Color3.fromRGB(30, 70, 30))
local btnCopy    = mkBtn("📋 COPY",     96,  70, Color3.fromRGB(30, 50, 60))
local btnRejoin  = mkBtn("🔁 REJOIN",  170,  75, Color3.fromRGB(60, 30, 60))
local btnClose   = mkBtn("✕",          249,  28, Color3.fromRGB(60, 20, 20))

local lbInfo = Instance.new("TextLabel")
lbInfo.Size = UDim2.new(1, -195, 0, 20)
lbInfo.Position = UDim2.new(0, 195, 0, 24)
lbInfo.BackgroundTransparency = 1
lbInfo.TextColor3 = Color3.fromRGB(140, 200, 140)
lbInfo.TextSize = 11
lbInfo.Font = Enum.Font.Code
lbInfo.TextXAlignment = Enum.TextXAlignment.Left
lbInfo.Text = ""
lbInfo.Parent = panel

-- ── Kolom kiri: UUID list ─────────────────────────────────────────────────────
local hdrL = Instance.new("TextLabel")
hdrL.Size = UDim2.new(0, 326, 0, 14)
hdrL.Position = UDim2.new(0, 4, 0, 46)
hdrL.BackgroundColor3 = Color3.fromRGB(15, 35, 15)
hdrL.BorderSizePixel = 0
hdrL.Text = "  #   uuid8     age     kg    tipe"
hdrL.TextColor3 = Color3.fromRGB(80, 140, 80)
hdrL.TextSize = 10
hdrL.Font = Enum.Font.Code
hdrL.TextXAlignment = Enum.TextXAlignment.Left
hdrL.Parent = panel

local sfL = Instance.new("ScrollingFrame")
sfL.Size = UDim2.new(0, 326, 0, 440)
sfL.Position = UDim2.new(0, 4, 0, 62)
sfL.BackgroundColor3 = Color3.fromRGB(12, 18, 12)
sfL.BorderSizePixel = 0
sfL.ScrollBarThickness = 4
sfL.CanvasSize = UDim2.new(0, 0, 0, 0)
sfL.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfL.Parent = panel

local lbList = Instance.new("TextLabel")
lbList.Size = UDim2.new(1, -4, 0, 0)
lbList.AutomaticSize = Enum.AutomaticSize.Y
lbList.BackgroundTransparency = 1
lbList.TextColor3 = Color3.fromRGB(140, 220, 140)
lbList.TextSize = 10
lbList.Font = Enum.Font.Code
lbList.TextXAlignment = Enum.TextXAlignment.Left
lbList.TextWrapped = false
lbList.Text = "(loading...)"
lbList.Parent = sfL

-- ── Kolom kanan: DS swap events ───────────────────────────────────────────────
local hdrR = Instance.new("TextLabel")
hdrR.Size = UDim2.new(0, 322, 0, 14)
hdrR.Position = UDim2.new(0, 334, 0, 46)
hdrR.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
hdrR.BorderSizePixel = 0
hdrR.Text = "  DS SWAP (mine only) — anim | uuid8 | age | kg"
hdrR.TextColor3 = Color3.fromRGB(120, 160, 220)
hdrR.TextSize = 10
hdrR.Font = Enum.Font.Code
hdrR.TextXAlignment = Enum.TextXAlignment.Left
hdrR.Parent = panel

local sfR = Instance.new("ScrollingFrame")
sfR.Size = UDim2.new(0, 322, 0, 440)
sfR.Position = UDim2.new(0, 334, 0, 62)
sfR.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
sfR.BorderSizePixel = 0
sfR.ScrollBarThickness = 4
sfR.CanvasSize = UDim2.new(0, 0, 0, 0)
sfR.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfR.Parent = panel

local lbDS = Instance.new("TextLabel")
lbDS.Size = UDim2.new(1, -4, 0, 0)
lbDS.AutomaticSize = Enum.AutomaticSize.Y
lbDS.BackgroundTransparency = 1
lbDS.TextColor3 = Color3.fromRGB(140, 180, 240)
lbDS.TextSize = 10
lbDS.Font = Enum.Font.Code
lbDS.TextXAlignment = Enum.TextXAlignment.Left
lbDS.TextWrapped = false
lbDS.Text = "(menunggu DS...)"
lbDS.Parent = sfR

-- ── SWAPLOG button (setelah sfR/lbDS tersedia) ───────────────────────────────
local btnSwapLog = mkBtn("SWAPLOG", 285, 70, Color3.fromRGB(40, 30, 60))

local sfSwapLog = Instance.new("ScrollingFrame")
sfSwapLog.Size = UDim2.new(0, 322, 0, 440)
sfSwapLog.Position = UDim2.new(0, 334, 0, 62)
sfSwapLog.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
sfSwapLog.BorderSizePixel = 0
sfSwapLog.ScrollBarThickness = 4
sfSwapLog.CanvasSize = UDim2.new(0, 0, 0, 0)
sfSwapLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfSwapLog.Visible = false
sfSwapLog.Parent = panel

local lbSwapLog = Instance.new("TextLabel")
lbSwapLog.Size = UDim2.new(1, -4, 0, 0)
lbSwapLog.AutomaticSize = Enum.AutomaticSize.Y
lbSwapLog.BackgroundTransparency = 1
lbSwapLog.TextColor3 = Color3.fromRGB(220, 200, 100)
lbSwapLog.TextSize = 10
lbSwapLog.Font = Enum.Font.Code
lbSwapLog.TextXAlignment = Enum.TextXAlignment.Left
lbSwapLog.TextWrapped = false
lbSwapLog.Text = ""
lbSwapLog.Parent = sfSwapLog

local _showSwapLog = false
btnSwapLog.MouseButton1Click:Connect(function()
    _showSwapLog = not _showSwapLog
    sfSwapLog.Visible = _showSwapLog
    sfR.Visible = not _showSwapLog
    btnSwapLog.BackgroundColor3 = _showSwapLog and Color3.fromRGB(80, 50, 120) or Color3.fromRGB(40, 30, 60)
    if _showSwapLog then
        lbSwapLog.Text = table.concat(_swapLog, "\n")
    end
end)

local copyBuf = ""
local _autoRunning = true
local _uuidIndex = {}   -- uuid/u8 → nomor urut (di-update tiap refresh)

-- update swaplog tiap detik kalau sedang tampil
task.spawn(function()
    while task.wait(1) do
        if not (sg and sg.Parent) then break end
        if _showSwapLog then
            lbSwapLog.Text = table.concat(_swapLog, "\n")
        end
    end
end)

-- ── Refresh ───────────────────────────────────────────────────────────────────
local function refresh()
    lbInfo.Text = "⟳ fetching RC..."
    lbInfo.TextColor3 = Color3.fromRGB(160, 160, 80)

    local container, rcErr = fetchRC()

    -- fallback: coba baca dari _G._kgContainer kalau RC gagal
    if not container then
        local g = _G and _G._kgContainer
        if g and next(g) then
            container = g
            lbInfo.Text = "⚠ RC gagal, pakai _G._kgContainer"
            lbInfo.TextColor3 = Color3.fromRGB(220, 160, 60)
        else
            lbList.Text = "❌ RC gagal:\n" .. tostring(rcErr or "unknown") .. "\n\n_G._kgContainer juga nil\nJalankan uplevelnew dulu atau tunggu ~5s"
            lbList.TextColor3 = Color3.fromRGB(220, 80, 80)
            lbInfo.Text = "RC GAGAL"
            lbInfo.TextColor3 = Color3.fromRGB(220, 80, 80)
            return
        end
    end

    -- hitung total
    local total = 0
    for _ in pairs(container) do total = total + 1 end

    -- bangun baris
    local rows = {}
    for rawUuid, entry in pairs(container) do
        local uuid = tostring(rawUuid):gsub("[{}]", "")
        local u8   = uuid:sub(1, 8)
        local age, kg, tipe = "?", "?", "?"

        pcall(function()
            local pd = entry.PetData or entry
            if type(pd) == "table" then
                local a = pd.Level or pd.Age or pd.level or pd.age
                if a ~= nil then age = tostring(a) end
                local k = pd.BaseWeight or pd.Weight or pd.kg or pd.baseWeight
                if k ~= nil then kg = tostring(k) end
            end
            local t = entry.PetType or entry.PetId or entry.Type or entry.petType
            if t ~= nil then tipe = tostring(t):sub(1, 14) end
        end)

        table.insert(rows, {uuid=uuid, u8=u8, age=age, kg=kg, tipe=tipe})
    end

    -- sort by age descending
    table.sort(rows, function(a, b)
        return (tonumber(a.age) or 0) > (tonumber(b.age) or 0)
    end)

    local lines = {}
    local copyLines = {"# uuid                                   age    kg     tipe"}
    for i, r in ipairs(rows) do
        local ageN = tonumber(r.age) or 0
        local marker = ageN >= 500 and "★" or " "
        table.insert(lines, string.format(" %s%-3d %-8s  %5s  %6s  %s", marker, i, r.u8, r.age, r.kg, r.tipe))
        table.insert(copyLines, r.uuid .. "  age=" .. r.age .. "  kg=" .. r.kg .. "  " .. r.tipe)
        -- simpan nomor urut per uuid untuk DS log
        _uuidIndex[r.uuid] = i
        _uuidIndex[r.u8]   = i  -- shorthand juga
    end

    lbList.Text = table.concat(lines, "\n")
    lbList.TextColor3 = Color3.fromRGB(140, 220, 140)
    copyBuf = table.concat(copyLines, "\n")

    -- label nomor di atas pet di workspace
    task.spawn(function()
        -- hapus label lama dulu
        for _, bb in ipairs(workspace:GetDescendants()) do
            if bb:IsA("BillboardGui") and bb.Name == "_DBG_PET_NUM" then
                pcall(function() bb:Destroy() end)
            end
        end

        -- scan seluruh workspace: cari Model/BasePart yang namanya = uuid kita
        local placed = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not (obj:IsA("Model") or obj:IsA("BasePart")) then continue end
            local n = tostring(obj.Name):gsub("[{}]","")
            local idx = _uuidIndex[n] or _uuidIndex[n:sub(1,8)]
            if not idx then continue end

            -- cari root part untuk adornee
            local rootPart = nil
            if obj:IsA("BasePart") then
                rootPart = obj
            elseif obj:IsA("Model") then
                rootPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end
            if not rootPart then continue end

            -- jangan duplikat kalau sudah ada billboard
            local existing = rootPart:FindFirstChild("_DBG_PET_NUM")
            if existing then existing:Destroy() end

            local bb = Instance.new("BillboardGui")
            bb.Name = "_DBG_PET_NUM"
            bb.Size = UDim2.new(0, 44, 0, 22)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = rootPart
            bb.Parent = rootPart

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            lbl.BackgroundTransparency = 0.3
            lbl.BorderSizePixel = 0
            lbl.TextColor3 = Color3.fromRGB(255, 230, 80)
            lbl.TextSize = 13
            lbl.Font = Enum.Font.GothamBold
            lbl.Text = "#"..idx
            lbl.Parent = bb
            placed = placed + 1
        end
        -- log berapa label yang berhasil dipasang
        lbInfo.Text = lbInfo.Text .. "  labels:"..placed
    end)

    if not rcErr then
        lbInfo.Text = "✓ RC  total: " .. total .. " pet"
        lbInfo.TextColor3 = Color3.fromRGB(100, 220, 100)
    end
end

-- ── Tombol ────────────────────────────────────────────────────────────────────
btnRefresh.MouseButton1Click:Connect(function()
    task.spawn(refresh)
end)

btnCopy.MouseButton1Click:Connect(function()
    if copyBuf == "" then return end
    -- coba setclipboard dulu (Arceus X / executor)
    local ok1 = pcall(function() setclipboard(copyBuf) end)
    if ok1 then
        btnCopy.Text = "✓ COPIED"
        task.delay(1.5, function() btnCopy.Text = "📋 COPY" end)
        return
    end
    -- fallback: TextBox select-all trick
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0, 1, 0, 1)
    tb.Position = UDim2.new(0, 0, 2, 0) -- di luar layar
    tb.BackgroundTransparency = 1
    tb.TextTransparency = 1
    tb.Text = copyBuf
    tb.Parent = panel
    tb:CaptureFocus()
    game:GetService("UserInputService"):SendKeyEvent(true,
        Enum.KeyCode.A, false, game)
    task.wait(0.05)
    tb:ReleaseFocus()
    tb:Destroy()
    btnCopy.Text = "✓ OK(fb)"
    task.delay(1.5, function() btnCopy.Text = "📋 COPY" end)
end)

btnRejoin.MouseButton1Click:Connect(function()
    btnRejoin.Text = "⟳ joining..."
    btnRejoin.BackgroundColor3 = Color3.fromRGB(80, 20, 80)
    task.spawn(function()
        pcall(function()
            local TS = game:GetService("TeleportService")
            TS:Teleport(game.PlaceId, plr)
        end)
    end)
end)

btnClose.MouseButton1Click:Connect(function()
    _autoRunning = false
    sg:Destroy()
end)

-- auto refresh tiap 5s + update _currentContainer
task.spawn(function()
    while _autoRunning and sg and sg.Parent do
        pcall(refresh)
        -- update container cache untuk DS listener
        local c, _ = fetchRC()
        if not c then c = _G and _G._kgContainer end
        if c then _currentContainer = c end
        task.wait(5)
    end
end)

-- ── DS Listener — swap events, filter mine only ───────────────────────────────
local MAX_DS = 120
local dsLines = {}
local _currentContainer = nil  -- cache container terbaru untuk lookup cepat

-- init container sekarang (sinkron) biar siap sebelum event pertama masuk
do
    local c, _ = fetchRC()
    if not c then c = _G and _G._kgContainer end
    _currentContainer = c
end

local function ts()
    return string.format("%.1f", os.clock() % 1000)
end

local function addDS(line)
    table.insert(dsLines, 1, line)
    if #dsLines > MAX_DS then dsLines[#dsLines] = nil end
    lbDS.Text = table.concat(dsLines, "\n")
end

local SWAP_ANIM = {roar=true, fan=true, weave=true}

local gs  = RS:WaitForChild("GameEvents", 10)
local ds2 = gs and gs:WaitForChild("DataStream", 10)

if ds2 then
    ds2.OnClientEvent:Connect(function(...)
        local args = {...}
        local svc = tostring(args[2] or "")
        if not svc:find("ActivePets", 1, true) then return end
        local data = type(args[3])=="table" and args[3] or (type(args[4])=="table" and args[4]) or nil
        if not data then return end

        local cont = _currentContainer
        if not cont then return end

        for _, v in pairs(data) do
            if type(v) == "table" then
                local v1 = tostring(v[1] or "")
                if v1:find("CustomAnimationState", 1, true) and v[2] ~= nil then
                    local uuid = v1:match("{([^}]+)}") or v1:match("/([^/]+)/CustomAnimationState") or "?"
                    local raw  = uuid:gsub("[{}]", "")
                    local anim = tostring(v[2]):lower()
                    if not SWAP_ANIM[anim] then continue end

                    -- filter: hanya UUID milik kita
                    local entry = cont[raw] or cont["{"..raw.."}"]
                    if not entry then continue end

                    -- ambil age & kg
                    local age, kg, tipe = "?", "?", "?"
                    pcall(function()
                        local pd = entry.PetData or entry
                        local a = pd.Level or pd.Age or pd.level or pd.age
                        if a ~= nil then age = tostring(a) end
                        local k = pd.BaseWeight or pd.Weight or pd.kg
                        if k ~= nil then kg = string.format("%.2f", k) end
                        local t = entry.PetType or entry.PetId or entry.Type
                        if t ~= nil then tipe = tostring(t):sub(1,10) end
                    end)

                    local r8 = raw:sub(1,8)
                    local reReady = _equipRE ~= nil
                    local numTag = _uuidIndex[raw] and ("#"..tostring(_uuidIndex[raw])) or _uuidIndex[r8] and ("#"..tostring(_uuidIndex[r8])) or "?"
                    -- log event masuk
                    addDS(ts().." ▶ "..anim:upper().." "..numTag.." "..r8.." a="..age.." k="..kg)
                    swapDbg("EVT "..anim.." "..r8.." re="..tostring(reReady))

                    task.spawn(function()
                        -- ── STEP 1: UNEQUIP ──────────────────────────────────
                        -- paksa refind tiap kali biar tidak pakai RE stale
                        _equipRE = findEquipRE()

                        addDS("  ℹ RE="..((_equipRE and _equipRE:GetFullName()) or "nil"))

                        if not _equipRE then
                            addDS("  ✗ UNEQ-FAIL: PetsService RE not found (cek nama RE)")
                            swapDbg("UNEQ-FAIL: no RE")
                            return
                        end

                        if not _equipRE.Parent then
                            addDS("  ✗ UNEQ-FAIL: RE orphan (parent=nil), refind...")
                            swapDbg("UNEQ-FAIL: orphan RE, refind")
                            _equipRE = findEquipRE()
                            if not _equipRE then
                                addDS("  ✗ UNEQ-FAIL: refind gagal")
                                return
                            end
                            addDS("  ↺ RE refound OK")
                        end

                        -- UNEQ x3 dengan jeda 0.1s
                        local u1Ok = pcall(function() _equipRE:FireServer("UnequipPet", fmtUUID(raw)) end)
                        addDS("  UNEQ#1 "..(u1Ok and "✓" or "✗").." "..r8)
                        task.wait(0.1)
                        local u2Ok = pcall(function() _equipRE:FireServer("UnequipPet", fmtUUID(raw)) end)
                        addDS("  UNEQ#2 "..(u2Ok and "✓" or "✗").." "..r8)
                        task.wait(0.1)
                        local u3Ok = pcall(function() _equipRE:FireServer("UnequipPet", fmtUUID(raw)) end)
                        addDS("  UNEQ#3 "..(u3Ok and "✓" or "✗").." "..r8)
                        task.wait(0.1)

                        -- equip
                        local eOk, eErr = pcall(function()
                            _equipRE:FireServer("EquipPet", fmtUUID(raw), getSpawnCF())
                        end)
                        if eOk then
                            addDS("  ✓ EQ-OK "..numTag.." "..r8.." ✔")
                            swapDbg("EQ-OK "..r8)
                        else
                            addDS("  ✗ EQ-ERR: "..tostring(eErr):sub(1,60))
                            swapDbg("EQ-ERR "..r8..": "..tostring(eErr):sub(1,40))
                        end

                        -- ── flash warna label di billboard pet ───────────────
                        pcall(function()
                            -- scan workspace: cari object dengan nama = raw/r8
                            for _, obj in ipairs(workspace:GetDescendants()) do
                                local cn = tostring(obj.Name):gsub("[{}]","")
                                if cn ~= raw and cn:sub(1,8) ~= r8 then continue end
                                -- cari billboard di obj atau descendantsnya
                                local bb = nil
                                if obj:IsA("BasePart") then
                                    bb = obj:FindFirstChild("_DBG_PET_NUM")
                                elseif obj:IsA("Model") then
                                    for _, d in ipairs(obj:GetDescendants()) do
                                        if d:IsA("BillboardGui") and d.Name == "_DBG_PET_NUM" then bb = d; break end
                                    end
                                end
                                if not bb then continue end
                                local lbl = bb:FindFirstChildWhichIsA("TextLabel")
                                if not lbl then continue end
                                local flashColor = eOk and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
                                lbl.BackgroundColor3 = flashColor
                                lbl.TextColor3 = Color3.fromRGB(0, 0, 0)
                                lbl.Text = numTag.." ★"
                                task.wait(1.5)
                                if lbl and lbl.Parent then
                                    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                    lbl.TextColor3 = Color3.fromRGB(255, 230, 80)
                                    lbl.Text = numTag
                                end
                            end
                        end)
                    end)
                end
            end
        end
    end)
    addDS("✓ DS connected — menunggu event...")
else
    addDS("❌ DataStream tidak ditemukan")
end

-- update _currentContainer tiap auto-refresh (5s)

print("[debug_garden_uuid] aktif")
