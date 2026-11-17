-- ============================================================
-- DEBUG COCONUT ATTR v0.1
-- Detect semua object "coconut" / buah di Plants_Physical kebun sendiri
-- Dump semua attribute, children, className-nya
-- ============================================================
local plr = game.Players.LocalPlayer

local LOG = {}
local function log(t, col)
    table.insert(LOG, t)
    print("[COCONUT]", t)
end

local function dumpAttrs(obj, indent)
    indent = indent or "  "
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if ok and attrs then
        local any = false
        for k, v in pairs(attrs) do
            log(indent .. "attr[" .. k .. "] = " .. tostring(v))
            any = true
        end
        if not any then log(indent .. "(tidak ada attribute)") end
    else
        log(indent .. "(GetAttributes gagal: " .. tostring(attrs) .. ")")
    end
end

local function dumpObj(obj, depth, indent)
    depth = depth or 0
    indent = indent or ""
    if depth > 5 then return end
    local name = obj.Name
    local cls  = obj.ClassName
    log(indent .. "▸ " .. name .. " [" .. cls .. "]")
    dumpAttrs(obj, indent .. "  ")
    -- cek children
    local children = obj:GetChildren()
    if #children > 0 then
        log(indent .. "  children: " .. #children)
        for _, c in ipairs(children) do
            dumpObj(c, depth+1, indent .. "  ")
        end
    end
end

local function scanCoconut()
    log("=== SCAN COCONUT ATTR ===")
    local farm = workspace:FindFirstChild("Farm")
    if not farm then log("workspace.Farm tidak ada!"); return end

    -- cari subfarm sendiri
    local mySubfarm
    for _, sf in ipairs(farm:GetChildren()) do
        pcall(function()
            if sf.Name == plr.Name then mySubfarm = sf; return end
            local sign = sf:FindFirstChild("Sign") or sf:FindFirstChild("Sign", true)
            local owner = sign and sign:GetAttribute("_owner")
            if owner == plr.Name then mySubfarm = sf end
        end)
    end

    if not mySubfarm then
        log("Subfarm sendiri TIDAK ketemu (coba nama: " .. plr.Name .. ")")
        -- fallback: scan semua subfarm
        log("Fallback: scan SEMUA subfarm...")
        for _, sf in ipairs(farm:GetChildren()) do
            mySubfarm = sf
            break
        end
        if not mySubfarm then log("Farm kosong!"); return end
    end

    log("Subfarm: " .. mySubfarm.Name)

    -- cari Plants_Physical
    local pp
    for _, desc in ipairs(mySubfarm:GetDescendants()) do
        if desc.Name == "Plants_Physical" then pp = desc; break end
    end
    if not pp then log("Plants_Physical tidak ada di subfarm!"); return end
    log("Plants_Physical: " .. pp:GetFullName())
    log("Jumlah pohon/tanaman: " .. #pp:GetChildren())

    -- scan setiap model pohon
    local found = 0
    for _, tree in ipairs(pp:GetChildren()) do
        local treeName = tree.Name:lower()
        -- cari yang coconut
        if treeName:find("coconut", 1, true) or treeName:find("cocon", 1, true) then
            found += 1
            log("--- COCONUT TREE: " .. tree.Name .. " ---")
            dumpObj(tree, 0, "  ")
        end
    end

    if found == 0 then
        log("Tidak ada pohon coconut ditemukan. Scan semua pohon:")
        log("Daftar nama pohon di Plants_Physical:")
        for _, tree in ipairs(pp:GetChildren()) do
            log("  " .. tree.Name .. " [" .. tree.ClassName .. "]")
            -- dump attribute pohon
            dumpAttrs(tree, "    ")
            -- cek Fruits
            local fruits = tree:FindFirstChild("Fruits")
            if fruits then
                log("    Fruits: " .. #fruits:GetChildren() .. " buah")
                for i, buah in ipairs(fruits:GetChildren()) do
                    if i <= 3 then  -- tampil max 3 buah
                        log("      Buah[" .. i .. "]: " .. buah.Name .. " [" .. buah.ClassName .. "]")
                        dumpAttrs(buah, "        ")
                    end
                end
                if #fruits:GetChildren() > 3 then
                    log("      ...dan " .. (#fruits:GetChildren()-3) .. " buah lagi")
                end
            end
        end
    end

    log("=== SELESAI ===")
end

-- ── GUI ──────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgCoconutAttr"; sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 420)
frame.Position = UDim2.new(0, 10, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local strokeInst = Instance.new("UIStroke", frame)
strokeInst.Color = Color3.fromRGB(255, 180, 50)  -- kuning coconut
strokeInst.Thickness = 1

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(30, 20, 5)
title.BorderSizePixel = 0
title.Text = "🥥 Coconut Attr Debug"
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

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -34)
scroll.Position = UDim2.new(0, 4, 0, 30)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame
local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 1)

local lineOrder = 0
local function addLine(t, col)
    lineOrder += 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -6, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = col or Color3.fromRGB(210, 210, 210)
    lbl.TextSize = 10; lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true; lbl.Text = t
    lbl.LayoutOrder = lineOrder; lbl.Parent = scroll
    task.defer(function()
        scroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

scanBtn.MouseButton1Click:Connect(function()
    -- clear dulu
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    LOG = {}; lineOrder = 0
    scanBtn.Text = "..."

    -- redirect log ke GUI juga
    local origLog = log
    local function guiLog(t)
        origLog(t)
        local col = Color3.fromRGB(210, 210, 210)
        if t:find("COCONUT") or t:find("===") then col = Color3.fromRGB(255, 200, 80) end
        if t:find("attr%[") then col = Color3.fromRGB(100, 220, 255) end
        if t:find("Fruits") or t:find("Buah") then col = Color3.fromRGB(180, 255, 100) end
        if t:find("tidak ada") or t:find("TIDAK") or t:find("gagal") then col = Color3.fromRGB(255, 100, 100) end
        addLine(t, col)
    end
    log = guiLog

    pcall(scanCoconut)
    log = origLog
    scanBtn.Text = "▶ SCAN"
end)

print("[COCONUT] dbg_coconut_attr v0.1 — tekan SCAN di panel")
