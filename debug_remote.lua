-- debug_remote.lua — hook semua RemoteEvent/RemoteFunction saat submit ke Mutation Machine
-- Jalankan, lalu manual submit 1 pet via UI game, lihat remote apa yang ke-fire

local RS = game:GetService("ReplicatedStorage")
local logged = {}
local hooks = {}

local function hookRemote(obj)
    if logged[obj] then return end
    logged[obj] = true
    local name = obj:GetFullName()

    if obj:IsA("RemoteEvent") then
        local old = obj.OnClientEvent
        -- hook dengan metatable
        local ok = pcall(function()
            local mt = {__index=function(t,k) return rawget(t,k) end}
            -- pakai hookfunction kalau tersedia (Delta/Synapse)
            if hookfunction then
                -- tidak bisa hook OnClientEvent langsung, tapi bisa monitor FireServer
                local origFS = obj.FireServer
                obj.FireServer = hookfunction(origFS, function(self, ...)
                    print("[REMOTE FireServer] " .. name)
                    for i, v in ipairs({...}) do
                        print("  arg["..i.."]: " .. tostring(v) .. " (" .. typeof(v) .. ")")
                    end
                    return origFS(self, ...)
                end)
                hooks[#hooks+1] = function() obj.FireServer = origFS end
            end
        end)
        if not ok then
            -- fallback: monitor via getconnections kalau ada
        end
    end
end

-- Hook semua remote di RS
local function scanRS(obj, depth)
    if depth > 5 then return end
    hookRemote(obj)
    for _, c in ipairs(obj:GetChildren()) do
        pcall(scanRS, c, depth+1)
    end
end
pcall(scanRS, RS, 0)

-- Juga hook workspace remotes
pcall(scanRS, game.Workspace, 0)

-- Monitor incoming remotes (kalau executor support)
print("=== debug_remote.lua ===")
print("Menghook " .. #hooks .. " RemoteEvent")
print("Sekarang: manual submit 1 pet via UI, liat output di bawah")
print("")

-- Cara lain: scan nama remote yang kemungkinan terkait mutasi
print("=== RemoteEvent/Function dengan keyword mutasi/pet/submit/send ===")
local function findRelevant(obj, depth)
    if depth > 6 then return end
    local n = obj.Name:lower()
    if n:find("mutat") or n:find("submit") or n:find("send.*pet") or n:find("pet.*send")
       or n:find("machine") or n:find("feedpet") or n:find("feed_pet") or n:find("givepet")
       or n:find("give_pet") or n:find("petmut") then
        print("  [FOUND] " .. obj:GetFullName() .. " (" .. obj.ClassName .. ")")
    end
    for _, c in ipairs(obj:GetChildren()) do pcall(findRelevant, c, depth+1) end
end
pcall(findRelevant, RS, 0)
pcall(findRelevant, game.Workspace, 0)

print("=== semua RemoteFunction di RS (top 2 level) ===")
for _, c in ipairs(RS:GetChildren()) do
    print("  " .. c.Name .. " (" .. c.ClassName .. ")")
    for _, cc in ipairs(c:GetChildren()) do
        print("    " .. cc.Name .. " (" .. cc.ClassName .. ")")
    end
end
print("=== selesai scan, tunggu submit... ===")
