-- debug_total_ui2.lua
-- Cek lebih dalam: cari label pet count di inventory backpack
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then print("PlayerGui nil"); return end

print("=== Scan BackpackGui lebih dalam ===")
local bg = pg:FindFirstChild("BackpackGui")
if not bg then
    print("BackpackGui tidak ada")
else
    print("BackpackGui ditemukan, scan children:")
    -- print semua descendants yang punya "Pet" atau ada angka X/Y
    for _, d in ipairs(bg:GetDescendants()) do
        local name = d.Name
        local nameLow = name:lower()
        -- cari yang namanya mengandung pet/category/count/total/header
        if nameLow:find("pet") or nameLow:find("categor") or nameLow:find("count")
            or nameLow:find("total") or nameLow:find("header") or nameLow:find("title") then
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                print(string.format("  [%s] name=%q text=%q", d.ClassName, d:GetFullName():sub(-70), d.Text))
            end
        end
        -- atau kalau punya text X/Y
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
            local a, b = d.Text:match("(%d+)%s*[/\\]%s*(%d+)")
            if a and b then
                print(string.format("  [X/Y] [%s] name=%q text=%q", d.ClassName, d:GetFullName():sub(-70), d.Text))
            end
        end
    end
end

print("")
print("=== Cari CategoryTemplate di seluruh PlayerGui ===")
-- mungkin CategoryTemplate ada di banyak tempat
for _, d in ipairs(pg:GetDescendants()) do
    if d.Name == "CategoryTemplate" then
        local txt = ""
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            txt = d.Text
        else
            -- mungkin Frame, cari TextLabel child
            for _, c in ipairs(d:GetDescendants()) do
                if (c:IsA("TextLabel") or c:IsA("TextButton")) and c.Text ~= "" then
                    txt = txt .. " | " .. c.Name .. "=" .. c.Text
                end
            end
        end
        print(string.format("  path=%q class=%s text=%q", d:GetFullName():sub(-80), d.ClassName, txt))
    end
end

print("")
print("=== Scan PlrInventory (inventory utama game) ===")
local inv = pg:FindFirstChild("PlrInventory")
if not inv then
    print("PlrInventory tidak ada")
else
    print("PlrInventory ada, scan children untuk pet/count label:")
    for _, d in ipairs(inv:GetDescendants()) do
        local nameLow = d.Name:lower()
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
            local txt = d.Text
            -- cari X/Y pattern
            local a, b = txt:match("(%d+)%s*[/\\]%s*(%d+)")
            if a and b then
                print(string.format("  [X/Y] %q = %q", d:GetFullName():sub(-70), txt))
            end
            -- cari yg ada kata pet
            if txt:lower():find("pet") then
                print(string.format("  [pet] %q = %q", d:GetFullName():sub(-70), txt))
            end
        end
    end
end

print("")
print("=== Cari tab Pets di inventory ===")
-- tab biasanya punya name "Pets" atau "Pet"
for _, d in ipairs(pg:GetDescendants()) do
    if d.Name == "Pets" or d.Name == "Pet" then
        print(string.format("  found: class=%s path=%q", d.ClassName, d:GetFullName():sub(-70)))
        -- kalau punya TextLabel child
        for _, c in ipairs(d:GetChildren()) do
            if c:IsA("TextLabel") or c:IsA("TextButton") then
                print(string.format("    child: %q = %q", c.Name, c.Text))
            end
        end
    end
end

print("")
print("=== CategoryTemplate detail (BackpackGui) ===")
if bg then
    -- cari semua CategoryTemplate di BackpackGui
    local invNode = bg:FindFirstChild("Backpack")
    if invNode then
        local invInner = invNode:FindFirstChild("Inventory")
        if invInner then
            print("Inventory children:")
            for _, c in ipairs(invInner:GetChildren()) do
                print(string.format("  %s (class=%s)", c.Name, c.ClassName))
                if c:IsA("TextLabel") or c:IsA("TextButton") then
                    print(string.format("    text=%q", c.Text))
                end
                -- cari CategoryTemplate di dalamnya
                for _, gc in ipairs(c:GetDescendants()) do
                    if gc.Name == "CategoryTemplate" then
                        local t = ""
                        if gc:IsA("TextLabel") or gc:IsA("TextButton") then t = gc.Text end
                        print(string.format("    CategoryTemplate: class=%s text=%q", gc.ClassName, t))
                    end
                end
            end
        else
            print("Inventory child tidak ada, children of Backpack:")
            for _, c in ipairs(invNode:GetChildren()) do
                print(string.format("  %s (class=%s)", c.Name, c.ClassName))
            end
        end
    else
        print("Backpack child tidak ada, BackpackGui children:")
        for _, c in ipairs(bg:GetChildren()) do
            print(string.format("  %s (class=%s)", c.Name, c.ClassName))
        end
    end
end
