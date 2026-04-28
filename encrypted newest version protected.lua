-- ⚠️ IMPORTANT: Put this code at the VERY TOP of your Main Script (before obfuscating) ⚠️

local ProtectionConfig = {
    -- 🔴 CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "0046",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "Life Hub"
}

-- Anti-Bypass Logic: Checks if the Key System successfully set the global variable
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n🛡️ Unauthorized Execution 🛡️\n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return -- Stops the rest of the script from loading!
end




-- [[ SERVICES & CORE ]] --
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()
local cam = workspace.CurrentCamera

-- [[ UI CLEANUP ]] --
local panelName = "LIFE_HUB_V1_0"
local targetParent = (RunService:IsStudio() and lp.PlayerGui or CoreGui)
if targetParent:FindFirstChild(panelName) then targetParent[panelName]:Destroy() end

-- [[ GLOBAL STATE ]] --
local state = {
    fly = false, flySpd = 25,
    tpSpd = 25, 
    click = false, afk = false,
    sz = false, szH = 1000, szHP = 30,
    aimbot = false, fov = true, fovR = 150, aimSmooth = 1,
    ctp = false, mini = false,
    carS = 50, carT = 2, carQ = 1000,
    esp = false
}
local platform = nil
local szDebounce = false -- Debounce to prevent double platforming

-- [[ SEARCH UTILITY ]] --
local function findDeep(name)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == name or v.Name:lower():find(name:lower()) then
            if v:IsA("Model") or v:IsA("BasePart") or v:IsA("MeshPart") then
                return v
            end
        end
    end
    return nil
end

-- [[ DRAWING API (FOV CIRCLE) ]] --
local fovCircle = nil
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Thickness = 1.5
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 1
        fovCircle.NumSides = 64
    end
end)

-- [[ UI SETUP ]] --
local sg = Instance.new("ScreenGui", targetParent)
sg.Name = panelName
sg.ResetOnSpawn = false

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 340, 0, 520) 
main.Position = UDim2.new(0.5, -170, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 40, 55)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -70, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "LIFE HUB V1.0"
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", titleBar)
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -30, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)

local miniBtn = Instance.new("TextButton", titleBar)
miniBtn.Size = UDim2.new(0, 30, 0, 30)
miniBtn.Position = UDim2.new(1, -60, 0, 0)
miniBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
miniBtn.Text = "_"
miniBtn.TextColor3 = Color3.new(1, 1, 1)

-- [[ TABS SYSTEM ]] --
local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, 0, 0, 35)
tabBar.Position = UDim2.new(0, 0, 0, 30)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)

local container = Instance.new("Frame", main)
container.Size = UDim2.new(1, 0, 1, -65)
container.Position = UDim2.new(0, 0, 0, 65)
container.BackgroundTransparency = 1

local tabs = {}
local function createTab(name, order)
    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(0.166, 0, 1, 0)
    btn.Position = UDim2.new(0.166 * (order - 1), 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = name
    btn.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 10 
    btn.BorderSizePixel = 0
    local page = Instance.new("ScrollingFrame", container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 4.5, 0)
    page.ScrollBarThickness = 3
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.p.Visible = false t.b.TextColor3 = Color3.new(0.6, 0.6, 0.6) end
        page.Visible = true
        btn.TextColor3 = Color3.new(1, 1, 1)
    end)
    tabs[name] = {b = btn, p = page}
    return page
end

local farmPage = createTab("Farm", 1)
local szPage = createTab("Safe", 2)
local carPage = createTab("Car", 3)
local tpPage = createTab("TP", 4)
local combatPage = createTab("Combat", 5)
local miscPage = createTab("Misc", 6)
tabs["Farm"].p.Visible = true

-- [[ UI BUILDERS ]] --
local function makeBtn(text, pos, color, parent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.94, 0, 0, 35)
    b.Position = UDim2.new(0.03, 0, 0, pos)
    b.BackgroundColor3 = color or Color3.fromRGB(50, 50, 65)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 14
    return b
end

local function makeSlider(text, yPos, defaultVal, min, max, parent, callback)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. defaultVal
    label.TextColor3 = Color3.new(0.9, 0.9, 1)
    label.Font = Enum.Font.SourceSansBold
    local sFrame = Instance.new("Frame", parent)
    sFrame.Size = UDim2.new(0.85, 0, 0, 4)
    sFrame.Position = UDim2.new(0.075, 0, 0, yPos + 22)
    sFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    local dot = Instance.new("TextButton", sFrame)
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new((defaultVal - min) / (max - min), -9, 0.5, -9)
    dot.Text = ""
    dot.MouseButton1Down:Connect(function()
        local move; move = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                local p = math.clamp((i.Position.X - sFrame.AbsolutePosition.X) / sFrame.AbsoluteSize.X, 0, 1)
                dot.Position = UDim2.new(p, -9, 0.5, -9)
                local val = math.floor(min + (p * (max - min)))
                label.Text = text .. ": " .. val
                callback(val)
            end
        end)
        local release; release = UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then move:Disconnect() release:Disconnect() end
        end)
    end)
