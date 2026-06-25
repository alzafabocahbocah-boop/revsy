-- ============= ZENX INVENTORY VIEWER v3.0 =============
-- Weight categories (Large/Huge/Titanic/Godly/Colossal) sesuai game.guide
-- Formula: weight = baseKG * (age + 10) / 11
local SCRIPT_VERSION = "v6.7 (relay + jeda 60s dibuang, gift terus)"
print("==== [ZenxInv] LOAD ("..SCRIPT_VERSION..") ====")

local Players = game:GetService("Players")
local TS = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ===== v5.13: APS via getgc memory container (bypass require, works di market+garden) =====
do
    local ZAPS = {api = nil, memContainer = nil, memContainerCount = 0, ready = false}
    local cache, cacheTime = {}, {}
    local TTL = 5
    local APS_CACHE_FILE = "ZenxMarket_APS_cache.json"
    local persistentCache = {}
    pcall(function()
        if isfile and readfile and isfile(APS_CACHE_FILE) then
            local raw = readfile(APS_CACHE_FILE)
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(data) == "table" then
                persistentCache = data
                local cnt = 0
                for _ in pairs(persistentCache) do cnt = cnt + 1 end
                print("[ZenxInv] [APS] loaded "..cnt.." entries from cache file")
            end
        end
    end)
    local function brace(uuid)
        local k = tostring(uuid)
        if k:sub(1,1) ~= "{" then k = "{"..k.."}" end
        return k
    end
    function ZAPS.findMemoryContainer()
        if not getgc then return nil, 0 end
        local best, bestCount = nil, 0
        pcall(function()
            for _, obj in pairs(getgc(true)) do
                if type(obj) == "table" then
                    local uuidLike = 0
                    for k in pairs(obj) do
                        if type(k) == "string" and #k >= 32 and k:find("-") then
                            uuidLike = uuidLike + 1
                            if uuidLike >= 5 then break end
                        end
                    end
                    if uuidLike >= 5 then
                        local sample = nil
                        for _, v in pairs(obj) do sample = v; break end
                        if type(sample) == "table" and rawget(sample, "PetData") then
                            local cnt = 0
                            for _ in pairs(obj) do cnt = cnt + 1 end
                            if cnt > bestCount then best = obj; bestCount = cnt end
                        end
                    end
                end
            end
        end)
        return best, bestCount
    end
    function ZAPS.getPetData(uuid)
        if not ZAPS.api or not uuid then return nil end
        local key = brace(uuid)
        local now = tick()
        if cache[key] and (now - (cacheTime[key] or 0)) < TTL then return cache[key] end
        local ok, info = pcall(function() return ZAPS.api:GetPetData(player.Name, key) end)
        if ok and info and info.PetData then
            cache[key] = info; cacheTime[key] = now
            return info
        end
        return nil
    end
    function ZAPS.getAge(uuid)
        if ZAPS.memContainer then
            local entry = ZAPS.memContainer[brace(uuid)]
            if type(entry) == "table" and entry.PetData and entry.PetData.Level then
                return entry.PetData.Level
            end
        end
        local info = ZAPS.getPetData(uuid)
        if info and info.PetData and info.PetData.Level then return info.PetData.Level end
        local pc = persistentCache[brace(uuid)]
        if pc and pc.Level then return pc.Level end
        return nil
    end
    function ZAPS.getBaseKg(uuid)
        if ZAPS.memContainer then
            local entry = ZAPS.memContainer[brace(uuid)]
            if type(entry) == "table" and entry.PetData and entry.PetData.BaseWeight then
                return entry.PetData.BaseWeight
            end
        end
        local info = ZAPS.getPetData(uuid)
        if info and info.PetData and info.PetData.BaseWeight then return info.PetData.BaseWeight end
        local pc = persistentCache[brace(uuid)]
        if pc and pc.BaseWeight then return pc.BaseWeight end
        return nil
    end
    getgenv().ZenxInvAPS = ZAPS
    task.spawn(function()
        ZAPS.memContainer, ZAPS.memContainerCount = ZAPS.findMemoryContainer()
        if ZAPS.memContainer then
            print("[ZenxInv] [APS] memContainer FOUND: "..ZAPS.memContainerCount.." entries")
        end
        if not ZAPS.memContainer then
            local attempt = 0
            while not ZAPS.api and attempt < 3 do
                attempt = attempt + 1
                local done = false
                task.spawn(function()
                    pcall(function()
                        local m = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("PetServices")
                        local am = m and m:FindFirstChild("ActivePetsService")
                        if am then ZAPS.api = require(am) end
                    end)
                    done = true
                end)
                local waited = 0
                while not done and waited < 5 do task.wait(0.5); waited = waited + 0.5 end
                if not ZAPS.api and attempt < 3 then task.wait(3) end
            end
        end
        ZAPS.ready = true
        print("[ZenxInv] [APS] FINAL: memContainer="..(ZAPS.memContainer and ZAPS.memContainerCount.." entries" or "FAIL").." api="..(ZAPS.api and "OK" or "FAIL"))
        task.spawn(function()
            while true do
                task.wait(60)
                local new, cnt = ZAPS.findMemoryContainer()
                if new and cnt > 0 then ZAPS.memContainer = new; ZAPS.memContainerCount = cnt end
            end
        end)
    end)
end

-- persistence
local STATE_FILE = "ZenxInv_state.json"
local function saveState(state)
    if not writefile then return end
    pcall(function() writefile(STATE_FILE, HttpService:JSONEncode(state)) end)
end
local function loadState()
    if not (isfile and readfile and isfile(STATE_FILE)) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(STATE_FILE)) end)
    return ok and data or nil
end
local savedState = loadState() or {}

-- ===== REJOIN SERVER DETECTION =====
local currentJobId = tostring(game.JobId or "")
local serverDGT = workspace.DistributedGameTime or 0
print("============================================")
print("[ZenxInv] REJOIN DETECTION ANALYSIS")
print("[ZenxInv] Current JobId: "..currentJobId)
print("[ZenxInv] Server uptime: "..math.floor(serverDGT).." detik ("..string.format("%.1f", serverDGT/60).." menit)")
print("[ZenxInv] Saved state file exists: "..tostring(isfile and isfile(STATE_FILE) or false))
if savedState and savedState.lastJobId then
    print("[ZenxInv] savedState.lastJobId: "..tostring(savedState.lastJobId))
    print("[ZenxInv] savedState.rejoinTime: "..tostring(savedState.rejoinTime))
    print("[ZenxInv] elapsed since rejoin: "..(os.time() - (savedState.rejoinTime or 0)).." detik")
    print("[ZenxInv] savedState.retryCount: "..tostring(savedState.retryCount))
end
print("============================================")

local rejoinStatus = "fresh"
local rejoinTimeAgo = nil
local retryCount = tonumber(savedState.retryCount or 0)
local triedJobIds = savedState.triedJobIds or {}
if savedState.lastJobId and savedState.lastJobId ~= "" then
    local elapsed = os.time() - (savedState.rejoinTime or 0)
    if elapsed < 600 then
        rejoinTimeAgo = elapsed
        if savedState.lastJobId == currentJobId then
            rejoinStatus = "same"
            print("[ZenxInv] WARN Server LAMA! Retry #"..retryCount.." JobId: "..currentJobId:sub(1,12).."...")
        else
            rejoinStatus = "new"
            print("[ZenxInv] OK Server BARU after "..retryCount.." retries. Old: "..savedState.lastJobId:sub(1,12).."... -> New: "..currentJobId:sub(1,12).."...")
            retryCount = 0
            triedJobIds = {}
        end
    end
end
local alreadyTried = false
for _, j in ipairs(triedJobIds) do
    if j == currentJobId then alreadyTried = true break end
end
if not alreadyTried then table.insert(triedJobIds, currentJobId) end
savedState.lastJobId = nil
savedState.rejoinTime = nil
savedState.retryCount = retryCount
savedState.triedJobIds = triedJobIds
saveState(savedState)

pcall(function()
    if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("ZenxInvGui") then
        player.PlayerGui.ZenxInvGui:Destroy()
    end
    if gethui then
        local hui = gethui()
        if hui and hui:FindFirstChild("ZenxInvGui") then hui.ZenxInvGui:Destroy() end
    end
    local cg = game:GetService("CoreGui")
    if cg:FindFirstChild("ZenxInvGui") then cg.ZenxInvGui:Destroy() end
end)

-- COLOR
local C = {
    BG=Color3.fromRGB(15,15,15), Panel=Color3.fromRGB(21,21,21), Card=Color3.fromRGB(25,25,25),
    White=Color3.fromRGB(225,225,225), Gray=Color3.fromRGB(120,120,120), Dim=Color3.fromRGB(55,55,55),
    Green=Color3.fromRGB(70,190,90), Red=Color3.fromRGB(200,60,60), RDim=Color3.fromRGB(35,10,10),
    Gold=Color3.fromRGB(220,160,0), Blue=Color3.fromRGB(80,150,255),
    Teal=Color3.fromRGB(40,200,160), TDim=Color3.fromRGB(8,30,24),
    Cyan=Color3.fromRGB(80,200,230), Purple=Color3.fromRGB(180,90,210),
    Pink=Color3.fromRGB(220,100,160), Orange=Color3.fromRGB(230,140,60),
    Black=Color3.fromRGB(0,0,0),
}

