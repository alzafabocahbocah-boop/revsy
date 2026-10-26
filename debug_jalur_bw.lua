-- debug_jalur_bw.lua
-- Cek apakah RC punya BaseWeight + Level per uuid
-- sama seperti _kgContainer dari getgc
-- Jalankan di executor, lihat output di console

local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local ok, err = pcall(function()
    -- ====== JALUR RC ======
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    assert(type(data) == "table", "RC data bukan table")

    local tbl = rawget(data, "Table")
    local ppd = rawget(tbl, "PlayerPetData")
    local pd  = rawget(ppd, player.Name)

    -- cek PetInventory.Data
    local pi  = rawget(pd, "PetInventory")
    local dat = rawget(pi, "Data")
    assert(type(dat) == "table", "PetInventory.Data nil")

    print("====== RC PetInventory.Data (3 sample) ======")
    local count = 0
    for uuid, entry in pairs(dat) do
        count = count + 1
        print("--- RC uuid:", uuid)
        print("    type(entry):", type(entry))
        if type(entry) == "table" then
            -- list semua key
            local keys = {}
            for k in pairs(entry) do keys[#keys+1] = tostring(k) end
            print("    keys:", table.concat(keys, ", "))

            -- field yang dicari
            print("    PetType:", tostring(rawget(entry, "PetType")))

            local petData = rawget(entry, "PetData")
            if type(petData) == "table" then
                local pdkeys = {}
                for k in pairs(petData) do pdkeys[#pdkeys+1] = tostring(k) end
                print("    PetData keys:", table.concat(pdkeys, ", "))
                print("    PetData.BaseWeight:", tostring(rawget(petData, "BaseWeight")))
                print("    PetData.Level:", tostring(rawget(petData, "Level")))
            else
                print("    PetData: NIL atau bukan table")
                -- mungkin BaseWeight langsung di entry?
                print("    entry.BaseWeight:", tostring(rawget(entry, "BaseWeight")))
                print("    entry.Level:", tostring(rawget(entry, "Level")))
            end
        end
        if count >= 3 then break end
    end
    print("====== Total RC entries:", count, "(shown 3) ======")

    -- ====== COBA EquippedPets ======
    local ep = rawget(pd, "EquippedPets")
    print("\n====== EquippedPets ======")
    if type(ep) == "table" then
        local ekeys = {}
        for k in pairs(ep) do ekeys[#ekeys+1] = tostring(k) end
        print("EquippedPets keys:", table.concat(ekeys, ", "))
        local ec = 0
        for uuid, entry in pairs(ep) do
            ec = ec + 1
            print("--- EP uuid:", uuid)
            if type(entry) == "table" then
                local eks = {}
                for k in pairs(entry) do eks[#eks+1] = tostring(k) end
                print("    keys:", table.concat(eks, ", "))
                print("    PetType:", tostring(rawget(entry, "PetType")))
                local epd = rawget(entry, "PetData")
                if type(epd) == "table" then
                    print("    PetData.BaseWeight:", tostring(rawget(epd, "BaseWeight")))
                    print("    PetData.Level:", tostring(rawget(epd, "Level")))
                else
                    print("    BaseWeight (direct):", tostring(rawget(entry, "BaseWeight")))
                    print("    Level (direct):", tostring(rawget(entry, "Level")))
                end
            end
            if ec >= 3 then break end
        end
    else
        print("EquippedPets nil atau bukan table:", type(ep))
    end
end)

if not ok then
    print("ERROR:", err)
end
