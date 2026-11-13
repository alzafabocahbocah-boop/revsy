-- ============================================================
-- DBG GILDED CHOC PERYTON ANIM v0.1
-- Monitor semua CustomAnimationState dari DataStream
-- khusus uuid d735xxxx dan bc8fxxxx
-- ============================================================
local RS     = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local GILDED_UUIDS = { ["d735"] = true, ["bc8f"] = true }

local LOG = {}  -- { time, uuid8, anim }
local LOG_MAX = 60

local function push(uuid8, anim)
    local ts = os.date("%H:%M:%S")
    local ms = math.floor((tick() % 1) * 1000)
    local entry = string.format("%s.%03d | %s | %s", ts, ms, uuid8, anim)
    table.insert(LOG, 1, entry)
    if #LOG > LOG_MAX then table.remove(LOG) end
    print("[GILDED]", entry)
end

-- ── DataStream listener ──────────────────────────────────────
local lastAnim = {}

local function scanDS(t, depth)
    depth = depth or 0
    if depth > 6 or type(t) ~= "table" then return end
    for _, v in pairs(t) do
        if type(v) == "table" then
            local path = tostring(v[1] or "")
            if path:find("CustomAnimationState", 1, true) then
                -- ambil uuid dari path
                local uuid = path:match("{([^}]+)}") or path:match("([%x%-]+)$") or "?"
                local uuid8 = uuid:sub(1,8):lower():gsub("%-",""):gsub("{",""):gsub("}",""):sub(1,4)
                if GILDED_UUIDS[uuid8] then
                    local animStr = tostring(v[2] or "")
                    if animStr ~= "" and lastAnim[uuid] ~= animStr then
                        lastAnim[uuid] = animStr
                        push(uuid:sub(1,8), animStr)
                    elseif animStr == "" or animStr == "Idle" or animStr == "Walk" or animStr == "Run" then
                        lastAnim[uuid] = nil
                    end
                end
            else
                scanDS(v, depth + 1)
            end
        end
    end
end

task.spawn(function()
    local ge = RS:WaitForChild("GameEvents", 10)
    if not ge then print("[GILDED] GameEvents not found"); return end
    local ds = ge:WaitForChild("DataStream", 10)
    if not ds then print("[GILDED] DataStream not found"); return end
    ds.OnClientEvent:Connect(function(_, service, data)
        if type(data) ~= "table" then return end
        scanDS(data)
    end)
    print("[GILDED] DS listener ON — watching d735xxxx & bc8fxxxx")
end)

-- ── GUI Panel ────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgGildedGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = player:WaitForChild("PlayerGui")

-- panel utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 380)
frame.Position = UDim2.new(0, 10, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(80, 160, 255)
stroke.Thickness = 1

-- title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
title.BorderSizePixel = 0
title.Text = "🦌 Gilded Choc Peryton — Anim"
title.TextColor3 = Color3.fromRGB(100, 200, 255)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- tombol clear
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 54, 0, 20)
clearBtn.Position = UDim2.new(1, -58, 0, 4)
clearBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "clear"
clearBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
clearBtn.TextSize = 11
clearBtn.Font = Enum.Font.Gotham
clearBtn.Parent = frame
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)
clearBtn.MouseButton1Click:Connect(function()
    LOG = {}
    lastAnim = {}
end)

-- scroll
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
layout.Padding = UDim.new(0, 2)

-- buat rows
local ROWS = 30
local rows = {}
for i = 1, ROWS do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -6, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = ""
    lbl.Visible = false
    lbl.LayoutOrder = i
    lbl.Parent = scroll
    rows[i] = lbl
end

-- warna per anim
local function getColor(anim)
    local a = anim:lower()
    if a:find("frill")  then return Color3.fromRGB(255, 100, 200) end
    if a:find("roar")   then return Color3.fromRGB(255, 160,  60) end
    if a:find("fan")    then return Color3.fromRGB(100, 220, 255) end
    if a:find("pee")    then return Color3.fromRGB(255, 230,  80) end
    if a:find("pew")    then return Color3.fromRGB(180, 255, 100) end
    if a:find("idle") or a:find("walk") or a:find("run") then
        return Color3.fromRGB(100, 100, 100)
    end
    return Color3.fromRGB(220, 180, 255)  -- unknown = ungu muda
end

-- render loop
task.spawn(function()
    while true do
        task.wait(0.1)
        for i = 1, ROWS do
            local entry = LOG[i]
            if entry then
                rows[i].Text = entry
                -- warna dari anim bagian terakhir
                local anim = entry:match("| ([^|]+)$") or ""
                rows[i].TextColor3 = getColor(anim)
                rows[i].Visible = true
            else
                rows[i].Visible = false
            end
        end
    end
end)

print("[GILDED] dbg_gilded_anim v0.1 LOADED")
