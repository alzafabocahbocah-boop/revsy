-- DBG PARTIKEL — scan semua partikel/weather/FX yang ada di game

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

-- ======== GUI ========
local sg = Instance.new("ScreenGui"); sg.Name="DbgPartikelGui"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=gui
local frame = Instance.new("Frame"); frame.Size=UDim2.new(0,220,0,340); frame.Position=UDim2.new(0,10,0,60); frame.BackgroundColor3=Color3.fromRGB(18,18,24); frame.BorderSizePixel=0; frame.Active=true; frame.Draggable=true; frame.Parent=sg
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)

local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,28); title.BackgroundColor3=Color3.fromRGB(30,180,120); title.Text="🔍 SCAN PARTIKEL"; title.TextColor3=Color3.new(1,1,1); title.Font=Enum.Font.GothamBold; title.TextSize=12; title.Parent=frame
Instance.new("UICorner",title).CornerRadius=UDim.new(0,8)

local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-8,1,-72); scroll.Position=UDim2.new(0,4,0,32); scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=4; scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=frame
Instance.new("UIListLayout",scroll).Padding=UDim.new(0,2)

local logL=Instance.new("TextLabel"); logL.Size=UDim2.new(1,-4,0,16); logL.BackgroundTransparency=1; logL.TextColor3=Color3.fromRGB(180,180,180); logL.Font=Enum.Font.Code; logL.TextSize=10; logL.TextXAlignment=Enum.TextXAlignment.Left; logL.TextWrapped=true; logL.AutomaticSize=Enum.AutomaticSize.Y

local allLines = {}
local function addLog(s, col)
    table.insert(allLines, s)
    local l=logL:Clone(); l.Text=s; l.TextColor3=col or Color3.fromRGB(180,220,180); l.Parent=scroll
end

-- tombol SCAN
local scanBtn=Instance.new("TextButton"); scanBtn.Size=UDim2.new(0.5,-6,0,28); scanBtn.Position=UDim2.new(0,4,1,-32); scanBtn.BackgroundColor3=Color3.fromRGB(30,120,220); scanBtn.Text="SCAN"; scanBtn.TextColor3=Color3.new(1,1,1); scanBtn.Font=Enum.Font.GothamBold; scanBtn.TextSize=11; scanBtn.Parent=frame
Instance.new("UICorner",scanBtn).CornerRadius=UDim.new(0,6)

-- tombol COPY ALL
local copyBtn=Instance.new("TextButton"); copyBtn.Size=UDim2.new(0.5,-6,0,28); copyBtn.Position=UDim2.new(0.5,2,1,-32); copyBtn.BackgroundColor3=Color3.fromRGB(80,60,160); copyBtn.Text="COPY ALL"; copyBtn.TextColor3=Color3.new(1,1,1); copyBtn.Font=Enum.Font.GothamBold; copyBtn.TextSize=11; copyBtn.Parent=frame
Instance.new("UICorner",copyBtn).CornerRadius=UDim.new(0,6)

copyBtn.MouseButton1Click:Connect(function()
    local txt = table.concat(allLines, "\n")
    setclipboard(txt)
    copyBtn.Text = "✓ COPIED"
    task.delay(1.5, function() copyBtn.Text = "COPY ALL" end)
end)

-- ======== SCAN FUNCTION ========
local WEATHER_NAMES = {
    "WeatherVisuals","WeatherObjects","WindBlastTemplate",
    "Whale","Clam","Kelp","Water_Effect","SpottedEffect",
    "SpiderWebFX","Rainbows","Dirt_VFX","BirthdayDecor",
    "BeanstalkEvent","AcornChaosLocal","Visuals","FishRainClient",
    "TornadoFX","CycloneFX","MeteorFX","LavaPools",
    "IcicleSpawner","SnowFX","FrostFX","LightningFX",
}

local PARTICLE_CLASSES = {
    "ParticleEmitter","Trail","Smoke","Fire","Sparkles",
    "BlurEffect","ColorCorrectionEffect","BloomEffect","SunRaysEffect","DepthOfFieldEffect",
}

local function isParticleClass(obj)
    for _,c in ipairs(PARTICLE_CLASSES) do
        if obj:IsA(c) then return true end
    end
    return false
end

local function scanAll()
    for _,c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    allLines = {}

    local Lighting = game:GetService("Lighting")
    local ws = workspace
    local found = 0

    addLog("── WORKSPACE CHILDREN ──", Color3.fromRGB(100,200,255))
    for _, obj in ipairs(ws:GetChildren()) do
        local isKnown = false
        for _, name in ipairs(WEATHER_NAMES) do
            if obj.Name == name then
                addLog("⚠️ WEATHER: "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,180,60))
                found = found + 1; isKnown = true; break
            end
        end
        if not isKnown and isParticleClass(obj) then
            addLog("❓ UNKNOWN: "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,120,120))
            found = found + 1
        end
    end

    addLog("── LIGHTING ──", Color3.fromRGB(100,200,255))
    for _, obj in ipairs(Lighting:GetChildren()) do
        if isParticleClass(obj) then
            addLog("💡 "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,220,80))
            found = found + 1
        end
    end
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") or obj:IsA("Sky") then
            addLog("🌤 "..obj.ClassName..": "..obj.Name, Color3.fromRGB(160,220,255))
        end
        if isParticleClass(obj) then
            addLog("💡 desc: "..obj.Name.." ["..obj.ClassName.."]", Color3.fromRGB(255,200,80))
            found = found + 1
        end
    end

    addLog("── WS DESCENDANTS (partikel) ──", Color3.fromRGB(100,200,255))
    local wsPartikel = {}
    pcall(function()
        for _, obj in ipairs(ws:GetDescendants()) do
            if isParticleClass(obj) then
                local path = obj.Name.."["..obj.ClassName.."] @"..obj.Parent.Name
                table.insert(wsPartikel, path)
                found = found + 1
                if #wsPartikel > 30 then break end
            end
        end
    end)
    if #wsPartikel == 0 then
        addLog("  (tidak ada)", Color3.fromRGB(120,120,120))
    else
        for _,s in ipairs(wsPartikel) do
            addLog("  "..s, Color3.fromRGB(255,150,100))
        end
    end

    addLog("── TOTAL: "..found.." objek ──", Color3.fromRGB(180,255,180))
end

scanBtn.MouseButton1Click:Connect(scanAll)
task.spawn(scanAll)
