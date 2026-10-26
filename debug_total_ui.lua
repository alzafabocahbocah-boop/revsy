-- debug_total_ui.lua
-- Cek apakah total pet bisa dibaca dari UI backpack tanpa hitung satu-satu
local player = game:GetService("Players").LocalPlayer

print("=== Cari label total pet di UI ===")
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then print("PlayerGui nil"); return end

-- scan semua TextLabel/TextButton yang ada angka X/Y
local found = {}
for _, d in ipairs(pg:GetDescendants()) do
    if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
        local a, b = d.Text:match("(%d+)%s*/%s*(%d+)")
        if a and b then
            found[#found+1] = {
                path = d:GetFullName():sub(-60),
                text = d.Text,
                a = tonumber(a),
                b = tonumber(b)
            }
        end
    end
end

print("Total label X/Y ditemukan:", #found)
for _, f in ipairs(found) do
    print(string.format("  [%s] = %q", f.path, f.text))
end

-- khusus cari yang ada kata "pet" atau "hewan"
print("")
print("=== Yang mengandung 'pet' atau 'hewan' ===")
for _, d in ipairs(pg:GetDescendants()) do
    if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
        local low = d.Text:lower()
        if (low:find("pet") or low:find("hewan")) then
            print(string.format("  [%s] = %q", d:GetFullName():sub(-60), d.Text))
        end
    end
end

-- cek CategoryTemplate khusus
print("")
print("=== CategoryTemplate ===")
local bg = pg:FindFirstChild("BackpackGui")
if bg then
    local ct = bg:FindFirstChild("Backpack") and bg.Backpack:FindFirstChild("Inventory")
        and bg.Backpack.Inventory:FindFirstChild("CategoryTemplate")
    if ct then
        print("  CategoryTemplate.Text =", ct.Text)
    else
        print("  CategoryTemplate belum ada (inventory belum dibuka)")
    end
else
    print("  BackpackGui belum ada")
end
