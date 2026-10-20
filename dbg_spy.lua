-- dbg_spy.lua — monitor getgc + require + GetAttribute + FPS
-- jalanin SEBELUM sc lain. GUI di tengah layar.

local LOG_GETGC    = true
local LOG_REQUIRE  = true
local LOG_ATTR     = true
local LOG_PETDATA  = true
local MAX_LINES    = 200  -- max log di GUI

-- ═══════════════════ GUI ═══════════════════
local player  = game:GetService("Players").LocalPlayer
local pgui    = player:WaitForChild("PlayerGui")

local sg = Instance.new("ScreenGui")
sg.Name = "SpyGui"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = pgui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 720, 0, 560)
main.Position = UDim2.new(0.5, -360, 0.5, -280)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- title bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 44)
bar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SPY — dbg_spy.lua"
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local fpsLbl = Instance.new("TextLabel")
fpsLbl.Size = UDim2.new(0, 70, 1, 0)
fpsLbl.Position = UDim2.new(1, -110, 0, 0)
fpsLbl.BackgroundTransparency = 1
fpsLbl.Text = "FPS --"
fpsLbl.TextColor3 = Color3.fromRGB(120, 255, 140)
fpsLbl.Font = Enum.Font.GothamBold
fpsLbl.TextSize = 16
fpsLbl.Parent = bar

local function mkBtn(text, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 84, 0, 30)
    b.Position = UDim2.new(1, xOff, 0.5, -15)
    b.BackgroundColor3 = color or Color3.fromRGB(60, 60, 60)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(220, 220, 220)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.Parent = bar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local copyBtn   = mkBtn("Copy All", -270, Color3.fromRGB(40, 80, 140))
local rejoinBtn = mkBtn("Rejoin", -178, Color3.fromRGB(140, 80, 40))
local closeBtn  = mkBtn("✕ Close", -88, Color3.fromRGB(160, 40, 40))

-- scroll frame
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -52)
scroll.Position = UDim2.new(0, 6, 0, 48)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 1)
layout.Parent = scroll

-- ═══════════════════ LOG SYSTEM ═══════════════════
local logLines = {}
local logAll   = {}  -- semua teks buat copy
local lineOrder = 0

local COLOR = {
    getgc   = Color3.fromRGB(255, 180, 60),
    require = Color3.fromRGB(100, 200, 255),
    attr    = Color3.fromRGB(180, 255, 150),
    petdata = Color3.fromRGB(255, 130, 200),
    fps     = Color3.fromRGB(120, 255, 140),
    info    = Color3.fromRGB(160, 160, 160),
}

