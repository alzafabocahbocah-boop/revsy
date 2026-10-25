-- scan BackpackGui untuk label kapasitas pet
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChild("PlayerGui")
local bg = pg and pg:FindFirstChild("BackpackGui")
print("BackpackGui:", bg and bg:GetFullName() or "nil")
if not bg then return end

-- dump semua descendants BackpackGui yang text-nya ada angka/angka
print("\n=== label X/Y di BackpackGui ===")
for _, d in ipairs(bg:GetDescendants()) do
    if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text)=="string" then
        local txt = d.Text
        if txt:match("%d") then
            print(string.format("  '%s' | %s", txt, d:GetFullName()))
        end
    end
end

-- dump semua children BackpackGui 1 level
print("\n=== BackpackGui children ===")
for _, child in ipairs(bg:GetChildren()) do
    print("  " .. child.Name .. " (" .. child.ClassName .. ")")
    for _, gc in ipairs(child:GetChildren()) do
        print("    " .. gc.Name .. " (" .. gc.ClassName .. ")")
    end
end
