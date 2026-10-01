-- sniff_pp_info.lua — cek properti ProximityPrompt buah mutasi
-- dan test fireproximityprompt langsung dari posisi karakter saat ini

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- cari buah mutasi di farm
local function getPlayerFarm()
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return nil end
    return farm:FindFirstChild(plr.Name) or farm:FindFirstChild("Farm")
end

local function findMutasiFruits()
    local out = {}
    pcall(function()
        local farm = getPlayerFarm(); if not farm then return end
        local imp = farm:FindFirstChild("Important"); if not imp then return end
        local plants = imp:FindFirstChild("Plants_Physical"); if not plants then return end
        for _,pt in ipairs(plants:GetChildren()) do
            local fruits = pt:FindFirstChild("Fruits"); if fruits then
                for _,fruit in ipairs(fruits:GetChildren()) do
                    -- buah mutasi punya atribut Mutations atau mutation_count
                    local mut = fruit:GetAttribute("Mutations") or fruit:GetAttribute("mutation_count") or 0
                    if tonumber(mut) and tonumber(mut) > 0 then
                        out[#out+1] = fruit
                    end
                end
            end
        end
    end)
    return out
end

local fruits = findMutasiFruits()
print("Buah mutasi ditemukan: "..#fruits)

if #fruits == 0 then
    print("TIDAK ada buah mutasi — coba scan semua buah (tanpa filter mutasi)")
    -- scan tanpa filter
    pcall(function()
        local farm = getPlayerFarm()
        local imp = farm:FindFirstChild("Important")
        local plants = imp:FindFirstChild("Plants_Physical")
        for _,pt in ipairs(plants:GetChildren()) do
            local fruits2 = pt:FindFirstChild("Fruits")
            if fruits2 then
                for _,f in ipairs(fruits2:GetChildren()) do
                    print("  Buah: "..f.Name.." path="..f:GetFullName())
                    for k,v in pairs(f:GetAttributes()) do print("    "..k.."="..tostring(v)) end
                    for _,pp in ipairs(f:GetDescendants()) do
                        if pp:IsA("ProximityPrompt") then
                            print("  PP: "..pp:GetFullName())
                            print("    ActionText="..pp.ActionText)
                            print("    MaxActivationDistance="..pp.MaxActivationDistance)
                            print("    RequiresLineOfSight="..tostring(pp.RequiresLineOfSight))
                            print("    Enabled="..tostring(pp.Enabled))
                            -- jarak karakter ke PP
                            local ppPart = pp.Parent
                            if ppPart and ppPart:IsA("BasePart") then
                                local dist = (hrp.Position - ppPart.Position).Magnitude
                                print("    JARAK dari karakter = "..math.floor(dist).." studs")
                            end
                        end
                    end
                end
            end
        end
    end)
else
    -- test collect buah mutasi pertama
    local fruit = fruits[1]
    print("Test fruit: "..fruit:GetFullName())
    for k,v in pairs(fruit:GetAttributes()) do print("  attr: "..k.."="..tostring(v)) end

    -- cari PP
    local pp = nil
    for _,v in ipairs(fruit:GetDescendants()) do
        if v:IsA("ProximityPrompt") then pp = v; break end
    end
    if pp then
        print("PP: "..pp:GetFullName())
        print("  ActionText="..pp.ActionText)
        print("  MaxActivationDistance="..pp.MaxActivationDistance)
        print("  RequiresLineOfSight="..tostring(pp.RequiresLineOfSight))
        print("  Enabled="..tostring(pp.Enabled))
        -- jarak
        local ppPart = pp.Parent
        if ppPart and ppPart:IsA("BasePart") then
            local dist = (hrp.Position - ppPart.Position).Magnitude
            print("  JARAK dari karakter = "..math.floor(dist).." studs")
        end
        -- test fireproximityprompt
        print("--- TEST fireproximityprompt ---")
        local ok, err = pcall(fireproximityprompt, pp)
        print("fireproximityprompt ok="..tostring(ok).." err="..tostring(err))
        task.wait(1)
        -- cek apakah buah masih ada (kalau hilang berarti berhasil)
        if fruit.Parent then
            print("GAGAL: buah masih ada setelah 1s")
        else
            print("SUKSES: buah hilang!")
        end
    else
        print("PP tidak ditemukan di buah!")
    end
end
