-- ============================================================
-- ZENX AGE STATS v2.0
-- Tab [STATS] / [GIFT]
-- STATS: per-type pet count (age 100 vs <100)
-- GIFT : auto-gift pet age 100 ke target player (recent targets saved)
-- ============================================================

local Players    = game:GetService("Players")
local CoreGui    = game:GetService("CoreGui")
local RS         = game:GetService("ReplicatedStorage")
local HS         = game:GetService("HttpService")
local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui", 10)
local VER = "v2.19"
local TARGETS_FILE = "ZenxAgeStats_targets.json"
local SETTINGS_FILE = "ZenxAgeStats_settings.json"
local MAX_RECENT = 8

-- ===== CLEANUP =====
local function cleanup()
    for _, p in ipairs({playerGui, CoreGui}) do
        for _, c in ipairs(p:GetChildren()) do
            if c.Name == "ZenxAgeStats" then pcall(function() c:Destroy() end) end
        end
    end
    pcall(function()
        if gethui then
            for _, c in ipairs(gethui():GetChildren()) do
                if c.Name == "ZenxAgeStats" then c:Destroy() end
            end
        end
    end)
end
cleanup()

-- ============================================================
-- MEMORY CONTAINER (getgc bypass)
-- ============================================================
local function findMemoryContainer()
    if not getgc then return nil, 0 end
    -- v2.9: Get backpack UUIDs to find the RIGHT container (yg sesuai pet user)
    local backpackUUIDs = {}
    local bpCount = 0
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local u = t:GetAttribute("PET_UUID")
                if u then
                    local k = tostring(u)
                    if k:sub(1,1) ~= "{" then k = "{"..k.."}" end
                    backpackUUIDs[k] = true
                    bpCount = bpCount + 1
                end
            end
        end
    end

    local best, bestCount, bestMatch = nil, 0, 0
    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                -- Count UUID-like keys AND how many match backpack
                local uuidLike, matchCount = 0, 0
                for k in pairs(obj) do
                    if type(k) == "string" and #k >= 32 and k:find("-") then
                        uuidLike = uuidLike + 1
                        if backpackUUIDs[k] then matchCount = matchCount + 1 end
                        if uuidLike >= 50 and matchCount == 0 then break end
                    end
                end
                if uuidLike >= 5 then
                    local sample = nil
                    for _, v in pairs(obj) do sample = v; break end
                    if type(sample) == "table" and rawget(sample, "PetData") then
                        local cnt = 0
                        for _ in pairs(obj) do cnt = cnt + 1 end
                        -- Prefer container with MORE matches to backpack
                        -- Fallback: if backpack empty, use largest
                        local better = false
                        if bpCount > 0 then
                            if matchCount > bestMatch then better = true
                            elseif matchCount == bestMatch and cnt > bestCount then better = true end
                        else
                            if cnt > bestCount then better = true end
                        end
                        if better then
                            best = obj
                            bestCount = cnt
                            bestMatch = matchCount
                        end
                    end
                end
            end
        end
    end)
    if best then
        print("[ZenxAgeStats] container: "..bestCount.." entries, "..bestMatch.."/"..bpCount.." backpack match")
    end
    return best, bestCount
end

local MUTATION_PREFIXES = {
    "Everchanted ","Rainbow ","Frozen ","Inverted ","Golden ","Diamond ",
    "Mythical ","Hexed ","Ascended ","Radiant ","Shocked ","Bloodlit ",
    "Twilight ","Voidtouched ","Foxfire ","Aurora ","Static ","Stormcloud ",
    "Frost ","Burnt ","Lethal ","Cooked ","Choc ",
}
local function stripMutation(s)
    if not s then return "" end
    for _, p in ipairs(MUTATION_PREFIXES) do
        if s:sub(1, #p) == p then return s:sub(#p + 1) end
    end
    return s
end

local function getPetLevel(container, uuid)
    if not container or not uuid then return 0 end
    local key = tostring(uuid)
    if key:sub(1,1) ~= "{" then key = "{"..key.."}" end
    local entry = container[key]
    if type(entry) == "table" and entry.PetData and entry.PetData.Level then
        return tonumber(entry.PetData.Level) or 0
    end
    return 0
end

local function collectStats(container)
    local byType, total, age100, lessAge = {}, 0, 0, 0
    local bp = player:FindFirstChild("Backpack")
    if not bp then return byType, total, age100, lessAge end
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            local uuid = tool:GetAttribute("PET_UUID")
            if uuid then
                local pType = stripMutation(tostring(tool:GetAttribute("f") or "?"))
                local level = getPetLevel(container, uuid)
                if not byType[pType] then byType[pType] = {age100=0, less100=0} end
                if level >= 100 then
                    byType[pType].age100 = byType[pType].age100 + 1
                    age100 = age100 + 1
                else
                    byType[pType].less100 = byType[pType].less100 + 1
                    lessAge = lessAge + 1
                end
                total = total + 1
            end
        end
    end
    return byType, total, age100, lessAge
end

-- ============================================================
-- RECENT TARGETS (persistence)
-- ============================================================
local function loadTargets()
    local ok, content = pcall(function()
        if isfile and readfile and isfile(TARGETS_FILE) then return readfile(TARGETS_FILE) end
        return nil
    end)
    if not ok or not content then return {} end
    local ok2, data = pcall(function() return HS:JSONDecode(content) end)
    if ok2 and type(data) == "table" then return data end
    return {}
end

local function saveTargets(list)
    pcall(function()
        if writefile then writefile(TARGETS_FILE, HS:JSONEncode(list)) end
    end)
end

local function addRecentTarget(name)
    if not name or name == "" then return end
    local list = loadTargets()
    -- remove duplicate
    for i = #list, 1, -1 do
        if (list[i] or ""):lower() == name:lower() then table.remove(list, i) end
    end
    -- prepend
    table.insert(list, 1, name)
    -- trim to MAX_RECENT
    while #list > MAX_RECENT do table.remove(list) end
    saveTargets(list)
end

local function removeRecentTarget(name)
    local list = loadTargets()
    for i = #list, 1, -1 do
        if (list[i] or ""):lower() == name:lower() then table.remove(list, i) end
    end
    saveTargets(list)
end

-- ============================================================
-- GIFT SETTINGS (persist across rejoin)
-- ============================================================
local function loadSettings()
    local ok, content = pcall(function()
        if isfile and readfile and isfile(SETTINGS_FILE) then return readfile(SETTINGS_FILE) end
        return nil
    end)
    if not ok or not content then return {} end
    local ok2, data = pcall(function() return HS:JSONDecode(content) end)
    if ok2 and type(data) == "table" then return data end
    return {}
end

local function saveSettings(s)
    pcall(function()
        if writefile then writefile(SETTINGS_FILE, HS:JSONEncode(s)) end
    end)
end

-- ============================================================
-- GIFT LOGIC (dari rainbow leveling)
-- ============================================================
local giftRE = nil
local PGS = nil  -- PetGiftingService module
pcall(function()
    local ge = RS:FindFirstChild("GameEvents")
    if ge then giftRE = ge:FindFirstChild("PetGiftingService") end
    if not giftRE then giftRE = RS:FindFirstChild("PetGiftingService", true) end
end)
pcall(function()
    local mods = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("PetServices")
    local gm = mods and mods:FindFirstChild("PetGiftingInputService")
    if gm then
        local ok, mod = pcall(require, gm)
        if ok then PGS = mod end
    end
end)

local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local low = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (p.Name:lower() == low or p.DisplayName:lower() == low) then
            return p
        end
    end
    -- partial match
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (p.Name:lower():find(low, 1, true) or p.DisplayName:lower():find(low, 1, true)) then
            return p
        end
    end
    return nil
end

local function giftPetToPlayer(targetPlayer, petTool)
    if not targetPlayer or not petTool then return false end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    -- Unequip current tools
    pcall(function() hum:UnequipTools() end)
    task.wait(0.1)
    -- Equip the pet
    pcall(function() hum:EquipTool(petTool) end)
    task.wait(0.25)

    -- Try module path first
    local sent = false
    if PGS and PGS.GivePet then
        pcall(function() PGS.GivePet(targetPlayer) end)
        task.wait(0.4)
        if not petTool.Parent or petTool.Parent == nil then sent = true end
    end
    -- Fallback: remote
    if not sent and giftRE then
        local uuid = petTool:GetAttribute("PET_UUID")
        local u = tostring(uuid)
        if u:sub(1,1) ~= "{" then u = "{"..u.."}" end
        pcall(function() giftRE:FireServer("GivePet", targetPlayer, u) end)
        task.wait(0.4)
        if not petTool.Parent or petTool.Parent == nil then sent = true end
        if not sent then
            pcall(function() giftRE:FireServer("GivePet", targetPlayer) end)
            task.wait(0.4)
            if not petTool.Parent or petTool.Parent == nil then sent = true end
        end
    end
    return sent
end

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    BG     = Color3.fromRGB(18, 18, 18),
    Panel  = Color3.fromRGB(28, 28, 28),
    Card   = Color3.fromRGB(36, 36, 36),
    Accent = Color3.fromRGB(255, 200, 0),
    Text   = Color3.fromRGB(230, 230, 230),
    Dim    = Color3.fromRGB(140, 140, 140),
    Green  = Color3.fromRGB(100, 200, 120),
    Orange = Color3.fromRGB(255, 140, 60),
    Red    = Color3.fromRGB(220, 80, 80),
    Blue   = Color3.fromRGB(80, 130, 200),
}

