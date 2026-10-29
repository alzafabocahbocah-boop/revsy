-- debug click: coba klik Cancel di GenericConfirmationPrompt
-- Path: GenericConfirmationPrompt > PromptFrame > Main > Buttons > Cancel(ImageButton)
-- JALANIN SAAT DIALOG MUNCUL
local plr = game:GetService("Players").LocalPlayer
local pg = plr:FindFirstChild("PlayerGui")

print("=== DEBUG CLICK Cancel ===")

local sg = pg:FindFirstChild("GenericConfirmationPrompt")
if not sg then print("GenericConfirmationPrompt NOT FOUND"); return end
print("Found ScreenGui:", sg.Name)

local pf = sg:FindFirstChild("PromptFrame")
if not pf then print("PromptFrame NOT FOUND"); return end

local main = pf:FindFirstChild("Main")
if not main then print("Main NOT FOUND"); return end

local buttons = main:FindFirstChild("Buttons")
if not buttons then print("Buttons NOT FOUND"); return end

local cancelBtn = buttons:FindFirstChild("Cancel")
if not cancelBtn then print("Cancel NOT FOUND"); return end
print("Cancel found! ClassName:", cancelBtn.ClassName)

-- Coba semua cara klik
print("Trying firesignal...")
if firesignal then
    pcall(function() firesignal(cancelBtn.MouseButton1Down) end)
    pcall(function() firesignal(cancelBtn.MouseButton1Click) end)
    print("firesignal done")
end

print("Trying getconnections...")
if getconnections then
    local conns = getconnections(cancelBtn.MouseButton1Click)
    print("connections count:", #conns)
    for _,c in ipairs(conns) do
        pcall(function() c:Fire() end)
    end
end

print("Trying MouseButton1Click:Fire()...")
pcall(function() cancelBtn.MouseButton1Click:Fire() end)

-- Juga coba anak-anaknya
print("Trying children...")
for _,child in ipairs(cancelBtn:GetDescendants()) do
    print("  child:", child.ClassName, child.Name)
    if child:IsA("TextButton") or child:IsA("ImageButton") then
        print("  -> clicking child", child.ClassName, child.Name)
        if firesignal then
            pcall(function() firesignal(child.MouseButton1Down) end)
            pcall(function() firesignal(child.MouseButton1Click) end)
        end
        if getconnections then
            for _,c in ipairs(getconnections(child.MouseButton1Click)) do
                pcall(function() c:Fire() end)
            end
        end
        pcall(function() child.MouseButton1Click:Fire() end)
    end
end

print("=== DONE ===")
