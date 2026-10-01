-- test_crops_mutasi.lua
-- Test Crops.Collect:FireServer(tbl) hanya untuk buah BERMUTASI
-- Jalankan dari jarak jauh, lihat buah mutasi hilang atau tidak

local plr = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local playerGui = plr:WaitForChild("PlayerGui", 10)

pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxCropsMutasi"); if old then old:Destroy() end
    local old2 = playerGui:FindFirstChild("ZenxCropsMutasi"); if old2 then old2:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ZenxCropsMutasi"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 460, 0, 400)
main.Position = UDim2.new(0.5, -230, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(8,8,8)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(40,40,40)

local bar = Instance.new("Frame", main)
bar.Size = UDim2.new(1,0,0,34)
bar.BackgroundColor3 = Color3.fromRGB(14,14,14)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0,10)
local bfix = Instance.new("Frame", bar)
bfix.Size = UDim2.new(1,0,0,10); bfix.Position = UDim2.new(0,0,1,-10)
bfix.BackgroundColor3 = Color3.fromRGB(14,14,14); bfix.BorderSizePixel = 0

local title = Instance.new("TextLabel", bar)
title.Size = UDim2.new(1,-40,1,0); title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1; title.Text = "🌿 TEST Crops.Collect — MUTASI ONLY"
title.Font = Enum.Font.GothamBold; title.TextSize = 12
title.TextColor3 = Color3.fromRGB(100,255,150); title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", bar)
closeBtn.Size = UDim2.new(0,26,0,26); closeBtn.Position = UDim2.new(1,-32,0.5,-13)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,20,25); closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.fromRGB(220,100,110); closeBtn.AutoButtonColor = true
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
logFrame.Size = UDim2.new(1,-16,1,-80); logFrame.Position = UDim2.new(0,8,0,42)
logFrame.BackgroundColor3 = Color3.fromRGB(4,4,4); logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 4; logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logFrame.CanvasSize = UDim2.new(0,0,0,0)
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0,6)
local ll = Instance.new("UIListLayout", logFrame)
ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,1)
local lp = Instance.new("UIPadding", logFrame)
lp.PaddingLeft = UDim.new(0,6); lp.PaddingRight = UDim.new(0,6)
lp.PaddingTop = UDim.new(0,4); lp.PaddingBottom = UDim.new(0,4)

