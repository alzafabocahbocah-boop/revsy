-- debug_nm_compare.lua
-- Bandingin NM count dari 2 jalur:
-- A) CollectionService:GetTagged("Harvestable") + attr Nightmare==true
-- B) Loop manual: Farm → subfarm → Plants_Physical → Model → Fruit → attr Nightmare==true

local CS = game:GetService("CollectionService")
local WS = workspace
local plr = game.Players.LocalPlayer

local function getPlayerFarm()
    local farms = WS:FindFirstChild("Farm")
    if not farms then return nil end
    for _, f in ipairs(farms:GetChildren()) do
        local imp = f:FindFirstChild("Important")
        local data = imp and imp:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner and owner.Value == plr.Name then return f end
    end
    return nil
end

local function compareNM()
    local farm = getPlayerFarm()
    if not farm then print("[NM-CMP] farm nil!"); return end

    -- Jalur A: CollectionService tag
    local tagTotal, tagNM = 0, 0
    for _, fruit in ipairs(CS:GetTagged("Harvestable")) do
        if fruit:IsDescendantOf(farm) then
            tagTotal = tagTotal + 1
            if fruit:GetAttribute("Nightmare") == true then
                tagNM = tagNM + 1
            end
        end
    end

    -- Jalur B: Loop manual pohon
    local manualTotal, manualNM = 0, 0
    local manualNoAttr = 0
    for _, subfarm in ipairs(farm:GetChildren()) do
        local plants = subfarm:FindFirstChild("Plants_Physical")
        if not plants then continue end
        for _, tree in ipairs(plants:GetChildren()) do
            if not tree:IsA("Model") then continue end
            -- cari fruit di dalam tree
            for _, child in ipairs(tree:GetChildren()) do
                -- fruit biasanya Model dengan tag Harvestable, atau BasePart
                if child:IsA("Model") or child:IsA("BasePart") then
                    manualTotal = manualTotal + 1
                    local nm = child:GetAttribute("Nightmare")
                    if nm == true then
                        manualNM = manualNM + 1
                    elseif nm == nil then
                        manualNoAttr = manualNoAttr + 1
                    end
                end
            end
        end
    end

    -- Jalur C: scanFruits dari _G (kalau ada)
    local sfNM = "N/A"
    if _G._UPL_scanFruits then
        local ok, data = pcall(_G._UPL_scanFruits)
        if ok and data then
            sfNM = tostring(data.nm or #(data.shovel or {}))
        end
    end

    -- _nmCached dari NMPoller
    local cached = tostring(_G._UPL_nmCached or "N/A")

    print("===== NM COMPARE =====")
    print("A) CS:GetTagged  → total="..tagTotal.."  NM="..tagNM)
    print("B) Manual loop   → total="..manualTotal.." NM="..manualNM.." noAttr="..manualNoAttr)
    print("C) scanFruits _G → NM="..sfNM)
    print("D) _nmCached     → "..cached)
    print("======================")
end

-- Jalankan sekali, lalu tiap 3s — hasil otomatis di-copy ke clipboard
local _lastResult = ""

local function compareAndCopy()
    local farm = getPlayerFarm()
    if not farm then print("[NM-CMP] farm nil!"); return end

    local tagTotal, tagNM = 0, 0
    for _, fruit in ipairs(CS:GetTagged("Harvestable")) do
        if fruit:IsDescendantOf(farm) then
            tagTotal = tagTotal + 1
            if fruit:GetAttribute("Nightmare") == true then tagNM = tagNM + 1 end
        end
    end

    local manualTotal, manualNM, manualNoAttr = 0, 0, 0
    for _, subfarm in ipairs(farm:GetChildren()) do
        local plants = subfarm:FindFirstChild("Plants_Physical")
        if not plants then continue end
        for _, tree in ipairs(plants:GetChildren()) do
            if not tree:IsA("Model") then continue end
            for _, child in ipairs(tree:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") then
                    manualTotal = manualTotal + 1
                    local nm = child:GetAttribute("Nightmare")
                    if nm == true then manualNM = manualNM + 1
                    elseif nm == nil then manualNoAttr = manualNoAttr + 1 end
                end
            end
        end
    end

    local sfNM = "N/A"
    if _G._UPL_scanFruits then
        local ok, data = pcall(_G._UPL_scanFruits)
        if ok and data then sfNM = tostring(data.nm or #(data.shovel or {})) end
    end
    local cached = tostring(_G._UPL_nmCached or "N/A")

    local result = table.concat({
        "===== NM COMPARE =====",
        "A) CS:GetTagged  → total="..tagTotal.."  NM="..tagNM,
        "B) Manual loop   → total="..manualTotal.." NM="..manualNM.." noAttr="..manualNoAttr,
        "C) scanFruits _G → NM="..sfNM,
        "D) _nmCached     → "..cached,
        "======================",
    }, "\n")

    print(result)

    -- auto copy kalau hasil berubah
    if result ~= _lastResult then
        _lastResult = result
        setclipboard(result)
        print("[NM-CMP] ✓ auto-copied ke clipboard")
    end
end

compareAndCopy()
task.spawn(function()
    while true do
        task.wait(3)
        compareAndCopy()
    end
end)