-- ============================================================
-- ScreenGui
-- ============================================================
local sg = Instance.new("ScreenGui")
sg.Name = "ZenxAgeStats"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 9999
local parented = false
pcall(function() if gethui then sg.Parent = gethui(); parented = true end end)
if not parented then sg.Parent = playerGui end

-- ============================================================
-- DIMENSIONS
-- ============================================================
local W = 400
local TITLE_H = 34
local HEADER_H = 80
local TAB_H = 30
local CONTENT_H = 180  -- v2.5: lebih compact, scroll buat baris ke 5+
local FOOTER_H = 22

local COLLAPSED_HEIGHT = TITLE_H + 8 + HEADER_H + 8  -- ~ 104 (just header)
local EXPANDED_HEIGHT  = COLLAPSED_HEIGHT + TAB_H + 6 + CONTENT_H + 4 + FOOTER_H

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local main = Instance.new("Frame")
main.Size = UDim2.new(0, W, 0, EXPANDED_HEIGHT)
main.Position = UDim2.new(0, 10, 0.5, -EXPANDED_HEIGHT/2)
main.BackgroundColor3 = C.BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = C.Accent
mainStroke.Thickness = 1.5

-- ============================================================
-- TITLE BAR
-- ============================================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.Panel
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 10)
tbFix.Position = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = C.Panel
tbFix.BorderSizePixel = 0
tbFix.Parent = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -98, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "ZENX AGE STATS "..VER
titleLbl.TextColor3 = C.Accent
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local function mkTitleBtn(x, txt, color, txtColor)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 22)
    b.Position = UDim2.new(1, x, 0.5, -11)
    b.BackgroundColor3 = color
    b.Text = txt b.TextColor3 = txtColor or Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = titleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local expandBtn = mkTitleBtn(-92, "+", C.Accent, Color3.new(0,0,0))
local minBtn    = mkTitleBtn(-62, "—", C.Blue)
local closeBtn  = mkTitleBtn(-32, "✕", C.Red)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- ============================================================
-- HEADER STATS
-- ============================================================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, -16, 0, HEADER_H)
header.Position = UDim2.new(0, 8, 0, TITLE_H + 8)
header.BackgroundColor3 = C.Card
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

local function mkStat(parent, x, w, labelText, valColor)
    local cell = Instance.new("Frame")
    cell.Size = UDim2.new(w, 0, 1, 0)
    cell.Position = UDim2.new(x, 0, 0, 0)
    cell.BackgroundTransparency = 1
    cell.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 18)
    t.Position = UDim2.new(0, 0, 0, 8)
    t.BackgroundTransparency = 1
    t.Text = labelText t.TextColor3 = C.Dim
    t.Font = Enum.Font.Gotham t.TextSize = 17  -- v2.15: label
    t.Parent = cell
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, 0, 0, 48)
    v.Position = UDim2.new(0, 0, 0, 28)
    v.BackgroundTransparency = 1
    v.Text = "0" v.TextColor3 = valColor or C.Text
    v.Font = Enum.Font.GothamBold v.TextSize = 44  -- v2.15: ANGKA gede banget
    v.Parent = cell
    return v
end
local totalVal  = mkStat(header, 0,    0.33, "TOTAL",     C.Text)
local age100Val = mkStat(header, 0.33, 0.33, "AGE 100",   C.Text)
local lessVal   = mkStat(header, 0.66, 0.33, "AGE <100",  C.Text)

-- ============================================================
-- TAB ROW [STATS] [GIFT]
-- ============================================================
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -16, 0, TAB_H)
tabRow.Position = UDim2.new(0, 8, 0, TITLE_H + 8 + HEADER_H + 6)
tabRow.BackgroundTransparency = 1
tabRow.Parent = main

local function mkTabBtn(x, w, label)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(w, -3, 1, 0)
    b.Position = UDim2.new(x, x > 0 and 3 or 0, 0, 0)
    b.BackgroundColor3 = C.Card
    b.Text = label
    b.TextColor3 = C.Dim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = tabRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local tabStatsBtn = mkTabBtn(0,    0.5, "STATS")
local tabGiftBtn  = mkTabBtn(0.5,  0.5, "GIFT")

-- ============================================================
-- CONTENT AREAS (statsPanel / giftPanel)
-- ============================================================
local CONTENT_Y = TITLE_H + 8 + HEADER_H + 6 + TAB_H + 6

-- ===== STATS PANEL =====
local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(1, -16, 0, CONTENT_H)
statsPanel.Position = UDim2.new(0, 8, 0, CONTENT_Y)
statsPanel.BackgroundTransparency = 1
statsPanel.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, 0, 0, 28)
searchBox.BackgroundColor3 = C.Card
searchBox.Text = ""
searchBox.PlaceholderText = "Cari jenis pet..."
searchBox.PlaceholderColor3 = C.Dim
searchBox.TextColor3 = C.Text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.BorderSizePixel = 0
searchBox.Parent = statsPanel
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
local sPad = Instance.new("UIPadding", searchBox)
sPad.PaddingLeft = UDim.new(0, 10)

