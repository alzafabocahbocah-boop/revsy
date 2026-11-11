-- debug_muttype2.lua — require MutationType/MutationEnums/MutationHandler langsung
local RS = game:GetService("ReplicatedStorage")

local function dumpTable(t, depth)
    depth = depth or 0
    if depth > 3 then return end
    if type(t) ~= "table" then print(string.rep("  ",depth)..tostring(t)); return end
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.rep("  ",depth)..tostring(k).." = {")
            dumpTable(v, depth+1)
            print(string.rep("  ",depth).."}")
        else
            print(string.rep("  ",depth)..tostring(k).." = "..tostring(v))
        end
    end
end

local function tryRequire(parent, name)
    local mod = parent and parent:FindFirstChild(name)
    if not mod then print("[SKIP] "..name.." tidak ditemukan"); return nil end
    local ok, result = pcall(require, mod)
    if not ok then print("[ERR] "..name..": "..tostring(result)); return nil end
    print("\n===== "..name.." =====")
    dumpTable(result, 0)
    return result
end

-- folder lokasi
local Types  = RS:FindFirstChild("Types")   -- RS.Types folder
local Data   = RS:FindFirstChild("Data")    -- RS.Data folder
local Shared = RS:FindFirstChild("Shared")

-- 1. MutationType (di RS.Types)
tryRequire(Types, "MutationType")

-- 2. PetMutationType (di RS.Types)
tryRequire(Types, "PetMutationType")

-- 3. StrictMutationType (di RS.Types)
tryRequire(Types, "StrictMutationType")

-- 4. MutationEnums (di RS.Data)
tryRequire(Data, "MutationEnums")

-- 5. ReversedMutationEnums (di RS.Data)
tryRequire(Data, "ReversedMutationEnums")

-- 6. MutationHandler.MutationNames (di RS.Modules)
local Modules = RS:FindFirstChild("Modules")
local mhMod = Modules and Modules:FindFirstChild("MutationHandler")
if mhMod then
    local ok, mh = pcall(require, mhMod)
    if ok and type(mh) == "table" then
        print("\n===== MutationHandler.MutationNames =====")
        if type(mh.MutationNames) == "table" then
            dumpTable(mh.MutationNames, 0)
        else
            print("MutationNames = "..tostring(mh.MutationNames))
        end

        -- GetEnumsToMutations — map enum -> name
        print("\n===== GetEnumsToMutations() =====")
        if type(mh.GetEnumsToMutations) == "function" then
            local ok2, res = pcall(mh.GetEnumsToMutations)
            if ok2 and type(res) == "table" then dumpTable(res, 0)
            else print("ERROR:", tostring(res)) end
        end

        -- GetMutationsToEnums — map name -> enum
        print("\n===== GetMutationsToEnums() =====")
        if type(mh.GetMutationsToEnums) == "function" then
            local ok3, res = pcall(mh.GetMutationsToEnums)
            if ok3 and type(res) == "table" then dumpTable(res, 0)
            else print("ERROR:", tostring(res)) end
        end
    end
end

-- 7. PetMutationRegistry (di RS.Data.PetRegistry)
local PetRegistry = Data and Data:FindFirstChild("PetRegistry")
tryRequire(PetRegistry, "PetMutationRegistry")

print("\n===== SELESAI =====")
