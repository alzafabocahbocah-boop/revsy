-- debug_pet_garden.lua
-- Cek pet yang lagi aktif/equipped di garden via RC container
-- TANPA workspace scan / DescendantAdded
-- Output di print/console executor

local function run()
    local RS = game:GetService("ReplicatedStorage")
    local plr = game:GetService("Players").LocalPlayer
    local mod = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ReplicationClass")
    if not mod then print("[DBG] ReplicationClass tidak ketemu"); return end

    local RC = require(mod)
    local inst = RC.new("ActivePetsService_Replicator")
    local ok, data = pcall(function() return inst:GetData(plr.Name) end)
    if not ok or not data then print("[DBG] GetData gagal: "..tostring(data)); return end

    -- dump semua key di root Table
    print("[DBG] ===== ROOT TABLE KEYS =====")
    pcall(function()
        for k, v in pairs(data.Table) do
            print("  "..tostring(k).." = "..type(v))
        end
    end)

    print("[DBG] ===== PlayerPetData KEYS =====")
    pcall(function()
        local ppd = data.Table.PlayerPetData[plr.Name]
        for k, v in pairs(ppd) do
            print("  "..tostring(k).." = "..type(v))
        end
    end)

    -- cek ActivePetStates (kemungkinan key equipped)
    print("[DBG] ===== ActivePetStates =====")
    pcall(function()
        local aps = data.Table.PlayerPetData[plr.Name].ActivePetStates
        if not aps then print("  nil — tidak ada"); return end
        local n = 0
        for uuid, state in pairs(aps) do
            n = n + 1
            if n <= 5 then
                print("  UUID: "..tostring(uuid))
                if type(state) == "table" then
                    for k, v in pairs(state) do
                        if type(v) ~= "table" then
                            print("    ["..tostring(k).."] = "..tostring(v))
                        else
                            print("    ["..tostring(k).."] = table")
                            for k2,v2 in pairs(v) do
                                if type(v2) ~= "table" then print("      ["..tostring(k2).."] = "..tostring(v2)) end
                            end
                        end
                    end
                else
                    print("    value = "..tostring(state))
                end
            end
        end
        print("  total ActivePetStates: "..n)
    end)

    -- cek EquippedPets / ActivePets / field lain yang mungkin ada
    print("[DBG] ===== cek field lain (EquippedPets, ActivePets, dll) =====")
    pcall(function()
        local ppd = data.Table.PlayerPetData[plr.Name]
        local cek = {"EquippedPets","ActivePets","EquippedPetList","PetSlots","ActiveSlots","Equipped"}
        for _, key in ipairs(cek) do
            local v = ppd[key]
            if v ~= nil then
                print("  KETEMU: "..key.." = "..type(v))
                if type(v) == "table" then
                    local n = 0
                    for k2,v2 in pairs(v) do
                        n = n + 1
                        if n <= 5 then print("    ["..tostring(k2).."] = "..tostring(v2)) end
                    end
                    print("    total: "..n)
                end
            else
                print("  "..key.." = nil")
            end
        end
    end)

    -- cek PetInventory.Data — field IsEquipped / Equipped per pet
    print("[DBG] ===== PetInventory.Data — cek field IsEquipped per pet =====")
    pcall(function()
        local invData = data.Table.PlayerPetData[plr.Name].PetInventory.Data
        local n, nEquipped = 0, 0
        for uuid, entry in pairs(invData) do
            if type(entry) == "table" then
                n = n + 1
                -- cek semua key yang ada di root entry (pertama kali saja)
                if n == 1 then
                    print("  sample root keys entry ke-1:")
                    for k,v in pairs(entry) do
                        print("    ["..tostring(k).."] = "..type(v).." ("..tostring(v):sub(1,30)..")")
                    end
                end
                -- cek field equipped
                local eq = entry.IsEquipped or entry.Equipped or entry.isEquipped or entry.active or entry.Active
                if eq then nEquipped = nEquipped + 1 end
            end
        end
        print("  total pet: "..n.." | equipped field ada: "..nEquipped)
    end)
end

pcall(run)
