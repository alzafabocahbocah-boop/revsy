-- debug_hact_methods.lua (v2 - fixed syntax)
local player = game:GetService("Players").LocalPlayer
local Results = {}

local _curTotal = 0
pcall(function()
    local seen = {}
    local holders = {player:FindFirstChild("Backpack"), player.Character}
    for i = 1, #holders do
        local holder = holders[i]
        if holder then
            local children = holder:GetChildren()
            for j = 1, #children do
                local tool = children[j]
                local uuid = tool:GetAttribute("PET_UUID")
                if uuid then
                    if not seen[uuid] then seen[uuid] = true; _curTotal = _curTotal + 1 end
                elseif tool:IsA("Tool") then
                    _curTotal = _curTotal + 1
                end
            end
        end
    end
end)
print("=== curTotal =", _curTotal, "===")

-- METODE 1: GetAttribute
print("--- METODE 1: GetAttribute ---")
pcall(function()
    local mp = player:GetAttribute("MaxPets") or player:GetAttribute("MaxPetsInInventory")
    print("  attr:", tostring(mp), type(mp))
    if type(mp) == "number" and mp > 0 then Results[1] = mp end
end)
print("  HASIL:", tostring(Results[1]))

-- METODE 2: UI scan hact style (pet + item)
print("--- METODE 2: UI scan pet+item hact style ---")
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then print("  PlayerGui nil"); return end
    local tradeUI = pg:FindFirstChild("TradingUI")
    local found = 0
    local desc = pg:GetDescendants()
    for i = 1, #desc do
        local dd = desc[i]
        if tradeUI then
            if dd:IsDescendantOf(tradeUI) then continue end
        end
        if dd:IsA("TextLabel") or dd:IsA("TextButton") then
            local txt = dd.Text
            if type(txt) == "string" then
                local low = txt:lower()
                local hasPet = string.find(low, "pet") ~= nil
                local hasItem = string.find(low, "item") ~= nil
                if hasPet and hasItem then
                    local a, b = string.match(txt, "(%d+)%s*/%s*(%d+)")
                    if a and b then
                        a = tonumber(a); b = tonumber(b)
                        local delta = math.abs(a - _curTotal)
                        print("  FOUND '"..txt.."' a="..tostring(a).." b="..tostring(b).." delta="..tostring(delta))
                        found = found + 1
                        if b and b > 0 and delta <= 10 then
                            if not Results[2] then Results[2] = b end
                        end
                    end
                end
            end
        end
    end
    if found == 0 then print("  tidak ada") end
end)
print("  HASIL:", tostring(Results[2]))

-- METODE 2B: scan Inventory descendants cari pet
print("--- METODE 2B: Inventory scan cari pet ---")
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then print("  PlayerGui nil"); return end
    local bg = pg:FindFirstChild("BackpackGui")
    if not bg then print("  BackpackGui nil"); return end
    local bk = bg:FindFirstChild("Backpack")
    if not bk then print("  Backpack nil"); return end
    local inv = bk:FindFirstChild("Inventory")
    if not inv then print("  Inventory nil"); return end
    local found = 0
    local desc = inv:GetDescendants()
    for i = 1, #desc do
        local d = desc[i]
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local txt = d.Text
            if type(txt) == "string" then
                local low = txt:lower()
                if string.find(low, "pet") ~= nil then
                    local a, b = string.match(txt, "(%d+)%s*/%s*(%d+)")
                    if a and b then
                        b = tonumber(b)
                        print("  FOUND '"..txt.."' b="..tostring(b).." path="..d:GetFullName():sub(-40))
                        found = found + 1
                        if b and b > 0 and not Results["2b"] then Results["2b"] = b end
                    end
                end
            end
        end
    end
    if found == 0 then print("  tidak ada label pet di Inventory") end
end)
print("  HASIL:", tostring(Results["2b"]))

-- METODE 3: getgc voting
print("--- METODE 3: getgc(true) MutableStats voting ---")
pcall(function()
    local votes = {}
    local count = 0
    local gc = getgc(true)
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj) == "table" then
            local mp = rawget(obj, "MaxPetsInInventory")
            local me = rawget(obj, "MaxEggsInFarm")
            local mq = rawget(obj, "MaxEquippedPets")
            if type(mp)=="number" and mp>0 and mp<=2000
            and type(me)=="number" and me>0
            and type(mq)=="number" and mq>0 then
                count = count + 1
                votes[mp] = (votes[mp] or 0) + 1
            end
        end
    end
    print("  total MutableStats:", count)
    for mp, cnt in pairs(votes) do
        print("    mp="..tostring(mp).." count="..tostring(cnt))
    end
    local bestMp, bestCnt = nil, 0
    for mp, cnt in pairs(votes) do
        if cnt > bestCnt then bestMp = mp; bestCnt = cnt end
    end
    if bestMp then
        Results[3] = bestMp
        print("  WINNER mp="..tostring(bestMp).." count="..tostring(bestCnt))
    end
end)
print("  HASIL:", tostring(Results[3]))

print("========== SUMMARY ==========")
print("  1) Attribute:    "..tostring(Results[1]))
print("  2) UI hact:      "..tostring(Results[2]))
print("  2B) UI inv:      "..tostring(Results["2b"]))
print("  3) GC voting:    "..tostring(Results[3]))
print("  curTotal =", _curTotal)
