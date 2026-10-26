-- debug_trace_ms7.lua
-- Cari table{PathRegistry,Table} dan cek apakah ada di _G
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

local gc = getgc(true)

-- step 1: temukan PlayerPetData container dulu
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

local ppdc = nil  -- PlayerPetData container
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=target then
        if rawget(obj,"PlayerPetData")==target then
            ppdc = obj; break
        end
    end
end
if not ppdc then print("ppdc nil"); return end
print("ppdc ditemukan: ActivePetStates,PlayerPetData,ServerPetStates,ServerPetData")

-- step 2: temukan {PathRegistry,Table} yang pegang ppdc dengan key="Table"
local prTable = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=ppdc and obj~=target then
        if rawget(obj,"Table")==ppdc and rawget(obj,"PathRegistry")~=nil then
            prTable = obj; break
        end
    end
end

if prTable then
    print("PathRegistry table ditemukan!")
    local keys = {}
    for k in pairs(prTable) do keys[#keys+1]=tostring(k) end
    print("  keys:", table.concat(keys,", "))
    local pr = rawget(prTable, "PathRegistry")
    print("  PathRegistry type:", type(pr))
    if type(pr)=="table" then
        local prkeys = {}
        for k in pairs(pr) do prkeys[#prkeys+1]=tostring(k); if #prkeys>=10 then break end end
        print("  PathRegistry keys:", table.concat(prkeys,", "))
    end

    -- cek di _G
    print("")
    print("=== PathRegistry table ada di _G? ===")
    local inG = false
    for gk, gv in pairs(_G) do
        if gv==prTable then print("  _G."..tostring(gk)); inG=true end
        if type(gv)=="table" then
            for gk2, gv2 in pairs(gv) do
                if gv2==prTable then print("  _G."..tostring(gk).."."..tostring(gk2)); inG=true end
            end
        end
    end
    if not inG then print("  tidak ada di _G") end

    -- cek PathRegistry sendiri
    print("")
    print("=== PathRegistry ada di _G? ===")
    local pr2 = rawget(prTable, "PathRegistry")
    inG = false
    for gk, gv in pairs(_G) do
        if gv==pr2 then print("  _G."..tostring(gk)); inG=true end
        if type(gv)=="table" then
            for gk2, gv2 in pairs(gv) do
                if gv2==pr2 then print("  _G."..tostring(gk).."."..tostring(gk2)); inG=true end
            end
        end
    end
    if not inG then print("  tidak ada di _G") end

    -- siapa pegang {PathRegistry,Table}
    print("")
    print("=== Yang pegang {PathRegistry,Table} ===")
    local found = 0
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj)=="table" and obj~=prTable and obj~=ppdc and obj~=target then
            for k, v in pairs(obj) do
                if v==prTable then
                    found = found + 1
                    local ks = {}
                    for kk in pairs(obj) do ks[#ks+1]=tostring(kk); if #ks>=8 then break end end
                    print(string.format("  [%d] key='%s' in table{%s}", found, tostring(k), table.concat(ks,",")))
                    for gk, gv2 in pairs(_G) do
                        if gv2==obj then print("    -> _G."..tostring(gk)) end
                    end
                    if found>=8 then break end
                end
            end
        end
        if found>=8 then break end
    end
    if found==0 then print("  tidak ada — ini root!") end

    -- test akses via PathRegistry jika ada di _G
    print("")
    print("=== Test akses via PathRegistry ===")
    pcall(function()
        local pr3 = rawget(prTable,"PathRegistry")
        if type(pr3)=="table" then
            -- coba PathRegistry.PlayerPetData[myName].MutableStats.MaxPetsInInventory
            local ppd = rawget(pr3,"PlayerPetData")
            if ppd then
                local ms = rawget(rawget(ppd,myName),"MutableStats")
                if ms then print("  PathRegistry.PlayerPetData[myName].MutableStats.MaxPetsInInventory =", rawget(ms,"MaxPetsInInventory")) end
            else
                print("  PathRegistry tidak punya key PlayerPetData")
                -- print beberapa key PathRegistry
                local prk = {}
                for k in pairs(pr3) do prk[#prk+1]=tostring(k); if #prk>=15 then break end end
                print("  PathRegistry keys:", table.concat(prk,", "))
            end
        end
    end)
else
    print("PathRegistry table tidak ditemukan, cari manual...")
    -- fallback: cari semua yang pegang ppdc
    local found = 0
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj)=="table" and obj~=ppdc and obj~=target then
            for k, v in pairs(obj) do
                if v==ppdc then
                    found = found + 1
                    local ks = {}
                    for kk in pairs(obj) do ks[#ks+1]=tostring(kk); if #ks>=8 then break end end
                    print(string.format("  [%d] key='%s' in table{%s}", found, tostring(k), table.concat(ks,",")))
                    for gk, gv2 in pairs(_G) do
                        if gv2==obj then print("    -> _G."..tostring(gk)) end
                    end
                    if found>=8 then break end
                end
            end
        end
        if found>=8 then break end
    end
end
