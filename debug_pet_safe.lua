-- debug_pet_safe.lua — safe version dengan pcall di setiap step
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local ok, err = pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    assert(type(data) == "table", "data bukan table: "..type(data))

    local tbl = rawget(data, "Table")
    assert(type(tbl) == "table", "Table nil")

    local ppd = rawget(tbl, "PlayerPetData")
    assert(type(ppd) == "table", "PlayerPetData nil")

    local pd = rawget(ppd, player.Name)
    assert(type(pd) == "table", "pd nil — player.Name="..tostring(player.Name))

    local pi = rawget(pd, "PetInventory")
    assert(type(pi) == "table", "PetInventory nil")

    local dat = rawget(pi, "Data")
    assert(type(dat) == "table", "Data nil")

    local total = 0
    for _ in pairs(dat) do total = total + 1 end

    local ms = rawget(pd, "MutableStats")
    local maxInv = ms and rawget(ms, "MaxPetsInInventory")

    print(string.format("Total pet (inventory) = %d / %s", total, tostring(maxInv)))
end)

if not ok then
    print("ERROR:", err)
end
