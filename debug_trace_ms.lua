-- debug_trace_ms.lua
-- Ambil pointer MutableStats 260 dari GC, lalu trace semua yang pegang dia
local player = game:GetService("Players").LocalPlayer

-- ambil semua MutableStats 260
local targets = {}
local gc = getgc(true)
for i = 1, #gc do
    local obj = gc[i]
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        local me = rawget(obj, "MaxEggsInFarm")
        local mq = rawget(obj, "MaxEquippedPets")
        if type(mp)=="number" and mp==260
        and type(me)=="number" and me>0
        and type(mq)=="number" and mq>0 then
            targets[obj] = true
        end
    end
end
print("Target MutableStats (mp=260):", (function() local n=0; for _ in pairs(targets) do n=n+1 end; return n end)())

-- scan semua table di GC, cari yang punya value = salah satu target
print("")
print("=== Table yang pegang MutableStats 260 ===")
local holders = {}
for i = 1, #gc do
    local obj = gc[i]
    if type(obj) == "table" and not targets[obj] then
        for k, v in pairs(obj) do
            if targets[v] then
                local keys = {}
                for kk in pairs(obj) do keys[#keys+1] = tostring(kk); if #keys >= 8 then break end end
                local entry = "  key='"..tostring(k).."' in table{" .. table.concat(keys,",") .. "}"
                holders[#holders+1] = {obj=obj, key=k, entry=entry}
                print(entry)
                break
            end
        end
    end
end
print("Total holder:", #holders)

-- cek apakah holder bisa diakses dari _G atau require
print("")
print("=== Cek holder ada di _G? ===")
for _, h in ipairs(holders) do
    for gk, gv in pairs(_G) do
        if gv == h.obj then
            print("  _G." .. tostring(gk) .. " -> " .. h.entry)
        end
        if type(gv) == "table" then
            for gk2, gv2 in pairs(gv) do
                if gv2 == h.obj then
                    print("  _G." .. tostring(gk) .. "." .. tostring(gk2) .. " -> " .. h.entry)
                end
            end
        end
    end
end

-- cek upvalue dari fungsi yang pegang holder
print("")
print("=== Fungsi yang punya upvalue = holder ===")
if getupvalues then
    local holderSet = {}
    for _, h in ipairs(holders) do holderSet[h.obj] = true end
    local found = 0
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj) == "function" then
            pcall(function()
                local ups = getupvalues(obj)
                for uvk, uv in pairs(ups) do
                    if holderSet[uv] then
                        found = found + 1
                        if found <= 8 then
                            local info = debug and debug.getinfo and debug.getinfo(obj)
                            print("  fn upvalue[" .. tostring(uvk) .. "] src=" .. tostring(info and info.short_src or "?"))
                        end
                    end
                end
            end)
        end
    end
    print("Total:", found)
end
