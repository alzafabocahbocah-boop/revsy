-- dump SEMUA field dari tiap MutableStats
local stats = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        if type(mp) == "number" then
            stats[#stats+1] = obj
        end
    end
end
print("Total MutableStats:", #stats)

for i, s in ipairs(stats) do
    local mp = rawget(s, "MaxPetsInInventory")
    print(string.format("\n--- #%d MaxPets=%d ---", i, mp))
    local keys = {}
    for k in pairs(s) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a)<tostring(b) end)
    for _, k in ipairs(keys) do
        local v = rawget(s, k)
        local vstr = type(v) == "table" and "{table}" or tostring(v)
        print(string.format("  %s = %s", tostring(k), vstr))
    end
end
