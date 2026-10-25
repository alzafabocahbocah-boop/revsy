-- cari MutableStats via backpack parent chain (metode findMemoryContainer up6kg)
local player = game:GetService("Players").LocalPlayer
local bp = player:FindFirstChild("Backpack")
print("Backpack:", bp and bp:GetFullName() or "nil")

-- kumpulkan semua MutableStats unik
local stats = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        if type(mp) == "number" then
            local isDup = false
            for _, s in ipairs(stats) do
                if rawequal(s, obj) then isDup = true; break end
            end
            if not isDup then stats[#stats+1] = obj end
        end
    end
end
print("MutableStats unik:", #stats)

-- untuk tiap stats, trace parent chain sampai Instance
-- caranya: build reverse map dari table ke parentnya
print("\n--- bangun reverse map (bisa lama) ---")
local parentOf = {}  -- parentOf[child_table] = {key, parent_table}

for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        for k, v in pairs(obj) do
            if type(v) == "table" then
                if not parentOf[v] then
                    parentOf[v] = {key=tostring(k), parent=obj}
                end
            end
        end
    end
end
print("reverse map selesai")

-- trace tiap MutableStats naik ke atas sampai kita ketemu Instance atau stuck
for i, s in ipairs(stats) do
    local mp = rawget(s, "MaxPetsInInventory")
    print(string.format("\n--- trace #%d MaxPets=%d ---", i, mp))
    local cur = s
    local depth = 0
    local seen = {}
    while cur and depth < 15 do
        if seen[cur] then print("  [cycle]"); break end
        seen[cur] = true
        local info = parentOf[cur]
        if not info then
            -- coba cek apakah ini Instance
            local isInst = pcall(function() return typeof(cur) end)
            print(string.format("  depth=%d: no parent (root?)", depth))
            break
        end
        local keyStr = info.key
        local parentType = type(info.parent)
        -- cek kalau parent adalah Instance
        local instName = ""
        pcall(function()
            if typeof(info.parent) == "Instance" then
                instName = " [Instance: " .. info.parent:GetFullName() .. "]"
            end
        end)
        -- cek apakah parent punya field yg khas
        local pmp = type(info.parent)=="table" and rawget(info.parent,"MaxPetsInInventory")
        local pkeys = {}
        if type(info.parent) == "table" then
            for k in pairs(info.parent) do
                if type(k)=="string" then pkeys[#pkeys+1]=k end
                if #pkeys >= 4 then break end
            end
        end
        print(string.format("  depth=%d key='%s' parentType=%s parentKeys={%s}%s",
            depth, keyStr, parentType, table.concat(pkeys,","), instName))
        cur = info.parent
        depth = depth + 1
    end
end

-- cek langsung: apakah backpack ada di getgc dan bisa di-link?
print("\n--- cek Backpack di getgc ---")
local bpFound = false
for _, obj in pairs(getgc(true)) do
    if rawequal(obj, bp) then bpFound = true; break end
end
print("Backpack ada di getgc:", bpFound)
