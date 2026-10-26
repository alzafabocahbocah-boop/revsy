-- debug_container_rc.lua
-- Cek apakah PetInventory.Data punya PetData.Level + PetData.BaseWeight + PetType
-- sama seperti yang dibutuhkan _kgContainer di uplevelnew
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local ok, err = pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    assert(type(data) == "table", "data bukan table")

    local tbl = rawget(data, "Table")
    local ppd = rawget(tbl, "PlayerPetData")
    local pd = rawget(ppd, player.Name)
    local pi = rawget(pd, "PetInventory")
    local dat = rawget(pi, "Data")
    assert(type(dat) == "table", "Data nil")

    -- ambil 3 entry pertama
    local count = 0
    for uuid, entry in pairs(dat) do
        count = count + 1
        print("=== Entry #" .. count .. " ===")
        print("  UUID key:", uuid)
        print("  type(entry):", type(entry))
        if type(entry) == "table" then
            -- list semua keys di entry
            local keys = {}
            for k in pairs(entry) do keys[#keys+1] = tostring(k) end
            print("  entry keys:", table.concat(keys, ", "))

            -- cek PetType
            local pt = rawget(entry, "PetType")
            print("  PetType:", tostring(pt))

            -- cek UUID field dalam entry
            local u = rawget(entry, "UUID")
            print("  UUID (field):", tostring(u))

            -- cek PetData
            local petData = rawget(entry, "PetData")
            print("  type(PetData):", type(petData))
            if type(petData) == "table" then
                local pdKeys = {}
                for k in pairs(petData) do pdKeys[#pdKeys+1] = tostring(k) end
                print("  PetData keys:", table.concat(pdKeys, ", "))
                -- cek field penting
                print("  PetData.Level:", tostring(rawget(petData, "Level")))
                print("  PetData.BaseWeight:", tostring(rawget(petData, "BaseWeight")))
                print("  PetData.PetType:", tostring(rawget(petData, "PetType")))
            end
        end
        if count >= 3 then break end
    end
    print("=== Total entries:", count, "(shown 3) ===")
end)

if not ok then
    print("ERROR:", err)
end
