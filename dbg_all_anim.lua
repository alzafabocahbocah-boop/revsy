-- ============================================================
-- DBG ALL ANIM STATE — log semua CustomAnimationState dari semua pet
-- Buat cek skill name apa aja yang ada di game
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local function lg(src, msg)
    print(string.format("[%.2f][%s] %s", os.clock(), src, msg))
end

local seen = {}  -- track state per uuid biar gak spam
local function scanAnim(t, depth)
    depth = depth or 0
    if depth > 6 or type(t) ~= "table" then return end
    for _, v in pairs(t) do
        if type(v) == "table" then
            local path = tostring(v[1] or "")
            if path:find("CustomAnimationState", 1, true) then
                local uuid = path:match("{([^}]+)}") or "?"
                local animStr = tostring(v[2] or "")
                if animStr ~= "" then
                    local key = uuid .. animStr
                    if not seen[key] then
                        seen[key] = true
                        lg("ANIM", string.format("uuid=%s → [%s]", uuid:sub(1,8), animStr))
                    end
                else
                    -- reset seen saat state kosong (idle/clear)
                    for k in pairs(seen) do
                        if k:sub(1, #uuid) == uuid then seen[k] = nil end
                    end
                end
            else
                scanAnim(v, depth+1)
            end
        end
    end
end

task.spawn(function()
    local ge = RS:WaitForChild("GameEvents", 10)
    if not ge then lg("ERR", "GameEvents not found"); return end
    local ds = ge:WaitForChild("DataStream", 10)
    if not ds then lg("ERR", "DataStream not found"); return end
    ds.OnClientEvent:Connect(function(_, service, data)
        if not tostring(service):find("ActivePets", 1, true) then return end
        if type(data) == "table" then scanAnim(data) end
    end)
    lg("INIT", "all anim state watcher ON — biarkan jalan, semua skill akan ke-log sekali")
end)

-- ── GUI Rejoin ────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "DbgAllAnimGui"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 110, 0, 36)
frame.Position = UDim2.new(0, 10, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
btn.Text = "⟳ REJOIN"; btn.BorderSizePixel = 0; btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseButton1Click:Connect(function()
    btn.Text = "..."
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

lg("DBG", "dbg_all_anim LOADED — tiap anim state baru ke-log sekali")
