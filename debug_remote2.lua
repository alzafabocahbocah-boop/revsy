-- debug_remote2.lua — intercept FireServer via hookmetamethod (Delta compatible)
-- Jalankan, lalu manual submit 1 pet via UI, lihat remote apa yang ke-fire

local logged = {}

if not hookmetamethod then
    print("[ERR] hookmetamethod tidak tersedia")
    -- fallback: list semua remote di RS
    local RS = game:GetService("ReplicatedStorage")
    local function scan(obj, depth, indent)
        if depth > 5 then return end
        local cls = obj.ClassName
        if cls == "RemoteEvent" or cls == "RemoteFunction" then
            print(indent .. obj.Name .. " [" .. cls .. "]")
        end
        for _, c in ipairs(obj:GetChildren()) do
            pcall(scan, c, depth+1, indent.."  ")
        end
    end
    print("=== Semua Remote di ReplicatedStorage ===")
    pcall(scan, RS, 0, "")
    return
end

print("=== debug_remote2.lua — hookmetamethod aktif ===")
print("Sekarang submit 1 pet via UI game, liat output di bawah:")
print("")

local origNamecall
origNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local ok, fullname = pcall(function() return self:GetFullName() end)
        fullname = ok and fullname or tostring(self)

        print(string.format("[%s] %s", method, fullname))
        local args = {...}
        for i, v in ipairs(args) do
            local t = typeof(v)
            local s
            if t == "string" then
                s = '"'..v..'"'
            elseif t == "Instance" then
                local ok2, fn = pcall(function() return v:GetFullName() end)
                s = ok2 and fn or tostring(v)
            elseif t == "table" then
                local parts = {}
                for k2, v2 in pairs(v) do
                    parts[#parts+1] = tostring(k2).."="..tostring(v2)
                end
                s = "{"..table.concat(parts,", ").."}"
            else
                s = tostring(v)
            end
            print("  arg["..i.."] ("..t.."): "..s)
        end
    end
    return origNamecall(self, ...)
end))

print("Hook siap. Submit pet manual sekarang via UI...")