local colHeader = Instance.new("Frame")
colHeader.Size = UDim2.new(1, 0, 0, 22)
colHeader.Position = UDim2.new(0, 0, 0, 34)
colHeader.BackgroundColor3 = C.Panel
colHeader.BorderSizePixel = 0
colHeader.Parent = statsPanel
Instance.new("UICorner", colHeader).CornerRadius = UDim.new(0, 4)

local function mkColLbl(parent, x, w, text, color, align)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(w, 0, 1, 0)
    l.Position = UDim2.new(x, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text l.TextColor3 = color
    l.Font = Enum.Font.GothamBold l.TextSize = 10
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.Parent = parent
    return l
end
mkColLbl(colHeader, 0.03, 0.47, "PET (tap=multi)", C.Accent, Enum.TextXAlignment.Left)
mkColLbl(colHeader, 0.50, 0.16, "AGE100",  C.Text)
mkColLbl(colHeader, 0.66, 0.14, "<100",    C.Text)
mkColLbl(colHeader, 0.80, 0.17, "TOTAL",   C.Text)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -60)
scroll.Position = UDim2.new(0, 0, 0, 60)
scroll.BackgroundColor3 = C.Card
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = C.Accent
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = statsPanel
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll
local listPad = Instance.new("UIPadding", scroll)
listPad.PaddingTop = UDim.new(0, 4) listPad.PaddingBottom = UDim.new(0, 4)
listPad.PaddingLeft = UDim.new(0, 4) listPad.PaddingRight = UDim.new(0, 4)

-- ===== GIFT PANEL =====
local giftPanel = Instance.new("Frame")
giftPanel.Size = UDim2.new(1, -16, 0, CONTENT_H)
giftPanel.Position = UDim2.new(0, 8, 0, CONTENT_Y)
giftPanel.BackgroundTransparency = 1
giftPanel.Visible = false
giftPanel.Parent = main

-- Target input — NODE HUB style picker
local targetLbl = Instance.new("TextLabel")
targetLbl.Size = UDim2.new(1, 0, 0, 16)
targetLbl.Position = UDim2.new(0, 0, 0, 0)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = "Target Player"
targetLbl.TextColor3 = C.Dim
targetLbl.Font = Enum.Font.GothamBold
targetLbl.TextSize = 10
targetLbl.TextXAlignment = Enum.TextXAlignment.Left
targetLbl.Parent = giftPanel

-- Target picker button (click to open modal)
local targetBtn = Instance.new("TextButton")
targetBtn.Size = UDim2.new(1, 0, 0, 32)
targetBtn.Position = UDim2.new(0, 0, 0, 18)
targetBtn.BackgroundColor3 = C.Card
targetBtn.Text = "Pilih target gift..."
targetBtn.TextColor3 = C.Dim
targetBtn.Font = Enum.Font.Gotham
targetBtn.TextSize = 12
targetBtn.TextXAlignment = Enum.TextXAlignment.Left
targetBtn.BorderSizePixel = 0
targetBtn.AutoButtonColor = false
targetBtn.Parent = giftPanel
Instance.new("UICorner", targetBtn).CornerRadius = UDim.new(0, 4)
local tbPad = Instance.new("UIPadding", targetBtn)
tbPad.PaddingLeft = UDim.new(0, 10)
tbPad.PaddingRight = UDim.new(0, 10)
-- arrow indicator
local arrowLbl = Instance.new("TextLabel")
arrowLbl.Size = UDim2.new(0, 20, 1, 0)
arrowLbl.Position = UDim2.new(1, -28, 0, 0)
arrowLbl.BackgroundTransparency = 1
arrowLbl.Text = "▼"
arrowLbl.TextColor3 = C.Dim
arrowLbl.Font = Enum.Font.Gotham
arrowLbl.TextSize = 10
arrowLbl.Parent = targetBtn

-- Current selected targets (multi-select set: {[name]=true})
local selectedTargets = {}
local function targetCount()
    local n = 0; for _ in pairs(selectedTargets) do n = n + 1 end; return n
end

-- ============================================================
-- FILTER ROW: jenis pet | KG | Age
-- ============================================================
-- Pet picker button (col 1)
local petPickBtn = Instance.new("TextButton")
petPickBtn.Size = UDim2.new(0.46, -2, 0, 30)
petPickBtn.Position = UDim2.new(0, 0, 0, 58)
petPickBtn.BackgroundColor3 = C.Card
petPickBtn.Text = "Jenis Pet ▼"
petPickBtn.TextColor3 = C.Dim
petPickBtn.Font = Enum.Font.Gotham
petPickBtn.TextSize = 11
petPickBtn.TextXAlignment = Enum.TextXAlignment.Left
petPickBtn.BorderSizePixel = 0
petPickBtn.AutoButtonColor = false
petPickBtn.Parent = giftPanel
Instance.new("UICorner", petPickBtn).CornerRadius = UDim.new(0, 4)
local ppPad = Instance.new("UIPadding", petPickBtn)
ppPad.PaddingLeft = UDim.new(0, 8) ppPad.PaddingRight = UDim.new(0, 8)

-- KG input (col 2)
local kgBox = Instance.new("TextBox")
kgBox.Size = UDim2.new(0.25, -2, 0, 30)
kgBox.Position = UDim2.new(0.48, 0, 0, 58)
kgBox.BackgroundColor3 = C.Card
kgBox.Text = ""
kgBox.PlaceholderText = "KG"
kgBox.PlaceholderColor3 = C.Dim
kgBox.TextColor3 = C.Text
kgBox.Font = Enum.Font.Gotham
kgBox.TextSize = 12
kgBox.TextXAlignment = Enum.TextXAlignment.Center
kgBox.ClearTextOnFocus = false
kgBox.BorderSizePixel = 0
kgBox.Parent = giftPanel
Instance.new("UICorner", kgBox).CornerRadius = UDim.new(0, 4)

-- Age input (col 3)
local ageBox = Instance.new("TextBox")
ageBox.Size = UDim2.new(0.25, -2, 0, 30)
ageBox.Position = UDim2.new(0.75, 2, 0, 58)
ageBox.BackgroundColor3 = C.Card
ageBox.Text = ""
ageBox.PlaceholderText = "Age"
ageBox.PlaceholderColor3 = C.Dim
ageBox.TextColor3 = C.Text
ageBox.Font = Enum.Font.Gotham
ageBox.TextSize = 12
ageBox.TextXAlignment = Enum.TextXAlignment.Center
ageBox.ClearTextOnFocus = false
ageBox.BorderSizePixel = 0
ageBox.Parent = giftPanel
Instance.new("UICorner", ageBox).CornerRadius = UDim.new(0, 4)

-- Filter state
local selectedPetTypes = {}  -- multi-select set: {[petName]=true}
local function petTypeCount()
    local n = 0; for _ in pairs(selectedPetTypes) do n = n + 1 end; return n
end

-- ============================================================
-- GIFT ON/OFF TOGGLE
-- ============================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 0, 34)
toggleBtn.Position = UDim2.new(0, 0, 0, 96)
toggleBtn.BackgroundColor3 = C.Red
toggleBtn.Text = "GIFT  OFF"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = giftPanel
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 5)

-- Status
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 18)
statusLbl.Position = UDim2.new(0, 0, 0, 138)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: idle"
statusLbl.TextColor3 = C.Dim
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = giftPanel

