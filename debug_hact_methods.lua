-- debug_hact_methods.lua
-- Test semua 4 metode deteksi maxInv yang dipakai hact getGameData()
-- Jalankan ini untuk lihat mana yang works, mana yang gagal

local player = game:GetService("Players").LocalPlayer
local Results = {}

-- hitung cur total dulu (dipakai untuk validasi)
local _curTotal = 0
pcall(function()
    local seen = {}
    for _, holder in ipairs({player:FindFirstChild("Backpack"), player.Character}) do
        if holder then
            for _, tool in ipairs(holder:GetChildren()) do
                local uuid = tool:GetAttribute and tool:GetAttribute("PET_UUID")
                if uuid then
                    if not seen[uuid] then seen[uuid] = true; _curTotal = _curTotal + 1 end
                elseif tool:IsA and tool:IsA("Tool") then
                    _curTotal = _curTotal + 1
                end
            end
        end
    end
end)
print("=== curTotal =", _curTotal, "===")
print("")

-- ============ METODE 1: player Attribute ============
print("--- METODE 1: GetAttribute ---")
pcall(function()
    local mp = player:GetAttribute("MaxPets") or player:GetAttribute("MaxPetsInInventory")
    print("  MaxPets attr:", tostring(mp), "| type:", type(mp))
    Results[1] = mp and type(mp)=="number" and mp > 0 and mp or nil
end)
print("  HASIL:", tostring(Results[1]))
print("")

-- ============ METODE 2: UI scan (cara hact lama) ============
print("--- METODE 2: UI scan 'pet' + 'item' (hact style) ---")
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then print("  PlayerGui nil"); return end
    local tradeUI = pg:FindFirstChild("TradingUI")
    local found = 0
    for _, dd in ipairs(pg:GetDescendants()) do
        if tradeUI and dd:IsDescendantOf(tradeUI) then continue end
        if (dd:IsA("TextLabel") or dd:IsA("TextButton")) and type(dd.Text) == "string" then
            local low = dd.Text:lower()
            local hasPet = low:find("pet") ~= nil
            local hasItem = low:find("item") ~= nil
            if hasPet and hasItem then
                local a, b = dd.Text:match("(%d+)%s*/%s*(%d+)")
                if a and b then
                    a, b = tonumber(a), tonumber(b)
                    local delta = a and math.abs(a - _curTotal) or 9999
                    print(string.format("  FOUND text='%s' path=%s | a=%s b=%s delta=%s",
                        dd.Text, dd:GetFullName():sub(-40), tostring(a), tostring(b), tostring(delta)))
                    found = found + 1
                    -- hact: wajib delta <= 10
                    if a and b and b > 0 and delta <= 10 then
                        if not Results[2] then Results[2] = b end
                    end
                end
            end
        end
    end
    if found == 0 then print("  tidak ada label 'pet'+'item' ditemukan") end
end)
print("  HASIL:", tostring(Results[2]))
print("")

-- ============ METODE 2B: UI scan versi up6kg v10.251 (cari "pet" di Inventory) ============
print("--- METODE 2B: UI scan Inventory descendants cari 'pet' (up6kg v10.251) ---")
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then print("  PlayerGui nil"); return end
    local inv = pg:FindFirstChild("BackpackGui")
        and pg.BackpackGui:FindFirstChild("Backpack")
        and pg.BackpackGui.Backpack:FindFirstChild("Inventory")
    if not inv then print("  BackpackGui.Backpack.Inventory nil"); return end
    local found = 0
    for _, d in ipairs(inv:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
            local low = d.Text:lower()
            local hasPet2b = low:find("pet") ~= nil
            if hasPet2b then
                local a, b = d.Text:match("(%d+)%s*/%s*(%d+)")
                if a and b then
                    a, b = tonumber(a), tonumber(b)
                    print(string.format("  FOUND text='%s' path=%s | b=%s",
                        d.Text, d:GetFullName():sub(-50), tostring(b)))
                    found = found + 1
                    if b and b > 0 and not Results["2b"] then Results["2b"] = b end
                end
            end
        end
    end
    if found == 0 then print("  tidak ada label 'pet' di Inventory") end
end)
print("  HASIL:", tostring(Results["2b"]))
print("")

-- ============ METODE 3: MutableStats pointer (dari getgc, cara hact init) ============
print("--- METODE 3: scan getgc(true) cari MutableStats (3-field) dengan voting ---")
pcall(function()
    local votes = {}
    local objs = {}
    local count = 0
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" then
            local mp = rawget(obj, "MaxPetsInInventory")
            local me = rawget(obj, "MaxEggsInFarm")
            local mq = rawget(obj, "MaxEquippedPets")
            if type(mp)=="number" and mp>0 and mp<=2000
            and type(me)=="number" and me>0
            and type(mq)=="number" and mq>0 then
                count = count + 1
                votes[mp] = (votes[mp] or 0) + 1
                if not objs[mp] then objs[mp] = {mp=mp, me=me, mq=mq} end
            end
        end
    end
    print("  total MutableStats ditemukan:", count)
    print("  distribusi votes:")
    for mp, cnt in pairs(votes) do
        print(string.format("    mp=%d  count=%d  (%.0f%%)", mp, cnt, cnt/count*100))
    end
    -- pilih yang paling banyak
    local bestMp, bestCnt = nil, 0
    for mp, cnt in pairs(votes) do
        if cnt > bestCnt then bestMp = mp; bestCnt = cnt end
    end
    if bestMp then
        Results[3] = bestMp
        print("  WINNER mp=", bestMp, "count=", bestCnt)
    end
end)
print("  HASIL:", tostring(Results[3]))
print("")

-- ============ SUMMARY ============
print("========== SUMMARY ==========")
print("  1) Attribute:         ", tostring(Results[1]))
print("  2) UI scan hact-style:", tostring(Results[2]))
print("  2B) UI scan inv-style:", tostring(Results["2b"]))
print("  3) GC voting:         ", tostring(Results[3]))
print("")
print("curTotal =", _curTotal)
print("Expected maxInv = ?  (bandingkan sendiri)")
