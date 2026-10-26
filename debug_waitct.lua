-- debug_waitct.lua v2
-- Jalankan SEBELUM buka inventory
-- DescendantAdded nangkep CategoryTemplate waktu inventory dibuka
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then print("PlayerGui nil"); return end

local function onCT(ct)
    print("CategoryTemplate MUNCUL, Text =", ct.Text)
    ct:GetPropertyChangedSignal("Text"):Connect(function()
        print("Text changed ->", ct.Text)
    end)
end

-- cek kalau sudah ada
pcall(function()
    local bg = pg:FindFirstChild("BackpackGui")
    if not bg then return end
    local ct = bg:FindFirstChild("Backpack") and
               bg.Backpack:FindFirstChild("Inventory") and
               bg.Backpack.Inventory:FindFirstChild("CategoryTemplate")
    if ct then onCT(ct) end
end)

-- watch DescendantAdded di seluruh PlayerGui
pg.DescendantAdded:Connect(function(d)
    if d.Name == "CategoryTemplate" then
        pcall(function() onCT(d) end)
    end
end)

print("(watching... sekarang buka inventory + klik Pet Items)")
