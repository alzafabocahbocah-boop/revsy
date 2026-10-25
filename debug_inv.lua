-- cari inventory container pet via getgc, link ke backpack player
local player = game:GetService("Players").LocalPlayer
local bp = player:FindFirstChild("Backpack")
print("player:", player.Name, "userId:", player.UserId)

-- step 1: cari semua table yang rawequal dengan backpack
-- (executor ini backpack ada di getgc)
local bpRef = nil
for _, obj in pairs(getgc(true)) do
    if rawequal(obj, bp) then bpRef = obj; break end
end
print("backpack di getgc:", bpRef ~= nil)

-- step 2: cari table yang punya field yang nilainya = backpack instance
-- atau punya field "Backpack" / "backpack"
local found = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        -- cek langsung field "Backpack"
        local v = rawget(obj, "Backpack") or rawget(obj, "backpack")
        if v and rawequal(v, bp) then
            found[#found+1] = {obj=obj, how="field"}
        end
        -- cek kalau ada value yang = bp
        for k, val in pairs(obj) do
            if rawequal(val, bp) then
                found[#found+1] = {obj=obj, how="value[" .. tostring(k) .. "]"}
                break
            end
        end
    end
end
print("table yang ref ke backpack:", #found)
for i, f in ipairs(found) do
    if i > 5 then print("..."); break end
    local keys = {}
    for k in pairs(f.obj) do
        if type(k)=="string" then keys[#keys+1]=k end
        if #keys >= 8 then break end
    end
    print(string.format("  [%d] via=%s keys={%s}", i, f.how, table.concat(keys,",")))
    -- cek apakah ada MaxPetsInInventory
    local mp = rawget(f.obj, "MaxPetsInInventory")
    if mp then print("    MaxPetsInInventory=" .. tostring(mp)) end
    -- cek apakah ada field player/user id
    local uid = rawget(f.obj,"UserId") or rawget(f.obj,"userId") or rawget(f.obj,"playerId")
    if uid then print("    userId=" .. tostring(uid)) end
end

-- step 3: cari table yang ref ke player instance langsung
print("\n--- table ref ke player instance ---")
local pFound = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        for k, v in pairs(obj) do
            if rawequal(v, player) then
                pFound[#pFound+1] = {obj=obj, key=tostring(k)}
                break
            end
        end
    end
end
print("total:", #pFound)
for i, f in ipairs(pFound) do
    if i > 8 then print("..."); break end
    local keys = {}
    for k in pairs(f.obj) do
        if type(k)=="string" then keys[#keys+1]=k end
        if #keys >= 6 then break end
    end
    local mp = rawget(f.obj, "MaxPetsInInventory")
    print(string.format("  [%d] key='%s' MaxPets=%s keys={%s}",
        i, f.key, tostring(mp), table.concat(keys,",")))
end
