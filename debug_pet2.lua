-- eksplorasi table [4] yang punya keys: Index,AssignToolData,IsEquipped,dll
local player = game:GetService("Players").LocalPlayer
local bp = player:FindFirstChild("Backpack")
local target = bp and bp:GetChildren()[1]
if not target then print("backpack kosong"); return end
print("target pet:", target.Name)

-- cari table yang ref ke target DAN punya key 'Tool'
local toolTable = nil
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        local hasTool = rawget(obj, "Tool")
        local hasAssign = rawget(obj, "AssignToolData")
        if hasTool and hasAssign then
            -- cek apakah ini ref ke pet kita
            for k, v in pairs(obj) do
                if rawequal(v, target) then
                    toolTable = obj
                    break
                end
            end
            if toolTable then break end
        end
    end
end

if not toolTable then
    print("toolTable tidak ketemu, cari semua yang punya key 'Tool' + 'Fill'")
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" then
            if rawget(obj,"Tool") and rawget(obj,"Fill") and rawget(obj,"Index") then
                toolTable = obj
                break
            end
        end
    end
end

if not toolTable then print("gak ketemu"); return end
print("toolTable ketemu!")

-- dump semua field toolTable
local keys = {}
for k in pairs(toolTable) do keys[#keys+1] = tostring(k) end
table.sort(keys)
print("keys:", table.concat(keys, ", "))

-- cek tiap value yang table/function
for _, k in ipairs(keys) do
    local v = rawget(toolTable, k)
    local t = type(v)
    if t == "table" then
        -- dump sub-keys
        local subkeys = {}
        for sk in pairs(v) do
            if type(sk)=="string" then subkeys[#subkeys+1]=sk end
            if #subkeys >= 6 then break end
        end
        print(string.format("  %s = {table} subkeys={%s}", k, table.concat(subkeys,",")))
        -- cek MaxPetsInInventory
        local mp = rawget(v, "MaxPetsInInventory")
        if mp then print("    -> MaxPetsInInventory=" .. tostring(mp)) end
        -- cek MutableStats
        local ms = rawget(v, "MutableStats") or rawget(v, "mutableStats")
        if ms then
            print("    -> MutableStats ada! MaxPets=" .. tostring(rawget(ms,"MaxPetsInInventory")))
        end
    elseif t ~= "function" then
        print(string.format("  %s = %s", k, tostring(v)))
    end
end

-- cari parent dari toolTable yang punya MaxPetsInInventory atau MutableStats
print("\n--- cari parent toolTable ---")
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        for k, v in pairs(obj) do
            if rawequal(v, toolTable) then
                local mp = rawget(obj, "MaxPetsInInventory")
                local ms = rawget(obj, "MutableStats")
                local keys2 = {}
                for kk in pairs(obj) do
                    if type(kk)=="string" then keys2[#keys2+1]=kk end
                    if #keys2 >= 8 then break end
                end
                print(string.format("  parent key='%s' MaxPets=%s MS=%s keys={%s}",
                    tostring(k), tostring(mp), tostring(ms~=nil), table.concat(keys2,",")))
                break
            end
        end
    end
end
