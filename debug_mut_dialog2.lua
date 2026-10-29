-- debug v2: scan SEMUA ScreenGui + CoreGui cari dialog Cancel/Confirm mutasi
-- JALANIN SAAT DIALOG "Are you sure" MUNCUL
local plr = game:GetService("Players").LocalPlayer
local pg = plr:FindFirstChild("PlayerGui")

print("=== SCAN v2 — cari Cancel/Confirm ===")

-- scan PlayerGui
if pg then
    for _,d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("TextLabel") then
            local t = d.Text or ""
            if t ~= "" and #t < 60 then
                local tl = t:lower()
                if tl:find("cancel") or tl:find("confirm") or tl:find("batalkan") or
                   tl:find("sure") or tl:find("submit") or tl:find("mutation") or
                   tl:find("reset") or tl:find("age 1") then
                    print("PG", d.ClassName, d.Name, "|", t, "| parent:", d.Parent and d.Parent.Name, "| grandparent:", d.Parent and d.Parent.Parent and d.Parent.Parent.Name)
                end
            end
        end
    end
end

-- scan CoreGui (butuh pcall)
pcall(function()
    local cg = game:GetService("CoreGui")
    for _,d in ipairs(cg:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("TextLabel") then
            local t = d.Text or ""
            if t ~= "" and #t < 60 then
                local tl = t:lower()
                if tl:find("cancel") or tl:find("confirm") or tl:find("batalkan") or
                   tl:find("sure") or tl:find("submit") or tl:find("mutation") or
                   tl:find("reset") or tl:find("age 1") then
                    print("CG", d.ClassName, d.Name, "|", t, "| parent:", d.Parent and d.Parent.Name)
                end
            end
        end
    end
end)

print("=== DONE ===")
