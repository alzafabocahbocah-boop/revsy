-- DBG PARTIKEL — scan + destroy WS FX + kill weather scripts

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

-- ======== GUI ========
local sg = Instance.new("ScreenGui"); sg.Name="DbgPartikelGui"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=gui
-- tinggi frame +34 buat row button ke-2
local frame = Instance.new("Frame"); frame.Size=UDim2.new(0,220,0,374); frame.Position=UDim2.new(0,10,0,60); frame.BackgroundColor3=Color3.fromRGB(18,18,24); frame.BorderSizePixel=0; frame.Active=false; frame.Draggable=false; frame.Parent=sg
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)

-- drag via title bar
local UIS = game:GetService("UserInputService")
local dragging, dragStart, startPos
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-28,0,28); title.BackgroundColor3=Color3.fromRGB(30,180,120); title.Text="🔍 SCAN PARTIKEL"; title.TextColor3=Color3.new(1,1,1); title.Font=Enum.Font.GothamBold; title.TextSize=12; title.Parent=frame
Instance.new("UICorner",title).CornerRadius=UDim.new(0,8)
title.Active=true
title.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging=true; dragStart=inp.Position
        startPos=frame.Position
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
title.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,26,0,26); closeBtn.Position=UDim2.new(1,-27,0,1); closeBtn.BackgroundColor3=Color3.fromRGB(180,40,40); closeBtn.Text="✕"; closeBtn.TextColor3=Color3.new(1,1,1); closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=12; closeBtn.Parent=frame
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- scroll area — sisakan 68px buat 2 row button
local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,1,-106); scroll.Position=UDim2.new(0,4,0,32); scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=4; scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=frame
Instance.new("UIListLayout",scroll).Padding=UDim.new(0,2)

local logL=Instance.new("TextLabel"); logL.Size=UDim2.new(1,-4,0,16); logL.BackgroundTransparency=1; logL.TextColor3=Color3.fromRGB(180,180,180); logL.Font=Enum.Font.Code; logL.TextSize=10; logL.TextXAlignment=Enum.TextXAlignment.Left; logL.TextWrapped=true; logL.AutomaticSize=Enum.AutomaticSize.Y

local allLines = {}
local function addLog(s, col)
    table.insert(allLines, s)
    local l=logL:Clone(); l.Text=s; l.TextColor3=col or Color3.fromRGB(180,220,180); l.Parent=scroll
end

-- ── ROW 1: SCAN+COPY | DEL FX ──
local scanBtn=Instance.new("TextButton"); scanBtn.Size=UDim2.new(0.5,-6,0,28); scanBtn.Position=UDim2.new(0,4,1,-66); scanBtn.BackgroundColor3=Color3.fromRGB(30,120,220); scanBtn.Text="SCAN+COPY"; scanBtn.TextColor3=Color3.new(1,1,1); scanBtn.Font=Enum.Font.GothamBold; scanBtn.TextSize=11; scanBtn.Parent=frame
Instance.new("UICorner",scanBtn).CornerRadius=UDim.new(0,6)

local delBtn=Instance.new("TextButton"); delBtn.Size=UDim2.new(0.5,-6,0,28); delBtn.Position=UDim2.new(0.5,2,1,-66); delBtn.BackgroundColor3=Color3.fromRGB(200,80,30); delBtn.Text="DEL FX"; delBtn.TextColor3=Color3.new(1,1,1); delBtn.Font=Enum.Font.GothamBold; delBtn.TextSize=11; delBtn.Parent=frame
Instance.new("UICorner",delBtn).CornerRadius=UDim.new(0,6)

-- ── ROW 2: KILL WEATHER (full width) ──
local killBtn=Instance.new("TextButton"); killBtn.Size=UDim2.new(1,-8,0,28); killBtn.Position=UDim2.new(0,4,1,-34); killBtn.BackgroundColor3=Color3.fromRGB(160,30,160); killBtn.Text="⚡ KILL WEATHER SCRIPTS"; killBtn.TextColor3=Color3.new(1,1,1); killBtn.Font=Enum.Font.GothamBold; killBtn.TextSize=11; killBtn.Parent=frame
Instance.new("UICorner",killBtn).CornerRadius=UDim.new(0,6)

