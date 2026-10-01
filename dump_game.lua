-- dump_game.lua — dump semua RE/RF di seluruh game (DataModel)
-- scan game:GetDescendants() untuk semua RemoteEvent dan RemoteFunction
-- GUI dengan filter + copy log

local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local playerGui = plr:WaitForChild("PlayerGui", 10)

pcall(function()
    local par = (gethui and gethui()) or playerGui
    local old = par:FindFirstChild("ZenxDump"); if old then old:Destroy() end
    local old2 = playerGui:FindFirstChild("ZenxDump"); if old2 then old2:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ZenxDump"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 560, 0, 440)
main.Position = UDim2.new(0.5, -280, 0.5, -220)
main.BackgroundColor3 = Color3.fromRGB(8,8,8)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local ms = Instance.new("UIStroke", main)
ms.Color = Color3.fromRGB(40,40,40); ms.Thickness = 1.5

local bar = Instance.new("Frame", main)
bar.Size = UDim2.new(1,0,0,36)
bar.BackgroundColor3 = Color3.fromRGB(14,14,14)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0,10)
local bfix = Instance.new("Frame", bar)
bfix.Size = UDim2.new(1,0,0,10)
bfix.Position = UDim2.new(0,0,1,-10)
bfix.BackgroundColor3 = Color3.fromRGB(14,14,14)
bfix.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel", bar)
titleLbl.Size = UDim2.new(1,-40,1,0)
titleLbl.Position = UDim2.new(0,12,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🗂 GAME DATA DUMP"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextColor3 = Color3.fromRGB(255,180,60)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", bar)
closeBtn.Size = UDim2.new(0,28,0,28)
closeBtn.Position = UDim2.new(1,-36,0.5,-14)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,20,25)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14; closeBtn.TextColor3 = Color3.fromRGB(220,100,110)
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

-- filter bar
local filterFrame = Instance.new("Frame", main)
filterFrame.Size = UDim2.new(1,-16,0,28)
filterFrame.Position = UDim2.new(0,8,0,42)
filterFrame.BackgroundTransparency = 1

local filterBox = Instance.new("TextBox", filterFrame)
filterBox.Size = UDim2.new(1,-90,1,0)
filterBox.Position = UDim2.new(0,0,0,0)
filterBox.BackgroundColor3 = Color3.fromRGB(20,20,20)
filterBox.BorderSizePixel = 0
filterBox.Text = ""
filterBox.PlaceholderText = "filter nama... (contoh: harvest)"
filterBox.Font = Enum.Font.Code
filterBox.TextSize = 11
filterBox.TextColor3 = Color3.fromRGB(220,220,220)
filterBox.PlaceholderColor3 = Color3.fromRGB(100,100,100)
filterBox.ClearTextOnFocus = false
Instance.new("UICorner", filterBox).CornerRadius = UDim.new(0,6)
local fp = Instance.new("UIPadding", filterBox)
fp.PaddingLeft = UDim.new(0,6)

local filterApply = Instance.new("TextButton", filterFrame)
filterApply.Size = UDim2.new(0,82,1,0)
filterApply.Position = UDim2.new(1,-82,0,0)
filterApply.BackgroundColor3 = Color3.fromRGB(30,50,80)
filterApply.Text = "🔍 FILTER"
filterApply.Font = Enum.Font.GothamSemibold
filterApply.TextSize = 11
filterApply.TextColor3 = Color3.fromRGB(200,220,255)
filterApply.AutoButtonColor = true
Instance.new("UICorner", filterApply).CornerRadius = UDim.new(0,6)

-- log area
local logFrame = Instance.new("ScrollingFrame", main)
logFrame.Size = UDim2.new(1,-16,1,-120)
logFrame.Position = UDim2.new(0,8,0,76)
logFrame.BackgroundColor3 = Color3.fromRGB(4,4,4)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 4
logFrame.CanvasSize = UDim2.new(0,0,0,0)
logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0,6)
local ls = Instance.new("UIStroke", logFrame)
ls.Color = Color3.fromRGB(25,25,25); ls.Thickness = 1
local logLayout = Instance.new("UIListLayout", logFrame)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0,1)
local lpad = Instance.new("UIPadding", logFrame)
lpad.PaddingLeft = UDim.new(0,6); lpad.PaddingRight = UDim.new(0,6)
lpad.PaddingTop = UDim.new(0,4); lpad.PaddingBottom = UDim.new(0,4)

local allData = {}   -- semua hasil scan
local logLines = {}
local logOrder = 0

