-- debug_pet_count5.lua
-- Konfirmasi final: baca total pet count dari PetInventory.Data
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local function getTotalPets()
    local result = nil
    pcall(function()
        local RC = require(RS.Modules.ReplicationClass)
        local inst = RC.new("ActivePetsService_Replicator")
        local data = inst:GetData(player.Name)
        local pd = rawget(rawget(rawget(data,"Table"),"PlayerPetData"), player.Name)
        local dat = rawget(rawget(pd, "PetInventory"), "Data")
        if type(dat) ~= "table" then return end
        local total = 0
        for _ in pairs(dat) do total = total + 1 end
        result = total
    end)
    return result
end

local function getMaxPets()
    local result = nil
    pcall(function()
        local RC = require(RS.Modules.ReplicationClass)
        local inst = RC.new("ActivePetsService_Replicator")
        local data = inst:GetData(player.Name)
        local pd = rawget(rawget(rawget(data,"Table"),"PlayerPetData"), player.Name)
        local ms = rawget(pd, "MutableStats")
        result = rawget(ms, "MaxPetsInInventory")
    end)
    return result
end

print("=== Final test ===")
local total = getTotalPets()
local max = getMaxPets()
print(string.format("Total pet = %s / %s", tostring(total), tostring(max)))

-- bandingkan dengan UI (kalau backpack terbuka di tab pet)
local pg = player:FindFirstChildOfClass("PlayerGui")
local bg = pg and pg:FindFirstChild("BackpackGui")
local ct = bg and bg:FindFirstChild("Backpack") and bg.Backpack:FindFirstChild("Inventory")
    and bg.Backpack.Inventory:FindFirstChild("CategoryTemplate")
if ct then
    print("UI CategoryTemplate:", ct.Text)
end

-- monitor 3x
print("")
print("Monitor 3x (interval 2s):")
for i = 1, 3 do
    task.wait(2)
    local t = getTotalPets()
    print(string.format("  t=%ds total=%s", i*2, tostring(t)))
end
print("DONE")
