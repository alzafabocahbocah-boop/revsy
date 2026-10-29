-- debug v3: dump SEMUA obj di dalam dialog muts (termasuk ClassName + path lengkap)
-- JALANIN SAAT DIALOG "Submit Pet To Mutation Machine" MUNCUL
local plr = game:GetService("Players").LocalPlayer
local pg = plr:FindFirstChild("PlayerGui")

print("=== DEBUG v3 — dump struktur dialog mutasi ===")

-- Fungsi bantu ambil path lengkap
local function getPath(obj)
    local path = {}
    local cur = obj
    local limit = 10
    while cur and cur ~= pg and limit > 0 do
        table.insert(path, 1, cur.Name .. "(" .. cur.ClassName .. ")")
        cur = cur.Parent
        limit = limit - 1
    end
    return table.concat(path, " > ")
end

if pg then
    -- Cari dulu ScreenGui yang mengandung "Submit" atau "Mutation"
    for _,sg in ipairs(pg:GetChildren()) do
        -- scan semua descendant
        for _,d in ipairs(sg:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("ImageButton") then
                local t = (d:IsA("TextLabel") or d:IsA("TextButton")) and (d.Text or "") or ""
                local tl = t:lower()
                -- filter: teks pendek yang relevan
                if tl:find("cancel") or tl:find("confirm") or tl:find("batalkan") or
                   tl:find("submit") or tl:find("mutation") or tl:find("sure") or
                   tl:find("age 1") or tl:find("kirim") or tl:find("mesin") then
                    print(d.ClassName, d.Name, "| text:", t, "| path:", getPath(d))
                end
            end
        end
    end

    -- Juga dump semua ScreenGui aktif yang visible
    print("--- ScreenGui aktif ---")
    for _,sg in ipairs(pg:GetChildren()) do
        if sg:IsA("ScreenGui") and sg.Enabled then
            print("ScreenGui:", sg.Name, "| children:", #sg:GetChildren())
        end
    end
else
    print("PlayerGui not found!")
end

-- Juga coba scan CoreGui
pcall(function()
    local cg = game:GetService("CoreGui")
    for _,d in ipairs(cg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local t = d.Text or ""
            local tl = t:lower()
            if tl:find("cancel") or tl:find("confirm") or tl:find("submit") or tl:find("mutation") then
                print("COREGUI", d.ClassName, d.Name, "| text:", t, "| parent:", d.Parent and d.Parent.Name)
            end
        end
    end
end)

print("=== DONE v3 ===")