local function clearLog()
    for _, v in ipairs(logFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    logLines = {}; logOrder = 0
end

local function addLine(text, col)
    logOrder += 1
    local lbl = Instance.new("TextLabel", logFrame)
    lbl.Size = UDim2.new(1,0,0,13)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 10
    lbl.TextColor3 = col or Color3.fromRGB(200,200,200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.LayoutOrder = logOrder
    table.insert(logLines, text)
    task.defer(function()
        logFrame.CanvasPosition = Vector2.new(0, math.max(0, logFrame.AbsoluteCanvasSize.Y - logFrame.AbsoluteSize.Y))
    end)
end

local colRE = Color3.fromRGB(100,200,255)
local colRF = Color3.fromRGB(255,150,100)
local colPP = Color3.fromRGB(150,255,150)
local colBS = Color3.fromRGB(255,255,100)
local colSV = Color3.fromRGB(180,180,180)

-- bottom buttons
local btnArea = Instance.new("Frame", main)
btnArea.Size = UDim2.new(1,-16,0,34)
btnArea.Position = UDim2.new(0,8,1,-42)
btnArea.BackgroundTransparency = 1

local function mkBtn(txt, x, w, col)
    local b = Instance.new("TextButton", btnArea)
    b.Size = UDim2.new(0,w,0,28)
    b.Position = UDim2.new(0,x,0,3)
    b.BackgroundColor3 = col or Color3.fromRGB(20,20,20)
    b.Text = txt; b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11; b.TextColor3 = Color3.fromRGB(220,220,220)
    b.AutoButtonColor = true
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    local bs = Instance.new("UIStroke",b)
    bs.Color = Color3.fromRGB(50,50,50); bs.Thickness = 1
    return b
end

local btnScanAll  = mkBtn("📡 SCAN SEMUA",  0,   130, Color3.fromRGB(20,50,20))
local btnScanRE   = mkBtn("RE/RF ONLY",     138, 90,  Color3.fromRGB(20,30,60))
local btnScanPP   = mkBtn("PP ONLY",        236, 75,  Color3.fromRGB(20,50,30))
local btnCopy     = mkBtn("📋 COPY",        319, 70,  Color3.fromRGB(30,20,50))
local btnClear    = mkBtn("🗑",             397, 36)

local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1,-16,0,12)
statusLbl.Position = UDim2.new(0,8,1,-14)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Belum scan"
statusLbl.Font = Enum.Font.Code
statusLbl.TextSize = 10
statusLbl.TextColor3 = Color3.fromRGB(120,120,120)
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ===== SCAN =====
local function doScan(mode, filterStr)
    clearLog()
    allData = {}
    statusLbl.Text = "Scanning..."
    statusLbl.TextColor3 = Color3.fromRGB(220,180,60)

    local filter = filterStr and filterStr:lower() or ""

    task.spawn(function()
        local reCount, rfCount, ppCount, svCount = 0, 0, 0, 0
        local total = 0

        -- scan seluruh DataModel
        local ok, err = pcall(function()
            for _, v in ipairs(game:GetDescendants()) do
                local cls = v.ClassName
                local name = v.Name
                local path = v:GetFullName()
                local nameLow = name:lower()
                local pathLow = path:lower()

                -- apply filter
                if filter ~= "" and not pathLow:find(filter, 1, true) and not nameLow:find(filter, 1, true) then
                    continue
                end

                local line = nil
                local col = nil

                if mode == "all" or mode == "re" then
                    if v:IsA("RemoteEvent") then
                        line = "[RE] "..path
                        col = colRE
                        reCount += 1
                        table.insert(allData, line)
                    elseif v:IsA("RemoteFunction") then
                        line = "[RF] "..path
                        col = colRF
                        rfCount += 1
                        table.insert(allData, line)
                    end
                end

                if mode == "all" or mode == "pp" then
                    if v:IsA("ProximityPrompt") then
                        local dist = v.MaxActivationDistance
                        local enabled = v.Enabled
                        local action = v.ActionText
                        line = "[PP] "..path.." | dist="..dist.." en="..tostring(enabled).." act="..action
                        col = colPP
                        ppCount += 1
                        table.insert(allData, line)
                    end
                end

                if mode == "all" then
                    -- BindableEvent/Function
                    if v:IsA("BindableEvent") then
                        line = "[BE] "..path
                        col = colBS
                        table.insert(allData, line)
                    elseif v:IsA("BindableFunction") then
                        line = "[BF] "..path
                        col = colBS
                        table.insert(allData, line)
                    end
                end

                if line then
                    total += 1
                    addLine(line, col)
                    -- yield setiap 200 item biar tidak lag
                    if total % 200 == 0 then task.wait() end
                end
            end
        end)

        if not ok then
            addLine("ERROR: "..tostring(err), Color3.fromRGB(220,80,80))
        end

        local summary = "RE:"..reCount.." RF:"..rfCount.." PP:"..ppCount.." | total:"..total
        addLine("═══ SELESAI — "..summary.." ═══", Color3.fromRGB(78,214,204))
        statusLbl.Text = summary
        statusLbl.TextColor3 = Color3.fromRGB(100,220,140)
    end)
end

btnScanAll.MouseButton1Click:Connect(function()
    doScan("all", filterBox.Text ~= "" and filterBox.Text or nil)
end)

btnScanRE.MouseButton1Click:Connect(function()
    doScan("re", filterBox.Text ~= "" and filterBox.Text or nil)
end)

btnScanPP.MouseButton1Click:Connect(function()
    doScan("pp", filterBox.Text ~= "" and filterBox.Text or nil)
end)

filterApply.MouseButton1Click:Connect(function()
    doScan("all", filterBox.Text ~= "" and filterBox.Text or nil)
end)

btnCopy.MouseButton1Click:Connect(function()
    local txt = table.concat(allData, "\n")
    -- coba writefile dulu (lebih reliable)
    local saved = false
    pcall(function()
        if writefile then
            writefile("dump_result.txt", txt)
            saved = true
        end
    end)
    -- coba clipboard
    local clipped = false
    pcall(function()
        if setclipboard then setclipboard(txt); clipped = true
        elseif toclipboard then toclipboard(txt); clipped = true
        elseif clipboard then clipboard.set(txt); clipped = true end
    end)
    if saved then
        addLine("💾 Tersimpan: dump_result.txt ("..#allData.." baris)", Color3.fromRGB(100,220,140))
    end
    if clipped then
        addLine("📋 Clipboard ok ("..#allData.." baris)", Color3.fromRGB(100,220,140))
    end
    if not saved and not clipped then
        addLine("⚠ Copy gagal — tampil di bawah, select manual:", Color3.fromRGB(255,180,60))
        -- tampilkan di textbox baru supaya bisa select
        showTextBox(txt)
    end
end)

local textBoxShown = false
function showTextBox(txt)
    if textBoxShown then return end
    textBoxShown = true
    local tbFrame = Instance.new("Frame", gui)
    tbFrame.Size = UDim2.new(0, 560, 0, 300)
    tbFrame.Position = UDim2.new(0.5,-280,0.5,160)
    tbFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
    tbFrame.BorderSizePixel = 0
    Instance.new("UICorner", tbFrame).CornerRadius = UDim.new(0,8)
    local tbClose = Instance.new("TextButton", tbFrame)
    tbClose.Size = UDim2.new(0,28,0,28)
    tbClose.Position = UDim2.new(1,-34,0,4)
    tbClose.BackgroundColor3 = Color3.fromRGB(50,20,25)
    tbClose.Text = "✕"; tbClose.Font = Enum.Font.GothamBold
    tbClose.TextSize = 13; tbClose.TextColor3 = Color3.fromRGB(220,100,110)
    tbClose.AutoButtonColor = true
    Instance.new("UICorner", tbClose).CornerRadius = UDim.new(0,6)
    tbClose.MouseButton1Click:Connect(function() tbFrame:Destroy(); textBoxShown = false end)
    local lbl2 = Instance.new("TextLabel", tbFrame)
    lbl2.Size = UDim2.new(1,-80,0,28)
    lbl2.Position = UDim2.new(0,8,0,0)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = "SELECT ALL → CTRL+C"
    lbl2.Font = Enum.Font.GothamBold
    lbl2.TextSize = 11
    lbl2.TextColor3 = Color3.fromRGB(255,180,60)
    lbl2.TextXAlignment = Enum.TextXAlignment.Left
    local tb = Instance.new("TextBox", tbFrame)
    tb.Size = UDim2.new(1,-16,1,-36)
    tb.Position = UDim2.new(0,8,0,32)
    tb.BackgroundColor3 = Color3.fromRGB(4,4,4)
    tb.BorderSizePixel = 0
    tb.Text = txt
    tb.Font = Enum.Font.Code
    tb.TextSize = 9
    tb.TextColor3 = Color3.fromRGB(200,200,200)
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.TextYAlignment = Enum.TextYAlignment.Top
    tb.MultiLine = true
    tb.TextWrapped = false
    tb.ClearTextOnFocus = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,6)
    local pad = Instance.new("UIPadding", tb)
    pad.PaddingLeft = UDim.new(0,4)
    pad.PaddingTop = UDim.new(0,4)
    tb:CaptureFocus()
end

btnClear.MouseButton1Click:Connect(function() clearLog() end)

-- auto scan RE/RF saat load
addLine("Tekan 📡 SCAN SEMUA untuk dump semua data", Color3.fromRGB(78,214,204))
addLine("Atau ketik filter lalu 🔍 FILTER", Color3.fromRGB(150,150,150))
addLine("Contoh filter: harvest, collect, fruit, farm", Color3.fromRGB(120,120,120))
