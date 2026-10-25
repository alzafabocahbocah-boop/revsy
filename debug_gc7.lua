-- eksplorasi PlayerGui.Data dan leaderstats
local player = game:GetService("Players").LocalPlayer
local pg = player:FindFirstChild("PlayerGui")

-- dump PlayerGui.Data descendants
print("=== PlayerGui.Data ===")
local dataGui = pg and pg:FindFirstChild("Data")
if dataGui then
    local function dumpTree(inst, indent)
        if indent > 4 then return end
        local pre = string.rep("  ", indent)
        -- cek attribute
        local attrs = {}
        pcall(function()
            for k, v in pairs(inst:GetAttributes()) do
                attrs[#attrs+1] = k .. "=" .. tostring(v)
            end
        end)
        local attrStr = #attrs > 0 and (" [" .. table.concat(attrs,", ") .. "]") or ""
        -- cek Value
        local val = ""
        pcall(function()
            if inst:IsA("StringValue") or inst:IsA("IntValue") or inst:IsA("NumberValue") then
                val = " val=" .. tostring(inst.Value)
            end
        end)
        print(pre .. inst.Name .. " (" .. inst.ClassName .. ")" .. val .. attrStr)
        for _, child in ipairs(inst:GetChildren()) do
            dumpTree(child, indent+1)
        end
    end
    dumpTree(dataGui, 0)
else
    print("PlayerGui.Data tidak ada")
end

-- dump leaderstats
print("\n=== leaderstats ===")
local ls = player:FindFirstChild("leaderstats")
if ls then
    for _, child in ipairs(ls:GetDescendants()) do
        local val = ""
        pcall(function()
            if child:IsA("IntValue") or child:IsA("NumberValue") or child:IsA("StringValue") then
                val = " = " .. tostring(child.Value)
            end
        end)
        print(" " .. child:GetFullName() .. " (" .. child.ClassName .. ")" .. val)
    end
end

-- cek MockData (kelihatan menarik)
print("\n=== MockData ===")
local mock = dataGui and dataGui:FindFirstChild("Padding")
    and dataGui.Padding:FindFirstChild("MockData")
if mock then
    for _, d in ipairs(mock:GetDescendants()) do
        local n = d.Name:lower()
        if n:find("max") or n:find("pet") or n:find("inv") then
            local val = ""
            pcall(function()
                if d:IsA("IntValue") or d:IsA("NumberValue") or d:IsA("StringValue") then
                    val = " = " .. tostring(d.Value)
                end
            end)
            print("  " .. d:GetFullName() .. val)
            -- cek attributes
            pcall(function()
                for k, v in pairs(d:GetAttributes()) do
                    if k:lower():find("max") or k:lower():find("pet") then
                        print("    attr: " .. k .. "=" .. tostring(v))
                    end
                end
            end)
        end
    end
end
