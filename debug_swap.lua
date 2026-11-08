-- debug_swap.lua — monitor DS swap: skip vs execute, roar count per UUID
-- GUI: panel kiri layar, 2 kolom (SKIP | EXEC), roar counter + pet info (age/kg)

local plr = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- ── GUI ──────────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DBG_SWAP"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = plr:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 440, 0, 560)
panel.Position = UDim2.new(0, 8, 0.05, 0)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = sg

-- title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title.BorderSizePixel = 0
title.Text = "  🔁 SWAP DEBUG  v8.758"
title.TextColor3 = Color3.fromRGB(180,180,220)
title.TextSize = 12
title.Font = Enum.Font.Code
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

-- tombol-tombol
local function mkBtn(txt, x, w, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 20)
    b.Position = UDim2.new(0, x, 0, 26)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(220,220,220)
    b.TextSize = 11
    b.Font = Enum.Font.Code
    b.Parent = panel
    return b
end

local btnClr  = mkBtn("CLR",     4,   50, Color3.fromRGB(60,30,30))
local btnCopy = mkBtn("COPY",   58,   60, Color3.fromRGB(30,50,60))
local btnRst  = mkBtn("RST CNT",122,  65, Color3.fromRGB(40,40,20))
local btnRef  = mkBtn("REFRESH",191,  70, Color3.fromRGB(30,40,50))

-- ── SECTION: pet info (atas, full width) ─────────────────────────────────────
local hdrPet = Instance.new("TextLabel")
hdrPet.Size = UDim2.new(1,-8,0,14)
hdrPet.Position = UDim2.new(0,4,0,48)
hdrPet.BackgroundColor3 = Color3.fromRGB(20,20,35)
hdrPet.BorderSizePixel = 0
hdrPet.Text = "  UUID PETS  (tipe | uuid8 | age | kg)"
hdrPet.TextColor3 = Color3.fromRGB(160,160,200)
hdrPet.TextSize = 11
hdrPet.Font = Enum.Font.Code
hdrPet.TextXAlignment = Enum.TextXAlignment.Left
hdrPet.Parent = panel

local sfPet = Instance.new("ScrollingFrame")
sfPet.Size = UDim2.new(1,-8,0,120)
sfPet.Position = UDim2.new(0,4,0,63)
sfPet.BackgroundColor3 = Color3.fromRGB(14,14,22)
sfPet.BorderSizePixel = 0
sfPet.ScrollBarThickness = 4
sfPet.CanvasSize = UDim2.new(0,0,0,0)
sfPet.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfPet.Parent = panel

local lbPet = Instance.new("TextLabel")
lbPet.Size = UDim2.new(1,0,0,0)
lbPet.AutomaticSize = Enum.AutomaticSize.Y
lbPet.BackgroundTransparency = 1
lbPet.TextColor3 = Color3.fromRGB(160,220,255)
lbPet.TextSize = 10
lbPet.Font = Enum.Font.Code
lbPet.TextXAlignment = Enum.TextXAlignment.Left
lbPet.TextWrapped = true
lbPet.Text = "(belum di-refresh)"
lbPet.Parent = sfPet

-- ── SECTION: header kolom swap ───────────────────────────────────────────────
local function mkHdr(txt, x, w)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(0,w,0,14)
    h.Position = UDim2.new(0,x,0,185)
    h.BackgroundColor3 = Color3.fromRGB(20,20,30)
    h.BorderSizePixel = 0
    h.Text = txt
    h.TextColor3 = Color3.fromRGB(160,160,200)
    h.TextSize = 11
    h.Font = Enum.Font.Code
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Parent = panel
end
mkHdr("  ✗ SKIP (in-flight)", 4, 210)
mkHdr("  ✓ EXEC",             218, 210)

-- scroll kiri (skip)
local sfSkip = Instance.new("ScrollingFrame")
sfSkip.Size = UDim2.new(0,210,0,250)
sfSkip.Position = UDim2.new(0,4,0,200)
sfSkip.BackgroundColor3 = Color3.fromRGB(18,10,10)
sfSkip.BorderSizePixel = 0
sfSkip.ScrollBarThickness = 4
sfSkip.CanvasSize = UDim2.new(0,0,0,0)
sfSkip.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfSkip.Parent = panel

