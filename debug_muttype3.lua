-- debug_muttype3.lua — require MutationType, StrictMutationType, PetMutationType dari RS.Types
local RS = game:GetService("ReplicatedStorage")

local function dumpTable(t, depth)
    depth = depth or 0
    if depth > 4 then return end
    if type(t) ~= "table" then return end
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

local function tryPath(...)
    local args = {...}
    local name = args[#args]
    local node = RS
    for i = 1, #args-1 do
        node = node:FindFirstChild(args[i])
        if not node then print("[SKIP] path tidak ditemukan di: "..args[i]); return end
    end
    local mod = node:FindFirstChild(name)
    if not mod then print("[SKIP] "..name.." tidak ditemukan"); return end
    local ok, result = pcall(require, mod)
    if not ok then print("[ERR] "..name..": "..tostring(result)); return end
    print("\n===== "..table.concat(args, "/").." =====")
    if type(result) == "table" then
        dumpTable(result, 0)
    else
        print(tostring(result))
    end
end

-- RS.Types folder
local typesFolder = RS:FindFirstChild("Types")
if typesFolder then
    print("[INFO] RS.Types children:")
    for _, c in ipairs(typesFolder:GetChildren()) do
        print("  "..c.ClassName.." "..c.Name)
    end
end

-- require semua yang ada di RS.Types
print("\n===== REQUIRE SEMUA RS.Types =====")
if typesFolder then
    for _, mod in ipairs(typesFolder:GetChildren()) do
        if mod:IsA("ModuleScript") then
            local ok, result = pcall(require, mod)
            if ok and type(result) == "table" then
                -- cek apakah ada key Mega/Transcend/size
                local hasMega = false
                for k, v in pairs(result) do
                    local ks = tostring(k):lower()
                    local vs = tostring(v):lower()
                    if ks:find("mega") or ks:find("transcend") or ks:find("giant")
                        or vs:find("mega") or vs:find("transcend") or vs:find("giant") then
                        hasMega = true
                    end
                end
                if hasMega then
                    print("\n[FOUND SIZE TIER] "..mod.Name)
                    dumpTable(result, 1)
                else
                    -- print semua isi tapi ringkas
                    local keys = {}
                    for k in pairs(result) do keys[#keys+1] = tostring(k) end
                    table.sort(keys)
                    print("[Types/"..mod.Name.."] keys: "..table.concat(keys, ", "))
                end
            elseif ok then
                print("[Types/"..mod.Name.."] = "..tostring(result))
            end
        end
    end
end

-- Coba juga StrictVariantType yang ada di list
print("\n===== StrictVariantType =====")
tryPath("Types", "StrictVariantType")

print("\n===== StrictMutationType =====")
tryPath("Types", "StrictMutationType")

print("\n===== MutationType =====")
tryPath("Types", "MutationType")

print("\n===== PetMutationType =====")
tryPath("Types", "PetMutationType")

-- Cek GGStaticData dan GGData (ada di DataModules, GG = Gigantic?)
print("\n===== GGStaticData =====")
-- cari di mana letaknya
local function findMod(root, name, depth)
    depth = depth or 0
    if depth > 5 then return nil end
    local found = root:FindFirstChild(name)
    if found then return found end
    local ok, children = pcall(function() return root:GetChildren() end)
    if not ok then return nil end
    for _, c in ipairs(children) do
        local r = findMod(c, name, depth+1)
        if r then return r end
    end
    return nil
end

local ggStatic = findMod(RS, "GGStaticData")
if ggStatic then
    print("[FOUND] GGStaticData di: "..ggStatic:GetFullName())
    local ok, result = pcall(require, ggStatic)
    if ok and type(result) == "table" then dumpTable(result, 0) end
end

local ggData = findMod(RS, "GGData")
if ggData then
    print("[FOUND] GGData di: "..ggData:GetFullName())
    local ok, result = pcall(require, ggData)
    if ok and type(result) == "table" then dumpTable(result, 0) end
end

print("\n===== SELESAI =====")
