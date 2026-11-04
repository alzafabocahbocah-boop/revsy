-- dbg_trigger.lua v1.0
-- Debug: cari semua jalur trigger Frill/Fan, bandingkan timing
-- Sumber yang di-monitor:
--   1. AnimationPlayed (Animator di model pet)
--   2. DataStream (GameEvents.DataStream, CustomAnimationState)
--   3. Sound (SoundId Frill/Fan di model pet)
--   4. PetCooldownsUpdated / PCU (Time=0)
--   5. DescendantAdded animasi (track name di Humanoid)

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local plr     = Players.LocalPlayer

-- ===== GUI =====
local sg = Instance.new("ScreenGui")
sg.Name = "ZenxTrigDbg"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.DisplayOrder = 999999
sg.Parent = (gethui and gethui()) or plr:WaitForChild("PlayerGui")

local fr = Instance.new("Frame", sg)
fr.Size = UDim2.new(0, 340, 0, 320)
fr.Position = UDim2.new(0, 4, 0.2, 0)
fr.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
fr.BackgroundTransparency = 0.05
fr.Active = true; fr.Draggable = true
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
local st = Instance.new("UIStroke", fr)
st.Color = Color3.fromRGB(100, 180, 255); st.Thickness = 1.5

local hdr = Instance.new("TextLabel", fr)
hdr.Size = UDim2.new(1,-60,0,22); hdr.Position = UDim2.new(0,8,0,4)
hdr.BackgroundTransparency = 1; hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 11
hdr.TextColor3 = Color3.fromRGB(100,180,255)
hdr.TextXAlignment = Enum.TextXAlignment.Left
hdr.Text = "TRIG DBG  (2x tap = salin)"

local clrBtn = Instance.new("TextButton", fr)
clrBtn.Size = UDim2.new(0,42,0,16); clrBtn.Position = UDim2.new(1,-48,0,4)
clrBtn.BackgroundColor3 = Color3.fromRGB(0,15,30); clrBtn.Text = "clear"
clrBtn.Font = Enum.Font.GothamBold; clrBtn.TextSize = 10
clrBtn.TextColor3 = Color3.fromRGB(100,180,255)
Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0,4)

local tx = Instance.new("TextLabel", fr)
tx.Size = UDim2.new(1,-10,1,-30); tx.Position = UDim2.new(0,6,0,28)
tx.BackgroundTransparency = 1; tx.Font = Enum.Font.Code; tx.TextSize = 10
tx.TextColor3 = Color3.fromRGB(220,220,180)
tx.TextXAlignment = Enum.TextXAlignment.Left
tx.TextYAlignment = Enum.TextYAlignment.Top
tx.TextWrapped = true

-- ===== LOG =====
local LOG = {}
-- epoch = tick() saat pertama kali ada event (buat relative ms)
local epoch = nil
local function push(src, kind, extra)
    local now = tick()
    if not epoch then epoch = now end
    local rel_ms = math.floor((now - epoch) * 1000)
    -- format: +12345ms | SRC    | FRILL | extra
    local line = string.format("+%-6dms | %-10s | %-5s | %s", rel_ms, src, kind, extra or "")
    table.insert(LOG, 1, line)
    if #LOG > 500 then table.remove(LOG) end
    -- reset epoch tiap 30 detik biar angka gak terlalu gede
    if now - epoch > 30 then epoch = now end
end

clrBtn.MouseButton1Click:Connect(function() LOG = {}; epoch = nil end)
local lastTap = 0
fr.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local now = tick()
        if now - lastTap < 0.45 then
            local body = "TRIG DBG (total="..#LOG.."):\n\n"..table.concat(LOG,"\n")
            if setclipboard then pcall(setclipboard, body)
            elseif toclipboard then pcall(toclipboard, body) end
        end
        lastTap = now
    end
end)

