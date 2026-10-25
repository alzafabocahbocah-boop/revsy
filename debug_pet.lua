-- cari pet di inventory via Instance, lalu trace ke getgc container
local player = game:GetService("Players").LocalPlayer
local bp = player:FindFirstChild("Backpack")

-- ambil beberapa pet dari Backpack (Instance)
print("=== pet di Backpack (Instance) ===")
local petInstances = {}
if bp then
    for _, child in ipairs(bp:GetChildren()) do
        petInstances[#petInstances+1] = child
        if #petInstances >= 3 then break end
    end
end
print("jumlah pet sample:", #petInstances)
for i, p in ipairs(petInstances) do
    print(string.format("  [%d] %s ClassName=%s", i, p.Name, p.ClassName))
    -- dump attributes
    pcall(function()
        for k, v in pairs(p:GetAttributes()) do
            print("    attr: " .. k .. "=" .. tostring(v))
        end
    end)
end

-- cari di getgc table yang ref ke salah satu pet instance ini
if #petInstances == 0 then print("Backpack kosong"); return end
local target = petInstances[1]
print("\n=== cari ref ke pet[1] =" .. target.Name .. " di getgc ===")
local found = {}
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        for k, v in pairs(obj) do
            if rawequal(v, target) then
                found[#found+1] = {obj=obj, key=tostring(k)}
                break
            end
        end
    end
end
print("table yang ref ke pet:", #found)
for i, f in ipairs(found) do
    if i > 5 then print("..."); break end
    local keys = {}
    for k in pairs(f.obj) do
        if type(k)=="string" then keys[#keys+1]=k end
        if #keys >= 8 then break end
    end
    print(string.format("  [%d] key='%s' keys={%s}", i, f.key, table.concat(keys,",")))
end

-- coba cara lain: cari table yang punya field "uid" / "id" yang sama dengan attribute pet
print("\n=== cari via pet UID/GUID attribute ===")
local petUid = nil
pcall(function()
    petUid = target:GetAttribute("uid") or target:GetAttribute("Uid")
              or target:GetAttribute("id") or target:GetAttribute("Id")
              or target:GetAttribute("UUID") or target:GetAttribute("uuid")
end)
print("petUid dari attribute:", tostring(petUid))
if petUid then
    local uidFound = 0
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" then
            local v = rawget(obj, "uid") or rawget(obj, "Uid") or rawget(obj, "id")
            if v == petUid then
                uidFound = uidFound + 1
                if uidFound <= 3 then
                    local keys = {}
                    for k in pairs(obj) do
                        if type(k)=="string" then keys[#keys+1]=k end
                        if #keys >= 8 then break end
                    end
                    print(string.format("  match[%d] keys={%s}", uidFound, table.concat(keys,",")))
                end
            end
        end
    end
    print("total match uid:", uidFound)
end