-- Counter
local gCounterLbl = Instance.new("TextLabel")
gCounterLbl.Size = UDim2.new(1, 0, 0, 18)
gCounterLbl.Position = UDim2.new(0, 0, 0, 158)
gCounterLbl.BackgroundTransparency = 1
gCounterLbl.Text = "Sent: 0   Failed: 0"
gCounterLbl.TextColor3 = C.Accent
gCounterLbl.Font = Enum.Font.GothamBold
gCounterLbl.TextSize = 11
gCounterLbl.TextXAlignment = Enum.TextXAlignment.Left
gCounterLbl.Parent = giftPanel

-- legacy stub
local eligibleLbl = {Text = ""}

-- ============================================================
-- FOOTER
-- ============================================================
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -16, 0, 16)
footer.Position = UDim2.new(0, 8, 1, -FOOTER_H + 4)
footer.BackgroundTransparency = 1
footer.Text = "scope: backpack • auto 2s"
footer.TextColor3 = C.Dim
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Parent = main

-- ============================================================
-- RENDER STATS
-- ============================================================
local cachedContainer, cachedCount = nil, 0

-- v2.16: filter stats IKUT pilihan di GIFT (selectedPetTypes). Gak ada filter terpisah.
local function updateHeader()
    local byType, total, age100, lessAge = collectStats(cachedContainer)
    -- v2.16: kalo ada jenis kepilih di GIFT, header jumlahin jenis2 itu
    if petTypeCount() > 0 then
        age100, lessAge, total = 0, 0, 0
        for t in pairs(selectedPetTypes) do
            local d = byType[t]
            if d then
                age100  = age100  + d.age100
                lessAge = lessAge + d.less100
                total   = total   + d.age100 + d.less100
            end
        end
    end
    totalVal.Text  = tostring(total)
    age100Val.Text = tostring(age100)
    lessVal.Text   = tostring(lessAge)
    eligibleLbl.Text = "Pet eligible (age 100): "..age100
    local nF = petTypeCount()
    local scopeTag = (nF == 0) and "scope: backpack" or ("filter(gift): "..nF.." jenis")
    footer.Text = scopeTag.." • memData "..(cachedContainer and (cachedCount.." OK") or "FAIL FAIL").." • auto 2s"
    return byType
end

