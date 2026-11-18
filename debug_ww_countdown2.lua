-- DEBUG WHALE WATERS COUNTDOWN v3 — fokus cari countdown text
-- Jalankan saat event AKTIF (ada Clam di WS)
local plr = game.Players.LocalPlayer
local WS = workspace

-- 1. Dump SEMUA TextLabel di Summer2026Event
print("=== SUMMER2026EVENT TEXT ===")
local ev = plr.PlayerGui:FindFirstChild("Events")
if ev then
    local s26 = ev:FindFirstChild("Summer2026Event")
    if s26 then
        for _, d in ipairs(s26:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextBox") then
                local t=""; pcall(function() t=tostring(d.Text) end)
                if #t > 0 and #t < 100 then
                    -- filter yang ada angka / detik / menit
                    if t:match("%d") then
                        print("  "..tostring(d.Name).." vis="..tostring(d.Visible)..' text="'..t..'"')
                    end
                end
            end
        end
    else
        print("Summer2026Event tidak ada")
    end
end

-- 2. Dump TextLabel di WeatherVisuals / WeatherObjects / Water_Effect
print("\n=== WEATHERVISUALS / WEATHEROBJECTS TEXTS ===")
for _, nm in ipairs({"WeatherVisuals","WeatherObjects","Water_Effect"}) do
    local obj = WS:FindFirstChild(nm)
    if obj then
        print("["..nm.."]")
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("BillboardGui") then
                local t=""; pcall(function() t=tostring(d.Text) end)
                if #t > 0 then
                    print("  "..tostring(d:GetFullName())..' text="'..t..'"')
                end
            end
            -- atribut yang ada angka
            pcall(function()
                for k,v in pairs(d:GetAttributes()) do
                    local vs = tostring(v)
                    if vs:match("%d") then
                        print("  ATTR "..tostring(d.Name).."."..tostring(k).."="..vs)
                    end
                end
            end)
        end
    end
end

-- 3. Poll tiap 1s — scan SEMUA TextLabel di PlayerGui yang isinya berubah
--    dan formatnya kayak timer (ada ":" atau "second" atau "minute")
print("\n=== POLL TIMER (tiap 1s) ===")
local seen = {}
task.spawn(function()
    while true do
        task.wait(1)
        for _, gui in ipairs(plr.PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") then
                local ok,t = pcall(function() return tostring(gui.Text) end)
                if ok and #t > 0 and #t < 80 then
                    -- format timer: "2:27" atau "2 Minutes" atau "2m 27s"
                    if t:match("^%d+:%d+") or t:match("%d+ [Mm]inute") or t:match("%d+ [Ss]econd")
                       or t:match("%d+m %d+s") or t:match("ends") or t:match("Ends") then
                        local key = tostring(gui:GetFullName())
                        if seen[key] ~= t then
                            print("[TIMER @ "..os.date("%H:%M:%S").."] "..key..'="'..t..'"')
                            seen[key] = t
                        end
                    end
                end
            end
        end
    end
end)

print("Listener aktif. Output akan muncul kalau ada TextLabel timer yang berubah.")
