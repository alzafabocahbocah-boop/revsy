-- debug_pp.lua — GUI debug PP collect (no F9 needed)
local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local playerGui = plr:WaitForChild("PlayerGui", 10)

-- destroy old
pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxDebugPP"); if old then old:Destroy() end
    local old2 = playerGui:FindFirstChild("ZenxDebugPP"); if old2 then old2:Destroy() end
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ZenxDebugPP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 540, 0, 420)
main.Position = UDim2.new(0.5, -270, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local ms = Instance.new("UIStroke", main)
ms.Color = Color3.fromRGB(40, 40, 40); ms.Thickness = 1.5

-- title bar
local bar = Instance.new("Frame", main)
bar.Size = UDim2.new(1, 0, 0, 38)
bar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
Instance.new("Frame", bar).Size = UDim2.new(1, 0, 0, 10)
bar:FindFirstChildOfClass("Frame").Position = UDim2.new(0, 0, 1, -10)
bar:FindFirstChildOfClass("Frame").BackgroundColor3 = Color3.fromRGB(14, 14, 14)
bar:FindFirstChildOfClass("Frame").BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel", bar)
titleLbl.Size = UDim2.new(1, -50, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🔍 DEBUG PP COLLECT"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextColor3 = Color3.fromRGB(78, 214, 204)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", bar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 25)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(220, 100, 110)
closeBtn.AutoButtonColor = true
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- drag
do
    local drag, ds, sp
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = main.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

-- log area
local logFrame = Instance.new("ScrollingFrame", main)
logFrame.Size = UDim2.new(1, -16, 1, -120)
logFrame.Position = UDim2.new(0, 8, 0, 46)
logFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 4
logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 6)
local ls = Instance.new("UIStroke", logFrame)
ls.Color = Color3.fromRGB(30, 30, 30); ls.Thickness = 1

local logLayout = Instance.new("UIListLayout", logFrame)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 1)
local lpad = Instance.new("UIPadding", logFrame)
lpad.PaddingLeft = UDim.new(0, 6); lpad.PaddingRight = UDim.new(0, 6)
lpad.PaddingTop = UDim.new(0, 4); lpad.PaddingBottom = UDim.new(0, 4)

local logLines = {}
local logOrder = 0

local function addLine(text, col)
    logOrder = logOrder + 1
    local lbl = Instance.new("TextLabel", logFrame)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextColor3 = col or Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.LayoutOrder = logOrder
    table.insert(logLines, text)
    -- auto scroll
    task.defer(function()
        logFrame.CanvasPosition = Vector2.new(0, math.max(0, logFrame.AbsoluteCanvasSize.Y - logFrame.AbsoluteSize.Y))
    end)
end

local function log(text, col) addLine(text, col) end
local function logOk(t) log("✅ "..t, Color3.fromRGB(100, 220, 140)) end
local function logErr(t) log("❌ "..t, Color3.fromRGB(220, 100, 100)) end
local function logInfo(t) log("ℹ "..t, Color3.fromRGB(180, 180, 100)) end

-- bottom buttons
local btnArea = Instance.new("Frame", main)
btnArea.Size = UDim2.new(1, -16, 0, 66)
btnArea.Position = UDim2.new(0, 8, 1, -74)
btnArea.BackgroundTransparency = 1

local function mkBtn(txt, x, col)
    local b = Instance.new("TextButton", btnArea)
    b.Size = UDim2.new(0, 120, 0, 28)
    b.Position = UDim2.new(0, x, 0, 4)
    b.BackgroundColor3 = col or Color3.fromRGB(25, 25, 25)
    b.Text = txt
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(220, 220, 220)
    b.AutoButtonColor = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke", b)
    bs.Color = Color3.fromRGB(50, 50, 50); bs.Thickness = 1
    return b
end