local _lastStatsSig = nil
local function renderStats(force)
    local byType = updateHeader()
    -- v2.18: signature dari data — kalo gak berubah, SKIP rebuild (anti lag tiap 2s)
    local sigParts = {}
    for k, v in pairs(byType) do
        sigParts[#sigParts+1] = k.."="..v.age100..","..v.less100
    end
    table.sort(sigParts)
    local selParts = {}
    for k in pairs(selectedPetTypes) do selParts[#selParts+1] = k end
    table.sort(selParts)
    local sig = table.concat(sigParts, "|").."#"..((searchBox and searchBox.Text) or "").."@"..table.concat(selParts, ",")
    if not force and sig == _lastStatsSig then return end  -- data sama → gak rebuild
    _lastStatsSig = sig

    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end

    local sorted = {}
    for k, v in pairs(byType) do table.insert(sorted, {name=k, data=v}) end
    table.sort(sorted, function(a, b)
        return (a.data.age100 + a.data.less100) > (b.data.age100 + b.data.less100)
    end)
    local filter = (searchBox.Text or ""):lower()
    for _, item in ipairs(sorted) do
        if filter == "" or item.name:lower():find(filter, 1, true) then
            local petTotal = item.data.age100 + item.data.less100
            local isSel = selectedPetTypes[item.name] == true
            -- v2.13: row TextButton, tap = toggle filter (multi)
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, -8, 0, 26)
            row.BackgroundColor3 = isSel and C.Accent or C.Panel
            row.AutoButtonColor = false
            row.Text = ""
            row.BorderSizePixel = 0 row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            local n = Instance.new("TextLabel")
            n.Size = UDim2.new(0.47, -4, 1, 0) n.Position = UDim2.new(0.03, 0, 0, 0)
            n.BackgroundTransparency = 1 n.Text = (isSel and "• " or "")..item.name
            n.TextColor3 = isSel and Color3.new(0,0,0) or C.Text
            n.Font = Enum.Font.Gotham n.TextSize = 11
            n.TextXAlignment = Enum.TextXAlignment.Left
            n.TextTruncate = Enum.TextTruncate.AtEnd n.Parent = row
            local c1 = Instance.new("TextLabel")
            c1.Size = UDim2.new(0.16, 0, 1, 0) c1.Position = UDim2.new(0.50, 0, 0, 0)
            c1.BackgroundTransparency = 1 c1.Text = tostring(item.data.age100)
            c1.TextColor3 = isSel and Color3.new(0,0,0) or C.Text
            c1.Font = Enum.Font.GothamBold c1.TextSize = 12
            c1.Parent = row
            local c2 = Instance.new("TextLabel")
            c2.Size = UDim2.new(0.14, 0, 1, 0) c2.Position = UDim2.new(0.66, 0, 0, 0)
            c2.BackgroundTransparency = 1 c2.Text = tostring(item.data.less100)
            c2.TextColor3 = isSel and Color3.new(0,0,0) or C.Text
            c2.Font = Enum.Font.GothamBold c2.TextSize = 12
            c2.Parent = row
            local c3 = Instance.new("TextLabel")
            c3.Size = UDim2.new(0.17, 0, 1, 0) c3.Position = UDim2.new(0.80, 0, 0, 0)
            c3.BackgroundTransparency = 1 c3.Text = tostring(petTotal)
            c3.TextColor3 = isSel and Color3.new(0,0,0) or C.Accent
            c3.Font = Enum.Font.GothamBold c3.TextSize = 12
            c3.Parent = row
            -- v2.13: tap = toggle jenis ini di filter (bisa pilih banyak)
            row.MouseButton1Click:Connect(function()
                if selectedPetTypes[item.name] then
                    selectedPetTypes[item.name] = nil
                else
                    selectedPetTypes[item.name] = true
                end
                renderStats()
            end)
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end

-- ============================================================
-- TARGET PICKER MODAL (NODE HUB style)
-- ============================================================
local pickerOverlay = nil

-- ============================================================
-- PERSIST GIFT SETTINGS (targets, pet types, kg, age)
-- ============================================================
local function persistGiftSettings()
    local types = {}
    for k in pairs(selectedPetTypes) do table.insert(types, k) end
    local targets = {}
    for k in pairs(selectedTargets) do table.insert(targets, k) end
    saveSettings({
        targets    = targets,
        petTypes   = types,
        kg         = kgBox.Text,
        age        = ageBox.Text,
        giftActive = _G.ZenxGiftActive == true,  -- persisted state
    })
end

local function updateTargetBtn()
    local cnt = targetCount()
    if cnt == 0 then
        targetBtn.Text = "Pilih target gift..."
        targetBtn.TextColor3 = C.Dim
    elseif cnt == 1 then
        -- show the single name
        local name
        for n in pairs(selectedTargets) do name = n; break end
        local p = findPlayerByName(name)
        if p then
            targetBtn.Text = name
            targetBtn.TextColor3 = C.Text
        else
            targetBtn.Text = name.." (offline)"
            targetBtn.TextColor3 = C.Accent
        end
    else
        targetBtn.Text = cnt.." targets ▼"
        targetBtn.TextColor3 = C.Accent
    end
end

local function toggleTarget(name)
    if not name or name == "" then return end
    if selectedTargets[name] then
        selectedTargets[name] = nil
    else
        selectedTargets[name] = true
    end
    persistGiftSettings()
    updateTargetBtn()
end

local function openTargetPicker()
    if pickerOverlay then pickerOverlay:Destroy() end

    pickerOverlay = Instance.new("Frame")
    pickerOverlay.Size = UDim2.new(1, 0, 1, 0)
    pickerOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    pickerOverlay.BackgroundTransparency = 0.4
    pickerOverlay.BorderSizePixel = 0
    pickerOverlay.ZIndex = 100
    pickerOverlay.Parent = main

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(1, 0, 1, 0)
    backBtn.BackgroundTransparency = 1
    backBtn.Text = "" backBtn.AutoButtonColor = false
    backBtn.ZIndex = 100
    backBtn.Parent = pickerOverlay

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0.85, 0, 0.75, 0)
    box.Position = UDim2.new(0.5, 0, 0.5, 0)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundColor3 = C.BG
    box.BorderSizePixel = 0
    box.ZIndex = 101
    box.Parent = pickerOverlay
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local bStroke = Instance.new("UIStroke", box)
    bStroke.Color = C.Accent
    bStroke.Thickness = 1.5

    -- Guard so backBtn click doesn't propagate when clicking inside box
    local guard = Instance.new("TextButton")
    guard.Size = UDim2.new(1, 0, 1, 0)
    guard.BackgroundTransparency = 1
    guard.Text = "" guard.AutoButtonColor = false
    guard.ZIndex = 101
    guard.Parent = box

    -- Title bar
    local pTitleBar = Instance.new("Frame")
    pTitleBar.Size = UDim2.new(1, 0, 0, 32)
    pTitleBar.BackgroundColor3 = C.Panel
    pTitleBar.BorderSizePixel = 0
    pTitleBar.ZIndex = 102
    pTitleBar.Parent = box
    Instance.new("UICorner", pTitleBar).CornerRadius = UDim.new(0, 8)
    local pTbFix = Instance.new("Frame")
    pTbFix.Size = UDim2.new(1, 0, 0, 10)
    pTbFix.Position = UDim2.new(0, 0, 1, -10)
    pTbFix.BackgroundColor3 = C.Panel
    pTbFix.BorderSizePixel = 0
    pTbFix.ZIndex = 102
    pTbFix.Parent = pTitleBar

    local pTitle = Instance.new("TextLabel")
    pTitle.Size = UDim2.new(1, -120, 1, 0)
    pTitle.Position = UDim2.new(0, 12, 0, 0)
    pTitle.BackgroundTransparency = 1
    pTitle.Text = "Target (multi)"
    pTitle.TextColor3 = C.Accent
    pTitle.Font = Enum.Font.GothamBold
    pTitle.TextSize = 13
    pTitle.TextXAlignment = Enum.TextXAlignment.Left
    pTitle.ZIndex = 103
    pTitle.Parent = pTitleBar

    local doneBtn = Instance.new("TextButton")
    doneBtn.Size = UDim2.new(0, 56, 0, 22)
    doneBtn.Position = UDim2.new(1, -110, 0.5, -11)
    doneBtn.BackgroundColor3 = C.Green
    doneBtn.Text = "DONE"
    doneBtn.TextColor3 = Color3.new(0, 0, 0)
    doneBtn.Font = Enum.Font.GothamBold
    doneBtn.TextSize = 10
    doneBtn.BorderSizePixel = 0
    doneBtn.AutoButtonColor = false
    doneBtn.ZIndex = 103
    doneBtn.Parent = pTitleBar
    Instance.new("UICorner", doneBtn).CornerRadius = UDim.new(0, 4)

    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 40, 0, 22)
    clearBtn.Position = UDim2.new(1, -50, 0.5, -11)
    clearBtn.BackgroundColor3 = C.Red
    clearBtn.Text = "CLR"
    clearBtn.TextColor3 = Color3.new(1, 1, 1)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 10
    clearBtn.BorderSizePixel = 0
    clearBtn.AutoButtonColor = false
    clearBtn.ZIndex = 103
    clearBtn.Parent = pTitleBar
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)

    -- Search box
    local pSearch = Instance.new("TextBox")
    pSearch.Size = UDim2.new(1, -16, 0, 28)
    pSearch.Position = UDim2.new(0, 8, 0, 40)
    pSearch.BackgroundColor3 = C.Card
    pSearch.Text = ""
    pSearch.PlaceholderText = "Search..."
    pSearch.PlaceholderColor3 = C.Dim
    pSearch.TextColor3 = C.Text
    pSearch.Font = Enum.Font.Gotham
    pSearch.TextSize = 12
    pSearch.TextXAlignment = Enum.TextXAlignment.Center
    pSearch.ClearTextOnFocus = false
    pSearch.BorderSizePixel = 0
    pSearch.ZIndex = 102
    pSearch.Parent = box
    Instance.new("UICorner", pSearch).CornerRadius = UDim.new(0, 4)

    -- List scroll
    local pScroll = Instance.new("ScrollingFrame")
    pScroll.Size = UDim2.new(1, -16, 1, -80)
    pScroll.Position = UDim2.new(0, 8, 0, 76)
    pScroll.BackgroundTransparency = 1
    pScroll.BorderSizePixel = 0
    pScroll.ScrollBarThickness = 4
    pScroll.ScrollBarImageColor3 = C.Accent
    pScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    pScroll.ZIndex = 102
    pScroll.Parent = box
    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding = UDim.new(0, 4)
    pLayout.Parent = pScroll

    local function closePicker()
        if pickerOverlay then pickerOverlay:Destroy() end
        pickerOverlay = nil
    end
    backBtn.MouseButton1Click:Connect(closePicker)
    doneBtn.MouseButton1Click:Connect(closePicker)
    clearBtn.MouseButton1Click:Connect(function()
        selectedTargets = {}
        persistGiftSettings()
        updateTargetBtn()
    end)

    local function renderList(filter)
        for _, c in ipairs(pScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        filter = (filter or ""):lower()

        -- Build combined list: saved + server players + already-selected (preserve picks)
        local saved = loadTargets()
        local seen = {}
        local items = {}
        -- 1) Selected targets first (so they don't disappear)
        for n in pairs(selectedTargets) do
            local p = findPlayerByName(n)
            table.insert(items, {name=n, saved=true, online=(p ~= nil), picked=true})
            seen[n:lower()] = true
        end
        -- 2) Recent saved (yellow)
        for _, name in ipairs(saved) do
            if not seen[name:lower()] then
                local p = findPlayerByName(name)
                table.insert(items, {name=name, saved=true, online=(p ~= nil), picked=false})
                seen[name:lower()] = true
            end
        end
        -- 3) Server players not in saved
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and not seen[p.Name:lower()] then
                table.insert(items, {name=p.Name, saved=false, online=true, picked=false})
            end
        end

        for _, it in ipairs(items) do
            if filter == "" or it.name:lower():find(filter, 1, true) then
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -4, 0, 30)
                local isPicked = selectedTargets[it.name] == true
                if isPicked then
                    row.BackgroundColor3 = C.Green
                    row.TextColor3 = Color3.new(0, 0, 0)
                    row.Font = Enum.Font.GothamBold
                elseif it.saved then
                    row.BackgroundColor3 = C.Accent
                    row.TextColor3 = Color3.new(0, 0, 0)
                    row.Font = Enum.Font.GothamBold
                else
                    row.BackgroundColor3 = C.Card
                    row.TextColor3 = C.Text
                    row.Font = Enum.Font.Gotham
                end
                local prefix = isPicked and "v " or "  "
                local suffix = (it.saved and not it.online) and " (offline)" or ""
                row.Text = prefix..it.name..suffix
                row.TextSize = 12
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.BorderSizePixel = 0
                row.AutoButtonColor = false
                row.ZIndex = 103
                row.Parent = pScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
                local rPad = Instance.new("UIPadding", row)
                rPad.PaddingLeft = UDim.new(0, 10)

                row.MouseButton1Click:Connect(function()
                    toggleTarget(it.name)
                    renderList(pSearch.Text)
                end)
            end
        end
        pScroll.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 8)
    end

    pSearch:GetPropertyChangedSignal("Text"):Connect(function() renderList(pSearch.Text) end)
    renderList("")
