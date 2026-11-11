-- debug_muttype.lua — scan semua MutationType unik dari RC container
-- Tujuan: tahu kode GG/MG/TR/EV/dll + petanya ke size tier apa
local plr = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")

local mutCount = {}   -- MutationType -> count
local mutExample = {} -- MutationType -> {toolName, petType}

-- baca RC
local ok, err = pcall(function()
    local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
    if not mod then print("[MT] Module tidak ditemukan!"); return end
    local RC   = require(mod)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(plr.Name)
    local tbl     = rawget(data, "Table")
    local ppd     = rawget(tbl,  "PlayerPetData")
    local pd      = rawget(ppd,  plr.Name)
    local inv     = rawget(pd,   "PetInventory")
    local invData = rawget(inv,  "Data")
    if type(invData) ~= "table" then print("[MT] invData nil!"); return end

    -- bangun lookup uuid -> MutationType dari RC
    local rcByUUID = {}
    for uuid, entry in pairs(invData) do
        if type(entry) == "table" and type(entry.PetData) == "table" then
            local mt = tostring(entry.PetData.MutationType or "NIL")
            local pt = tostring(entry.PetType or "?")
            mutCount[mt]   = (mutCount[mt] or 0) + 1
            rcByUUID[tostring(uuid):gsub("[{}]","")] = {mt=mt, pt=pt}
        end
    end

    -- scan backpack + char untuk dapat Tool.Name per MutationType
    local tools = {}
    local bp   = plr:FindFirstChild("Backpack")
    local char = plr.Character
    if bp   then for _,t in ipairs(bp:GetChildren())   do if t:IsA("Tool") then tools[#tools+1]=t end end end
    if char then for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") then tools[#tools+1]=t end end end

    for _, t in ipairs(tools) do
        local rawUUID = tostring(t:GetAttribute("PET_UUID") or t:GetAttribute("uuid") or "")
        local uPlain  = rawUUID:gsub("[{}]","")
        local rcInfo  = rcByUUID[uPlain]
        if rcInfo then
            local mt = rcInfo.mt
            if not mutExample[mt] then
                mutExample[mt] = {toolName=t.Name, petType=rcInfo.pt}
            end
        end
    end
end)
if not ok then print("[MT] ERROR:", err) end

-- print hasil
print("===== MUTATION TYPE UNIK DI INVENTORY =====")
-- sort by count desc
local sorted = {}
for mt, cnt in pairs(mutCount) do sorted[#sorted+1] = {mt=mt, cnt=cnt} end
table.sort(sorted, function(a,b) return a.cnt > b.cnt end)

for _, row in ipairs(sorted) do
    local ex = mutExample[row.mt]
    local exStr = ex and string.format("  contoh: [%s] %s", ex.petType, ex.toolName) or ""
    print(string.format("  %-6s x%d%s", row.mt, row.cnt, exStr))
end
print("===========================================")
print("Total MutationType unik:", #sorted)