local lbSkip = Instance.new("TextLabel")
lbSkip.Size = UDim2.new(1,0,0,0)
lbSkip.AutomaticSize = Enum.AutomaticSize.Y
lbSkip.BackgroundTransparency = 1
lbSkip.TextColor3 = Color3.fromRGB(230,100,100)
lbSkip.TextSize = 10
lbSkip.Font = Enum.Font.Code
lbSkip.TextXAlignment = Enum.TextXAlignment.Left
lbSkip.TextWrapped = true
lbSkip.Text = ""
lbSkip.Parent = sfSkip

-- scroll kanan (exec)
local sfExec = Instance.new("ScrollingFrame")
sfExec.Size = UDim2.new(0,210,0,250)
sfExec.Position = UDim2.new(0,218,0,200)
sfExec.BackgroundColor3 = Color3.fromRGB(10,18,10)
sfExec.BorderSizePixel = 0
sfExec.ScrollBarThickness = 4
sfExec.CanvasSize = UDim2.new(0,0,0,0)
sfExec.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfExec.Parent = panel

local lbExec = Instance.new("TextLabel")
lbExec.Size = UDim2.new(1,0,0,0)
lbExec.AutomaticSize = Enum.AutomaticSize.Y
lbExec.BackgroundTransparency = 1
lbExec.TextColor3 = Color3.fromRGB(100,230,120)
lbExec.TextSize = 10
lbExec.Font = Enum.Font.Code
lbExec.TextXAlignment = Enum.TextXAlignment.Left
lbExec.TextWrapped = true
lbExec.Text = ""
lbExec.Parent = sfExec

-- roar counter bar (paling bawah)
local lbCount = Instance.new("TextLabel")
lbCount.Size = UDim2.new(1,-8,0,32)
lbCount.Position = UDim2.new(0,4,0,452)
lbCount.BackgroundColor3 = Color3.fromRGB(18,18,28)
lbCount.BorderSizePixel = 0
lbCount.TextColor3 = Color3.fromRGB(180,180,100)
lbCount.TextSize = 10
lbCount.Font = Enum.Font.Code
lbCount.TextXAlignment = Enum.TextXAlignment.Left
lbCount.TextWrapped = true
lbCount.Text = "roar cnt: —"
lbCount.Parent = panel

-- ── State ─────────────────────────────────────────────────────────────────────
local MAX = 120
local skipLines = {}
local execLines = {}
local roarCount = {}  -- r8 -> {total, skipped}
local copyBuf = {}

local function ts()
    return string.format("%.2f", os.clock() % 1000)
end

local function addSkip(r8, anim)
    local line = ts().." ✗ "..anim.." "..r8
    table.insert(skipLines, 1, line)
    table.insert(copyBuf, 1, "[SKIP] "..line)
    if #skipLines > MAX then skipLines[#skipLines] = nil end
    if #copyBuf > 400 then copyBuf[#copyBuf] = nil end
    lbSkip.Text = table.concat(skipLines, "\n")
end

local function addExec(r8, anim)
    local line = ts().." ✓ "..anim.." "..r8
    table.insert(execLines, 1, line)
    table.insert(copyBuf, 1, "[EXEC] "..line)
    if #execLines > MAX then execLines[#execLines] = nil end
    if #copyBuf > 400 then copyBuf[#copyBuf] = nil end
    lbExec.Text = table.concat(execLines, "\n")
end

