-- ============================================================
-- DBG EAT SWAP — test swap pet pas CustomAnimationState = Eat
-- Cuma log + simulate swap (gak beneran swap dulu)
-- ============================================================
local RS   = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local function lg(src, msg)
    print(string.format("[%.2f][%s] %s", os.clock(), src, msg))
end

-- ── cari equipRE (sama kayak up6kg) ──────────────────────────
local equipRE
local ge = RS:FindFirstChild("GameEvents")
if ge then
    for _, v in ipairs(ge:GetDescendants()) do
        if v.Name == "PetsService" and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            equipRE = v; break
        end
    end
end
if not equipRE then
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == "PetsService" then equipRE = v; break end
    end
end
lg("INIT", "equipRE = " .. tostring(equipRE and equipRE.ClassName or "NIL"))

local function fmtUUID(u)
    local s = tostring(u)
    if s:sub(1,1) ~= "{" then s = "{" .. s .. "}" end
    return s
end

local function swapPet(uuid)
    if not equipRE then lg("SWAP", "equipRE NIL, skip"); return end
    local u = fmtUUID(uuid)
    lg("SWAP", "UnequipPet " .. u)
    pcall(function() equipRE:FireServer("UnequipPet", u) end)
    task.wait(0.3)
    lg("SWAP", "EquipPet " .. u)
    pcall(function() equipRE:FireServer("EquipPet", u, nil) end)
end


-- ── getgc container (sama kayak up6kg) ───────────────────────
local _kgCache = nil
local function getContainer()
    if _kgCache then
        local ok = false
        pcall(function()
            for _, v in pairs(_kgCache) do
                if type(v) == "table" and rawget(v, "PetData") then ok = true end
                break
            end
        end)
        if ok then return _kgCache end
    end
    if not getgc then return nil end
    local best, bestCount = nil, 0
    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                local uuidLike = 0
                for k in pairs(obj) do
                    if type(k) == "string" and #k >= 32 and k:find("-") then
                        uuidLike = uuidLike + 1
                        if uuidLike >= 50 then break end
                    end
                end
                if uuidLike >= 5 then
                    local sample = nil
                    for _, v in pairs(obj) do sample = v; break end
                    if type(sample) == "table" and rawget(sample, "PetData") then
                        local cnt = 0; for _ in pairs(obj) do cnt = cnt + 1 end
                        if cnt > bestCount then best = obj; bestCount = cnt end
                    end
                end
            end
        end
    end)
    _kgCache = best
    return best
end

-- ── lookup nama pet by uuid ───────────────────────────────────
local function getPetName(uuid)
    local fmtU = "{" .. uuid .. "}"
    -- 1. cari di _kgContainer (paling reliable, ada PetType)
    local c = getContainer()
    if c then
        local entry = c[fmtU]
        if type(entry) == "table" then
            local pt = entry.PetType or (entry.PetData and entry.PetData.PetType)
            if pt then return tostring(pt) end
        end
    end
    -- 2. fallback: Backpack Tool attr "f"
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local toolUuid = tostring(t:GetAttribute("PET_UUID") or "")
                local normUuid = "{" .. toolUuid:gsub("[{}]", "") .. "}"
                if normUuid == fmtU then
                    return tostring(t:GetAttribute("f") or t.Name)
                end
            end
        end
    end
    -- 3. fallback: Character Tool attr "f"
    local char = player.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                local toolUuid = tostring(t:GetAttribute("PET_UUID") or "")
                local normUuid = "{" .. toolUuid:gsub("[{}]", "") .. "}"
                if normUuid == fmtU then
                    return tostring(t:GetAttribute("f") or t.Name)
                end
            end
        end
    end
    return "?"
end

local function isTrex(uuid)
    local t = getPetName(uuid):lower()
    return t:find("t%-rex", 1, true) or t:find("trex", 1, true) or t:find("t_rex", 1, true)
end

-- ── listener CustomAnimationState ────────────────────────────
local SKIP = { Idle=true, Walk=true, Run=true }
local function scanEat(t, depth)
    depth = depth or 0
    if depth > 6 or type(t) ~= "table" then return end
    for _, v in pairs(t) do
        if type(v) == "table" then
            local path = tostring(v[1] or "")
            if path:find("CustomAnimationState", 1, true) then
                local uuid = path:match("{([^}]+)}") or "?"
                local animStr = tostring(v[2] or "")
                local shouldSwap = false
                if animStr ~= "" then
                    if isTrex(uuid) then
                        shouldSwap = (animStr == "Eat")
                    else
                        shouldSwap = not SKIP[animStr]
                    end
                end
                if shouldSwap then
                    local petName = getPetName(uuid)
                    lg("SWAP-TRIGGER", "uuid=" .. uuid:sub(1,8) .. " (" .. petName .. ") [" .. animStr .. "] → swap!")
                    task.spawn(function() swapPet(uuid) end)
                end
            else
                scanEat(v, depth+1)
            end
        end
    end
end

task.spawn(function()
    local ge2 = RS:WaitForChild("GameEvents", 10)
    if not ge2 then lg("ERR", "GameEvents not found"); return end
    local ds = ge2:WaitForChild("DataStream", 10)
    if not ds then lg("ERR", "DataStream not found"); return end
    ds.OnClientEvent:Connect(function(_, service, data)
        if not tostring(service):find("ActivePets", 1, true) then return end
        if type(data) == "table" then scanEat(data) end
    end)
    lg("INIT", "Eat swap listener ON — tunggu pet ngeskill...")
    -- debug: cek container
    task.spawn(function()
        task.wait(3)
        local c = getContainer()
        if c then
            local cnt = 0; for _ in pairs(c) do cnt = cnt + 1 end
            lg("CONTAINER", "found, " .. cnt .. " entries")
            for uuid, entry in pairs(c) do
                if type(entry) == "table" then
                    local pt = entry.PetType or (entry.PetData and entry.PetData.PetType) or "nil"
                    lg("CONTAINER", "sample uuid=" .. tostring(uuid):sub(1,12) .. " PetType=" .. tostring(pt))
                end
                break
            end
        else
            lg("CONTAINER", "NIL — getgc gagal atau container belum ada")
        end
    end)
end)

-- ── GUI Rejoin ────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgEatSwapGui"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 110, 0, 36)
frame.Position = UDim2.new(0, 10, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
btn.Text = "⟳ REJOIN"; btn.BorderSizePixel = 0; btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseButton1Click:Connect(function()
    btn.Text = "..."
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

lg("DBG", "dbg_eat_swap LOADED")
