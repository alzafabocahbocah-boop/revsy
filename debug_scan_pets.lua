-- debug_scan_pets.lua
-- Scan SEMUA pet via RC (ActivePetsService_Replicator) — sama persis cara up3.8kg
-- Jalankan di executor. Butuh up3.8kg TIDAK perlu jalan dulu (RC langsung).

local MUTATION_PREFIXES = {
    "Everchanted ","Frozen ","Inverted ","Golden ","Diamond ",
    "Mythical ","Hexed ","Ascended ","Radiant ","Shocked ","Bloodlit ",
    "Twilight ","Voidtouched ","Foxfire ","Aurora ","Static ","Stormcloud ",
    "Frost ","Burnt ","Lethal ","Cooked ","Choc ",
}
local function stripMutation(s)
    if not s then return "" end
    for _, p in ipairs(MUTATION_PREFIXES) do
        if s:sub(1, #p) == p then return s:sub(#p + 1) end
    end
    return s
end

local player = game:GetService("Players").LocalPlayer

-- ── Ambil RC container (sama persis up3.8kg findMemoryContainer) ──────────────
local function getRC()
    local result = nil
    local ok, err = pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local RC = require(RS.Modules.ReplicationClass)
        local inst = RC.new("ActivePetsService_Replicator")
        local data = inst:GetData(player.Name)
        local dat = data.Table.PlayerPetData[player.Name].PetInventory.Data
        local out = {}
        for uuid, entry in pairs(dat) do
            if type(entry) == "table" then
                out[tostring(uuid)] = entry
            end
        end
        if next(out) then result = out end
    end)
    if not ok then print("[debug] RC ERROR: "..tostring(err)) end
    return result
end

-- ── Main scan ─────────────────────────────────────────────────────────────────
print("=== DEBUG SCAN ALL PETS (RC) ===")
print("player: "..player.Name)

local c = getRC()
if not c then
    print("[!] RC container nil — coba jalankan lagi setelah game load penuh")
    return
end

-- Hitung & kumpulkan
local pets = {}
for uuid, e in pairs(c) do
    if type(e) == "table" then
        local rawType = tostring(e.PetType or (e.PetData and e.PetData.PetType) or "?")
        local tipe = stripMutation(rawType)
        local pd = e.PetData or {}
        local lv = tonumber(pd.Level) or 0
        local bw = tonumber(pd.BaseWeight) or 0
        local kg = bw * (lv + 10) / 10
        pets[#pets+1] = {
            uuid = tostring(uuid):sub(1,10),
            tipe = tipe,
            rawType = rawType,
            lv = lv,
            bw = bw,
            kg = kg,
        }
    end
end

-- Sort by tipe
table.sort(pets, function(a,b)
    if a.tipe == b.tipe then return a.lv > b.lv end
    return a.tipe < b.tipe
end)

-- Print semua pet (max 200)
print(string.format("\n%-42s | %-4s | %-7s | %-7s", "PetType (stripped)", "Lv", "BaseWt", "KG now"))
print(string.rep("-", 70))
for i, p in ipairs(pets) do
    if i > 200 then print("... (+"..( #pets-200).." lagi)"); break end
    print(string.format("%-42s | %-4d | %-7.1f | %-7.1f", p.tipe:sub(1,42), p.lv, p.bw, p.kg))
end

-- Summary per tipe
print("\n=== SUMMARY PER TIPE ===")
local counts = {}
for _, p in ipairs(pets) do
    counts[p.tipe] = (counts[p.tipe] or 0) + 1
end
local sorted = {}
for tipe, cnt in pairs(counts) do sorted[#sorted+1] = {tipe=tipe, cnt=cnt} end
table.sort(sorted, function(a,b)
    if a.cnt == b.cnt then return a.tipe < b.tipe end
    return a.cnt > b.cnt
end)
for _, v in ipairs(sorted) do
    -- tandai kalau ada whale
    local mark = v.tipe:lower():find("whale",1,true) and " <-- WHALE" or ""
    print(string.format("  %-42s x%d%s", v.tipe:sub(1,42), v.cnt, mark))
end

print("\nTotal: "..#pets.." pets")
print("=== SELESAI ===")
