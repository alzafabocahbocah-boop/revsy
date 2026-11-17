-- ============================================================
-- DEBUG EYEBALL ANIMATION v1.0
-- Scan semua animasi/skill/string yang muncul dari pet Eyeball
-- Dump: PetsPhysical, ReplicatedStorage, PlayerScripts, workspace
-- ============================================================
local plr = game.Players.LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local CS  = game:GetService("CollectionService")
local WS  = workspace

local _lines = {}
local function log(s) table.insert(_lines, s) print("[EYE] "..s) end

-- keyword yang dicari
local KEYWORDS = {"eyeball","eye_ball","frill","fan","skill","ability","anim","passive","effect","vfx","visual"}
local function isInteresting(s)
    s = tostring(s):lower()
    for _, k in ipairs(KEYWORDS) do
        if s:find(k, 1, true) then return true end
    end
    return false
end

-- ── dump semua StringValue/atribut dari object ──────────────
local function dumpStrings(obj, path, depth)
    if depth <= 0 or not obj then return end
    local ok, children = pcall(function() return obj:GetChildren() end)
    if not ok then return end
    for _, c in ipairs(children) do
        local nm = tostring(c.Name)
        local cn = tostring(c.ClassName)
        local valStr = ""
        local interesting = isInteresting(nm)
        pcall(function()
            if c:IsA("StringValue") or c:IsA("BoolValue") or c:IsA("NumberValue") or c:IsA("IntValue") then
                valStr = " = "..tostring(c.Value)
                if isInteresting(tostring(c.Value)) then interesting = true end
            end
        end)
        if interesting then
            log(path.."/"..nm.." ["..cn.."]"..valStr)
        end
        -- dump atribut
        pcall(function()
            local attrs = c:GetAttributes()
            for k, v in pairs(attrs) do
                if isInteresting(k) or isInteresting(tostring(v)) then
                    log(path.."/"..nm.." attr: "..k.." = "..tostring(v))
                end
            end
        end)
        dumpStrings(c, path.."/"..nm, depth - 1)
    end
end

