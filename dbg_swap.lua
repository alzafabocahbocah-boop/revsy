-- dbg_swap.lua
-- Debug sc lain: cari tau trigger swap (ready loop / sound / animStr)
-- Jalanin SEBELUM atau BARENG sc yang mau diinvestigasi

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

-- ============ GUI ============
local sg = Instance.new("ScreenGui"); sg.Name = "ZenxSwapDbg"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 999999
sg.Parent = (gethui and gethui()) or plr:WaitForChild("PlayerGui")
local fr = Instance.new("Frame", sg)
fr.Size = UDim2.new(0, 360, 0, 340); fr.Position = UDim2.new(0, 4, 0.5, -170)
fr.BackgroundColor3 = Color3.fromRGB(8, 10, 18); fr.BackgroundTransparency = 0.05
fr.Active = true; fr.Draggable = true
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
local st = Instance.new("UIStroke", fr); st.Color = Color3.fromRGB(255, 180, 50); st.Thickness = 1.5
local hdr = Instance.new("TextLabel", fr)
hdr.Size = UDim2.new(1,-60,0,22); hdr.Position = UDim2.new(0,8,0,4)
hdr.BackgroundTransparency = 1; hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 11
hdr.TextColor3 = Color3.fromRGB(255,180,50); hdr.TextXAlignment = Enum.TextXAlignment.Left
hdr.Text = "SWAP DBG  (tap 2x = salin)"
-- tombol clear
local clrBtn = Instance.new("TextButton", fr)
clrBtn.Size = UDim2.new(0,42,0,16); clrBtn.Position = UDim2.new(1,-48,0,4)
clrBtn.BackgroundColor3 = Color3.fromRGB(40,20,0); clrBtn.Text = "clear"
clrBtn.Font = Enum.Font.GothamBold; clrBtn.TextSize = 10
clrBtn.TextColor3 = Color3.fromRGB(255,160,50)
Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0,4)
-- tombol rejoin
local rejBtn = Instance.new("TextButton", fr)
rejBtn.Size = UDim2.new(0,46,0,16); rejBtn.Position = UDim2.new(1,-96,0,4)
rejBtn.BackgroundColor3 = Color3.fromRGB(10,30,10); rejBtn.Text = "rejoin"
rejBtn.Font = Enum.Font.GothamBold; rejBtn.TextSize = 10
rejBtn.TextColor3 = Color3.fromRGB(80,255,120)
Instance.new("UICorner", rejBtn).CornerRadius = UDim.new(0,4)
rejBtn.MouseButton1Click:Connect(function()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, plr)
    end)
end)
local tx = Instance.new("TextLabel", fr)
tx.Size = UDim2.new(1,-10,1,-30); tx.Position = UDim2.new(0,6,0,28)
tx.BackgroundTransparency = 1; tx.Font = Enum.Font.Code; tx.TextSize = 10
tx.TextColor3 = Color3.fromRGB(220, 220, 180); tx.TextXAlignment = Enum.TextXAlignment.Left
tx.TextYAlignment = Enum.TextYAlignment.Top; tx.TextWrapped = true

-- ============ LOG ============
local LOG = {}
local function push(tag, msg)
    local ts = os.date("%H:%M:%S")
    local ms = math.floor((tick() % 1) * 1000)
    local line = string.format("%s.%03d | %-8s | %s", ts, ms, tag, msg)
    table.insert(LOG, 1, line)
    if #LOG > 2000 then table.remove(LOG) end
end

clrBtn.MouseButton1Click:Connect(function() LOG = {} end)

local lastTap = 0
fr.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local now = tick()
        if now - lastTap < 0.45 then
            local body = "SWAP DBG (total="..#LOG.."):\n\n"..table.concat(LOG, "\n")
            if setclipboard then pcall(setclipboard, body)
            elseif toclipboard then pcall(toclipboard, body) end
        end
        lastTap = now
    end
end)

