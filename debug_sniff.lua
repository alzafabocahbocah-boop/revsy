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
titleLbl.Text = "🔍 SNIFF COLLECT METHOD v3"
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

local hooks = {}
local conns = {}
local active = false

local function stopSniff()
    active = false
    for _, h in ipairs(hooks) do pcall(function() hookfunction(h.fn, h.orig) end) end
    hooks = {}
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    statusLbl.Text = "Sniff berhenti"
    statusLbl.TextColor3 = Color3.fromRGB(180, 80, 80)
    logWarn("Sniff dihentikan")
end

local function hookArgs(args)
    for i, a in ipairs(args) do
        if typeof(a) == "Instance" then log("  ["..i.."] "..a:GetFullName())
        else log("  ["..i.."] "..typeof(a).."="..tostring(a)) end
    end
end

local function startSniff()
    if active then stopSniff() end
    active = true
    logLines = {}
    log("═══ SNIFF v3 AKTIF ═══", Color3.fromRGB(78, 214, 204))
    statusLbl.Text = "● Sniff aktif..."
    statusLbl.TextColor3 = Color3.fromRGB(100, 220, 140)

    local hookCount = 0

    -- 1. fireproximityprompt
    if fireproximityprompt then
        local orig = fireproximityprompt
        local new = hookfunction(orig, function(pp, ...)
            if active then
                logHit("fireproximityprompt → "..(pp and pp:GetFullName() or "?"))
                local ppPart = pp and pp.Parent
                if ppPart and ppPart:IsA("BasePart") then
                    local hrp2 = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp2 then log("  jarak: "..math.floor((hrp2.Position-ppPart.Position).Magnitude).." studs") end
                end
            end
            return orig(pp, ...)
        end)
        table.insert(hooks, {fn=new, orig=orig}); hookCount+=1
        logOk("Hook: fireproximityprompt")
    else logWarn("fireproximityprompt tidak ada") end

    -- 2. firetouchinterest
    if firetouchinterest then
        local orig = firetouchinterest
        local new = hookfunction(orig, function(p1,p2,t,...)
            if active then
                logHit("firetouchinterest t="..(t or "?"))
                log("  p1: "..(p1 and p1:GetFullName() or "?"))
                log("  p2: "..(p2 and p2:GetFullName() or "?"))
            end
            return orig(p1,p2,t,...)
        end)
        table.insert(hooks, {fn=new, orig=orig}); hookCount+=1
        logOk("Hook: firetouchinterest")
    else logWarn("firetouchinterest tidak ada") end

    -- 3. fireclickdetector
    if fireclickdetector then
        local orig = fireclickdetector
        local new = hookfunction(orig, function(cd,...)
            if active then logHit("fireclickdetector → "..(cd and cd:GetFullName() or "?")) end
            return orig(cd,...)
        end)
        table.insert(hooks, {fn=new, orig=orig}); hookCount+=1
        logOk("Hook: fireclickdetector")
    end

    -- 4. fireserver shortcut
    if fireserver then
        local orig = fireserver
        local new = hookfunction(orig, function(re,...)
            if active then logHit("fireserver → "..(re and re:GetFullName() or "?")); hookArgs({...}) end
            return orig(re,...)
        end)
        table.insert(hooks, {fn=new, orig=orig}); hookCount+=1
        logOk("Hook: fireserver (shortcut)")
    end

    -- 5. invokeserver shortcut
    if invokeserver then
        local orig = invokeserver
        local new = hookfunction(orig, function(rf,...)
            if active then logHit("invokeserver → "..(rf and rf:GetFullName() or "?")); hookArgs({...}) end
            return orig(rf,...)
        end)
        table.insert(hooks, {fn=new, orig=orig}); hookCount+=1
        logOk("Hook: invokeserver (shortcut)")
    end

    -- 6. sethiddenproperty
    if sethiddenproperty then
        local orig = sethiddenproperty
        local new = hookfunction(orig, function(inst, prop, val, ...)
            if active then
                logHit("sethiddenproperty: "..tostring(prop).."="..tostring(val))
                log("  on: "..(inst and inst:GetFullName() or "?"))
            end
            return orig(inst, prop, val, ...)
        end)
        table.insert(hooks, {fn=new, orig=orig}); hookCount+=1
        logOk("Hook: sethiddenproperty")
    else logWarn("sethiddenproperty tidak ada") end

    -- 7. Semua RS RE/RF
    local SKIP = {Fps=true, Input=true, Ping=true, RefreshIndex=true, GetState=true}
    local rsCount = 0
    for _, v in ipairs(RS:GetDescendants()) do
        if not SKIP[v.Name] then
            local vpath = v:GetFullName()
            if v:IsA("RemoteEvent") then
                local orig = v.FireServer
                local ok, new = pcall(hookfunction, orig, function(self,...)
                    if active then logHit("FireServer: "..vpath); hookArgs({...}) end
                    return orig(self,...)
                end)
                if ok then table.insert(hooks,{fn=new,orig=orig}); rsCount+=1; hookCount+=1 end
            elseif v:IsA("RemoteFunction") then
                local orig = v.InvokeServer
                local ok, new = pcall(hookfunction, orig, function(self,...)
                    if active then logHit("InvokeServer: "..vpath); hookArgs({...}) end
                    return orig(self,...)
                end)
                if ok then table.insert(hooks,{fn=new,orig=orig}); rsCount+=1; hookCount+=1 end
            end
        end
    end
    log("RS hooks: "..rsCount, Color3.fromRGB(150,150,150))

    -- 8. PP hooks: Triggered + InputHoldBegin + InputHoldEnd per PP
    local ppCount = 0
    local ppHoldCount = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local vpath = v:GetFullName()

            -- Triggered event
            local c1 = v.Triggered:Connect(function(who)
                if active then
                    logHit("PP.Triggered: "..vpath)
                    log("  by: "..(who and who.Name or "?"))
                end
            end)
            table.insert(conns, c1)
            ppCount += 1

            -- Hook InputHoldBegin
            pcall(function()
                local origB = v.InputHoldBegin
                local nb = hookfunction(origB, function(self,...)
                    if active then logHit("PP.InputHoldBegin: "..vpath) end
                    return origB(self,...)
                end)
                table.insert(hooks, {fn=nb, orig=origB})
                ppHoldCount += 1
            end)

            -- Hook InputHoldEnd
            pcall(function()
                local origE = v.InputHoldEnd
                local ne = hookfunction(origE, function(self,...)
                    if active then logHit("PP.InputHoldEnd: "..vpath) end
                    return origE(self,...)
                end)
                table.insert(hooks, {fn=ne, orig=origE})
            end)
        end
    end
    log("PP Triggered: "..ppCount.." | InputHold hooks: "..ppHoldCount, Color3.fromRGB(150,150,150))

    -- 9. Monitor buah hilang (deteksi pasif)
    local farmFolder = workspace:FindFirstChild("Farm")
    if farmFolder then
        local function watchFruits(folder)
            local c = folder.ChildRemoved:Connect(function(child)
                if active then
                    log("🍎 ChildRemoved dari "..folder:GetFullName()..": "..child.Name, Color3.fromRGB(255,200,100))
                end
            end)
            table.insert(conns, c)
        end
        -- watch semua Fruits folder
        for _, v in ipairs(farmFolder:GetDescendants()) do
            if v.Name == "Fruits" then
                watchFruits(v)
            end
        end
        logOk("Monitor: farm ChildRemoved aktif")
    end

    logOk("TOTAL: "..hookCount.." hooks | "..ppCount.." PP listeners")
    log("Jalankan sc lain → collect 1 buah, lihat 🎯", Color3.fromRGB(180,180,60))
    statusLbl.Text = "● Aktif — "..hookCount.." hooks"
end

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

log("Tekan MULAI SNIFF dulu, BARU jalankan sc lain", Color3.fromRGB(78, 214, 204))
