-- debug_collect.lua v9 — SNIFF LISTEN: pasang OnClientEvent di semua RS remote, tanpa hook
local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local playerGui = plr:WaitForChild("PlayerGui", 10)
local gameEvents = RS:WaitForChild("GameEvents", 10)
local harvestRE = gameEvents:FindFirstChild("HarvestRemote")

-- ===================== HELPERS =====================
local function getPlayerFarm()
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name == "Farm" then
            for _, f in ipairs(v:GetChildren()) do
                if f.Name == "Farm" then
                    -- cek punya Important.Plants_Physical
                    if f:FindFirstChild("Important") then return f end
                end
            end
        end
    end
    return nil
end

local SKIP = {Nightmare=true,IsOutlined=true,FruitSpawnIndex=true,
    FruitVersion=true,DoneGrowTime=true,WeightMulti=true,MaxAge=true,GrowRateMulti=true}

local function fruitMutasi(fruit)
    for k, v in pairs(fruit:GetAttributes()) do
        if v == true and not SKIP[k] then return k end
    end
    return nil
end

local function scanAllMutasi()
    local out = {}
    local farm = getPlayerFarm(); if not farm then return out end
    local plants = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plants then return out end
    for _, pt in ipairs(plants:GetChildren()) do
        local fruits = pt:FindFirstChild("Fruits"); if not fruits then continue end
        for _, fruit in ipairs(fruits:GetChildren()) do
            local mut = fruitMutasi(fruit)
            if mut then table.insert(out, {fruit=fruit, mut=mut}) end
        end
    end
    return out
end

local function countFruits()
    local n = 0
    local farm = getPlayerFarm(); if not farm then return 0 end
    local plants = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plants then return 0 end
    for _, pt in ipairs(plants:GetChildren()) do
        local fr = pt:FindFirstChild("Fruits")
        if fr then n = n + #fr:GetChildren() end
    end
    return n
end

local function getPrompt(fruit)
    for _, v in ipairs(fruit:GetDescendants()) do
        if v:IsA("ProximityPrompt") then return v end
    end
    return nil
end

-- ===================== STATE =====================
local _logLines = {}
local _fruit = nil
local _prompt = nil
local _busy = false

-- ===================== GUI =====================
local old = playerGui:FindFirstChild("ZenxDbgCollect"); if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "ZenxDbgCollect"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
pcall(function() gui.Parent = (gethui and gethui()) or playerGui end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 625)
main.Position = UDim2.new(0.5, -200, 0.5, -312)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
main.BorderSizePixel = 0; main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke", main); st.Color = Color3.fromRGB(50,50,50); st.Thickness = 1.5

-- title bar drag
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,40); titleBar.BackgroundColor3 = Color3.fromRGB(18,18,18)
titleBar.BorderSizePixel = 0; titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
Instance.new("Frame", titleBar).Size = UDim2.new(1,0,0,10)
titleBar:FindFirstChildWhichIsA("Frame").Position = UDim2.new(0,0,1,-10)
titleBar:FindFirstChildWhichIsA("Frame").BackgroundColor3 = Color3.fromRGB(18,18,18)
titleBar:FindFirstChildWhichIsA("Frame").BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,-40,1,0); titleLbl.Position = UDim2.new(0,12,0,0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "🔬 DEBUG COLLECT"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 13
titleLbl.TextColor3 = Color3.fromRGB(78,214,204); titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-34,0.5,-14)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,20,20); closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(220,100,100); closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

do -- drag
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = main.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

-- scroll log
local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(1,-16,1,-240); logFrame.Position = UDim2.new(0,8,0,48)
logFrame.BackgroundColor3 = Color3.fromRGB(5,5,5); logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 4; logFrame.ScrollBarImageColor3 = Color3.fromRGB(50,50,50)
logFrame.CanvasSize = UDim2.new(0,0,0,0); logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logFrame.Parent = main
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0,6)
Instance.new("UIListLayout", logFrame).Padding = UDim.new(0,2)
local logPad = Instance.new("UIPadding", logFrame)
logPad.PaddingLeft = UDim.new(0,6); logPad.PaddingRight = UDim.new(0,6)
logPad.PaddingTop = UDim.new(0,4); logPad.PaddingBottom = UDim.new(0,4)