-- ===== HELPERS =====
local FRILL_SOUND  = "5879280084"
local FAN_SOUND    = "5703683838"
local FRILL_ANIMID = "50996247"
local FAN_ANIMID   = "84309615"

local function isPetModel(d)
    if not d:IsA("Model") then return false end
    return d.Name:match("^{?%x%x%x%x%x%x%x%x%-") ~= nil
end
local function short(name)
    return tostring(name):gsub("[{}]",""):sub(1,8)
end

-- ===== [1] ANIMATION PLAYED =====
local function hookAnimator(model)
    if not isPetModel(model) then return end
    pcall(function()
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Animator") then
                desc.AnimationPlayed:Connect(function(track)
                    local animId = ""
                    pcall(function()
                        animId = track.Animation and tostring(track.Animation.AnimationId) or ""
                    end)
                    local isFrill = animId:find(FRILL_ANIMID) ~= nil
                    local isFan   = animId:find(FAN_ANIMID)   ~= nil
                    if not (isFrill or isFan) then return end
                    local kind = isFrill and "FRILL" or "FAN"
                    push("ANIM_PLAY", kind, short(model.Name) .. " id=" .. animId:match("%d+$"))
                end)
            end
        end
    end)
end

pcall(function()
    for _, d in ipairs(workspace:GetDescendants()) do
        if isPetModel(d) then hookAnimator(d) end
    end
    workspace.DescendantAdded:Connect(function(d)
        task.defer(function()
            pcall(function()
                if isPetModel(d) then hookAnimator(d) end
            end)
        end)
    end)
end)

