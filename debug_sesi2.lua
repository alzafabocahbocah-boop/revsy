-- debug_sesi2.lua — cari remote yang dipakai saat tambah pet ke mesin yang sudah running
-- Jalankan hookmetamethod, lalu:
-- 1. Masukkan pet sesi 1 (Mimic/Golem) ke mesin yang kosong
-- 2. Tunggu mesin running
-- 3. Masukkan pet sesi 2 (Gremlin) ke mesin yang sudah running
-- Lihat bedanya remote/arg yang muncul

local origNamecall
origNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method ~= "FireServer" and method ~= "InvokeServer" then
        return origNamecall(self, ...)
    end

    local ok, fullname = pcall(function() return self:GetFullName() end)
    fullname = ok and fullname or tostring(self)

    -- skip spam
    if fullname:find("Safari") or fullname:find("Ping") or fullname:find("FocusState")
       or fullname:find("Analytics") then
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

print("=== debug_sesi2.lua aktif ===")
print("LANGKAH:")
print("1. Masukkan pet ke mesin KOSONG (sesi 1) — lihat remote")
print("2. Tunggu mesin mulai running")
print("3. Masukkan pet ke mesin RUNNING (sesi 2) — lihat remote")
print("4. Paste semua output ke chat")
