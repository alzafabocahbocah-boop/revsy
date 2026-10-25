-- test UI scan "Pet Items (X/Y)" tanpa filter
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChild("PlayerGui")
if not pg then print("PlayerGui nil"); return end

local tradeUI = pg:FindFirstChild("TradingUI")
local found = false
for _, d in ipairs(pg:GetDescendants()) do
    if tradeUI and d:IsDescendantOf(tradeUI) then continue end
    if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
        local txt = d.Text
        -- cari format angka/angka
        if txt:match("%d+%s*/%s*%d+") then
            local a, b = txt:match("(%d+)%s*/%s*(%d+)")
            if a and b then
                print("label: '" .. txt .. "' -> " .. a .. "/" .. b
                    .. " path=" .. d:GetFullName())
                found = true
            end
        end
    end
end
if not found then print("tidak ada label X/Y") end
