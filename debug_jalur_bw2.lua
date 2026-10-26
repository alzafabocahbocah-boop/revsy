-- debug_jalur_bw2.lua
-- Print SEMUA pet dari RC: uuid, PetType, BaseWeight, Level, MutationType
-- Sorted by Level desc biar gampang liat

local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local ok, err = pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)

    local tbl = rawget(data, "Table")
    local ppd = rawget(tbl, "PlayerPetData")
    local pd  = rawget(ppd, player.Name)
    local dat = rawget(rawget(pd, "PetInventory"), "Data")
    assert(type(dat) == "table", "Data nil")

    -- kumpulkan semua entry
    local list = {}
    for uuid, entry in pairs(dat) do
        if type(entry) == "table" then
            local petData = rawget(entry, "PetData") or {}
            list[#list+1] = {
                uuid      = tostring(uuid),
                petType   = tostring(rawget(entry, "PetType") or "?"),
                bw        = tonumber(rawget(petData, "BaseWeight")) or 0,
                level     = tonumber(rawget(petData, "Level")) or 0,
                mutation  = tostring(rawget(petData, "MutationType") or "-"),
            }
        end
    end

    -- sort by level desc
    table.sort(list, function(a,b) return a.level > b.level end)

    print(string.format("%-45s %-30s %10s %6s %s", "UUID", "PetType", "BaseWeight", "Level", "MutationType"))
    print(string.rep("-", 110))
    for _, e in ipairs(list) do
        print(string.format("%-45s %-30s %10.4f %6d %s",
            e.uuid, e.petType:sub(1,30), e.bw, e.level, e.mutation))
    end
    print("====== TOTAL:", #list, "======")
end)

if not ok then print("ERROR:", err) end
