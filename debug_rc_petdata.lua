-- debug_rc_petdata.lua
-- Dump RC container data 1 pet → lihat field apa yang ada (equipped state, dll)
-- Jalankan di executor, output di print/console

local function run()
    local RS = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer
    local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
    if not mod then print("[DBG] ReplicationClass tidak ketemu"); return end
    
    local RC = require(mod)
    local inst = RC.new("ActivePetsService_Replicator")
    local ok, data = pcall(function() return inst:GetData(plr.Name) end)
    if not ok or not data then print("[DBG] GetData gagal: "..tostring(data)); return end

    -- navigasi ke PetInventory.Data
    local petData
    pcall(function()
        petData = data.Table.PlayerPetData[plr.Name].PetInventory.Data
    end)
    if not petData then print("[DBG] PetInventory.Data nil"); return end

    -- ambil 1 entry pertama
    local count = 0
    for uuid, entry in pairs(petData) do
        if type(entry) == "table" then
            count = count + 1
            if count == 1 then
                print("[DBG] UUID: "..tostring(uuid))
                -- dump semua key di root entry
                print("[DBG] ROOT KEYS:")
                for k, v in pairs(entry) do
                    local vt = type(v)
                    if vt == "table" then
                        print("  ["..tostring(k).."] = table {")
                        for k2, v2 in pairs(v) do
                            print("    ["..tostring(k2).."] = "..tostring(v2))
                        end
                        print("  }")
                    else
                        print("  ["..tostring(k).."] = "..tostring(v))
                    end
                end
            end
        end
        if count >= 3 then break end
    end
    print("[DBG] total entry: "..count)
end

pcall(run)
