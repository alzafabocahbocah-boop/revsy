-- debug_collect.lua — test HarvestRemote argumen satu per satu
-- Jalankan di executor, pantau output console

local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer
local gameEvents = RS:WaitForChild("GameEvents", 10)
local harvestRE = gameEvents:FindFirstChild("HarvestRemote")

local function log(msg) print("[DBG] " .. tostring(msg)) end

local function getOneFruit()
    local farm
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name == "Farm" then
            for _, f in ipairs(v:GetChildren()) do
                if f.Name == "Farm" then farm = f; break end
            end
        end
    end
    if not farm then log("farm nil"); return nil end
    local plants = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plants then log("plants nil"); return nil end
    for _, pt in ipairs(plants:GetChildren()) do
        local fruits = pt:FindFirstChild("Fruits")
        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                for k, v in pairs(fruit:GetAttributes()) do
                    local skip = {Nightmare=true,IsOutlined=true,FruitSpawnIndex=true,
                        FruitVersion=true,DoneGrowTime=true,WeightMulti=true,MaxAge=true,GrowRateMulti=true}
                    if v == true and not skip[k] then
                        log("Buah test: " .. fruit:GetFullName())
                        log("Mutasi: " .. k)
                        local attrs = {}
                        for ak, av in pairs(fruit:GetAttributes()) do table.insert(attrs, ak.."="..tostring(av)) end
                        log("Attrs: " .. table.concat(attrs, ", "))
                        return fruit
                    end
                end
            end
        end
    end
    log("Tidak ada buah mutasi"); return nil
end

local function countFruits()
    local n = 0
    local farm
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name == "Farm" then
            for _, f in ipairs(v:GetChildren()) do
                if f.Name == "Farm" then farm = f; break end
            end
        end
    end
    if not farm then return 0 end
    local plants = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plants then return 0 end
    for _, pt in ipairs(plants:GetChildren()) do
        local fr = pt:FindFirstChild("Fruits")
        if fr then n = n + #fr:GetChildren() end
    end
    return n
end

if not harvestRE then log("HarvestRemote TIDAK ADA!"); return end
log("HarvestRemote: " .. harvestRE:GetFullName())

local fruit = getOneFruit()
if not fruit then return end

local prompt = nil
for _, v in ipairs(fruit:GetDescendants()) do
    if v:IsA("ProximityPrompt") then prompt = v; break end
end
log("Prompt: " .. (prompt and prompt:GetFullName() or "NIL"))

local before = countFruits()
log("Buah sebelum: " .. before)

-- TEST 1: FireServer(fruit)
log("=== TEST 1: FireServer(fruit) ===")
local ok, err = pcall(function() harvestRE:FireServer(fruit) end)
log("ok="..tostring(ok).." err="..tostring(err))
task.wait(1.5)
local a1 = countFruits()
log("Setelah: "..a1.." | berkurang: "..(before-a1))

task.wait(1)

-- TEST 2: FireServer(prompt)
if prompt then
    log("=== TEST 2: FireServer(prompt) ===")
    local b2 = countFruits()
    local ok2, err2 = pcall(function() harvestRE:FireServer(prompt) end)
    log("ok="..tostring(ok2).." err="..tostring(err2))
    task.wait(1.5)
    local a2 = countFruits()
    log("Setelah: "..a2.." | berkurang: "..(b2-a2))
    task.wait(1)
end

-- TEST 3: FireServer() kosong
log("=== TEST 3: FireServer() kosong ===")
local b3 = countFruits()
local ok3, err3 = pcall(function() harvestRE:FireServer() end)
log("ok="..tostring(ok3).." err="..tostring(err3))
task.wait(1.5)
local a3 = countFruits()
log("Setelah: "..a3.." | berkurang: "..(b3-a3))

task.wait(1)

-- TEST 4: InputHoldBegin/End
if prompt then
    log("=== TEST 4: InputHoldBegin/End ===")
    local b4 = countFruits()
    local ok4, err4 = pcall(function()
        prompt:InputHoldBegin(); task.wait(0.1); prompt:InputHoldEnd()
    end)
    log("ok="..tostring(ok4).." err="..tostring(err4))
    task.wait(1.5)
    local a4 = countFruits()
    log("Setelah: "..a4.." | berkurang: "..(b4-a4))
end

log("=== SELESAI ===")
