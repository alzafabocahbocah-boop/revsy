-- debug_pet_count4.lua
-- Error rawget nil -- cek path step by step
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    print("data type:", type(data))

    local tbl = rawget(data, "Table")
    print("Table type:", type(tbl))

    local ppd = rawget(tbl, "PlayerPetData")
    print("PlayerPetData type:", type(ppd))

    local pd = rawget(ppd, player.Name)
    print("pd type:", type(pd))

    if type(pd) ~= "table" then
        print("pd nil! Coba keys di ppd:")
        for k in pairs(ppd) do print("  key:", k) end
        return
    end

    print("pd keys:")
    for k, v in pairs(pd) do
        print(string.format("  %q => %s", tostring(k), type(v)))
    end

    local pi = rawget(pd, "PetInventory")
    print("PetInventory type:", type(pi))
    if type(pi) == "table" then
        for k, v in pairs(pi) do
            print(string.format("  PetInventory.%q => %s", tostring(k), type(v)))
        end
    end
end)
