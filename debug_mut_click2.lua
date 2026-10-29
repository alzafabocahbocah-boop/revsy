-- debug click v2: coba Activated + cara lain
local plr = game:GetService("Players").LocalPlayer
local pg = plr:FindFirstChild("PlayerGui")

print("=== DEBUG CLICK v2 ===")

local cancelBtn = pg
    :FindFirstChild("GenericConfirmationPrompt")
    :FindFirstChild("PromptFrame")
    :FindFirstChild("Main")
    :FindFirstChild("Buttons")
    :FindFirstChild("Cancel")

if not cancelBtn then print("Cancel NOT FOUND"); return end
print("Cancel ClassName:", cancelBtn.ClassName, "| Visible:", cancelBtn.Visible)

-- Cek semua events/connections
print("--- Connections ---")
if getconnections then
    for evtName, evt in pairs({"MouseButton1Click","MouseButton1Down","MouseButton1Up","Activated","InputBegan"}) do
        pcall(function()
            local conns = getconnections(cancelBtn[evt])
            if #conns > 0 then
                print(evt, "connections:", #conns)
            end
        end)
    end
end

-- Cara 1: firesignal Activated
print("Try firesignal Activated...")
if firesignal then
    pcall(function() firesignal(cancelBtn.Activated) end)
end
task.wait(0.5)

-- Cara 2: firesignal dengan urutan Down->Up->Click
print("Try firesignal Down->Up->Click sequence...")
if firesignal then
    pcall(function()
        firesignal(cancelBtn.MouseButton1Down, Vector2.new(0,0), true)
    end)
    task.wait(0.05)
    pcall(function()
        firesignal(cancelBtn.MouseButton1Up, Vector2.new(0,0), true)
    end)
    task.wait(0.05)
    pcall(function()
        firesignal(cancelBtn.MouseButton1Click, Vector2.new(0,0), true)
    end)
end
task.wait(0.5)

-- Cara 3: getconnections fire dengan argumen
print("Try getconnections with args...")
if getconnections then
    pcall(function()
        for _,c in ipairs(getconnections(cancelBtn.MouseButton1Click)) do
            pcall(function() c:Fire(Vector2.new(0,0), true) end)
            pcall(function() c:Fire() end)
        end
    end)
    pcall(function()
        for _,c in ipairs(getconnections(cancelBtn.Activated)) do
            pcall(function() c:Fire() end)
        end
    end)
end
task.wait(0.5)

-- Cara 4: click via InputObject simulasi
print("Try UserInputService simulasi...")
pcall(function()
    local UIS = game:GetService("UserInputService")
    if fireuserinput then
        fireuserinput(cancelBtn)
    end
end)

print("=== DONE v2 ===")
print("Dialog masih ada?")
task.wait(0.3)
local stillThere = pg:FindFirstChild("GenericConfirmationPrompt") ~= nil
print("GenericConfirmationPrompt still exists:", stillThere)
