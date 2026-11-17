-- ============================================================
-- DEBUG EYEBALL ANIMATION v2.0
-- Dump isi RS/Assets/Animations/PetAnimations/EyeballMonster
-- + Actions / Animations / States / Passives dari PetRegistry
-- ============================================================
local plr = game.Players.LocalPlayer
local RS  = game:GetService("ReplicatedStorage")

local _lines = {}
local function log(s) table.insert(_lines, s) print("[EYE2] "..s) end

local function dumpTable(t, prefix, depth)
    if depth <= 0 or type(t) ~= "table" then return end
    for k, v in pairs(t) do
        if type(v) == "table" then
            log(prefix..tostring(k).." = {")
            dumpTable(v, prefix.."  ", depth - 1)
            log(prefix.."}")
        else
            log(prefix..tostring(k).." = "..tostring(v))
        end
    end
end

local function dumpObj(obj, path, depth)
    if depth <= 0 or not obj then return end
    local ok, children = pcall(function() return obj:GetChildren() end)
    if not ok then return end
    for _, c in ipairs(children) do
        local nm = c.Name; local cn = c.ClassName
        local extra = ""
        pcall(function()
            if c:IsA("Animation") then extra = " (AnimId="..tostring(c.AnimationId)..")" end
            if c:IsA("StringValue") or c:IsA("NumberValue") or c:IsA("BoolValue") then extra = " = "..tostring(c.Value) end
        end)
        log(path.."/"..nm.." ["..cn.."]"..extra)
        -- dump atribut
        pcall(function()
            local attrs = c:GetAttributes()
            for ak, av in pairs(attrs) do
                log(path.."/"..nm.." attr:"..ak.."="..tostring(av))
            end
        end)
        dumpObj(c, path.."/"..nm, depth - 1)
    end
end

