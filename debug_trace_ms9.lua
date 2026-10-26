-- debug_trace_ms9.lua
-- Akses ReplicationClass dari ReplicatedStorage dan cek apakah bisa dapat dspTable
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

-- target chain untuk verifikasi
local gc = getgc(true)
local target = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" then
        local v = rawget(obj, myName)
        if type(v)=="table" and type(rawget(v,"MutableStats"))=="table" then
            local mp = rawget(rawget(v,"MutableStats"), "MaxPetsInInventory")
            if type(mp)=="number" and mp==260 then
                target = obj; break
            end
        end
    end
end
if not target then print("target nil"); return end
local ppdc = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=target and rawget(obj,"PlayerPetData")==target then
        ppdc = obj; break
    end
end
local prTable = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and rawget(obj,"Table")==ppdc and rawget(obj,"PathRegistry")~=nil then
        prTable = obj; break
    end
end
local dspTable = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and rawget(obj,"ActivePetsService_Replicator")==prTable then
        dspTable = obj; break
    end
end
if not dspTable then print("dspTable nil"); return end
print("dspTable confirmed")

-- cari 2 fungsi dari ReplicationClass yang pegang dspTable
print("")
print("=== Fungsi ReplicationClass dengan upvalue dspTable ===")
if not getupvalues then print("getupvalues nil"); return end

local fnList = {}
for i = 1, #gc do
    local fn = gc[i]
    if type(fn)=="function" then
        pcall(function()
            for uvk, uv in pairs(getupvalues(fn)) do
                if uv==dspTable then
                    fnList[#fnList+1] = fn
                end
            end
        end)
    end
end
print("Total fungsi:", #fnList)

-- print semua upvalue dari setiap fungsi
for fi, fn in ipairs(fnList) do
    print(string.format("\n--- fungsi[%d] ---", fi))
    pcall(function()
        local ups = getupvalues(fn)
        for k, v in pairs(ups) do
            print(string.format("  upvalue[%s] = %s (%s)", tostring(k), tostring(v), type(v)))
        end
    end)
    -- cek apakah fn ini ada di _G
    for gk, gv in pairs(_G) do
        if gv==fn then print("  -> _G."..tostring(gk)) end
        if type(gv)=="table" then
            for gk2, gv2 in pairs(gv) do
                if gv2==fn then print("  -> _G."..tostring(gk).."."..tostring(gk2)) end
            end
        end
    end
end

-- coba require ReplicationClass langsung
print("")
print("=== require ReplicationClass ===")
pcall(function()
    local RC = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules",1):WaitForChild("ReplicationClass",1))
    print("  require OK, type:", type(RC))
    if type(RC)=="table" then
        local ks = {}
        for k in pairs(RC) do ks[#ks+1]=tostring(k); if #ks>=15 then break end end
        print("  keys:", table.concat(ks,", "))
        -- coba akses PlayerPetData
        pcall(function()
            local v = RC.PlayerPetData or RC.ActivePetsService_Replicator or RC.Table
            print("  RC.PlayerPetData:", type(RC.PlayerPetData))
            print("  RC.ActivePetsService_Replicator:", type(RC.ActivePetsService_Replicator))
        end)
    end
end)

-- coba akses via getupvalue langsung dari fungsi pertama
print("")
print("=== getupvalue dari fungsi ReplicationClass ===")
if #fnList > 0 then
    pcall(function()
        local ups = getupvalues(fnList[1])
        for k, v in pairs(ups) do
            if type(v)=="table" and rawget(v,"ActivePetsService_Replicator")~=nil then
                print("  upvalue["..tostring(k).."] = dspTable confirmed")
                -- coba akses chain
                local ar = rawget(v,"ActivePetsService_Replicator")
                if type(ar)=="table" then
                    local tbl = rawget(ar,"Table")
                    if type(tbl)=="table" then
                        local ppd = rawget(tbl,"PlayerPetData")
                        if type(ppd)=="table" then
                            local pdata = rawget(ppd, myName)
                            if type(pdata)=="table" then
                                local ms = rawget(pdata,"MutableStats")
                                if type(ms)=="table" then
                                    print("  CHAIN OK: MaxPetsInInventory =", rawget(ms,"MaxPetsInInventory"))
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end
