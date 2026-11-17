-- ============================================================
-- DEBUG COCONUT KG v0.1
-- Cek kg per buah coconut + jumlah pohon coconut di kebun sendiri
-- ============================================================
local plr = game.Players.LocalPlayer

-- ── cari Plants_Physical kebun sendiri ──────────────────────
local function getMyPP()
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return nil, "workspace.Farm tidak ada" end
    for _, sf in ipairs(farm:GetChildren()) do
        local found = false
        pcall(function()
            if sf.Name == plr.Name then found = true; return end
            local sign = sf:FindFirstChild("Sign") or sf:FindFirstChild("Sign", true)
            local owner = sign and sign:GetAttribute("_owner")
            if owner == plr.Name then found = true end
        end)
        if found then
            for _, desc in ipairs(sf:GetDescendants()) do
                if desc.Name == "Plants_Physical" then return desc, nil end
            end
            return nil, "Plants_Physical tidak ada di subfarm"
        end
    end
    return nil, "Subfarm sendiri tidak ketemu"
end

-- ── ambil nilai kg dari object ────────────────────────────
local function getKg(obj)
    local keys = { "kg", "KG", "weight", "Weight", "value", "Value",
                   "fruitKg", "FruitKg", "fruit_kg", "amount", "Amount",
                   "size", "Size", "mass", "Mass" }
    for _, k in ipairs(keys) do
        local ok, v = pcall(function() return obj:GetAttribute(k) end)
        if ok and v and tonumber(v) then return tonumber(v), k end
    end
    -- cek semua attribute
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if ok and attrs then
        for k, v in pairs(attrs) do
            if tonumber(v) then return tonumber(v), k end
        end
    end
    return nil, nil
end

-- ── SCAN khusus COCONUT ──────────────────────────────────────
local function scanCoconutKg()
    local pp, err = getMyPP()
    if not pp then return nil, err end

    local results = {}  -- list of { treeIdx, buahCount, kgSample, kgTotal, attrKey, buahList }

    for _, tree in ipairs(pp:GetChildren()) do
        if tree:IsA("Model") then
            local nm = tree.Name:lower()
            if nm:find("coconut", 1, true) or nm:find("cocon", 1, true) then
                local fruits = tree:FindFirstChild("Fruits")
                local buahCount = 0
                local kgTotal = 0
                local kgSample = nil
                local attrKey = nil
                local buahList = {}

                if fruits then
                    for _, buah in ipairs(fruits:GetChildren()) do
                        buahCount += 1
                        local kg, key = getKg(buah)
                        if not kg then
                            -- cek children buah
                            for _, ch in ipairs(buah:GetChildren()) do
                                local kg2, key2 = getKg(ch)
                                if kg2 then kg, key = kg2, key2; break end
                            end
                        end
                        if kg then
                            kgTotal += kg
                            kgSample = kg
                            attrKey = key
                            table.insert(buahList, { name = buah.Name, kg = kg })
                        else
                            table.insert(buahList, { name = buah.Name, kg = nil })
                        end
                    end
                end

                -- fallback: kg dari tree itu sendiri
                if buahCount == 0 then
                    local tKg, tKey = getKg(tree)
                    if tKg then kgSample = tKg; kgTotal = tKg; attrKey = tKey end
                end

                table.insert(results, {
                    treeName  = tree.Name,
                    buahCount = buahCount,
                    kgSample  = kgSample,
                    kgTotal   = kgTotal,
                    attrKey   = attrKey or "?",
                    buahList  = buahList,
                    hasFruits = fruits ~= nil,
                })
            end
        end
    end

    return results, nil
end

-- ── GUI ──────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgCoconutKg"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 460)
frame.Position = UDim2.new(0, 10, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local strokeInst = Instance.new("UIStroke", frame)
strokeInst.Color = Color3.fromRGB(255, 180, 50)
strokeInst.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(30, 20, 5)
title.BorderSizePixel = 0
title.Text = "🥥 Coconut KG Debug"
title.TextColor3 = Color3.fromRGB(255, 200, 80)
title.TextSize = 12; title.Font = Enum.Font.GothamBold
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0, 80, 0, 22)
scanBtn.Position = UDim2.new(1, -88, 0, 3)
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 35, 10)
scanBtn.BorderSizePixel = 0
scanBtn.Text = "▶ SCAN"
scanBtn.TextColor3 = Color3.fromRGB(255, 210, 100)
scanBtn.TextSize = 11; scanBtn.Font = Enum.Font.GothamBold
scanBtn.Parent = frame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 4)

local sumBar = Instance.new("TextLabel")
sumBar.Size = UDim2.new(1, -8, 0, 20)
sumBar.Position = UDim2.new(0, 4, 0, 30)
sumBar.BackgroundColor3 = Color3.fromRGB(24, 18, 5)
sumBar.BorderSizePixel = 0
sumBar.Text = "tekan SCAN"
sumBar.TextColor3 = Color3.fromRGB(255, 220, 120)
sumBar.TextSize = 10; sumBar.Font = Enum.Font.GothamBold
sumBar.Parent = frame
Instance.new("UICorner", sumBar).CornerRadius = UDim.new(0, 4)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -56)
scroll.Position = UDim2.new(0, 4, 0, 54)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame
local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)