-- ======== SCAN ========
local PARTICLE_CLASSES = {
    "ParticleEmitter","Trail","Beam","Smoke","Fire","Sparkles",
    "BlurEffect","ColorCorrectionEffect","BloomEffect","SunRaysEffect","DepthOfFieldEffect",
}
local function isParticleClass(obj)
    for _,c in ipairs(PARTICLE_CLASSES) do if obj:IsA(c) then return true end end
    return false
end

local WEATHER_NAMES = {
    "WeatherVisuals","WeatherObjects","WindBlastTemplate",
    "Whale","Clam","Kelp","Water_Effect","SpottedEffect",
    "SpiderWebFX","Rainbows","Dirt_VFX","BirthdayDecor",
    "BeanstalkEvent","AcornChaosLocal","Visuals","FishRainClient",
    "TornadoFX","CycloneFX","MeteorFX","LavaPools",
    "IcicleSpawner","SnowFX","FrostFX","LightningFX",
}

local LIGHTNING_KEYWORDS = {"lightning","thunder","storm","electric","petir","flash","bolt","zap","spark","rain","snow","frost","wind","tornado","cyclone","meteor","lava","fog","cloud","sky","weather","visual","fx","effect","vfx"}

-- objek normal di workspace (bukan cuaca)
local NORMAL_WS = {
    Terrain=true, Camera=true, Baseplate=true, Map=true,
    TradeWorld=true, GardenServer=true, LevelingServer=true,
    Players=true, Workspace=true, ReplicatedStorage=true,
    -- folder game
    ["Arceus X"]=true, Delta=true, Ugc=true,
    -- nama umum
    SoundEffects=true, PetZoneAbilityVFX=true, FlowerRushFX=true,
    HapticEffect=true,
}

local function hasKeyword(name)
    local low = name:lower()
    for _,kw in ipairs(LIGHTNING_KEYWORDS) do
        if low:find(kw,1,true) then return kw end
    end
    return nil
end

local lkw = {"weather","lightning","thunder","storm","electric","petir","bolt","flash","cuaca","kilat"}
local function hasLKW(name)
    local low = name:lower()
    for _,k in ipairs(lkw) do if low:find(k,1,true) then return k end end
    return nil
end

