-- test_submit.lua — test submit held pet ke Mutation Machine tanpa UI
-- Cara pakai: pegang pet dulu manual, lalu jalankan script ini

local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

-- cari PP mesin mutasi
local pp
local ok, part = pcall(function()
    return game.Workspace.NPCS.PetMutationMachine.Model.ProxPromptPart
end)
if ok and part then
    pp = part:FindFirstChildOfClass("ProximityPrompt")
end

if not pp then
    print("[ERR] PP Mutation Machine tidak ditemukan, pastikan dekat mesin")
    return
end

local RE = RS.GameEvents.PetMutationMachineService_RE

print("=== test_submit.lua ===")
print("Jarak ke mesin: " .. string.format("%.1f", (hrp.Position - part.Position).Magnitude) .. "m")
print("PP Enabled: " .. tostring(pp.Enabled))

-- step 1: trigger PP (buka sesi di server)
print("[1] Trigger PP...")
pcall(fireproximityprompt, pp)
task.wait(0.5)

-- step 2: fire SubmitHeldPet
print("[2] Fire SubmitHeldPet...")
local ok2, err2 = pcall(function()
    RE:FireServer("SubmitHeldPet")
end)

if ok2 then
    print("[OK] SubmitHeldPet berhasil! Cek apakah pet masuk mesin.")
else
    print("[ERR] " .. tostring(err2))
end
