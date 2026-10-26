-- debug_total_ui3.lua
-- Konfirmasi: CategoryTemplate "Pet Items (X/Y)" bisa dibaca tanpa buka backpack?
-- Dan apakah X = total pet di inventory (bukan termasuk garden)?
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then print("PlayerGui nil"); return end

local function getCategoryTemplate()
    local bg = pg:FindFirstChild("BackpackGui")
    if not bg then return nil, "BackpackGui nil" end
    local bp = bg:FindFirstChild("Backpack")
    if not bp then return nil, "Backpack nil" end
    local inv = bp:FindFirstChild("Inventory")
    if not inv then return nil, "Inventory nil" end
    local ct = inv:FindFirstChild("CategoryTemplate")
    if not ct then return nil, "CategoryTemplate nil" end
    return ct, nil
end

print("=== Test 1: baca sekarang (backpack TUTUP dulu sebelum jalanin ini) ===")
local ct, err = getCategoryTemplate()
if err then
    print("ERROR:", err)
else
    print("CategoryTemplate.Text =", ct.Text)
    local cur, mx = ct.Text:match("(%d+)/(%d+)")
    print("  current pets =", cur, "| max =", mx)
end

print("")
print("=== Test 2: parse helper ===")
local function getPetCount()
    local ct2, e = getCategoryTemplate()
    if e or not ct2 then return nil, nil, e end
    local txt = ct2.Text
    -- support "Pet Items (255/260)" atau "Pet Items 255/260"
    local cur, mx = txt:match("(%d+)%s*/%s*(%d+)")
    if not cur then return nil, nil, "no X/Y in: "..tostring(txt) end
    -- pastikan ini label pet (bukan All Items dll)
    if not txt:lower():find("pet") then
        return nil, nil, "bukan pet label: "..tostring(txt)
    end
    return tonumber(cur), tonumber(mx), nil
end

local cur, mx, e = getPetCount()
if e then
    print("getPetCount error:", e)
else
    print(string.format("getPetCount() => current=%d, max=%d", cur, mx))
end

print("")
print("=== Test 3: monitor perubahan 5 detik ===")
print("(kalau mau test, tambah/hapus pet sambil ini jalan)")
for i = 1, 5 do
    task.wait(1)
    local c, m, er = getPetCount()
    if er then
        print(string.format("  t=%ds ERROR: %s", i, er))
    else
        print(string.format("  t=%ds => current=%s, max=%s", i, tostring(c), tostring(m)))
    end
end

print("")
print("=== Test 4: bandingkan dengan RC direct ===")
pcall(function()
    local RS = game:GetService("ReplicatedStorage")
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    local ms = rawget(rawget(rawget(data,"Table"),"PlayerPetData")[player.Name],"MutableStats")
    local rcMax = rawget(ms, "MaxPetsInInventory")
    print("RC MaxPetsInInventory =", rcMax)
    local uiMax = select(2, getPetCount())
    print("UI max (dari CategoryTemplate) =", uiMax)
    if rcMax and uiMax then
        print("Match:", rcMax == uiMax and "YES sama!" or "NO beda! RC="..tostring(rcMax).." UI="..tostring(uiMax))
    end
end)
