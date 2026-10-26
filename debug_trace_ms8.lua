-- debug_trace_ms8.lua
-- Cari table{wildnx_27_DataServiceProfile, ActivePetsService_Replicator}
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

local gc = getgc(true)

-- temukan target langsung
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

-- temukan ppdc
local ppdc = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=target and rawget(obj,"PlayerPetData")==target then
        ppdc = obj; break
    end
end
if not ppdc then print("ppdc nil"); return end

-- temukan {PathRegistry,Table}
local prTable = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and rawget(obj,"Table")==ppdc and rawget(obj,"PathRegistry")~=nil then
        prTable = obj; break
    end
end
if not prTable then print("prTable nil"); return end

-- temukan {wildnx_27_DataServiceProfile, ActivePetsService_Replicator}
local dspTable = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=prTable and obj~=ppdc and obj~=target then
        if rawget(obj,"ActivePetsService_Replicator")==prTable then
            dspTable = obj; break
        end
    end
end

if not dspTable then
    -- fallback: cari yang punya key ActivePetsService_Replicator saja
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj)=="table" and rawget(obj,"ActivePetsService_Replicator")~=nil then
            local ks = {}
            for k in pairs(obj) do ks[#ks+1]=tostring(k); if #ks>=6 then break end end
            print("kandidat: {" .. table.concat(ks,",") .. "}")
        end
    end
    print("dspTable nil"); return
end

print("dspTable ditemukan!")
local dspKeys = {}
for k in pairs(dspTable) do dspKeys[#dspKeys+1]=tostring(k) end
print("  keys:", table.concat(dspKeys,", "))

-- cek _G
print("")
print("=== dspTable ada di _G? ===")
local inG = false
for gk, gv in pairs(_G) do
    if gv==dspTable then print("  _G."..tostring(gk)); inG=true end
    if type(gv)=="table" then
        for gk2, gv2 in pairs(gv) do
            if gv2==dspTable then print("  _G."..tostring(gk).."."..tostring(gk2)); inG=true end
        end
    end
end
if not inG then print("  tidak ada di _G") end

-- siapa pegang dspTable
print("")
print("=== Yang pegang dspTable ===")
local found = 0
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=dspTable and obj~=prTable and obj~=ppdc and obj~=target then
        for k, v in pairs(obj) do
            if v==dspTable then
                found = found + 1
                local ks = {}
                for kk in pairs(obj) do ks[#ks+1]=tostring(kk); if #ks>=8 then break end end
                print(string.format("  [%d] key='%s' in table{%s}", found, tostring(k), table.concat(ks,",")))
                -- cek _G langsung
                for gk, gv2 in pairs(_G) do
                    if gv2==obj then print("    -> _G."..tostring(gk)) end
                end
                if found>=8 then break end
            end
        end
    end
    if found>=8 then break end
end
if found==0 then print("  tidak ada — INI ROOT!") end

-- upvalue
print("")
print("=== Fungsi dengan upvalue dspTable ===")
if getupvalues then
    local uf = 0
    for i = 1, #gc do
        local fn = gc[i]
        if type(fn)=="function" then
            pcall(function()
                for uvk, uv in pairs(getupvalues(fn)) do
                    if uv==dspTable then
                        uf = uf + 1
                        if uf<=5 then
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

-- coba DataServiceProfile key juga
print("")
print("=== DataServiceProfile value ===")
local dsp = rawget(dspTable, tostring(myName).."_DataServiceProfile") or rawget(dspTable, "wildnx_27_DataServiceProfile")
if dsp then
    print("  DataServiceProfile type:", type(dsp))
    if type(dsp)=="table" then
        local dspk = {}
        for k in pairs(dsp) do dspk[#dspk+1]=tostring(k); if #dspk>=10 then break end end
        print("  keys:", table.concat(dspk,", "))
    end
else
    -- cek key apa yang ada selain ActivePetsService_Replicator
    for k,v in pairs(dspTable) do
        if k~="ActivePetsService_Replicator" then
            print("  other key:", tostring(k), "type:", type(v))
        end
    end
end
