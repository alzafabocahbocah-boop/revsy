-- debug_feed.lua — scan dan coba trigger FeedPetProxPart / Mesin Mutasi
-- Dari log sebelumnya: path=FeedPetProxPart, action='Interact', maxDist=inf
-- Jalankan saat karakter dekat mesin mutasi

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

print("=== debug_feed.lua ===")
print("Posisi char: " .. tostring(hrp.Position))

-- 1. Cari FeedPetProxPart langsung di workspace
local feedPart = game.Workspace:FindFirstChild("FeedPetProxPart", true)
if feedPart then
    print("[OK] FeedPetProxPart ditemukan!")
    print("     Instance: " .. tostring(feedPart))
    print("     Class: " .. feedPart.ClassName)
    print("     Parent: " .. tostring(feedPart.Parent))
    if feedPart.Parent then
        print("     Parent.Parent: " .. tostring(feedPart.Parent.Parent))
    end

    -- Hitung jarak
    local pos
    if feedPart:IsA("BasePart") then pos = feedPart.Position
    elseif feedPart.Parent and feedPart.Parent:IsA("BasePart") then pos = feedPart.Parent.Position end
    if pos then
        local dist = (hrp.Position - pos).Magnitude
        print("     Jarak: " .. string.format("%.1f", dist) .. "m")
    end

    -- Cari ProximityPrompt di dalam atau di parent
    local pp = feedPart:FindFirstChildOfClass("ProximityPrompt")
    if not pp then pp = feedPart.Parent and feedPart.Parent:FindFirstChildOfClass("ProximityPrompt") end

    if pp then
        print("[OK] ProximityPrompt ditemukan!")
        print("     ActionText: '" .. pp.ActionText .. "'")
        print("     ObjectText: '" .. pp.ObjectText .. "'")
        print("     MaxActivationDistance: " .. tostring(pp.MaxActivationDistance))
        print("     Enabled: " .. tostring(pp.Enabled))
        print("     RequiresLineOfSight: " .. tostring(pp.RequiresLineOfSight))

        -- Coba trigger
        print("\n[...] Mencoba trigger ProximityPrompt...")
        local ok, err = pcall(function()
            fireproximityprompt(pp)
        end)
        if ok then
            print("[OK] fireproximityprompt berhasil!")
        else
            print("[ERR] fireproximityprompt gagal: " .. tostring(err))
            -- Coba cara lain
            local ok2, err2 = pcall(function()
                pp:InputHoldBegin()
            end)
            if ok2 then
                print("[OK] InputHoldBegin berhasil!")
                task.wait(0.5)
                pcall(function() pp:InputHoldEnd() end)
            else
                print("[ERR] InputHoldBegin gagal: " .. tostring(err2))
            end
        end
    else
        print("[WARN] Tidak ada ProximityPrompt di FeedPetProxPart")
        -- Scan children
        print("Children dari FeedPetProxPart:")
        for _, c in ipairs(feedPart:GetChildren()) do
            print("  - " .. c.Name .. " (" .. c.ClassName .. ")")
        end
    end
else
    print("[WARN] FeedPetProxPart tidak ditemukan!")
    print("Mencari alternatif dengan keyword...")

    -- Scan workspace cari nama yang mirip
    local function scan(obj, depth)
        if depth > 6 then return end
        local name = obj.Name:lower()
        if name:find("feed") or name:find("mutasi") or name:find("mutate") or name:find("mutation") or name:find("kirim") then
            print("  [FOUND] " .. obj.Name .. " (" .. obj.ClassName .. ") @ " .. obj:GetFullName())
        end
        for _, c in ipairs(obj:GetChildren()) do
            pcall(scan, c, depth + 1)
        end
    end
    pcall(scan, game.Workspace, 0)
end

-- 2. Scan semua PP dengan action 'Interact' atau yang tidak umum
print("\n=== PP dengan action bukan Collect/Hatch/Skip/View ===")
local interesting = {}
local function scanPP(obj, depth)
    if depth > 8 then return end
    local ok, pp = pcall(function() return obj:FindFirstChildOfClass("ProximityPrompt") end)
    if ok and pp then
        local action = pp.ActionText
        if action ~= "Collect" and action ~= "Hatch!" and action ~= "Skip Growth"
           and action ~= "Hatch All" and action ~= "View" and action ~= "Skip All Growth" then
            local pos
            if obj:IsA("BasePart") then pos = obj.Position
            elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position end
            local dist = 9999
            if pos then
                local ok2, d = pcall(function() return (hrp.Position - pos).Magnitude end)
                if ok2 then dist = math.floor(d*10)/10 end
            end
            interesting[#interesting+1] = {
                dist=dist, action=action, object=pp.ObjectText,
                path=obj:GetFullName(), maxDist=pp.MaxActivationDistance, pp=pp
            }
        end
    end
    for _, c in ipairs(obj:GetChildren()) do pcall(scanPP, c, depth+1) end
end
pcall(scanPP, game.Workspace, 0)
table.sort(interesting, function(a,b) return a.dist < b.dist end)
for i, r in ipairs(interesting) do
    print(string.format("[%d] %.1fm | action='%s' | obj='%s'", i, r.dist, r.action, r.object))
    print("     " .. r.path)
end
print("=== selesai ===")
