-- test_crops_collect.lua
-- Test ReplicatedStorage.GameEvents.Crops.Collect dengan berbagai argumen
-- Jalankan dari JAUH (>30 studs dari buah)

local plr = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local playerGui = plr:WaitForChild("PlayerGui", 10)

-- cleanup
pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxCropsTest"); if old then old:Destroy() end
    local old2 = playerGui:FindFirstChild("ZenxCropsTest"); if old2 then old2:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ZenxCropsTest"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 480, 0, 440)
main.Position = UDim2.new(0.5, -240, 0.5, -220)
main.BackgroundColor3 = Color3.fromRGB(8,8,8)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local ms = Instance.new("UIStroke", main)
ms.Color = Color3.fromRGB(40,40,40); ms.Thickness = 1.5

local bar = Instance.new("Frame", main)
bar.Size = UDim2.new(1,0,0,34)
bar.BackgroundColor3 = Color3.fromRGB(14,14,14)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0,10)
local bfix = Instance.new("Frame", bar)
bfix.Size = UDim2.new(1,0,0,10)
bfix.Position = UDim2.new(0,0,1,-10)
bfix.BackgroundColor3 = Color3.fromRGB(14,14,14)
bfix.BorderSizePixel = 0

local title = Instance.new("TextLabel", bar)
title.Size = UDim2.new(1,-40,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "🌾 TEST Crops.Collect"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(100,255,100)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", bar)
closeBtn.Size = UDim2.new(0,26,0,26)
closeBtn.Position = UDim2.new(1,-32,0.5,-13)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,20,25)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13; closeBtn.TextColor3 = Color3.fromRGB(220,100,110)
closeBtn.AutoButtonColor = true
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

do
    local drag, ds, sp
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=main.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

local logFrame = Instance.new("ScrollingFrame", main)
logFrame.Size = UDim2.new(1,-16,1,-80)
logFrame.Position = UDim2.new(0,8,0,42)
logFrame.BackgroundColor3 = Color3.fromRGB(4,4,4)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 4
logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logFrame.CanvasSize = UDim2.new(0,0,0,0)
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0,6)
local ll = Instance.new("UIListLayout", logFrame)
ll.SortOrder = Enum.SortOrder.LayoutOrder
ll.Padding = UDim.new(0,1)
local lp = Instance.new("UIPadding", logFrame)
lp.PaddingLeft = UDim.new(0,6); lp.PaddingRight = UDim.new(0,6)
lp.PaddingTop = UDim.new(0,4); lp.PaddingBottom = UDim.new(0,4)

