-- debug_trace_ms2.lua
-- Cari siapa yang pegang PlayerData container (table yg punya MutableStats key)
local player = game:GetService("Players").LocalPlayer

-- ambil MutableStats 260 dulu
local msTargets = {}
local gc = getgc(true)
for i = 1, #gc do
    local obj = gc[i]
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        local me = rawget(obj, "MaxEggsInFarm")
        local mq = rawget(obj, "MaxEquippedPets")
        if type(mp)=="number" and mp==260 and type(me)=="number" and type(mq)=="number" then
            msTargets[obj] = true
        end
    end
end

-- cari PlayerData container (yang punya key MutableStats = salah satu msTargets)
local pdTargets = {}
for i = 1, #gc do
    local obj = gc[i]
    if type(obj) == "table" and not msTargets[obj] then
        local ms = rawget(obj, "MutableStats")
        if msTargets[ms] then
            pdTargets[obj] = true
        end
    end
end
print("PlayerData containers:", (function() local n=0; for _ in pairs(pdTargets) do n=n+1 end; return n end)())

-- print keys dari PlayerData
for pd in pairs(pdTargets) do
    local keys = {}
    for k in pairs(pd) do keys[#keys+1] = tostring(k) end
    print("  keys: " .. table.concat(keys, ", "))
    break  -- cukup satu
end

-- sekarang cari siapa yang pegang PlayerData
print("")
print("=== Table yang pegang PlayerData ===")
local found = 0
for i = 1, #gc do
    local obj = gc[i]
    if type(obj) == "table" and not pdTargets[obj] and not msTargets[obj] then
        for k, v in pairs(obj) do
            if pdTargets[v] then
                found = found + 1
                local keys = {}
                for kk in pairs(obj) do keys[#keys+1] = tostring(kk); if #keys >= 8 then break end end
                print(string.format("  [%d] key='%s' in table{%s}", found, tostring(k), table.concat(keys,",")))
                if found >= 10 then break end
            end
        end
    end
    if found >= 10 then break end
end
if found == 0 then print("  tidak ada") end

-- cek _G
print("")
print("=== Cek PlayerData ada di _G? ===")
for gk, gv in pairs(_G) do
    if pdTargets[gv] then
        print("  _G." .. tostring(gk))
    end
    if type(gv) == "table" then
        for gk2, gv2 in pairs(gv) do
            if pdTargets[gv2] then
                print("  _G." .. tostring(gk) .. "." .. tostring(gk2))
            end
        end
    end
end

-- cek upvalue
print("")
print("=== Fungsi dengan upvalue PlayerData ===")
if getupvalues then
    local uf = 0
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj) == "function" then
            pcall(function()
                local ups = getupvalues(obj)
                for uvk, uv in pairs(ups) do
                    if pdTargets[uv] then
                        uf = uf + 1
                        if uf <= 5 then
                            local info = debug and debug.getinfo and debug.getinfo(obj)
                            print("  fn upvalue[" .. tostring(uvk) .. "] src=" .. tostring(info and info.short_src or "?"))
                        end
                    end
                end
            end)
        end
    end
    print("Total:", uf)
end
