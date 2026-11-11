-- debug_rc2.lua — RC container dengan path yang benar
local plr = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")

local rcPets = {}

local ok, err = pcall(function()
    local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
    if not mod then print("[RC2] Module tidak ditemukan!"); return end
    local RC = require(mod)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(plr.Name)

    local tbl     = rawget(data, "Table")
    local ppd     = rawget(tbl,  "PlayerPetData")
    local pd      = rawget(ppd,  plr.Name)
    local inv     = rawget(pd,   "PetInventory")
    local invData = rawget(inv,  "Data")

    print("[RC2] PetInventory.Data type =", type(invData))
    if type(invData) ~= "table" then print("[RC2] invData bukan table!"); return end

    local count = 0
    for uuid, entry in pairs(invData) do
        count = count + 1
        if type(entry) == "table" then
            local info = {}
            info.uuid    = tostring(uuid)
            info.petType = tostring(entry.PetType or "NIL")

            local eKeys = {}
            for k in pairs(entry) do eKeys[#eKeys+1] = k end
            table.sort(eKeys)
            info.entryKeys = table.concat(eKeys, ", ")

            if type(entry.PetData) == "table" then
                local pdPairs = {}
                local pdKeys  = {}
                for k in pairs(entry.PetData) do pdKeys[#pdKeys+1] = k end
                table.sort(pdKeys)
                for _, k in ipairs(pdKeys) do
                    pdPairs[#pdPairs+1] = k.."="..tostring(entry.PetData[k])
                end
                info.petDataStr = table.concat(pdPairs, " | ")
            else
                info.petDataStr = "PetData=NIL"
            end

            rcPets[tostring(uuid)] = info
        end
    end
    print("[RC2] Total pet di RC =", count)
end)
if not ok then print("[RC2] ERROR:", err) end

print("")
print("===== SAMPLE RC ENTRY (5 pertama) =====")
local shown = 0
for uuid, info in pairs(rcPets) do
    shown = shown + 1
    if shown > 5 then break end
    print("PetType   : "..info.petType)
    print("Entry keys: "..info.entryKeys)
    print("PetData   : "..info.petDataStr)
    print("")
end

print("===== GIGANTIC/MEGA/TRANSCENDENT =====")
local tools = {}
local bp   = plr:FindFirstChild("Backpack")
local char = plr.Character
if bp   then for _,t in ipairs(bp:GetChildren())   do if t:IsA("Tool") then tools[#tools+1]=t end end end
if char then for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") then tools[#tools+1]=t end end end

local sizeFound = 0
for _, t in ipairs(tools) do
    local dn = t.Name:lower()
    if dn:find("gigantic") or dn:find("mega") or dn:find("transcendent") then
        sizeFound = sizeFound + 1
        local rawUUID = tostring(t:GetAttribute("PET_UUID") or t:GetAttribute("uuid") or "")
        local uPlain  = rawUUID:gsub("[{}]","")
        local uBrace  = "{"..uPlain.."}"
        local rcInfo  = rcPets[uPlain] or rcPets[uBrace] or rcPets[rawUUID]

        local attrs = {}
        local ok2, list = pcall(function() return t:GetAttributes() end)
        if ok2 and list then
            local ks = {}
            for k in pairs(list) do ks[#ks+1]=k end
            table.sort(ks)
            for _,k in ipairs(ks) do attrs[#attrs+1]=k.."="..tostring(list[k]) end
        end

        print("[SIZE] "..t.Name)
        print("       Tool attrs : "..table.concat(attrs, " | "))
        if rcInfo then
            print("       RC PetType : "..rcInfo.petType)
            print("       RC keys    : "..rcInfo.entryKeys)
            print("       RC PetData : "..rcInfo.petDataStr)
        else
            print("       RC         : UUID tidak match | rawUUID="..rawUUID:sub(1,30))
        end
        print("")
    end
end
print("[SIZE] Total:", sizeFound)
print("===== SELESAI =====")