local function addLog(msg, col)
    table.insert(_logLines, msg)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,0); l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1; l.Text = msg
    l.Font = Enum.Font.Code; l.TextSize = 11
    l.TextColor3 = col or Color3.fromRGB(200,200,200)
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    l.Parent = logFrame
    -- auto scroll
    task.defer(function()
        pcall(function() logFrame.CanvasPosition = Vector2.new(0, logFrame.AbsoluteCanvasSize.Y) end)
    end)
end

-- tombol salin log
local copyLogBtn = Instance.new("TextButton")
copyLogBtn.Size = UDim2.new(1,-16,0,24); copyLogBtn.Position = UDim2.new(0,8,1,-284)
copyLogBtn.BackgroundColor3 = Color3.fromRGB(20,20,40); copyLogBtn.Text = "📋  SALIN LOG"
copyLogBtn.Font = Enum.Font.GothamBold; copyLogBtn.TextSize = 11
copyLogBtn.TextColor3 = Color3.fromRGB(100,160,255); copyLogBtn.AutoButtonColor = false; copyLogBtn.Parent = main
Instance.new("UICorner", copyLogBtn).CornerRadius = UDim.new(0,5)
copyLogBtn.MouseButton1Click:Connect(function()
    if #_logLines == 0 then return end
    local txt = table.concat(_logLines, "\n")
    if setclipboard then setclipboard(txt)
    elseif toclipboard then toclipboard(txt) end
    copyLogBtn.Text = "✅ TERSALIN!"
    task.delay(1.5, function() copyLogBtn.Text = "📋  SALIN LOG" end)
end)

-- info buah
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1,-16,0,70); infoFrame.Position = UDim2.new(0,8,1,-256)
infoFrame.BackgroundColor3 = Color3.fromRGB(14,14,14); infoFrame.BorderSizePixel = 0; infoFrame.Parent = main
Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0,6)
Instance.new("UIStroke", infoFrame).Color = Color3.fromRGB(40,40,40)

local infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1,-8,1,0); infoLbl.Position = UDim2.new(0,8,0,0)
infoLbl.BackgroundTransparency = 1; infoLbl.Text = "Tekan SCAN dulu"
infoLbl.Font = Enum.Font.Code; infoLbl.TextSize = 11
infoLbl.TextColor3 = Color3.fromRGB(160,160,160)
infoLbl.TextXAlignment = Enum.TextXAlignment.Left; infoLbl.TextYAlignment = Enum.TextYAlignment.Top
infoLbl.TextWrapped = true; infoLbl.Parent = infoFrame

-- counter
local cntLbl = Instance.new("TextLabel")
cntLbl.Size = UDim2.new(1,-16,0,22); cntLbl.Position = UDim2.new(0,8,1,-180)
cntLbl.BackgroundTransparency = 1; cntLbl.Text = "Total buah: ?"
cntLbl.Font = Enum.Font.GothamBold; cntLbl.TextSize = 12
cntLbl.TextColor3 = Color3.fromRGB(78,214,204)
cntLbl.TextXAlignment = Enum.TextXAlignment.Left; cntLbl.Parent = main

-- tombol helper
local btnY = {0, 42, 84, 126, 168}
local btnDefs = {
    {label="📋  SCAN Buah Mutasi",             col=Color3.fromRGB(40,40,80),   tcol=Color3.fromRGB(140,160,255)},
    {label="TEST 1: InvokeServer(fruit)",      col=Color3.fromRGB(20,50,20),   tcol=Color3.fromRGB(100,220,100)},
    {label="TEST 2: InvokeServer(prompt)",     col=Color3.fromRGB(50,35,10),   tcol=Color3.fromRGB(230,180,80)},
    {label="TEST 3: InputHoldBegin/End",       col=Color3.fromRGB(50,20,50),   tcol=Color3.fromRGB(200,120,220)},
    {label="🔥 TEST 4: fireproximityprompt",   col=Color3.fromRGB(60,20,10),   tcol=Color3.fromRGB(255,100,60)},
}
local btns = {}
for i, def in ipairs(btnDefs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-16,0,34); b.Position = UDim2.new(0,8,1,-158+btnY[i])
    b.BackgroundColor3 = def.col; b.Text = def.label
    b.Font = Enum.Font.GothamBold; b.TextSize = 12
    b.TextColor3 = def.tcol; b.AutoButtonColor = false; b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
    local bst = Instance.new("UIStroke", b); bst.Color = def.tcol; bst.Thickness = 1; bst.Transparency = 0.6
    btns[i] = b
