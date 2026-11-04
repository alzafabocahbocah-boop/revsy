-- sc_swap.lua v3.0
-- Trigger: DataStream (GameEvents.DataStream > CustomAnimationState)
-- Skill: frill (dilop), fan (peacock), roar (lion), fly (peryton)
-- ~17ms lebih cepet dari AnimationPlayed
-- Swap: unequip → equip, cek posisi SPAWN (10,3,12), retry 1x kalau miss
-- Frill/Dilop: delay 200ms setelah trigger

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local plr     = Players.LocalPlayer

-- ===== GUI =====
local sg = Instance.new("ScreenGui")
sg.Name = "ZenxScSwap"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.DisplayOrder = 999999
sg.Parent = (gethui and gethui()) or plr:WaitForChild("PlayerGui")

local fr = Instance.new("Frame", sg)
fr.Size = UDim2.new(0, 280, 0, 280)
fr.Position = UDim2.new(0, 4, 0.3, 0)
fr.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
fr.BackgroundTransparency = 0.05
fr.Active = true; fr.Draggable = true
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
local st = Instance.new("UIStroke", fr)
st.Color = Color3.fromRGB(80, 220, 120); st.Thickness = 1.5

local hdr = Instance.new("TextLabel", fr)
hdr.Size = UDim2.new(1,-60,0,22); hdr.Position = UDim2.new(0,8,0,4)
hdr.BackgroundTransparency = 1; hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 11
hdr.TextColor3 = Color3.fromRGB(80,220,120)
hdr.TextXAlignment = Enum.TextXAlignment.Left
hdr.Text = "SC SWAP v3  (2x tap = salin)"

local clrBtn = Instance.new("TextButton", fr)
clrBtn.Size = UDim2.new(0,42,0,16); clrBtn.Position = UDim2.new(1,-48,0,4)
clrBtn.BackgroundColor3 = Color3.fromRGB(0,30,10); clrBtn.Text = "clear"
clrBtn.Font = Enum.Font.GothamBold; clrBtn.TextSize = 10
clrBtn.TextColor3 = Color3.fromRGB(80,220,120)
Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0,4)

local rejBtn = Instance.new("TextButton", fr)
rejBtn.Size = UDim2.new(1,-12,0,22); rejBtn.Position = UDim2.new(0,6,1,-28)
rejBtn.BackgroundColor3 = Color3.fromRGB(180,30,30); rejBtn.Text = "⟳ REJOIN"
rejBtn.Font = Enum.Font.GothamBold; rejBtn.TextSize = 11
rejBtn.TextColor3 = Color3.fromRGB(255,220,220)
Instance.new("UICorner", rejBtn).CornerRadius = UDim.new(0,5)
rejBtn.MouseButton1Click:Connect(function()
    rejBtn.Text = "rejoining..."
    rejBtn.BackgroundColor3 = Color3.fromRGB(100,20,20)
    task.wait(0.3)
    pcall(function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, plr)
    end)
end)

local tx = Instance.new("TextLabel", fr)
tx.Size = UDim2.new(1,-10,1,-30); tx.Position = UDim2.new(0,6,0,28)
tx.BackgroundTransparency = 1; tx.Font = Enum.Font.Code; tx.TextSize = 10
tx.TextColor3 = Color3.fromRGB(220,220,180)
tx.TextXAlignment = Enum.TextXAlignment.Left
tx.TextYAlignment = Enum.TextYAlignment.Top
tx.TextWrapped = true

-- ===== LOG =====
local LOG = {}
local function push(tag, msg)
    local ts = os.date("%H:%M:%S")
    local ms = math.floor((tick() % 1) * 1000)
    local line = string.format("%s.%03d | %-7s | %s", ts, ms, tag, msg)
    table.insert(LOG, 1, line)
    if #LOG > 500 then table.remove(LOG) end
end
clrBtn.MouseButton1Click:Connect(function() LOG = {} end)
local lastTap = 0
fr.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local now = tick()
        if now - lastTap < 0.45 then
            local body = "SC SWAP (total="..#LOG.."):\n\n"..table.concat(LOG,"\n")
            if setclipboard then pcall(setclipboard, body)
            elseif toclipboard then pcall(toclipboard, body) end
        end
        lastTap = now
    end
end)

-- ===== ROBLOX SERVICES =====
local equipRE
pcall(function()
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == "PetsService" and v:IsA("RemoteEvent") then
            equipRE = v; break
        end
    end
    if not equipRE then
        for _, v in pairs(RS:GetDescendants()) do
            if v.Name == "PetsService" then equipRE = v; break end
        end
    end
end)

local function fmtUUID(u)
    local s = tostring(u)
    if s:sub(1,1) ~= "{" then s = "{"..s.."}" end
    return s
end
local function unequipPet(uuid)
    if not equipRE then return end
    pcall(function() equipRE:FireServer("UnequipPet", fmtUUID(uuid)) end)
end
local function equipPet(uuid)
    if not equipRE then return end
    pcall(function() equipRE:FireServer("EquipPet", fmtUUID(uuid), nil) end)
end

-- ===== SKILL TRIGGERS =====
-- animStr → kind label
-- frill = dilophosaurus, fan = peacock, roar = lion/gilded lion, fly = peryton
local SKILL_KIND = {
    frill = "FRILL",
    fan   = "FAN",
    roar  = "ROAR",
    fly   = "FLY",
    pew   = "PEW",    -- hotdog
}
-- skill yang perlu delay 200ms sebelum swap
local SKILL_DELAY = {
    FRILL = 0.2,
}

-- ===== SWAP LOGIC =====
local swapBusy  = {}   -- [uuid8] = true kalau sedang sequence
local CENTER    = Vector3.new(10, 3, 12)   -- default (fan/roar/fly/pew)
local CENTER_FRILL = Vector3.new(11, 22, 8) -- dilop
local CENTER_THRESH = 2.0

