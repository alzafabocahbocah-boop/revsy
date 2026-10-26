-- debug_pet_count.lua
-- Cari total current pet count dari data (tanpa hitung satu-satu)
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")

print("=== Cari current pet count dari RC data ===")
pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    local inst = RC.new("ActivePetsService_Replicator")
    local data = inst:GetData(player.Name)
    if type(data) ~= "table" then print("data bukan table"); return end

    local tbl = rawget(data, "Table")
    if type(tbl) ~= "table" then print("Table nil"); return end

    -- lihat semua keys di tbl
    print("Keys di Table:")
    for k, v in pairs(tbl) do
        print(string.format("  %q => %s", tostring(k), type(v)))
    end

    local ppd = rawget(tbl, "PlayerPetData")
    if type(ppd) ~= "table" then print("PlayerPetData nil"); return end

    print("")
    print("Keys di PlayerPetData:")
    for k, v in pairs(ppd) do
        print(string.format("  %q => %s", tostring(k), type(v)))
    end

    local pd = rawget(ppd, player.Name)
    if type(pd) ~= "table" then print("pd nil"); return end

    print("")
    print("Keys di pd (PlayerData untuk akun ini):")
    for k, v in pairs(pd) do
        if type(v) == "table" then
            -- hitung size
            local sz = 0
            for _ in pairs(v) do sz = sz + 1 end
            print(string.format("  %q => table (size=%d)", tostring(k), sz))
        else
            print(string.format("  %q => %s = %s", tostring(k), type(v), tostring(v)))
        end
    end

    -- khusus lihat PetInventory atau Pets atau apapun yang mirip
    print("")
    print("=== Cek field yang mungkin berisi list pet ===")
    for k, v in pairs(pd) do
        if type(v) == "table" then
            local sz = 0
            for _ in pairs(v) do sz = sz + 1 end
            -- kalau size ~255 (total pet kita) kemungkinan ini
            if sz > 100 and sz < 1000 then
                print(string.format("  KANDIDAT: key=%q size=%d", tostring(k), sz))
                -- lihat sample key pertama
                local count = 0
                for sk, sv in pairs(v) do
                    if count < 3 then
                        if type(sv) == "table" then
                            local inner = {}
                            for ik in pairs(sv) do inner[#inner+1] = tostring(ik) end
                            print(string.format("    sample[%s] = table{%s}", tostring(sk), table.concat(inner, ",")))
                        else
                            print(string.format("    sample[%s] = %s", tostring(sk), tostring(sv)))
                        end
                        count = count + 1
                    end
                end
            end
        end
    end

    -- cek MutableStats untuk field count
    local ms = rawget(pd, "MutableStats")
    if type(ms) == "table" then
        print("")
        print("=== Semua field MutableStats ===")
        for k, v in pairs(ms) do
            print(string.format("  %q = %s", tostring(k), tostring(v)))
        end
    end
end)

print("")
print("=== Coba replicator lain (mungkin ada PetInventoryService) ===")
-- coba nama replicator lain yang mungkin punya pet count
local tryNames = {
    "PetInventoryService_Replicator",
    "PetService_Replicator",
    "InventoryService_Replicator",
    "PlayerDataService_Replicator",
    "PetData_Replicator",
}
pcall(function()
    local RC = require(RS.Modules.ReplicationClass)
    for _, name in ipairs(tryNames) do
        pcall(function()
            local inst = RC.new(name)
            local data = inst:GetData(player.Name)
            if type(data) == "table" then
                print(string.format("  FOUND: %q => type=table", name))
                for k, v in pairs(data) do
                    print(string.format("    key=%q type=%s", tostring(k), type(v)))
                end
            end
        end)
    end
end)
