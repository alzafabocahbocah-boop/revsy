-- ============================================================
-- ZENX KG STATS v1.1 (minimal)
-- Cuma show TOTAL / KG 60+ / KG 60- — no table, no search
-- Data via getgc memory container
-- Scope: backpack only — Auto-refresh 5 detik
-- ============================================================

local Players    = game:GetService("Players")
local CoreGui    = game:GetService("CoreGui")
local HS         = game:GetService("HttpService")
local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui", 10)
local VER = "v2.0"
local KG_THRESHOLD = 6  -- compared against age-1 kg (BaseWeight × 1.1)
local SETTINGS_FILE = "ZenxKgStats_settings.json"

-- Mutation prefixes for type normalization
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

-- ALL pet types in Grow A Garden (master list — comprehensive base)
local ALL_PET_TYPES = {
    "Bee","Black Bear","Brontosaurus","Bunny","Bull","Capybara","Cat","Chicken",
    "Cow","Crab","Cyclops","Dog","Dragonfly","Dragon Fruit","Duck","Eagle",
    "Elephant","Fennec Fox","Flamingo","Frog","Giraffe","Goat","Golden Lab",
    "Grey Mouse","Hamster","Hedgehog","Honey Bee","Horse","Hyena","Ice Golem",
    "Kappa","King Bee","Komodo Dragon","Krakeon","Ladybug","Lion","Llama",
    "Mantis","Meerkat","Mimic Octopus","Mole","Monkey","Moon Cat","Mosquito",
    "Newt","Nightmare Peacock","Otter","Owl","Pack Bee","Panda","Parrot",
    "Peacock","Penguin","Peryton","Petal Bee","Pig","Polar Bear","Puma",
    "Queen Bee","Rabbit","Raccoon","Red Fox","Rhino","Ringneck Pheasant",
    "Robin","Rooster","Ruby Squid","Salamander","Scorpion","Sea Turtle","Seal",
    "Shark","Shiba Inu","Silver Monkey","Snail","Snow Owl","Snowfall","Spider",
    "Spotted Deer","Squirrel","Starfish","Stork","Sugar Glider","Swan","T-Rex",
    "Tarantula","Tortoise","Toucan","Triceratops","Turtle","Wasp","Werewolf",
    "White Mouse","Wolf","ZapHorse","Beaver","Chocolate Bunny","Hootsie Roll",
    "Brown Mouse","Black Mouse","Octopus","Snake","Snowman","Reindeer","Yak",
    "Wolverine","Manta Ray","Jellyfish","Seahorse","Anglerfish","Pufferfish",
    "Lobster","Bat","Cobra","Iguana","Chameleon","Gecko","Pelican","Vulture",
    "Hawk","Falcon","Crow","Raven","Magpie","Cardinal","Sparrow","Bluebird",
    "Hummingbird","Woodpecker","Pheasant","Quail","Turkey","Ostrich","Emu",
    "Kookaburra","Cockatoo","Macaw","Lemur","Sloth","Anteater","Armadillo",
    "Tapir","Capuchin","Gorilla","Orangutan","Chimpanzee","Baboon","Bushbaby",
    "Tarsier","Possum","Skunk","Badger","Weasel","Ferret","Marten","Stoat",
    "Mink","Mongoose","Pangolin","Aardvark","Echidna","Platypus","Wombat",
    "Kangaroo","Wallaby","Koala","Tasmanian Devil",
}

-- Settings persistence
local selectedPetTypes = {}  -- {[petName]=true}