local function updateCountBar()
    local parts = {}
    for r8, c in pairs(roarCount) do
        table.insert(parts, r8:sub(1,6)..":"..c.total.."/"..c.skipped.."s")
    end
    table.sort(parts)
    lbCount.Text = (#parts>0 and table.concat(parts,"  ") or "—").." (total/skip)")
end

-- ── Refresh pet info ─────────────────────────────────────────────────────────
local function refreshPetInfo()
    local kgC = _G and _G._kgContainer
    if not kgC then
        lbPet.Text = "_kgContainer belum ready"
        return
    end
    local lines = {}
    for uuid, data in pairs(kgC) do
        local raw = tostring(uuid):gsub("[{}]","")
        local r8 = raw:sub(1,8)
        local pd = data and data.PetData
        local tipe = (data and data.PetType) or "?"
        local age = pd and pd.Level or "?"
        local kg = pd and pd.BaseWeight or "?"
        -- tipe pendek (ambil kata terakhir setelah spasi/titik)
        local tipeShort = tostring(tipe):match("[^ .]+$") or tostring(tipe):sub(1,10)
        table.insert(lines, string.format("%-12s %s  age=%-5s kg=%s", tipeShort, r8, tostring(age), tostring(kg)))
    end
    table.sort(lines)
    if #lines == 0 then
        lbPet.Text = "(kosong)"
    else
        lbPet.Text = table.concat(lines, "\n")
        -- tambah ke copyBuf juga
        table.insert(copyBuf, 1, "=== PET INFO ===\n"..table.concat(lines,"\n"))
    end
end

-- ── Tombol ───────────────────────────────────────────────────────────────────
btnClr.MouseButton1Click:Connect(function()
    skipLines={}; execLines={}; copyBuf={}
    lbSkip.Text=""; lbExec.Text=""
end)

btnCopy.MouseButton1Click:Connect(function()
    setclipboard(table.concat(copyBuf,"\n"))
    btnCopy.Text="✓ OK"
    task.delay(1.5, function() btnCopy.Text="COPY" end)
end)

btnRst.MouseButton1Click:Connect(function()
    roarCount={}; updateCountBar()
end)

btnRef.MouseButton1Click:Connect(function()
    refreshPetInfo()
    btnRef.Text="✓ OK"
    task.delay(1, function() btnRef.Text="REFRESH" end)
end)

-- auto refresh tiap 5s
task.spawn(function()
    while task.wait(5) do
        pcall(refreshPetInfo)
    end
end)

-- ── Helpers ──────────────────────────────────────────────────────────────────
local SWAP_ANIM = {roar=true, fan=true, weave=true}

local function getMyUuids()
    local mine = {}
    local kgC = _G and _G._kgContainer
    if kgC then
        for uuid in pairs(kgC) do
            mine[tostring(uuid):gsub("[{}]","")] = true
        end
    end
    local mbu = _G and _G.ZenxModelByUuid
    if mbu then
        for name in pairs(mbu) do
            mine[tostring(name):gsub("[{}]","")] = true
        end
    end
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            local u = t:GetAttribute("PET_UUID") or t:GetAttribute("UUID")
            if u then mine[tostring(u):gsub("[{}]","")] = true end
        end
    end
    return mine
end

local _inFlight = {}  -- r8 -> tick() saat event pertama

-- ── DS Listener ──────────────────────────────────────────────────────────────
local gs = RS:WaitForChild("GameEvents",10)
if not gs then lbSkip.Text="ERR: GameEvents not found"; return end
local ds2 = gs:WaitForChild("DataStream",10)
if not ds2 then lbSkip.Text="ERR: DataStream not found"; return end

lbSkip.Text = "(menunggu event...)"
lbExec.Text = "(menunggu event...)"

ds2.OnClientEvent:Connect(function(...)
    local args = {...}
    local svc = tostring(args[2] or "")
    if not svc:find("ActivePets",1,true) then return end
    local data = type(args[3])=="table" and args[3] or (type(args[4])=="table" and args[4] or nil)
    if not data then return end

    local myUuids = getMyUuids()

    for _, v in pairs(data) do
        if type(v) == "table" then
            local v1 = tostring(v[1] or "")
            if v1:find("CustomAnimationState",1,true) and v[2] ~= nil then
                local uuid = v1:match("{([^}]+)}") or v1:match("/([^/]+)/CustomAnimationState") or "?"
                local raw = uuid:gsub("[{}]","")
                local anim = tostring(v[2]):lower()
                if not SWAP_ANIM[anim] then continue end

                local r8 = raw:sub(1,8)
                if not myUuids[raw] then continue end  -- skip pet lain

                -- hitung per UUID
                if not roarCount[r8] then roarCount[r8] = {total=0, skipped=0} end
                roarCount[r8].total = roarCount[r8].total + 1

                -- deteksi kemungkinan skip: event kedua < 0.5s dari event sebelumnya
                local now = tick()
                local last = _inFlight[r8]
                if last and (now - last) < 0.5 then
                    roarCount[r8].skipped = roarCount[r8].skipped + 1
                    addSkip(r8, anim)
                else
                    _inFlight[r8] = now
                    addExec(r8, anim)
                end

                updateCountBar()
            end
        end
    end
end)

-- refresh pertama
task.delay(2, function() pcall(refreshPetInfo) end)
print("[debug_swap] aktif")
