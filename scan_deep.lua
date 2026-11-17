-- ============================================================
-- DEEP SCAN COCONUT v1.0
-- Dump SEMUA info: atribut pohon, buah, children buah, CS tags
-- Tujuan: nemuin di mana KG buah disimpan
-- ============================================================
local plr = game.Players.LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local CS  = game:GetService("CollectionService")

local _allLines = {}
local function log(s) table.insert(_allLines, s) print("[DEEP] "..s) end

-- ── cari farm ────────────────────────────────────────────
local function getMyFarm()
    local farmWS = workspace:FindFirstChild("Farm")
    if not farmWS then return nil end
    for _, sf in ipairs(farmWS:GetChildren()) do
        local found = false
        pcall(function()
            if sf.Name == plr.Name then found = true; return end
            local imp  = sf:FindFirstChild("Important")
            local data = imp and imp:FindFirstChild("Data")
            local own  = data and data:FindFirstChild("Owner")
            if own and own.Value == plr.Name then found = true; return end
        end)
        if found then return sf end
    end
    return nil
end

local function getMyPP()
    local farm = getMyFarm()
    if not farm then return nil end
    local imp = farm:FindFirstChild("Important")
    if imp then
        local pp = imp:FindFirstChild("Plants_Physical")
        if pp then return pp end
    end
    for _, d in ipairs(farm:GetDescendants()) do
        if d.Name == "Plants_Physical" then return d end
    end
    return nil
end

-- ── dump atribut object ──────────────────────────────────
local function dumpAttrs(obj, prefix)
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if not ok or not attrs then log(prefix.."  [GetAttributes GAGAL]"); return end
    local keys = {}
    for k in pairs(attrs) do table.insert(keys, k) end
    table.sort(keys)
    if #keys == 0 then
        log(prefix.."  attrs: (kosong)")
    else
        for _, k in ipairs(keys) do
            log(prefix.."  attr: "..k.." = "..tostring(attrs[k]))
        end
    end
end

-- ── dump CS tags ─────────────────────────────────────────
local function dumpTags(obj, prefix)
    local ok, tags = pcall(function() return CS:GetTags(obj) end)
    if not ok or not tags or #tags == 0 then return end
    log(prefix.."  tags: "..table.concat(tags, ", "))
end

-- ── dump properties umum ─────────────────────────────────
local function dumpProps(obj, prefix)
    local props = {}
    -- coba baca properties yang mungkin nyimpen nilai
    local tryProps = {
        "Value","Weight","KG","Kg","kg","Mass","Size",
        "Name","ClassName","Health","MaxHealth",
        "Transparency","BrickColor","Material",
    }
    for _, p in ipairs(tryProps) do
        local ok2, v = pcall(function() return obj[p] end)
        if ok2 and v ~= nil then
            table.insert(props, p.."="..tostring(v))
        end
    end
    if #props > 0 then
        log(prefix.."  props: "..table.concat(props, " | "))
    end
end

