-- debug_equip_manual.lua — test equip/unequip manual + spy semua RE
-- Paste UUID di box, klik EQUIP atau UNEQUIP, lihat log

local plr = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")

-- ── spy semua RemoteEvent outgoing via __namecall hook ───────────────────────
local spyLog = {}
local function addSpy(msg)
    table.insert(spyLog, 1, string.format("%.1f", os.clock() % 1000) .. "  " .. msg)
    if #spyLog > 60 then spyLog[#spyLog] = nil end
end

local origNamecall = nil
origNamecall = hookmetamethod and hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod and getnamecallmethod() or ""
    if method == "FireServer" and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
        -- filter: skip RE noise (Input, Activation, HB, Heartbeat, Step)
        local n = self.Name
        local skip = (n=="Input" or n=="Activation" or n=="Heartbeat" or n=="HB" or n=="Step" or n=="Ping")
        if not skip then
            local args = {...}
            local argStr = ""
            for i, a in ipairs(args) do
                argStr = argStr .. (i > 1 and " | " or "") .. tostring(a):sub(1, 80)
            end
            addSpy("FIRE ["..n.."] "..argStr)
        end
    end
    return origNamecall(self, ...)
end)

-- ── cari PetsService RE ───────────────────────────────────────────────────────
local _re = nil
local function findRE()
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name == "PetsService" and v:IsA("RemoteEvent") then return v end
    end
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name == "PetsService" then return v end
    end
    return nil
end
_re = findRE()
task.spawn(function()
    for _ = 1, 20 do
        if _re then break end
        task.wait(1); _re = findRE()
    end
end)

local function fmtUUID(raw) return "{"..raw:gsub("[{}]","").."}" end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DBG_EQUIP"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = plr:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 520, 0, 480)
panel.Position = UDim2.new(0, 8, 0.1, 0)
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = sg

local function lbl(txt, x, y, w, h, col)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, w, 0, h)
    l.Position = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = col or Color3.fromRGB(200, 200, 200)
    l.TextSize = 11
    l.Font = Enum.Font.Code
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = txt
    l.Parent = panel
    return l
end

local function mkBtn(txt, x, y, w, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 22)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = col
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(230, 230, 230)
    b.TextSize = 11
    b.Font = Enum.Font.Code
    b.Parent = panel
    return b
end

lbl("🔧 EQUIP DEBUG — " .. plr.Name, 4, 4, 400, 18, Color3.fromRGB(160, 220, 255))

-- UUID input box
lbl("UUID:", 4, 28, 40, 18, Color3.fromRGB(160, 160, 160))
local tbUUID = Instance.new("TextBox")
tbUUID.Size = UDim2.new(0, 400, 0, 20)
tbUUID.Position = UDim2.new(0, 46, 0, 27)
tbUUID.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
tbUUID.BorderSizePixel = 1
tbUUID.BorderColor3 = Color3.fromRGB(80, 80, 120)
tbUUID.TextColor3 = Color3.fromRGB(220, 220, 100)
tbUUID.TextSize = 10
tbUUID.Font = Enum.Font.Code
tbUUID.Text = "paste uuid disini"
tbUUID.ClearTextOnFocus = true
tbUUID.Parent = panel

-- tombol-tombol
local btnUneq  = mkBtn("⬆ UNEQUIP",    4,  52, 90, Color3.fromRGB(60, 30, 20))
local btnEquip = mkBtn("⬇ EQUIP",     98,  52, 80, Color3.fromRGB(20, 50, 20))
local btnBoth  = mkBtn("🔄 UNEQ+EQ", 182,  52, 95, Color3.fromRGB(30, 30, 70))
local btnClear = mkBtn("🗑 CLEAR",    281,  52, 70, Color3.fromRGB(40, 40, 40))
local btnRejoin = mkBtn("🔁 REJOIN",  356,  52, 80, Color3.fromRGB(60, 30, 60))
local btnClose  = mkBtn("✕",          440,  52, 28, Color3.fromRGB(60, 20, 20))

