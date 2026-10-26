-- debug_petitems_ui.lua
-- TEST: buka inventory dulu, klik tab "Pet Items", BARU jalankan script ini
-- Tujuan: cek apakah label "Pet Items (X/Y)" bisa dibaca dari PlayerGui

local player = game:GetService("Players").LocalPlayer

-- hitung curTotal dulu (sama persis cara hact)
local curTotal = 0
pcall(function()
    local seen = {}
    local holders = {player:FindFirstChild("Backpack"), player.Character}
    for i = 1, #holders do
        local h = holders[i]
        if h then
            local children = h:GetChildren()
            for j = 1, #children do
                local t = children[j]
                if t:IsA("Tool") then
                    local u = t:GetAttribute("PET_UUID")
                    if u then
                        local k = tostring(u):gsub("[{}]","")
                        if not seen[k] then seen[k] = true; curTotal = curTotal + 1 end
                    end
                end
            end
        end
    end
end)
print("curTotal =", curTotal)
print("")

-- scan semua label X/Y di PlayerGui
local pg = player:FindFirstChild("PlayerGui")
if not pg then print("PlayerGui nil"); return end

local tradeUI = pg:FindFirstChild("TradingUI")
local found = 0
local desc = pg:GetDescendants()

print("=== SEMUA label X/Y di PlayerGui ===")
for i = 1, #desc do
    local d = desc[i]
    -- skip TradingUI (milik lawan)
    if tradeUI and d:IsDescendantOf(tradeUI) then continue end
    if d:IsA("TextLabel") or d:IsA("TextButton") then
        local txt = d.Text
        if type(txt) == "string" then
            local a, b = txt:match("(%d+)%s*/%s*(%d+)")
            if a and b then
                found = found + 1
                local low = txt:lower()
                local hasPet = string.find(low, "pet") ~= nil
                local hasItem = string.find(low, "item") ~= nil
                local delta = math.abs(tonumber(a) - curTotal)
                print(string.format("  [%d] '%s'  pet=%s item=%s delta=%d  path=...%s",
                    found, txt:sub(1,35), tostring(hasPet), tostring(hasItem),
                    delta, d:GetFullName():sub(-45)))
            end
        end
    end
end

if found == 0 then
    print("  (tidak ada label X/Y — inventory belum terbuka?)")
end

print("")
print("=== FILTER: pet+item saja ===")
local result = nil
for i = 1, #desc do
    local d = desc[i]
    if tradeUI and d:IsDescendantOf(tradeUI) then continue end
    if d:IsA("TextLabel") or d:IsA("TextButton") then
        local txt = d.Text
        if type(txt) == "string" then
            local low = txt:lower()
            if string.find(low, "pet") ~= nil and string.find(low, "item") ~= nil then
                local a, b = txt:match("(%d+)%s*/%s*(%d+)")
                if a and b then
                    a = tonumber(a); b = tonumber(b)
                    local delta = math.abs(a - curTotal)
                    print(string.format("  MATCH '%s' a=%d b=%d delta=%d", txt:sub(1,35), a, b, delta))
                    if b > 0 and delta <= 10 and not result then
                        result = b
                    end
                end
            end
        end
    end
end

print("")
print("HASIL maxInv dari UI =", tostring(result))