local function doScan()
    log("=== EYEBALL ANIMATION DEBUG START ===")

    -- 1. Cari pet Eyeball di PetsPhysical
    log("--- PetsPhysical scan ---")
    local pp = WS:FindFirstChild("PetsPhysical")
    if pp then
        for _, pet in ipairs(pp:GetChildren()) do
            local nm = tostring(pet.Name):lower()
            if nm:find("eyeball",1,true) or nm:find("eye",1,true) then
                log("PET: "..pet.Name.." ["..pet.ClassName.."]")
                -- dump semua atribut
                pcall(function()
                    local attrs = pet:GetAttributes()
                    for k, v in pairs(attrs) do
                        log("  attr: "..k.." = "..tostring(v))
                    end
                end)
                -- dump semua children depth 3
                dumpStrings(pet, "PetsPhysical/"..pet.Name, 3)
                -- dump semua children nama saja
                log("  children:")
                pcall(function()
                    for _, c in ipairs(pet:GetChildren()) do
                        log("    ["..c.ClassName.."] "..c.Name)
                        for _, cc in ipairs(c:GetChildren()) do
                            log("      ["..cc.ClassName.."] "..cc.Name)
                        end
                    end
                end)
            end
        end
    else
        log("PetsPhysical tidak ada di workspace")
    end

    -- 2. Cari di RS — PetRegistry / Data
    log("--- RS PetRegistry scan ---")
    pcall(function()
        local data = RS:FindFirstChild("Data")
        if data then
            local petReg = data:FindFirstChild("PetRegistry")
            if petReg then
                local ok, reg = pcall(function() return require(petReg) end)
                if ok and reg then
                    -- cari entry eyeball
                    local petList = reg.PetList or reg
                    for name, data2 in pairs(petList) do
                        if tostring(name):lower():find("eyeball",1,true) or tostring(name):lower():find("eye",1,true) then
                            log("PetList entry: "..tostring(name))
                            if type(data2) == "table" then
                                for k, v in pairs(data2) do
                                    log("  "..tostring(k).." = "..tostring(v))
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 3. Scan RS children langsung cari "eyeball"/"frill"/"fan"/"skill"
    log("--- RS keyword scan ---")
    local function scanRS(obj, path, depth)
        if depth <= 0 or not obj then return end
        local ok, children = pcall(function() return obj:GetChildren() end)
        if not ok then return end
        for _, c in ipairs(children) do
            local nm = tostring(c.Name)
            if isInteresting(nm) then
                log(path.."/"..nm.." ["..c.ClassName.."]")
                -- dump value kalau ada
                pcall(function()
                    if c:IsA("StringValue") or c:IsA("BoolValue") or c:IsA("NumberValue") then
                        log("  value = "..tostring(c.Value))
                    end
                end)
            end
            scanRS(c, path.."/"..nm, depth - 1)
        end
    end
    scanRS(RS, "RS", 4)

    -- 4. Scan PlayerScripts cari animation/skill eyeball
    log("--- PlayerScripts scan ---")
    local ps = plr:FindFirstChild("PlayerScripts")
    if ps then scanRS(ps, "PlayerScripts", 3) end

    -- 5. Cari di workspace langsung
    log("--- workspace keyword scan ---")
    for _, c in ipairs(WS:GetChildren()) do
        if isInteresting(c.Name) then
            log("WS/"..c.Name.." ["..c.ClassName.."]")
            dumpStrings(c, "WS/"..c.Name, 2)
        end
    end

    -- 6. CS tagged "Eyeball" / "Skill" / "Ability"
    log("--- CS tag brute force ---")
    for _, tag in ipairs({"Eyeball","EyeBall","Skill","Ability","Frill","Fan","PetSkill","PassiveSkill"}) do
        local ok2, list = pcall(function() return CS:GetTagged(tag) end)
        if ok2 and list and #list > 0 then
            log("CS:GetTagged('"..tag.."') -> "..#list.." objects")
            for i, obj in ipairs(list) do
                if i <= 5 then log("  ["..i.."] "..obj.Name.." @ "..obj:GetFullName()) end
            end
        end
    end

    log("=== SELESAI — "..(#_lines).." baris ===")
end

-- GUI
local sg = Instance.new("ScreenGui")
sg.Name = "EyeDbg"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,280,0,70); frame.Position = UDim2.new(0,10,0,100)
frame.BackgroundColor3 = Color3.fromRGB(10,5,20); frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true; frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(180,100,255)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1,0,0,22); ttl.BackgroundColor3 = Color3.fromRGB(15,8,30)
ttl.BorderSizePixel = 0; ttl.Text = "👁 DEBUG EYEBALL ANIMATION"
ttl.TextColor3 = Color3.fromRGB(180,120,255); ttl.TextSize = 10
ttl.Font = Enum.Font.GothamBold; ttl.Parent = frame
Instance.new("UICorner", ttl).CornerRadius = UDim.new(0,8)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0,120,0,26); scanBtn.Position = UDim2.new(0,4,0,26)
scanBtn.BackgroundColor3 = Color3.fromRGB(20,10,40); scanBtn.BorderSizePixel = 0
scanBtn.Text = "▶ SCAN"; scanBtn.TextColor3 = Color3.fromRGB(180,120,255)
scanBtn.TextSize = 11; scanBtn.Font = Enum.Font.GothamBold; scanBtn.Parent = frame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0,4)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0,120,0,26); copyBtn.Position = UDim2.new(0,138,0,26)
copyBtn.BackgroundColor3 = Color3.fromRGB(15,10,30); copyBtn.BorderSizePixel = 0
copyBtn.Text = "📋 Copy Log"; copyBtn.TextColor3 = Color3.fromRGB(160,140,255)
copyBtn.TextSize = 11; copyBtn.Font = Enum.Font.GothamBold; copyBtn.Parent = frame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,4)

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(1,-8,0,16); statLbl.Position = UDim2.new(0,4,0,52)
statLbl.BackgroundTransparency = 1; statLbl.Text = "belum scan"
statLbl.TextColor3 = Color3.fromRGB(120,100,150); statLbl.TextSize = 9
statLbl.Font = Enum.Font.Code; statLbl.Parent = frame

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "scanning..."; _lines = {}
    task.spawn(function()
        pcall(doScan)
        scanBtn.Text = "▶ SCAN"
        statLbl.Text = "✅ done — "..(#_lines).." baris"
        statLbl.TextColor3 = Color3.fromRGB(150,255,150)
    end)
end)

copyBtn.MouseButton1Click:Connect(function()
    if #_lines == 0 then
        copyBtn.Text = "⚠ scan dulu!"; task.delay(2, function() copyBtn.Text = "📋 Copy Log" end); return
    end
    local txt = table.concat(_lines, "\n")
    local ok = pcall(function() setclipboard(txt) end)
    if ok then copyBtn.Text = "✅ Copied! ("..(#_lines)..")"
    else
        print("[EYE LOG]===START===")
        for _, l in ipairs(_lines) do print(l) end
        print("[EYE LOG]===END===")
        copyBtn.Text = "⚠ cek console"
    end
    task.delay(3, function() copyBtn.Text = "📋 Copy Log" end)
end)

print("[EYE DEBUG] loaded — equip/spawn Eyeball dulu, lalu klik SCAN")
