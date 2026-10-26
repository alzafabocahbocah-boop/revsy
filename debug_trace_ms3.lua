-- debug_trace_ms3.lua
-- Trace siapa yang pegang table {wildnx_27} (atau nama player)
local player = game:GetService("Players").LocalPlayer
local myName = player.Name

-- rebuild chain: MutableStats → PlayerData → PetsData container → {myName} container
local gc = getgc(true)

-- step 1: MutableStats 260
local msSet = {}
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" then
        local mp = rawget(obj,"MaxPetsInInventory")
        if type(mp)=="number" and mp==260
        and type(rawget(obj,"MaxEggsInFarm"))=="number"
        and type(rawget(obj,"MaxEquippedPets"))=="number" then
            msSet[obj]=true
        end
    end
end

-- step 2: PlayerData (punya MutableStats)
local pdSet = {}
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and not msSet[obj] then
        if msSet[rawget(obj,"MutableStats")] then pdSet[obj]=true end
    end
end

-- step 3: PetsData container (punya key PetsData = PlayerData)
local petsDataSet = {}
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and not pdSet[obj] and not msSet[obj] then
        for k, v in pairs(obj) do
            if pdSet[v] then petsDataSet[obj]=true; break end
        end
    end
end

-- step 4: {myName} container (punya key myName = PetsData container)
local nameContSet = {}
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and not petsDataSet[obj] and not pdSet[obj] and not msSet[obj] then
        local v = rawget(obj, myName)
        if petsDataSet[v] then nameContSet[obj]=true end
    end
end
print("{myName} containers:", (function() local n=0; for _ in pairs(nameContSet) do n=n+1 end; return n end)())

-- step 5: siapa pegang {myName} container
print("=== Yang pegang {myName} container ===")
local found = 0
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" and not nameContSet[obj] and not petsDataSet[obj] and not pdSet[obj] and not msSet[obj] then
        for k, v in pairs(obj) do
            if nameContSet[v] then
                found = found + 1
                local keys = {}
                for kk in pairs(obj) do keys[#keys+1]=tostring(kk); if #keys>=8 then break end end
                print(string.format("  [%d] key='%s' in table{%s}", found, tostring(k), table.concat(keys,",")))
            end
        end
    end
end
if found==0 then print("  tidak ada table lagi — ini root") end

-- cek _G
print("")
print("=== {myName} container ada di _G? ===")
for gk, gv in pairs(_G) do
    if nameContSet[gv] then print("  _G."..tostring(gk)) end
    if type(gv)=="table" then
        for gk2, gv2 in pairs(gv) do
            if nameContSet[gv2] then print("  _G."..tostring(gk).."."..tostring(gk2)) end
        end
    end
end

-- cek upvalue
print("")
print("=== Fungsi dengan upvalue {myName} container ===")
if getupvalues then
    local uf = 0
    for i = 1, #gc do
        local fn = gc[i]
        if type(fn)=="function" then
            pcall(function()
                for _, uv in pairs(getupvalues(fn)) do
                    if nameContSet[uv] then
                        uf = uf + 1
                        if uf <= 8 then
                            local info = debug and debug.getinfo and debug.getinfo(fn)
                            print("  upvalue src="..tostring(info and info.short_src or "?"))
                        end
                    end
                end
            end)
        end
    end
    print("Total:", uf)
end

-- SHORTCUT: coba akses langsung via chain yang sudah kita tahu
print("")
print("=== Test akses langsung (tanpa getgc) ===")
-- cari di GC table yang punya key myName langsung dan value-nya punya PetsData
for i = 1, #gc do
    local obj = gc[i]
    if type(obj)=="table" then
        local v = rawget(obj, myName)
        if type(v)=="table" then
            local pd = rawget(v, "PetsData")
            if type(pd)=="table" then
                local ms = rawget(pd, "MutableStats")
                if type(ms)=="table" then
                    local mp = rawget(ms, "MaxPetsInInventory")
                    if type(mp)=="number" and mp>0 then
                        print("  FOUND via obj[myName].PetsData.MutableStats.MaxPetsInInventory =", mp)
                        -- cek apakah obj ini ada di _G
                        for gk, gv2 in pairs(_G) do
                            if gv2==obj then print("  -> _G."..tostring(gk)) end
                        end
                    end
                end
            end
        end
    end
end
