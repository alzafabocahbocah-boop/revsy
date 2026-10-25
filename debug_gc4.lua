-- cari MutableStats milik user sendiri lewat parent chain
local player = game:GetService("Players").LocalPlayer
local bp = player:FindFirstChild("Backpack")
print("player:", player.Name, "userId:", player.UserId)
print("Backpack:", bp and bp:GetFullName() or "nil")

-- kumpulkan semua MutableStats dulu
local stats = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        if type(mp) == "number" then
            stats[#stats+1] = {tbl=obj, mp=mp,
                me=rawget(obj,"MaxEggsInFarm"),
                mq=rawget(obj,"MaxEquippedPets")}
        end
    end
end
print("Total MutableStats:", #stats)

-- untuk tiap stats, cari siapa parentnya lewat getgc
-- caranya: cari table lain yang punya value = stats[i].tbl
for i, s in ipairs(stats) do
    print(string.format("\n--- MutableStats #%d MaxPets=%d ---", i, s.mp))
    local parents = {}
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and obj ~= s.tbl then
            for k, v in pairs(obj) do
                if v == s.tbl then
                    parents[#parents+1] = {key=tostring(k), parent=obj}
                    break
                end
            end
        end
    end
    print("  jumlah parent:", #parents)
    for j, p in ipairs(parents) do
        if j > 3 then print("  ..."); break end
        -- cek apakah parent ini ada di dalam backpack/player
        local keys = {}
        for k in pairs(p.parent) do
            if type(k)=="string" then keys[#keys+1]=k end
            if #keys >= 6 then break end
        end
        -- cek apakah parent punya UserId atau Name yang cocok
        local uid = rawget(p.parent, "UserId") or rawget(p.parent, "userId")
        local nm  = rawget(p.parent, "Name") or rawget(p.parent, "name")
        print(string.format("  parent[%d] key='%s' UserId=%s Name=%s keys={%s}",
            j, p.key, tostring(uid), tostring(nm), table.concat(keys,",")))
    end

    -- cek langsung: apakah ada field UserId di stats table sendiri
    local uid2 = rawget(s.tbl, "UserId") or rawget(s.tbl, "userId")
    local nm2  = rawget(s.tbl, "Name")
    local pid  = rawget(s.tbl, "PlayerId") or rawget(s.tbl, "playerId")
    print(string.format("  self: UserId=%s Name=%s PlayerId=%s",
        tostring(uid2), tostring(nm2), tostring(pid)))
end
