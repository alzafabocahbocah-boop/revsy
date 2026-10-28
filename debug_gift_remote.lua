-- debug_gift_remote.lua — cari remote yang ke-fire saat gift pet manual
-- Jalankan ini, lalu gift pet ke player lain via UI game
-- Lihat remote apa yang muncul

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
       or fullname:find("Analytics") or fullname:find("Heartbeat") then
        return origNamecall(self, ...)
    end

    -- highlight kalau ada kata "gift" / "give" / "pet"
    local lower = fullname:lower()
    local isInteresting = lower:find("gift") or lower:find("give") or lower:find("pet")
        or lower:find("trade") or lower:find("send")

    if isInteresting then
        print("★★★ ["..method.."] "..fullname)
    else
        print("["..method.."] "..fullname)
    end

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

print("=== debug_gift_remote aktif ===")
print("Sekarang: gift pet ke player lain via UI game (tekan tombol gift di inventory)")
print("Lihat remote ★★★ yang muncul")
