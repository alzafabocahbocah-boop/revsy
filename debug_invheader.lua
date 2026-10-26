-- debug_invheader.lua
-- Jalankan waktu inventory pet terbuka (kelihatan "Barang Hewan Peliharaan (255/260)")
-- Cari path label yang benar
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then print("PlayerGui nil"); return end

print("=== Cari label yang mengandung angka max pet ===")
local tradeUI = pg:FindFirstChild("TradingUI")
local found = 0
local desc = pg:GetDescendants()
for i = 1, #desc do
    local d = desc[i]
    if tradeUI and d:IsDescendantOf(tradeUI) then continue end
    if d:IsA("TextLabel") or d:IsA("TextButton") then
        local txt = d.Text
        if type(txt) == "string" then
            local low = txt:lower()
            -- cari yang ada "hewan" atau "peliharaan" atau mengandung "/260" atau "/265" dll
            local hasHewan = string.find(low, "hewan") ~= nil
            local hasPeli  = string.find(low, "peliharaan") ~= nil
            local hasSlash = txt:match("%d+%s*/%s*2%d%d") ~= nil  -- X/2XX (range maxInv wajar)
            if hasHewan or hasPeli or hasSlash then
                found = found + 1
                print(string.format("  [%d] '%s'  path=...%s", found, txt:sub(1,40), d:GetFullName():sub(-55)))
            end
        end
    end
end
if found == 0 then print("  tidak ada — coba buka tab Pet Items dulu") end

print("")
print("=== Watch: label yang berubah ke format X/2XX ===")
print("(ganti-ganti tab inventory setelah ini)")
local watched = {}
local function attach(d)
    if watched[d] then return end
    if not (d:IsA("TextLabel") or d:IsA("TextButton")) then return end
    watched[d] = true
    local function check(txt)
        if type(txt) ~= "string" then return end
        if txt:match("%d+%s*/%s*2%d%d") then
            print("CHANGED -> '" .. txt:sub(1,40) .. "'  path=..." .. d:GetFullName():sub(-55))
        end
    end
    check(d.Text)
    d:GetPropertyChangedSignal("Text"):Connect(function() check(d.Text) end)
end
local desc2 = pg:GetDescendants()
for i = 1, #desc2 do pcall(function() attach(desc2[i]) end) end
pg.DescendantAdded:Connect(function(d) pcall(function() attach(d) end) end)
print("(watching...)")
