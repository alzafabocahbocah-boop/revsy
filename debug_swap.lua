-- debug_swap.lua — monitor DS roar/fan: kiri=asing, kanan=mine+age/kg
local plr = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local sg = Instance.new("ScreenGui")
sg.Name = "DBG_SWAP"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = plr:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 440, 0, 480)
panel.Position = UDim2.new(0, 8, 0.05, 0)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title.BorderSizePixel = 0
title.Text = "  🔁 DS ROAR DEBUG"
title.TextColor3 = Color3.fromRGB(180,180,220)
title.TextSize = 12
title.Font = Enum.Font.Code
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

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

local btnClr  = mkBtn("CLR",  4,  50, Color3.fromRGB(60,30,30))
local btnCopy = mkBtn("COPY", 58, 60, Color3.fromRGB(30,50,60))

-- header kolom
local function mkHdr(txt, x, w, col)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(0,w,0,14)
    h.Position = UDim2.new(0,x,0,48)
    h.BackgroundColor3 = Color3.fromRGB(20,20,30)
    h.BorderSizePixel = 0
    h.Text = txt
    h.TextColor3 = col
    h.TextSize = 11
    h.Font = Enum.Font.Code
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Parent = panel
end
mkHdr("  ✗ ASING", 4, 210, Color3.fromRGB(220,120,120))
mkHdr("  ✓ MINE (anim | uuid8 | age | kg)", 218, 220, Color3.fromRGB(120,220,140))

-- scroll kiri (asing)
local sfL = Instance.new("ScrollingFrame")
sfL.Size = UDim2.new(0,210,0,380)
sfL.Position = UDim2.new(0,4,0,63)
sfL.BackgroundColor3 = Color3.fromRGB(18,10,10)
sfL.BorderSizePixel = 0
sfL.ScrollBarThickness = 4
sfL.CanvasSize = UDim2.new(0,0,0,0)
sfL.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfL.Parent = panel

local lbL = Instance.new("TextLabel")
lbL.Size = UDim2.new(1,0,0,0)
lbL.AutomaticSize = Enum.AutomaticSize.Y
lbL.BackgroundTransparency = 1
lbL.TextColor3 = Color3.fromRGB(230,100,100)
lbL.TextSize = 10
lbL.Font = Enum.Font.Code
lbL.TextXAlignment = Enum.TextXAlignment.Left
lbL.TextWrapped = true
lbL.Text = "(menunggu...)"
lbL.Parent = sfL

-- scroll kanan (mine)
local sfR = Instance.new("ScrollingFrame")
sfR.Size = UDim2.new(0,218,0,380)
sfR.Position = UDim2.new(0,218,0,63)
sfR.BackgroundColor3 = Color3.fromRGB(10,18,10)
sfR.BorderSizePixel = 0
sfR.ScrollBarThickness = 4
sfR.CanvasSize = UDim2.new(0,0,0,0)
sfR.AutomaticCanvasSize = Enum.AutomaticSize.Y
sfR.Parent = panel

local lbR = Instance.new("TextLabel")
lbR.Size = UDim2.new(1,0,0,0)
lbR.AutomaticSize = Enum.AutomaticSize.Y
lbR.BackgroundTransparency = 1
lbR.TextColor3 = Color3.fromRGB(100,230,120)
lbR.TextSize = 10
lbR.Font = Enum.Font.Code
lbR.TextXAlignment = Enum.TextXAlignment.Left
lbR.TextWrapped = true
lbR.Text = "(menunggu...)"
lbR.Parent = sfR

-- state
local MAX = 150
local linesL, linesR = {}, {}
local copyBuf = {}

local function ts()
    return string.format("%.2f", os.clock() % 1000)
end

local function addL(line)
    table.insert(linesL, 1, line)
    table.insert(copyBuf, 1, "[ASING] "..line)
    if #linesL > MAX then linesL[#linesL] = nil end
    if #copyBuf > 500 then copyBuf[#copyBuf] = nil end
    lbL.Text = table.concat(linesL, "\n")
end

local function addR(line)
    table.insert(linesR, 1, line)
    table.insert(copyBuf, 1, "[MINE] "..line)
    if #linesR > MAX then linesR[#linesR] = nil end
    if #copyBuf > 500 then copyBuf[#copyBuf] = nil end
    lbR.Text = table.concat(linesR, "\n")
end

btnClr.MouseButton1Click:Connect(function()
    linesL={}; linesR={}; copyBuf={}
    lbL.Text=""; lbR.Text=""
end)
btnCopy.MouseButton1Click:Connect(function()
    setclipboard(table.concat(copyBuf,"\n"))
    btnCopy.Text="✓ OK"
    task.delay(1.5, function() btnCopy.Text="COPY" end)
end)

-- helper: cek UUID milik kita
local function getMyUuids()
    local mine = {}
    -- HANYA dari _kgContainer (RC plr.Name) — sudah filter punya kita saja
    -- ZenxModelByUuid TIDAK dipakai — isinya semua model workspace termasuk pet orang lain
    local kgC = _G and _G._kgContainer
    if kgC then
        for uuid in pairs(kgC) do
            mine[tostring(uuid):gsub("[{}]","")] = true
        end
    end
    -- fallback backpack attribute kalau container belum ready
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            local u = t:GetAttribute("PET_UUID") or t:GetAttribute("UUID")
            if u then mine[tostring(u):gsub("[{}]","")] = true end
        end
    end
    return mine
end

-- helper: ambil age + kg dari _kgContainer
local function getPetInfo(raw)
    local kgC = _G and _G._kgContainer
    if not kgC then return "?","?" end
    local entry = kgC[raw] or kgC["{"..raw.."}"]
    if not entry then return "?","?" end
    local pd = entry.PetData
    local age = pd and pd.Level or "?"
    local kg  = pd and pd.BaseWeight or "?"
    return tostring(age), tostring(kg)
end

local SWAP_ANIM = {roar=true, fan=true, weave=true}

local gs = RS:WaitForChild("GameEvents",10)
if not gs then lbL.Text="ERR: GameEvents not found"; return end
local ds2 = gs:WaitForChild("DataStream",10)
if not ds2 then lbL.Text="ERR: DataStream not found"; return end

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
                local t = ts()

                if myUuids[raw] then
                    -- mine: tampilkan age + kg
                    local age, kg = getPetInfo(raw)
                    addR(t.." "..anim.." "..r8.." a="..age.." k="..kg)
                else
                    -- asing: hanya uuid8
                    addL(t.." "..anim.." "..r8)
                end
            end
        end
    end
end)

print("[debug_swap] aktif")
