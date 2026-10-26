-- debug_trace_ms4.lua
-- Langsung cari table yang punya key = nama player
-- lalu akses chain ke MutableStats
local player = game:GetService("Players").LocalPlayer
local myName = player.Name
print("myName =", myName)

local gc = getgc(true)
local found = 0

for i = 1, #gc do
    local obj = gc[i]
    if type(obj) == "table" then
        local v = rawget(obj, myName)
        if type(v) == "table" then
            found = found + 1
            -- print keys dari obj dan v
            local objKeys = {}
            for k in pairs(obj) do objKeys[#objKeys+1]=tostring(k); if #objKeys>=6 then break end end
            local vKeys = {}
            for k in pairs(v) do vKeys[#vKeys+1]=tostring(k); if #vKeys>=8 then break end end
            print(string.format("[%d] obj{%s}[%q] = {%s}", found, table.concat(objKeys,","), myName, table.concat(vKeys,",")))

            -- coba akses PetsData.MutableStats.MaxPetsInInventory
            pcall(function()
                local pd = rawget(v, "PetsData")
                if type(pd)=="table" then
                    local ms = rawget(pd, "MutableStats")
                    if type(ms)=="table" then
                        local mp = rawget(ms, "MaxPetsInInventory")
                        print("  -> PetsData.MutableStats.MaxPetsInInventory =", tostring(mp))
                    else
                        print("  -> PetsData ada, MutableStats nil")
                        -- print keys PetsData
                        local pdKeys = {}
                        for k in pairs(pd) do pdKeys[#pdKeys+1]=tostring(k); if #pdKeys>=8 then break end end
                        print("     PetsData keys:", table.concat(pdKeys,","))
                    end
                else
                    -- coba langsung v.MutableStats
                    local ms = rawget(v, "MutableStats")
                    if type(ms)=="table" then
                        local mp = rawget(ms, "MaxPetsInInventory")
                        print("  -> MutableStats.MaxPetsInInventory =", tostring(mp))
                    else
                        print("  -> PetsData nil, MutableStats nil")
                    end
                end
            end)

            -- cek apakah obj ada di _G
            for gk, gv in pairs(_G) do
                if gv == obj then print("  -> _G."..tostring(gk)) end
            end

            if found >= 5 then break end
        end
    end
end

print("Total table dengan key myName:", found)