local function isPetModel(d)
    if not d:IsA("Model") then return false end
    return d.Name:match("^{?%x%x%x%x%x%x%x%x%-") ~= nil
end
local function short8(uuid)
    return tostring(uuid):gsub("[{}]",""):sub(1,8)
end

local function waitSpawn(targetUUID, timeoutSec)
    local raw8 = short8(targetUUID)
    local done, pos = false, nil
    local conn = workspace.DescendantAdded:Connect(function(d)
        if done then return end
        if not isPetModel(d) then return end
        local dName = d.Name
        local dRaw8 = dName:sub(1,1) == "{" and dName:sub(2,9) or dName:sub(1,8)
        if dRaw8 ~= raw8 then return end
        task.defer(function()
            if done then return end
            pcall(function()
                local part = d:FindFirstChild("HumanoidRootPart") or d:FindFirstChildWhichIsA("BasePart")
                if part then pos = part.Position end
            end)
            done = true
        end)
    end)
    local t0 = tick()
    while not done and (tick() - t0) < timeoutSec do task.wait(0.02) end
    conn:Disconnect()
    return pos
end

local function distToCenter(p, kind)
    if not p then return 999 end
    local c = (kind == "FRILL") and CENTER_FRILL or CENTER
    return math.sqrt((p.X-c.X)^2 + (p.Y-c.Y)^2 + (p.Z-c.Z)^2)
end

local function doSwap(uuid, attempt, kind)
    local r8 = short8(uuid)
    push("SWAP"..attempt, r8 .. " unequip")
    unequipPet(uuid)
    task.wait(0.03)
    push("SWAP"..attempt, r8 .. " equip")
    equipPet(uuid)
    local spawnPos = waitSpawn(uuid, 1.5)
    if spawnPos then
        local dist = distToCenter(spawnPos, kind)
        local posStr = string.format("(%.0f,%.0f,%.0f)", spawnPos.X, spawnPos.Y, spawnPos.Z)
        if dist <= CENTER_THRESH then
            push("OK"..attempt, r8 .. " " .. posStr .. " CENTER ✓")
            return true
        else
            push("MISS"..attempt, r8 .. " " .. posStr .. string.format(" d=%.1f", dist))
            return false
        end
    else
        push("MISS"..attempt, r8 .. " (no spawn)")
        return false
    end
end

local function runSwapSequence(uuid, kind)
    local r8 = short8(uuid)
    if swapBusy[r8] then push("SKIP", r8 .. " busy"); return end
    swapBusy[r8] = true
    push("TRIG", r8 .. " " .. kind)

    local delay = SKILL_DELAY[kind]
    if delay then task.wait(delay) end

    local ok = doSwap(uuid, 1, kind)
    if not ok then
        push("RETRY", r8 .. " attempt 2")
        local ok2 = doSwap(uuid, 2, kind)
        if not ok2 then push("FAIL", r8 .. " gagal 2x") end
    end
    swapBusy[r8] = nil
end

-- ===== TRIGGER: DataStream =====
-- Parse CustomAnimationState dari nested table DataStream
local function deepFind(t, depth, out)
    depth = depth or 0; out = out or {}
    if depth > 12 or type(t) ~= "table" then return out end
    for _, v in pairs(t) do
        if type(v) == "table" then
            local v1 = tostring(v[1] or "")
            if v1:find("CustomAnimationState", 1, true) then
                -- v[2] nil = state di-clear (idle) → skip
                if v[2] ~= nil then
                    local uuid = v1:match("{([^}]+)}") or v1:match("/([^/]+)/CustomAnimationState") or "?"
                    local animStr = tostring(v[2]):lower()
                    out[#out+1] = { uuid:gsub("[{}]",""), animStr }
                end
            else
                deepFind(v, depth+1, out)
            end
        end
    end
    return out
end

-- debounce per uuid: cegah trigger ganda dalam 0.5s
local lastTrigger = {}  -- [uuid8] = tick()
local DS_DEBOUNCE = 0.5

task.spawn(function()
    local ge = RS:WaitForChild("GameEvents", 15)
    if not ge then push("DS", "ERR: GameEvents nil"); return end
    local ds = ge:WaitForChild("DataStream", 15)
    if not ds then push("DS", "ERR: DataStream nil"); return end
    push("DS", "OK — hooked")

    local _lastParse = 0
    ds.OnClientEvent:Connect(function(...)
        local now = tick()
        -- throttle parse: max 20x/s
        if now - _lastParse < 0.05 then return end
        _lastParse = now

        local args = {...}
        local svc = tostring(args[2] or "")
        if not svc:find("ActivePets", 1, true) then return end

        local data = type(args[3])=="table" and args[3] or (type(args[4])=="table" and args[4] or nil)
        if not data then return end

        local hits = deepFind(data, 0)
        for _, hit in ipairs(hits) do
            local rawUUID, animStr = hit[1], hit[2]
            local kind = SKILL_KIND[animStr]
            if not kind then continue end

            local r8 = rawUUID:sub(1,8)
            if lastTrigger[r8] and (now - lastTrigger[r8]) < DS_DEBOUNCE then continue end
            lastTrigger[r8] = now

            task.spawn(function()
                runSwapSequence(rawUUID, kind)
            end)
        end
    end)
end)

-- ===== UPDATE LOOP =====
task.spawn(function()
    while sg.Parent do
        task.wait(0.4)
        local head = string.format("[total=%d]\n", #LOG)
        tx.Text = head .. table.concat(LOG, "\n")
    end
end)

push("INIT", "sc_swap v3.0 | equipRE=" .. (equipRE and "OK" or "NIL"))
