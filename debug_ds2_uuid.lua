-- debug_ds2_uuid.lua
-- Listener DS2 standalone — log semua roar/fan dengan mine/asing
-- Jalankan terpisah dari uplevelnew

local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer

-- Ambil semua UUID milik kita dari Backpack + workspace
local function getMyUuids()
    local mine = {}
    -- dari workspace (pet equip)
    pcall(function()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") and tostring(d.Name):sub(1,1) == "{" then
                mine[d.Name] = true
                -- juga tanpa kurung kurawal
                local clean = tostring(d.Name):gsub("[{}]","")
                mine[clean] = true
            end
        end
    end)
    -- dari karakter
    pcall(function()
        local char = plr.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("Model") and tostring(d.Name):sub(1,1) == "{" then
                    mine[d.Name] = true
                    mine[tostring(d.Name):gsub("[{}]","")] = true
                end
            end
        end
    end)
    -- dari Backpack
    pcall(function()
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                local u = t:GetAttribute("PET_UUID") or t:GetAttribute("UUID") or t:GetAttribute("uuid")
                if u then
                    local ustr = tostring(u)
                    mine[ustr] = true
                    mine[ustr:gsub("[{}]","")] = true
                end
            end
        end
    end)
    return mine
end

-- log ke chat (tidak perlu panel)
local function log(msg)
    print("[DS2-DBG] "..tostring(msg))
end

-- Pasang listener
local ds2 = RS:FindFirstChild("GameEvents") and RS.GameEvents:FindFirstChild("DataStream")
if not ds2 then
    log("ERROR: DataStream tidak ditemukan!")
else
    log("DS2 listener ON — player: "..plr.Name)
    ds2.OnClientEvent:Connect(function(anim, uuid)
        if anim ~= "roar" and anim ~= "fan" and anim ~= "weave" then return end
        local raw = tostring(uuid or ""):gsub("[{}]",""):lower()
        if raw == "" then return end
        -- cek mine
        local myUuids = getMyUuids()
        local isMine = myUuids[raw] or myUuids["{"..raw.."}"] or false
        log(anim.." uuid="..raw:sub(1,8).." mine="..tostring(isMine))
    end)
    log("Listening... (roar/fan/weave)")
end
