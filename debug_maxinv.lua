-- DEBUG maxInv — paste di executor, lihat output console
local player = game:GetService("Players").LocalPlayer

print("=== DEBUG maxInv ===")

-- 1. GetAttribute
local a1 = player:GetAttribute("MaxPets")
local a2 = player:GetAttribute("MaxPetsInInventory")
print("[ATTR] MaxPets=" .. tostring(a1) .. " MaxPetsInInventory=" .. tostring(a2))

-- 2. HactTelurGetMaxPets
if _G.HactTelurGetMaxPets then
    local ok, d = pcall(_G.HactTelurGetMaxPets)
    print("[HACT] ok=" .. tostring(ok) .. " val=" .. tostring(d))
else
    print("[HACT] tidak ada")
end

-- 3. Scan UI "Pet Items"
local found3 = nil
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then print("[UI] PlayerGui nil"); return end
    local tradeUI = pg:FindFirstChild("TradingUI")
    for _, d in ipairs(pg:GetDescendants()) do
        if tradeUI and d:IsDescendantOf(tradeUI) then continue end
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
            local low = d.Text:lower()
            if low:find("pet") and low:find("item") then
                local a, b = d.Text:match("(%d+)%s*/%s*(%d+)")
                print("[UI] ketemu label: '" .. d.Text .. "' path=" .. d:GetFullName())
                if a and b then found3 = tonumber(b) end
            end
        end
    end
end)
print("[UI] maxInv=" .. tostring(found3))

-- 4. getgc scan MutableStats langsung (semua yang punya MaxPetsInInventory)
if not getgc then print("[GC] getgc tidak ada"); return end
print("[GC] scan semua MutableStats...")
local results = {}
pcall(function()
    for _, obj in pairs(getgc(false)) do
        if type(obj) == "table" then
            local mp = rawget(obj, "MaxPetsInInventory")
            local me = rawget(obj, "MaxEggsInFarm")
            local mq = rawget(obj, "MaxEquippedPets")
            if type(mp) == "number" and type(me) == "number" and type(mq) == "number" then
                results[#results+1] = {mp=mp, me=me, mq=mq}
            end
        end
    end
end)
print("[GC] ketemu " .. #results .. " MutableStats:")
for i, r in ipairs(results) do
    print(string.format("  [%d] MaxPets=%d MaxEggs=%d MaxEquip=%d", i, r.mp, r.me, r.mq))
end

-- 5. _kgMutableStats (kalau up6kg jalan)
if _G.ZenxKgStat then
    print("[STAT] ZenxKgStat.maxInv=" .. tostring(_G.ZenxKgStat.maxInv)
        .. " totalAll=" .. tostring(_G.ZenxKgStat.totalAll))
    print("[CACHE] __ZenxMaxPetCache=" .. tostring(_G.__ZenxMaxPetCache)
        .. " src=" .. tostring(_G.__ZenxMaxPetSrc))
else
    print("[STAT] up6kg belum jalan")
end

print("=== SELESAI ===")
