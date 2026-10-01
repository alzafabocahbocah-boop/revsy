-- debug_sniff.lua — GUI sniff collect method (aman, tidak hook global)
local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local playerGui = plr:WaitForChild("PlayerGui", 10)

pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxSniff"); if old then old:Destroy() end
    local old2 = playerGui:FindFirstChild("ZenxSniff"); if old2 then old2:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ZenxSniff"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 500, 0, 380)
main.Position = UDim2.new(0.5, -250, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local ms = Instance.new("UIStroke", main)
ms.Color = Color3.fromRGB(40, 40, 40); ms.Thickness = 1.5

-- title bar
local bar = Instance.new("Frame", main)
bar.Size = UDim2.new(1, 0, 0, 36)
bar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local fix = Instance.new("Frame", bar)
fix.Size = UDim2.new(1, 0, 0, 10)
fix.Position = UDim2.new(0, 0, 1, -10)
fix.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
fix.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel", bar)
titleLbl.Size = UDim2.new(1, -50, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🔍 SNIFF COLLECT METHOD"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextColor3 = Color3.fromRGB(78, 214, 204)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", bar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 25)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14; closeBtn.TextColor3 = Color3.fromRGB(220, 100, 110)
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
logFrame.Size = UDim2.new(1, -16, 1, -90)
logFrame.Position = UDim2.new(0, 8, 0, 44)
logFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 4
logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 6)
local ls = Instance.new("UIStroke", logFrame)
ls.Color = Color3.fromRGB(25, 25, 25); ls.Thickness = 1
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
    lbl.Size = UDim2.new(1, 0, 0, 14)
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
    task.defer(function()
        logFrame.CanvasPosition = Vector2.new(0, math.max(0, logFrame.AbsoluteCanvasSize.Y - logFrame.AbsoluteSize.Y))
    end)
end
local function log(t, c) addLine(t, c) end
local function logOk(t) log("✅ "..t, Color3.fromRGB(100, 220, 140)) end
local function logWarn(t) log("⚠ "..t, Color3.fromRGB(220, 180, 60)) end
local function logHit(t) log("🎯 "..t, Color3.fromRGB(255, 120, 255)) end

-- bottom buttons
local btnArea = Instance.new("Frame", main)
btnArea.Size = UDim2.new(1, -16, 0, 36)
btnArea.Position = UDim2.new(0, 8, 1, -44)
btnArea.BackgroundTransparency = 1

local function mkBtn(txt, x, w, col)
    local b = Instance.new("TextButton", btnArea)
    b.Size = UDim2.new(0, w or 110, 0, 28)
    b.Position = UDim2.new(0, x, 0, 4)
    b.BackgroundColor3 = col or Color3.fromRGB(20, 20, 20)
    b.Text = txt; b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11; b.TextColor3 = Color3.fromRGB(220, 220, 220)
    b.AutoButtonColor = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke", b)
    bs.Color = Color3.fromRGB(50, 50, 50); bs.Thickness = 1
    return b
end

local btnStart = mkBtn("▶ MULAI SNIFF", 0,   130, Color3.fromRGB(20, 50, 20))
local btnClear = mkBtn("🗑 CLEAR",       138, 80)
local btnCopy  = mkBtn("📋 COPY LOG",   226, 110, Color3.fromRGB(30, 20, 50))
local btnStop  = mkBtn("⛔ STOP",       344, 80,  Color3.fromRGB(50, 15, 15))

local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1, -16, 0, 14)
statusLbl.Position = UDim2.new(0, 8, 1, -14)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Belum aktif"
statusLbl.Font = Enum.Font.Code
statusLbl.TextSize = 10
statusLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ===== SNIFF LOGIC =====
local hooks = {}
local conns = {}
local active = false

local function stopSniff()
    active = false
    for _, h in ipairs(hooks) do
        pcall(function() hookfunction(h.fn, h.orig) end)
    end
    hooks = {}
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    statusLbl.Text = "Sniff berhenti"
    statusLbl.TextColor3 = Color3.fromRGB(180, 80, 80)
    logWarn("Sniff dihentikan")
end

local function hookArgs(label, args)
    for i, a in ipairs(args) do
        if typeof(a) == "Instance" then
            log("  ["..i.."] "..a:GetFullName())
        else
            log("  ["..i.."] "..typeof(a).."="..tostring(a))
        end
    end
end

