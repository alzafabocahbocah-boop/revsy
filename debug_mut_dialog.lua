-- debug: scan PlayerGui cari dialog Submit Pet To Mutation Machine
local plr = game:GetService("Players").LocalPlayer
local pg = plr:FindFirstChild("PlayerGui")
if not pg then print("NO PLAYERGUI"); return end

print("=== SCAN PlayerGui ===")
for _,d in ipairs(pg:GetDescendants()) do
    if d:IsA("TextLabel") or d:IsA("TextButton") then
        local t = d.Text or ""
        if t ~= "" and #t < 80 then
            print(d.ClassName, d.Name, "|", t:sub(1,50), "| parent:", d.Parent and d.Parent.Name)
        end
    end
end
print("=== DONE ===")
