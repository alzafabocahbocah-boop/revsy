-- cek getgc dan scan table dengan field angka apapun
print("getgc ada:", getgc ~= nil)
if not getgc then return end

local total = 0
local sample = {}
for _, obj in pairs(getgc(false)) do
    if type(obj) == "table" then
        total = total + 1
        -- ambil 3 sample pertama yg punya key string
        if #sample < 3 then
            local keys = {}
            for k in pairs(obj) do
                if type(k) == "string" then keys[#keys+1] = k end
                if #keys >= 5 then break end
            end
            if #keys > 0 then
                sample[#sample+1] = table.concat(keys, ", ")
            end
        end
    end
end
print("total table di gc:", total)
for i, s in ipairs(sample) do
    print("sample " .. i .. ":", s)
end

-- coba cari table yang punya key mengandung "Max" atau "Pet"
local found = 0
for _, obj in pairs(getgc(false)) do
    if type(obj) == "table" then
        for k in pairs(obj) do
            if type(k) == "string" and (k:find("Max") or k:find("Pet")) then
                found = found + 1
                if found <= 5 then
                    print("found key:", k, "val:", tostring(rawget(obj,k)))
                end
                break
            end
        end
    end
end
print("table dengan key Max/Pet:", found)