end

-- [[ FARM TAB ]] --
local flyB = makeBtn("Parts Farm: OFF", 10, nil, farmPage)
flyB.MouseButton1Click:Connect(function()
    state.fly = not state.fly
    flyB.Text = "Parts Farm: " .. (state.fly and "ON" or "OFF")
    if state.fly then
        task.spawn(function()
            local i = 1
            while state.fly do
                pcall(function()
                    local loot = workspace.SpawnsLoot:GetChildren()
                    if #loot > 0 then
                        if i > #loot then i = 1 end
                        local target = loot[i]
                        if target and target.Parent then
                            local r = lp.Character.HumanoidRootPart
                            local targetPos = target:GetPivot() + Vector3.new(0, 5, 0)
                            TweenService:Create(r, TweenInfo.new((r.Position - targetPos.Position).Magnitude/state.flySpd, Enum.EasingStyle.Linear), {CFrame = targetPos}):Play()
                            task.wait(1.2)
                        end
                        i = i + 1
                    else task.wait(1) end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

local autoEB = makeBtn("Auto-Interact (E): OFF", 55, nil, farmPage)
autoEB.MouseButton1Click:Connect(function() state.click = not state.click autoEB.Text = "Auto-Interact (E): " .. (state.click and "ON" or "OFF") end)

local espB = makeBtn("Part ESP: OFF", 100, Color3.fromRGB(60, 60, 30), farmPage)
espB.MouseButton1Click:Connect(function()
    state.esp = not state.esp
    espB.Text = "Part ESP: " .. (state.esp and "ON" or "OFF")
    if state.esp then
        task.spawn(function()
            while state.esp do
                for _, v in pairs(workspace.SpawnsLoot:GetChildren()) do
                    if not v:FindFirstChild("LootHighlight") then
                        local h = Instance.new("Highlight", v)
                        h.Name = "LootHighlight"
                        h.FillColor = Color3.new(1, 1, 0)
                    end
                end
                task.wait(1)
            end
            for _, v in pairs(workspace:GetDescendants()) do if v.Name == "LootHighlight" then v:Destroy() end end
        end)
    end
end)
makeSlider("Fly Speed", 150, 25, 10, 150, farmPage, function(v) state.flySpd = v end)

-- [[ SAFE TAB ]] --
local szB = makeBtn("Safe Zone: OFF", 10, Color3.fromRGB(80, 40, 80), szPage)
szB.MouseButton1Click:Connect(function()
    state.sz = not state.sz
    szB.Text = "Safe Zone: " .. (state.sz and "ON" or "OFF")
    if not state.sz and platform then 
        lp.Character.HumanoidRootPart.CFrame -= Vector3.new(0, state.szH, 0) 
        platform:Destroy() 
        platform = nil 
        szDebounce = false
    end
end)
makeSlider("SZ Height", 60, 1000, 100, 5000, szPage, function(v) state.szH = v end)
makeSlider("Trigger HP", 110, 30, 5, 95, szPage, function(v) state.szHP = v end)

-- [[ CAR TAB ]] --
makeSlider("Car Speed", 10, 50, 10, 1000, carPage, function(v) state.carS = v end)
makeSlider("Car Turn", 60, 2, 1, 100, carPage, function(v) state.carT = v end)
makeSlider("Car Torque", 110, 1000, 500, 10000, carPage, function(v) state.carQ = v end)
makeBtn("Apply Car Mods", 160, Color3.fromRGB(100, 50, 50), carPage).MouseButton1Click:Connect(function()
    pcall(function() 
        local d = workspace.Vehicles[lp.Name].CarStats.DrivingStats 
        d.Speed.Value = state.carS 
        d.TurnSpeed.Value = state.carT 
        d.Torque.Value = state.carQ 
    end)
end)

-- [[ TP TAB ]] --
makeBtn("House [SAFE]", 10, Color3.fromRGB(40, 70, 40), tpPage).MouseButton1Click:Connect(function()
    local o = findDeep("HouseType3")
    if o then 
        local t = o:GetPivot() + Vector3.new(0,7,0) 
        TweenService:Create(lp.Character.HumanoidRootPart, TweenInfo.new((lp.Character.HumanoidRootPart.Position - t.Position).Magnitude/state.tpSpd, Enum.EasingStyle.Linear), {CFrame = t}):Play() 
    end
end)
makeBtn("House [RISKY]", 55, Color3.fromRGB(120, 40, 40), tpPage).MouseButton1Click:Connect(function() 
    local o = findDeep("HouseType3") if o then lp.Character.HumanoidRootPart.CFrame = o:GetPivot() + Vector3.new(0,5,0) end
end)
makeBtn("Work Bench [SAFE]", 100, Color3.fromRGB(40, 70, 40), tpPage).MouseButton1Click:Connect(function()
    local o = findDeep("WorkBench") or findDeep("Workbench") or findDeep("Bench")
    if o then 
        local t = o:GetPivot() + Vector3.new(0,7,0) 
        TweenService:Create(lp.Character.HumanoidRootPart, TweenInfo.new((lp.Character.HumanoidRootPart.Position - t.Position).Magnitude/state.tpSpd, Enum.EasingStyle.Linear), {CFrame = t}):Play() 
    end
end)
makeBtn("Work Bench [RISKY]", 145, Color3.fromRGB(120, 40, 40), tpPage).MouseButton1Click:Connect(function() 
    local o = findDeep("WorkBench") or findDeep("Workbench") or findDeep("Bench")
    if o then lp.Character.HumanoidRootPart.CFrame = o:GetPivot() + Vector3.new(0,5,0) end
end)
local ctpBtn = makeBtn("Click TP (Ctrl+LMB): OFF", 190, nil, tpPage)
ctpBtn.MouseButton1Click:Connect(function() state.ctp = not state.ctp ctpBtn.Text = "Click TP: " .. (state.ctp and "ON" or "OFF") end)

-- [[ COMBAT TAB ]] --
local aimB = makeBtn("Aimbot: OFF", 10, Color3.fromRGB(40, 60, 60), combatPage)
aimB.MouseButton1Click:Connect(function() state.aimbot = not state.aimbot aimB.Text = "Aimbot: " .. (state.aimbot and "ON" or "OFF") end)
makeSlider("FOV Radius", 60, 150, 10, 800, combatPage, function(v) state.fovR = v end)
makeSlider("Aim Smooth", 110, 1, 1, 50, combatPage, function(v) state.aimSmooth = v end)

-- [[ MISC TAB ]] --
local afkB = makeBtn("Anti-AFK: OFF", 10, Color3.fromRGB(40, 80, 40), miscPage)
afkB.MouseButton1Click:Connect(function() state.afk = not state.afk afkB.Text = "Anti-AFK: " .. (state.afk and "ON" or "OFF") end)

-- [[ LOOP LOGIC ]] --
lp.Idled:Connect(function() 
    if state.afk then 
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) 
        task.wait(0.1) 
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) 
    end 
end)

local function getBestTarget()
    local target, near = nil, state.fovR
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            local aim = v.Character.HumanoidRootPart
            local pos, vis = cam:WorldToViewportPoint(aim.Position)
            if vis then
                local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mag < near then near = mag target = aim end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function() 
    if fovCircle then fovCircle.Visible = state.aimbot and state.fov fovCircle.Radius = state.fovR fovCircle.Position = UserInputService:GetMouseLocation() end 
    if state.aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, t.Position), 1 / state.aimSmooth) end
    end