local function addLog(text, color)
    lineOrder = lineOrder + 1
    logAll[#logAll+1] = text

    -- trim kalau kebanyak
    if #logLines >= MAX_LINES then
        local old = table.remove(logLines, 1)
        if old and old.Parent then old:Destroy() end
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or COLOR.info
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.LayoutOrder = lineOrder
    lbl.Parent = scroll
    logLines[#logLines+1] = lbl

    -- auto scroll ke bawah
    task.defer(function()
        scroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- ═══════════════════ TOMBOL ═══════════════════
closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

rejoinBtn.MouseButton1Click:Connect(function()
    local TS = game:GetService("TeleportService")
    pcall(function() TS:Teleport(game.PlaceId, player) end)
end)

copyBtn.MouseButton1Click:Connect(function()
    local all = table.concat(logAll, "\n")
    pcall(function() setclipboard(all) end)
    copyBtn.Text = "✓ Copied!"
    task.delay(2, function() copyBtn.Text = "Copy All" end)
end)

-- drag
do
    local UIS = game:GetService("UserInputService")
    local drag, dragStart, startPos
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; dragStart = i.Position; startPos = main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- ═══════════════════ HELPERS ═══════════════════
local function short(s)
    s = tostring(s or "")
    if #s > 80 then s = s:sub(1,80).."…" end
    return s
end

local function caller()
    local info = debug.getinfo(3, "Sl")
    if info then
        return ("[%s:%d]"):format(info.short_src or "?", info.currentline or 0)
    end
    return "[?]"
end

-- ═══════════════════ HOOK GETGC ═══════════════════
if LOG_GETGC and getgc then
    local _orig = getgc
    local _cnt, _last = 0, 0
    getgc = function(...)
        _cnt = _cnt + 1
        local now = tick()
        local dt = now - _last; _last = now
        local loc = caller()
        local msg = ("[getgc] #%d dt=%.0fms %s"):format(_cnt, dt*1000, loc)
        addLog(msg, COLOR.getgc)
        print(msg)
        return _orig(...)
    end
    addLog("[SPY] getgc hooked", COLOR.info)
end

-- ═══════════════════ HOOK REQUIRE ═══════════════════
if LOG_REQUIRE and require then
    local _orig = require
    require = function(mod, ...)
        local name = "?"
        pcall(function()
            if type(mod) == "string" then name = mod
            elseif typeof(mod) == "Instance" then name = mod:GetFullName() end
        end)
        local loc = caller()
        local msg = ("[require] %s %s"):format(short(name), loc)
        addLog(msg, COLOR.require)
        print(msg)
        return _orig(mod, ...)
    end
    addLog("[SPY] require hooked", COLOR.info)
end

-- ═══════════════════ HOOK GETATTRIBUTE ═══════════════════
if LOG_ATTR then
    local monitored = {}
    local function hookTool(t)
        if not t:IsA("Tool") then return end
        if monitored[t] then return end
        local uuid = t:GetAttribute("PET_UUID")
        if not uuid then return end
        monitored[t] = true
        local su = tostring(uuid):sub(1,8)
        local origGA = t.GetAttribute
        t.GetAttribute = function(self, attr, ...)
            local v = origGA(self, attr, ...)
            if attr ~= "PET_UUID" then
                local msg = ("[GetAttr] [%s].%s=%s"):format(su, attr, tostring(v))
                addLog(msg, COLOR.attr)
                print(msg)
            end
            return v
        end
    end
    pcall(function()
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do pcall(hookTool, t) end
            bp.ChildAdded:Connect(function(t) pcall(hookTool, t) end)
        end
    end)
    addLog("[SPY] GetAttribute hooked (backpack tools)", COLOR.info)
end

-- ═══════════════════ PETDATA FIELDS ═══════════════════
if LOG_PETDATA then
    local _logged = {}
    task.spawn(function()
        task.wait(3)
        while true do
            task.wait(5)
            if not getgc then break end
            local ok, dump = pcall(getgc, true)
            if not ok then break end
            local found = 0
            for _, obj in pairs(dump) do
                if type(obj) == "table" then
                    local pd = rawget(obj, "PetData")
                    if type(pd) == "table" then
                        local key = tostring(obj):sub(1,20)
                        if not _logged[key] then
                            _logged[key] = true
                            local fields = {}
                            for k, v in pairs(pd) do
                                fields[#fields+1] = k.."="..short(tostring(v))
                            end
                            local msg = ("[PetData] %s"):format(table.concat(fields, " | "))
                            addLog(msg, COLOR.petdata)
                            print(msg)
                            found = found + 1
                            if found >= 3 then break end
                        end
                    end
                end
            end
        end
    end)
    addLog("[SPY] PetData monitor aktif (tiap 5s)", COLOR.info)
end

-- ═══════════════════ FPS ═══════════════════
task.spawn(function()
    local RS = game:GetService("RunService")
    local cnt, last = 0, tick()
    RS.Heartbeat:Connect(function()
        cnt = cnt + 1
        local now = tick()
        if now - last >= 1 then
            local f = cnt; cnt = 0; last = now
            fpsLbl.Text = "FPS "..f
            fpsLbl.TextColor3 = f <= 5 and Color3.fromRGB(255,80,80)
                or f <= 20 and Color3.fromRGB(255,210,80)
                or COLOR.fps
            addLog(("[FPS] %d"):format(f), COLOR.fps)
        end
    end)
end)

addLog("[SPY] ready — jalanin sc lain sekarang", COLOR.info)