local function scanAll(doCopy)
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    allLines = {}
    local ws = workspace; local found = 0

    addLog("── WS CHILDREN (semua suspect) ──", Color3.fromRGB(100,200,255))
    for _, obj in ipairs(ws:GetChildren()) do
        local isKnown = false
        for _, name in ipairs(WEATHER_NAMES) do
            if obj.Name == name then
                addLog("⚠️ "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,180,60))
                found=found+1; isKnown=true; break
            end
        end
        if not isKnown then
            local kw = hasKeyword(obj.Name)
            if kw then
                addLog("🌩 "..obj.Name.." ["..obj.ClassName.."] (kw:"..kw..")", Color3.fromRGB(255,140,200))
                found=found+1
            elseif isParticleClass(obj) then
                addLog("❓ "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,120,120))
                found=found+1
            end
        end
    end

    addLog("── LIGHTING ──", Color3.fromRGB(100,200,255))
    local Lighting = game:GetService("Lighting")
    for _, obj in ipairs(Lighting:GetChildren()) do
        if isParticleClass(obj) then
            addLog("💡 "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,220,80)); found=found+1
        end
    end
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") or obj:IsA("Sky") then
            addLog("🌤 "..obj.ClassName..": "..obj.Name, Color3.fromRGB(160,220,255))
        end
        if isParticleClass(obj) then
            addLog("💡 "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,200,80)); found=found+1
        end
    end

    addLog("── WS DESCENDANTS ──", Color3.fromRGB(100,200,255))
    local wsP={}
    pcall(function()
        for _, obj in ipairs(ws:GetDescendants()) do
            if isParticleClass(obj) then
                local p = obj.Parent
                local pp = p and p.Parent
                local loc = p and p.Name or "?"
                if pp and pp ~= ws then loc = pp.Name.."/"..loc end
                table.insert(wsP, obj.Name.."["..obj.ClassName.."] @"..loc)
                found=found+1; if #wsP>=200 then break end
            end
        end
    end)
    if #wsP==0 then addLog("  (tidak ada)", Color3.fromRGB(120,120,120))
    else for _,s in ipairs(wsP) do addLog("  "..s, Color3.fromRGB(255,150,100)) end end

    addLog("── WS BOLT/RAY SCAN ──", Color3.fromRGB(100,200,255))
    local boltKW = {"light","bolt","strike","ray","flash","beam","lightning","petir","electric","zap","plasma","arc","spark"}
    local boltFound = {}
    pcall(function()
        for _, obj in ipairs(ws:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                local low = obj.Name:lower()
                for _, kw in ipairs(boltKW) do
                    if low:find(kw,1,true) then
                        local p = obj.Parent
                        table.insert(boltFound, obj.Name.."["..obj.ClassName.."] @"..(p and p.Name or "?"))
                        break
                    end
                end
            end
            if #boltFound >= 50 then break end
        end
    end)
    if #boltFound == 0 then addLog("  (tidak ada)", Color3.fromRGB(120,120,120))
    else for _,s in ipairs(boltFound) do addLog("  ⚡ "..s, Color3.fromRGB(255,255,100)) end end

    addLog("── WS UNKNOWN (objek asing) ──", Color3.fromRGB(100,200,255))
    local unknownCount = 0
    pcall(function()
        for _, obj in ipairs(ws:GetChildren()) do
            if not NORMAL_WS[obj.Name] then
                local kw = hasKeyword(obj.Name)
                if not kw and not isParticleClass(obj) then
                    -- cek anak-anaknya ada partikel/beam gak
                    local hasVfx = false
                    for _, d in ipairs(obj:GetDescendants()) do
                        if isParticleClass(d) then hasVfx = true; break end
                    end
                    local tag = hasVfx and " ⚡VFX" or ""
                    addLog("  🔎 "..obj.Name.." ["..obj.ClassName.."]"..tag, hasVfx and Color3.fromRGB(255,200,60) or Color3.fromRGB(200,200,200))
                    unknownCount = unknownCount + 1
                end
            end
        end
    end)
    if unknownCount == 0 then addLog("  (semua objek dikenal)", Color3.fromRGB(120,120,120)) end

    addLog("── VFX FOLDERS ──", Color3.fromRGB(100,200,255))
    local VFX_FOLDERS = {"PetZoneAbilityVFX","FlowerRushFX","SpottedFX","SoundEffects","WeatherFX","LightningFX","StormFX"}
    pcall(function()
        for _, folderName in ipairs(VFX_FOLDERS) do
            local f = ws:FindFirstChild(folderName, true)
            if f then
                local kids = {}
                for _, d in ipairs(f:GetDescendants()) do
                    if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("BillboardGui") or d:IsA("SpecialMesh") then
                        table.insert(kids, "  "..d.ClassName.."["..d.Name.."] en="..tostring(d.Enabled).." @"..d.Parent.Name)
                        found=found+1
                    end
                end
                if #kids > 0 then
                    addLog("📁 "..folderName.." ("..#kids.." emitter):", Color3.fromRGB(255,220,80))
                    for _,s in ipairs(kids) do addLog(s, Color3.fromRGB(255,180,80)) end
                else
                    addLog("📁 "..folderName.." (kosong/no emitter)", Color3.fromRGB(120,120,120))
                end
            end
        end
    end)

    addLog("── LOCALSCRIPT AKTIF ──", Color3.fromRGB(100,200,255))
    local lsFound = {}
    pcall(function()
        local sources = {
            lp:WaitForChild("PlayerGui",1),
            lp:WaitForChild("PlayerScripts",1),
            workspace,
        }
        for _, src in ipairs(sources) do
            if src then
                for _, obj in ipairs(src:GetDescendants()) do
                    if obj:IsA("LocalScript") or obj:IsA("Script") then
                        local kw = hasLKW(obj.Name)
                        if kw then
                            table.insert(lsFound, obj.Name.." @"..obj.Parent.Name.." [kw:"..kw.."] enabled="..tostring(obj.Enabled))
                        end
                    end
                end
            end
        end
    end)
    if #lsFound == 0 then
        addLog("  (tidak ada LocalScript cuaca)", Color3.fromRGB(120,120,120))
    else
        for _,s in ipairs(lsFound) do
            addLog("  ⚡ "..s, Color3.fromRGB(255,160,60)); found=found+1
        end
    end

    addLog("── LIGHTING PROPS ──", Color3.fromRGB(100,200,255))
    local L = game:GetService("Lighting")
    addLog("  Brightness="..tostring(L.Brightness), Color3.fromRGB(200,200,200))
    addLog("  ClockTime="..tostring(L.ClockTime), Color3.fromRGB(200,200,200))
    addLog("  Ambient="..tostring(L.Ambient), Color3.fromRGB(200,200,200))
    addLog("  OutdoorAmbient="..tostring(L.OutdoorAmbient), Color3.fromRGB(200,200,200))

    addLog("── TOTAL: "..found.." objek ──", Color3.fromRGB(180,255,180))
    -- copy hanya kalau doCopy=true (dari tombol manual)
    if doCopy then
        task.defer(function()
            pcall(function() setclipboard(table.concat(allLines, "\n")) end)
            scanBtn.Text = "✓ COPIED"; task.delay(2, function() scanBtn.Text = "SCAN+COPY" end)
        end)
    end
end

-- ======== DESTROY WS FX ========
local FX_CLASSES = {
    "ColorCorrectionEffect","BlurEffect","SunRaysEffect","BloomEffect",
    "DepthOfFieldEffect",
}
local function isFxClass(obj)
    for _,c in ipairs(FX_CLASSES) do if obj:IsA(c) then return true end end
    return false
end

delBtn.MouseButton1Click:Connect(function()
    local destroyed = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            if isFxClass(obj) then
                table.insert(destroyed, obj.Name.."["..obj.ClassName.."]")
                obj:Destroy()
            end
        end
    end)
    -- juga destroy dari Lighting
    pcall(function()
        for _, obj in ipairs(game:GetService("Lighting"):GetChildren()) do
            if isFxClass(obj) then
                table.insert(destroyed, "L:"..obj.Name.."["..obj.ClassName.."]")
                obj:Destroy()
            end
        end
    end)
    if #destroyed > 0 then
        addLog("🗑 DESTROYED: "..table.concat(destroyed,", "), Color3.fromRGB(255,80,80))
    else
        addLog("✓ tidak ada FX di workspace/lighting", Color3.fromRGB(120,200,120))
    end
    task.wait(0.5)
    scanAll(false)
end)

-- ======== KILL WEATHER SCRIPTS ========
killBtn.MouseButton1Click:Connect(function()
    local killed = {}
    local failed = {}

    pcall(function()
        local sources = {
            lp:WaitForChild("PlayerScripts",1),
            lp:WaitForChild("PlayerGui",1),
            workspace,
        }
        for _, src in ipairs(sources) do
            if src then
                for _, obj in ipairs(src:GetDescendants()) do
                    if (obj:IsA("LocalScript") or obj:IsA("Script")) and hasLKW(obj.Name) then
                        local ok, err = pcall(function()
                            obj.Enabled = false
                        end)
                        if ok then
                            table.insert(killed, obj.Name.."(disabled)")
                        else
                            -- coba destroy kalau gak bisa disable
                            local ok2 = pcall(function() obj:Destroy() end)
                            if ok2 then
                                table.insert(killed, obj.Name.."(destroyed)")
                            else
                                table.insert(failed, obj.Name)
                            end
                        end
                    end
                end
            end
        end
    end)

    -- reset Lighting ke normal setelah kill
    pcall(function()
        local L = game:GetService("Lighting")
        L.Brightness = 2
        L.ClockTime = 14
        L.Ambient = Color3.fromRGB(70,70,70)
        L.OutdoorAmbient = Color3.fromRGB(128,128,128)
    end)

    if #killed > 0 then
        addLog("⚡ KILLED: "..table.concat(killed,", "), Color3.fromRGB(255,80,255))
    else
        addLog("  (tidak ada script cuaca ditemukan)", Color3.fromRGB(120,120,120))
    end
    if #failed > 0 then
        addLog("  ❌ GAGAL: "..table.concat(failed,", "), Color3.fromRGB(255,80,80))
    end
    addLog("  Lighting direset ke normal", Color3.fromRGB(120,220,180))
    task.wait(0.5)
    scanAll(false)
end)

-- tombol SCAN+COPY: scan lalu copy 1x
scanBtn.MouseButton1Click:Connect(function() scanAll(true) end)
-- auto-loop tiap 5 detik: scan aja, gak copy
task.spawn(function()
    while sg and sg.Parent do
        scanAll(false)
        task.wait(5)
    end
end)