local btnScan    = mkBtn("🔍 SCAN INFO", 0,   Color3.fromRGB(20, 40, 60))
local btnTest    = mkBtn("▶ TEST COLLECT", 130, Color3.fromRGB(20, 50, 30))
local btnAuto    = mkBtn("⚡ AUTO COLLECT", 260, Color3.fromRGB(50, 30, 10))
local btnCopy    = mkBtn("📋 COPY LOG", 390,  Color3.fromRGB(30, 20, 50))

local btnStop = Instance.new("TextButton", btnArea)
btnStop.Size = UDim2.new(1, 0, 0, 24)
btnStop.Position = UDim2.new(0, 0, 0, 38)
btnStop.BackgroundColor3 = Color3.fromRGB(50, 15, 15)
btnStop.Text = "⛔ STOP AUTO"
btnStop.Font = Enum.Font.GothamBold
btnStop.TextSize = 11
btnStop.TextColor3 = Color3.fromRGB(220, 100, 100)
btnStop.AutoButtonColor = true
Instance.new("UICorner", btnStop).CornerRadius = UDim.new(0, 6)

-- ===== HELPERS =====
local function getPlayerFarm()
    local farm = workspace:FindFirstChild("Farm"); if not farm then return nil end
    return farm:FindFirstChild(plr.Name) or farm:FindFirstChild("Farm")
end

local function getFruitPrompt(fruit)
    local part = fruit:FindFirstChild("2")
    if part then
        local pp = part:FindFirstChildOfClass("ProximityPrompt")
        if pp then return pp end
    end
    for _, v in ipairs(fruit:GetDescendants()) do
        if v:IsA("ProximityPrompt") then return v end
    end
    return nil
end

