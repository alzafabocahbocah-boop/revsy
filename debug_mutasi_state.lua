-- debug_mutasi_state.lua — cari timer/state mesin mutasi
-- Tujuan: tau kapan mesin selesai biar bisa auto-loop

local RS  = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer

-- ── 1. Monitor OnClientEvent dari RE (server → client updates) ──
local RE = RS.GameEvents.PetMutationMachineService_RE

print("=== Monitoring PetMutationMachineService_RE OnClientEvent ===")
RE.OnClientEvent:Connect(function(...)
    local args = {...}
    local t = os.clock()
    print(string.format("[%.2f] OnClientEvent:", t))
    for i, v in ipairs(args) do
        local typ = typeof(v)
        local s
        if typ == "string" then s = '"'..v..'"'
        elseif typ == "number" then s = tostring(v)
        elseif typ == "table" then
            local parts = {}
            for k, vv in pairs(v) do
                parts[#parts+1] = tostring(k).."="..tostring(vv)
            end
            s = "{"..table.concat(parts, ", ").."}"
        elseif typ == "Instance" then
            local ok, fn = pcall(function() return v:GetFullName() end)
            s = ok and fn or tostring(v)
        else s = tostring(v) end
        print(string.format("  arg[%d] (%s): %s", i, typ, s))
    end
end)

-- ── 2. Cek attribute di model mesin mutasi ──
print("\n=== Attribute di PetMutationMachine ===")
local ok, machine = pcall(function()
    return game.Workspace.NPCS.PetMutationMachine
end)
if ok and machine then
    -- print semua attribute
    local attrs = machine:GetAttributes()
    for k, v in pairs(attrs) do
        print(string.format("  [ATTR] %s = %s (%s)", k, tostring(v), typeof(v)))
    end
    if not next(attrs) then print("  (tidak ada attribute di root machine)") end

    -- scan children untuk attribute
    for _, child in ipairs(machine:GetDescendants()) do
        local a = child:GetAttributes()
        if next(a) then
            print(string.format("  [%s] %s:", child.ClassName, child:GetFullName()))
            for k, v in pairs(a) do
                print(string.format("    %s = %s (%s)", k, tostring(v), typeof(v)))
            end
        end
    end

    -- ── 3. Monitor attribute changed (timer countdown) ──
    print("\n=== Monitor AttributeChanged di semua descendants ===")
    for _, child in ipairs(machine:GetDescendants()) do
        child.AttributeChanged:Connect(function(attr)
            local val = child:GetAttribute(attr)
            print(string.format("[ATTR_CHG] %s.%s = %s", child.Name, attr, tostring(val)))
        end)
    end
    machine.AttributeChanged:Connect(function(attr)
        local val = machine:GetAttribute(attr)
        print(string.format("[ATTR_CHG] Machine.%s = %s", attr, tostring(val)))
    end)
    print("  Monitoring AttributeChanged aktif...")
else
    warn("PetMutationMachine tidak ditemukan di Workspace.NPCS")
end

-- ── 4. Cek BillboardGui / SurfaceGui yang nampilin timer ──
print("\n=== GUI timer di mesin (BillboardGui/SurfaceGui) ===")
if ok and machine then
    for _, obj in ipairs(machine:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            print("  [GUI] " .. obj:GetFullName())
            for _, label in ipairs(obj:GetDescendants()) do
                if label:IsA("TextLabel") or label:IsA("TextButton") then
                    print(string.format("    %s.Text = %q", label.Name, label.Text))
                    -- monitor perubahan text (ini yang nampilin "59:49")
                    label:GetPropertyChangedSignal("Text"):Connect(function()
                        print(string.format("[TIMER] %s.Text = %q", label.Name, label.Text))
                    end)
                end
            end
        end
    end
end

print("\n=== Semua monitoring aktif. Tunggu update dari server... ===")
print("(Kalau mesin lagi running, harusnya langsung ada output ATTR_CHG atau TIMER)")
