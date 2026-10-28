-- debug_pet_inside2.lua — baca nama pet dari PetModelLocation + monitor perubahannya

local machine = game.Workspace.NPCS.PetMutationMachine
local pml = machine.PetModelLocation

-- ── baca nama pet sekarang ──
local function getCurrentPet()
    for _, child in ipairs(pml:GetChildren()) do
        if child:IsA("Model") then
            return child.Name  -- nama model = nama pet
        end
    end
    return nil
end

print("=== Pet di dalam mesin sekarang ===")
local petNow = getCurrentPet()
print("  Pet: " .. tostring(petNow))

-- ── cek attribute/value di model pet ──
print("\n=== Detail model pet ===")
for _, child in ipairs(pml:GetChildren()) do
    print(string.format("[%s] %s", child.ClassName, child.Name))
    local attrs = child:GetAttributes()
    for k, v in pairs(attrs) do
        print(string.format("  ATTR: %s = %s (%s)", k, tostring(v), typeof(v)))
    end
    -- scan descendants juga
    for _, desc in ipairs(child:GetDescendants()) do
        local a2 = desc:GetAttributes()
        if next(a2) then
            print(string.format("  [%s] %s:", desc.ClassName, desc.Name))
            for k, v in pairs(a2) do
                print(string.format("    %s = %s (%s)", k, tostring(v), typeof(v)))
            end
        end
    end
end

-- ── monitor kalau pet berubah (submit baru / claim) ──
print("\n=== Monitor perubahan pet di mesin ===")
pml.ChildAdded:Connect(function(child)
    print("[PET MASUK] " .. child.Name .. " (" .. child.ClassName .. ")")
end)
pml.ChildRemoved:Connect(function(child)
    print("[PET KELUAR] " .. child.Name .. " (" .. child.ClassName .. ")")
end)

print("Monitoring aktif. Submit/claim pet dan lihat output...")
print("(Bisa juga langsung pakai getCurrentPet() di auto_mutasi untuk log nama pet)")
