-- debug_pet_count3.lua
-- Cek apakah PetInventory.Counter = 255 (langsung tanpa hitung)
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    local pd = rawget(rawget(rawget(data,"Table"),"PlayerPetData"), player.Name)
    local pi = rawget(pd, "PetInventory")

    print("=== PetInventory fields ===")
    local counter = rawget(pi, "Counter")
    print("Counter =", counter)  -- kalau ini = 255, kita bisa pakai langsung!

    local dat = rawget(pi, "Data")
    local sz = 0
    for _ in pairs(dat) do sz = sz + 1 end
    print("Data size (hitung manual) =", sz)

    print("")
    if counter == sz then
        print("MATCH: Counter == Data size, bisa pakai Counter langsung tanpa hitung!")
    else
        print("BEDA: Counter="..tostring(counter).." vs size="..sz)
    end

    -- juga cek ActivePetStates[playerName] = list equipped pets
    print("")
    print("=== ActivePetStates[playerName] ===")
    local aps = rawget(rawget(data,"Table"), "ActivePetStates")
    local myAps = rawget(aps, player.Name)
    if myAps then
        local eqCount = 0
        for _ in pairs(myAps) do eqCount = eqCount + 1 end
        print("Equipped pet count (dari ActivePetStates) =", eqCount)
        print("MutableStats.MaxEquippedPets =", rawget(rawget(pd,"MutableStats"),"MaxEquippedPets"))
    end
end)
