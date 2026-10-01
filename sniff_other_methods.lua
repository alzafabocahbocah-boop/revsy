-- sniff_other_methods.lua — test berbagai method collect tanpa jarak
-- test 1 per 1, lihat mana yang bisa

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local function getPlayerFarm()
    local farm = workspace:FindFirstChild("Farm"); if not farm then return nil end
    return farm:FindFirstChild(plr.Name) or farm:FindFirstChild("Farm")
end

local function getFirstFruit()
    local result = nil
    pcall(function()
        local farm = getPlayerFarm()
        local plants = farm:FindFirstChild("Important"):FindFirstChild("Plants_Physical")
        for _,pt in ipairs(plants:GetChildren()) do
            local fruits = pt:FindFirstChild("Fruits")
            if fruits then
                for _,f in ipairs(fruits:GetChildren()) do
                    result = f; return
                end
            end
            if result then return end
        end
    end)
    return result
end

local function getFruitPP(fruit)
    for _, v in ipairs(fruit:GetDescendants()) do
        if v:IsA("ProximityPrompt") then return v end
    end
end

local function testMethod(name, fn)
    local fruit = getFirstFruit()
    if not fruit then print("❌ "..name..": no fruit"); return end
    local pp = getFruitPP(fruit)
    if not pp then print("❌ "..name..": no PP"); return end
    print("--- TEST: "..name.." ---")
    print("  Jarak: "..math.floor((hrp.Position - (pp.Parent and pp.Parent:IsA("BasePart") and pp.Parent.Position or hrp.Position)).Magnitude).." studs")
    local before = fruit.Parent ~= nil
    local ok, err = pcall(fn, fruit, pp)
    task.wait(1)
    local after = fruit.Parent == nil
    if after then
        print("✅ "..name.." SUKSES!")
    else
        print("❌ "..name.." GAGAL. ok="..tostring(ok).." err="..tostring(err))
    end
end

-- pastikan karakter JAUH dari buah dulu (jarak > 30 studs)
print("Jarak karakter ke buah pertama:")
local fruit0 = getFirstFruit()
if fruit0 then
    local pp0 = getFruitPP(fruit0)
    if pp0 and pp0.Parent and pp0.Parent:IsA("BasePart") then
        print("  "..math.floor((hrp.Position - pp0.Parent.Position).Magnitude).." studs")
    end
end

task.wait(1)

-- METHOD 1: fireproximityprompt biasa (baseline — harusnya gagal kalau jauh)
testMethod("fireproximityprompt (baseline)", function(fruit, pp)
    fireproximityprompt(pp)
end)

task.wait(0.5)

-- METHOD 2: firetouchinterest — simulasi touch Part
testMethod("firetouchinterest", function(fruit, pp)
    local ppPart = pp.Parent
    if ppPart and ppPart:IsA("BasePart") then
        -- touch part buah dengan HRP
        firetouchinterest(hrp, ppPart, 0)  -- 0 = touch begin
        task.wait(0.1)
        firetouchinterest(hrp, ppPart, 1)  -- 1 = touch end
    end
end)

task.wait(0.5)

-- METHOD 3: sethiddenproperty MaxActivationDistance jadi sangat besar dulu
testMethod("sethiddenproperty MaxActivationDistance", function(fruit, pp)
    -- set MaxActivationDistance ke 9999 dulu, lalu fire
    local ok2 = pcall(sethiddenproperty, pp, "MaxActivationDistance", 9999)
    print("  sethiddenproperty ok="..tostring(ok2))
    fireproximityprompt(pp)
end)

task.wait(0.5)

-- METHOD 4: InputHoldBegin/End langsung
testMethod("InputHoldBegin/End", function(fruit, pp)
    pp:InputHoldBegin()
    task.wait(0.3)
    pp:InputHoldEnd()
end)

task.wait(0.5)

-- METHOD 5: HarvestRemote:InvokeServer dengan fruit object
testMethod("HarvestRemote:InvokeServer(fruit)", function(fruit, pp)
    local RS = game:GetService("ReplicatedStorage")
    local gameEvents = RS:WaitForChild("GameEvents", 5)
    local hr = gameEvents:FindFirstChild("HarvestRemote")
    if hr then
        hr:InvokeServer(fruit)
    end
end)

task.wait(0.5)

-- METHOD 6: HarvestRemote:InvokeServer dengan FruitSpawnIndex
testMethod("HarvestRemote:InvokeServer(id)", function(fruit, pp)
    local RS = game:GetService("ReplicatedStorage")
    local gameEvents = RS:WaitForChild("GameEvents", 5)
    local hr = gameEvents:FindFirstChild("HarvestRemote")
    if hr then
        local id = fruit:GetAttribute("FruitSpawnIndex") or fruit:GetAttribute("Id") or 1
        hr:InvokeServer(id)
    end
end)

print("=== Semua test selesai ===")
