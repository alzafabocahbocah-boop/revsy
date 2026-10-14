-- ============================================================
-- DBG SKILL PET v0.1
-- Sniff semua cara detect skill pet:
--   1. Sound listener (DescendantAdded di PetsPhysical)
--   2. PetCooldownsUpdated RemoteEvent (Time <= 0 = ready -> fire)
--   3. Attribute berubah di pet model (PET_UUID dst)
--   4. RemoteEvent apapun yg di-fire client saat skill
--   5. AnimationTrack played di pet model
-- ============================================================
local RS   = game:GetService("ReplicatedStorage")
local RunS = game:GetService("RunService")
local player = game.Players.LocalPlayer

local LOG = {}
local function lg(src, msg)
    local t = string.format("[%.2f][%s] %s", os.clock(), src, msg)
    table.insert(LOG, t)
    print(t)
end

-- ── 1. SOUND LISTENER (dinonaktifkan) ──────────────────────

-- ── 2. PetCooldownsUpdated (dinonaktifkan) ─────────────────

-- ── 3. ATTRIBUTE CHANGED di pet model ──────────────────────
task.spawn(function()
    local pp = workspace:WaitForChild("PetsPhysical", 15)
    if not pp then return end
    -- track pet yg udah ada
    local tracked = {}
    local function trackPet(obj)
        if not obj:IsA("Model") then return end
        local uuid = obj:GetAttribute("PET_UUID")
        if not uuid or tracked[tostring(uuid)] then return end
        tracked[tostring(uuid)] = true
        obj.AttributeChanged:Connect(function(attr)
            lg("ATTR", string.format("uuid=%s attr=%s val=%s",
                tostring(uuid), attr, tostring(obj:GetAttribute(attr))))
        end)
    end
    for _, c in ipairs(pp:GetChildren()) do trackPet(c) end
    pp.ChildAdded:Connect(trackPet)
    lg("ATTR", "attribute watcher ON")
end)

-- ── 4. DataStream — CustomAnimationState dari server ──
local lastAnim = {}
local function scanAnim(t, depth)
    depth = depth or 0
    if depth > 6 or type(t) ~= "table" then return end
    for _, v in pairs(t) do
        if type(v) == "table" then
            local path = tostring(v[1] or "")
            if path:find("CustomAnimationState", 1, true) then
                local uuid = path:match("{([^}]+)}") or "?"
                local animStr = tostring(v[2] or "")
                local SKIP = { Eat=true, Idle=true, Walk=true, Run=true }
                if not SKIP[animStr] and animStr ~= "" then
                    if lastAnim[uuid] ~= animStr then
                        lastAnim[uuid] = animStr
                        lg("SKILL", string.format("uuid=%s → %s", uuid:sub(1,8), animStr))
                    end
                elseif SKIP[animStr] then
                    lastAnim[uuid] = nil  -- reset biar skill berikutnya ke-log
                end
            else
                scanAnim(v, depth+1)
            end
        end
    end
end

task.spawn(function()
    local ge = RS:WaitForChild("GameEvents", 10)
    if not ge then return end
    local ds = ge:WaitForChild("DataStream", 10)
    if not ds then lg("DS", "DataStream not found"); return end
    ds.OnClientEvent:Connect(function(_, service, data)
        if not tostring(service):find("ActivePets", 1, true) then return end
        if type(data) == "table" then scanAnim(data) end
    end)
    lg("DS", "CustomAnimationState watcher ON")
end)

-- ── 5. ANIMATION (dinonaktifkan) ───────────────────────────

lg("DBG", "dbg_skill_pet v0.1 LOADED — tunggu event...")

-- ── GUI MENGAMBANG (Rejoin) ─────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgSkillGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 110, 0, 36)
frame.Position = UDim2.new(0, 10, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.Text = "⟳ REJOIN"
btn.BorderSizePixel = 0
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseButton1Click:Connect(function()
    btn.Text = "..."
    game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
end)
