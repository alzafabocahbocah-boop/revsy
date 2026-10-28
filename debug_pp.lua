-- debug_pp.lua — scan semua ProximityPrompt di workspace, urutkan dari terdekat
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local results = {}

local function scanObj(obj, depth)
    if depth > 8 then return end
    local ok, pp = pcall(function() return obj:FindFirstChildOfClass("ProximityPrompt") end)
    if ok and pp then
        local dist = 999
        local partPos
        if obj:IsA("BasePart") then
            partPos = obj.Position
        elseif obj:IsA("Model") and obj.PrimaryPart then
            partPos = obj.PrimaryPart.Position
        end
        if partPos then
            local ok2, d = pcall(function() return (hrp.Position - partPos).Magnitude end)
            if ok2 then dist = math.floor(d * 10) / 10 end
        end

        -- bangun path sampai 4 level
        local path = obj.Name
        local par = obj.Parent
        for _ = 1, 4 do
            if par and par ~= game.Workspace and par ~= game then
                path = par.Name .. "/" .. path
                par = par.Parent
            else break end
        end

        results[#results + 1] = {
            dist = dist,
            path = path,
            action = tostring(pp.ActionText),
            object = tostring(pp.ObjectText),
            maxDist = pp.MaxActivationDistance,
        }
    end
    for _, c in ipairs(obj:GetChildren()) do
        pcall(scanObj, c, depth + 1)
    end
end

pcall(scanObj, game.Workspace, 0)

table.sort(results, function(a, b) return a.dist < b.dist end)

print(string.rep("=", 60))
print(string.format("SCAN PP — %d ditemukan | posisi char: %s", #results, tostring(hrp.Position)))
print(string.rep("=", 60))
for i, r in ipairs(results) do
    print(string.format("[%d] dist=%.1fm | maxDist=%s | action='%s' | object='%s'",
        i, r.dist, tostring(r.maxDist), r.action, r.object))
    print(string.format("     path: %s", r.path))
end
print(string.rep("=", 60))
