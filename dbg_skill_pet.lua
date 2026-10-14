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
    local t = string.format("[%s][%s] %s", os.clock():sub(1,7), src, msg)
    table.insert(LOG, t)
    print(t)
end

-- ── 1. SOUND LISTENER ──────────────────────────────────────
task.spawn(function()
    local pp = workspace:WaitForChild("PetsPhysical", 15)
    if not pp then lg("SOUND", "PetsPhysical not found"); return end
    pp.DescendantAdded:Connect(function(obj)
        if not obj:IsA("Sound") then return end
        lg("SOUND", string.format("SoundId=%s  Name=%s  Parent=%s",
            tostring(obj.SoundId), obj.Name, tostring(obj.Parent and obj.Parent.Name)))
    end)
    lg("SOUND", "listener ON di PetsPhysical")
end)

-- ── 2. PetCooldownsUpdated (Time <= 0 = skill ready/fired) ─
task.spawn(function()
    local ge  = RS:WaitForChild("GameEvents", 10)
    if not ge then lg("CD", "GameEvents not found"); return end
    local pcu = ge:WaitForChild("PetCooldownsUpdated", 10)
    if not pcu then lg("CD", "PetCooldownsUpdated not found"); return end
    pcu.OnClientEvent:Connect(function(uuid, data)
        if type(data) ~= "table" then return end
        for i, v in ipairs(data) do
            if type(v) == "table" and type(v.Time) == "number" then
                local passive = tostring(v.Passive or ""):lower()
                if not passive:find("mutation") then
                    if v.Time <= 0 then
                        lg("CD-READY", string.format("uuid=%s skill[%d] %s Time=%.2f",
                            tostring(uuid), i, tostring(v.Passive or v.Name or "?"), v.Time))
                    else
                        lg("CD", string.format("uuid=%s skill[%d] %s Time=%.2f",
                            tostring(uuid), i, tostring(v.Passive or v.Name or "?"), v.Time))
                    end
                end
            end
        end
    end)
    -- minta data cooldown sekarang
    local req = ge:FindFirstChild("RequestPetCooldowns")
    if req and req:IsA("RemoteEvent") then
        pcall(function() req:FireServer() end)
        lg("CD", "RequestPetCooldowns dikirim")
    end
    lg("CD", "listener ON")
end)

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

-- ── 4. SEMUA RemoteEvent di GameEvents (sniff fire) ────────
task.spawn(function()
    local ge = RS:WaitForChild("GameEvents", 10)
    if not ge then return end
    for _, re in ipairs(ge:GetChildren()) do
        if re:IsA("RemoteEvent") then
            local nm = re.Name
            re.OnClientEvent:Connect(function(...)
                local args = {...}
                local parts = {}
                for _, a in ipairs(args) do
                    parts[#parts+1] = tostring(a):sub(1, 40)
                end
                lg("RE:"..nm, table.concat(parts, " | "))
            end)
        end
    end
    lg("RE", "sniff "..#ge:GetChildren().." events di GameEvents")
end)

-- ── 5. ANIMATION di pet (detect animasi skill) ─────────────
task.spawn(function()
    local pp = workspace:WaitForChild("PetsPhysical", 15)
    if not pp then return end
    local function trackAnim(obj)
        if not obj:IsA("Model") then return end
        local uuid = obj:GetAttribute("PET_UUID")
        local hum = obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChildOfClass("AnimationController")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        animator.AnimationPlayed:Connect(function(track)
            lg("ANIM", string.format("uuid=%s anim=%s speed=%.1f",
                tostring(uuid or "?"), track.Name, track.Speed))
        end)
    end
    for _, c in ipairs(pp:GetChildren()) do trackAnim(c) end
    pp.ChildAdded:Connect(trackAnim)
    lg("ANIM", "animation watcher ON")
end)

lg("DBG", "dbg_skill_pet v0.1 LOADED — tunggu event...")