local rowOrder = 0
local function clearRows()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    rowOrder = 0
end

local function addRow(txt, col, bg, bold)
    rowOrder += 1
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -6, 0, 18)
    row.BackgroundColor3 = bg or Color3.fromRGB(14, 10, 2)
    row.BackgroundTransparency = bg and 0 or 0.5
    row.BorderSizePixel = 0
    row.TextColor3 = col or Color3.fromRGB(220, 200, 150)
    row.TextSize = 10
    row.Font = bold and Enum.Font.GothamBold or Enum.Font.Code
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextWrapped = false; row.Text = txt
    row.LayoutOrder = rowOrder; row.Parent = scroll
    local rp = Instance.new("UIPadding", row)
    rp.PaddingLeft = UDim.new(0, 4)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 3)
end

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "..."
    clearRows()
    sumBar.Text = "scanning coconut..."
    sumBar.TextColor3 = Color3.fromRGB(255, 220, 120)

    task.spawn(function()
        local res, err = scanCoconutKg()
        if not res then
            sumBar.Text = "ERROR: " .. tostring(err)
            sumBar.TextColor3 = Color3.fromRGB(255, 100, 100)
            addRow(tostring(err), Color3.fromRGB(255, 100, 100))
            scanBtn.Text = "▶ SCAN"
            return
        end

        if #res == 0 then
            sumBar.Text = "⚠ Tidak ada pohon coconut ditemukan!"
            sumBar.TextColor3 = Color3.fromRGB(255, 150, 50)
            addRow("Pohon coconut tidak ada di Plants_Physical kebun kamu", Color3.fromRGB(255, 150, 50))
            addRow("Pastikan nama pohon mengandung 'coconut' atau 'cocon'", Color3.fromRGB(180, 180, 180))
            scanBtn.Text = "▶ SCAN"
            return
        end

        -- hitung total
        local totalPohon = #res
        local totalBuah = 0
        local totalKg = 0
        for _, r in ipairs(res) do
            totalBuah += r.buahCount
            totalKg   += r.kgTotal
        end

        local avgKg = totalBuah > 0 and (totalKg / totalBuah) or 0
        sumBar.Text = string.format("🥥 %d pohon | %d buah | %.2f kg/buah | %.1f kg total",
            totalPohon, totalBuah, avgKg, totalKg)
        sumBar.TextColor3 = Color3.fromRGB(255, 220, 100)

        for i, r in ipairs(res) do
            -- header pohon
            local kgPerBuah = r.buahCount > 0 and (r.kgTotal / r.buahCount) or (r.kgSample or 0)
            local hdr = string.format("🌴 Pohon #%d: %s", i, r.treeName)
            addRow(hdr, Color3.fromRGB(255, 210, 80), Color3.fromRGB(28, 20, 5), true)

            addRow(string.format("   Jumlah buah: %d | kg/buah: %.2f | total: %.1f kg",
                r.buahCount, kgPerBuah, r.kgTotal),
                Color3.fromRGB(220, 200, 140), Color3.fromRGB(18, 14, 4))

            if r.attrKey ~= "?" then
                addRow("   attr key: [" .. r.attrKey .. "]",
                    Color3.fromRGB(100, 180, 255), Color3.fromRGB(10, 12, 20))
            end

            if not r.hasFruits then
                addRow("   ⚠ tidak ada folder Fruits",
                    Color3.fromRGB(255, 150, 50), Color3.fromRGB(20, 12, 4))
            elseif r.buahCount == 0 then
                addRow("   ⚠ Fruits kosong (buah belum tumbuh?)",
                    Color3.fromRGB(255, 150, 50), Color3.fromRGB(20, 12, 4))
            else
                -- tampilkan max 5 buah
                local shown = 0
                for _, buah in ipairs(r.buahList) do
                    if shown >= 5 then
                        addRow(string.format("   ...+%d buah lagi", r.buahCount - shown),
                            Color3.fromRGB(150, 150, 150))
                        break
                    end
                    local kgTxt = buah.kg and string.format("%.2f kg", buah.kg) or "(kg ?)"
                    addRow(string.format("   • %s — %s", buah.name, kgTxt),
                        buah.kg and Color3.fromRGB(180, 240, 160) or Color3.fromRGB(255, 130, 80),
                        Color3.fromRGB(14, 18, 10))
                    shown += 1
                end
            end
        end

        -- print ke console juga
        print("[COCONUT KG] ===== HASIL =====")
        print(string.format("[COCONUT KG] %d pohon, %d buah, %.2f kg/buah avg, %.1f kg total",
            totalPohon, totalBuah, avgKg, totalKg))
        for i, r in ipairs(res) do
            local kpb = r.buahCount > 0 and (r.kgTotal / r.buahCount) or (r.kgSample or 0)
            print(string.format("[COCONUT KG] Pohon#%d %s — buah=%d kgPerBuah=%.2f totalKg=%.1f attrKey=%s",
                i, r.treeName, r.buahCount, kpb, r.kgTotal, r.attrKey))
        end

        scanBtn.Text = "▶ SCAN"
    end)
end)

print("[COCONUT KG] debug_coconut_kg v0.1 — tekan SCAN di panel kuning")
