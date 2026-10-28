-- debug_pet_inside.lua — cari info pet yang ada di dalam mesin mutasi
-- Jalankan saat ada pet di dalam mesin (sedang mutasi / SIAP)

local RS  = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer

-- ── 1. Scan PetModelLocation (tempat model pet ditampilkan di mesin) ──
print("=== PetModelLocation ===")
local ok, pml = pcall(function()
    return game.Workspace.NPCS.PetMutationMachine.PetModelLocation
end)
if ok and pml then
    for _, child in ipairs(pml:GetChildren()) do
        print(string.format("  [%s] %s", child.ClassName, child.Name))
        -- cek attribute
        local attrs = child:GetAttributes()
        for k, v in pairs(attrs) do
            print(string.format("    ATTR: %s = %s", k, tostring(v)))
        end
    end
else
    print("  PetModelLocation tidak ditemukan")
end

-- ── 2. Scan semua attribute di seluruh mesin ──
print("\n=== Semua Attribute di PetMutationMachine ===")
local ok2, machine = pcall(function()
    return game.Workspace.NPCS.PetMutationMachine
end)
if ok2 and machine then
    local function scanAttr(obj, indent)
        local attrs = obj:GetAttributes()
        if next(attrs) then
            print(indent .. "[" .. obj.ClassName .. "] " .. obj.Name)
            for k, v in pairs(attrs) do
                print(indent .. "  " .. k .. " = " .. tostring(v) .. " (" .. typeof(v) .. ")")
            end
        end
        for _, c in ipairs(obj:GetChildren()) do
            pcall(scanAttr, c, indent .. "  ")
        end
    end
    scanAttr(machine, "")
end

-- ── 3. Monitor OnClientEvent (server kirim update pet/state ke client) ──
print("\n=== Monitoring OnClientEvent (submit pet baru sekarang!) ===")
local RE = RS.GameEvents.PetMutationMachineService_RE
RE.OnClientEvent:Connect(function(...)
    local args = {...}
    print("[OnClientEvent] " .. #args .. " arg(s):")
    for i, v in ipairs(args) do
        local t = typeof(v)
        local s
        if t == "string" then s = '"'..v..'"'
        elseif t == "number" then s = tostring(v)
        elseif t == "boolean" then s = tostring(v)
        elseif t == "table" then
            local parts = {}
            for k, vv in pairs(v) do
                parts[#parts+1] = tostring(k).."="..tostring(vv)
            end
            s = "{"..table.concat(parts, ", ").."}"
        elseif t == "Instance" then
            local ok3, fn = pcall(function() return v:GetFullName() end)
            s = (ok3 and fn or tostring(v))
            -- kalau instance, print juga attributenya
            local a2 = v:GetAttributes()
            if next(a2) then
                s = s .. " {attrs:"
                for k, vv in pairs(a2) do s = s .. k.."="..tostring(vv).."," end
                s = s .. "}"
            end
        else s = tostring(v) end
        print(string.format("  arg[%d] (%s): %s", i, t, s))
    end
end)

-- ── 4. Cek InvokeServer (GetPetInfo / GetState) ──
print("\n=== Coba InvokeServer GetState / GetPetInfo ===")
local function tryInvoke(arg)
    local ok4, result = pcall(function()
        return RE:InvokeServer(arg)
    end)
    if ok4 then
        local t = typeof(result)
        print(string.format("  InvokeServer(%q) → %s: %s", arg, t, tostring(result)))
        if t == "table" then
            for k, v in pairs(result) do
                print(string.format("    [%s] = %s (%s)", tostring(k), tostring(v), typeof(v)))
            end
        end
    else
        print(string.format("  InvokeServer(%q) → ERROR: %s", arg, tostring(result)))
    end
end

-- coba beberapa nama yang umum
for _, arg in ipairs({"GetState", "GetPetInfo", "GetMachineState", "GetCurrentPet", "GetPet"}) do
    tryInvoke(arg)
    task.wait(0.2)
end

print("\n=== Monitoring aktif. Coba submit pet baru via auto_mutasi dan lihat output ===")
