-- debug_rc_getdata.lua
-- Test ReplicationClass:GetData untuk akses MaxPetsInInventory tanpa getgc
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

local RS = game:GetService("ReplicatedStorage")
local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
if not mod then print("ReplicationClass tidak ditemukan"); return end

local RC = require(mod)
print("RC keys:", table.concat((function() local ks={}; for k in pairs(RC) do ks[#ks+1]=tostring(k) end; return ks end)(), ", "))

-- coba GetData dengan berbagai path
print("")
print("=== Test GetData ===")

-- coba path ActivePetsService_Replicator
pcall(function()
    local v = RC:GetData("ActivePetsService_Replicator")
    print("GetData('ActivePetsService_Replicator') type:", type(v))
    if type(v)=="table" then
        local ks={}; for k in pairs(v) do ks[#ks+1]=tostring(k); if #ks>=8 then break end end
        print("  keys:", table.concat(ks,","))
    end
end)

-- coba GetData tanpa arg / dengan berbagai variasi
pcall(function()
    local v = RC.GetData(RC)
    print("RC:GetData() type:", type(v))
end)

-- coba instance baru
pcall(function()
    local inst = RC.new("ActivePetsService_Replicator")
    print("RC.new type:", type(inst))
    if type(inst)=="table" then
        local ks={}; for k in pairs(inst) do ks[#ks+1]=tostring(k); if #ks>=10 then break end end
        print("  keys:", table.concat(ks,","))
        -- coba GetData dari instance
        pcall(function()
            local v = inst:GetData(myName)
            print("  inst:GetData(myName) type:", type(v))
            if type(v)=="table" then
                local ks2={}; for k in pairs(v) do ks2[#ks2+1]=tostring(k); if #ks2>=10 then break end end
                print("  keys:", table.concat(ks2,","))
            end
        end)
        pcall(function()
            local v = inst:GetData()
            print("  inst:GetData() type:", type(v))
        end)
        -- coba YieldUntilData
        pcall(function()
            local v = inst:YieldUntilData(myName)
            print("  inst:YieldUntilData(myName) type:", type(v))
        end)
        -- coba GetPathSignal
        pcall(function()
            local v = inst:GetPathSignal(myName)
            print("  inst:GetPathSignal(myName) type:", type(v))
        end)
        -- coba akses Table langsung
        pcall(function()
            local t = rawget(inst, "Table") or inst.Table
            print("  inst.Table type:", type(t))
            if type(t)=="table" then
                local ppd = rawget(t,"PlayerPetData")
                if type(ppd)=="table" then
                    local pd = rawget(ppd, myName)
                    if type(pd)=="table" then
                        local ms = rawget(pd, "MutableStats")
                        if type(ms)=="table" then
                            print("  CHAIN VIA inst.Table.PlayerPetData[myName].MutableStats.MaxPetsInInventory =", rawget(ms,"MaxPetsInInventory"))
                        end
                    end
                end
            end
        end)
    end
end)

-- inspect RC lebih dalam
print("")
print("=== RC method signatures ===")
pcall(function()
    -- cek apakah GetData butuh instance
    local info = debug and debug.getinfo
    if info then
        print("GetData info:", tostring(info(RC.GetData)))
    end
    -- print upvalue GetData
    if getupvalues then
        local ups = getupvalues(RC.GetData)
        print("GetData upvalues:")
        for k,v in pairs(ups) do
            print(string.format("  [%s] type=%s", tostring(k), type(v)))
            if type(v)=="table" then
                local ks={}; for kk in pairs(v) do ks[#ks+1]=tostring(kk); if #ks>=8 then break end end
                print("    keys:", table.concat(ks,","))
            end
        end
    end
end)
