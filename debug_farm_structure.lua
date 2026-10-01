-- debug_farm_structure.lua
-- GUI: dump struktur workspace.Farm lengkap
-- Lihat subfarm per player, Plants_Physical, model count dll
-- Bisa scroll + copy

local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local playerGui = plr:WaitForChild("PlayerGui", 10)

pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxDebugFarm"); if old then old:Destroy() end
    local old2 = playerGui:FindFirstChild("ZenxDebugFarm"); if old2 then old2:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ZenxDebugFarm"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 540, 0, 480)
main.Position = UDim2.new(0.5, -270, 0.5, -240)
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
title.BackgroundTransparency = 1; title.Text = "🌾 DEBUG FARM STRUCTURE"
title.Font = Enum.Font.GothamBold; title.TextSize = 12
title.TextColor3 = Color3.fromRGB(100,200,255); title.TextXAlignment = Enum.TextXAlignment.Left

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
local function logOk(t) log("✅ "..t, Color3.fromRGB(100,220,140)) end
local function logErr(t) log("❌ "..t, Color3.fromRGB(220,100,100)) end
local function logInfo(t) log("ℹ  "..t, Color3.fromRGB(255,200,60)) end
local function logH(t) log("── "..t.." ──", Color3.fromRGB(200,200,100)) end

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

local btnScan  = mkBtn("🌾 SCAN FARM",   0,   120, Color3.fromRGB(20,40,20))
local btnDeep  = mkBtn("🔍 DEEP SCAN",  128,  110, Color3.fromRGB(20,20,60))
local btnCopy  = mkBtn("📋 COPY",       246,  70,  Color3.fromRGB(30,20,50))
local btnClear = mkBtn("🗑",            324,  36)

-- ===== SCAN =====
local function scanFarm(deep)
    logH("SCAN FARM (plr=" .. plr.Name .. ")")
    local farm = workspace:FindFirstChild("Farm")
    if not farm then logErr("workspace.Farm tidak ada!"); return end
    logOk("Farm ada: "..farm:GetFullName().." | ClassName="..farm.ClassName)
    logInfo("Jumlah children Farm: "..#farm:GetChildren())

    for _, subfarm in ipairs(farm:GetChildren()) do
        local isSelf = (subfarm.Name == plr.Name)
        local tag = isSelf and " [SENDIRI]" or " [ORANG LAIN]"
        log("  📁 "..subfarm.Name.." ("..subfarm.ClassName..")"..tag,
            isSelf and Color3.fromRGB(255,180,60) or Color3.fromRGB(100,220,255))

        -- cari Plants_Physical di descendants
        local function findPP(obj, depth)
            if depth > 6 then return end
            for _, c in ipairs(obj:GetChildren()) do
                local indent = string.rep("  ", depth+2)
                if c.Name == "Plants_Physical" then
                    local modelCount = 0
                    for _, m in ipairs(c:GetChildren()) do
                        if m:IsA("Model") then modelCount += 1 end
                    end
                    log(indent.."📦 Plants_Physical ("..c.ClassName..") — "..modelCount.." Model",
                        isSelf and Color3.fromRGB(255,220,80) or Color3.fromRGB(80,220,255))
                    if deep then
                        -- tampilkan path lengkap
                        log(indent.."   Path: "..c:GetFullName(), Color3.fromRGB(150,150,150))
                        -- tampilkan 5 model pertama
                        local shown = 0
                        for _, m in ipairs(c:GetChildren()) do
                            if m:IsA("Model") and shown < 5 then
                                log(indent.."   Model["..shown+1.."]: "..m.Name, Color3.fromRGB(180,255,180))
                                shown += 1
                            end
                        end
                        if modelCount > 5 then
                            log(indent.."   ...dan "..(modelCount-5).." model lagi", Color3.fromRGB(120,120,120))
                        end
                    end
                elseif deep or c.Name == "Important" then
                    -- tampilkan folder penting
                    log(indent.."📂 "..c.Name.." ("..c.ClassName..")", Color3.fromRGB(160,160,160))
                    findPP(c, depth+1)
                end
            end
        end
        findPP(subfarm, 0)
    end

    -- cek player list
    logH("PLAYERS DI SERVER")
    for _, p in ipairs(game.Players:GetPlayers()) do
        local tag = (p.Name == plr.Name) and " [KITA]" or ""
        logInfo(p.Name..tag)
    end

    -- summary destroy target
    logH("DESTROY TARGET SUMMARY")
    local destroyCount = 0
    for _, subfarm in ipairs(farm:GetChildren()) do
        if subfarm.Name ~= plr.Name then
            for _, f in ipairs(subfarm:GetDescendants()) do
                if f.Name == "Plants_Physical" and (f:IsA("Folder") or f:IsA("Model")) then
                    for _, c in ipairs(f:GetChildren()) do
                        if c:IsA("Model") then destroyCount += 1 end
                    end
                end
            end
        end
    end
    if destroyCount > 0 then
        logOk("Target destroy: "..destroyCount.." pohon orang lain")
    else
        log("⚠️  Tidak ada pohon orang lain ditemukan (solo server / subfarm nama beda?)",
            Color3.fromRGB(255,150,50))
    end
end

btnScan.MouseButton1Click:Connect(function() scanFarm(false) end)
btnDeep.MouseButton1Click:Connect(function() scanFarm(true) end)

btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    local saved = false; local clipped = false
    pcall(function() if writefile then writefile("debug_farm.txt", txt); saved = true end end)
    pcall(function()
        if setclipboard then setclipboard(txt); clipped = true
        elseif toclipboard then toclipboard(txt); clipped = true end
    end)
    if saved then logOk("Saved: debug_farm.txt") end
    if clipped then logOk("Clipboard ok!") end
    if not saved and not clipped then logErr("Copy gagal") end
end)

btnClear.MouseButton1Click:Connect(function()
    for _,v in ipairs(logFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logLines = {}; logOrder = 0
end)

log("🌾 SCAN FARM = lihat struktur Farm (cepat)", Color3.fromRGB(78,214,204))
log("🔍 DEEP SCAN = tampilkan path + model detail per subfarm", Color3.fromRGB(78,214,204))
