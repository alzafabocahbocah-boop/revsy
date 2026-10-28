-- auto_mutasi.lua — auto submit pet ke Mutation Machine
-- Path PP: Workspace.NPCS.PetMutationMachine.Model.ProxPromptPart
-- Action: 'Submit Pet' | Object: 'Mutation Machine'

local plr  = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

print("=== auto_mutasi.lua ===")

-- ── helper: cari PP mesin mutasi ──
local function getMutasiPP()
    local ok, part = pcall(function()
        return game.Workspace.NPCS.PetMutationMachine.Model.ProxPromptPart
    end)
    if not ok or not part then
        -- fallback: scan
        local found
        local function scan(obj, d)
            if d > 6 or found then return end
            local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            if pp and pp.ActionText == "Submit Pet" and pp.ObjectText == "Mutation Machine" then
                found = obj
            end
            for _, c in ipairs(obj:GetChildren()) do pcall(scan, c, d+1) end
        end
        pcall(scan, game.Workspace.NPCS, 0)
        return found and found:FindFirstChildOfClass("ProximityPrompt")
    end
    return part:FindFirstChildOfClass("ProximityPrompt")
end

-- ── cek jarak ke mesin ──
local function getMutasiDist()
    local ok, part = pcall(function()
        return game.Workspace.NPCS.PetMutationMachine.Model.ProxPromptPart
    end)
    if not ok or not part then return 9999 end
    local ok2, d = pcall(function() return (hrp.Position - part.Position).Magnitude end)
    return ok2 and d or 9999
end

-- ── MAIN ──
local pp = getMutasiPP()
if not pp then
    print("[ERR] ProximityPrompt Mutation Machine tidak ditemukan!")
    print("      Pastikan karakter di area mesin mutasi dan mesin terload")
    return
end

print("[OK] Mutation Machine PP ditemukan")
print("     Enabled: " .. tostring(pp.Enabled))
print("     Jarak: " .. string.format("%.1f", getMutasiDist()) .. "m")

-- coba trigger
print("[...] Trigger Submit Pet...")
local ok, err = pcall(fireproximityprompt, pp)
if ok then
    print("[OK] Submit Pet berhasil! Cek UI game untuk konfirmasi.")
else
    print("[ERR] Gagal: " .. tostring(err))
end
print("=== selesai ===")