local function loadSettings()
    -- Try file first
    local content = nil
    pcall(function()
        if isfile and readfile and isfile(SETTINGS_FILE) then
            content = readfile(SETTINGS_FILE)
        end
    end)
    if content then
        local ok, data = pcall(function() return HS:JSONDecode(content) end)
        if ok and type(data) == "table" and type(data.petTypes) == "table" then
            for _, n in ipairs(data.petTypes) do
                if type(n) == "string" then selectedPetTypes[n] = true end
            end
            print("[ZenxKgStats] loaded "..#data.petTypes.." pet filters from file")
            return
        end
    end
    -- Fallback: getgenv (in-session)
    local g = (getgenv and getgenv()) or _G
    if g and g.ZenxKgStatsSettings and type(g.ZenxKgStatsSettings) == "table" then
        for _, n in ipairs(g.ZenxKgStatsSettings.petTypes or {}) do
            if type(n) == "string" then selectedPetTypes[n] = true end
        end
        print("[ZenxKgStats] loaded from getgenv (in-session)")
    end
end

local function saveSettings()
    local types = {}
    for k in pairs(selectedPetTypes) do table.insert(types, k) end
    local data = {petTypes = types}
    -- Save to file (persist across rejoin)
    pcall(function()
        if writefile then writefile(SETTINGS_FILE, HS:JSONEncode(data)) end
    end)
    -- Also save to getgenv (in-session backup)
    local g = (getgenv and getgenv()) or _G
    if g then g.ZenxKgStatsSettings = data end
end

local function petTypeCount()
    local n = 0; for _ in pairs(selectedPetTypes) do n = n + 1 end; return n
end

-- ===== CLEANUP =====
local function cleanup()
    for _, p in ipairs({playerGui, CoreGui}) do
        for _, c in ipairs(p:GetChildren()) do
            if c.Name == "ZenxKgStats" then pcall(function() c:Destroy() end) end
        end
    end
    pcall(function()
        if gethui then
            for _, c in ipairs(gethui():GetChildren()) do
                if c.Name == "ZenxKgStats" then c:Destroy() end
            end
        end
    end)
end
cleanup()

-- ============================================================
-- MEMORY CONTAINER
-- ============================================================
local function findMemoryContainer()
    if not getgc then return nil, 0 end
    -- v1.8: Get backpack UUIDs to find the RIGHT container
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
        print("[ZenxKgStats] container: "..bestCount.." entries, "..bestMatch.."/"..bpCount.." backpack match")
    end
    return best, bestCount
end

local function getAgeOneKg(container, uuid)
    -- Return berat di age 1 = BaseWeight × 1.1
    -- Contoh: pet 27kg age 40 → BW≈5.4 → age 1 = 5.94 ≈ 6kg
    if not container or not uuid then return 0 end
    local key = tostring(uuid)
    if key:sub(1,1) ~= "{" then key = "{"..key.."}" end
    local entry = container[key]
    if type(entry) == "table" and entry.PetData then
        local bw = tonumber(entry.PetData.BaseWeight) or 0
        return bw * 1.1
    end
    return 0
end

local function collectStats(container)
    local total, above, below = 0, 0, 0
    local bp = player:FindFirstChild("Backpack")
    if not bp then return total, above, below end
    local hasFilter = petTypeCount() > 0
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            local uuid = tool:GetAttribute("PET_UUID")
            if uuid then
                local skip = false
                if hasFilter then
                    local pType = stripMutation(tostring(tool:GetAttribute("f") or "?"))
                    if not selectedPetTypes[pType] then skip = true end
                end
                if not skip then
                    local kg = getAgeOneKg(container, uuid)
                    if kg >= KG_THRESHOLD then
                        above = above + 1
                    else
                        below = below + 1
                    end
                    total = total + 1
                end
            end
        end
    end
    return total, above, below
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
sg.Name = "ZenxKgStats"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 9999
local parented = false
pcall(function() if gethui then sg.Parent = gethui(); parented = true end end)
if not parented then sg.Parent = playerGui end

-- ============================================================
-- DIMENSIONS
-- ============================================================
local W = 380
local TITLE_H = 34
local HEADER_H = 64
local TOTAL_H = TITLE_H + 8 + HEADER_H + 8

-- ============================================================
-- MAIN
-- ============================================================
local main = Instance.new("Frame")
main.Size = UDim2.new(0, W, 0, TOTAL_H)
main.Position = UDim2.new(0, 10, 0.5, -TOTAL_H/2)
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
titleLbl.Size = UDim2.new(1, -150, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "ZENX KG STATS "..VER
titleLbl.TextColor3 = C.Accent
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 12
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

-- Pet picker button (small, in title bar)
local petPickBtn = Instance.new("TextButton")
petPickBtn.Size = UDim2.new(0, 68, 0, 22)
petPickBtn.Position = UDim2.new(1, -150, 0.5, -11)
petPickBtn.BackgroundColor3 = C.Card
petPickBtn.Text = "Pet ▼"
petPickBtn.TextColor3 = C.Dim
petPickBtn.Font = Enum.Font.GothamBold
petPickBtn.TextSize = 10
petPickBtn.BorderSizePixel = 0
petPickBtn.AutoButtonColor = false
petPickBtn.Parent = titleBar
Instance.new("UICorner", petPickBtn).CornerRadius = UDim.new(0, 4)

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

local minBtn   = mkTitleBtn(-62, "—", C.Blue)
local closeBtn = mkTitleBtn(-32, "✕", C.Red)
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
    t.Font = Enum.Font.Gotham t.TextSize = 15  -- v2.0: atas gede dikit lagi (13->15)
    t.Parent = cell
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, 0, 0, 34)
    v.Position = UDim2.new(0, 0, 0, 28)
    v.BackgroundTransparency = 1
    v.Text = "0" v.TextColor3 = valColor or C.Text
    v.Font = Enum.Font.GothamBold v.TextSize = 30  -- v2.0: bawah gede dikit lagi (24->30)
    v.Parent = cell
    return v
end
local totalVal = mkStat(header, 0,    0.33, "TOTAL",                C.Text)
local aboveVal = mkStat(header, 0.33, 0.33, "KG "..KG_THRESHOLD.."+", C.Text)
local belowVal = mkStat(header, 0.66, 0.33, "KG "..KG_THRESHOLD.."-", C.Text)

-- ============================================================
-- RENDER
-- ============================================================
local cachedContainer, cachedCount = nil, 0

local function render()
    local total, above, below = collectStats(cachedContainer)
    totalVal.Text = tostring(total)
    aboveVal.Text = tostring(above)
    belowVal.Text = tostring(below)
end

-- ============================================================
-- FLOATING LOGO + MINIMIZE
-- ============================================================
local zLogo = Instance.new("TextButton")
zLogo.Size = UDim2.new(0, 42, 0, 42)
zLogo.Position = UDim2.new(0, 10, 0.5, -21)
zLogo.BackgroundColor3 = C.Accent
zLogo.Text = "⚖" zLogo.TextColor3 = Color3.new(0,0,0)
zLogo.Font = Enum.Font.GothamBold zLogo.TextSize = 22
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
-- PET TYPE PICKER MODAL
-- ============================================================
local function updatePetPickBtn()
    local cnt = petTypeCount()
    if cnt == 0 then
        petPickBtn.Text = "Pet ▼"
        petPickBtn.TextColor3 = C.Dim
    else
        petPickBtn.Text = cnt.." pet ▼"
        petPickBtn.TextColor3 = C.Accent
    end
end

local pickerOverlay = nil

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
    box.Size = UDim2.new(0, 320, 0, 360)
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
        render()  -- refresh stats with new filter
    end
    backBtn.MouseButton1Click:Connect(closePicker)
    doneBtn.MouseButton1Click:Connect(closePicker)
    clearBtn.MouseButton1Click:Connect(function()
        selectedPetTypes = {}
        saveSettings()
    end)

    local function renderList(filter)
        for _, c in ipairs(pScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        filter = (filter or ""):lower()
        -- Build pet type list from: master list + backpack + memContainer + already-selected
        local byType = {}
        -- 1) Master list (semua jenis pet di game)
        for _, n in ipairs(ALL_PET_TYPES) do
            byType[n] = 0
        end
        -- 2) Backpack (count actual pets)
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("PET_UUID") then
                    local pType = stripMutation(tostring(tool:GetAttribute("f") or "?"))
                    byType[pType] = (byType[pType] or 0) + 1
                end
            end
        end
        -- 3) memContainer (catches new pets gw belum hardcode)
        if cachedContainer then
            for _, entry in pairs(cachedContainer) do
                if type(entry) == "table" and entry.PetType then
                    local pType = stripMutation(tostring(entry.PetType))
                    if not byType[pType] then byType[pType] = 0 end
                end
            end
        end
        -- 4) Already-selected (so they don't disappear)
        for k in pairs(selectedPetTypes) do
            if not byType[k] then byType[k] = 0 end
        end

        local items = {}
        for k, v in pairs(byType) do table.insert(items, {name=k, count=v}) end
        table.sort(items, function(a, b)
            local aSel = selectedPetTypes[a.name] and 1 or 0
            local bSel = selectedPetTypes[b.name] and 1 or 0
            if aSel ~= bSel then return aSel > bSel end
            if a.count ~= b.count then return a.count > b.count end
            return a.name < b.name
        end)

        for _, it in ipairs(items) do
            if filter == "" or it.name:lower():find(filter, 1, true) then
                local sel = selectedPetTypes[it.name] == true
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -4, 0, 28)
                row.BackgroundColor3 = sel and C.Accent or C.Card
                row.Text = (sel and "v " or "  ")..it.name..(it.count > 0 and ("  ("..it.count..")") or "")
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
                    saveSettings()
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

-- Load saved settings
loadSettings()
updatePetPickBtn()

-- ============================================================
-- INIT + AUTO-REFRESH
-- ============================================================
cachedContainer, cachedCount = findMemoryContainer()
print("[ZenxKgStats] memContainer: "..(cachedContainer and cachedCount.." entries" or "FAIL"))
print("[ZenxKgStats] threshold: "..KG_THRESHOLD.."kg")

render()

task.spawn(function()
    while sg.Parent do
        task.wait(2)
        if not sg.Parent then break end
        local nc, ncnt = findMemoryContainer()
        if nc and ncnt > 0 then cachedContainer = nc; cachedCount = ncnt end
        render()
    end
end)

print("[ZenxKgStats] "..VER.." loaded")