end

targetBtn.MouseButton1Click:Connect(openTargetPicker)

-- legacy stub (some code references it)
local function renderRecent() end

-- ============================================================
-- PET TYPE PICKER MODAL (multi-select)
-- ============================================================
local function updatePetPickBtn()
    local cnt = petTypeCount()
    if cnt == 0 then
        petPickBtn.Text = "Jenis Pet ▼"
        petPickBtn.TextColor3 = C.Dim
    else
        petPickBtn.Text = cnt.." pet ▼"
        petPickBtn.TextColor3 = C.Accent
    end
end

local function openPetPicker()
    if pickerOverlay then pickerOverlay:Destroy() end

    pickerOverlay = Instance.new("Frame")
    pickerOverlay.Size = UDim2.new(1, 0, 1, 0)
    pickerOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    pickerOverlay.BackgroundTransparency = 0.4
    pickerOverlay.BorderSizePixel = 0
    pickerOverlay.ZIndex = 100
    pickerOverlay.Parent = main

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(1, 0, 1, 0)
    backBtn.BackgroundTransparency = 1
    backBtn.Text = "" backBtn.AutoButtonColor = false
    backBtn.ZIndex = 100
    backBtn.Parent = pickerOverlay

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0.85, 0, 0.75, 0)
    box.Position = UDim2.new(0.5, 0, 0.5, 0)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundColor3 = C.BG
    box.BorderSizePixel = 0
    box.ZIndex = 101
    box.Parent = pickerOverlay
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local bStroke = Instance.new("UIStroke", box)
    bStroke.Color = C.Accent
    bStroke.Thickness = 1.5

    local guard = Instance.new("TextButton")
    guard.Size = UDim2.new(1, 0, 1, 0)
    guard.BackgroundTransparency = 1
    guard.Text = "" guard.AutoButtonColor = false
    guard.ZIndex = 101
    guard.Parent = box

    local pTitleBar = Instance.new("Frame")
    pTitleBar.Size = UDim2.new(1, 0, 0, 32)
    pTitleBar.BackgroundColor3 = C.Panel
    pTitleBar.BorderSizePixel = 0
    pTitleBar.ZIndex = 102
    pTitleBar.Parent = box
    Instance.new("UICorner", pTitleBar).CornerRadius = UDim.new(0, 8)
    local pTbFix = Instance.new("Frame")
    pTbFix.Size = UDim2.new(1, 0, 0, 10)
    pTbFix.Position = UDim2.new(0, 0, 1, -10)
    pTbFix.BackgroundColor3 = C.Panel
    pTbFix.BorderSizePixel = 0
    pTbFix.ZIndex = 102
    pTbFix.Parent = pTitleBar

    local pTitle = Instance.new("TextLabel")
    pTitle.Size = UDim2.new(1, -120, 1, 0)
    pTitle.Position = UDim2.new(0, 12, 0, 0)
    pTitle.BackgroundTransparency = 1
    pTitle.Text = "Pilih Jenis Pet"
    pTitle.TextColor3 = C.Accent
    pTitle.Font = Enum.Font.GothamBold
    pTitle.TextSize = 13
    pTitle.TextXAlignment = Enum.TextXAlignment.Left
    pTitle.ZIndex = 103
    pTitle.Parent = pTitleBar

    local doneBtn = Instance.new("TextButton")
    doneBtn.Size = UDim2.new(0, 56, 0, 22)
    doneBtn.Position = UDim2.new(1, -110, 0.5, -11)
    doneBtn.BackgroundColor3 = C.Green
    doneBtn.Text = "✓ DONE"
    doneBtn.TextColor3 = Color3.new(0, 0, 0)
    doneBtn.Font = Enum.Font.GothamBold
    doneBtn.TextSize = 10
    doneBtn.BorderSizePixel = 0
    doneBtn.AutoButtonColor = false
    doneBtn.ZIndex = 103
    doneBtn.Parent = pTitleBar
    Instance.new("UICorner", doneBtn).CornerRadius = UDim.new(0, 4)

    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 40, 0, 22)
    clearBtn.Position = UDim2.new(1, -50, 0.5, -11)
    clearBtn.BackgroundColor3 = C.Red
    clearBtn.Text = "CLR"
    clearBtn.TextColor3 = Color3.new(1, 1, 1)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 10
    clearBtn.BorderSizePixel = 0
    clearBtn.AutoButtonColor = false
    clearBtn.ZIndex = 103
    clearBtn.Parent = pTitleBar
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)

    local pSearch = Instance.new("TextBox")
    pSearch.Size = UDim2.new(1, -16, 0, 28)
    pSearch.Position = UDim2.new(0, 8, 0, 40)
    pSearch.BackgroundColor3 = C.Card
    pSearch.Text = ""
    pSearch.PlaceholderText = "Cari pet..."
    pSearch.PlaceholderColor3 = C.Dim
    pSearch.TextColor3 = C.Text
    pSearch.Font = Enum.Font.Gotham
    pSearch.TextSize = 12
    pSearch.ClearTextOnFocus = false
    pSearch.BorderSizePixel = 0
    pSearch.ZIndex = 102
    pSearch.Parent = box
    Instance.new("UICorner", pSearch).CornerRadius = UDim.new(0, 4)
    local psPad = Instance.new("UIPadding", pSearch)
    psPad.PaddingLeft = UDim.new(0, 10)

    local pScroll = Instance.new("ScrollingFrame")
    pScroll.Size = UDim2.new(1, -16, 1, -80)
    pScroll.Position = UDim2.new(0, 8, 0, 76)
    pScroll.BackgroundTransparency = 1
    pScroll.BorderSizePixel = 0
    pScroll.ScrollBarThickness = 4
    pScroll.ScrollBarImageColor3 = C.Accent
    pScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    pScroll.ZIndex = 102
    pScroll.Parent = box
    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding = UDim.new(0, 3)
    pLayout.Parent = pScroll

    local function closePicker()
        if pickerOverlay then pickerOverlay:Destroy() end
        pickerOverlay = nil
        updatePetPickBtn()
    end
    backBtn.MouseButton1Click:Connect(closePicker)
    doneBtn.MouseButton1Click:Connect(closePicker)
    clearBtn.MouseButton1Click:Connect(function()
        selectedPetTypes = {}
        persistGiftSettings()
    end)

    local function renderList(filter)
        for _, c in ipairs(pScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        filter = (filter or ""):lower()
        -- Build pet type list from: backpack + memContainer (storage/booth) + already-selected types
        local byType = {}
        -- 1) backpack
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("PET_UUID") then
                    local pType = stripMutation(tostring(tool:GetAttribute("f") or "?"))
                    byType[pType] = (byType[pType] or 0) + 1
                end
            end
        end
        -- 2) memContainer (storage, booth, pets seen)
        if cachedContainer then
            for _, entry in pairs(cachedContainer) do
                if type(entry) == "table" and entry.PetType then
                    local pType = stripMutation(tostring(entry.PetType))
                    if not byType[pType] then byType[pType] = 0 end
                    -- don't double-count backpack, but make sure type exists in list
                end
            end
        end
        -- 3) already-selected types (so they don't disappear if not in backpack)
        for k in pairs(selectedPetTypes) do
            if not byType[k] then byType[k] = 0 end
        end
        local items = {}
        for k, v in pairs(byType) do table.insert(items, {name=k, count=v}) end
        table.sort(items, function(a, b)
            -- Selected first
            local aSel = selectedPetTypes[a.name] and 1 or 0
            local bSel = selectedPetTypes[b.name] and 1 or 0
            if aSel ~= bSel then return aSel > bSel end
            -- Then by count desc (backpack > 0)
            if a.count ~= b.count then return a.count > b.count end
            -- Then alphabetical
            return a.name < b.name
        end)

        for _, it in ipairs(items) do
            if filter == "" or it.name:lower():find(filter, 1, true) then
                local sel = selectedPetTypes[it.name] == true
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -4, 0, 28)
                row.BackgroundColor3 = sel and C.Accent or C.Card
                row.Text = (sel and "✓ " or "  ")..it.name..(it.count > 0 and ("  ("..it.count..")") or "")
                row.TextColor3 = sel and Color3.new(0,0,0) or C.Text
                row.Font = sel and Enum.Font.GothamBold or Enum.Font.Gotham
                row.TextSize = 12
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.BorderSizePixel = 0
                row.AutoButtonColor = false
                row.ZIndex = 103
                row.Parent = pScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
                local rPad = Instance.new("UIPadding", row)
                rPad.PaddingLeft = UDim.new(0, 10)
                row.MouseButton1Click:Connect(function()
                    if selectedPetTypes[it.name] then
                        selectedPetTypes[it.name] = nil
                    else
                        selectedPetTypes[it.name] = true
                    end
                    persistGiftSettings()
                    renderList(pSearch.Text)
                end)
            end
        end
        pScroll.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 8)
    end

    pSearch:GetPropertyChangedSignal("Text"):Connect(function() renderList(pSearch.Text) end)
    renderList("")
