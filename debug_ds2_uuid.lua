-- debug_ds2_uuid.lua
-- Listener DS2 standalone — log semua roar/fan dengan mine/asing
-- GUI panel kiri layar + tombol copy

local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")

-- ===================== GUI =====================
local playerGui = plr:WaitForChild("PlayerGui", 10)

-- hapus instance lama kalau ada
local old = playerGui:FindFirstChild("DS2DbgGui")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "DS2DbgGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

-- panel utama kiri tengah
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 300, 0, 400)
panel.Position = UDim2.new(0, 8, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 26)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleBar.BorderSizePixel = 0
titleBar.Parent = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -60, 1, 0)
titleLbl.Position = UDim2.new(0, 8, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "DS2 UUID Debug"
titleLbl.TextColor3 = Color3.fromRGB(180, 180, 255)
titleLbl.TextSize = 11
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

-- tombol clear
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 44, 0, 20)
clearBtn.Position = UDim2.new(1, -50, 0, 3)
clearBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 50)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "CLR"
clearBtn.TextColor3 = Color3.fromRGB(255, 160, 160)
clearBtn.TextSize = 10
clearBtn.Font = Enum.Font.GothamBold
clearBtn.Parent = titleBar
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)

-- tombol copy (bawah panel)
local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(1, -16, 0, 28)
copyBtn.Position = UDim2.new(0, 8, 1, -34)
copyBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
copyBtn.BorderSizePixel = 0
copyBtn.Text = "📋 COPY LOG"
copyBtn.TextColor3 = Color3.fromRGB(180, 220, 255)
copyBtn.TextSize = 11
copyBtn.Font = Enum.Font.GothamBold
copyBtn.Parent = panel
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

-- scroll frame untuk log
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -64)
scroll.Position = UDim2.new(0, 4, 0, 30)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 160)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local logBox = Instance.new("TextLabel")
logBox.Size = UDim2.new(1, -4, 0, 0)
logBox.AutomaticSize = Enum.AutomaticSize.Y
logBox.BackgroundTransparency = 1
logBox.Text = ""
logBox.TextColor3 = Color3.fromRGB(210, 210, 210)
logBox.TextSize = 10
logBox.Font = Enum.Font.RobotoMono
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.RichText = false
logBox.Parent = scroll

-- drag panel
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = panel.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ===================== LOG =====================
local logs = {}
local MAX_LOG = 300

local function addLog(msg)
    local ts = string.format("%.2f", tick() % 1000)
    table.insert(logs, 1, ts.." "..msg)
    if #logs > MAX_LOG then logs[#logs] = nil end
    pcall(function() logBox.Text = table.concat(logs, "\n") end)
    -- auto scroll ke atas (entry terbaru di atas)
    pcall(function() scroll.CanvasPosition = Vector2.new(0, 0) end)
end

clearBtn.MouseButton1Click:Connect(function()
    for i = #logs, 1, -1 do logs[i] = nil end
    pcall(function() logBox.Text = "" end)
end)

copyBtn.MouseButton1Click:Connect(function()
    local txt = table.concat(logs, "\n")
    pcall(function() setclipboard(txt) end)
    copyBtn.Text = "✓ COPIED!"
    copyBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
    task.wait(1.5)
    copyBtn.Text = "📋 COPY LOG"
    copyBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
end)

-- ===================== UUID MINE CHECK =====================
local function getMyUuids()
    local mine = {}
    pcall(function()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") and tostring(d.Name):sub(1,1) == "{" then
                mine[d.Name] = true
                mine[tostring(d.Name):gsub("[{}]",""):lower()] = true
            end
        end
    end)
    pcall(function()
        local char = plr.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("Model") and tostring(d.Name):sub(1,1) == "{" then
                    mine[d.Name] = true
                    mine[tostring(d.Name):gsub("[{}]",""):lower()] = true
                end
            end
        end
    end)
    pcall(function()
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                local u = t:GetAttribute("PET_UUID") or t:GetAttribute("UUID") or t:GetAttribute("uuid")
                if u then
                    local ustr = tostring(u):lower()
                    mine[ustr] = true
                    mine[ustr:gsub("[{}]","")] = true
                end
            end
        end
    end)
    return mine
end

-- ===================== DS2 LISTENER =====================
local ds2 = RS:FindFirstChild("GameEvents") and RS.GameEvents:FindFirstChild("DataStream")
if not ds2 then
    addLog("ERROR: DataStream not found!")
else
    addLog("DS2 ON — "..plr.Name)
    ds2.OnClientEvent:Connect(function(anim, uuid)
        if anim ~= "roar" and anim ~= "fan" and anim ~= "weave" then return end
        local raw = tostring(uuid or ""):gsub("[{}]",""):lower()
        if raw == "" then return end
        local r8 = raw:sub(1,8)
        local myUuids = getMyUuids()
        local isMine = myUuids[raw] or myUuids["{"..raw.."}"] or false
        if isMine then
            addLog("✓ "..anim.." "..r8.." [MINE]")
        else
            addLog("✗ "..anim.." "..r8.." [asing]")
        end
    end)
    addLog("Listening roar/fan/weave...")
end
