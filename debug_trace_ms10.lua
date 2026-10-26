-- debug_trace_ms10.lua
-- Fokus: cek upvalue[2] dan upvalue[3] dari fungsi ReplicationClass
-- apakah salah satunya = dspTable, dan apakah fungsinya bisa diakses dari _G
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

local gc = getgc(true)

-- rebuild chain cepat
local target = nil
for i=1,#gc do local o=gc[i]; if type(o)=="table" then local v=rawget(o,myName); if type(v)=="table" and type(rawget(v,"MutableStats"))=="table" then local mp=rawget(rawget(v,"MutableStats"),"MaxPetsInInventory"); if type(mp)=="number" and mp==260 then target=o; break end end end end
local ppdc = nil
for i=1,#gc do local o=gc[i]; if type(o)=="table" and o~=target and rawget(o,"PlayerPetData")==target then ppdc=o; break end end
local prTable = nil
for i=1,#gc do local o=gc[i]; if type(o)=="table" and rawget(o,"Table")==ppdc and rawget(o,"PathRegistry")~=nil then prTable=o; break end end
local dspTable = nil
for i=1,#gc do local o=gc[i]; if type(o)=="table" and rawget(o,"ActivePetsService_Replicator")==prTable then dspTable=o; break end end

if not dspTable then print("chain gagal"); return end
print("dspTable OK")

-- temukan 1 fungsi ReplicationClass yang punya dspTable sebagai upvalue
local rcFn = nil
for i=1,#gc do
    local fn=gc[i]
    if type(fn)=="function" then
        pcall(function()
            local ups = getupvalues(fn)
            for k,v in pairs(ups) do
                if v==dspTable then rcFn=fn; break end
            end
        end)
        if rcFn then break end
    end
end
if not rcFn then print("rcFn tidak ditemukan"); return end
print("rcFn ditemukan")

-- print semua upvalue rcFn (hanya 3)
local ups = getupvalues(rcFn)
print("upvalue count:", #ups or "n/a")
for k,v in pairs(ups) do
    print(string.format("  [%s] type=%s", tostring(k), type(v)))
    if type(v)=="table" then
        local ks = {}
        for kk in pairs(v) do ks[#ks+1]=tostring(kk); if #ks>=8 then break end end
        print("    keys:", table.concat(ks,","))
    end
end

-- upvalue[2] = 0x6c278bc032a14685 — cek ini apa
print("")
print("=== Cek upvalue[2] ===")
local uv2 = ups[2]
if type(uv2)=="table" then
    local inG = false
    for gk,gv in pairs(_G) do
        if gv==uv2 then print("  _G."..tostring(gk)); inG=true end
        if type(gv)=="table" then
            for gk2,gv2 in pairs(gv) do
                if gv2==uv2 then print("  _G."..tostring(gk).."."..tostring(gk2)); inG=true end
            end
        end
    end
    if not inG then print("  upvalue[2] tidak di _G") end
end

print("")
print("=== Cek upvalue[3] ===")
local uv3 = ups[3]
if type(uv3)=="table" then
    local inG = false
    for gk,gv in pairs(_G) do
        if gv==uv3 then print("  _G."..tostring(gk)); inG=true end
        if type(gv)=="table" then
            for gk2,gv2 in pairs(gv) do
                if gv2==uv3 then print("  _G."..tostring(gk).."."..tostring(gk2)); inG=true end
            end
        end
    end
    if not inG then print("  upvalue[3] tidak di _G") end
end

-- apakah rcFn sendiri ada di _G?
print("")
print("=== rcFn ada di _G? ===")
local fnInG = false
for gk,gv in pairs(_G) do
    if gv==rcFn then print("  _G."..tostring(gk)); fnInG=true end
    if type(gv)=="table" then
        for gk2,gv2 in pairs(gv) do
            if gv2==rcFn then print("  _G."..tostring(gk).."."..tostring(gk2)); fnInG=true end
            if type(gv2)=="table" then
                for gk3,gv3 in pairs(gv2) do
                    if gv3==rcFn then print("  _G."..tostring(gk).."."..tostring(gk2).."."..tostring(gk3)); fnInG=true end
                end
            end
        end
    end
end
if not fnInG then print("  rcFn tidak di _G") end

-- coba require ReplicationClass dan inspect
print("")
print("=== require ReplicationClass ===")
pcall(function()
    local RS = game:GetService("ReplicatedStorage")
    local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
    if not mod then print("  module tidak ditemukan di RS.Modules"); return end
    local RC = require(mod)
    print("  require OK, type:", type(RC))
    if type(RC)=="table" then
        local ks={}; for k in pairs(RC) do ks[#ks+1]=tostring(k); if #ks>=20 then break end end
        print("  keys:", table.concat(ks,", "))
        -- cek apakah RC == uv2 atau uv3
        print("  RC == uv2?", RC==uv2)
        print("  RC == uv3?", RC==uv3)
        print("  RC == dspTable?", RC==dspTable)
    end
end)