-- v5.15: gajah merah (tier 2) DIHAPUS dari CAT_BOT
local CAT_TOP = {
    {name="0-2",     min=0,    max=2,         color=C.Green},
    {name="2-3",     min=2,    max=3,         color=C.Gold},
    {name="3-3.7",   min=3,    max=3.7,       color=C.Orange},
    {name="3.8-4",   min=3.8,  max=4,         color=C.Red},
}
local CAT_BOT = {
    {name="3-4",     min=3,    max=4,         color=C.Green},
    {name="4-5",     min=4,    max=5,         color=C.Gold},
    {name="5-5.9",   min=5,    max=5.9,       color=C.Orange},
    {name="5.9-6.4", min=5.9,  max=6.4,       color=C.Red},
}
local CATEGORIES = CAT_TOP
local function categorize(kg)
    if not kg then return nil end
    for _, cat in ipairs(CATEGORIES) do
        if kg >= cat.min and kg < cat.max then return cat end
    end
    return CATEGORIES[#CATEGORIES]
end

-- HELPERS
local function mk(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    return o
end
local function corner(p, r) return mk("UICorner",{CornerRadius=UDim.new(0, r or 7), Parent=p}) end
local function stroke(p, col, th) return mk("UIStroke",{Color=col or C.Teal, Thickness=th or 1.5, Parent=p}) end
local function lbl(p, txt, ts, col, xa)
    return mk("TextLabel",{
        BackgroundTransparency=1, Text=txt, TextColor3=col or C.White,
        Font=Enum.Font.GothamBold, TextSize=ts or 11, TextScaled=false,
        TextXAlignment=xa or Enum.TextXAlignment.Left, Parent=p
    })
end
local function btn(p, txt, ts, bg, tc)
    local b = mk("TextButton",{
        BackgroundColor3=bg or C.Card, Text=txt, TextColor3=tc or C.White,
        Font=Enum.Font.GothamBold, TextSize=ts or 11, TextScaled=false, AutoButtonColor=false, Parent=p
    })
    corner(b, 7)
    return b
end
local function div(parent, lo)
    return mk("Frame",{Size=UDim2.new(1,0,0,1), BackgroundColor3=C.Dim, BorderSizePixel=0, LayoutOrder=lo, Parent=parent})
end
local function togRow(parent, labelTxt, descTxt, lo)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,32), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=lo, Parent=parent})
    corner(row, 6) local rowStroke = stroke(row, C.Dim, 1.1)
    local l = lbl(row, labelTxt, 9, C.White) l.Size = UDim2.new(0.65,0,0,16) l.Position = UDim2.new(0,8,0,4)
    if descTxt then
        local dl = lbl(row, descTxt, 8, C.Dim) dl.Size = UDim2.new(0.75,0,0,11) dl.Position = UDim2.new(0,8,0,19)
    end
    local tog = btn(row, "OFF", 9, C.Panel, C.Gray) tog.Size = UDim2.new(0,44,0,20) tog.Position = UDim2.new(1,-50,0.5,-10)
    local togStroke = stroke(tog, C.Dim, 1.1)
    return row, tog, togStroke, rowStroke
end
local function cfgRow(parent, labelTxt, lo, default, onChange)
    local r = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=lo, Parent=parent})
    corner(r, 6) stroke(r, C.Dim, 1.1)
    local l = lbl(r, labelTxt, 9, C.Gray) l.Size = UDim2.new(0.6,0,1,0) l.Position = UDim2.new(0,8,0,0)
    local box = mk("TextBox",{
        Size=UDim2.new(0,56,0,20), Position=UDim2.new(1,-62,0.5,-10),
        BackgroundColor3=C.Panel, Text=tostring(default), TextColor3=C.White,
        Font=Enum.Font.GothamBold, TextSize=10, TextScaled=false,
        TextXAlignment=Enum.TextXAlignment.Center, ClearTextOnFocus=false, Parent=r
    })
    corner(box, 5) stroke(box, C.Dim, 1)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        local v = tonumber(box.Text)
        if v then onChange(v) end
    end)
    return r, box
end

-- PET HELPERS
local function isPet(item) return item:FindFirstChild("PetToolLocal") or item:FindFirstChild("PetToolServer") end
local function isFavorite(item)
    for _, attr in ipairs({"Loved","IsLoved","Heart","Hearted","Liked","IsLiked","IsHeart","Love","HeartIcon","Favorited","Favourited","Favorite","Favourite","IsFavorited","IsFavourited","d"}) do
        local v = item:GetAttribute(attr) if v == true then return true end
    end
    return false
end
local function getPetName(item) return item.Name:match("^(.-)%s*%[") or item.Name end
local function getKG(item)
    local n = item.Name
    local kg = n:match("%[%s*([%d%.]+)%s*[Kk][Gg]%s*%]")
    if kg then return tonumber(kg) end
    kg = n:match("([%d%.]+)%s*[Kk][Gg]")
    if kg then return tonumber(kg) end
    return nil
end
local function getAge(item)
    if getgenv().ZenxInvAPS then
        local okU, uuid = pcall(function() return item:GetAttribute("PET_UUID") end)
        if okU and uuid then
            local age = getgenv().ZenxInvAPS.getAge(uuid)
            if age then return age end
        end
    end
    local ok, attrs = pcall(function() return item:GetAttributes() end)
    if ok and attrs then
        for k, v in pairs(attrs) do
            if tonumber(v) and tonumber(v) > 0 and tonumber(v) <= 200 then
                local kl = k:lower()
                if kl == "age" or kl == "level" or kl == "petage" or kl == "petlevel"
                    or kl == "displayage" or kl == "currentage" or kl == "currentlevel" then
                    return tonumber(v)
                end
            end
        end
    end
    for _, childName in ipairs({"Age", "AGE", "age", "Level", "LEVEL", "level", "PetAge", "PetLevel"}) do
        local c = item:FindFirstChild(childName)
        if c and c.Value and tonumber(c.Value) then return tonumber(c.Value) end
    end
    local n = item.Name
    for _, pat in ipairs({
        "%[Age%s+(%d+)%]","%[Age(%d+)%]",
        "%[Lv%s+(%d+)%]","%[Lv(%d+)%]",
        "%[Level%s+(%d+)%]","%[Level(%d+)%]",
        "%[Lvl%s+(%d+)%]","%[Lvl(%d+)%]",
        "Age%s*[:=]%s*(%d+)","Lv%s*[:=]%s*(%d+)","Level%s*[:=]%s*(%d+)",
    }) do
        local f = n:match(pat) if f then return tonumber(f) end
    end
    if n:match("%[Age%s*MAX%]") or n:match("%[MAX%]") then return 100 end
    return nil
end

local MUTATION_NAMES = {
    "Alienated","Ancient","Angelic","Aromatic","Ascended","Astral","Aurora",
    "Bearded","Blazing","Blessed","Blossoming","Bloodlust",
    "Celestial","Chaotic","Chilled","Chocolate","Christmas","Chromatic","Corrupt","Corrupted",
    "Cosmic","Crocodile","Crystal","Cursed",
    "Dawn","Demonic","Diamond","Disco","Divine","Dreadbound",
    "Eclipse","Eclipsed","Eldritch","Enchanted","Ethereal","Everchanted",
    "Fiery","Forger","Fried","Frostbite","Frozen",
    "Galactic","GIANT","Giraffe","Ghostly","Glacial","Glimmering","Gold","Golden",
    "HyperHunger","Holy",
    "Icy","Infernal","Inferno","Inverted","IronSkin",
    "JollyDecorator","JUMBO",
    "Lion","Lunar","Luminous",
    "Mega","MerryNursery","Mimic","Mini","Moonlit","Mystic","Mythic",
    "Nightmare","Nocturnal","Nutty",
    "Oxpecker",
    "Peppermint","Phantom","Plasma","Prismatic","Primal",
    "Radiant","Rainbow","Rhino","Rideable","Royal",
    "Shadow","Shiny","Shocked","Silver","SpiritSparkle","Solar","Soulflame","Sparkling","Spectral","Starlit","Stellar","Storm",
    "Tempest","Tethered","Tiny","Toxic","Tranquil","Twilight",
    "UFO",
    "Venom","Verdant","Volcanic",
    "Wet","Windy",
    "Zombified",
    "Christmas Rally","ChristmasRally",
    "Giant Bean","GiantBean",
    "Giant Golem","GiantGolem",
    "Hyper Hunger",
    "Iron Skin",
    "Jolly Decorator",
    "Merry Nursery","MerryNursery",
    "Spirit Sparkle",
}
local MUTATION_PREFIXES = {}
for _, m in ipairs(MUTATION_NAMES) do
    table.insert(MUTATION_PREFIXES, m..", ")
    table.insert(MUTATION_PREFIXES, m.." ")
