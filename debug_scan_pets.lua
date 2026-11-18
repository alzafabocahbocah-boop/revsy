-- debug_scan_pets.lua
-- Script debug: scan SEMUA pet yang kamu punya via RC memory container
-- Jalankan di executor Roblox. Output di console/output.
-- Versi: 2026-11-18

local function scanAllPets()
    print("=== DEBUG SCAN ALL PETS ===")

    -- Coba ambil container dari global (kalau up3.8kg / upkg sudah jalan)
    local container = _G._kgContainer

    -- Cari RC memory container langsung kalau _G._kgContainer nil
    if not container then
        print("[scan] _G._kgContainer nil, coba cari RC container langsung...")
        local plr = game:GetService("Players").LocalPlayer
        -- Coba cari via PlayerGui atau ReplicatedStorage
        local ok, err = pcall(function()
            -- Coba nama umum RC container
            for _, svc in ipairs({
                game:GetService("ReplicatedStorage"),
                plr and plr:WaitForChild("PlayerGui", 1),
                plr and plr:WaitForChild("Backpack", 1),
            }) do
                if svc then
                    for _, c in ipairs(svc:GetChildren()) do
                        print("[scan] child svc "..svc.Name..": "..c.Name.." ("..c.ClassName..")")
                    end
                end
            end
        end)
        if not ok then print("[scan] error: "..tostring(err)) end
    end

    -- Scan via backpack (selalu available)
    print("\n--- BACKPACK PETS ---")
    local plr = game:GetService("Players").LocalPlayer
    local bp = plr and plr:FindFirstChild("Backpack")
    local bpCount = 0
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            -- Pet di backpack biasanya punya attribute PetType atau nama mengandung pet
            local petType = item:GetAttribute("PetType") or item:GetAttribute("Type") or ""
            local petUuid = item:GetAttribute("UUID") or item:GetAttribute("Id") or ""
            local petLevel = item:GetAttribute("Level") or item:GetAttribute("Age") or 0
            local petWeight = item:GetAttribute("BaseWeight") or item:GetAttribute("Weight") or 0
            if petType ~= "" or item.ClassName == "Tool" then
                bpCount = bpCount + 1
                print(string.format("  [BP #%d] UUID=%s | Type=%s | Lv=%s | BW=%s",
                    bpCount, tostring(petUuid):sub(1,8), tostring(petType), tostring(petLevel), tostring(petWeight)))
            end
        end
    end
    if bpCount == 0 then print("  (tidak ada pet di backpack / attribute tidak match)") end

    -- Scan via Character (equipped pets)
    print("\n--- CHARACTER / EQUIPPED PETS ---")
    local char = plr and plr.Character
    local eqCount = 0
    if char then
        for _, item in ipairs(char:GetChildren()) do
            local petType = item:GetAttribute("PetType") or item:GetAttribute("Type") or ""
            local petUuid = item:GetAttribute("UUID") or item:GetAttribute("Id") or ""
            local petLevel = item:GetAttribute("Level") or item:GetAttribute("Age") or 0
            if petType ~= "" or item.ClassName == "Tool" then
                eqCount = eqCount + 1
                print(string.format("  [EQ #%d] UUID=%s | Type=%s | Lv=%s | Name=%s",
                    eqCount, tostring(petUuid):sub(1,8), tostring(petType), tostring(petLevel), item.Name))
            end
        end
    end
    if eqCount == 0 then print("  (tidak ada pet equipped / attribute tidak match)") end

    -- Scan via _G._kgContainer (kalau upkg / up3.8kg sudah jalan)
    print("\n--- _G._kgContainer (RC memory) ---")
    local c = _G._kgContainer
    if c and type(c) == "table" then
        local n = 0
        local counts = {}  -- hitung per tipe
        for uuid, e in pairs(c) do
            if type(e) == "table" then
                local pt = e.PetType or (e.PetData and e.PetData.PetType) or "?"
                local pd = e.PetData or {}
                local lv = tonumber(pd.Level) or 0
                local bw = tonumber(pd.BaseWeight) or 0
                local kg = bw * (lv + 10) / 10
                n = n + 1
                counts[tostring(pt)] = (counts[tostring(pt)] or 0) + 1
                if n <= 50 then  -- limit output biar gak spam
                    print(string.format("  [RC #%d] %-40s | Lv=%-3d | BW=%-6.1f | KG=%.1f",
                        n, tostring(pt):sub(1,40), lv, bw, kg))
                end
            end
        end
        if n > 50 then print("  ... (+"..( n-50).." lagi, total "..n..")") end
        print("\n--- SUMMARY PER TIPE ---")
        local sorted = {}
        for tipe, cnt in pairs(counts) do
            sorted[#sorted+1] = { tipe=tipe, cnt=cnt }
        end
        table.sort(sorted, function(a,b) return a.cnt > b.cnt end)
        for _, v in ipairs(sorted) do
            print(string.format("  %-40s x%d", v.tipe:sub(1,40), v.cnt))
        end
        print("\nTotal RC: "..n.." pets")
    else
        print("  _G._kgContainer = nil (upkg/up3.8kg belum jalan atau container belum ke-set)")
    end

    -- Cek support yang di-equip oleh upkg
    print("\n--- _G._ZenxSupportKunci (support equip upkg) ---")
    local sk = _G._ZenxSupportKunci
    if sk and type(sk) == "table" then
        local n = 0
        for uuid, nama in pairs(sk) do
            n = n + 1
            print(string.format("  [SK #%d] UUID=%s | nama=%s", n, tostring(uuid):sub(1,8), tostring(nama)))
        end
        if n == 0 then print("  (kosong - tidak ada support di-equip)") end
    else
        print("  _G._ZenxSupportKunci = nil (upkg belum jalan)")
    end

    print("\n=== SELESAI ===")
end

-- Jalankan langsung
local ok, err = pcall(scanAllPets)
if not ok then
    print("[scan ERROR] "..tostring(err))
end
