-- naik 2-3 level dari toolTable, cari container inventory
local player = game:GetService("Players").LocalPlayer
local bp = player:FindFirstChild("Backpack")
local target = bp and bp:GetChildren()[1]
if not target then print("backpack kosong"); return end

-- cari toolTable dulu
local toolTable = nil
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" and rawget(obj,"Tool") and rawget(obj,"Fill") and rawget(obj,"Index") then
        for k, v in pairs(obj) do
            if rawequal(v, target) then toolTable = obj; break end
        end
        if toolTable then break end
    end
end
if not toolTable then print("toolTable nil"); return end
print("toolTable ok, Index=" .. tostring(rawget(toolTable,"Index")))

-- bangun reverse map satu level saja dari toolTable
-- cari semua parent dari toolTable
local level1 = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" and obj ~= toolTable then
        for k, v in pairs(obj) do
            if rawequal(v, toolTable) then
                level1[#level1+1] = {obj=obj, key=tostring(k)}
                break
            end
        end
    end
end
print("level1 parents:", #level1)

-- untuk tiap level1, cari parent mereka (level2)
for i, l1 in ipairs(level1) do
    if i > 4 then break end
    local keys1 = {}
    for k in pairs(l1.obj) do
        if type(k)=="string" then keys1[#keys1+1]=k end
        if #keys1 >= 6 then break end
    end
    local mp1 = rawget(l1.obj,"MaxPetsInInventory")
    print(string.format("\nL1[%d] key='%s' MaxPets=%s keys={%s}", i, l1.key, tostring(mp1), table.concat(keys1,",")))

    -- cari parent L1
    local l2count = 0
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and obj ~= l1.obj then
            for k, v in pairs(obj) do
                if rawequal(v, l1.obj) then
                    l2count = l2count + 1
                    if l2count <= 3 then
                        local keys2 = {}
                        for kk in pairs(obj) do
                            if type(kk)=="string" then keys2[#keys2+1]=kk end
                            if #keys2 >= 8 then break end
                        end
                        local mp2 = rawget(obj,"MaxPetsInInventory")
                        local ms2 = rawget(obj,"MutableStats") or rawget(obj,"mutableStats")
                        local cap = rawget(obj,"Capacity") or rawget(obj,"capacity") or rawget(obj,"MaxSize")
                        print(string.format("  L2 key='%s' MaxPets=%s MS=%s Cap=%s keys={%s}",
                            tostring(k), tostring(mp2), tostring(ms2~=nil), tostring(cap), table.concat(keys2,",")))
                    end
                    break
                end
            end
        end
    end
    print("  L2 total:", l2count)
end
