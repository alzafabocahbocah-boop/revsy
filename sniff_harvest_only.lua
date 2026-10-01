-- sniff_harvest_only.lua — wrap InvokeServer/FireServer HANYA di HarvestRemote
-- tidak hook global, tidak crash
local RS = game:GetService("ReplicatedStorage")
local gameEvents = RS:WaitForChild("GameEvents", 10)
local hr = gameEvents:WaitForChild("HarvestRemote", 10)

print("HarvestRemote: " .. hr.ClassName)

-- wrap FireServer (kalau RemoteEvent)
local origFire = hr.FireServer
hr.FireServer = function(self, ...)
    print("=== HarvestRemote:FireServer ===")
    for i, a in ipairs({...}) do
        if typeof(a) == "Instance" then
            print("  ["..i.."] "..a:GetFullName())
            for k,v in pairs(a:GetAttributes()) do print("    "..k.."="..tostring(v)) end
        else
            print("  ["..i.."] "..typeof(a).."="..tostring(a))
        end
    end
    return origFire(self, ...)
end

-- wrap InvokeServer (kalau RemoteFunction)
local origInvoke = hr.InvokeServer
hr.InvokeServer = function(self, ...)
    print("=== HarvestRemote:InvokeServer ===")
    for i, a in ipairs({...}) do
        if typeof(a) == "Instance" then
            print("  ["..i.."] "..a:GetFullName())
            for k,v in pairs(a:GetAttributes()) do print("    "..k.."="..tostring(v)) end
        else
            print("  ["..i.."] "..typeof(a).."="..tostring(a))
        end
    end
    return origInvoke(self, ...)
end

print("✅ Wrap terpasang — collect 1 buah manual sekarang (F9)")
