-- debug remote: cari RemoteEvent/Function untuk cancel mutation machine
-- Scan ReplicatedStorage + semua RemoteEvent aktif
local RS = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer
local pg = plr:FindFirstChild("PlayerGui")

print("=== DEBUG REMOTE mutation cancel ===")

-- 1. Scan ReplicatedStorage cari remote terkait mutation/cancel/confirm
print("--- ReplicatedStorage remotes ---")
for _,d in ipairs(RS:GetDescendants()) do
    if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") then
        local n = d.Name:lower()
        if n:find("mutat") or n:find("cancel") or n:find("confirm") or n:find("submit") or n:find("pet") or n:find("machine") then
            print(d.ClassName, d:GetFullName())
        end
    end
end

-- 2. Cek script LocalScript di dalam Cancel button — mungkin ada BindableEvent
print("--- Scripts di Cancel button ---")
local cancelBtn = pg
    :FindFirstChild("GenericConfirmationPrompt")
    and pg:FindFirstChild("GenericConfirmationPrompt")
    :FindFirstChild("PromptFrame")
    :FindFirstChild("Main")
    :FindFirstChild("Buttons")
    :FindFirstChild("Cancel")

if cancelBtn then
    for _,child in ipairs(cancelBtn:GetDescendants()) do
        print("  child:", child.ClassName, child.Name)
    end
    -- Cek parent PromptFrame apakah ada LocalScript
    local main = cancelBtn.Parent.Parent -- Buttons.Parent = Main
    print("  Main children:")
    for _,c in ipairs(main:GetChildren()) do
        print("    ", c.ClassName, c.Name)
    end
    local pf = main.Parent -- PromptFrame
    print("  PromptFrame children:")
    for _,c in ipairs(pf:GetChildren()) do
        print("    ", c.ClassName, c.Name)
    end
    local sg = pf.Parent -- ScreenGui
    print("  ScreenGui children:")
    for _,c in ipairs(sg:GetChildren()) do
        print("    ", c.ClassName, c.Name)
    end
end

-- 3. Coba InputBegan simulasi pada button
print("--- Try InputBegan ---")
if cancelBtn then
    pcall(function()
        local inputObj = {
            UserInputType = Enum.UserInputType.MouseButton1,
            UserInputState = Enum.UserInputState.Begin,
            Position = Vector3.new(0,0,0),
            Delta = Vector3.new(0,0,0),
            KeyCode = Enum.KeyCode.Unknown,
        }
        if firesignal then
            firesignal(cancelBtn.InputBegan, inputObj, false)
            task.wait(0.1)
            inputObj.UserInputState = Enum.UserInputState.End
            firesignal(cancelBtn.InputEnded, inputObj, false)
        end
    end)
    task.wait(0.3)
    local stillThere = pg:FindFirstChild("GenericConfirmationPrompt") ~= nil
    print("After InputBegan — dialog still exists:", stillThere)
end

print("=== DONE ===")
