-- DEBUG RC totalPet + maxInv untuk market
-- Run di console SC akun market, lihat output tiap step

local RS = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer

print("=== DEBUG RC MARKET ===")
print("akun:", plr.Name)

-- Step 1: cek module ada
local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
print("[1] ReplicationClass module:", mod and "FOUND" or "NIL")
if not mod then print("STOP: module gak ada"); return end

-- Step 2: require + new
local ok1, RC = pcall(require, mod)
print("[2] require RC:", ok1 and "OK" or ("FAIL: " .. tostring(RC)))
if not ok1 then return end

local ok2, inst = pcall(function() return RC.new("ActivePetsService_Replicator") end)
print("[3] RC.new:", ok2 and "OK" or ("FAIL: " .. tostring(inst)))
if not ok2 or not inst then return end

-- Step 3: GetData
local ok3, data = pcall(function() return inst:GetData(plr.Name) end)
print("[4] GetData:", ok3 and type(data) or ("FAIL: " .. tostring(data)))
if not ok3 or type(data) ~= "table" then
    -- coba tanpa nama (some RC pakai key berbeda)
    print("    → coba GetData() tanpa arg...")
    local ok4, d2 = pcall(function() return inst:GetData() end)
    print("    → GetData():", ok4 and type(d2) or ("FAIL: "..tostring(d2)))
    if ok4 and type(d2) == "table" then
        print("    → keys:", table.concat((function() local k={} for key in pairs(d2) do k[#k+1]=tostring(key) end return k end)(), ", "))
    end
    return
end

-- Step 4: drill ke Table
print("[5] data keys:", table.concat((function() local k={} for key in pairs(data) do k[#k+1]=tostring(key) end return k end)(), ", "))

local tbl = rawget(data, "Table")
print("[6] data.Table:", type(tbl))
if type(tbl) ~= "table" then
    -- coba rawget semua key
    print("    → semua key di data:")
    for k, v in pairs(data) do print("      ", tostring(k), "=", type(v)) end
    return
end

print("[7] Table keys:", table.concat((function() local k={} for key in pairs(tbl) do k[#k+1]=tostring(key) end return k end)(), ", "))

local ppd = rawget(tbl, "PlayerPetData")
print("[8] PlayerPetData:", type(ppd))
if type(ppd) ~= "table" then return end

print("[9] PlayerPetData keys:", table.concat((function() local k={} for key in pairs(ppd) do k[#k+1]=tostring(key) end return k end)(), ", "))

local pd = rawget(ppd, plr.Name)
print("[10] pd[" .. plr.Name .. "]:", type(pd))
if type(pd) ~= "table" then
    -- coba key pertama
    local firstKey, firstVal = next(ppd)
    print("     → key pertama di PlayerPetData:", tostring(firstKey), "=", type(firstVal))
    pd = firstVal
    if type(pd) ~= "table" then return end
end

print("[11] pd keys:", table.concat((function() local k={} for key in pairs(pd) do k[#k+1]=tostring(key) end return k end)(), ", "))

-- MutableStats → MaxPetsInInventory
local ms = rawget(pd, "MutableStats")
print("[12] MutableStats:", type(ms))
if type(ms) == "table" then
    local mp = rawget(ms, "MaxPetsInInventory")
    print("[12a] MaxPetsInInventory:", tostring(mp))
end

-- PetInventory → Data → count
local pi = rawget(pd, "PetInventory")
print("[13] PetInventory:", type(pi))
if type(pi) == "table" then
    print("     PetInventory keys:", table.concat((function() local k={} for key in pairs(pi) do k[#k+1]=tostring(key) end return k end)(), ", "))
    local dat = rawget(pi, "Data")
    print("[14] PetInventory.Data:", type(dat))
    if type(dat) == "table" then
        local cnt = 0
        for _ in pairs(dat) do cnt = cnt + 1 end
        print("[15] TOTAL PET:", cnt)
        -- sample 3 entry
        local n = 0
        for uuid, entry in pairs(dat) do
            n = n + 1
            if n <= 3 then
                print("     sample entry:", tostring(uuid):sub(1,20), "PetType=", type(entry)=="table" and tostring(entry.PetType) or "?")
            end
        end
    end
end

print("=== DONE ===")