end

petPickBtn.MouseButton1Click:Connect(openPetPicker)
updatePetPickBtn()

-- Persist on kg/age text change
kgBox:GetPropertyChangedSignal("Text"):Connect(persistGiftSettings)
ageBox:GetPropertyChangedSignal("Text"):Connect(persistGiftSettings)

-- Load saved settings (targets + petTypes + kg + age)
local _savedGS = loadSettings()
if type(_savedGS) == "table" then
    -- New format: array of targets
    if type(_savedGS.targets) == "table" then
        for _, n in ipairs(_savedGS.targets) do
            if type(n) == "string" then selectedTargets[n] = true end
        end
    end
    -- Backward compat: old single target field
    if _savedGS.target and _savedGS.target ~= "" then
        selectedTargets[_savedGS.target] = true
    end
    updateTargetBtn()
    if type(_savedGS.petTypes) == "table" then
        for _, n in ipairs(_savedGS.petTypes) do
            if type(n) == "string" then selectedPetTypes[n] = true end
        end
        updatePetPickBtn()
    end
    if type(_savedGS.kg) == "string" then kgBox.Text = _savedGS.kg end
    if type(_savedGS.age) == "string" then ageBox.Text = _savedGS.age end
end

-- ============================================================
-- GIFT LOOP
-- ============================================================
local giftActive = false
local giftStopReq = false
local sentCount, failCount = 0, 0

local function setRunning(v)
    if v then
        toggleBtn.Text = "GIFT  ON"
        toggleBtn.BackgroundColor3 = C.Green
        toggleBtn.TextColor3 = Color3.new(0, 0, 0)
    else
        toggleBtn.Text = "GIFT  OFF"
        toggleBtn.BackgroundColor3 = C.Red
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end

-- Check pet matches filter (jenis pet / kg / age)
local function petMatchesFilter(tool)
    local uuid = tool:GetAttribute("PET_UUID")
    if not uuid then return false end
    -- v2.11: SKIP favorite pets (cek multiple field names)
    if tool:GetAttribute("FAVORITE") == true then return false end
    if tool:GetAttribute("IsFavorited") == true then return false end
    if tool:GetAttribute("Favorited") == true then return false end
    -- pet type filter
    if petTypeCount() > 0 then
        local pType = stripMutation(tostring(tool:GetAttribute("f") or "?"))
        if not selectedPetTypes[pType] then return false end
    end
    -- get kg + level
    local key = tostring(uuid)
    if key:sub(1,1) ~= "{" then key = "{"..key.."}" end
    local entry = cachedContainer and cachedContainer[key]
    if not entry or not entry.PetData then return false end
    -- v2.11: also check IsFavorite di PetData
    if entry.PetData.IsFavorite == true then return false end
    local bw = tonumber(entry.PetData.BaseWeight) or 0
    local lvl = tonumber(entry.PetData.Level) or 0
    local kg = bw * (10 + lvl) / 10
    -- KG filter: minimum threshold
    local kgMin = tonumber(kgBox.Text) or 0
    if kgMin > 0 and kg < kgMin then return false end
    -- Age filter: exact level (e.g. 100 = only level 100)
    local ageReq = tonumber(ageBox.Text) or 0
    if ageReq > 0 and lvl < ageReq then return false end
    return true
end

