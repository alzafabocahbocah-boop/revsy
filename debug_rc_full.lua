-- debug_rc_full.lua
-- Dump: EquippedPets + semua pet (uuid, jenis, kg, age) dari RC
-- TANPA workspace scan

local function run()
    local RS = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer
    local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
    if not mod then print("[DBG] ReplicationClass tidak ketemu"); return end

    local RC = require(mod)
    local inst = RC.new("ActivePetsService_Replicator")
    local ok, data = pcall(function() return inst:GetData(plr.Name) end)
    if not ok or not data then print("[DBG] GetData gagal: "..tostring(data)); return end

    local ppd
    pcall(function() ppd = data.Table.PlayerPetData[plr.Name] end)
    if not ppd then print("[DBG] PlayerPetData nil"); return end

    -- ===== EquippedPets =====
    print("[DBG] ===== EquippedPets =====")
    local equippedSet = {}
    pcall(function()
        local eq = ppd.EquippedPets
        if not eq then print("  nil"); return end
        for i, u in ipairs(eq) do
            local clean = tostring(u):gsub("[{}]","")
            equippedSet[clean] = true
            print("  ["..i.."] "..tostring(u))
        end
        print("  total equipped: "..#eq)
    end)

    -- ===== PetInventory.Data — uuid, jenis, kg, age =====
    print("[DBG] ===== PetInventory (uuid | jenis | kg | age) =====")
    pcall(function()
        local invData = ppd.PetInventory.Data
        if not invData then print("  nil"); return end
        local list = {}
        for uuid, entry in pairs(invData) do
            if type(entry) == "table" and entry.PetType and type(entry.PetData) == "table" then
                local bw  = tonumber(entry.PetData.BaseWeight) or 0
                local lv  = tonumber(entry.PetData.Level) or 0
                local kg  = bw * (lv + 10) / 10
                local clean = tostring(uuid):gsub("[{}]","")
                list[#list+1] = {
                    uuid    = clean,
                    jenis   = tostring(entry.PetType),
                    bw      = bw,
                    kg      = kg,
                    age     = lv,
                    equipped = equippedSet[clean] and "YES" or "-"
                }
            end
        end
        -- sort by kg desc
        table.sort(list, function(a,b) return a.kg > b.kg end)
        print(string.format("  %-36s | %-28s | %6s | %6s | %4s | eq", "UUID","JENIS","BW","KG","AGE"))
        print("  "..string.rep("-",100))
        for _, p in ipairs(list) do
            print(string.format("  %-36s | %-28s | %6.2f | %6.2f | %4d | %s",
                p.uuid:sub(1,36), p.jenis:sub(1,28), p.bw, p.kg, p.age, p.equipped))
        end
        print("  total: "..#list)
    end)
end

pcall(run)
