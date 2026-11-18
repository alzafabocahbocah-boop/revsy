-- ============================================================
-- DEBUG GUI MENGAMBANG v1.0
-- Scan semua ScreenGui / BillboardGui / SurfaceGui di PlayerGui
-- Print nama, enabled, ResetOnSpawn, ZIndexBehavior, jumlah child
-- ============================================================
local plr = game.Players.LocalPlayer
local pg  = plr:WaitForChild("PlayerGui", 5)
if not pg then print("[GUI] PlayerGui gak ketemu"); return end

local function fmtSize(frame)
    local s = ""
    pcall(function()
        local sz = frame.Size
        s = string.format("%.0fx%.0f", sz.X.Offset, sz.Y.Offset)
    end)
    return s
end

local function scanGui(gui, indent)
    indent = indent or ""
    local nm   = tostring(gui.Name)
    local cls  = tostring(gui.ClassName)
    local en   = ""
    local vis  = ""
    local pos  = ""
    local sz   = ""
    local tx   = ""

    pcall(function() en  = " enabled="..tostring(gui.Enabled) end)
    pcall(function() vis = " vis="..tostring(gui.Visible) end)
    pcall(function()
        local p = gui.Position
        pos = string.format(" pos=(%.0f,%.0f)", p.X.Offset, p.Y.Offset)
    end)
    pcall(function()
        local s = gui.Size
        sz = string.format(" size=(%.0f,%.0f)", s.X.Offset, s.Y.Offset)
    end)
    pcall(function()
        local t = tostring(gui.Text)
        if #t > 0 and #t < 60 then tx = ' text="'..t..'"' end
    end)

    print(indent..nm.." ["..cls.."]"..en..vis..pos..sz..tx)
end

print("============ GUI MENGAMBANG ============")
print("Total ScreenGui di PlayerGui: ")

local guiList = {}
for _, g in ipairs(pg:GetChildren()) do
    table.insert(guiList, g)
end
print("  jumlah: "..#guiList)
print("")

for _, g in ipairs(guiList) do
    local nm  = tostring(g.Name)
    local cls = tostring(g.ClassName)
    local en  = true
    local ros = false
    local ndesc = 0
    pcall(function() en  = g.Enabled end)
    pcall(function() ros = g.ResetOnSpawn end)
    pcall(function() ndesc = #g:GetDescendants() end)

    local flag = en and "✅" or "❌"
    print(flag.." "..nm.." ["..cls.."] enabled="..tostring(en).." ResetOnSpawn="..tostring(ros).." descendants="..ndesc)

    -- kalau ScreenGui, scan child langsung (Frame/Label/etc mengambang)
    if g:IsA("ScreenGui") and en then
        for _, c in ipairs(g:GetChildren()) do
            local cnm = tostring(c.Name)
            local ccls = tostring(c.ClassName)
            local cvis = true
            local cpos = ""
            local csz  = ""
            local ctx  = ""
            pcall(function() cvis = c.Visible end)
            pcall(function()
                local p = c.Position
                cpos = string.format("pos=(%.0f%%+%.0f, %.0f%%+%.0f)",
                    p.X.Scale*100, p.X.Offset, p.Y.Scale*100, p.Y.Offset)
            end)
            pcall(function()
                local s = c.Size
                csz = string.format("size=(%.0f%%+%.0f, %.0f%%+%.0f)",
                    s.X.Scale*100, s.X.Offset, s.Y.Scale*100, s.Y.Offset)
            end)
            pcall(function()
                local t = tostring(c.Text)
                if #t > 0 and #t < 80 then ctx = ' text="'..t..'"' end
            end)
            local vflag = cvis and "  👁" or "  🔇"
            print(vflag.." "..cnm.." ["..ccls.."] "..cpos.." "..csz..ctx)
        end
    end
    print("")
end

-- BillboardGui di workspace
print("============ BILLBOARDGUI DI WORKSPACE ============")
local bbCount = 0
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") then
        bbCount = bbCount + 1
        local tx = ""; pcall(function()
            for _, c in ipairs(obj:GetDescendants()) do
                local t = ""; pcall(function() t = tostring(c.Text) end)
                if #t > 0 and #t < 60 then tx = tx..t.." | " end
            end
        end)
        print("  "..tostring(obj:GetFullName())..' text="'..tx..'"')
        if bbCount >= 20 then print("  ... (truncated)"); break end
    end
end
if bbCount == 0 then print("  (tidak ada)") end

print("============ SELESAI ============")
