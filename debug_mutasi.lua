-- debug_mutasi.lua — snapshot backpack sebelum & sesudah ClaimMutatedPet
local plr = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RE = RS:FindFirstChild("GameEvents") and RS.GameEvents:FindFirstChild("PetMutationMachineService_RE")

local function snapBackpack()
    local snap = {}
    local bp = plr:FindFirstChild("Backpack")
    local char = plr.Character
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local uuid = tostring(t:GetAttribute("PET_UUID") or t:GetAttribute("uuid") or "")
                snap[uuid] = {
                    name = tostring(t:GetAttribute("PetType") or t:GetAttribute("f") or t.Name),
                    level = tonumber(t:GetAttribute("Level") or t:GetAttribute("Age") or t:GetAttribute("age") or 0) or 0,
                }
            end
        end
    end
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                local uuid = tostring(t:GetAttribute("PET_UUID") or t:GetAttribute("uuid") or "")
                snap[uuid] = {
                    name = tostring(t:GetAttribute("PetType") or t:GetAttribute("f") or t.Name),
                    level = tonumber(t:GetAttribute("Level") or t:GetAttribute("Age") or t:GetAttribute("age") or 0) or 0,
                }
            end
        end
    end
    return snap
end

local function diffSnap(before, after)
    local new = {}
    for uuid, data in pairs(after) do
        if not before[uuid] then
            new[#new+1] = string.format("  [NEW] %s | level=%d | uuid=%s", data.name, data.level, uuid:sub(1,12))
        end
    end
    local gone = {}
    for uuid, data in pairs(before) do
        if not after[uuid] then
            gone[#gone+1] = string.format("  [GONE] %s | level=%d | uuid=%s", data.name, data.level, uuid:sub(1,12))
        end
    end
    return new, gone
end

-- tunggu mesin selesai lalu snapshot
print("[DEBUG MUT] Nunggu mesin selesai...")

local function waitMachineDone()
    local machine = workspace:FindFirstChild("NPCS") and workspace.NPCS:FindFirstChild("PetMutationMachine")
    if not machine then print("[DEBUG MUT] Mesin tidak ditemukan!"); return end
    while true do
        local timerLbl = machine:FindFirstChild("TimerTextLabel", true)
        local txt = timerLbl and timerLbl.Text or ""
        local m, s = txt:match("^(%d+):(%d+)$")
        local secs = m and (tonumber(m)*60 + tonumber(s)) or 0
        if secs <= 0 then
            local petLoc = machine:FindFirstChild("PetModelLocation", true)
            local hasPet = petLoc and #petLoc:GetChildren() > 0
            if not hasPet then break end
        end
        task.wait(2)
    end
end

task.spawn(function()
    waitMachineDone()
    local before = snapBackpack()
    print("[DEBUG MUT] Snapshot SEBELUM claim: "..tostring(#(function() local n=0; for _ in pairs(before) do n=n+1 end; return n end)()).." pet")

    -- claim
    if RE then
        print("[DEBUG MUT] FireServer ClaimMutatedPet...")
        pcall(function() RE:FireServer("ClaimMutatedPet") end)
    else
        print("[DEBUG MUT] RE tidak ditemukan, claim manual dulu lalu tunggu 3s...")
    end

    task.wait(3)
    local after = snapBackpack()
    local new, gone = diffSnap(before, after)

    print("[DEBUG MUT] ===== HASIL MUTASI =====")
    if #new == 0 then
        print("[DEBUG MUT] Tidak ada pet baru masuk backpack!")
    else
        for _, s in ipairs(new) do print("[DEBUG MUT]"..s) end
    end
    if #gone > 0 then
        print("[DEBUG MUT] Pet hilang dari backpack:")
        for _, s in ipairs(gone) do print("[DEBUG MUT]"..s) end
    end
    print("[DEBUG MUT] ========================")
end)