local logLines = {}
local logOrder = 0
local function addLine(t, col)
    logOrder += 1
    local lbl = Instance.new("TextLabel", logFrame)
    lbl.Size = UDim2.new(1,0,0,14)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = t; lbl.Font = Enum.Font.Code
    lbl.TextSize = 11; lbl.TextColor3 = col or Color3.fromRGB(200,200,200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true; lbl.LayoutOrder = logOrder
    table.insert(logLines, t)
    task.defer(function()
        logFrame.CanvasPosition = Vector2.new(0, math.max(0, logFrame.AbsoluteCanvasSize.Y - logFrame.AbsoluteSize.Y))
    end)
end
local function log(t,c) addLine(t,c) end
local function logOk(t) log("✅ "..t, Color3.fromRGB(100,220,140)) end
local function logErr(t) log("❌ "..t, Color3.fromRGB(220,100,100)) end
local function logInfo(t) log("ℹ "..t, Color3.fromRGB(255,200,60)) end

local btnArea = Instance.new("Frame", main)
btnArea.Size = UDim2.new(1,-16,0,30)
btnArea.Position = UDim2.new(0,8,1,-38)
btnArea.BackgroundTransparency = 1

local function mkBtn(txt, x, w, col)
    local b = Instance.new("TextButton", btnArea)
    b.Size = UDim2.new(0,w,0,26)
    b.Position = UDim2.new(0,x,0,2)
    b.BackgroundColor3 = col or Color3.fromRGB(20,20,20)
    b.Text = txt; b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11; b.TextColor3 = Color3.fromRGB(220,220,220)
    b.AutoButtonColor = true
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local btnRun  = mkBtn("▶ RUN TESTS", 0, 130, Color3.fromRGB(20,60,20))
local btnOne  = mkBtn("1 BUAH AJA", 138, 110, Color3.fromRGB(40,30,10))
local btnCopy = mkBtn("📋 COPY", 256, 70, Color3.fromRGB(30,20,50))
local btnClear= mkBtn("🗑", 334, 36)

-- ===== HELPERS =====
local CropsCollect = RS:WaitForChild("GameEvents", 5)
if CropsCollect then CropsCollect = CropsCollect:WaitForChild("Crops", 5) end
if CropsCollect then CropsCollect = CropsCollect:WaitForChild("Collect", 5) end

local function getPlayerFarm()
    local farm = workspace:FindFirstChild("Farm"); if not farm then return nil end
    return farm:FindFirstChild(plr.Name) or farm:FindFirstChild("Farm")
end

local function getAllFruits()
    local results = {}
    pcall(function()
        local farm = getPlayerFarm()
        local plants = farm:FindFirstChild("Important"):FindFirstChild("Plants_Physical")
        for _, pt in ipairs(plants:GetChildren()) do
            local fruits = pt:FindFirstChild("Fruits")
            if fruits then
                for _, f in ipairs(fruits:GetChildren()) do
                    table.insert(results, {fruit=f, plant=pt})
                end
            end
        end
    end)
    return results
end

local function getFirstFruit()
    local all = getAllFruits()
    if #all > 0 then return all[1].fruit, all[1].plant end
    return nil, nil
end

local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- ===== TESTS =====
-- Crops.Collect RE — coba argumen yang paling masuk akal untuk harvest mechanic
local tests = {
    {name="Crops.Collect(fruit)", fn=function(fruit, plant)
        CropsCollect:FireServer(fruit)
        return true
    end},
    {name="Crops.Collect(plant)", fn=function(fruit, plant)
        CropsCollect:FireServer(plant)
        return true
    end},
    {name="Crops.Collect(fruit, plant)", fn=function(fruit, plant)
        CropsCollect:FireServer(fruit, plant)
        return true
    end},
    {name="Crops.Collect(fruit.Name)", fn=function(fruit, plant)
        CropsCollect:FireServer(fruit.Name)
        return true
    end},
    {name="Crops.Collect(plant.Name)", fn=function(fruit, plant)
        CropsCollect:FireServer(plant.Name)
        return true
    end},
    {name="Crops.Collect(fruit, 1)", fn=function(fruit, plant)
        CropsCollect:FireServer(fruit, 1)
        return true
    end},
    {name="Crops.Collect(plant, fruit)", fn=function(fruit, plant)
        CropsCollect:FireServer(plant, fruit)
        return true
    end},
    {name="Crops.Collect(fruit, true)", fn=function(fruit, plant)
        CropsCollect:FireServer(fruit, true)
        return true
    end},
    {name="Crops.Collect()", fn=function(fruit, plant)
        CropsCollect:FireServer()
        return true
    end},
    -- coba collect ALL fruits sekaligus (kirim semua)
    {name="Crops.Collect(allFruits table)", fn=function(fruit, plant)
        local all = getAllFruits()
        local tbl = {}
        for _, v in ipairs(all) do table.insert(tbl, v.fruit) end
        CropsCollect:FireServer(tbl)
        return true
    end},
}

local running = false

btnRun.MouseButton1Click:Connect(function()
    if running then log("Masih jalan..."); return end
    if not CropsCollect then
        logErr("Crops.Collect tidak ditemukan di RS!")
        return
    end
    running = true
    logInfo("═══ MULAI TEST Crops.Collect ═══")
    logInfo("RE path: "..CropsCollect:GetFullName())

    task.spawn(function()
        for _, t in ipairs(tests) do
            local fruit, plant = getFirstFruit()
            if not fruit then
                logErr("Tidak ada buah lagi! Stop.")
                break
            end

            local dist = 999
            pcall(function()
                for _, v in ipairs(fruit:GetDescendants()) do
                    if v:IsA("BasePart") then
                        dist = math.floor((hrp.Position - v.Position).Magnitude)
                        break
                    end
                end
            end)

            log("── "..t.name.." (jarak ~"..dist.."s) ──", Color3.fromRGB(200,200,100))

            local ok, err = pcall(t.fn, fruit, plant)
            if not ok then logErr("pcall: "..tostring(err)) end

            task.wait(2)

            if fruit.Parent == nil then
                logOk("🎯 SUKSES! → "..t.name)
                log("⭐⭐ METHOD: Crops.Collect dengan arg: "..t.name, Color3.fromRGB(100,255,100))
                running = false
                return
            else
                log("  GAGAL — buah masih ada", Color3.fromRGB(180,80,80))
            end

            task.wait(0.5)
        end

        log("═══ Semua test selesai ═══", Color3.fromRGB(180,180,180))
        running = false
    end)
end)

-- test 1 buah dengan argumen paling probable
btnOne.MouseButton1Click:Connect(function()
    if running then return end
    if not CropsCollect then logErr("RE tidak ada!"); return end

    local fruit, plant = getFirstFruit()
    if not fruit then logErr("Tidak ada buah!"); return end

    logInfo("Test cepat — Crops.Collect(fruit) pada: "..fruit:GetFullName())
    local ok, err = pcall(function() CropsCollect:FireServer(fruit) end)
    log("  FireServer ok="..tostring(ok).." err="..tostring(err and err or "nil"))
    task.wait(1.5)
    if fruit.Parent == nil then
        logOk("SUKSES dengan Crops.Collect(fruit)!")
    else
        log("  Buah masih ada. Coba RUN TESTS untuk semua variasi.", Color3.fromRGB(180,100,100))
    end
end)

btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    local saved = false
    pcall(function()
        if writefile then writefile("crops_collect_test.txt", txt); saved = true end
    end)
    local clipped = false
    pcall(function()
        if setclipboard then setclipboard(txt); clipped = true
        elseif toclipboard then toclipboard(txt); clipped = true end
    end)
    if saved then logOk("Saved: crops_collect_test.txt") end
    if clipped then logOk("Clipboard ok!") end
    if not saved and not clipped then logErr("Copy gagal, scroll manual") end
end)

btnClear.MouseButton1Click:Connect(function()
    for _,v in ipairs(logFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logLines = {}; logOrder = 0
end)

-- info awal
if CropsCollect then
    logOk("RE ditemukan: "..CropsCollect:GetFullName())
else
    logErr("ReplicatedStorage.GameEvents.Crops.Collect TIDAK ADA!")
end
log("Pastikan karakter JAUH dari buah (>30 studs)", Color3.fromRGB(255,180,60))
log("Tekan ▶ RUN TESTS atau 1 BUAH AJA untuk test cepat", Color3.fromRGB(78,214,204))