end)

RunService.Heartbeat:Connect(function()
    if state.sz then
        pcall(function()
            local h = lp.Character.Humanoid
            local r = lp.Character.HumanoidRootPart
            
            if platform and h.Health >= 50 then 
                r.CFrame -= Vector3.new(0, state.szH, 0) 
                platform:Destroy() 
                platform = nil 
                szDebounce = false -- Reset for next use
            end

            -- Debounce check to ensure strict single-platform creation
            if not platform and not szDebounce and h.Health < state.szHP then
                szDebounce = true
                r.CFrame += Vector3.new(0, state.szH, 0)
                local p = Instance.new("Part")
                p.Name = "SafeZonePlatform"
                p.Size = Vector3.new(20000, 5, 20000) 
                p.Transparency = 0.9
                p.Position = r.Position - Vector3.new(0,4,0) 
                p.Anchored = true
                p.Parent = workspace
                platform = p
            end
        end)
    end
end)

mouse.Button1Down:Connect(function() if state.ctp and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then pcall(function() lp.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0, 3, 0)) end) end end)

task.spawn(function()
    while task.wait(1.5) do
        if state.click then pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.05) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) end
    end
end)

miniBtn.MouseButton1Click:Connect(function() state.mini = not state.mini main:TweenSize(state.mini and UDim2.new(0, 340, 0, 30) or UDim2.new(0, 340, 0, 520), "Out", "Quad", 0.3, true) end)
close.MouseButton1Click:Connect(function() if fovCircle then fovCircle:Remove() end sg:Destroy() end)
