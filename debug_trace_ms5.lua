-- debug_trace_ms5.lua
-- Cari siapa yang pegang obj{wildnx_27} yang punya MutableStats
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

-- temukan obj target dulu
local gc = getgc(true)
local target = nil
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" then
        local v = rawget(obj, myName)
        if type(v)=="table" then
            local ms = rawget(v, "MutableStats")
            if type(ms)=="table" then
                local mp = rawget(ms, "MaxPetsInInventory")
                if type(mp)=="number" and mp==260 then
                    target = obj
                    break
                end
            end
        end
    end
end

if not target then print("target tidak ditemukan"); return end
print("target ditemukan, MaxPetsInInventory =", rawget(rawget(target, myName), "MutableStats") and rawget(rawget(rawget(target, myName), "MutableStats"), "MaxPetsInInventory"))

-- cari siapa yang pegang target
print("")
print("=== Yang pegang target ===")
local found = 0
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and obj~=target then
        for k, v in pairs(obj) do
            if v==target then
                found = found + 1
                local keys = {}
                for kk in pairs(obj) do keys[#keys+1]=tostring(kk); if #keys>=8 then break end end
                print(string.format("  [%d] key='%s' in table{%s}", found, tostring(k), table.concat(keys,",")))
                -- cek di _G
                for gk, gv in pairs(_G) do
                    if gv==obj then print("    -> _G."..tostring(gk)) end
                end
                if found>=8 then break end
            end
        end
    end
    if found>=8 then break end
end
if found==0 then print("  tidak ada — target adalah root/upvalue") end

-- cek _G langsung
print("")
print("=== target ada di _G? ===")
local inG = false
for gk, gv in pairs(_G) do
    if gv==target then print("  _G."..tostring(gk)); inG=true end
    if type(gv)=="table" then
        for gk2, gv2 in pairs(gv) do
            if gv2==target then print("  _G."..tostring(gk).."."..tostring(gk2)); inG=true end
        end
    end
end
if not inG then print("  tidak ada di _G") end

-- cek upvalue
print("")
print("=== Fungsi dengan upvalue = target ===")
if getupvalues then
    local uf = 0
    for i = 1, #gc do
        local fn = gc[i]
        if type(fn)=="function" then
            pcall(function()
                for uvk, uv in pairs(getupvalues(fn)) do
                    if uv==target then
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
