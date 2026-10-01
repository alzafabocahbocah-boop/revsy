-- test_harvest_remotes.lua — test semua RE/RF yang namanya mengandung kata harvest/collect
-- jalankan dari JARAK JAUH (>30 studs dari buah), lihat mana yang bikin buah hilang

local plr = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local UIS = game:GetService("UserInputService")
local playerGui = plr:WaitForChild("PlayerGui", 10)

pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxHTest"); if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ZenxHTest"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 480, 0, 400)
main.Position = UDim2.new(0.5, -240, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(8,8,8)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

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
title.Text = "🧪 TEST HARVEST REMOTES"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(255,180,60)
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

-- drag
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
local function logInfo(t) log("ℹ "..t, Color3.fromRGB(180,180,80)) end

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

local btnRun  = mkBtn("▶ RUN ALL TESTS", 0,   150, Color3.fromRGB(20,50,20))
local btnCopy = mkBtn("📋 COPY", 158, 80, Color3.fromRGB(30,20,50))
local btnClear= mkBtn("🗑 CLEAR", 246, 80)

-- ===== HELPERS =====
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
    local p2 = fruit:FindFirstChild("2")
    if p2 then
        local pp = p2:FindFirstChildOfClass("ProximityPrompt")
        if pp then return pp end
    end
    for _, v in ipairs(fruit:GetDescendants()) do
        if v:IsA("ProximityPrompt") then return v end
    end
end

-- find RE/RF by name anywhere in RS
local function findRemote(name)
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

-- ===== TESTS =====
local tests = {
    -- format: {name, fn}

    -- Test A: TryHarvestBasket (RE) dengan fruit object
    {name="TryHarvestBasket(fruit)", fn=function(fruit, pp)
        local re = findRemote("TryHarvestBasket")
        if not re then return false, "tidak ditemukan" end
        re:FireServer(fruit)
        return true
    end},

    -- Test B: TryHarvestBasket dengan fruit + jumlah
    {name="TryHarvestBasket(fruit,1)", fn=function(fruit, pp)
        local re = findRemote("TryHarvestBasket")
        if not re then return false, "tidak ditemukan" end
        re:FireServer(fruit, 1)
        return true
    end},

    -- Test C: TryHarvestBasket tanpa argumen
    {name="TryHarvestBasket()", fn=function(fruit, pp)
        local re = findRemote("TryHarvestBasket")
        if not re then return false, "tidak ditemukan" end
        re:FireServer()
        return true
    end},

    -- Test D: CollectAllAnimation
    {name="CollectAllAnimation(fruit)", fn=function(fruit, pp)
        local re = findRemote("CollectAllAnimation")
        if not re then return false, "tidak ditemukan" end
        re:FireServer(fruit)
        return true
    end},

    -- Test E: HarvestStaffRemoteEvent
    {name="HarvestStaffRemoteEvent(fruit)", fn=function(fruit, pp)
        local re = findRemote("HarvestStaffRemoteEvent")
        if not re then return false, "tidak ditemukan" end
        re:FireServer(fruit)
        return true
    end},

    -- Test F: sethiddenproperty MaxActivationDistance lalu fireproximityprompt
    {name="sethidden(9999)+firepp", fn=function(fruit, pp)
        if not sethiddenproperty then return false, "sethiddenproperty tidak ada" end
        local ok = pcall(sethiddenproperty, pp, "MaxActivationDistance", 9999)
        log("  sethiddenproperty ok="..tostring(ok))
        local ok2, err2 = pcall(fireproximityprompt, pp)
        log("  fireproximityprompt ok="..tostring(ok2).." err="..tostring(err2))
        return true
    end},

    -- Test G: pp.MaxActivationDistance = 9999 (normal property set) lalu fire
    {name="pp.MaxActDist=9999+firepp", fn=function(fruit, pp)
        pcall(function() pp.MaxActivationDistance = 9999 end)
        local ok2 = pcall(fireproximityprompt, pp)
        log("  fireproximityprompt ok="..tostring(ok2))
        return true
    end},

    -- Test H: HarvestRemote:InvokeServer dengan berbagai argumen
    {name="HarvestRemote:InvokeServer(fruit)", fn=function(fruit, pp)
        local rf = findRemote("HarvestRemote")
        if not rf then return false, "tidak ditemukan" end
        local ok, res = pcall(function() return rf:InvokeServer(fruit) end)
        log("  ok="..tostring(ok).." res="..tostring(res))
        return true
    end},

    -- Test I: Water_RE (kadang harvest = water?)
    {name="Water_RE(fruit)", fn=function(fruit, pp)
        local re = findRemote("Water_RE")
        if not re then return false, "tidak ditemukan" end
        re:FireServer(fruit)
        return true
    end},

    -- Test J: Sell_Item
    {name="Sell_Item(fruit)", fn=function(fruit, pp)
        local re = findRemote("Sell_Item")
        if not re then return false, "tidak ditemukan" end
        re:FireServer(fruit)
        return true
    end},
}

local running = false

btnRun.MouseButton1Click:Connect(function()
    if running then log("Masih jalan..."); return end
    running = true
    log("═══ MULAI TEST (jarak jauh) ═══", Color3.fromRGB(255,180,60))

    task.spawn(function()
        for _, t in ipairs(tests) do
            local fruit = getFirstFruit()
            if not fruit then
                logErr("Tidak ada buah lagi! Stop.")
                break
            end
            local pp = getFruitPP(fruit)
            if not pp then
                logErr("Tidak ada PP di buah! Skip: "..t.name)
                task.wait(0.3)
                continue
            end

            -- jarak sekarang
            local ppPart = pp.Parent
            local dist = 0
            if ppPart and ppPart:IsA("BasePart") then
                dist = math.floor((hrp.Position - ppPart.Position).Magnitude)
            end

            log("── "..t.name.." (jarak "..dist.."s) ──", Color3.fromRGB(200,200,100))

            local parentBefore = fruit.Parent
            local ok, err = pcall(t.fn, fruit, pp)
            if not ok then
                logErr("pcall err: "..tostring(err))
            end

            task.wait(1.5)

            if fruit.Parent == nil then
                logOk("SUKSES! Buah hilang → "..t.name)
                log("⭐ METHOD DITEMUKAN: "..t.name, Color3.fromRGB(255,255,60))
                running = false
                return
            else
                log("  GAGAL — buah masih ada", Color3.fromRGB(180,80,80))
            end

            task.wait(0.3)
        end

        log("═══ Semua test selesai ═══", Color3.fromRGB(180,180,180))
        running = false
    end)
end)

btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    if setclipboard then setclipboard(txt)
    elseif toclipboard then toclipboard(txt) end
    logOk("Disalin!")
end)

btnClear.MouseButton1Click:Connect(function()
    for _, v in ipairs(logFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logLines = {}; logOrder = 0
end)

log("Pastikan karakter JAUH dari buah (>30 studs)", Color3.fromRGB(255,180,60))
log("Tekan RUN ALL TESTS", Color3.fromRGB(78,214,204))
