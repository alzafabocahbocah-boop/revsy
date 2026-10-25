-- cek apakah MutableStats duplikat (rawequal) dan cari via findFirstChild path
local player = game:GetService("Players").LocalPlayer

local stats = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        local mp = rawget(obj, "MaxPetsInInventory")
        if type(mp) == "number" then
            -- cek duplikat
            local isDup = false
            for _, s in ipairs(stats) do
                if rawequal(s, obj) then isDup = true; break end
            end
            if not isDup then stats[#stats+1] = obj end
        end
    end
end
print("MutableStats unik:", #stats)
for i, s in ipairs(stats) do
    print(string.format("#%d MaxPets=%d", i, rawget(s,"MaxPetsInInventory")))
end

-- coba akses via Instance path langsung
-- PlayerData atau DataStore biasanya ada di player
print("\n--- cari via player descendants ---")
local function tryFind(root, depth)
    if depth > 5 then return end
    for _, child in ipairs(root:GetChildren()) do
        local n = child.Name
        if n:lower():find("stat") or n:lower():find("data") or n:lower():find("mutable") then
            print("  found:", child:GetFullName(), child.ClassName)
            -- cek attribute
            local mp = child:GetAttribute("MaxPetsInInventory")
                    or child:GetAttribute("MaxPets")
            if mp then print("    MaxPets attr:", mp) end
        end
        tryFind(child, depth+1)
    end
end
tryFind(player, 0)

-- coba PlayerData service
print("\n--- cari PlayerData service ---")
for _, svc in ipairs({"DataStoreService","ReplicatedStorage","ServerStorage"}) do
    local ok, s = pcall(function() return game:GetService(svc) end)
    if ok and s then
        -- cek children
        for _, child in ipairs(s:GetChildren()) do
            if child.Name:lower():find("mutable") or child.Name:lower():find("stat") then
                print("  " .. svc .. "." .. child.Name, child.ClassName)
            end
        end
    end
end