-- ============ 1. LISTEN PetsService OnClientEvent (server -> client) ============
pcall(function()
    local equipRE
    for _, v in pairs(RS:GetDescendants()) do
        if v.Name == "PetsService" and v:IsA("RemoteEvent") then equipRE = v; break end
    end
    if equipRE then
        equipRE.OnClientEvent:Connect(function(action, uuid, ...)
            push("RE-SVR", tostring(action).." | "..(tostring(uuid):sub(1,10)))
        end)
        push("INIT", "PetsService listener OK")
    else
        push("INIT", "PetsService NOT FOUND")
    end
end)

-- ============ 2. HOOK AnimationTrack (hookfunction jika tersedia) ============
-- Tangkap semua .Play() di semua AnimationTrack di karakter + pet models
local function watchAnimations(model)
    if not model then return end
    pcall(function()
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Animator") then
                desc.AnimationPlayed:Connect(function(track)
                    local animId = ""
                    pcall(function() animId = track.Animation and tostring(track.Animation.AnimationId) or "?" end)
                    local name = tostring(track.Name or "")
                    -- skip Idle, Walk, WalkAnim — terlalu spam
                    local lo = name:lower()
                    if lo == "idle" or lo == "walk" or lo == "walkanim" or lo == "animation1"
                        or lo == "fallanim" or lo == "jumpanim" or lo == "climbanim"
                        or lo == "runaniml" or lo == "runanim" or lo == "swimanim"
                        or lo == "swimidle" or lo == "toolnone" then return end
                    push("ANIM", name:sub(1,16).." | "..animId:sub(-8))
                end)
            end
        end
    end)
end

-- watch karakter sendiri
pcall(function()
    local char = plr.Character or plr.CharacterAdded:Wait()
    watchAnimations(char)
end)

-- UUID pattern: 8-4-4-4-12 hex dalam kurung kurawal
local function isPetModel(d)
    if not d:IsA("Model") then return false end
    return d.Name:match("^{?%x%x%x%x%x%x%x%x%-") ~= nil
end

-- watch semua model di workspace (pet models)
local watchedModels = {}
pcall(function()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChild("Animator", true) then
            watchAnimations(d)
        end
    end
    workspace.DescendantAdded:Connect(function(d)
        task.defer(function()
            pcall(function()
                if d:IsA("Model") then
                    watchAnimations(d)
                end
                -- SPAWN detection
                if isPetModel(d) then
                    local uuid8 = d.Name:sub(1,10)
                    -- posisi & slot info
                    local info = ""
                    pcall(function()
                        -- cek attribute slot/index
                        local slot = d:GetAttribute("Slot") or d:GetAttribute("Index") or d:GetAttribute("SlotIndex") or d:GetAttribute("EquipSlot")
                        if slot ~= nil then info = info .. " slot="..tostring(slot) end
                        -- cek NumberValue/StringValue bernama Slot/Index di dalam model
                        for _, v in ipairs(d:GetChildren()) do
                            local n = v.Name:lower()
                            if (n == "slot" or n == "index" or n == "slotindex" or n == "equipslot") and v.Value ~= nil then
                                info = info .. " "..v.Name.."="..tostring(v.Value)
                            end
                        end
                        -- posisi relatif ke karakter
                        local char = plr.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local petRoot = d:FindFirstChild("HumanoidRootPart") or d:FindFirstChildWhichIsA("BasePart")
                        if root and petRoot then
                            local rel = petRoot.Position - root.Position
                            info = info .. string.format(" pos=(%.1f,%.1f,%.1f)", rel.X, rel.Y, rel.Z)
                        end
                    end)
                    push("SPAWN", uuid8 .. info)
                    watchedModels[d] = true
                end
            end)
        end)
    end)
    workspace.DescendantRemoving:Connect(function(d)
        if isPetModel(d) and watchedModels[d] then
            local uuid8 = d.Name:sub(1,10)
            push("DESPAWN", uuid8)
            watchedModels[d] = nil
        end
    end)
end)

