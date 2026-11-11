-- debug_muttype4.lua — require langsung MutationType, StrictMutationType, GGData
local RS = game:GetService("ReplicatedStorage")

local function dumpTable(t, depth)
    depth = depth or 0
    if depth > 3 or type(t) ~= "table" then return end
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

local function reqAndDump(mod, label)
    if not mod then print("[SKIP] "..label.." tidak ditemukan"); return end
    local ok, r = pcall(require, mod)
    print("\n===== "..label.." =====")
    if ok then dumpTable(type(r)=="table" and r or {result=tostring(r)}, 0)
    else print("ERROR: "..tostring(r)) end
end

-- cari di seluruh RS secara recursive (batas depth)
local found = {}
local function findAll(node, name, depth)
    depth = depth or 0
    if depth > 6 then return end
    local c = node:FindFirstChild(name)
    if c then found[#found+1] = c end
    local ok, children = pcall(function() return node:GetChildren() end)
    if not ok then return end
    for _, child in ipairs(children) do
        if child.ClassName == "Folder" or child.ClassName == "ModuleScript" then
            findAll(child, name, depth+1)
        end
    end
end

local targets = {
    "MutationType", "PetMutationType", "StrictMutationType",
    "StrictVariantType", "GGStaticData", "GGData",
}

for _, name in ipairs(targets) do
    found = {}
    findAll(RS, name, 0)
    if #found == 0 then
        print("\n[NOT FOUND] "..name)
    else
        for _, mod in ipairs(found) do
            reqAndDump(mod, name.." ("..mod:GetFullName()..")")
        end
    end
end

print("\n===== SELESAI =====")