end
local function hasMutation(item)
    if not item then return false end
    local name = item.Name or ""
    for _, prefix in ipairs(MUTATION_PREFIXES) do
        if name:sub(1, #prefix) == prefix then return true end
    end
    return false
end
local CONFLICTING_PET_NAMES = {
    ["Mimic Octopus"] = true,
}
local function getBaseName(name)
    if CONFLICTING_PET_NAMES[name] then return name end
    local result = name
    local changed = true
    while changed do
        changed = false
        for _, prefix in ipairs(MUTATION_PREFIXES) do
            if result:sub(1, #prefix) == prefix then
                local stripped = result:sub(#prefix + 1)
                if stripped == "" then break end
                result = stripped
                changed = true
                if CONFLICTING_PET_NAMES[result] then return result end
                break
            end
        end
    end
    return result
end
local maxKGCache = {}
local function buildMaxKGCache()
    maxKGCache = {}
    local bp = player:FindFirstChild("Backpack") if not bp then return end
    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local name = getPetName(item)
            local age = getAge(item)
            local kg = getKG(item)
            if name and age and kg and age >= 0 then
                local maxKG = kg * 11 / (age + 10)
                local existing = maxKGCache[name]
                if not existing or maxKG > existing then maxKGCache[name] = maxKG end
                local base = getBaseName(name)
                if base ~= name then
                    local existingBase = maxKGCache[base]
                    if not existingBase or maxKG > existingBase then maxKGCache[base] = maxKG end
                end
            end
        end
    end
end
local function getMaxKGForPet(name)
    if maxKGCache[name] then return maxKGCache[name] end
    local base = getBaseName(name)
    if maxKGCache[base] then return maxKGCache[base] end
    return nil
end
local function getEstimatedAge(item)
    local age = getAge(item) if age then return age end
    local kg = getKG(item) if not kg then return nil end
    local maxKG = getMaxKGForPet(getPetName(item))
    if maxKG and maxKG > 0 then
        return math.max(0, math.min(200, math.floor(kg * 11 / maxKG - 10 + 0.5)))
    end
    return nil
end
local function getPetBaseKG(item)
    if getgenv().ZenxInvAPS then
        local okU, uuid = pcall(function() return item:GetAttribute("PET_UUID") end)
        if okU and uuid then
            local bw = getgenv().ZenxInvAPS.getBaseKg(uuid)
            if bw and bw > 0 then return bw * 1.1 end
        end
    end
    return getKG(item)
end
local function calcBaseKG(kg, age)
    if not kg or not age or age < 1 then return nil end
    return kg * 11 / (age + 10)
end

-- ============================================
-- BUILD GUI
-- ============================================
local GUI_W = 420 local GUI_H_COMPACT = 150 local GUI_H_FULL = 300 local GUI_H = GUI_H_COMPACT
local guiParent = player:WaitForChild("PlayerGui")
local protected = false
do
    local ok, hui = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    if ok and hui then
        guiParent = hui
        protected = true
        print("[ZenxInv] GUI parented to gethui() — protected from destroy")
    else
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then
            local test = pcall(function()
                local tmp = Instance.new("ScreenGui")
                tmp.Name = "_zenxTest"
                tmp.Parent = cg
                tmp:Destroy()
            end)
            if test then
                guiParent = cg
                protected = true
                print("[ZenxInv] GUI parented to CoreGui — protected")
            end
        end
    end
    if not protected then
        print("[ZenxInv] GUI di PlayerGui (gak protected)")
    end
end
local sg = mk("ScreenGui",{
    Name="ZenxInvGui",
    DisplayOrder=2147483647,
    ResetOnSpawn=false,
    IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=guiParent
})
task.spawn(function()
    while sg do
        task.wait(2)
        pcall(function()
            if sg.DisplayOrder ~= 2147483647 then sg.DisplayOrder = 2147483647 end
            if not sg.Parent or sg.Parent == nil then sg.Parent = guiParent end
        end)
    end
end)
local main = mk("Frame",{
    Size=UDim2.new(0, GUI_W, 0, GUI_H),
    AnchorPoint=Vector2.new(0, 1),
    Position=UDim2.new(0, 70, 1, -75),  -- v5.25: spawn 75px dari bawah
    BackgroundColor3=C.BG, BorderSizePixel=0, Active=true, Draggable=true,
    Visible=true,
    Parent=sg
})
corner(main, 10) stroke(main, C.Teal, 2)

local TB = mk("Frame",{Size=UDim2.new(1,0,0,34), BackgroundColor3=C.Panel, BorderSizePixel=0, Parent=main})
corner(TB, 10)
mk("Frame",{Size=UDim2.new(1,0,0,1.5), Position=UDim2.new(0,0,1,-1.5), BackgroundColor3=C.Teal, BorderSizePixel=0, Parent=TB})
-- v5.30: tampilin versi di title bar biar tau udah update apa belum
local _verShort = SCRIPT_VERSION:match("^(v[%d%.]+)") or SCRIPT_VERSION
local titleLbl = lbl(TB, "ZENX INV  "..(_verShort or ""), 11, C.Teal)
titleLbl.Size = UDim2.new(0, 150, 1, 0) titleLbl.Position = UDim2.new(0, 10, 0, 0)
-- v5.22: pet picker button di TITLE BAR (kayak kg_stat, selalu keliatan)
local petPickBtn = btn(TB, "Pet ▼", 10, C.Card, C.Teal)
petPickBtn.Size = UDim2.new(0,118,0,22) petPickBtn.Position = UDim2.new(1,-200,0.5,-11)
stroke(petPickBtn, C.Dim, 1.1)
local expBtn = btn(TB, "+", 14, C.TDim, C.Teal)
expBtn.Size = UDim2.new(0,22,0,22) expBtn.Position = UDim2.new(1,-76,0.5,-11) stroke(expBtn, C.Teal, 1.2)
local minBtn = btn(TB, "-", 13, C.Panel, C.Gray)
minBtn.Size = UDim2.new(0,22,0,22) minBtn.Position = UDim2.new(1,-50,0.5,-11) stroke(minBtn, C.Dim, 1.2)
local closeBtn = btn(TB, "X", 10, C.RDim, C.Red)
closeBtn.Size = UDim2.new(0,22,0,22) closeBtn.Position = UDim2.new(1,-24,0.5,-11) stroke(closeBtn, C.Red, 1.2)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local miniIcon = mk("TextButton",{
    Size=UDim2.new(0,40,0,40),
    Position=UDim2.new(0,18,0.5,-20),
    BackgroundColor3=C.BG, Text="Z", TextColor3=C.Teal,
    Font=Enum.Font.GothamBold, TextSize=22, AutoButtonColor=false,
    Visible=false, Active=false, Draggable=false, Parent=sg
})
corner(miniIcon, 8) stroke(miniIcon, C.Teal, 2)
minBtn.MouseButton1Click:Connect(function() main.Visible=false miniIcon.Visible=true end)
miniIcon.MouseButton1Click:Connect(function() main.Visible=true miniIcon.Visible=false end)

local content = mk("ScrollingFrame",{
    Size=UDim2.new(1,-10,1,-44), Position=UDim2.new(0,5,0,39),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=4, AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=main
})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5), Parent=content})
mk("UIPadding",{PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2), Parent=content})

local invHeader = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Panel, BorderSizePixel=0, LayoutOrder=1, Parent=content})
corner(invHeader, 7) stroke(invHeader, C.Dim, 1.2)
local invHeaderLbl = lbl(invHeader, "Pet Inventory (loading...)", 10, C.Teal)
invHeaderLbl.Size = UDim2.new(1,-100,1,0) invHeaderLbl.Position = UDim2.new(0,8,0,0)
local invRefreshBtn = btn(invHeader, "Refresh", 9, C.TDim, C.Teal)
invRefreshBtn.Size = UDim2.new(0,80,0,20) invRefreshBtn.Position = UDim2.new(1,-86,0.5,-10)
stroke(invRefreshBtn, C.Teal, 1.2)

-- v5.21: PILIH JENIS PET (multi-select) — pill ngitung semua jenis terpilih (kosong = semua)
local selectedPetTypes = {}  -- set: {typeName = true}
do
    local saved = savedState.selectedPetTypes
    if type(saved) == "table" then
        for _, t in ipairs(saved) do selectedPetTypes[t] = true end
    elseif type(savedState.selectedPetType) == "string" then
        selectedPetTypes[savedState.selectedPetType] = true  -- migrasi dari versi single
    end
end
local function countSelected()
    local n = 0
    for _ in pairs(selectedPetTypes) do n = n + 1 end
    return n
end
-- petPickBtn udah dibuat di title bar (v5.22). Cuma update teksnya:
local function updatePetPickBtn()
    local n = countSelected()
    if n == 0 then
        petPickBtn.Text = "Pet ▼"
        petPickBtn.TextColor3 = C.Teal
    elseif n == 1 then
        local nm for k in pairs(selectedPetTypes) do nm = k break end
        petPickBtn.Text = "Pet: "..(#nm > 10 and nm:sub(1,9).."…" or nm)
        petPickBtn.TextColor3 = C.Gold
    else
        petPickBtn.Text = "Pet: "..n.." ✓"
        petPickBtn.TextColor3 = C.Gold
    end
end
updatePetPickBtn()

-- v5.19: bot row dihapus — cuma 1 row pill (TOP)
local catRow1 = mk("Frame",{Size=UDim2.new(1,0,0,42), BackgroundTransparency=1, LayoutOrder=2, Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,3), HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=catRow1})

local PILL_W = 88
local PILL_W_GAJAH = 72
local catTopLabels = {}
for i, cat in ipairs(CAT_TOP) do
    local w = cat.no_text and PILL_W_GAJAH or PILL_W
    local pill = mk("Frame",{Size=UDim2.new(0, w, 1, 0), BackgroundColor3=cat.bg or C.Card, BorderSizePixel=0, LayoutOrder=i, Parent=catRow1})
    corner(pill, 5) stroke(pill, C.Dim, 1)
    local initText = cat.no_text and cat.name or (cat.name..": 0")
    local pl = lbl(pill, initText, 16, cat.no_text and (cat.color or C.White) or C.Gray, Enum.TextXAlignment.Center)
    pl.Size = UDim2.new(1,0,1,0)
    pl.Font = Enum.Font.GothamBold
    pl.RichText = true
    catTopLabels[i] = pl
end
local catBotLabels = {}  -- v5.19: kosong (bot row dihapus)
local catLabels = catTopLabels

local detailTotal = {Text="", TextColor3=C.Teal}
local detailFav = {Text="", TextColor3=C.Gold}
local detailHigh = {Text="", TextColor3=C.Green}
local detailKG = {Text="", TextColor3=C.Blue}
local detailUnread = {Text="", TextColor3=C.Gray}

div(content, 4)

