-- sniff_harvest_only.lua — hookfunction InvokeServer di HarvestRemote
-- hookfunction = exploit API, bisa hook method bawaan Roblox
local RS = game:GetService("ReplicatedStorage")
local gameEvents = RS:WaitForChild("GameEvents", 10)
local hr = gameEvents:WaitForChild("HarvestRemote", 10)

print("HarvestRemote class: " .. hr.ClassName)

-- hookfunction langsung ke method InvokeServer milik RemoteFunction
local origInvoke = hookfunction(hr.InvokeServer, function(self, ...)
    print("=== HarvestRemote:InvokeServer ===")
    local args = {...}
    if #args == 0 then
        print("  (no args)")
    end
    for i, a in ipairs(args) do
        if typeof(a) == "Instance" then
            print("  ["..i.."] Instance = " .. a:GetFullName())
            local ok2, attrs = pcall(function() return a:GetAttributes() end)
            if ok2 then
                for k,v in pairs(attrs) do
                    print("    attr: "..k.."="..tostring(v))
                end
            end
        else
            print("  ["..i.."] "..typeof(a).." = "..tostring(a))
        end
    end
    local result = origInvoke(self, ...)
    print("  → result: "..tostring(result))
    return result
end)

print("✅ hookfunction InvokeServer terpasang — collect 1 buah manual sekarang (F9)")