local function getAllFruits(mutasiOnly)
    local out = {}
    pcall(function()
        local farm = getPlayerFarm(); if not farm then return end
        local imp = farm:FindFirstChild("Important"); if not imp then return end
        local plants = imp:FindFirstChild("Plants_Physical"); if not plants then return end
        for _,pt in ipairs(plants:GetChildren()) do
            local fruits = pt:FindFirstChild("Fruits"); if fruits then
                for _,fruit in ipairs(fruits:GetChildren()) do
                    if mutasiOnly then
                        local mut = fruit:GetAttribute("Mutations") or fruit:GetAttribute("mutation_count") or 0
                        if tonumber(mut) and tonumber(mut) > 0 then
                            out[#out+1] = fruit
                        end
                    else
                        out[#out+1] = fruit
                    end
                end
            end
        end
    end)
    return out
end

-- ===== SCAN INFO =====
btnScan.MouseButton1Click:Connect(function()
    log("─────────── SCAN ───────────", Color3.fromRGB(78, 214, 204))
    local char = plr.Character; if not char then logErr("no char"); return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then logErr("no HRP"); return end

    local fruits = getAllFruits(false)
    logInfo("Total buah di farm: "..#fruits)

    local mutasi = getAllFruits(true)
    logInfo("Buah MUTASI: "..#mutasi)

    if #fruits == 0 then logErr("Farm kosong / path salah"); return end

    -- info buah pertama (mutasi prioritas, kalau ga ada ambil pertama)
    local target = mutasi[1] or fruits[1]
    log("Target: "..target.Name, Color3.fromRGB(200, 200, 100))

    -- atribut
    for k,v in pairs(target:GetAttributes()) do
        log("  "..k.."="..tostring(v), Color3.fromRGB(150, 150, 150))
    end

    -- PP info
    local pp = getFruitPrompt(target)
    if pp then
        logOk("PP: "..pp:GetFullName())
        log("  ActionText: "..pp.ActionText)
        log("  MaxActivationDistance: "..pp.MaxActivationDistance)
        log("  RequiresLineOfSight: "..tostring(pp.RequiresLineOfSight))
        log("  Enabled: "..tostring(pp.Enabled))
        local ppPart = pp.Parent
        if ppPart and ppPart:IsA("BasePart") then
            local dist = (hrp.Position - ppPart.Position).Magnitude
            local distStr = math.floor(dist).." studs"
            local distCol = dist > pp.MaxActivationDistance
                and Color3.fromRGB(220, 100, 100)
                or Color3.fromRGB(100, 220, 140)
            log("  JARAK dari char: "..distStr, distCol)
            if dist > pp.MaxActivationDistance then
                logErr("Terlalu jauh! ("..distStr.." > "..pp.MaxActivationDistance..")")
            else
                logOk("Dalam jangkauan!")
            end
        end
    else
        logErr("PP tidak ditemukan di buah!")
    end
end)

-- ===== TEST COLLECT (1 buah) =====
btnTest.MouseButton1Click:Connect(function()
    log("─────── TEST COLLECT ────────", Color3.fromRGB(78, 214, 204))
    local fruits = getAllFruits(true)
    if #fruits == 0 then
        fruits = getAllFruits(false)
        if #fruits == 0 then logErr("Tidak ada buah!"); return end
        logInfo("Tidak ada mutasi, pakai buah biasa")
    end

    local fruit = fruits[1]
    log("Fruit: "..fruit.Name.." ("..#fruits.." total)")
    local pp = getFruitPrompt(fruit)
    if not pp then logErr("PP tidak ada!"); return end

    pcall(function() pp.RequiresLineOfSight = false end)
    log("fire PP: "..pp:GetFullName())
    local ok, err = pcall(fireproximityprompt, pp)
    log("fireproximityprompt ok="..tostring(ok))
    if not ok then logErr("err: "..tostring(err)) end

    task.wait(1)
    if fruit.Parent then
        logErr("GAGAL — buah masih ada setelah 1s")
    else
        logOk("SUKSES — buah hilang!")
    end
end)

-- ===== AUTO COLLECT =====
local autoRunning = false
local autoStop = false

btnAuto.MouseButton1Click:Connect(function()
    if autoRunning then logErr("Auto sedang jalan, tekan STOP dulu"); return end
    autoStop = false
    autoRunning = true
    log("─────── AUTO COLLECT ────────", Color3.fromRGB(78, 214, 204))
    task.spawn(function()
        local total = 0
        while not autoStop do
            local fruits = getAllFruits(true)
            if #fruits == 0 then
                logInfo("Tidak ada mutasi — selesai")
                break
            end
            log("Batch: "..#fruits.." mutasi")
            local batch = 0
            for i, fruit in ipairs(fruits) do
                if autoStop then break end
                local pp = getFruitPrompt(fruit)
                if pp then
                    pcall(function() pp.RequiresLineOfSight = false end)
                    local ok = pcall(fireproximityprompt, pp)
                    if ok then batch = batch + 1; total = total + 1 end
                end
                task.wait(0.08)
                if i % 50 == 0 then
                    log("batch "..i.." — "..batch.." OK, pause 2s")
                    task.wait(2)
                end
            end
            log("Batch selesai: "..batch.." collect | total: "..total)
            task.wait(0.5)
            -- scan lagi
            local next = getAllFruits(true)
            if #next == 0 then
                logOk("Semua mutasi habis! Total: "..total)
                break
            end
        end
        autoRunning = false
        log("Auto collect berhenti. Total: "..total)
    end)
end)

btnStop.MouseButton1Click:Connect(function()
    autoStop = true
    log("STOP diminta...", Color3.fromRGB(220, 160, 60))
end)

-- ===== COPY LOG =====
btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    if setclipboard then
        setclipboard(txt)
        log("✅ Log disalin ke clipboard!", Color3.fromRGB(100, 220, 140))
    elseif toclipboard then
        toclipboard(txt)
        log("✅ Log disalin!", Color3.fromRGB(100, 220, 140))
    else
        log("⚠ setclipboard tidak tersedia", Color3.fromRGB(220, 160, 60))
    end
end)

log("Debug PP siap — tekan SCAN INFO dulu", Color3.fromRGB(78, 214, 204))