-- v6.0: REJOIN dimatiin — UI-nya dibangun ke frame tersembunyi (semua ref logic lama tetep valid, tapi ga keliatan & ga jalan)
local _realContent = content
local _rejoinHide = mk("Frame", { Size = UDim2.new(0,10,0,10), Visible = false, Name = "RejoinHidden", Parent = sg })
content = _rejoinHide
local rejoinHeader = lbl(content, "REJOIN", 9, C.Teal) rejoinHeader.Size=UDim2.new(1,0,0,14) rejoinHeader.LayoutOrder=5
local rnBtn = btn(content, "Rejoin Now", 10, C.TDim, C.Teal)
rnBtn.Size = UDim2.new(1,0,0,24) rnBtn.LayoutOrder=6 stroke(rnBtn, C.Teal, 1.5)
local rejoinMinutes = tonumber(savedState.rejoinMinutes) or 30
if rejoinMinutes < 1 then rejoinMinutes = 30 end  -- v5.35: fix interval 0 -> rejoin instan loop
cfgRow(content, "Interval (menit)", 7, rejoinMinutes, function(v)
    rejoinMinutes = math.max(1, math.min(120, v))
    saveState({autoRejoin=savedState.autoRejoin, rejoinMinutes=rejoinMinutes,
               rejoinDelay=savedState.rejoinDelay, serverHistory=savedState.serverHistory})
end)
local rejoinDelay = tonumber(savedState.rejoinDelay) or 5
savedState.rejoinDelay = rejoinDelay
cfgRow(content, "Delay TP (detik)", 7.5, rejoinDelay, function(v)
    rejoinDelay = math.max(0, math.min(30, v))
    savedState.rejoinDelay = rejoinDelay
    saveState(savedState)
end)
-- v5.26: tunggu di publik berapa detik sebelum balik ke PS (biar PS lama mati -> fresh)
local bounceWaitSec = tonumber(savedState.bounceWaitSec) or 20
savedState.bounceWaitSec = bounceWaitSec
cfgRow(content, "Tunggu publik (detik)", 7.6, bounceWaitSec, function(v)
    bounceWaitSec = math.max(0, math.min(180, v))
    savedState.bounceWaitSec = bounceWaitSec
    saveState(savedState)
end)
local psLink = savedState.psLink or ""
local psLinkCode = savedState.psLinkCode or ""
local function parsePsLink(link)
    if not link or link == "" then return "" end
    -- v5.27: support banyak format link PS
    -- 1. format lama: ...privateServerLinkCode=XXX
    local code = link:match("privateServerLinkCode=([^&%s]+)")
    if code then return code end
    -- 2. format share baru: ...share?code=XXX&type=Server
    code = link:match("[?&]code=([^&%s]+)")
    if code then return code end
    -- 3. accessCode (reserved server)
    code = link:match("accessCode=([^&%s]+)")
    if code then return code end
    -- 4. bare code (cuma kode-nya doang, panjang >=20)
    if link:match("^[%w%-_]+$") and #link >= 20 then return link end
    return ""
end
do
    local r = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=7.7, Parent=content})
    corner(r, 6) stroke(r, C.Dim, 1.1)
    local l = lbl(r, "PS Link", 9, C.Gray) l.Size = UDim2.new(0.25,0,1,0) l.Position = UDim2.new(0,8,0,0)
    local box = mk("TextBox",{
        Size=UDim2.new(0.7,-10,0,20), Position=UDim2.new(0.3,0,0.5,-10),
        BackgroundColor3=C.Panel, Text=psLink, PlaceholderText="paste link / kosong = OFF",
        TextColor3=C.White, PlaceholderColor3=C.Dim,
        Font=Enum.Font.Gotham, TextSize=9, TextScaled=false,
        TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=r
    })
    corner(box, 5) stroke(box, C.Dim, 1)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        psLink = box.Text
        psLinkCode = parsePsLink(psLink)
        savedState.psLink = psLink
        savedState.psLinkCode = psLinkCode
        saveState(savedState)
        if psLinkCode ~= "" then
            print("[ZenxInv] PS code OK: "..psLinkCode:sub(1, 12).."...")
        end
    end)
    if psLink ~= "" then
        psLinkCode = parsePsLink(psLink)
        savedState.psLinkCode = psLinkCode
        saveState(savedState)
    end
end
-- v5.29: Script URL — buat auto-reload abis teleport (wajib biar bounce balik ke PS otomatis)
do
    local r = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=7.75, Parent=content})
    corner(r, 6) stroke(r, C.Dim, 1.1)
    local l = lbl(r, "Script URL", 9, C.Gray) l.Size = UDim2.new(0.28,0,1,0) l.Position = UDim2.new(0,8,0,0)
    local box = mk("TextBox",{
        Size=UDim2.new(0.67,-10,0,20), Position=UDim2.new(0.33,0,0.5,-10),
        BackgroundColor3=C.Panel, Text=savedState.scriptUrl or "", PlaceholderText="raw url script (buat auto-reload)",
        TextColor3=C.White, PlaceholderColor3=C.Dim,
        Font=Enum.Font.Gotham, TextSize=9, TextScaled=false,
        TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=r
    })
    corner(box, 5) stroke(box, C.Dim, 1)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        savedState.scriptUrl = box.Text
        saveState(savedState)
        if box.Text ~= "" then print("[ZenxInv] Script URL set: "..box.Text:sub(1,30).."...") end
    end)
end
local bounceMode = savedState.bounceMode or false
local _, bcTog, bcTogStroke, bcStroke = togRow(content, "Bounce via Public", "Public dulu, terus balik ke PS", 7.8)
local function setBounceTog(v)
    bcTog.Text = v and "ON" or "OFF"
    bcTog.BackgroundColor3 = v and C.TDim or C.Panel
    bcTog.TextColor3 = v and C.Teal or C.Gray
    bcTogStroke.Color = v and C.Teal or C.Dim
    bcStroke.Color = v and C.Teal or C.Dim
end
setBounceTog(bounceMode)
bcTog.MouseButton1Click:Connect(function()
    bounceMode = not bounceMode
    savedState.bounceMode = bounceMode
    saveState(savedState)
    setBounceTog(bounceMode)
    print("[ZenxInv] Bounce mode: "..(bounceMode and "ON" or "OFF"))
end)
local _, arTog, arTogStroke, arStroke = togRow(content, "Auto Rejoin", "Rejoin otomatis sesuai interval", 8)
-- v5.39: tombol RESET State — hapus semua flag nyangkut (bouncePending, autoRejoin, lastJobId)
local resetBtn = btn(content, "RESET State (hapus flag nyangkut)", 9, C.RDim, C.Red)
resetBtn.Size = UDim2.new(1,0,0,22) resetBtn.LayoutOrder = 8.5 stroke(resetBtn, C.Red, 1.2)
resetBtn.MouseButton1Click:Connect(function()
    savedState.bouncePending = false
    savedState.bounceTime = nil
    savedState.bouncePsCode = nil
    savedState.autoRejoin = false
    savedState.lastJobId = nil
    savedState.rejoinTime = nil
    savedState.retryCount = 0
    savedState.triedJobIds = {}
    saveState(savedState)
    isAR = false
    if arTask then pcall(function() task.cancel(arTask) end) arTask = nil end
    resetBtn.Text = "✓ State di-reset (flag bersih)"
    resetBtn.TextColor3 = C.Green
    print("[ZenxInv] STATE RESET — semua flag teleport di-clear")
    task.spawn(function() task.wait(3) resetBtn.Text = "RESET State (hapus flag nyangkut)" resetBtn.TextColor3 = C.Red end)
end)
local cdLbl = lbl(content, "Auto Rejoin: OFF", 9, C.Gray, Enum.TextXAlignment.Center)
cdLbl.Size = UDim2.new(1,0,0,20) cdLbl.LayoutOrder=9 cdLbl.BackgroundColor3=C.Panel cdLbl.BackgroundTransparency=0
corner(cdLbl, 6) stroke(cdLbl, C.Dim, 1.1)
local ageLbl = lbl(content, "Server age: ?", 9, C.Gray, Enum.TextXAlignment.Center)
ageLbl.Size = UDim2.new(1,0,0,20) ageLbl.LayoutOrder=10
ageLbl.BackgroundColor3=C.Panel ageLbl.BackgroundTransparency=0
corner(ageLbl, 6) stroke(ageLbl, C.Dim, 1.1)
local dbgLbl = lbl(content, "", 8, C.Gray, Enum.TextXAlignment.Center)
dbgLbl.Size = UDim2.new(1,0,0,32) dbgLbl.LayoutOrder=11
dbgLbl.BackgroundColor3=C.Panel dbgLbl.BackgroundTransparency=0
dbgLbl.TextWrapped = true
corner(dbgLbl, 6) stroke(dbgLbl, C.Dim, 1.1)
local function buildDbgText()
    local lines = {}
    table.insert(lines, "JobId: "..currentJobId:sub(1, 12))
    if rejoinStatus == "fresh" then
        table.insert(lines, "Status: FRESH (gak ada history)")
    elseif rejoinStatus == "new" then
        table.insert(lines, "Status: BARU (rejoin OK)")
    elseif rejoinStatus == "same" then
        table.insert(lines, "Status: LAMA (retry #"..(retryCount or 0)..")")
    end
    return table.concat(lines, "\n")
end
dbgLbl.Text = ""
local rawLbl = lbl(content, "", 8, C.Gray, Enum.TextXAlignment.Center)
rawLbl.Size = UDim2.new(1,0,0,16) rawLbl.LayoutOrder=12
rawLbl.BackgroundTransparency = 1
rawLbl.TextSize = 9
content = _realContent  -- v6.0: balik ke content asli. mulai sini = section GIFT (ganti rejoin)

-- ===================== GIFT (v6.0) =====================
-- remote gift (port dari try.lua): PetGiftingService + module PGS
local giftRE, PGS = nil, nil
pcall(function()
    local ge = RS:FindFirstChild("GameEvents")
    if ge then giftRE = ge:FindFirstChild("PetGiftingService") end
    if not giftRE then giftRE = RS:FindFirstChild("PetGiftingService", true) end
end)
pcall(function()
    local mods = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("PetServices")
    local gm = mods and mods:FindFirstChild("PetGiftingInputService")
    if gm then local ok, mod = pcall(require, gm); if ok then PGS = mod end end
end)
local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local low = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (p.Name:lower() == low or p.DisplayName:lower() == low) then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (p.Name:lower():find(low,1,true) or p.DisplayName:lower():find(low,1,true)) then return p end
    end
    return nil
end
local function giftPetToPlayer(targetPlayer, petTool)
    if not targetPlayer or not petTool then return false end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    pcall(function() hum:EquipTool(petTool) end)
    task.wait(0.12)
    if PGS and PGS.GivePet then
        pcall(function() PGS.GivePet(targetPlayer) end)
        task.wait(0.18)
        if not petTool.Parent then return true end
    end
    if giftRE then
        local u = tostring(petTool:GetAttribute("PET_UUID"))
        if u:sub(1,1) ~= "{" then u = "{"..u.."}" end
        pcall(function() giftRE:FireServer("GivePet", targetPlayer, u) end)
        task.wait(0.18)
        if not petTool.Parent then return true end
    end
    return false