-- ============ 3. LISTEN Sound di PetsPhysical ============
pcall(function()
    local pp = workspace:FindFirstChild("PetsPhysical") or workspace:WaitForChild("PetsPhysical", 10)
    if not pp then push("INIT", "PetsPhysical NOT FOUND"); return end
    push("INIT", "PetsPhysical listener ON")

    local seenSounds = {}
    pp.DescendantAdded:Connect(function(obj)
        task.defer(function()
            pcall(function()
                if not obj:IsA("Sound") then return end
                local sid = tostring(obj.SoundId)
                if seenSounds[sid] then return end
                seenSounds[sid] = true
                task.delay(0.5, function() seenSounds[sid] = nil end)

                local model = obj
                while model and not model:IsA("Model") do model = model.Parent end
                local uuid8 = (model and isPetModel(model)) and model.Name:sub(1,10) or "?"
                local shortId = sid:sub(-10)
                push("SND-SPAWN", uuid8 .. " | id:" .. shortId)
            end)
        end)
    end)
end)

-- ============ 4. LISTEN semua RemoteEvent di ReplicatedStorage ============
pcall(function()
    local function hookRE(re, path)
        pcall(function()
            re.OnClientEvent:Connect(function(a1, a2, ...)
                local s1 = type(a1) == "string" and a1:sub(1,20)
                         or type(a1) == "number" and tostring(a1)
                         or type(a1) == "table"  and "tbl"
                         or tostring(a1):sub(1,20)
                local s2 = a2 ~= nil and ("|" .. tostring(a2):sub(1,15)) or ""
                push("RE", path:sub(-28) .. " → " .. s1 .. s2)
            end)
        end)
    end

    local hooked = 0
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name ~= "PetsService" then
            hookRE(v, v:GetFullName())
            hooked = hooked + 1
        end
    end
    push("INIT", "RE hooked: " .. hooked .. " events")

    RS.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteEvent") and v.Name ~= "PetsService" then
            hookRE(v, v:GetFullName())
            push("INIT", "RE+ " .. v:GetFullName():sub(-30))
        end
    end)
end)

-- ============ 5. DEEP HOOK PetCooldownsUpdated ============
-- Dump full args supaya tau isi table cooldown-nya
pcall(function()
    local function findRE(name)
        for _, v in pairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name == name then return v end
        end
        return nil
    end

    local function dumpVal(v, depth)
        depth = depth or 0
        if depth > 2 then return "..." end
        local t = type(v)
        if t == "string" then return '"'..v:sub(1,30)..'"'
        elseif t == "number" then return tostring(v)
        elseif t == "boolean" then return tostring(v)
        elseif t == "table" then
            local parts = {}
            local n = 0
            for k, val in pairs(v) do
                n = n + 1
                if n > 6 then table.insert(parts, "..."); break end
                table.insert(parts, tostring(k):sub(1,12).."="..dumpVal(val, depth+1))
            end
            return "{"..table.concat(parts,",").."}"
        else
            return tostring(v):sub(1,20)
        end
    end

    local pcu = findRE("PetCooldownsUpdated")
    if not pcu then
        -- coba tunggu sebentar
        task.delay(3, function()
            pcu = findRE("PetCooldownsUpdated")
            if pcu then
                push("INIT", "PCU found (delayed)")
            else
                push("INIT", "PCU NOT FOUND")
            end
        end)
        push("INIT", "PCU searching...")
        return
    end

    push("INIT", "PCU deep-hook OK @ " .. pcu:GetFullName():sub(-40))
    pcu.OnClientEvent:Connect(function(uuid, cooldownTbl, ...)
        local ustr = tostring(uuid):sub(1,18)
        local cstr = dumpVal(cooldownTbl)
        local extras = ""
        local extra = {...}
        for i, v in ipairs(extra) do
            extras = extras .. "|" .. dumpVal(v)
            if i >= 2 then break end
        end
        push("PCU", ustr .. " | " .. cstr .. extras)
    end)
end)

-- ============ UPDATE LOOP ============
task.spawn(function()
    while sg.Parent do
        task.wait(0.4)
        local head = string.format("RE-SVR=server events | ANIM=anim play | SOUND=sound\n[total=%d]\n", #LOG)
        tx.Text = head .. table.concat(LOG, "\n")
    end
end)

push("INIT", "dbg_swap v1.7 ready (pcu-deep)")
