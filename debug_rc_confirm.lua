-- debug_rc_confirm.lua
-- Konfirmasi chain akses tanpa getgc
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

local RS = game:GetService("ReplicatedStorage")
local RC = require(RS.Modules.ReplicationClass)

print("=== Test chain akses tanpa getgc ===")
pcall(function()
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(myName)
    print("GetData type:", type(data))

    if type(data)=="table" then
        local tbl = rawget(data, "Table")
        print("Table type:", type(tbl))

        if type(tbl)=="table" then
            local ppd = rawget(tbl, "PlayerPetData")
            print("PlayerPetData type:", type(ppd))

            if type(ppd)=="table" then
                local pd = rawget(ppd, myName)
                print("pd type:", type(pd))

                if type(pd)=="table" then
                    local ms = rawget(pd, "MutableStats")
                    print("MutableStats type:", type(ms))

                    if type(ms)=="table" then
                        local maxInv = rawget(ms, "MaxPetsInInventory")
                        local maxEggs = rawget(ms, "MaxEggsInFarm")
                        local maxEq = rawget(ms, "MaxEquippedPets")
                        print("MaxPetsInInventory =", maxInv)
                        print("MaxEggsInFarm =", maxEggs)
                        print("MaxEquippedPets =", maxEq)
                        print("")
                        print("SUCCESS: chain tanpa getgc berfungsi!")
                    end
                end
            end
        end
    end
end)

-- test apakah inst bisa di-cache (dipanggil sekali lalu reuse)
print("")
print("=== Test cache inst ===")
local inst = RC.new("ActivePetsService_Replicator")
pcall(function()
    local d1 = inst:GetData(myName)
    local ms1 = rawget(rawget(rawget(d1,"Table"),"PlayerPetData")[myName],"MutableStats")
    print("Call 1: MaxPetsInInventory =", rawget(ms1,"MaxPetsInInventory"))
end)
task.wait(0.1)
pcall(function()
    local d2 = inst:GetData(myName)
    local ms2 = rawget(rawget(rawget(d2,"Table"),"PlayerPetData")[myName],"MutableStats")
    print("Call 2: MaxPetsInInventory =", rawget(ms2,"MaxPetsInInventory"))
end)
print("inst reuse OK")

-- satu liner
print("")
print("=== One-liner test ===")
pcall(function()
    local mx = rawget(rawget(rawget(RC.new("ActivePetsService_Replicator"):GetData(myName),"Table"),"PlayerPetData")[myName],"MutableStats")
    if mx then print("MaxPetsInInventory =", rawget(mx,"MaxPetsInInventory")) end
end)