-- ===== [2] DATA STREAM =====
pcall(function()
    local ge = RS:WaitForChild("GameEvents", 10)
    if not ge then push("DS", "ERR", "GameEvents nil"); return end
    local ds = ge:WaitForChild("DataStream", 10)
    if not ds then push("DS", "ERR", "DataStream nil"); return end

    local function deepFind(t, depth, out)
        depth = depth or 0; out = out or {}
        if depth > 12 or type(t) ~= "table" then return out end
        for _, v in pairs(t) do
            if type(v) == "table" then
                local v1 = tostring(v[1] or "")
                if v1:find("CustomAnimationState", 1, true) and v[2] ~= nil then
                    local uuid = v1:match("{([^}]+)}") or v1:match("/([^/]+)/CustomAnimationState") or "?"
                    local animStr = tostring(v[2]):lower()
                    out[#out+1] = {uuid:gsub("[{}]",""):sub(1,8), animStr}
                else
                    deepFind(v, depth+1, out)
                end
            end
        end
        return out
    end

    local _lastDS = 0
    ds.OnClientEvent:Connect(function(...)
        local now = tick()
        if now - _lastDS < 0.05 then return end
        _lastDS = now
        local args = {...}
        local svc = tostring(args[2] or "")
        if not svc:find("ActivePets", 1, true) then return end
        local data = type(args[3])=="table" and args[3] or (type(args[4])=="table" and args[4] or nil)
        if not data then return end
        local hits = deepFind(data, 0)
        for _, hit in ipairs(hits) do
            local uuid8, animStr = hit[1], hit[2]
            push("DATASTREAM", animStr:upper(), uuid8 .. " state=" .. animStr)
        end
    end)
    push("DS", "OK", "DataStream hooked")
end)

-- ===== [3] SOUND =====
local function hookSounds(model)
    if not isPetModel(model) then return end
    pcall(function()
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Sound") then
                local sid = tostring(desc.SoundId or "")
                local isFrill = sid:find(FRILL_SOUND) ~= nil
                local isFan   = sid:find(FAN_SOUND) ~= nil
                if isFrill or isFan then
                    local kind = isFrill and "FRILL" or "FAN"
                    desc.Played:Connect(function()
                        push("SOUND", kind, short(model.Name) .. " snd=" .. sid:match("%d+$"))
                    end)
                end
            end
        end
    end)
end

pcall(function()
    for _, d in ipairs(workspace:GetDescendants()) do
        if isPetModel(d) then hookSounds(d) end
    end
    workspace.DescendantAdded:Connect(function(d)
        task.defer(function()
            pcall(function()
                if isPetModel(d) then hookSounds(d) end
            end)
        end)
    end)
end)

-- ===== [4] PCU (PetCooldownsUpdated, Time=0) =====
pcall(function()
    local ge = RS:FindFirstChild("GameEvents")
    local pcu = ge and ge:FindFirstChild("PetCooldownsUpdated")
    if not pcu then push("PCU", "ERR", "not found"); return end
    pcu.OnClientEvent:Connect(function(uuid, data)
        if type(data) ~= "table" then return end
        for _, v in ipairs(data) do
            if type(v) == "table" and type(v.Time) == "number" and v.Time <= 0 then
                local p = tostring(v.Passive or ""):lower()
                if not p:find("mutation") then
                    push("PCU", "RDY", short(tostring(uuid)) .. " passive=" .. (v.Passive or "?"))
                end
            end
        end
    end)
    push("PCU", "OK", "hooked")
end)

-- ===== [5] ANIMATE SCRIPT (LocalScript "Animate" di Character-like) =====
-- Beberapa pet punya LocalScript atau Script bernama "Animate" yang set AnimationId
-- Coba hook ChangeHistoryService atau attribute change
pcall(function()
    local function hookAttrib(model)
        if not isPetModel(model) then return end
        model.AttributeChanged:Connect(function(attr)
            local val = model:GetAttribute(attr)
            if type(val) == "string" then
                local vl = val:lower()
                if vl == "frill" or vl == "fan" or vl == "attack" then
                    push("ATTRIB", vl:upper(), short(model.Name) .. " attr=" .. attr)
                end
            end
        end)
    end
    for _, d in ipairs(workspace:GetDescendants()) do
        if isPetModel(d) then hookAttrib(d) end
    end
    workspace.DescendantAdded:Connect(function(d)
        task.defer(function()
            pcall(function() if isPetModel(d) then hookAttrib(d) end end)
        end)
    end)
end)

-- ===== [6] VALUE OBJECTS (StringValue/BoolValue bernama "AnimationState" dll) =====
pcall(function()
    local ANIM_VALS = { "animationstate", "state", "animation", "customanimationstate", "skill" }
    local function hookValues(model)
        if not isPetModel(model) then return end
        local function tryHook(obj)
            if obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("IntValue") then
                local n = obj.Name:lower()
                local relevant = false
                for _, kw in ipairs(ANIM_VALS) do
                    if n:find(kw, 1, true) then relevant = true; break end
                end
                if relevant then
                    obj.Changed:Connect(function(val)
                        local vs = tostring(val):lower()
                        if vs == "frill" or vs == "fan" or vs == "attack" or vs == "true" then
                            push("VALUE", vs:upper(), short(model.Name) .. " obj=" .. obj.Name)
                        end
                    end)
                end
            end
        end
        for _, d in ipairs(model:GetDescendants()) do tryHook(d) end
        model.DescendantAdded:Connect(function(d) pcall(tryHook, d) end)
    end
    for _, d in ipairs(workspace:GetDescendants()) do
        if isPetModel(d) then hookValues(d) end
    end
    workspace.DescendantAdded:Connect(function(d)
        task.defer(function()
            pcall(function() if isPetModel(d) then hookValues(d) end end)
        end)
    end)
end)

-- ===== UPDATE LOOP =====
task.spawn(function()
    while sg.Parent do
        task.wait(0.4)
        local head = string.format("[total=%d | sources: ANIM_PLAY DataStream SOUND PCU ATTRIB VALUE]\n", #LOG)
        tx.Text = head .. table.concat(LOG, "\n")
    end
end)

push("INIT", "BOOT", "dbg_trigger v1.0 — 6 sources hooked")
