-- debug_all_pet.lua — print semua atribut pet di backpack + character
local plr = game:GetService("Players").LocalPlayer

local function printPet(t)
    local attrs = {}
    local ok, list = pcall(function() return t:GetAttributes() end)
    if ok and list then
        for k, v in pairs(list) do
            attrs[#attrs+1] = k.."="..tostring(v)
        end
        table.sort(attrs)
    end
    print(string.format("  [%s] %s", t.Name, table.concat(attrs, " | ")))
end

local scan = {}
local bp = plr:FindFirstChild("Backpack")
local char = plr.Character
if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then scan[#scan+1]=t end end end
if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then scan[#scan+1]=t end end end

print("===== ALL PET ("..#scan..") =====")
for _, t in ipairs(scan) do
    printPet(t)
end
print("================================")