-- status RE
local lbRE = lbl("RE: ...", 4, 78, 510, 16, Color3.fromRGB(120, 180, 120))

-- log panel
local sf = Instance.new("ScrollingFrame")
sf.Size = UDim2.new(0, 512, 0, 360)
sf.Position = UDim2.new(0, 4, 0, 96)
sf.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 4
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
sf.Parent = panel

local lbLog = Instance.new("TextLabel")
lbLog.Size = UDim2.new(1, -4, 0, 0)
lbLog.AutomaticSize = Enum.AutomaticSize.Y
lbLog.BackgroundTransparency = 1
lbLog.TextColor3 = Color3.fromRGB(180, 220, 180)
lbLog.TextSize = 10
lbLog.Font = Enum.Font.Code
lbLog.TextXAlignment = Enum.TextXAlignment.Left
lbLog.TextWrapped = false
lbLog.Text = "(log kosong)"
lbLog.Parent = sf

-- ── log helper ────────────────────────────────────────────────────────────────
local logLines = {}
local function addLog(msg, col)
    table.insert(logLines, 1, msg)
    if #logLines > 80 then logLines[#logLines] = nil end
    lbLog.Text = table.concat(logLines, "\n")
    if col then lbLog.TextColor3 = col end
end

-- ── update RE status tiap detik ───────────────────────────────────────────────
task.spawn(function()
    while sg and sg.Parent do
        if not _re then _re = findRE() end
        if _re then
            lbRE.Text = "RE: ✓ " .. _re:GetFullName() .. ((_re.Parent and "" or " ⚠ORPHAN"))
            lbRE.TextColor3 = Color3.fromRGB(80, 220, 80)
        else
            lbRE.Text = "RE: ✗ PetsService tidak ditemukan"
            lbRE.TextColor3 = Color3.fromRGB(220, 80, 80)
        end
        task.wait(1)
    end
end)

-- update spy log tiap 0.5s
task.spawn(function()
    while sg and sg.Parent do
        task.wait(0.5)
        -- spy log ditampilkan di bawah manual log dengan separator
        local combined = table.concat(logLines, "\n")
        if #spyLog > 0 then
            combined = combined .. "\n── SPY ──\n" .. table.concat(spyLog, "\n")
        end
        lbLog.Text = combined
    end
end)

-- ── aksi tombol ───────────────────────────────────────────────────────────────
local function getUUID()
    local raw = tbUUID.Text:gsub("[{}%s]", "")
    if raw == "" or raw == "pasteuuiddisini" then
        addLog("⚠ UUID kosong!", Color3.fromRGB(220, 180, 60))
        return nil
    end
    return raw
end

local function doUneq(raw)
    if not _re then _re = findRE() end
    if not _re then addLog("✗ UNEQ: RE tidak ditemukan"); return false end
    if not _re.Parent then
        addLog("✗ UNEQ: RE orphan, refind...")
        _re = findRE()
        if not _re then addLog("✗ UNEQ: refind gagal"); return false end
    end
    local ok, err = pcall(function() _re:FireServer("UnequipPet", fmtUUID(raw)) end)
    if ok then
        addLog("✓ UNEQ sent: " .. fmtUUID(raw), Color3.fromRGB(100, 220, 100))
    else
        addLog("✗ UNEQ err: " .. tostring(err):sub(1,100), Color3.fromRGB(220, 100, 100))
    end
    return ok
end

local function getSpawnCF()
    -- coba ambil posisi dari HRP player, fallback ke posisi default garden
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        return hrp.CFrame
    end
    return CFrame.new(-190, 0, 60)  -- fallback posisi garden
end

