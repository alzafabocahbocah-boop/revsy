-- listen_harvest.lua — pasang OnClientEvent + OnClientInvoke di HarvestRemote
-- collect 1 buah manual, lihat apa yang server kirim balik ke client
local RS = game:GetService("ReplicatedStorage")
local gameEvents = RS:WaitForChild("GameEvents", 10)
local harvestRE = gameEvents:WaitForChild("HarvestRemote", 10)

print("HarvestRemote type: " .. harvestRE.ClassName)

if harvestRE:IsA("RemoteEvent") then
    harvestRE.OnClientEvent:Connect(function(...)
        local args = {...}
        print("=== OnClientEvent FIRED ===")
        for i, a in ipairs(args) do
            if typeof(a) == "Instance" then
                print("  ["..i.."] Instance = " .. a:GetFullName())
                for k,v in pairs(a:GetAttributes()) do
                    print("    attr: "..k.."="..tostring(v))
                end
            else
                print("  ["..i.."] "..typeof(a).." = "..tostring(a))
            end
        end
    end)
    print("OnClientEvent listener terpasang — collect buah manual sekarang")

elseif harvestRE:IsA("RemoteFunction") then
    harvestRE.OnClientInvoke = function(...)
        local args = {...}
        print("=== OnClientInvoke FIRED ===")
        for i, a in ipairs(args) do
            if typeof(a) == "Instance" then
                print("  ["..i.."] Instance = " .. a:GetFullName())
            else
                print("  ["..i.."] "..typeof(a).." = "..tostring(a))
            end
        end
    end
    print("OnClientInvoke listener terpasang — collect buah manual sekarang")
end
