-- coba getgc(true) dan lihat isinya
print("getgc ada:", getgc ~= nil)
if not getgc then return end

local counts = {table=0, func=0, thread=0, userdata=0, other=0}
for _, obj in pairs(getgc(true)) do
    local t = type(obj)
    if t == "table" then counts.table = counts.table + 1
    elseif t == "function" then counts.func = counts.func + 1
    elseif t == "thread" then counts.thread = counts.thread + 1
    elseif t == "userdata" then counts.userdata = counts.userdata + 1
    else counts.other = counts.other + 1
    end
end
print("getgc(true): table=" .. counts.table
    .. " func=" .. counts.func
    .. " thread=" .. counts.thread
    .. " ud=" .. counts.userdata)

-- scan table dengan MaxPetsInInventory
local found = 0
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        if type(mp) == "number" then
            found = found + 1
            print("MutableStats #" .. found .. " MaxPets=" .. mp
                .. " MaxEggs=" .. tostring(rawget(obj,"MaxEggsInFarm"))
                .. " MaxEquip=" .. tostring(rawget(obj,"MaxEquippedPets")))
        end
    end
end
if found == 0 then
    print("MutableStats: tidak ketemu")
    -- cari table yang ada key 'Max' apapun
    local anyMax = 0
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" then
            for k in pairs(obj) do
                if type(k)=="string" and k:sub(1,3)=="Max" then
                    anyMax = anyMax + 1
                    if anyMax <= 3 then
                        print("key Max: " .. k .. "=" .. tostring(rawget(obj,k)))
                    end
                    break
                end
            end
        end
    end
    print("table dengan key 'Max...': " .. anyMax)
end