end

-- ===== RELAY (port dari gag2: Pantry getpantry.cloud) =====
-- tiap akun PUT key=nama sendiri (PUT=merge, anti-race), akun lain GET baca semua.
-- akun TARGET nyalain "Lapor ke relay" -> tiap 10s kirim jumlah pet-nya.
-- akun PENGIRIM baca count target -> kalau >= batas -> target penuh -> jeda.
local PANTRY_BASE = "https://getpantry.cloud/apiv1/pantry/25efb22c-2754-4d73-bf2d-e3aa987b52c6/basket/"
local relayUrl = savedState.relayUrl or (PANTRY_BASE.."zenxpetcount")
local function relayReq(opts)
    local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if not req then return nil end
    local ok, resp = pcall(function() return req(opts) end)
    if ok then return resp end
    return nil
end
local function myPetCount()
    local n = 0
    for _, holder in ipairs({player.Character, player:FindFirstChildOfClass("Backpack")}) do
        if holder then for _, t in ipairs(holder:GetChildren()) do
            if t:IsA("Tool") and isPet(t) then n = n + 1 end
        end end
    end
    return n
end
-- batas inventory (port dari hact3): scan getgc cari MaxPetsInInventory (ambil terbesar), cache 30s.
-- otomatis ikut upgrade akun. fallback attribute MaxPets.
local _maxPetsCache, _maxPetsAt = nil, 0
local function getMaxPets()
    if _maxPetsCache and (tick() - _maxPetsAt) < 30 then return _maxPetsCache end
    local best = nil
    pcall(function()
        if getgc then
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    local mp = rawget(obj, "MaxPetsInInventory")
                    if type(mp) == "number" and mp > 0 and (not best or mp > best) then best = mp end
                end
            end
        end
    end)
    if not best then
        pcall(function()
            local m = player:GetAttribute("MaxPets") or player:GetAttribute("MaxPetsInInventory")
            if type(m) == "number" and m > 0 then best = m end
        end)
    end
    _maxPetsCache = best; _maxPetsAt = tick()
    return best
end
local function relayReport()  -- akun target: lapor count + batas sendiri (PUT merge)
    if relayUrl == "" then return end
    local payload = HttpService:JSONEncode({ [player.Name] = { c = myPetCount(), m = getMaxPets() or 0, t = os.time() } })
    pcall(function() relayReq({ Url=relayUrl, Method="PUT", Headers={["Content-Type"]="application/json"}, Body=payload }) end)
end
local _relayCache, _relayCacheAt = nil, 0
local function relayGetAll()  -- GET semua (cache 8s biar ga spam)
    if relayUrl == "" then return nil end
    local now = os.clock()
    if _relayCache and (now - _relayCacheAt) < 8 then return _relayCache end
    local resp = relayReq({ Url=relayUrl, Method="GET" })
    local body = resp and (resp.Body or resp.body)
    local d = nil
    if body then local ok, parsed = pcall(function() return HttpService:JSONDecode(body) end); if ok then d = parsed end end
    _relayCache = d or false; _relayCacheAt = now
    return d
end
local function relayTargetData(name)  -- return count, max target dari relay (nil kalau ga ada / basi)
    if not name or name == "" then return nil, nil end
    local d = relayGetAll()
    if type(d) ~= "table" then return nil, nil end
    local e = d[name]
    if type(e) == "table" and type(e.c) == "number" then
        if not e.t or (os.time() - e.t) < 60 then  -- fresh < 60s
            return e.c, (type(e.m) == "number" and e.m > 0 and e.m or nil)
        end
    end
    return nil, nil
end

div(content, 4.5)
local giftHeader = lbl(content, "GIFT", 9, C.Teal) giftHeader.Size=UDim2.new(1,0,0,14) giftHeader.LayoutOrder=5

-- target: ketik username (ke-save, kayak rejoin) + tombol pilih dari server
local giftTarget = savedState.giftTarget or ""
local tgtRow = mk("Frame", { Size=UDim2.new(1,0,0,24), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=6, Parent=content })
corner(tgtRow, 6) stroke(tgtRow, C.Teal, 1.2)
local tgtBox = mk("TextBox", {
    Size=UDim2.new(1,-66,1,-6), Position=UDim2.new(0,6,0,3),
    BackgroundColor3=C.Panel, Text=giftTarget, PlaceholderText="ketik username target",
    TextColor3=C.White, PlaceholderColor3=C.Dim, Font=Enum.Font.GothamBold, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=tgtRow
})
corner(tgtBox, 5) stroke(tgtBox, C.Dim, 1)
tgtBox:GetPropertyChangedSignal("Text"):Connect(function()
    giftTarget = tgtBox.Text; savedState.giftTarget = giftTarget; saveState(savedState)
end)
local pickBtn = btn(tgtRow, "Pilih", 9, C.Panel, C.Teal)
pickBtn.Size = UDim2.new(0,56,1,-6) pickBtn.Position = UDim2.new(1,-60,0,3) stroke(pickBtn, C.Teal, 1)
local listFrame = mk("Frame", { Size=UDim2.new(1,0,0,0), BackgroundColor3=C.Panel, BorderSizePixel=0, LayoutOrder=6.5, Visible=false, Parent=content })
corner(listFrame, 6) mk("UIListLayout", { Padding=UDim.new(0,2), Parent=listFrame })
local function refreshList()
    for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local h = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local pb = btn(listFrame, p.Name, 9, C.Card, C.White)
            pb.Size = UDim2.new(1,0,0,20) pb.LayoutOrder = h
            pb.MouseButton1Click:Connect(function()
                giftTarget = p.Name; savedState.giftTarget = giftTarget; saveState(savedState)
                tgtBox.Text = giftTarget
                listFrame.Visible = false; listFrame.Size = UDim2.new(1,0,0,0)
            end)
            h = h + 1
        end
    end
    listFrame.Size = UDim2.new(1,0,0, math.max(1,h)*22)
end
pickBtn.MouseButton1Click:Connect(function()
    if listFrame.Visible then listFrame.Visible=false; listFrame.Size=UDim2.new(1,0,0,0)
    else refreshList(); listFrame.Visible=true end
end)

-- metode: Direct (on/off) + Trade Tiket (on/off, step 2)
local giftDirect = savedState.giftDirect ~= false   -- default ON
local _, dirTog, dirTS, dirRS = togRow(content, "Metode Tanpa Tiket", "gift langsung satu-satu", 7)
local function setDir(v) dirTog.Text=v and "ON" or "OFF"; dirTog.BackgroundColor3=v and C.TDim or C.Panel; dirTog.TextColor3=v and C.Teal or C.Gray; dirTS.Color=v and C.Teal or C.Dim; dirRS.Color=v and C.Teal or C.Dim end
setDir(giftDirect)
dirTog.MouseButton1Click:Connect(function() giftDirect=not giftDirect; savedState.giftDirect=giftDirect; saveState(savedState); setDir(giftDirect) end)
local giftTicket = savedState.giftTicket or false    -- default OFF (step 2)
local _, tikTog, tikTS, tikRS = togRow(content, "Metode Pakai Tiket", "borongan (segera, step 2)", 7.5)
local function setTik(v) tikTog.Text=v and "ON" or "OFF"; tikTog.BackgroundColor3=v and C.TDim or C.Panel; tikTog.TextColor3=v and C.Teal or C.Gray; tikTS.Color=v and C.Teal or C.Dim; tikRS.Color=v and C.Teal or C.Dim end
setTik(giftTicket)
tikTog.MouseButton1Click:Connect(function() giftTicket=not giftTicket; savedState.giftTicket=giftTicket; saveState(savedState); setTik(giftTicket) end)

-- filter: base weight min-max + gate jumlah
local giftKgMin = tonumber(savedState.giftKgMin) or 3
cfgRow(content, "Base weight min (kg)", 8, giftKgMin, function(v) giftKgMin = math.max(0, v); savedState.giftKgMin=giftKgMin; saveState(savedState) end)
local giftKgMax = tonumber(savedState.giftKgMax) or 4
cfgRow(content, "Base weight max (kg)", 8.2, giftKgMax, function(v) giftKgMax = math.max(0, v); savedState.giftKgMax=giftKgMax; saveState(savedState) end)
local giftGateN = tonumber(savedState.giftGateN) or 20
cfgRow(content, "Gate: kumpul brp pet", 8.5, giftGateN, function(v) giftGateN = math.max(1, math.floor(v)); savedState.giftGateN=giftGateN; saveState(savedState) end)

-- (v6.6) fitur "Lapor pet ke relay" + "Batas manual via relay" DIBUANG (bikin bug/lag).