local function startSniff()
    if active then stopSniff() end
    active = true
    logLines = {}
    log("═══ SNIFF AKTIF — jalankan sc lain, collect 1 buah ═══", Color3.fromRGB(78, 214, 204))
    statusLbl.Text = "● Sniff aktif..."
    statusLbl.TextColor3 = Color3.fromRGB(100, 220, 140)

    local hookCount = 0

    -- 1. fireproximityprompt
    if fireproximityprompt then
        local origFPP = fireproximityprompt
        local newFPP = hookfunction(origFPP, function(pp, ...)
            if active then
                logHit("fireproximityprompt → "..tostring(pp and pp:GetFullName()))
                local ppPart = pp and pp.Parent
                if ppPart and ppPart:IsA("BasePart") then
                    local char2 = plr.Character
                    local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                    if hrp2 then
                        log("  jarak: "..math.floor((hrp2.Position - ppPart.Position).Magnitude).." studs")
                    end
                end
            end
            return origFPP(pp, ...)
        end)
        table.insert(hooks, {fn=newFPP, orig=origFPP})
        hookCount = hookCount + 1
        logOk("Hook: fireproximityprompt")
    else
        logWarn("fireproximityprompt tidak ada")
    end

    -- 2. firetouchinterest
    if firetouchinterest then
        local origFTI = firetouchinterest
        local newFTI = hookfunction(origFTI, function(part1, part2, toggle, ...)
            if active then
                logHit("firetouchinterest toggle="..tostring(toggle))
                log("  part1: "..tostring(part1 and part1:GetFullName()))
                log("  part2: "..tostring(part2 and part2:GetFullName()))
            end
            return origFTI(part1, part2, toggle, ...)
        end)
        table.insert(hooks, {fn=newFTI, orig=origFTI})
        hookCount = hookCount + 1
        logOk("Hook: firetouchinterest")
    else
        logWarn("firetouchinterest tidak ada")
    end

    -- 3. fireclickdetector
    if fireclickdetector then
        local origFCD = fireclickdetector
        local newFCD = hookfunction(origFCD, function(cd, ...)
            if active then
                logHit("fireclickdetector → "..tostring(cd and cd:GetFullName()))
            end
            return origFCD(cd, ...)
        end)
        table.insert(hooks, {fn=newFCD, orig=origFCD})
        hookCount = hookCount + 1
        logOk("Hook: fireclickdetector")
    else
        logWarn("fireclickdetector tidak ada")
    end

    -- 4. fireserver (exploit shortcut)
    if fireserver then
        local origFS = fireserver
        local newFS = hookfunction(origFS, function(re, ...)
            if active then
                logHit("fireserver → "..tostring(re and re:GetFullName()))
                hookArgs("", {...})
            end
            return origFS(re, ...)
        end)
        table.insert(hooks, {fn=newFS, orig=origFS})
        hookCount = hookCount + 1
        logOk("Hook: fireserver (shortcut)")
    end

    -- 5. invokeserver (exploit shortcut)
    if invokeserver then
        local origIS = invokeserver
        local newIS = hookfunction(origIS, function(rf, ...)
            if active then
                logHit("invokeserver → "..tostring(rf and rf:GetFullName()))
                hookArgs("", {...})
            end
            return origIS(rf, ...)
        end)
        table.insert(hooks, {fn=newIS, orig=origIS})
        hookCount = hookCount + 1
        logOk("Hook: invokeserver (shortcut)")
    end

    -- 6. Scan SEMUA RS descendants → hook FireServer + InvokeServer per-instance
    local SKIP = {Fps=true, Input=true, Ping=true, RefreshIndex=true, GetState=true}
    local hooked_paths = {}
    for _, v in ipairs(RS:GetDescendants()) do
        if not SKIP[v.Name] then
            local vpath = v:GetFullName()
            if v:IsA("RemoteEvent") then
                local origFire = v.FireServer
                local ok2, newFire = pcall(hookfunction, origFire, function(self, ...)
                    if active then
                        logHit("FireServer: "..vpath)
                        hookArgs("", {...})
                    end
                    return origFire(self, ...)
                end)
                if ok2 then
                    table.insert(hooks, {fn=newFire, orig=origFire})
                    table.insert(hooked_paths, "RE:"..v.Name)
                    hookCount = hookCount + 1
                end
            elseif v:IsA("RemoteFunction") then
                local origInv = v.InvokeServer
                local ok2, newInv = pcall(hookfunction, origInv, function(self, ...)
                    if active then
                        logHit("InvokeServer: "..vpath)
                        hookArgs("", {...})
                    end
                    return origInv(self, ...)
                end)
                if ok2 then
                    table.insert(hooks, {fn=newInv, orig=origInv})
                    table.insert(hooked_paths, "RF:"..v.Name)
                    hookCount = hookCount + 1
                end
            end
        end
    end
    log("RS scan: "..#hooked_paths.." RE/RF di-hook", Color3.fromRGB(150, 150, 150))
    if #hooked_paths > 0 then
        log("  "..table.concat(hooked_paths, ", "), Color3.fromRGB(120, 120, 120))
    end

    -- 7. PP Triggered listener (semua PP di workspace)
    local ppCount = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local vpath = v:GetFullName()
            local c = v.Triggered:Connect(function(plrWho)
                if active then
                    logHit("PP.Triggered: "..vpath)
                    log("  by: "..tostring(plrWho and plrWho.Name))
                end
            end)
            table.insert(conns, c)
            ppCount = ppCount + 1
        end
    end
    log("PP listeners: "..ppCount, Color3.fromRGB(150, 150, 150))

    logOk("TOTAL HOOKS: "..hookCount.." | PP: "..ppCount)
    log("Sekarang jalankan sc lain → collect 1 buah", Color3.fromRGB(180, 180, 60))
    statusLbl.Text = "● Aktif — "..hookCount.." hooks + "..ppCount.." PP"
end

-- buttons
btnStart.MouseButton1Click:Connect(function() startSniff() end)
btnStop.MouseButton1Click:Connect(function() stopSniff() end)
btnClear.MouseButton1Click:Connect(function()
    for _, v in ipairs(logFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logLines = {}; logOrder = 0
end)
btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    if setclipboard then setclipboard(txt)
    elseif toclipboard then toclipboard(txt) end
    logOk("Log disalin!")
end)

log("Tekan MULAI SNIFF, lalu jalankan sc lain dan collect 1 buah", Color3.fromRGB(78, 214, 204))