end

local function setBusy(b)
    _busy = b
    for _, btn in ipairs(btns) do btn.AutoButtonColor = not b end
end

local function updateCount()
    local n = countFruits()
    cntLbl.Text = "Total buah di kebun: " .. n
    return n
end

-- SCAN
btns[1].MouseButton1Click:Connect(function()
    if _busy then return end
    setBusy(true)
    addLog("── SCAN ──", Color3.fromRGB(78,214,204))
    local list = scanAllMutasi()
    addLog("Buah mutasi: " .. #list)
    updateCount()
    if #list == 0 then
        infoLbl.Text = "Tidak ada buah mutasi!"
        addLog("Tidak ada buah mutasi ditemukan", Color3.fromRGB(220,80,80))
        _fruit = nil; _prompt = nil
        setBusy(false); return
    end
    -- ambil buah pertama
    _fruit = list[1].fruit
    _prompt = getPrompt(_fruit)
    -- tampilkan semua buah mutasi (ringkas)
    addLog("Daftar buah mutasi (" .. #list .. " buah):", Color3.fromRGB(255,200,80))
    local mutCount = {}
    for _, item in ipairs(list) do
        mutCount[item.mut] = (mutCount[item.mut] or 0) + 1
    end
    for mut, cnt in pairs(mutCount) do
        addLog("  " .. mut .. " × " .. cnt, Color3.fromRGB(255,200,80))
    end

    -- detail buah pertama
    addLog("── Detail buah[1] ──", Color3.fromRGB(160,160,160))
    addLog("Path: " .. _fruit:GetFullName())
    -- pisah: attr yang dianggap MUTASI vs NON-MUTASI
    local mutAttrs = {}; local sysAttrs = {}
    for k, v in pairs(_fruit:GetAttributes()) do
        if type(v) == "boolean" and v == true and not SKIP[k] then
            table.insert(mutAttrs, k)
        else
            table.insert(sysAttrs, k.."="..tostring(v))
        end
    end
    table.sort(mutAttrs); table.sort(sysAttrs)
    addLog("🔴 MUTASI (boolean true, bukan skip): " .. (#mutAttrs>0 and table.concat(mutAttrs,", ") or "NONE"), Color3.fromRGB(255,120,120))
    addLog("⚪ System/lain: " .. table.concat(sysAttrs, " | "), Color3.fromRGB(130,130,130))
    addLog("Prompt: " .. (_prompt and _prompt:GetFullName() or "NIL"), Color3.fromRGB(160,160,160))
    addLog("harvestRE: " .. (harvestRE and harvestRE:GetFullName() or "NIL!"), Color3.fromRGB(160,160,160))

    infoLbl.Text = "🍇 " .. _fruit.Name .. "\nMUTASI: " .. table.concat(mutAttrs, ", ") .. "\nSYS: " .. table.concat(sysAttrs, " | ")
    setBusy(false)
end)

-- TEST 1: InvokeServer(fruit)
btns[2].MouseButton1Click:Connect(function()
    if _busy then return end
    if not _fruit then addLog("SCAN dulu!", Color3.fromRGB(220,80,80)); return end
    if not harvestRE then addLog("harvestRE NIL!", Color3.fromRGB(220,80,80)); return end
    setBusy(true)
    local before = updateCount()
    addLog("── TEST 1: InvokeServer(fruit) ──", Color3.fromRGB(100,220,100))
    local ok, err = pcall(function() harvestRE:InvokeServer(_fruit) end)
    addLog("pcall: ok="..tostring(ok).." | "..tostring(err))
    task.wait(1.5)
    local after = updateCount()
    local delta = before - after
    local col = delta > 0 and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,80,80)
    addLog("Berkurang: " .. delta .. " buah", col)
    if delta > 0 then addLog("✅ BERHASIL! InvokeServer(fruit)", col)
    else addLog("❌ Tidak ada perubahan", col) end
    setBusy(false)
end)

-- TEST 2: InvokeServer(prompt)
btns[3].MouseButton1Click:Connect(function()
    if _busy then return end
    if not _fruit then addLog("SCAN dulu!", Color3.fromRGB(220,80,80)); return end
    if not harvestRE then addLog("harvestRE NIL!", Color3.fromRGB(220,80,80)); return end
    if not _prompt then addLog("Prompt NIL!", Color3.fromRGB(220,80,80)); return end
    setBusy(true)
    local before = updateCount()
    addLog("── TEST 2: InvokeServer(prompt) ──", Color3.fromRGB(230,180,80))
    local ok, err = pcall(function() harvestRE:InvokeServer(_prompt) end)
    addLog("pcall: ok="..tostring(ok).." | "..tostring(err))
    task.wait(1.5)
    local after = updateCount()
    local delta = before - after
    local col = delta > 0 and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,80,80)
    addLog("Berkurang: " .. delta .. " buah", col)
    if delta > 0 then addLog("✅ BERHASIL! InvokeServer(prompt)", col)
    else addLog("❌ Tidak ada perubahan", col) end
    setBusy(false)
end)

-- TEST 3: InputHoldBegin/End
btns[4].MouseButton1Click:Connect(function()
    if _busy then return end
    if not _fruit then addLog("SCAN dulu!", Color3.fromRGB(220,80,80)); return end
    if not _prompt then addLog("Prompt NIL!", Color3.fromRGB(220,80,80)); return end
    setBusy(true)
    local before = updateCount()
    addLog("── TEST 3: InputHoldBegin/End ──", Color3.fromRGB(200,120,220))
    local ok, err = pcall(function()
        _prompt:InputHoldBegin(); task.wait(0.1); _prompt:InputHoldEnd()
    end)
    addLog("pcall: ok="..tostring(ok).." | "..tostring(err))
    task.wait(1.5)
    local after = updateCount()
    local delta = before - after
    local col = delta > 0 and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,80,80)
    addLog("Berkurang: " .. delta .. " buah", col)
    if delta > 0 then addLog("✅ BERHASIL! InputHoldBegin/End", col)
    else addLog("❌ Tidak ada perubahan", col) end
    setBusy(false)
end)

-- TEST 4: fireproximityprompt
btns[5].MouseButton1Click:Connect(function()
    if _busy then return end
    if not _fruit then addLog("SCAN dulu!", Color3.fromRGB(220,80,80)); return end
    if not _prompt then addLog("Prompt NIL! (buah tidak punya PP)", Color3.fromRGB(220,80,80)); return end
    if not fireproximityprompt then
        addLog("❌ fireproximityprompt tidak ada (exploit tidak support)!", Color3.fromRGB(220,80,80))
        return
    end
    setBusy(true)
    local before = updateCount()
    addLog("── TEST 4: fireproximityprompt ──", Color3.fromRGB(255,100,60))
    addLog("Prompt: " .. _prompt:GetFullName(), Color3.fromRGB(180,180,180))
    -- disable line-of-sight dulu biar bisa dari jauh
    local losOk, losErr = pcall(function() _prompt.RequiresLineOfSight = false end)
    addLog("RequiresLineOfSight=false: " .. tostring(losOk) .. (losOk and "" or " | "..tostring(losErr)), Color3.fromRGB(180,180,180))
    -- fire
    local ok, err = pcall(fireproximityprompt, _prompt)
    addLog("pcall fireproximityprompt: ok="..tostring(ok).." | "..tostring(err))
    task.wait(1.5)
    local after = updateCount()
    local delta = before - after
    local col = delta > 0 and Color3.fromRGB(100,220,100) or Color3.fromRGB(220,80,80)
    addLog("Berkurang: " .. delta .. " buah", col)
    if delta > 0 then
        addLog("✅ BERHASIL! fireproximityprompt WORKS — uplevelnew v8.111 siap dipakai!", col)
    else
        addLog("❌ Tidak ada perubahan — fireproximityprompt gagal", col)
        addLog("  Coba: dekat ke buah dulu, atau PP RequiresLineOfSight masih true", Color3.fromRGB(200,150,80))
    end
    setBusy(false)
end)

-- ===================== SNIFF LISTEN =====================
-- Pasang OnClientEvent/OnClientInvoke di semua RemoteEvent/RemoteFunction di RS
-- Tangkap server→client callback setelah collect — TANPA hook __namecall
local _sniffing = false
local _sniffConns = {}
local _sniffBtn = Instance.new("TextButton")
_sniffBtn.Size = UDim2.new(1,-16,0,28)
_sniffBtn.BackgroundColor3 = Color3.fromRGB(50,20,20)
_sniffBtn.Text = "🎯 LISTEN — pasang listener semua RS remote"
_sniffBtn.Font = Enum.Font.GothamBold; _sniffBtn.TextSize = 11
_sniffBtn.TextColor3 = Color3.fromRGB(255,80,80); _sniffBtn.AutoButtonColor = false
_sniffBtn.TextWrapped = true; _sniffBtn.Parent = main
_sniffBtn.Position = UDim2.new(0,8,0,44)
logFrame.Position = UDim2.new(0,8,0,80)
logFrame.Size = UDim2.new(1,-16,1,-284)
Instance.new("UICorner", _sniffBtn).CornerRadius = UDim.new(0,6)

_sniffBtn.MouseButton1Click:Connect(function()
    if _sniffing then
        -- disconnect semua
        for _, c in ipairs(_sniffConns) do pcall(function() c:Disconnect() end) end
        _sniffConns = {}
        _sniffing = false
        _sniffBtn.Text = "🎯 LISTEN — pasang listener semua RS remote"
        _sniffBtn.TextColor3 = Color3.fromRGB(255,80,80)
        addLog("── LISTEN berhenti ──", Color3.fromRGB(160,160,160))
        return
    end

    _sniffing = true
    _sniffBtn.Text = "⏹ LISTEN aktif — collect buah manual sekarang!"
    _sniffBtn.TextColor3 = Color3.fromRGB(100,255,100)
    addLog("── LISTEN aktif ──", Color3.fromRGB(255,80,80))
    addLog("Pasang listener di semua RS remote...", Color3.fromRGB(200,200,200))

    local count = 0
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local name = v.Name
            local ok, conn = pcall(function()
                return v.OnClientEvent:Connect(function(...)
                    local args = {...}
                    addLog("📡 OnClientEvent: "..name, Color3.fromRGB(100,255,100))
                    for i, a in ipairs(args) do
                        local info = typeof(a) == "Instance" and a:GetFullName() or tostring(a)
                        addLog("  ["..i.."] "..typeof(a).."="..info, Color3.fromRGB(255,220,100))
                        if typeof(a) == "Instance" then
                            local _, attrs = pcall(function() return a:GetAttributes() end)
                            if attrs then
                                local at = {}
                                for k,vv in pairs(attrs) do table.insert(at, k.."="..tostring(vv)) end
                                if #at>0 then addLog("   attrs: "..table.concat(at," | "), Color3.fromRGB(200,200,100)) end
                            end
                        end
                    end
                end)
            end)
            if ok and conn then table.insert(_sniffConns, conn); count += 1 end
        elseif v:IsA("RemoteFunction") then
            local name = v.Name
            -- wrap OnClientInvoke
            pcall(function()
                v.OnClientInvoke = function(...)
                    local args = {...}
                    addLog("📡 OnClientInvoke: "..name, Color3.fromRGB(100,255,200))
                    for i, a in ipairs(args) do
                        local info = typeof(a) == "Instance" and a:GetFullName() or tostring(a)
                        addLog("  ["..i.."] "..typeof(a).."="..info, Color3.fromRGB(255,220,100))
                    end
                end
            end)
            count += 1
        end
    end

    addLog("Listener terpasang di "..count.." remote", Color3.fromRGB(100,255,100))
    addLog("Collect 1 buah manual sekarang (klik/E di buah)", Color3.fromRGB(255,200,80))
    addLog("Kalau tidak ada log baru = game pakai PP server-side murni", Color3.fromRGB(160,160,160))
end)

addLog("Script loaded. Tekan SCAN dulu.", Color3.fromRGB(78,214,204))
if not harvestRE then
    addLog("⚠️ HarvestRemote tidak ditemukan di GameEvents!", Color3.fromRGB(220,80,80))
else
    addLog("HarvestRemote OK: " .. harvestRE:GetFullName(), Color3.fromRGB(100,220,100))
end
