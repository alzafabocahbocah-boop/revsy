-- debug_categorytemplate.lua
-- test baca langsung dari BackpackGui.Backpack.Inventory.CategoryTemplate
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then print("PlayerGui nil"); return end

-- cek path step by step
local bg = pg:FindFirstChild("BackpackGui")
print("BackpackGui:", tostring(bg))
if not bg then return end

local bp = bg:FindFirstChild("Backpack")
print("Backpack:", tostring(bp))
if not bp then return end

local inv = bp:FindFirstChild("Inventory")
print("Inventory:", tostring(inv))
if not inv then return end

local ct = inv:FindFirstChild("CategoryTemplate")
print("CategoryTemplate:", tostring(ct))
if not ct then
    -- print semua children Inventory
    print("Children of Inventory:")
    for _, c in ipairs(inv:GetChildren()) do
        print("  " .. c.Name .. " [" .. c.ClassName .. "]")
    end
    return
end

print("CategoryTemplate.Text:", tostring(ct.Text))

-- watch Text berubah
print("--- watching Text changes (ganti tab inventory) ---")
ct:GetPropertyChangedSignal("Text"):Connect(function()
    print("Text changed ->", tostring(ct.Text))
end)

-- juga print semua sibling CategoryTemplate (kadang ada beberapa)
print("Siblings di Inventory yang ada 'Category':")
for _, c in ipairs(inv:GetChildren()) do
    if c.Name:lower():find("category") then
        print("  " .. c.Name .. " Text=" .. tostring(c:IsA("TextLabel") and c.Text or "(bukan TextLabel)"))
    end
end
