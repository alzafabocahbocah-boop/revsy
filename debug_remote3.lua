-- debug_remote3.lua — intercept SEMUA remote khusus PetMutationMachine
-- Jalankan, lalu:
-- 1. Trigger PP mesin (fireproximityprompt / tekan E)
-- 2. Klik pet di list UI
-- 3. Tekan confirm/submit
-- Kita butuh remote yang dipanggil saat SELECT pet (sebelum submit)

local origNamecall
origNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method ~= "FireServer" and method ~= "InvokeServer" then
        return origNamecall(self, ...)
    end

    local ok, fullname = pcall(function() return self:GetFullName() end)
    fullname = ok and fullname or tostring(self)

    -- hanya print yang relevan (bukan spam Safari/Ping)
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

print("=== debug_remote3.lua aktif (filter Safari/Ping) ===")
print("Langkah:")
print("1. Trigger PP mesin mutasi (E / fireproximityprompt)")
print("2. Klik satu pet di list UI")
print("3. Klik confirm/submit")
print("Liat remote apa yang muncul urutan 1-2-3")