-- ── dump children ────────────────────────────────────────
local function dumpChildren(obj, prefix, depth)
    if depth <= 0 then return end
    local children = obj:GetChildren()
    if #children == 0 then return end
    log(prefix.."  children ("..#children.."):")
    for _, c in ipairs(children) do
        log(prefix.."    ["..c.ClassName.."] "..c.Name)
        dumpAttrs(c, prefix.."    ")
        dumpTags(c, prefix.."    ")
        dumpProps(c, prefix.."    ")
        -- recurse 1 level lagi
        if depth > 1 then
            dumpChildren(c, prefix.."    ", depth-1)
        end
    end
end

-- ── MAIN SCAN ────────────────────────────────────────────
local function doDeepScan()
    log("========================================")
    log("DEEP SCAN START")
    log("========================================")

    local pp = getMyPP()
    if not pp then log("ERROR: Plants_Physical tidak ketemu"); return end

    local coconutTrees = {}
    for _, tree in ipairs(pp:GetChildren()) do
        if tree:IsA("Model") then
            local nm = tree.Name:lower()
            if nm:find("coconut",1,true) or nm:find("cocon",1,true) then
                table.insert(coconutTrees, tree)
            end
        end
    end

    log("Ketemu "..#coconutTrees.." pohon coconut")

    -- scan 1 pohon pertama secara mendalam, sisanya ringkasan
    for treeIdx, tree in ipairs(coconutTrees) do
        log("----------------------------------------")
        log("POHON #"..treeIdx..": "..tree.Name.." ["..tree.ClassName.."]")

        -- atribut pohon
        log("  === ATRIBUT POHON ===")
        dumpAttrs(tree, "")
        dumpTags(tree, "")
        dumpProps(tree, "")

        -- children langsung pohon
        log("  === CHILDREN POHON ===")
        for _, c in ipairs(tree:GetChildren()) do
            log("  ["..c.ClassName.."] "..c.Name)
            dumpAttrs(c, "  ")
            dumpTags(c, "  ")
            dumpProps(c, "  ")

            -- kalau Fruits folder, scan tiap buah
            if c.Name == "Fruits" then
                local buahList = c:GetChildren()
                log("  Fruits: "..#buahList.." buah")

                -- scan SEMUA buah (bukan cuma 4)
                for buahIdx, buah in ipairs(buahList) do
                    log("  --- buah#"..buahIdx.." ["..buah.ClassName.."] "..buah.Name.." ---")

                    -- atribut buah
                    log("    ATRIBUT:")
                    dumpAttrs(buah, "    ")

                    -- tags buah
                    dumpTags(buah, "    ")

                    -- props buah
                    log("    PROPERTIES:")
                    dumpProps(buah, "    ")

                    -- children buah (depth 2)
                    if #buah:GetChildren() > 0 then
                        log("    CHILDREN BUAH:")
                        dumpChildren(buah, "    ", 2)
                    end

                    -- kalau treeIdx > 1, cukup scan 3 buah pertama
                    if treeIdx > 1 and buahIdx >= 3 then
                        log("  ... (skip sisa buah, pohon #"..treeIdx..")")
                        break
                    end
                end
            end
        end
    end

    -- scan via CollectionService "Harvestable" juga
    log("========================================")
    log("CS:GetTagged('Harvestable') — 3 buah pertama dari farm sendiri:")
    local farm = getMyFarm()
    local count = 0
    for _, fruit in ipairs(CS:GetTagged("Harvestable")) do
        if farm and fruit:IsDescendantOf(farm) then
            count += 1
            if count <= 3 then
                log("CS buah#"..count..": "..fruit.Name.." path="..fruit:GetFullName())
                dumpAttrs(fruit, "")
                dumpTags(fruit, "")
                dumpProps(fruit, "")
                if #fruit:GetChildren() > 0 then
                    log("  children:")
                    dumpChildren(fruit, "  ", 2)
                end
            end
        end
    end
    log("Total Harvestable di farm: "..count)

    log("========================================")
    log("DEEP SCAN SELESAI — total "..#_allLines.." baris")
    log("========================================")
end

-- ── GUI minimal ──────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DeepScan"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,320,0,80)
frame.Position = UDim2.new(0,10,0,10)
frame.BackgroundColor3 = Color3.fromRGB(8,8,8)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(100,200,255)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,22); title.BackgroundColor3 = Color3.fromRGB(10,20,35)
title.BorderSizePixel = 0; title.Text = "🔍 DEEP SCAN — cari KG buah coconut"
title.TextColor3 = Color3.fromRGB(100,200,255); title.TextSize = 10
title.Font = Enum.Font.GothamBold; title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0,8)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0,130,0,26); scanBtn.Position = UDim2.new(0,4,0,26)
scanBtn.BackgroundColor3 = Color3.fromRGB(15,35,50); scanBtn.BorderSizePixel = 0
scanBtn.Text = "▶ DEEP SCAN"; scanBtn.TextColor3 = Color3.fromRGB(100,200,255)
scanBtn.TextSize = 11; scanBtn.Font = Enum.Font.GothamBold; scanBtn.Parent = frame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0,4)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0,130,0,26); copyBtn.Position = UDim2.new(0,138,0,26)
copyBtn.BackgroundColor3 = Color3.fromRGB(20,20,40); copyBtn.BorderSizePixel = 0
copyBtn.Text = "📋 Copy Log"; copyBtn.TextColor3 = Color3.fromRGB(160,180,255)
copyBtn.TextSize = 11; copyBtn.Font = Enum.Font.GothamBold; copyBtn.Parent = frame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,4)

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(1,-8,0,16); statLbl.Position = UDim2.new(0,4,0,56)
statLbl.BackgroundTransparency = 1; statLbl.Text = "belum scan"
statLbl.TextColor3 = Color3.fromRGB(150,150,150); statLbl.TextSize = 9
statLbl.Font = Enum.Font.Code; statLbl.Parent = frame

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "scanning..."
    _allLines = {}
    task.spawn(function()
        pcall(doDeepScan)
        scanBtn.Text = "▶ DEEP SCAN"
        statLbl.Text = "✅ done — "..#_allLines.." baris — tekan Copy"
        statLbl.TextColor3 = Color3.fromRGB(100,255,100)
    end)
end)

copyBtn.MouseButton1Click:Connect(function()
    if #_allLines == 0 then
        copyBtn.Text = "⚠ scan dulu!"; task.delay(2, function() copyBtn.Text = "📋 Copy Log" end); return
    end
    local txt = table.concat(_allLines, "\n")
    local ok = pcall(function() setclipboard(txt) end)
    if ok then
        copyBtn.Text = "✅ Copied! ("..#_allLines..")"
    else
        print("[DEEP SCAN LOG]===START===")
        for _, l in ipairs(_allLines) do print(l) end
        print("[DEEP SCAN LOG]===END===")
        copyBtn.Text = "⚠ cek console"
    end
    task.delay(3, function() copyBtn.Text = "📋 Copy Log" end)
end)

print("[DEEP SCAN] loaded — klik DEEP SCAN lalu Copy Log")
