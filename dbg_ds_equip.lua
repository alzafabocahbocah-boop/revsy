-- dbg_ds_equip.lua — bandingin DS animation vs equip state
-- Pas DS kasih CustomAnimationState (anim frill/skill) → cek uuid itu
-- masih ke-equip di garden (PetsPhysical) atau udah unequip (Backpack)
-- Overlay mengambang pojok kanan, draggable, max 12 baris log

local RS     = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

-- ── helper: cek equip state dari uuid ──────────────────────
local function getEquipState(uuid)
    -- format uuid bisa {xxx} atau xxx saja
    local bare = tostring(uuid):gsub("[{}]", "")
    local withBrace = "{" .. bare .. "}"

    -- cek PetsPhysical (equip di garden)
    local pp = workspace:FindFirstChild("PetsPhysical")
    if pp then
        for _, m in ipairs(pp:GetChildren()) do
            local n = m.Name
            if n == withBrace or n == bare then return "EQUIP" end
        end
    end

    -- cek Backpack (unequip)
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:GetAttribute("PET_UUID") == withBrace
            or t:GetAttribute("PET_UUID") == bare then
                return "UNEQUIP"
            end
        end
    end

    return "?"
end

-- ── GUI mengambang ──────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "ZenxDsEquipDbg"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 99997
sg.Parent = player:WaitForChild("PlayerGui")

local fr = Instance.new("Frame")
fr.AnchorPoint = Vector2.new(1, 0)
fr.Size = UDim2.new(0, 300, 0, 290)
fr.Position = UDim2.new(1, -12, 0, 90)   -- di bawah upkg debug overlay
fr.BackgroundColor3 = Color3.fromRGB(14, 20, 26)
fr.BackgroundTransparency = 0.08
fr.BorderSizePixel = 0
fr.Active = true
fr.Draggable = true
fr.Parent = sg
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 10)
local stk = Instance.new("UIStroke", fr)
stk.Color = Color3.fromRGB(251, 191, 36); stk.Thickness = 1.4

-- header
local hdr = Instance.new("TextLabel")
hdr.Size = UDim2.new(1, -12, 0, 18)
hdr.Position = UDim2.new(0, 8, 0, 4)
hdr.BackgroundTransparency = 1
hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 10
hdr.TextXAlignment = Enum.TextXAlignment.Left
hdr.TextColor3 = Color3.fromRGB(251, 191, 36)
hdr.Text = "🎬 DS ANIM vs EQUIP STATE"
hdr.Parent = fr

-- counter
local ctrLbl = Instance.new("TextLabel")
ctrLbl.Size = UDim2.new(0, 80, 0, 18)
ctrLbl.Position = UDim2.new(1, -88, 0, 4)
ctrLbl.BackgroundTransparency = 1
ctrLbl.Font = Enum.Font.Gotham; ctrLbl.TextSize = 9
ctrLbl.TextXAlignment = Enum.TextXAlignment.Right
ctrLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
ctrLbl.Text = "total: 0"
ctrLbl.Parent = fr

-- separator line
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -16, 0, 1)
sep.Position = UDim2.new(0, 8, 0, 24)
sep.BackgroundColor3 = Color3.fromRGB(50, 60, 70)
sep.BorderSizePixel = 0
sep.Parent = fr

-- scroll frame untuk log baris
local sf = Instance.new("ScrollingFrame")
sf.Size = UDim2.new(1, -8, 1, -34)
sf.Position = UDim2.new(0, 4, 0, 28)
sf.BackgroundTransparency = 1
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 3
sf.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
sf.Parent = fr

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = sf

-- ── log system ─────────────────────────────────────────────
local MAX_ROWS = 30
local rows = {}
local totalCount = 0

local COLOR_EQUIP   = Color3.fromRGB(74, 222, 128)   -- hijau = masih equip (normal)
local COLOR_UNEQUIP = Color3.fromRGB(248, 113, 113)  -- merah = udah unequip (aneh!)
local COLOR_UNKNOWN = Color3.fromRGB(148, 163, 184)  -- abu = gak ketemu

local function addRow(uuid8, anim, state)
    totalCount = totalCount + 1
    ctrLbl.Text = "total: " .. totalCount

    -- buat label baru
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -6, 0, 14)
    lb.BackgroundTransparency = 1
    lb.Font = Enum.Font.Code; lb.TextSize = 10
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.TextTruncate = Enum.TextTruncate.AtEnd
    lb.LayoutOrder = totalCount

    local ts = string.format("%05.1f", os.clock() % 1000)
    lb.Text = string.format("[%s] %s  %-18s  %s", ts, uuid8, anim, state)
    lb.TextColor3 = (state == "EQUIP") and COLOR_EQUIP
                 or (state == "UNEQUIP") and COLOR_UNEQUIP
                 or COLOR_UNKNOWN
    lb.Parent = sf
    table.insert(rows, lb)

    -- hapus baris lama kalau lebih dari MAX_ROWS
    if #rows > MAX_ROWS then
        rows[1]:Destroy()
        table.remove(rows, 1)
    end

    -- scroll ke bawah
    task.defer(function()
        sf.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- ── DS listener ────────────────────────────────────────────
local lastAnim = {}
local SKIP = { Eat=true, Idle=true, Walk=true, Run=true, [""] = true }

local function scanAnim(t, depth)
    depth = depth or 0
    if depth > 6 or type(t) ~= "table" then return end
    for _, v in pairs(t) do
        if type(v) == "table" then
            local path = tostring(v[1] or "")
            if path:find("CustomAnimationState", 1, true) then
                local uuid = path:match("{([^}]+)}") or "?"
                local anim  = tostring(v[2] or "")
                if not SKIP[anim] then
                    if lastAnim[uuid] ~= anim then
                        lastAnim[uuid] = anim
                        local state = getEquipState(uuid)
                        addRow(uuid:sub(1,8), anim, state)
                    end
                else
                    lastAnim[uuid] = nil  -- reset biar event berikutnya ke-log
                end
            else
                scanAnim(v, depth + 1)
            end
        end
    end
end

task.spawn(function()
    local ge = RS:WaitForChild("GameEvents", 15)
    if not ge then addRow("?", "ERR", "GameEvents nil"); return end
    local ds = ge:WaitForChild("DataStream", 15)
    if not ds then addRow("?", "ERR", "DataStream nil"); return end

    addRow("SYSTEM", "DS connected", "OK")

    ds.OnClientEvent:Connect(function(_, service, data)
        if not tostring(service):find("ActivePets", 1, true) then return end
        if type(data) == "table" then scanAnim(data) end
    end)
end)
