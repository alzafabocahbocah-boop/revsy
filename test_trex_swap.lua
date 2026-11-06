-- test_trex_swap.lua
-- Test swap T-Rex via 2 mode: ready loop atau animation str
-- Inject ke executor Roblox

local MODE = "anim"       -- "ready" = ready loop | "anim" = animation str
local DELAY_BEFORE_SWAP = 0  -- detik sebelum swap setelah trigger (atur sendiri)

-- ============================================================

local plr = game.Players.LocalPlayer
local ge2 = game:GetService("ReplicatedStorage"):FindFirstChild("GameEvents2")
    or game:GetService("ReplicatedStorage"):FindFirstChild("GameEvents")

local function log(msg)
    print("[TEST-SWAP] "..tostring(msg))
end

-- Ambil container pet dari _G
local function getContainer()
    return _G._ZenxKgContainer or _G._UPL_kgContainer
end

local function equipPet(uuid)
    local ustr = tostring(uuid):gsub("[{}]","")
    if _G._UPL_equipPet then
        _G._UPL_equipPet(ustr)
    else
        log("ERR: _G._UPL_equipPet nil")
    end
end

local function unequipPet(uuid)
    local ustr = tostring(uuid):gsub("[{}]","")
    if _G._UPL_unequipPet then
        _G._UPL_unequipPet(ustr)
    else
        log("ERR: _G._UPL_unequipPet nil")
    end
end

local function doSwap(uuid, source)
    log("TRIGGER dari ["..source.."] uuid="..tostring(uuid):sub(1,12).." — delay "..DELAY_BEFORE_SWAP.."s")
    task.spawn(function()
        if DELAY_BEFORE_SWAP > 0 then task.wait(DELAY_BEFORE_SWAP) end
        log("SWAP: unequip → equip "..tostring(uuid):sub(1,12))
        unequipPet(uuid); task.wait(0.03)
        equipPet(uuid)
        log("SWAP DONE: "..tostring(uuid):sub(1,12))
    end)
end

-- ============================================================
-- MODE 1: READY LOOP — polling _UPL_petReady tiap 0.1s
-- ============================================================
if MODE == "ready" then
    log("MODE: ready loop | delay="..DELAY_BEFORE_SWAP.."s")
    local _lastReady = {}  -- [uuid] = last trigger tick
    local COOLDOWN = 2.0   -- cooldown per uuid agar tidak loop terus

    task.spawn(function()
        while true do
            task.wait(0.1)
            local c = getContainer()
            if not c then log("container nil, skip"); continue end
            for uuid, entry in pairs(c) do
                local tl = tostring(entry.PetType or (entry.PetData and entry.PetData.PetType) or ""):lower()
                if not tl:find("t-rex", 1, true) then continue end
                -- cek ready via _G._UPL_petReady atau petReadyUpl
                local ready = false
                if _G._UPL_petReady then
                    ready = _G._UPL_petReady(uuid)
                end
                if ready then
                    local now = tick()
                    local last = _lastReady[uuid] or 0
                    if now - last > COOLDOWN then
                        _lastReady[uuid] = now
                        doSwap(uuid, "ready-loop")
                    end
                end
            end
        end
    end)

-- ============================================================
-- MODE 2: ANIM STR — monitor DataStream animStr "roar"
-- ============================================================
elseif MODE == "anim" then
    log("MODE: anim str | delay="..DELAY_BEFORE_SWAP.."s")

    if not ge2 then log("ERR: ge2 nil"); return end
    local ds2 = ge2:WaitForChild("DataStream", 15)
    if not ds2 then log("ERR: DataStream nil"); return end

    local _debounce = {}  -- [r8] = tick()
    local COOLDOWN = 1.5

    local function deepFind(t, depth)
        depth = depth or 0
        if depth > 12 or type(t) ~= "table" then return end
        for _, v in pairs(t) do
            if type(v) == "table" then
                local v1 = tostring(v[1] or "")
                if v1:find("CustomAnimationState", 1, true) then
                    local animStr = tostring(v[2] or "")
                    local anim = animStr:lower()
                    if anim ~= "roar" then continue end

                    local uuid = v1:match("{([^}]+)}") or v1:match("/([^/]+)/CustomAnimationState") or "?"
                    local raw = uuid:gsub("[{}]","")
                    local r8 = raw:sub(1,8)

                    -- cek tipe pet
                    local tl = ""
                    local c = getContainer()
                    if c then
                        local e = c["{"..raw.."}"] or c[raw]
                        if type(e) == "table" then
                            tl = tostring(e.PetType or (e.PetData and e.PetData.PetType) or ""):lower()
                        end
                    end

                    if not tl:find("t-rex", 1, true) then
                        log("roar detected tapi bukan T-Rex: tl='"..tl.."' r8="..r8)
                        continue
                    end

                    local now = tick()
                    local last = _debounce[r8] or 0
                    if now - last < COOLDOWN then continue end
                    _debounce[r8] = now

                    log("roar DETECTED T-Rex r8="..r8)
                    doSwap(raw, "anim-roar")
                else
                    deepFind(v, depth+1)
                end
            end
        end
    end

    ds2.OnClientEvent:Connect(function(...)
        local args = {...}
        local svc = tostring(args[2] or "")
        if not svc:find("ActivePets", 1, true) then return end
        local data = type(args[3])=="table" and args[3] or (type(args[4])=="table" and args[4] or nil)
        if data then deepFind(data, 0) end
    end)

    log("anim listener ON — tunggu roar T-Rex...")
end
