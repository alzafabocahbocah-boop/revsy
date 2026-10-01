-- sniff_client2server.lua — tangkap FireServer/InvokeServer client→server
-- pakai hookmetamethod (Delta support)
-- collect 1 buah manual, lihat remote apa yang dikirim

local RS = game:GetService("ReplicatedStorage")

local SKIP = {Fps=true, Input=true, Ping=true, RefreshIndex=true, GetState=true}

local hooked = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()

    -- hanya tangkap FireServer / InvokeServer
    if method ~= "FireServer" and method ~= "InvokeServer" then
        return hooked(self, ...)
    end

    -- skip spam
    if SKIP[self.Name] then return hooked(self, ...) end

    -- hanya dari RS
    local ok, inRS = pcall(function() return self:IsDescendantOf(RS) end)
    if not (ok and inRS) then return hooked(self, ...) end

    -- LOG
    local args = {...}
    print("=== CLIENT→SERVER ===")
    print("Remote: " .. self:GetFullName() .. " → " .. method)
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

    return hooked(self, ...)
end)

print("✅ hookmetamethod aktif — collect 1 buah manual sekarang (F9 lihat output)")
