-- debug_gcdump_path.lua
-- Dump GC: cari table punya MaxPetsInInventory
-- lalu cek siapa yang pegang table itu (upvalue, _G, dll)
local player = game:GetService("Players").LocalPlayer

-- hitung curTotal
local curTotal = 0
pcall(function()
    local seen = {}
    local holders = {player:FindFirstChild("Backpack"), player.Character}
    for i = 1, #holders do
        local h = holders[i]
        if h then
            for _, t in ipairs(h:GetChildren()) do
                if t:IsA("Tool") then
                    local u = t:GetAttribute("PET_UUID")
                    if u then
                        local k = tostring(u):gsub("[{}]","")
                        if not seen[k] then seen[k] = true; curTotal = curTotal + 1 end
                    end
                end
            end
        end
    end
end)
print("curTotal =", curTotal)

-- dump semua MutableStats dari GC
print("=== GC dump MutableStats ===")
local found = {}
local gc = getgc(true)
for i = 1, #gc do
    local obj = gc[i]
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        local me = rawget(obj, "MaxEggsInFarm")
        local mq = rawget(obj, "MaxEquippedPets")
        if type(mp)=="number" and mp>0 and mp<=2000
        and type(me)=="number" and me>0
        and type(mq)=="number" and mq>0 then
            found[#found+1] = {obj=obj, mp=mp, me=me, mq=mq}
        end
    end
end
print("Total MutableStats ditemukan:", #found)
for i, f in ipairs(found) do
    -- print semua keys di table ini
    local keys = {}
    for k in pairs(f.obj) do keys[#keys+1] = tostring(k) end
    print(string.format("  [%d] mp=%d me=%d mq=%d | keys: %s", i, f.mp, f.me, f.mq, table.concat(keys, ", ")))
end

-- cek apakah ada di _G
print("")
print("=== Cek _G keys yang mungkin pegang MutableStats ===")
for k, v in pairs(_G) do
    if type(v) == "table" then
        local mp = rawget(v, "MaxPetsInInventory")
        if type(mp) == "number" and mp > 0 and mp <= 2000 then
            print("  _G." .. tostring(k) .. " punya MaxPetsInInventory=" .. tostring(mp))
        end
        -- cek 1 level dalam
        for k2, v2 in pairs(v) do
            if type(v2) == "table" then
                local mp2 = rawget(v2, "MaxPetsInInventory")
                if type(mp2) == "number" and mp2 > 0 and mp2 <= 2000 then
                    print("  _G." .. tostring(k) .. "." .. tostring(k2) .. " punya MaxPetsInInventory=" .. tostring(mp2))
                end
            end
        end
    end
end

-- cek shared
print("")
print("=== Cek shared ===")
pcall(function()
    for k, v in pairs(shared) do
        if type(v) == "table" then
            local mp = rawget(v, "MaxPetsInInventory")
            if type(mp) == "number" and mp > 0 then
                print("  shared." .. tostring(k) .. " punya MaxPetsInInventory=" .. tostring(mp))
            end
        end
    end
end)

-- cek upvalue dari fungsi di GC — cari fungsi yang punya upvalue table dgn MaxPetsInInventory
print("")
print("=== Cek upvalue fungsi di GC (cari yg pegang MutableStats) ===")
local upfound = 0
if getupvalues then
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj) == "function" then
            pcall(function()
                local ups = getupvalues(obj)
                for _, uv in pairs(ups) do
                    if type(uv) == "table" then
                        local mp = rawget(uv, "MaxPetsInInventory")
                        if type(mp)=="number" and mp>0 and mp<=2000 then
                            upfound = upfound + 1
                            if upfound <= 5 then
                                local info = debug and debug.getinfo and debug.getinfo(obj, "S")
                                print("  fungsi src=" .. tostring(info and info.short_src or "?") .. " punya upvalue MaxPetsInInventory=" .. tostring(mp))
                            end
                        end
                    end
                end
            end)
        end
    end
end
print("Total fungsi dgn upvalue MutableStats:", upfound)
