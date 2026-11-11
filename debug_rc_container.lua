-- debug_rc_container.lua
-- Dump semua data dari RC container (ActivePetsService_Replicator)
-- + bandingkan dengan Tool.Name di backpack
-- Tujuan: lihat semua field PetData yang tersedia (termasuk size tier jika ada)

local plr = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- ===== 1. BACA RC CONTAINER =====
print("===== RC CONTAINER DUMP =====")
local rcData = nil
local ok, err = pcall(function()
    local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
    if not mod then print("[RC] ReplicationClass module NOT FOUND"); return end
    local RC = require(mod)
    local inst = RC.new("ActivePetsService_Replicator")
    local dat = inst:GetData(plr.Name)
    if type(dat) ~= "table" then print("[RC] GetData bukan table, type=", type(dat)); return end
    rcData = dat
end)
if not ok then print("[RC] ERROR:", err) end

if not rcData then
    print("[RC] rcData nil — coba cara lain via rawget")
    pcall(function()
        local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
        if not mod then return end
        local RC = require(mod)
        local inst = RC.new("ActivePetsService_Replicator")
        local data = inst:GetData(plr.Name)
        -- coba rawget path
        local tbl = rawget(data, "Table")
        print("[RC] rawget Table =", type(tbl))
        if type(tbl) == "table" then
            local ppd = rawget(tbl, "PlayerPetData")
            print("[RC] rawget PlayerPetData =", type(ppd))
            if type(ppd) == "table" then
                local pd = rawget(ppd, plr.Name)
                print("[RC] rawget pd =", type(pd))
                rcData = pd
            end
        end
    end)
end

local petCount = 0
local rcPets = {}  -- {uuid -> {PetType, PetData keys, PetData values}}

if type(rcData) == "table" then
    for uuid, entry in pairs(rcData) do
        if type(entry) == "table" then
            petCount = petCount + 1
            local info = {uuid = tostring(uuid), petType = tostring(entry.PetType or "NIL")}

            -- kumpulkan semua key di entry (top level)
            local entryKeys = {}
            for k in pairs(entry) do entryKeys[#entryKeys+1] = k end
            table.sort(entryKeys)
            info.entryKeys = table.concat(entryKeys, ", ")

            -- kumpulkan semua field PetData
            if type(entry.PetData) == "table" then
                local pdKeys = {}
                local pdVals = {}
                for k, v in pairs(entry.PetData) do
                    pdKeys[#pdKeys+1] = k
                end
                table.sort(pdKeys)
                for _, k in ipairs(pdKeys) do
                    local v = entry.PetData[k]
                    pdVals[#pdVals+1] = k.."="..tostring(v)
                end
                info.petDataStr = table.concat(pdVals, " | ")
            else
                info.petDataStr = "PetData=NIL/bukan table"
            end

            rcPets[tostring(uuid)] = info
        end
    end
end

print("[RC] Total pet di container:", petCount)
print("")

-- Print SEMUA pet dari container (limit 30 dulu)
local shown = 0
for uuid, info in pairs(rcPets) do
    shown = shown + 1
    if shown > 30 then
        print("... (lebih dari 30, tampilkan 30 dulu)")
        break
    end
    -- format uuid pendek
    local uShort = uuid:sub(1,16).."..."
    print(string.format("[RC] %s", uShort))
    print(string.format("     PetType   : %s", info.petType))
    print(string.format("     Entry keys: %s", info.entryKeys))
    print(string.format("     PetData   : %s", info.petDataStr))
end

print("")
print("===== BACKPACK TOOL DUMP =====")

-- ===== 2. BACA TOOL DI BACKPACK + CHARACTER =====
local tools = {}
local bp = plr:FindFirstChild("Backpack")
local char = plr.Character
if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then tools[#tools+1] = t end end end
if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then tools[#tools+1] = t end end end

print("[BP] Total tool di backpack+char:", #tools)
print("")

-- Print sample 10 tool dengan atribut lengkap
local bpShown = 0
for _, t in ipairs(tools) do
    bpShown = bpShown + 1
    if bpShown > 10 then
        print("... (limit 10, bisa edit script untuk lebih)")
        break
    end

    -- kumpulkan semua atribut
    local attrs = {}
    local ok2, list = pcall(function() return t:GetAttributes() end)
    if ok2 and list then
        local keys = {}
        for k in pairs(list) do keys[#keys+1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            attrs[#attrs+1] = k.."="..tostring(list[k])
        end
    end

    -- cari di rcPets berdasarkan uuid
    local uuid = tostring(t:GetAttribute("PET_UUID") or t:GetAttribute("uuid") or "")
    local uFmt = uuid
    if uFmt ~= "" and uFmt:sub(1,1) ~= "{" then uFmt = "{"..uFmt.."}" end
    local rcInfo = rcPets[uuid] or rcPets[uFmt]

    print(string.format("[BP] Tool.Name = %s", t.Name))
    print(string.format("     uuid      = %s", uuid:sub(1,20)))
    print(string.format("     attrs     : %s", table.concat(attrs, " | ")))
    if rcInfo then
        print(string.format("     RC PetType: %s", rcInfo.petType))
        print(string.format("     RC PetData: %s", rcInfo.petDataStr))
    else
        print("     RC        : tidak ditemukan di container")
    end
    print("")
end

-- ===== 3. CEK GIGANTIC PET KHUSUS =====
print("===== GIGANTIC/MEGA/TRANSCENDENT PET =====")
local sizePets = {}
for _, t in ipairs(tools) do
    local dn = t.Name:lower()
    if dn:find("gigantic") or dn:find("mega") or dn:find("transcendent") then
        sizePets[#sizePets+1] = t
    end
end

print("[SIZE] Ditemukan", #sizePets, "pet size tier")
for _, t in ipairs(sizePets) do
    local uuid = tostring(t:GetAttribute("PET_UUID") or t:GetAttribute("uuid") or "")
    local uFmt = uuid
    if uFmt ~= "" and uFmt:sub(1,1) ~= "{" then uFmt = "{"..uFmt.."}" end
    local rcInfo = rcPets[uuid] or rcPets[uFmt]

    -- atribut
    local attrs = {}
    local ok3, list = pcall(function() return t:GetAttributes() end)
    if ok3 and list then
        local keys = {}
        for k in pairs(list) do keys[#keys+1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            attrs[#attrs+1] = k.."="..tostring(list[k])
        end
    end

    print(string.format("[SIZE] >> %s", t.Name))
    print(string.format("         uuid      = %s", uuid:sub(1,20)))
    print(string.format("         attrs     : %s", table.concat(attrs, " | ")))
    if rcInfo then
        print(string.format("         RC PetType: %s", rcInfo.petType))
        print(string.format("         RC keys   : %s", rcInfo.entryKeys))
        print(string.format("         RC PetData: %s", rcInfo.petDataStr))
    else
        print("         RC        : tidak ditemukan di container")
    end
    print("")
end

print("===== SELESAI =====")
