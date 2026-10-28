-- debug_claim.lua — cari remote ClaimPet dari Mutation Machine
-- Jalankan hookmetamethod, lalu tekan E "Claim Pet" di mesin
-- Lihat remote apa yang ke-fire

local origNamecall
origNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method ~= "FireServer" and method ~= "InvokeServer" then
        return origNamecall(self, ...)
    end

    local ok, fullname = pcall(function() return self:GetFullName() end)
    fullname = ok and fullname or tostring(self)

    -- skip spam
    if fullname:find("Safari") or fullname:find("Ping") or fullname:find("FocusState") then
        return origNamecall(self, ...)
    end

    print(string.format("[%s] %s", method, fullname))
    for i, v in ipairs({...}) do
        local t = typeof(v)
        local s
        if t == "string" then s = '"'..v..'"'
        elseif t == "Instance" then
            local ok2, fn = pcall(function() return v:GetFullName() end)
            s = ok2 and fn or tostring(v)
        elseif t == "table" then
            local parts = {}
            for k, vv in pairs(v) do parts[#parts+1] = tostring(k).."="..tostring(vv) end
            s = "{"..table.concat(parts,", ").."}"
        else s = tostring(v) end
        print("  arg["..i.."] ("..t.."): "..s)
    end

    return origNamecall(self, ...)
end))

print("=== debug_claim.lua aktif ===")
print("Sekarang: tekan E di mesin untuk 'Claim Pet'")
print("Lihat remote apa yang muncul di output")
