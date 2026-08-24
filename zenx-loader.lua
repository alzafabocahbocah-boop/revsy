-- ============================================================
-- ZENX LOADER PINTER — pilih script per AKUN dari backend (panel assign)
-- Taruh di Arceus Autoexec. Auto-run tiap join. Nampilin STATUS di layar.
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

-- INDIKATOR ON-SCREEN (label global, di-update status jalan/error)
local infoLbl
pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ZenxLoaderInfo"; gui.ResetOnSpawn = false
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(0, 380, 0, 32); infoLbl.Position = UDim2.new(0.5, -190, 0, 6)
    infoLbl.BackgroundColor3 = Color3.fromRGB(18, 18, 24); infoLbl.BackgroundTransparency = 0.06
    infoLbl.Text = "ZenxLoader:  " .. nama .. "  ->  " .. sc .. "  [loading...]"
    infoLbl.Font = Enum.Font.GothamBold; infoLbl.TextSize = 13; infoLbl.TextColor3 = Color3.fromRGB(230, 220, 120)
    infoLbl.BorderSizePixel = 0; infoLbl.Parent = gui
    Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 7)
    task.delay(35, function() pcall(function() gui:Destroy() end) end)
end)
local function setInfo(txt, warna)
    pcall(function() if infoLbl then infoLbl.Text = txt; if warna then infoLbl.TextColor3 = warna end end end)
end
local IJO  = Color3.fromRGB(120, 255, 140)
local MERAH= Color3.fromRGB(255, 110, 110)

-- fetch + jalanin script
local ok, src = pcall(function() return game:HttpGet(REPO .. sc .. "?cb=" .. os.time()) end)
if ok and src and #src > 100 then
    local fn, cerr = loadstring(src)
    if fn then
        local ok2, rerr = pcall(fn)
        if ok2 then
            setInfo("ZenxLoader:  " .. nama .. "  ->  " .. sc .. "  [JALAN OK]", IJO)
        else
            setInfo("ZenxLoader:  " .. nama .. "  ->  " .. sc .. "  [RUN-ERR: " .. tostring(rerr):sub(1, 55) .. "]", MERAH)
            warn("[ZenxLoader] " .. sc .. " RUN error: " .. tostring(rerr))
        end
    else
        setInfo("ZenxLoader:  " .. nama .. "  ->  " .. sc .. "  [COMPILE-ERR: " .. tostring(cerr):sub(1, 50) .. "]", MERAH)
        warn("[ZenxLoader] " .. sc .. " loadstring gagal: " .. tostring(cerr))
    end
else
    setInfo("ZenxLoader:  " .. nama .. "  ->  " .. sc .. "  [FETCH-GAGAL: ronihub/" .. sc .. " gak ada?]", MERAH)
    warn("[ZenxLoader] fetch gagal: " .. sc)
end
