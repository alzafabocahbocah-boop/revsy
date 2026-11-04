-- sc_swap.lua v1.0
-- Swap gacor: trigger dari ANIM Frill/Fan → unequip → equip
-- Cek posisi SPAWN: kalau (10,3,12) = sukses, kalau bukan retry 1x
-- UUID = auto-detect dari backpack (Dilop/Peacock/Peryton)

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local plr        = Players.LocalPlayer

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
hdr.Text = "SC SWAP  (2x tap = salin)"

local clrBtn = Instance.new("TextButton", fr)
clrBtn.Size = UDim2.new(0,42,0,16); clrBtn.Position = UDim2.new(1,-48,0,4)
clrBtn.BackgroundColor3 = Color3.fromRGB(0,30,10); clrBtn.Text = "clear"
clrBtn.Font = Enum.Font.GothamBold; clrBtn.TextSize = 10
clrBtn.TextColor3 = Color3.fromRGB(80,220,120)
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

-- ===== TARGET PET UUID =====
-- Auto-detect dari backpack: cari Dilop, Peacock, atau Peryton
-- Bisa override manual: _G.ZenxSwapUUID = "uuid-mu"
local TARGET_TYPES = { "dilophosaurus", "peacock", "peryton", "dilo" }
local function findTargetUUID()
    if _G.ZenxSwapUUID and _G.ZenxSwapUUID ~= "" then
        return _G.ZenxSwapUUID
    end
    local bp = plr:FindFirstChild("Backpack")
    if not bp then return nil end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") then
            local uuid = t:GetAttribute("PET_UUID")
            local f = tostring(t:GetAttribute("f") or ""):lower()
            if uuid then
                for _, kw in ipairs(TARGET_TYPES) do
                    if f:find(kw, 1, true) then
                        return tostring(uuid)
                    end
                end
            end
        end
    end
    return nil
end

-- ===== SWAP LOGIC =====
-- State per-UUID: sedang dalam swap sequence atau tidak
local swapBusy = {}       -- [uuid8] = true kalau sedang dalam sequence
local CENTER = Vector3.new(10, 3, 12)
local CENTER_THRESH = 2.0  -- toleransi jarak dari center (studs)

local function isPetModel(d)
    if not d:IsA("Model") then return false end
    return d.Name:match("^{?%x%x%x%x%x%x%x%x%-") ~= nil
end
local function uuid8(uuid)
    return tostring(uuid):gsub("[{}]",""):sub(1,8)
end

-- Nunggu SPAWN model uuid dalam timeout detik, return position atau nil
local function waitSpawn(targetUUID, timeoutSec)
    local raw8 = uuid8(targetUUID)
    local conn, pos
    local done = false
    conn = workspace.DescendantAdded:Connect(function(d)
        if done then return end
        if not isPetModel(d) then return end
        if d.Name:sub(1,8) ~= raw8 and d.Name:sub(2,9) ~= raw8 then return end
        -- ambil posisi
        task.defer(function()
            if done then return end
            pcall(function()
                local part = d:FindFirstChild("HumanoidRootPart") or d:FindFirstChildWhichIsA("BasePart")
                if part then
                    pos = part.Position
                end
            end)
            done = true
        end)
    end)
    local t0 = tick()
    while not done and (tick() - t0) < timeoutSec do
        task.wait(0.02)
    end
    conn:Disconnect()
    return pos
end

local function distToCenter(p)
    if not p then return 999 end
    local dx = p.X - CENTER.X
    local dz = p.Z - CENTER.Z
    return math.sqrt(dx*dx + dz*dz)
end

-- Eksekusi 1 kali swap untuk uuid, return true kalau masuk center
local function doSwap(uuid, attempt)
    local raw8 = uuid8(uuid)
    push("SWAP"..attempt, raw8 .. " unequip")
    unequipPet(uuid)
    task.wait(0.03)
    push("SWAP"..attempt, raw8 .. " equip")
    equipPet(uuid)
    -- tunggu SPAWN max 1.5s
    local spawnPos = waitSpawn(uuid, 1.5)
    if spawnPos then
        local dist = distToCenter(spawnPos)
        local posStr = string.format("(%.0f,%.0f,%.0f)", spawnPos.X, spawnPos.Y, spawnPos.Z)
        if dist <= CENTER_THRESH then
            push("OK"..attempt, raw8 .. " " .. posStr .. " CENTER ✓")
            return true
        else
            push("MISS"..attempt, raw8 .. " " .. posStr .. string.format(" d=%.1f", dist))
            return false
        end
    else
        push("MISS"..attempt, raw8 .. " (no spawn detected)")
        return false
    end
end

-- Main swap sequence: 1 attempt + max 1 retry
local function runSwapSequence(uuid, triggerKind)
    local raw8 = uuid8(uuid)
    if swapBusy[raw8] then
        push("SKIP", raw8 .. " busy")
        return
    end
    swapBusy[raw8] = true
    push("TRIG", raw8 .. " " .. triggerKind)

    -- Dilop/Frill: tunggu 200ms setelah ANIM sebelum swap
    if triggerKind == "FRILL" then
        task.wait(0.2)
    end

    local ok = doSwap(uuid, 1)
    if ok then
        swapBusy[raw8] = nil
        return
    end

    -- Retry 1x
    push("RETRY", raw8 .. " attempt 2")
    local ok2 = doSwap(uuid, 2)
    if ok2 then
        push("DONE", raw8 .. " sukses retry")
    else
        push("FAIL", raw8 .. " gagal 2x")
    end
    swapBusy[raw8] = nil
end

-- ===== HOOK ANIM =====
-- Frill anim ID: 50996247
-- Fan/Peacock anim ID: 84309615
local FRILL_ID = "50996247"
local FAN_ID   = "84309615"

local function watchAnimations(model)
    if not model then return end
    if not isPetModel(model) then return end
    pcall(function()
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Animator") then
                desc.AnimationPlayed:Connect(function(track)
                    local animId = ""
                    pcall(function()
                        animId = track.Animation and tostring(track.Animation.AnimationId) or ""
                    end)
                    local isFrill = animId:find(FRILL_ID) ~= nil
                    local isFan   = animId:find(FAN_ID) ~= nil
                    if not (isFrill or isFan) then return end
                    local kind = isFrill and "FRILL" or "FAN"
                    -- cari uuid target
                    local uuid = findTargetUUID()
                    if not uuid then
                        push("WARN", "no target UUID found")
                        return
                    end
                    -- jalankan swap di task.spawn (non-blocking)
                    task.spawn(function()
                        runSwapSequence(uuid, kind)
                    end)
                end)
            end
        end
    end)
end

pcall(function()
    for _, d in ipairs(workspace:GetDescendants()) do
        if isPetModel(d) then watchAnimations(d) end
    end
    workspace.DescendantAdded:Connect(function(d)
        task.defer(function()
            pcall(function()
                if isPetModel(d) then watchAnimations(d) end
            end)
        end)
    end)
end)

-- ===== UPDATE LOOP =====
task.spawn(function()
    while sg.Parent do
        task.wait(0.4)
        local uuid = findTargetUUID()
        local uStr = uuid and uuid8(uuid) or "none"
        local head = string.format("[target=%s | total=%d]\n", uStr, #LOG)
        tx.Text = head .. table.concat(LOG, "\n")
    end
end)

push("INIT", "sc_swap v1.1 ready | equipRE=" .. (equipRE and "OK" or "NIL"))
