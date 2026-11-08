-- debug_destroy_foreign.lua — destroy model pet orang lain di workspace.PetsPhysical
-- test: apakah DS events dari pet asing hilang setelah modelnya di-destroy?

local plr = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- ── GUI ──────────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DBG_DESTROY"
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
title.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
title.BorderSizePixel = 0
title.Text = "  💥 DESTROY FOREIGN + DS MONITOR"
title.TextColor3 = Color3.fromRGB(220,180,180)
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

local btnDestroy  = mkBtn("💥 DESTROY ONCE",  4, 110, Color3.fromRGB(100,30,30))
local btnAutoOn   = mkBtn("▶ AUTO ON",        118,  70, Color3.fromRGB(40,80,40))
local btnAutoOff  = mkBtn("■ AUTO OFF",       192,  70, Color3.fromRGB(60,60,30))
local btnClr      = mkBtn("CLR",              266,  45, Color3.fromRGB(40,40,40))
local btnCopy     = mkBtn("COPY",             315,  55, Color3.fromRGB(30,50,60))

-- status
local lbStatus = Instance.new("TextLabel")
lbStatus.Size = UDim2.new(1,-8,0,14)
lbStatus.Position = UDim2.new(0,4,0,48)
lbStatus.BackgroundColor3 = Color3.fromRGB(20,20,20)
lbStatus.BorderSizePixel = 0
lbStatus.Text = "  status: idle"
lbStatus.TextColor3 = Color3.fromRGB(160,160,160)
lbStatus.TextSize = 10
lbStatus.Font = Enum.Font.Code
lbStatus.TextXAlignment = Enum.TextXAlignment.Left
lbStatus.Parent = panel

-- header kolom
local function mkHdr(txt, x, w, col)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(0,w,0,14)
    h.Position = UDim2.new(0,x,0,63)
    h.BackgroundColor3 = Color3.fromRGB(20,20,30)
    h.BorderSizePixel = 0
    h.Text = txt
    h.TextColor3 = col
    h.TextSize = 11
    h.Font = Enum.Font.Code
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Parent = panel
end
mkHdr("  ✗ ASING (DS event)", 4, 210, Color3.fromRGB(220,120,120))
mkHdr("  ✓ MINE (anim|uuid8)", 218, 220, Color3.fromRGB(120,220,140))

local sfL = Instance.new("ScrollingFrame")
sfL.Size = UDim2.new(0,210,0,375)
sfL.Position = UDim2.new(0,4,0,78)
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

local sfR = Instance.new("ScrollingFrame")
sfR.Size = UDim2.new(0,218,0,375)
sfR.Position = UDim2.new(0,218,0,78)
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

-- ── State ─────────────────────────────────────────────────────────────────────
local MAX = 150
local linesL, linesR = {}, {}
local copyBuf = {}
local _autoConn = nil
local _autoOn = false

local function ts()
    return string.format("%.2f", os.clock() % 1000)
end
local function addL(line)
    table.insert(linesL,1,line); table.insert(copyBuf,1,"[ASING] "..line)
    if #linesL>MAX then linesL[#linesL]=nil end
    if #copyBuf>500 then copyBuf[#copyBuf]=nil end
    lbL.Text=table.concat(linesL,"\n")
end
local function addR(line)
    table.insert(linesR,1,line); table.insert(copyBuf,1,"[MINE] "..line)
    if #linesR>MAX then linesR[#linesR]=nil end
    if #copyBuf>500 then copyBuf[#copyBuf]=nil end
    lbR.Text=table.concat(linesR,"\n")
end
local function setStatus(txt, col)
    lbStatus.Text = "  "..txt
    lbStatus.TextColor3 = col or Color3.fromRGB(160,160,160)
end

-- ── UUID helpers ─────────────────────────────────────────────────────────────
local function getMyUuids()
    local mine = {}
    local kgC = _G and _G._kgContainer
    if kgC then
        for uuid in pairs(kgC) do
            mine[tostring(uuid):gsub("[{}]","")] = true
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

-- ── Destroy logic ─────────────────────────────────────────────────────────────
local function destroyForeign()
    local myUuids = getMyUuids()
    local pp = workspace:FindFirstChild("PetsPhysical")
    if not pp then setStatus("PetsPhysical tidak ada", Color3.fromRGB(220,100,100)); return 0 end

    local del = 0
    for _, obj in ipairs(pp:GetChildren()) do
        if obj:IsA("Model") then
            local raw = tostring(obj.Name):gsub("[{}]","")
            if not myUuids[raw] then
                pcall(function() obj:Destroy() end)
                del = del + 1
            end
        end
    end
    return del
end

-- ── Tombol ───────────────────────────────────────────────────────────────────
btnDestroy.MouseButton1Click:Connect(function()
    local del = destroyForeign()
    setStatus("DESTROY ONCE: "..del.." model dihapus", Color3.fromRGB(220,160,80))
    table.insert(copyBuf, 1, "[ACTION] destroy once: "..del.." del")
end)

btnAutoOn.MouseButton1Click:Connect(function()
    if _autoOn then return end
    _autoOn = true
    setStatus("AUTO ON — destroy tiap ChildAdded", Color3.fromRGB(100,220,100))
    btnAutoOn.BackgroundColor3 = Color3.fromRGB(20,100,20)
    -- destroy existing dulu
    local del = destroyForeign()
    table.insert(copyBuf, 1, "[AUTO] start: "..del.." existing del")
    -- listener ChildAdded
    local pp = workspace:FindFirstChild("PetsPhysical")
    if pp then
        _autoConn = pp.ChildAdded:Connect(function(newObj)
            if not _autoOn then return end
            if not newObj:IsA("Model") then return end
            task.wait(0.08)
            if not newObj or not newObj.Parent then return end
            local raw = tostring(newObj.Name):gsub("[{}]","")
            local myUuids = getMyUuids()
            if not myUuids[raw] then
                local r8 = raw:sub(1,8)
                pcall(function() newObj:Destroy() end)
                table.insert(copyBuf, 1, "[AUTO-DEL] "..r8)
            end
        end)
    else
        setStatus("AUTO ON tapi PetsPhysical tidak ada!", Color3.fromRGB(220,100,100))
    end
end)

btnAutoOff.MouseButton1Click:Connect(function()
    _autoOn = false
    if _autoConn then pcall(function() _autoConn:Disconnect() end); _autoConn = nil end
    setStatus("AUTO OFF", Color3.fromRGB(160,160,80))
    btnAutoOn.BackgroundColor3 = Color3.fromRGB(40,80,40)
end)

btnClr.MouseButton1Click:Connect(function()
    linesL={}; linesR={}; copyBuf={}
    lbL.Text=""; lbR.Text=""
end)
btnCopy.MouseButton1Click:Connect(function()
    setclipboard(table.concat(copyBuf,"\n"))
    btnCopy.Text="✓ OK"
    task.delay(1.5, function() btnCopy.Text="COPY" end)
end)

-- ── DS Listener ──────────────────────────────────────────────────────────────
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
                if myUuids[raw] then
                    addR(ts().." "..anim.." "..r8)
                else
                    addL(ts().." "..anim.." "..r8)
                end
            end
        end
    end
end)

setStatus("ready — tekan DESTROY ONCE atau AUTO ON", Color3.fromRGB(160,160,200))
print("[debug_destroy_foreign] aktif")
