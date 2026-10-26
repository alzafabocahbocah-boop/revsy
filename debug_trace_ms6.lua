-- debug_trace_ms6.lua
-- Cari siapa yang pegang table{ActivePetStates,PlayerPetData,ServerPetStates,ServerPetData}
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

local gc = getgc(true)

-- temukan target (obj{wildnx_27} dengan MutableStats)
local playerPetDataTable = nil  -- table yang punya key PlayerPetData = target
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

-- temukan PlayerPetData container
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=target then
        if rawget(obj,"PlayerPetData")==target then
            playerPetDataTable = obj; break
        end
    end
end
if not playerPetDataTable then print("PlayerPetData container nil"); return end
print("PlayerPetData container ditemukan")
local keys = {}
for k in pairs(playerPetDataTable) do keys[#keys+1]=tostring(k) end
print("  keys:", table.concat(keys,", "))

-- test akses langsung
print("")
print("=== Test akses chain ===")
pcall(function()
    local mp = rawget(rawget(rawget(playerPetDataTable,"PlayerPetData")[myName],"MutableStats"),"MaxPetsInInventory")
    print("  PlayerPetData[myName].MutableStats.MaxPetsInInventory =", mp)
end)

-- cek _G
print("")
print("=== PlayerPetData container ada di _G? ===")
local inG = false
for gk, gv in pairs(_G) do
    if gv==playerPetDataTable then print("  _G."..tostring(gk)); inG=true end
    if type(gv)=="table" then
        for gk2, gv2 in pairs(gv) do
            if gv2==playerPetDataTable then print("  _G."..tostring(gk).."."..tostring(gk2)); inG=true end
        end
    end
end
if not inG then print("  tidak ada di _G") end

-- cari yang pegang PlayerPetData container
print("")
print("=== Yang pegang PlayerPetData container ===")
local found = 0
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=playerPetDataTable and obj~=target then
        for k, v in pairs(obj) do
            if v==playerPetDataTable then
                found = found + 1
                local ks = {}
                for kk in pairs(obj) do ks[#ks+1]=tostring(kk); if #ks>=8 then break end end
                print(string.format("  [%d] key='%s' in table{%s}", found, tostring(k), table.concat(ks,",")))
                for gk, gv in pairs(_G) do
                    if gv==obj then print("    -> _G."..tostring(gk)) end
                end
                if found>=8 then break end
            end
        end
    end
    if found>=8 then break end
end
if found==0 then print("  tidak ada") end

-- upvalue
print("")
print("=== Fungsi dengan upvalue PlayerPetData container ===")
if getupvalues then
    local uf = 0
    for i = 1, #gc do
        local fn = gc[i]
        if type(fn)=="function" then
            pcall(function()
                for uvk, uv in pairs(getupvalues(fn)) do
                    if uv==playerPetDataTable then
                        uf = uf + 1
                        if uf<=8 then
                            local info = debug and debug.getinfo and debug.getinfo(fn)
                            print(string.format("  [%d] upvalue[%s] src=%s", uf, tostring(uvk), tostring(info and info.short_src or "?")))
                        end
                    end
                end
            end)
        end
    end
    print("Total:", uf)
end