local logLines = {}; local logOrder = 0
local function addLine(t, col)
    logOrder += 1
    local lbl = Instance.new("TextLabel", logFrame)
    lbl.Size = UDim2.new(1,0,0,14); lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1; lbl.Text = t; lbl.Font = Enum.Font.Code
    lbl.TextSize = 11; lbl.TextColor3 = col or Color3.fromRGB(200,200,200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.LayoutOrder = logOrder
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
btnArea.Size = UDim2.new(1,-16,0,30); btnArea.Position = UDim2.new(0,8,1,-38)
btnArea.BackgroundTransparency = 1

local function mkBtn(txt, x, w, col)
    local b = Instance.new("TextButton", btnArea)
    b.Size = UDim2.new(0,w,0,26); b.Position = UDim2.new(0,x,0,2)
    b.BackgroundColor3 = col or Color3.fromRGB(20,20,20)
    b.Text = txt; b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11; b.TextColor3 = Color3.fromRGB(220,220,220); b.AutoButtonColor = true
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local btnScan  = mkBtn("🔍 SCAN MUTASI", 0,   130, Color3.fromRGB(20,40,60))
local btnRun   = mkBtn("▶ COLLECT",      138, 100, Color3.fromRGB(20,60,20))
local btnCopy  = mkBtn("📋 COPY",        246, 70,  Color3.fromRGB(30,20,50))
local btnClear = mkBtn("🗑",             324, 36)

-- ===== SETUP =====
local cropsRE = RS:WaitForChild("GameEvents",5)
if cropsRE then cropsRE = cropsRE:WaitForChild("Crops",5) end
if cropsRE then cropsRE = cropsRE:WaitForChild("Collect",5) end

-- mutasi = Variant != "Normal"

local function isMutasi(f)
    local v = f:FindFirstChild("Variant")
    if v and v:IsA("StringValue") then
        if v.Value ~= "Normal" and v.Value ~= "" then
            return true, v.Value
        end
    end
    return false
end

local function getPlayerFarm()
    local farm = workspace:FindFirstChild("Farm"); if not farm then return nil end
    return farm:FindFirstChild(plr.Name) or farm:FindFirstChild("Farm")
end

local scannedFruits = {}

local function scanMutasi()
    scannedFruits = {}
    local farm = getPlayerFarm()
    if not farm then logErr("Farm tidak ditemukan!"); return end
    local plants = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plants then logErr("Plants_Physical tidak ditemukan!"); return end

    local total = 0; local mutasiCount = 0
    for _, pt in ipairs(plants:GetChildren()) do
        local fruits = pt:FindFirstChild("Fruits")
        if fruits then
            for _, f in ipairs(fruits:GetChildren()) do
                total += 1
                local ok, mut = isMutasi(f)
                if ok then
                    mutasiCount += 1
                    table.insert(scannedFruits, f)
                end
            end
        end
    end
    logInfo("Scan: "..total.." buah total, "..mutasiCount.." bermutasi")
    if mutasiCount > 0 then
        -- tampilkan 10 pertama
        local preview = {}
        for i = 1, math.min(10, #scannedFruits) do
            table.insert(preview, scannedFruits[i].Name)
        end
        log("  Contoh: "..table.concat(preview, ", "), Color3.fromRGB(150,220,255))
        if #scannedFruits > 10 then
            log("  ...dan "..(#scannedFruits-10).." lagi", Color3.fromRGB(120,120,120))
        end
    end
    return mutasiCount
end

local running = false

btnScan.MouseButton1Click:Connect(function()
    log("── SCAN MUTASI ──", Color3.fromRGB(200,200,100))
    scanMutasi()
end)

btnRun.MouseButton1Click:Connect(function()
    if running then log("Masih jalan..."); return end
    if not cropsRE then logErr("Crops.Collect RE tidak ada!"); return end
    if #scannedFruits == 0 then
        logInfo("Scan dulu...")
        scanMutasi()
    end
    if #scannedFruits == 0 then logErr("Tidak ada buah mutasi!"); return end

    running = true
    local sebelum = #scannedFruits
    logInfo("Collect "..sebelum.." buah mutasi via Crops.Collect...")

    task.spawn(function()
        -- filter yang masih ada
        local valid = {}
        for _, f in ipairs(scannedFruits) do
            if f and f.Parent then table.insert(valid, f) end
        end
        log("  Valid (masih ada): "..#valid, Color3.fromRGB(180,180,80))

        -- kirim semua sekaligus
        local ok, err = pcall(function() cropsRE:FireServer(valid) end)
        if ok then
            logOk("FireServer("..#valid.." buah) OK!")
        else
            logErr("FireServer error: "..tostring(err))
        end

        task.wait(2)

        -- cek berapa yang hilang
        local hilang = 0
        for _, f in ipairs(valid) do
            if f.Parent == nil then hilang += 1 end
        end
        local masih = #valid - hilang

        if hilang > 0 then
            logOk(hilang.." buah hilang dari "..#valid.." ✓")
        end
        if masih > 0 then
            log("  "..masih.." masih ada", Color3.fromRGB(220,100,100))
        end

        -- update list
        scannedFruits = {}
        for _, f in ipairs(valid) do
            if f.Parent ~= nil then table.insert(scannedFruits, f) end
        end

        running = false
    end)
end)

btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    local saved = false
    pcall(function() if writefile then writefile("mutasi_test.txt", txt); saved = true end end)
    local clipped = false
    pcall(function()
        if setclipboard then setclipboard(txt); clipped = true
        elseif toclipboard then toclipboard(txt); clipped = true end
    end)
    if saved then logOk("Saved: mutasi_test.txt") end
    if clipped then logOk("Clipboard ok!") end
end)

btnClear.MouseButton1Click:Connect(function()
    for _,v in ipairs(logFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logLines = {}; logOrder = 0; scannedFruits = {}
end)

-- init
if cropsRE then
    logOk("RE: "..cropsRE:GetFullName())
else
    logErr("Crops.Collect tidak ditemukan!")
end
log("1. Tekan 🔍 SCAN MUTASI — lihat berapa mutasi ada", Color3.fromRGB(78,214,204))
log("2. Tekan ▶ COLLECT dari jarak jauh", Color3.fromRGB(78,214,204))