local function doEq(raw)
    if not _re then _re = findRE() end
    if not _re then addLog("✗ EQ: RE tidak ditemukan"); return false end
    if not _re.Parent then addLog("✗ EQ: RE orphan"); return false end
    local cf = getSpawnCF()
    addLog("  CF: " .. tostring(cf):sub(1,60), Color3.fromRGB(160,160,160))
    local ok, err = pcall(function() _re:FireServer("EquipPet", fmtUUID(raw), cf) end)
    if ok then
        addLog("✓ EQ sent: " .. fmtUUID(raw), Color3.fromRGB(100, 220, 100))
    else
        addLog("✗ EQ err: " .. tostring(err):sub(1,100), Color3.fromRGB(220, 100, 100))
    end
    return ok
end

btnUneq.MouseButton1Click:Connect(function()
    local raw = getUUID(); if not raw then return end
    addLog("── MANUAL UNEQUIP ──")
    doUneq(raw)
end)

btnEquip.MouseButton1Click:Connect(function()
    local raw = getUUID(); if not raw then return end
    addLog("── MANUAL EQUIP ──")
    doEq(raw)
end)

btnBoth.MouseButton1Click:Connect(function()
    local raw = getUUID(); if not raw then return end
    addLog("── MANUAL UNEQ+EQ ──")
    task.spawn(function()
        doUneq(raw)
        task.wait(0.1)
        doEq(raw)
    end)
end)

btnClear.MouseButton1Click:Connect(function()
    logLines = {}
    spyLog = {}
    lbLog.Text = "(cleared)"
end)

btnRejoin.MouseButton1Click:Connect(function()
    btnRejoin.Text = "⟳ joining..."
    btnRejoin.BackgroundColor3 = Color3.fromRGB(80, 20, 80)
    task.spawn(function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, plr)
        end)
    end)
end)

local btnCopy2 = mkBtn("📋 COPY LOG", 282, 52, 90, Color3.fromRGB(30, 50, 70))
btnCopy2.MouseButton1Click:Connect(function()
    local txt = table.concat(logLines, "\n")
    if #spyLog > 0 then txt = txt .. "\n── SPY ──\n" .. table.concat(spyLog, "\n") end
    if txt == "" then return end
    local ok = pcall(function() setclipboard(txt) end)
    if ok then
        btnCopy2.Text = "✓ COPIED"
        task.delay(1.5, function() btnCopy2.Text = "📋 COPY LOG" end)
    else
        -- fallback TextBox
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(0,1,0,1)
        tb.Position = UDim2.new(0,0,2,0)
        tb.BackgroundTransparency = 1
        tb.TextTransparency = 1
        tb.Text = txt
        tb.Parent = panel
        tb:CaptureFocus()
        game:GetService("UserInputService"):SendKeyEvent(true, Enum.KeyCode.A, false, game)
        task.wait(0.05)
        tb:ReleaseFocus()
        tb:Destroy()
        btnCopy2.Text = "✓ OK(fb)"
        task.delay(1.5, function() btnCopy2.Text = "📋 COPY LOG" end)
    end
end)

btnClose.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- tombol test format berbeda
local btnUneqRaw = mkBtn("UNEQ raw",   4, 78, 70, Color3.fromRGB(50, 40, 20))
local btnUneqFmt = mkBtn("UNEQ {fmt}", 78, 78, 80, Color3.fromRGB(20, 40, 50))
btnUneqRaw.MouseButton1Click:Connect(function()
    local raw = getUUID(); if not raw then return end
    addLog("── UNEQ tanpa kurung: "..raw)
    local ok, err = pcall(function() _re:FireServer("UnequipPet", raw) end)
    addLog(ok and "✓ sent" or "✗ "..tostring(err):sub(1,80))
end)
btnUneqFmt.MouseButton1Click:Connect(function()
    local raw = getUUID(); if not raw then return end
    local fmt = fmtUUID(raw)
    addLog("── UNEQ dengan {}: "..fmt)
    local ok, err = pcall(function() _re:FireServer("UnequipPet", fmt) end)
    addLog(ok and "✓ sent" or "✗ "..tostring(err):sub(1,80))
end)

addLog("ready — paste UUID lalu klik tombol")
print("[debug_equip_manual] aktif")
