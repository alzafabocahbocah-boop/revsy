-- ============================================================
-- ZENX LOADER PINTER — pilih script per AKUN dari backend (panel assign)
-- Taruh di Arceus Autoexec (ganti loader lama). Auto-run tiap join.
-- Akun di-assign script dari panel; loader fetch + jalanin script itu.
-- ============================================================
local URL     = "https://dry-glitter-63e4.petagee5.workers.dev"
local KUNCI   = "nfSUwzy6aXTFF0a546iQ2tizIVBeTF3T2Z1Xx0rb"
local REPO    = "https://raw.githubusercontent.com/alzafabocahbocah-boop/ronihub/main/"
local DEFAULT = "hact"   -- kalau akun belum di-assign / backend gagal -> pakai ini

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local t0 = tick()
while not plr and (tick() - t0) < 30 do task.wait(0.5); plr = Players.LocalPlayer end
if not plr then plr = Players.LocalPlayer end
local nama = (plr and plr.Name) or ""

-- fetch script yg di-assign buat akun ini
local sc = DEFAULT
pcall(function()
    local req = (syn and syn.request) or (fluxus and fluxus.request)
             or (krnl and krnl.request) or http_request or request or httprequest
    if type(http) == "table" and http.request then req = http.request end
    if req and nama ~= "" then
        local r = req({ Url = URL .. "/sc-get?akun=" .. nama, Method = "GET", Headers = { ["X-Kunci"] = KUNCI } })
        if r and (r.StatusCode == 200 or r.Success) and r.Body then
            local m = tostring(r.Body):match('"sc"%s*:%s*"([%w_%-]+)"')
            if m and m ~= "" then sc = m end
        end
    end
end)

print("[ZenxLoader] akun=" .. nama .. " -> script: " .. sc)

-- jalanin script dari ronihub
local ok, src = pcall(function() return game:HttpGet(REPO .. sc .. "?cb=" .. os.time()) end)
if ok and src and #src > 100 then
    local fn = loadstring(src)
    if fn then fn() else warn("[ZenxLoader] loadstring gagal buat " .. sc) end
else
    warn("[ZenxLoader] fetch script gagal: " .. sc)
end
