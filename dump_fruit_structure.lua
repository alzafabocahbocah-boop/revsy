-- dump_fruit_structure.lua
-- GUI: tampilkan nama, attributes, dan children dari semua buah di farm
-- Bisa scroll, bisa copy

local plr = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")
local playerGui = plr:WaitForChild("PlayerGui", 10)

pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxDumpFruit"); if old then old:Destroy() end
    local old2 = playerGui:FindFirstChild("ZenxDumpFruit"); if old2 then old2:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ZenxDumpFruit"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 520, 0, 460)
main.Position = UDim2.new(0.5, -260, 0.5, -230)
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
title.BackgroundTransparency = 1; title.Text = "🔬 DUMP FRUIT STRUCTURE"
title.Font = Enum.Font.GothamBold; title.TextSize = 12
title.TextColor3 = Color3.fromRGB(255,200,100); title.TextXAlignment = Enum.TextXAlignment.Left

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
    lbl.TextSize = 10; lbl.TextColor3 = col or Color3.fromRGB(200,200,200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.LayoutOrder = logOrder
    table.insert(logLines, t)
    task.defer(function()
        logFrame.CanvasPosition = Vector2.new(0, math.max(0, logFrame.AbsoluteCanvasSize.Y - logFrame.AbsoluteSize.Y))
    end)
end
local function log(t,c) addLine(t,c) end

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

local btnDump  = mkBtn("🔬 DUMP 30 BUAH", 0,   140, Color3.fromRGB(40,30,10))
local btnAll   = mkBtn("📦 DUMP SEMUA",   148, 120, Color3.fromRGB(20,40,20))
local btnCopy  = mkBtn("📋 COPY",         276, 70,  Color3.fromRGB(30,20,50))
local btnClear = mkBtn("🗑",              354, 36)

local function getPlayerFarm()
    local farm = workspace:FindFirstChild("Farm"); if not farm then return nil end
    return farm:FindFirstChild(plr.Name) or farm:FindFirstChild("Farm")
end

local function dumpFruit(f, idx)
    -- nama
    log("["..idx.."] "..f.Name, Color3.fromRGB(100,200,255))
    -- attributes
    local ok1, attrs = pcall(function() return f:GetAttributes() end)
    if ok1 and attrs then
        local parts = {}
        for k,v in pairs(attrs) do
            table.insert(parts, k.."="..tostring(v))
        end
        if #parts > 0 then
            log("  ATTR: "..table.concat(parts, " | "), Color3.fromRGB(255,180,80))
        else
            log("  ATTR: (kosong)", Color3.fromRGB(120,120,120))
        end
    end
    -- children
    local children = f:GetChildren()
    if #children > 0 then
        for _, c in ipairs(children) do
            local val = ""
            pcall(function()
                if c:IsA("ValueBase") then val = "="..tostring(c.Value) end
            end)
            log("  CHILD: "..c.ClassName..":"..c.Name..val, Color3.fromRGB(180,255,180))
        end
    else
        log("  CHILD: (tidak ada)", Color3.fromRGB(120,120,120))
    end
end

local function runDump(limit)
    log("── DUMP FRUIT STRUCTURE (limit="..(limit or "semua")..") ──", Color3.fromRGB(200,200,100))
    local farm = getPlayerFarm()
    if not farm then log("❌ Farm tidak ditemukan!"); return end
    local plants = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plants then log("❌ Plants_Physical tidak ditemukan!"); return end

    local idx = 0
    for _, pt in ipairs(plants:GetChildren()) do
        local fruits = pt:FindFirstChild("Fruits")
        if fruits then
            for _, f in ipairs(fruits:GetChildren()) do
                idx += 1
                dumpFruit(f, idx)
                if limit and idx >= limit then
                    log("── Selesai "..idx.." buah ──", Color3.fromRGB(150,150,150))
                    return
                end
            end
        end
    end
    log("── Total: "..idx.." buah ──", Color3.fromRGB(150,150,150))
end

btnDump.MouseButton1Click:Connect(function() runDump(30) end)
btnAll.MouseButton1Click:Connect(function() runDump(nil) end)

btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    local saved = false
    pcall(function() if writefile then writefile("fruit_structure.txt", txt); saved = true end end)
    local clipped = false
    pcall(function()
        if setclipboard then setclipboard(txt); clipped = true
        elseif toclipboard then toclipboard(txt); clipped = true end
    end)
    if saved then log("✅ Saved: fruit_structure.txt", Color3.fromRGB(100,220,140)) end
    if clipped then log("✅ Clipboard ok!", Color3.fromRGB(100,220,140)) end
    if not saved and not clipped then log("❌ Copy gagal", Color3.fromRGB(220,100,100)) end
end)

btnClear.MouseButton1Click:Connect(function()
    for _,v in ipairs(logFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logLines = {}; logOrder = 0
end)

log("Tekan 🔬 DUMP 30 BUAH untuk lihat structure buah", Color3.fromRGB(78,214,204))
log("Cari: Attr mutation/mutasi/type, atau Child StringValue/IntValue", Color3.fromRGB(150,150,150))
