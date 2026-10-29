-- debug: dump semua attribute + children PetMutationMachine
-- Jalanin 2x: pas mesin RUNNING dan pas mesin SIAP/READY
local machine = game.Workspace.NPCS.PetMutationMachine
print("=== PetMutationMachine DUMP ===")

-- Attributes
print("--- Attributes ---")
for k,v in pairs(machine:GetAttributes()) do
    print("  ATTR:", k, "=", tostring(v))
end

-- Children langsung
print("--- Children ---")
for _,c in ipairs(machine:GetChildren()) do
    print("  child:", c.ClassName, c.Name)
    -- attribute anak
    for k,v in pairs(c:GetAttributes()) do
        print("    ATTR:", k, "=", tostring(v))
    end
    -- children anak
    for _,cc in ipairs(c:GetChildren()) do
        print("    sub:", cc.ClassName, cc.Name)
        for k,v in pairs(cc:GetAttributes()) do
            print("      ATTR:", k, "=", tostring(v))
        end
    end
end

-- PetModelLocation isi
print("--- PetModelLocation ---")
local ok,pml=pcall(function() return machine.PetModelLocation end)
if ok and pml then
    for _,c in ipairs(pml:GetChildren()) do
        print("  pet model:", c.ClassName, c.Name)
    end
    print("  total children:", #pml:GetChildren())
else
    print("  PetModelLocation not found / error")
end

-- TimerTextLabel value
print("--- TimerTextLabel ---")
local function findTimer(parent, depth)
    if depth > 8 then return nil end
    for _,child in ipairs(parent:GetChildren()) do
        if child:IsA("TextLabel") and child.Name == "TimerTextLabel" then
            return child
        end
        local res = findTimer(child, depth+1)
        if res then return res end
    end
end
local timerLbl = findTimer(machine, 0)
if timerLbl then
    print("  TimerTextLabel.Text =", timerLbl.Text)
    print("  TimerTextLabel.Visible =", timerLbl.Visible)
    for k,v in pairs(timerLbl:GetAttributes()) do
        print("  ATTR:", k, "=", tostring(v))
    end
else
    print("  TimerTextLabel NOT FOUND")
end

-- Cari semua StringValue/IntValue/BoolValue/NumberValue
print("--- Value objects ---")
for _,d in ipairs(machine:GetDescendants()) do
    if d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("BoolValue") or d:IsA("NumberValue") or d:IsA("ObjectValue") then
        print("  ", d.ClassName, d:GetFullName():gsub("Workspace.NPCS.PetMutationMachine.",""), "=", tostring(d.Value))
    end
end

print("=== DONE ===")
