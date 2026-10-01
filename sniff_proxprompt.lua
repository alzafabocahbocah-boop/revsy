-- sniff_proxprompt.lua — tangkap ProximityPrompt.Triggered saat collect manual
-- hookfunction pada fireproximityprompt (exploit API)

local origFPP = fireproximityprompt
fireproximityprompt = hookfunction(origFPP, function(pp, ...)
    print("=== fireproximityprompt ===")
    print("  PP: " .. pp:GetFullName())
    print("  Parent: " .. tostring(pp.Parent and pp.Parent:GetFullName()))
    -- print attributes parent (buah)
    local ok, attrs = pcall(function() return pp.Parent:GetAttributes() end)
    if ok then
        for k,v in pairs(attrs) do
            print("    attr: "..k.."="..tostring(v))
        end
    end
    return origFPP(pp, ...)
end)

-- juga hook __namecall tapi HANYA untuk ProximityPrompt:FireServer (kalau ada)
-- dan listen TriggerEnded
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

-- scan semua ProximityPrompt di workspace, print namanya
task.spawn(function()
    task.wait(0.5)
    local count = 0
    for _, pp in ipairs(workspace:GetDescendants()) do
        if pp:IsA("ProximityPrompt") then
            count = count + 1
            -- hook Triggered event
            pp.Triggered:Connect(function(plr)
                if plr == player then
                    print("=== PP.Triggered (client event) ===")
                    print("  PP: " .. pp:GetFullName())
                    local ok2, attrs2 = pcall(function() return pp.Parent:GetAttributes() end)
                    if ok2 then
                        for k,v in pairs(attrs2) do
                            print("    attr: "..k.."="..tostring(v))
                        end
                    end
                end
            end)
        end
    end
    print("✅ Scan selesai — "..count.." ProximityPrompt ditemukan di workspace")
    print("Collect 1 buah manual sekarang (F9)")
end)