-- pet yg cocok: base weight (age-1) di rentang giftKgMin..giftKgMax
local function matchingPets()
    local list = {}
    local APS = getgenv and getgenv().ZenxInvAPS
    for _, holder in ipairs({player.Character, player:FindFirstChildOfClass("Backpack")}) do
        if holder then
            for _, t in ipairs(holder:GetChildren()) do
                if t:IsA("Tool") and isPet(t) then
                    local uuid = t:GetAttribute("PET_UUID")
                    local bw = uuid and APS and APS.getBaseKg(uuid)
                    if bw and bw >= giftKgMin and bw <= giftKgMax then list[#list+1] = t end
                end
            end
        end
    end
    return list
end

-- auto gift: DEFAULT ON (always on, langsung jalan pas load) + status
local giftRunning = true
local _, agTog, agTS, agRS = togRow(content, "Auto Gift", "always on (jalan kalau pet >= gate)", 9)
local function setAg(v) agTog.Text=v and "ON" or "OFF"; agTog.BackgroundColor3=v and C.TDim or C.Panel; agTog.TextColor3=v and C.Teal or C.Gray; agTS.Color=v and C.Teal or C.Dim; agRS.Color=v and C.Teal or C.Dim end
local giftStatus = lbl(content, "Gift: ON", 9, C.Teal, Enum.TextXAlignment.Center)
giftStatus.Size=UDim2.new(1,0,0,30) giftStatus.LayoutOrder=10 giftStatus.BackgroundColor3=C.Panel giftStatus.BackgroundTransparency=0 giftStatus.TextWrapped=true
corner(giftStatus, 6) stroke(giftStatus, C.Dim, 1.1)
local giftLoopActive = false
local function runGiftLoop()
    if giftLoopActive then return end
    giftLoopActive = true
    task.spawn(function()
        while giftRunning do
            do
                local target = findPlayerByName(giftTarget)
                local pets = matchingPets()
                if not target then
                    giftStatus.Text="Target ga ketemu: "..(giftTarget~="" and giftTarget or "(blm diisi)"); giftStatus.TextColor3=C.Red
                    task.wait(3)
                elseif #pets < giftGateN then
                    giftStatus.Text="Nunggu: "..#pets.."/"..giftGateN.." pet "..giftKgMin.."-"..giftKgMax.."kg"; giftStatus.TextColor3=C.Gold
                    task.wait(3)
                else
                    giftStatus.Text="Gift "..#pets.." pet ke "..target.Name.."..."; giftStatus.TextColor3=C.Teal
                    local sent, failStreak = 0, 0
                    for _, pt in ipairs(pets) do
                        if not giftRunning then break end
                        local ok = giftDirect and giftPetToPlayer(target, pt)
                        if ok then sent = sent + 1; failStreak = 0
                        else failStreak = failStreak + 1; if failStreak >= 3 then break end end  -- 3 gagal beruntun = target penuh
                        task.wait(0.2)
                    end
                    giftStatus.Text="Kekirim "..sent.." pet (cek lagi)"; giftStatus.TextColor3=C.Green
                    task.wait(3)
                end
            end
        end
        giftStatus.Text="Gift: OFF"; giftStatus.TextColor3=C.Gray
        giftLoopActive = false
    end)
end
setAg(giftRunning)
agTog.MouseButton1Click:Connect(function()
    giftRunning = not giftRunning; setAg(giftRunning)
    if giftRunning then runGiftLoop()
    else giftStatus.Text="Gift: OFF"; giftStatus.TextColor3=C.Gray end
end)
if giftRunning then runGiftLoop() end   -- always on: langsung jalan pas load
-- ===================== /GIFT =====================
local function fmtAge(sec)
    sec = math.floor(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%dj %02dm %02ds", h, m, s)
    elseif m > 0 then return string.format("%dm %02ds", m, s)
    else return string.format("%ds", s) end
end
local serverHistory = savedState.serverHistory or {}
local firstSeen = serverHistory[currentJobId]
if not firstSeen then
    firstSeen = os.time()
    serverHistory[currentJobId] = firstSeen
    savedState.serverHistory = serverHistory
    saveState(savedState)
    print("[ZenxInv] First time liat server "..currentJobId:sub(1,8).." -> recorded "..firstSeen)
else
    print("[ZenxInv] Server ini udah pernah ke-record di "..firstSeen.." ("..(os.time()-firstSeen).." detik lalu)")
end
do
    local now = os.time()
    local cleaned = {}
    for jid, ts in pairs(serverHistory) do
        if now - ts < 86400 then cleaned[jid] = ts end
    end
    serverHistory = cleaned
    savedState.serverHistory = cleaned
    saveState(savedState)
end
local function updateServerAge()
    local age = os.time() - firstSeen
    local dgt = workspace.DistributedGameTime or 0
    local count = 0
    for _ in pairs(serverHistory) do count = count + 1 end
    ageLbl.Text = "Server age: "..fmtAge(age).." (min)"
    rawLbl.Text = string.format("[Tracked %d servers | DGT=%.0f]", count, dgt)
    local color = C.Green
    if age > 3600 then color = C.Red
    elseif age > 1800 then color = C.Gold end
    ageLbl.TextColor3 = color
end
updateServerAge()
task.spawn(function()
    while ageLbl.Parent do
        task.wait(1)
        pcall(updateServerAge)
    end
end)

-- ============================================
-- INVENTORY BUILD
-- ============================================
local function _doBuildInvShow()
    local bp = player:FindFirstChild("Backpack")
    if not bp then invHeaderLbl.Text = "Backpack gak ada" return end
    pcall(buildMaxKGCache)
    local petsList = {}
    local minKG, maxKG, sumKG, kgCount = math.huge, 0, 0, 0
    local favCount = 0 local highAgeCount = 0 local unreadCount = 0
    local catTopCounts = {} local catBotCounts = {}
    for i = 1, #CAT_TOP do catTopCounts[i] = 0 end
    for i = 1, #CAT_BOT do catBotCounts[i] = 0 end
    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            -- v5.21: filter jenis pet (multi) — kalo ada yg dipilih, cuma yg masuk set
            local _ptype = getBaseName(getPetName(item))
            local _match = (countSelected() == 0) or selectedPetTypes[_ptype]
            if _match then
            local kg = getKG(item)
            local age = getEstimatedAge(item)
            local fav = isFavorite(item)
            if kg then
                if kg < minKG then minKG = kg end
                if kg > maxKG then maxKG = kg end
                sumKG = sumKG + kg
                kgCount = kgCount + 1
                local baseKG = getPetBaseKG(item)
                if baseKG then
                    for i, c in ipairs(CAT_TOP) do
                        if baseKG >= c.min and baseKG < c.max then
                            catTopCounts[i] = catTopCounts[i] + 1
                        end
                    end
                    for i, c in ipairs(CAT_BOT) do
                        if baseKG >= c.min and baseKG < c.max then
                            catBotCounts[i] = catBotCounts[i] + 1
                        end
                    end
                end
            else
                unreadCount = unreadCount + 1
                print("[ZenxInv] UNREAD pet: '"..item.Name.."'")
            end
            if fav then favCount = favCount + 1 end
            if age and age >= 100 then highAgeCount = highAgeCount + 1 end
            table.insert(petsList, {kg=kg, age=age, fav=fav, name=item.Name})
            end -- _match
        end
    end
    local _nSel = countSelected()
    local _hdrType = ""
    if _nSel == 1 then
        local nm for k in pairs(selectedPetTypes) do nm = k break end
        _hdrType = " ["..nm.."]"
    elseif _nSel > 1 then
        _hdrType = " ["..tostring(_nSel).." jenis]"
    end
    invHeaderLbl.Text = "Total: "..#petsList.." pet".._hdrType
    invHeaderLbl.TextColor3 = C.Teal
    -- v5.16: render TOP row — count GEDE via RichText (GUI size tetep, font doang)
    for i, lblWidget in ipairs(catTopLabels) do
        local cat = CAT_TOP[i]
        local count = catTopCounts[i]
        if cat.no_text then
            -- Gajah hitam: emoji + COUNT (gajah-tier pets, ganti gajah merah)
            lblWidget.Text = string.format('<font size="16">%s</font> <font size="20"><b>%d</b></font>', cat.name, count)
            lblWidget.TextColor3 = count > 0 and (cat.color or C.White) or C.Gray
        else
            lblWidget.Text = string.format('<font size="11">%s</font>\n<font size="20"><b>%d</b></font>', cat.name, count)
            lblWidget.TextColor3 = count > 0 and cat.color or C.Gray
        end
    end
    -- v5.18: render BOTTOM row — font NORMAL (kecil), gede cuma di TOP
    for i, lblWidget in ipairs(catBotLabels) do
        local cat = CAT_BOT[i]
        local count = catBotCounts[i]
        lblWidget.Text = string.format('<font size="10">%s</font>\n<font size="13"><b>%d</b></font>', cat.name, count)
        lblWidget.TextColor3 = count > 0 and cat.color or C.Gray
    end
    detailTotal.Text = "Total: "..#petsList.." pet ("..kgCount.." dgn KG)"
    detailFav.Text = "Favorite: "..favCount.." pet"
    detailHigh.Text = "Pet age 100+: "..highAgeCount.." pet"
    if kgCount > 0 then
        detailKG.Text = string.format("Current KG: min=%.2f max=%.2f avg=%.2f", minKG, maxKG, sumKG/kgCount)
    else
        detailKG.Text = "Weight: gak ada data"
    end
    if unreadCount > 0 then
        detailUnread.Text = "Unread: "..unreadCount.." pet (cek console)"
        detailUnread.TextColor3 = C.Red
    else
        detailUnread.Text = "Semua pet ke-baca"
        detailUnread.TextColor3 = C.Green
    end
end
local function buildInvShow()
    local ok, err = pcall(_doBuildInvShow)
    if not ok then
        invHeaderLbl.Text = "ERR: "..tostring(err):sub(1,80)
        invHeaderLbl.TextColor3 = C.Red
    end
end
invRefreshBtn.MouseButton1Click:Connect(buildInvShow)

-- v5.20: PET TYPE PICKER MODAL
-- v5.28: master list semua jenis pet (biar picker tampil semua, bukan cuma yg dipunya)
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
local function showPetPicker()
    -- Scan backpack buat count
    local typeCounts = {}
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            if isPet(item) then
                local t = getBaseName(getPetName(item))
                typeCounts[t] = (typeCounts[t] or 0) + 1
            end
        end
    end
    -- v5.28: gabung semua sumber: punya + master list + yg lagi kepilih (count 0 gpp)
    local seen = {}
    local items = {}
    -- 1. yg dipunya (count > 0) duluan
    local owned = {}
    for t, c in pairs(typeCounts) do table.insert(owned, {name=t, count=c}); seen[t]=true end
    table.sort(owned, function(a,b) return a.count > b.count end)
    for _, it in ipairs(owned) do table.insert(items, it) end
    -- 2. yg lagi kepilih tapi count 0 (biar gak ilang dari list = gak ke-unselect)
    for t in pairs(selectedPetTypes) do
        if not seen[t] then table.insert(items, {name=t, count=0}); seen[t]=true end
    end
    -- 3. master list (semua jenis) yg belum kemunculan
    local rest = {}
    for _, t in ipairs(ALL_PET_TYPES) do
        if not seen[t] then table.insert(rest, {name=t, count=0}); seen[t]=true end
    end
    table.sort(rest, function(a,b) return a.name < b.name end)
    for _, it in ipairs(rest) do table.insert(items, it) end

    local backdrop = mk("Frame",{Size=UDim2.new(1,0,1,0), BackgroundColor3=C.Black, BackgroundTransparency=0.5, BorderSizePixel=0, ZIndex=50, Parent=sg})
    local modal = mk("Frame",{Size=UDim2.new(0,300,0,380), Position=UDim2.new(0.5,-150,0.5,-190), BackgroundColor3=C.BG, BorderSizePixel=0, ZIndex=51, Parent=backdrop})
    corner(modal,10) stroke(modal, C.Teal, 2)
    local hdr = lbl(modal, "Pilih Jenis Pet", 13, C.Teal) hdr.Size=UDim2.new(1,-80,0,28) hdr.Position=UDim2.new(0,12,0,8) hdr.ZIndex=52
    local allBtn = btn(modal, "SEMUA", 9, C.TDim, C.Teal) allBtn.Size=UDim2.new(0,52,0,22) allBtn.Position=UDim2.new(1,-84,0,11) allBtn.ZIndex=52 stroke(allBtn,C.Teal,1.1)
    local closeM = btn(modal, "X", 11, C.RDim, C.Red) closeM.Size=UDim2.new(0,24,0,24) closeM.Position=UDim2.new(1,-28,0,10) closeM.ZIndex=52 stroke(closeM,C.Red,1.1)
    local sbox = mk("TextBox",{Size=UDim2.new(1,-24,0,26), Position=UDim2.new(0,12,0,44), BackgroundColor3=C.Card, BorderSizePixel=0, PlaceholderText="cari...", Text="", TextColor3=C.White, PlaceholderColor3=C.Gray, Font=Enum.Font.Gotham, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, ZIndex=52, Parent=modal})
    corner(sbox,5) stroke(sbox,C.Dim,1) mk("UIPadding",{PaddingLeft=UDim.new(0,8), Parent=sbox})
    local listSF = mk("ScrollingFrame",{Size=UDim2.new(1,-24,1,-84), Position=UDim2.new(0,12,0,78), BackgroundColor3=C.Panel, BorderSizePixel=0, ScrollBarThickness=4, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=52, Parent=modal})
    corner(listSF,6)
    mk("UIListLayout",{Padding=UDim.new(0,3), Parent=listSF})
    mk("UIPadding",{PaddingTop=UDim.new(0,4), PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), Parent=listSF})

    local function applyAndRefresh()
        local arr = {}
        for k in pairs(selectedPetTypes) do table.insert(arr, k) end
        savedState.selectedPetTypes = arr
        savedState.selectedPetType = nil  -- buang key lama
        saveState(savedState)
        updatePetPickBtn()
        buildInvShow()
    end
    local rerender
    local function toggle(name)
        if selectedPetTypes[name] then selectedPetTypes[name] = nil
        else selectedPetTypes[name] = true end
        applyAndRefresh()
        rerender(sbox.Text)  -- update checkmark live
    end
    rerender = function(q)
        for _, c in ipairs(listSF:GetChildren()) do
            if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then c:Destroy() end
        end
        local ql = (q or ""):lower()
        for _, e in ipairs(items) do
            if ql == "" or e.name:lower():find(ql, 1, true) then
                local on = selectedPetTypes[e.name] == true
                local r = btn(listSF, "", 11, on and C.TDim or C.Card) r.Size=UDim2.new(1,-8,0,30) r.ZIndex=53
                if on then stroke(r, C.Teal, 1.2) end
                local ck = lbl(r, on and "[x]" or "[  ]", 11, on and C.Teal or C.Gray) ck.Size=UDim2.new(0,28,1,0) ck.Position=UDim2.new(0,6,0,0) ck.ZIndex=54
                local nm = lbl(r, e.name, 11, on and C.Gold or C.White) nm.Size=UDim2.new(1,-86,1,0) nm.Position=UDim2.new(0,36,0,0) nm.ZIndex=54 nm.TextTruncate=Enum.TextTruncate.AtEnd
                local cl = lbl(r, e.count.."x", 11, C.Teal, Enum.TextXAlignment.Right) cl.Size=UDim2.new(0,46,1,0) cl.Position=UDim2.new(1,-54,0,0) cl.ZIndex=54
                r.MouseButton1Click:Connect(function() toggle(e.name) end)
            end
        end
    end
    sbox:GetPropertyChangedSignal("Text"):Connect(function() rerender(sbox.Text) end)
    allBtn.MouseButton1Click:Connect(function()
        selectedPetTypes = {}  -- clear semua = tampil semua jenis
        applyAndRefresh()
        rerender(sbox.Text)
    end)
    closeM.MouseButton1Click:Connect(function() backdrop:Destroy() end)
    rerender("")
end
petPickBtn.MouseButton1Click:Connect(showPetPicker)

task.spawn(function() task.wait(0.5) buildInvShow() end)
task.spawn(function()
    while true do
        task.wait(5)
        pcall(buildInvShow)
    end
end)

-- ============================================
-- REJOIN
-- ============================================
local isAR = false
local arTask = nil
-- v5.33: log buffer + auto-copy ke clipboard (biar bisa di-paste sebelum keburu teleport)
local _bLog = {}
local function _clip(s)
    local fns = {setclipboard, toclipboard, (Clipboard and Clipboard.set), setrbxclipboard, (syn and syn.write_clipboard)}
    for _, f in ipairs(fns) do
        if type(f) == "function" then
            local ok = pcall(f, s)
            if ok then return true end
        end
    end
    return false
end
local function blog(msg)
    table.insert(_bLog, msg)
    print("[ZenxInv] "..msg)
    -- auto-copy tiap append biar selalu kebawa walau keburu TP
    pcall(function() _clip("=== ZenxInv Bounce Log ===\n"..table.concat(_bLog, "\n")) end)
end
local function teleportToDifferentServer()
    _bLog = {}  -- reset tiap attempt
    blog("placeId="..tostring(game.PlaceId).." curJob="..tostring(game.JobId):sub(1,12))
    local req = (syn and syn.request) or http_request or request or (http and http.request) or (fluxus and fluxus.request)
    blog("req fn = "..(req and "ADA" or "TIDAK ADA"))
    if not req then
        cdLbl.Text = "✗ Executor gak ada fungsi HTTP request (log di-copy)"
        cdLbl.TextColor3 = C.Red
        blog("✗ NO http request function — gak bisa fetch server publik")
        return
    end
    local data = nil
    for attempt = 1, 3 do
        cdLbl.Text = "Fetch server list (try "..attempt.."/3)..."
        local url = "https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?limit=100"
        local ok, resp = pcall(function() return req({Url=url, Method="GET"}) end)
        if ok and resp then
            local body = resp.Body or resp.body or ""
            local status = resp.StatusCode or resp.status_code or 0
            blog("try"..attempt..": status="..tostring(status).." body_len="..#body)
            if #body > 0 then
                local okd, parsed = pcall(function() return HttpService:JSONDecode(body) end)
                if okd and parsed and parsed.data then data = parsed break
                else blog("try"..attempt..": JSON decode fail / no .data") end
            end
        else
            blog("try"..attempt..": REQUEST FAIL: "..tostring(resp):sub(1,80))
        end
        task.wait(1)
    end
    if not data then
        cdLbl.Text = "✗ Fetch GAGAL — log udah di-COPY, paste ke chat"
        cdLbl.TextColor3 = C.Red
        blog("✗ Fetch GAGAL 3x — bounce gak bisa keluar PS")
        rnBtn.Text = "Rejoin Now"
        return
    end
    blog("Fetched "..#data.data.." servers")
    local triedSet = {}
    for _, j in ipairs(savedState.triedJobIds or {}) do triedSet[j] = true end
    local candidates = {}
    for _, s in ipairs(data.data) do
        if s.id ~= currentJobId and not triedSet[s.id] and (s.playing or 0) < (s.maxPlayers or 30) then
            table.insert(candidates, s)
        end
    end
    print("[ZenxInv] Candidates: "..#candidates)
    if #candidates == 0 then
        savedState.triedJobIds = {currentJobId}
        saveState(savedState)
        for _, s in ipairs(data.data) do
            if s.id ~= currentJobId and (s.playing or 0) < (s.maxPlayers or 30) then
                table.insert(candidates, s)
            end
        end
    end
    if #candidates == 0 then
        cdLbl.Text = "Gak ada server lain available"
        cdLbl.TextColor3 = C.Red
        task.wait(2)
        TS:Teleport(game.PlaceId, player)
        return
    end
    local target = candidates[1]
    cdLbl.Text = string.format("Hop %d/%d players (JobId %s)",
        target.playing or 0, target.maxPlayers or 30, target.id:sub(1, 8))
    cdLbl.TextColor3 = C.Teal
    task.wait(0.5)
    TS:TeleportToPlaceInstance(game.PlaceId, target.id, player)
end
local function tryQueueOnTeleport()
    -- v5.31: AUTOEXEC = cara terbaik (gak perlu URL). Script jalan otomatis tiap join.
    -- queueonteleport cuma fallback kalo gak pake autoexec + ada Script URL.
    local url = savedState.scriptUrl or ""
    if url == "" then
        -- Gak ada URL — andelin autoexec. bouncePending udah di file, jadi
        -- begitu script ke-run lagi (via autoexec) di server baru, dia auto lanjut.
        print("[ZenxInv] (no URL) — pastiin script di FOLDER AUTOEXEC biar auto-jalan abis teleport")
        return false
    end
    local qot = queueonteleport or queue_on_teleport or (syn and syn.queue_on_teleport)
    if not qot then
        print("[ZenxInv] queueonteleport gak ada — taruh script di autoexec aja")
        return false
    end
    local reloadSrc = 'task.wait(3)\nloadstring(game:HttpGet("'..url..'"))()'
    local ok, err = pcall(function() qot(reloadSrc) end)
    if ok then print("[ZenxInv] queueonteleport set (auto-reload via URL)") return true
    else print("[ZenxInv] queueonteleport gagal: "..tostring(err)) return false end
end
local rejoinCancelled = false
local function markRejoinAndTeleport(useDifferent, isRetry)
    savedState.lastJobId = currentJobId
    savedState.rejoinTime = os.time()
    if isRetry then
        savedState.retryCount = (savedState.retryCount or 0) + 1
    else
        savedState.retryCount = 0
        savedState.triedJobIds = {currentJobId}
    end
    saveState(savedState)
    local verify = loadState()
    if verify and verify.lastJobId == currentJobId then
        print("[ZenxInv] State saved: lastJobId="..currentJobId:sub(1,12).."... retry="..tostring(savedState.retryCount))
    else
        print("[ZenxInv] State save FAIL!")
    end
    tryQueueOnTeleport()
    local delaySec = tonumber(savedState.rejoinDelay) or 5
    rejoinCancelled = false
    for i = delaySec, 1, -1 do
        if rejoinCancelled then
            cdLbl.Text = "Rejoin cancelled"
            cdLbl.TextColor3 = C.Gold
            rnBtn.Text = "Rejoin Now"
            return
        end
        cdLbl.Text = "Rejoin dalam "..i.." detik (klik lagi buat cancel)"
        cdLbl.TextColor3 = C.Teal
        rnBtn.Text = "Cancel ("..i..")"
        task.wait(1)
    end
    cdLbl.Text = "Teleporting..."
    -- v5.27: diagnostic biar keliatan kenapa bounce jalan/enggak
    print("[ZenxInv] [Rejoin] bounceMode="..tostring(bounceMode).." psLinkCode="..(psLinkCode ~= "" and (psLinkCode:sub(1,10).."...") or "KOSONG"))
    if bounceMode and psLinkCode == "" then
        -- bounce ON tapi link gak ke-parse — kasih tau, jangan diem-diem hop biasa
        cdLbl.Text = "Bounce ON tapi PS Link kosong/salah!"
        cdLbl.TextColor3 = C.Red
        print("[ZenxInv] ⚠ Bounce ON tapi psLinkCode KOSONG — paste link PS yg bener (privateServerLinkCode= / share?code=)")
        rnBtn.Text = "Rejoin Now"
        return
    end
    if bounceMode and psLinkCode ~= "" then
        savedState.bouncePending = true
        savedState.bouncePsCode = psLinkCode
        savedState.bounceTime = os.time()  -- v5.34: timestamp biar gak nyangkut
        saveState(savedState)
        print("[ZenxInv] [Bounce] keluar ke server PUBLIK dulu (TeleportToPlaceInstance), bouncePending=true")
        -- v5.29: JANGAN TS:Teleport(placeId) — dari dalem PS itu balik ke PS yg sama.
        -- Pake teleportToDifferentServer (fetch server publik + TeleportToPlaceInstance) biar bener2 keluar PS.
        teleportToDifferentServer()
    elseif useDifferent then
        teleportToDifferentServer()
    else
        TS:Teleport(game.PlaceId, player)
    end
end
local rejoinInProgress = false
rnBtn.MouseButton1Click:Connect(function()
    if rejoinInProgress then
        rejoinCancelled = true
        rejoinInProgress = false
        return
    end
    rejoinInProgress = true
    rnBtn.Text = "Rejoining..."
    task.spawn(function()
        markRejoinAndTeleport(true, false)
        rejoinInProgress = false
    end)
end)
local function setArTog(val)
    arTog.Text = val and "ON" or "OFF"
    arTog.BackgroundColor3 = val and C.TDim or C.Panel
    arTog.TextColor3 = val and C.Teal or C.Gray
    arTogStroke.Color = val and C.Teal or C.Dim
    arStroke.Color = val and C.Teal or C.Dim
end
setArTog(false)
local function stopAR()
    isAR = false
    if arTask then task.cancel(arTask) arTask = nil end
    setArTog(false)
    cdLbl.Text = "Auto Rejoin: OFF"
    cdLbl.TextColor3 = C.Gray
    saveState({autoRejoin=false, rejoinMinutes=rejoinMinutes})
end
local function startAR()
    isAR = true
    setArTog(true)
    saveState({autoRejoin=true, rejoinMinutes=rejoinMinutes,
               lastJobId=savedState.lastJobId, rejoinTime=savedState.rejoinTime})
    arTask = task.spawn(function()
        while isAR do
            local mins = rejoinMinutes
            if mins < 1 then mins = 30 end  -- v5.35: jaga2 jangan sampe 0 (loop instan)
            for i = mins*60, 1, -1 do
                if not isAR then return end
                cdLbl.Text = string.format("Rejoin dalam: %02d:%02d", math.floor(i/60), i%60)
                cdLbl.TextColor3 = C.Teal
                task.wait(1)
            end
            if isAR then
                -- v5.38: interval juga lewat markRejoinAndTeleport (biar ikut bounce/hop publik,
                -- bukan TS:Teleport biasa yg dari PS balik ke PS lagi)
                cdLbl.Text = "Auto-rejoin (interval)..."
                markRejoinAndTeleport(true, false)
                return
            end
        end
    end)
end
arTog.MouseButton1Click:Connect(function()
    if isAR then stopAR() else startAR() end
end)

local expanded = false
local function setExpanded(state)
    expanded = state
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
            local lo = child.LayoutOrder
            if lo and lo >= 5 then child.Visible = state end
        end
    end
    main.Size = UDim2.new(0, GUI_W, 0, state and GUI_H_FULL or GUI_H_COMPACT)
    expBtn.Text = state and "-" or "+"
    expBtn.BackgroundColor3 = state and C.Panel or C.TDim
    expBtn.TextColor3 = state and C.Gray or C.Teal
    local s = expBtn:FindFirstChildOfClass("UIStroke")
    if s then s.Color = state and C.Dim or C.Teal end
end
setExpanded(false)
expBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

-- v5.37: resume Auto Rejoin KALO user emang nyalain (interval countdown dulu, gak instan).
-- v6.0: REJOIN DIMATIIN TOTAL — paksa semua flag teleport OFF biar ga pernah auto-rejoin/bounce
savedState.autoRejoin = false
savedState.bouncePending = false
savedState.bounceTime = nil
pcall(function() saveState(savedState) end)

-- Loop instan dulu dari path bounce/same-server (udah difix v5.34-36), BUKAN dari sini.
-- startAR count down mins*60 detik dulu sebelum teleport, jadi aman gak langsung rejoin.
if savedState.autoRejoin == true then
    local mins = tonumber(savedState.rejoinMinutes) or 30
    if mins < 1 then mins = 30 end
    print("[ZenxInv] resume Auto Rejoin ON (interval "..mins.." menit — countdown dulu, gak instan)")
    task.spawn(function() task.wait(2) startAR() end)
end

dbgLbl.Text = buildDbgText()
if rejoinStatus == "fresh" then dbgLbl.TextColor3 = C.Gray
elseif rejoinStatus == "new" then dbgLbl.TextColor3 = C.Green
elseif rejoinStatus == "same" then dbgLbl.TextColor3 = C.Red end

if rejoinStatus == "new" then
    cdLbl.Text = "Server BARU (rejoin OK)"
    cdLbl.TextColor3 = C.Green
    task.spawn(function()
        task.wait(8)
        if not isAR then cdLbl.Text = "Auto Rejoin: OFF" cdLbl.TextColor3 = C.Gray end
    end)
elseif rejoinStatus == "same" then
    -- v5.35: JANGAN auto-teleport (itu bikin loop rejoin pas baru nyala).
    -- Cuma kasih info — user pencet Rejoin manual kalo emang mau hop.
    local nextRetry = (retryCount or 0) + 1
    cdLbl.Text = "Server sama kayak sebelumnya (pencet Rejoin manual)"
    cdLbl.TextColor3 = C.Gold
    print("[ZenxInv] rejoinStatus=same — auto-retry DIMATIIN (anti loop). Pencet Rejoin manual.")
    task.spawn(function()
        task.wait(8)
        if not isAR then cdLbl.Text = "Auto Rejoin: OFF" cdLbl.TextColor3 = C.Gray end
    end)
end

-- v5.34: bounce cuma diproses kalo MASIH BARU (< 120s). Kalo basi -> clear (anti nyangkut)
if savedState.bouncePending then
    local btime = tonumber(savedState.bounceTime) or 0
    if (os.time() - btime) > 120 or not savedState.bouncePsCode or savedState.bouncePsCode == "" then
        print("[ZenxInv] bouncePending BASI/invalid -> di-clear (gak auto-TP)")
        savedState.bouncePending = false
        savedState.bounceTime = nil
        saveState(savedState)
    end
end
if savedState.bouncePending and savedState.bouncePsCode and savedState.bouncePsCode ~= "" then
    local psCode = savedState.bouncePsCode
    savedState.bouncePending = false
    savedState.bounceTime = nil
    saveState(savedState)
    cdLbl.Text = "Bouncing back to PS..."
    cdLbl.TextColor3 = C.Gold
    task.spawn(function()
        -- v5.26: tunggu di publik (bounceWaitSec) biar PS lama mati -> dapet fresh
        local waitSec = tonumber(savedState.bounceWaitSec) or 20
        for i = waitSec, 1, -1 do
            cdLbl.Text = "Tunggu PS lama mati... balik PS dalam "..i.."s"
            cdLbl.TextColor3 = C.Gold
            task.wait(1)
        end
        cdLbl.Text = "Teleporting ke PS (fresh)..."
        tryQueueOnTeleport()
        local ok, err = pcall(function()
            TS:TeleportToPrivateServer(game.PlaceId, psCode, {player})
        end)
        if not ok then
            cdLbl.Text = "PS TP fail — code salah?"
            cdLbl.TextColor3 = C.Red
        end
    end)
end

print("==== ZenxInv "..SCRIPT_VERSION.." READY ====")
