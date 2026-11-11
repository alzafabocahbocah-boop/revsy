-- debug_muttype_game.lua — cari semua MutationType dari config/module game
-- Scan: ReplicatedStorage.Modules, ReplicatedStorage.Assets, dll
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")

-- ===== 1. Cari module yang namanya mengandung kata kunci mutation/pet/config =====
print("===== SCAN MODULES DI RS =====")
local function scanFolder(folder, depth)
    if depth > 3 then return end
    local ok, children = pcall(function() return folder:GetChildren() end)
    if not ok then return end
    for _, obj in ipairs(children) do
        local n = obj.Name:lower()
        if n:find("mut") or n:find("pet") or n:find("config") or n:find("data") or n:find("type") then
            print(string.rep("  ", depth).."["..obj.ClassName.."] "..obj.Name)
        end
        if obj.ClassName == "Folder" or obj.ClassName == "ModuleScript" then
            -- jangan require dulu, cuma list
        end
        scanFolder(obj, depth+1)
    end
end
scanFolder(RS, 0)

-- ===== 2. Coba require modul yang relevan dan dump isinya =====
print("")
print("===== COBA REQUIRE MODULE MUTATION/PET =====")

local candidates = {
    -- path umum di game pet simulator
    {"Modules", "PetMutationData"},
    {"Modules", "MutationData"},
    {"Modules", "PetData"},
    {"Modules", "PetConfig"},
    {"Modules", "GameConfig"},
    {"Modules", "Mutations"},
    {"Modules", "MutationTypes"},
    {"Modules", "PetMutations"},
    {"Shared", "PetMutationData"},
    {"Shared", "MutationData"},
    {"Assets", "PetData"},
    {"Assets", "MutationData"},
}

local function dumpTable(t, depth, maxDepth)
    if depth > maxDepth then print(string.rep("  ",depth).."..."); return end
    if type(t) ~= "table" then print(string.rep("  ",depth)..tostring(t)); return end
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.rep("  ",depth)..tostring(k).." = {")
            dumpTable(v, depth+1, maxDepth)
            print(string.rep("  ",depth).."}")
        else
            print(string.rep("  ",depth)..tostring(k).." = "..tostring(v))
        end
    end
end

for _, path in ipairs(candidates) do
    local parent = RS
    for i = 1, #path-1 do
        parent = parent:FindFirstChild(path[i])
        if not parent then break end
    end
    if parent then
        local mod = parent:FindFirstChild(path[#path])
        if mod and mod:IsA("ModuleScript") then
            print("[FOUND] "..table.concat(path, "/"))
            local ok2, result = pcall(require, mod)
            if ok2 and type(result) == "table" then
                dumpTable(result, 1, 2)
            else
                print("  require failed:", tostring(result))
            end
        end
    end
end

-- ===== 3. Brute force: require semua ModuleScript di RS.Modules dan cari key "Mutation" =====
print("")
print("===== BRUTE FORCE SCAN RS.Modules =====")
local modsFolder = RS:FindFirstChild("Modules")
if modsFolder then
    for _, mod in ipairs(modsFolder:GetChildren()) do
        if mod:IsA("ModuleScript") then
            local ok3, result = pcall(require, mod)
            if ok3 and type(result) == "table" then
                -- cek apakah ada key mengandung "Mut" atau "Size" atau "Gigantic"
                for k, v in pairs(result) do
                    local ks = tostring(k):lower()
                    if ks:find("mut") or ks:find("size") or ks:find("gigantic") or ks:find("mega") or ks:find("transcend") then
                        print("[MOD] "..mod.Name.." -> key="..tostring(k).." val="..tostring(v):sub(1,80))
                    end
                end
            end
        end
    end
end

print("===== SELESAI =====")