-- v2.10: startGift can be called from click OR auto-load
local function startGift()
    if giftActive then return end
    if targetCount() == 0 then
        statusLbl.Text = "Error: Belum pilih target"
        statusLbl.TextColor3 = C.Red
        return
    end
    if not giftRE and not PGS then
        statusLbl.Text = "Error: Gift remote/module gak ditemukan"
        statusLbl.TextColor3 = C.Red
        return
    end

    giftActive = true
    giftStopReq = false
    sentCount, failCount = 0, 0
    gCounterLbl.Text = "Sent: 0   Failed: 0"
    setRunning(true)
    statusLbl.Text = "Status: starting..."
    statusLbl.TextColor3 = C.Accent
    _G.ZenxGiftActive = true
    persistGiftSettings()

    task.spawn(function()
        math.randomseed(tick())  -- v2.11: fresh seed
        local lastPoolLog = 0
        while not giftStopReq do
            -- Refresh online targets each cycle (with dedup)
            local poolTargets = {}
            local seenPlayer = {}
            for name in pairs(selectedTargets) do
                local p = findPlayerByName(name)
                if p and not seenPlayer[p] then
                    table.insert(poolTargets, p)
                    seenPlayer[p] = true
                end
            end

            -- v2.11: log pool size periodically biar bisa diagnose
            if tick() - lastPoolLog > 10 then
                lastPoolLog = tick()
                local names = {}
                for _, p in ipairs(poolTargets) do table.insert(names, p.Name) end
                print(string.format("[ZenxGift] pool=%d/%d (online/selected) — %s",
                    #poolTargets, targetCount(), table.concat(names, ", ")))
            end

            if #poolTargets == 0 then
                statusLbl.Text = "Waiting: target offline semua... ("..targetCount().." selected)"
                statusLbl.TextColor3 = C.Orange
                task.wait(5)
            else
                local bp = player:FindFirstChild("Backpack")
                if not bp then task.wait(2); else

                -- save recent for online targets
                for _, p in ipairs(poolTargets) do addRecentTarget(p.Name) end

                local matching = {}
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and petMatchesFilter(t) then
                        table.insert(matching, t)
                    end
                end
                if #matching == 0 then
                    statusLbl.Text = "Waiting: no pet match filter di backpack..."
                    statusLbl.TextColor3 = C.Orange
                    task.wait(5)
                else
                    local petTool = matching[math.random(1, #matching)]
                    local target = poolTargets[math.random(1, #poolTargets)]
                    local petName = petTool.Name
                    statusLbl.Text = "→ "..target.Name:sub(1,14).." : "..petName:sub(1,18)
                    statusLbl.TextColor3 = C.Blue
                    local ok = giftPetToPlayer(target, petTool)
                    if ok then
                        sentCount = sentCount + 1
                    else
                        failCount = failCount + 1
                    end
                    gCounterLbl.Text = "Sent: "..sentCount.."   Failed: "..failCount
                    task.wait(1.5)
                end
                end
            end
        end
        giftActive = false
        setRunning(false)
        statusLbl.Text = "Stop: Stopped (Sent: "..sentCount..")"
        statusLbl.TextColor3 = C.Dim
        _G.ZenxGiftActive = false
        persistGiftSettings()
    end)
end

local function stopGift()
    if not giftActive then return end
    giftStopReq = true
    statusLbl.Text = "Status: stopping..."
    statusLbl.TextColor3 = C.Orange
end

toggleBtn.MouseButton1Click:Connect(function()
    if giftActive then
        stopGift()
    else
        startGift()
    end
end)

-- ============================================================
-- TAB SWITCH
-- ============================================================
local activeTab = "stats"
local function setTab(tab)
    activeTab = tab
    if tab == "stats" then
        tabStatsBtn.BackgroundColor3 = C.Accent
        tabStatsBtn.TextColor3 = Color3.new(0, 0, 0)
        tabGiftBtn.BackgroundColor3 = C.Card
        tabGiftBtn.TextColor3 = C.Dim
        statsPanel.Visible = true
        giftPanel.Visible = false
    else
        tabGiftBtn.BackgroundColor3 = C.Accent
        tabGiftBtn.TextColor3 = Color3.new(0, 0, 0)
        tabStatsBtn.BackgroundColor3 = C.Card
        tabStatsBtn.TextColor3 = C.Dim
        statsPanel.Visible = false
        giftPanel.Visible = true
        renderRecent()
    end
end
tabStatsBtn.MouseButton1Click:Connect(function() setTab("stats") end)
tabGiftBtn.MouseButton1Click:Connect(function() setTab("gift") end)
setTab("stats")

-- ============================================================
-- TOGGLE EXPAND
-- ============================================================
local expanded = false
local function setExpanded(v)
    expanded = v
    tabRow.Visible = v
    statsPanel.Visible = v and (activeTab == "stats")
    giftPanel.Visible = v and (activeTab == "gift")
    footer.Visible = v
    if v then
        main.Size = UDim2.new(0, W, 0, EXPANDED_HEIGHT)
        expandBtn.Text = "—"
    else
        main.Size = UDim2.new(0, W, 0, COLLAPSED_HEIGHT)
        expandBtn.Text = "+"
    end
end
setExpanded(false)
expandBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

-- ============================================================
-- MINIMIZE — floating logo
-- ============================================================
local zLogo = Instance.new("TextButton")
zLogo.Size = UDim2.new(0, 40, 0, 40)
zLogo.Position = UDim2.new(0, 10, 0.5, -20)
zLogo.BackgroundColor3 = Color3.fromRGB(255,255,255)
zLogo.Text = "Z" zLogo.TextColor3 = Color3.new(0,0,0)
zLogo.Font = Enum.Font.GothamBold zLogo.TextSize = 20
zLogo.BorderSizePixel = 0
zLogo.AutoButtonColor = false
zLogo.Active = true
zLogo.Draggable = true
zLogo.Visible = false
zLogo.Parent = sg
Instance.new("UICorner", zLogo).CornerRadius = UDim.new(1, 0)
local zStroke = Instance.new("UIStroke", zLogo)
zStroke.Color = Color3.new(0,0,0) zStroke.Thickness = 1.5

minBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    zLogo.Visible = true
end)
zLogo.MouseButton1Click:Connect(function()
    main.Visible = true
    zLogo.Visible = false
end)

-- ============================================================
-- INIT + AUTO-REFRESH
-- ============================================================
cachedContainer, cachedCount = findMemoryContainer()
print("[ZenxAgeStats] memContainer: "..(cachedContainer and cachedCount.." entries" or "FAIL"))
print("[ZenxAgeStats] giftRE="..(giftRE and "OK" or "FAIL").." PGS="..(PGS and "OK" or "FAIL"))

renderStats()
renderRecent()

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if activeTab == "stats" then renderStats() end
end)

task.spawn(function()
    -- v2.19: begitu container KETEMU, STOP re-scan getgc rutin (itu yg bikin lag berkala).
    -- Referensi container tetep hidup — game update pet baru di tabel yg sama.
    -- Re-scan cuma kalo: belum ketemu, ATAU tiap 5 MENIT (safety net kalo stale).
    local lastScan = 0
    local scanCount = 0
    while sg.Parent do
        task.wait(2)
        if not sg.Parent then break end
        local needScan = false
        if not cachedContainer then needScan = true                         -- belum ketemu: cari
        elseif scanCount < 3 and (tick() - lastScan) > 4 then needScan = true -- 3x awal (akun baru)
        elseif (tick() - lastScan) > 300 then needScan = true                -- safety: tiap 5 menit
        end
        if needScan then
            local nc, ncnt = findMemoryContainer()
            if nc and ncnt > 0 then cachedContainer = nc; cachedCount = ncnt end
            lastScan = tick()
            scanCount = scanCount + 1
        end
        updateHeader()  -- ringan — tiap 2s
        if activeTab == "stats" then renderStats() end  -- skip otomatis kalo data sama
    end
end)

-- v2.11: Backpack ChildRemoved/Added listener — instant update header pas pet di-gift/hatch
local function hookBp(c)
    if not c then return end
    c.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and child:GetAttribute("PET_UUID") then
            task.wait(0.2)
            updateHeader()
            if activeTab == "stats" then renderStats() end
        end
    end)
    c.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child:GetAttribute("PET_UUID") then
            task.wait(0.2)
            updateHeader()
            if activeTab == "stats" then renderStats() end
        end
    end)
end
hookBp(player:FindFirstChild("Backpack"))
hookBp(player.Character)
player.CharacterAdded:Connect(function(ch) hookBp(ch) end)

print("[ZenxAgeStats] "..VER.." loaded")

-- v2.10: Restore gift state — kalo terakhir ON, auto-resume after rejoin
if type(_savedGS) == "table" and _savedGS.giftActive == true then
    print("[ZenxAgeStats] gift was ON, auto-resuming...")
    task.spawn(function()
        task.wait(3)  -- delay biar memContainer + players settle dulu
        startGift()
    end)
end