local function doScan()
    log("=== EYEBALL ANIM DEBUG v2 START ===")

    -- 1. Dump RS/Assets/Animations/PetAnimations/EyeballMonster
    log("--- RS/Assets/Animations/PetAnimations/EyeballMonster ---")
    pcall(function()
        local folder = RS:FindFirstChild("Assets")
            and RS.Assets:FindFirstChild("Animations")
            and RS.Assets.Animations:FindFirstChild("PetAnimations")
            and RS.Assets.Animations.PetAnimations:FindFirstChild("EyeballMonster")
        if folder then
            log("Ketemu! children:")
            dumpObj(folder, "EyeballMonster", 4)
        else
            log("TIDAK KETEMU folder EyeballMonster")
        end
    end)

    -- 2. Dump Actions, Animations, States, Passives dari PetRegistry
    log("--- PetRegistry Eyeball Monster tables ---")
    pcall(function()
        local reg = require(RS:FindFirstChild("Data"):FindFirstChild("PetRegistry"))
        local petList = reg.PetList or reg
        for name, data in pairs(petList) do
            if tostring(name):lower():find("eyeball",1,true) then
                log("=== "..tostring(name).." ===")
                if type(data) == "table" then
                    for k, v in pairs(data) do
                        if type(v) == "table" then
                            log("["..k.."]:")
                            dumpTable(v, "  ", 4)
                        else
                            log(k.." = "..tostring(v))
                        end
                    end
                end
            end
        end
    end)

    -- 3. Dump PassiveRegistry — cari eyeball/gaze
    log("--- PassiveRegistry (Gaze/Eyeball) ---")
    pcall(function()
        local passReg = require(RS.Data:FindFirstChild("PetRegistry"):FindFirstChild("PassiveRegistry"))
        if type(passReg) == "table" then
            for k, v in pairs(passReg) do
                local ks = tostring(k):lower()
                if ks:find("gaze",1,true) or ks:find("eye",1,true) or ks:find("spooky",1,true) or ks:find("stare",1,true) then
                    log("key: "..tostring(k))
                    if type(v) == "table" then dumpTable(v, "  ", 3) end
                end
            end
        end
    end)

    -- 4. Dump RS/Modules/PetServices/AnimationEvents
    log("--- RS/Modules/PetServices/AnimationEvents ---")
    pcall(function()
        local ae = RS:FindFirstChild("Modules")
            and RS.Modules:FindFirstChild("PetServices")
            and RS.Modules.PetServices:FindFirstChild("AnimationEvents")
        if ae then dumpObj(ae, "AnimationEvents", 3)
        else log("tidak ketemu") end
    end)

    -- 5. Dump RS/Modules/PetServices/PetVFXHandler — lihat isinya
    log("--- RS/Modules/PetServices/PetVFXHandler ---")
    pcall(function()
        local vfx = RS.Modules.PetServices:FindFirstChild("PetVFXHandler")
        if vfx then
            local ok, mod = pcall(require, vfx)
            if ok and type(mod) == "table" then
                log("keys: ")
                for k in pairs(mod) do log("  "..tostring(k)) end
            end
            dumpObj(vfx, "PetVFXHandler", 2)
        end
    end)

    -- 6. Dump PetZoneAbilityVFX di workspace
    log("--- workspace/PetZoneAbilityVFX ---")
    pcall(function()
        local vfxF = workspace:FindFirstChild("PetZoneAbilityVFX")
        if vfxF then dumpObj(vfxF, "PetZoneAbilityVFX", 3)
        else log("kosong") end
    end)

    log("=== SELESAI — "..(#_lines).." baris ===")
end

-- GUI
local sg = Instance.new("ScreenGui")
sg.Name = "EyeDbg2"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,280,0,70); frame.Position = UDim2.new(0,10,0,180)
frame.BackgroundColor3 = Color3.fromRGB(10,5,20); frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true; frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(255,120,180)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1,0,0,22); ttl.BackgroundColor3 = Color3.fromRGB(20,5,30)
ttl.BorderSizePixel = 0; ttl.Text = "👁 EYEBALL ANIM v2 — Actions+Anim"
ttl.TextColor3 = Color3.fromRGB(255,120,200); ttl.TextSize = 10
ttl.Font = Enum.Font.GothamBold; ttl.Parent = frame
Instance.new("UICorner", ttl).CornerRadius = UDim.new(0,8)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0,120,0,26); scanBtn.Position = UDim2.new(0,4,0,26)
scanBtn.BackgroundColor3 = Color3.fromRGB(25,8,40); scanBtn.BorderSizePixel = 0
scanBtn.Text = "▶ SCAN"; scanBtn.TextColor3 = Color3.fromRGB(255,120,200)
scanBtn.TextSize = 11; scanBtn.Font = Enum.Font.GothamBold; scanBtn.Parent = frame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0,4)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0,120,0,26); copyBtn.Position = UDim2.new(0,138,0,26)
copyBtn.BackgroundColor3 = Color3.fromRGB(18,8,30); copyBtn.BorderSizePixel = 0
copyBtn.Text = "📋 Copy Log"; copyBtn.TextColor3 = Color3.fromRGB(200,150,255)
copyBtn.TextSize = 11; copyBtn.Font = Enum.Font.GothamBold; copyBtn.Parent = frame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,4)

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(1,-8,0,16); statLbl.Position = UDim2.new(0,4,0,52)
statLbl.BackgroundTransparency = 1; statLbl.Text = "belum scan"
statLbl.TextColor3 = Color3.fromRGB(150,100,180); statLbl.TextSize = 9
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
        print("[EYE2 LOG]===START===")
        for _, l in ipairs(_lines) do print(l) end
        print("[EYE2 LOG]===END===")
        copyBtn.Text = "⚠ cek console"
    end
    task.delay(3, function() copyBtn.Text = "📋 Copy Log" end)
end)

print("[EYE2 DEBUG] loaded — klik SCAN")
