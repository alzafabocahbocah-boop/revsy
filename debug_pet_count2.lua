-- debug_pet_count2.lua
-- Deep dive PetInventory dan cari di mana 255 pet tersimpan
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    local tbl = rawget(data, "Table")
    local ppd = rawget(tbl, "PlayerPetData")
    local pd = rawget(ppd, player.Name)

    print("=== PetInventory (size=2) ===")
    local pi = rawget(pd, "PetInventory")
    for k, v in pairs(pi) do
        print(string.format("  key=%q type=%s", tostring(k), type(v)))
        if type(v) == "table" then
            local sz = 0
            for _ in pairs(v) do sz = sz + 1 end
            print(string.format("    size=%d", sz))
            -- sample 3 entries
            local c = 0
            for sk, sv in pairs(v) do
                if c < 3 then
                    if type(sv) == "table" then
                        local keys = {}
                        for ik in pairs(sv) do keys[#keys+1] = tostring(ik) end
                        print(string.format("    [%s] = table{%s}", tostring(sk), table.concat(keys, ",")))
                    else
                        print(string.format("    [%s] = %s", tostring(sk), tostring(sv)))
                    end
                    c = c + 1
                end
            end
        end
    end

    print("")
    print("=== ActivePetStates ===")
    local aps = rawget(tbl, "ActivePetStates")
    local apsSize = 0
    for _ in pairs(aps) do apsSize = apsSize + 1 end
    print("ActivePetStates size =", apsSize)
    -- sample
    local c = 0
    for k, v in pairs(aps) do
        if c < 2 then
            if type(v) == "table" then
                local keys = {}
                for ik in pairs(v) do keys[#keys+1] = tostring(ik) end
                print(string.format("  [%s] = table{%s}", tostring(k), table.concat(keys, ",")))
            else
                print(string.format("  [%s] = %s", tostring(k), tostring(v)))
            end
            c = c + 1
        end
    end

    print("")
    print("=== ServerPetData ===")
    local spd = rawget(tbl, "ServerPetData")
    local spdSize = 0
    for _ in pairs(spd) do spdSize = spdSize + 1 end
    print("ServerPetData size =", spdSize)
    -- kalau ada player name key
    local mySpd = rawget(spd, player.Name)
    if mySpd then
        print("ServerPetData[playerName] keys:")
        for k, v in pairs(mySpd) do
            if type(v) == "table" then
                local sz = 0
                for _ in pairs(v) do sz = sz + 1 end
                print(string.format("  %q => table (size=%d)", tostring(k), sz))
                -- kalau besar, ini kandidat
                if sz > 100 then
                    print("  *** KANDIDAT (size>"..sz..") ***")
                    local cc = 0
                    for sk, sv in pairs(v) do
                        if cc < 3 then
                            if type(sv) == "table" then
                                local keys = {}
                                for ik in pairs(sv) do keys[#keys+1] = tostring(ik) end
                                print(string.format("    [%s] = table{%s}", tostring(sk), table.concat(keys, ",")))
                            else
                                print(string.format("    [%s] = %s", tostring(sk), tostring(sv)))
                            end
                            cc = cc + 1
                        end
                    end
                end
            else
                print(string.format("  %q => %s = %s", tostring(k), type(v), tostring(v)))
            end
        end
    else
        -- print keys di ServerPetData langsung
        print("ServerPetData keys (top level):")
        local c2 = 0
        for k, v in pairs(spd) do
            if c2 < 10 then
                if type(v) == "table" then
                    local sz = 0
                    for _ in pairs(v) do sz = sz + 1 end
                    print(string.format("  %q => table (size=%d)", tostring(k), sz))
                else
                    print(string.format("  %q => %s", tostring(k), tostring(v)))
                end
                c2 = c2 + 1
            end
        end
    end

    print("")
    print("=== ServerPetStates ===")
    local sps = rawget(tbl, "ServerPetStates")
    local spsSize = 0
    for _ in pairs(sps) do spsSize = spsSize + 1 end
    print("ServerPetStates size =", spsSize)
end)
