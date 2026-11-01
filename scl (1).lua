-- Evade Hub: Advanced Strafe Acceleration + High Jump & Speed-Based High Launch Screen Freeze Lagswitch + Auto Crouch

for _, ui in ipairs({"EvadeSpeedVectorUI", "EvadeAutoTrimpFixedUI", "EvadeVerticalHubUI", "EvadeInfiniteHubUI", "EvadeSettingsHubUI", "EvadeDragonHubUI", "EvadeFarmHubUI", "EvadeSmartFarmHubUI", "EvadeUltimateFarmUI", "EvadeInstantFarmUI", "EvadeDeepFarmUI", "EvadeFullHubUI", "EvadeSyncFarmUI", "EvadeDeepTicketUI", "EvadeInstantSnapUI", "EvadeSimultaneousUI", "EvadeStrafeSpeedUI", "EvadeStrafeAccelUI"}) do
    if game:GetService("CoreGui"):FindFirstChild(ui) then
        game:GetService("CoreGui")[ui]:Destroy()
    end
end
if game:GetService("CoreGui"):FindFirstChild("EvadeAllToggle") then
    game:GetService("CoreGui").EvadeAllToggle:Destroy()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- --- BIẾN CẤU HÌNH ---
local systemEnabled = false   
local bhopActive = false      
local infiniteJumpActive = false 
local lagSwitchActive = false
local lagDelay = 0.2          
local lagKey = Enum.KeyCode.X  
local isMiddleMouseBound = true 

local autoReviveActive = false 
local wallToggleActive = false 
local cachedWalls = {}         
local currentTrack = nil

-- Biến Cài đặt Icon & Kéo thả
local moveIconEnabled = false

-- Biến Auto Farm
local autoFarmTicketActive = false
local autoFarmMoneyActive = false
local safeAutoFarmActive = false

-- Biến Keybind cho Inviswalls & Auto Crouch
local invisWallKey = Enum.KeyCode.Z
local autoCrouchActive = false
local autoCrouchKey = Enum.KeyCode.C

-- Biến Auto Edge Trimp
local autoTrimpActive = false
local lastLaunchTime = 0
local trimpPower = 1.2

-- Biến Tab Speed & Height
local speedToggleActive = false
local customWalkSpeed = 33.3
local currentStrafeBoost = 0

local jumpToggleActive = false
local customJumpPower = 50 
local originalJumpPower = 7.2

-- Biến Tab Fake CO (Visual Cosmetics)
local fakeHeadlessActive = false
local fakeKorbloxActive = false

-- Biến Hiệu ứng Toxic Inferno
local toxicInfernoActive = false

-- --- TỪ ĐIỂN EMOTE EVADE ---
local gameEmotes = {
    ["kickback"] = "rbxassetid://507771019",
    ["rockinstride"] = "rbxassetid://507771019",
    ["doomboom"] = "rbxassetid://10214311282",
    ["slickdance"] = "rbxassetid://507772104",
    ["flossdance"] = "rbxassetid://591745973",
    ["californiagurls"] = "rbxassetid://507771955",
    ["distraction"] = "rbxassetid://591745973",
    ["catjam"] = "rbxassetid://507772104",
    ["outlaw"] = "rbxassetid://507772104",
    ["banger"] = "rbxassetid://33379665",
    ["zenserenity"] = "rbxassetid://507771019"
}

-- --- HÀM THÔNG BÁO HUB ---
local function notifyStatus(text, color)
    local sg = CoreGui:FindFirstChild("EvadeNotify") or Instance.new("ScreenGui", CoreGui)
    sg.Name = "EvadeNotify"
    
    local txt = sg:FindFirstChild("NotifyText") or Instance.new("TextLabel", sg)
    txt.Name = "NotifyText"
    txt.Size = UDim2.new(0, 260, 0, 30)
    txt.Position = UDim2.new(0.5, -130, 0.12, 0)
    txt.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    txt.TextColor3 = color
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 14
    txt.Text = text
    txt.Visible = true
    
    task.spawn(function()
        task.wait(2)
        if txt.Text == text then txt.Visible = false end
    end)
end

local function cleanString(str)
    return string.lower(str:gsub("%s+", ""):gsub("%W", ""))
end

local function playFixedEmote(selRaw)
    local cleanSel = cleanString(selRaw)
    local targetAnimId = gameEmotes[cleanSel] or "rbxassetid://507771019"
    
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
            if currentTrack then pcall(function() currentTrack:Stop() end) end
            
            local anim = Instance.new("Animation")
            anim.AnimationId = targetAnimId
            pcall(function()
                currentTrack = animator:LoadAnimation(anim)
                currentTrack.Priority = Enum.AnimationPriority.Action4
                currentTrack:Play()
                notifyStatus("VISUAL EMOTE: " .. string.upper(cleanSel), Color3.fromRGB(50, 255, 50))
            end)
        end
    end
end

-- --- HÀM XÓA TƯỜNG TÀNG HÌNH ---
local function toggleInvisWallsState(forceState)
    if forceState ~= nil then
        wallToggleActive = forceState
    else
        wallToggleActive = not wallToggleActive
    end

    if wallToggleActive then
        cachedWalls = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency >= 0.99 and obj.CanCollide and not obj.Parent:FindFirstChildOfClass("Humanoid") then
                table.insert(cachedWalls, {Part = obj, OriginalCanCollide = obj.CanCollide})
                obj.CanCollide = false
            end
        end
        notifyStatus("XÓA TƯỜNG TÀNG HÌNH: ON", Color3.fromRGB(50, 255, 50))
    else
        for _, item in ipairs(cachedWalls) do
            if item.Part and item.Part.Parent then item.Part.CanCollide = item.OriginalCanCollide end
        end
        cachedWalls = {}
        notifyStatus("XÓA TƯỜNG TÀNG HÌNH: OFF", Color3.fromRGB(255, 50, 50))
    end
end

-- --- LAGSWITCH ---
local function triggerLagSwitch()
    if lagSwitchActive then return end
    lagSwitchActive = true
    
    task.spawn(function()
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid then
                local speedBefore = hrp.AssemblyLinearVelocity
                local speedMagnitude = speedBefore.Magnitude
                local originalWalkSpeed = humanoid.WalkSpeed
                local originalJumpPower = humanoid.JumpPower
                
                local launchUpPower = math.clamp(speedMagnitude * 1.35 + 2.4, 2.4, 180)
                
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.8, 0)
                hrp.Anchored = true
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                
                local freezeStartTime = tick()
                while tick() - freezeStartTime < lagDelay do
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.RotVelocity = Vector3.zero
                    RunService.RenderStepped:Wait()
                end
                
                hrp.Anchored = false
                humanoid.WalkSpeed = originalWalkSpeed
                humanoid.JumpPower = originalJumpPower
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                
                hrp.AssemblyLinearVelocity = Vector3.new(speedBefore.X * 1.1, launchUpPower, speedBefore.Z * 1.1)
            end
        end
        lagSwitchActive = false
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.B and systemEnabled then
        bhopActive = not bhopActive
        notifyStatus(bhopActive and "AUTO BHOP: ON (B)" or "AUTO BHOP: OFF (B)", bhopActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
    end
    if input.KeyCode == lagKey or (isMiddleMouseBound and input.UserInputType == Enum.UserInputType.MouseButton3) then
        triggerLagSwitch()
    end
    if input.KeyCode == invisWallKey then
        toggleInvisWallsState()
    end
    if input.KeyCode == autoCrouchKey then
        autoCrouchActive = not autoCrouchActive
        notifyStatus(autoCrouchActive and "AUTO CROUCH: ON" or "AUTO CROUCH: OFF", autoCrouchActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpActive then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- --- VÒNG LẶP AUTO CROUCH (SPAM CTRL) ---
task.spawn(function()
    while true do
        task.wait(0.08)
        if autoCrouchActive then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.04)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            end)
        end
    end
end)

-- --- QUẢN LÝ GREEN FIRE AURA ---
local function toggleToxicFireAura(state)
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local existingFire = head:FindFirstChild("ToxicInfernoFire")
    if state then
        if not existingFire then
            local fire = Instance.new("Fire")
            fire.Name = "ToxicInfernoFire"
            fire.Color = Color3.fromRGB(0, 255, 80)
            fire.SecondaryColor = Color3.fromRGB(150, 255, 0)
            fire.Size = 6
            fire.Heat = 9
            fire.Parent = head
        end
    else
        if existingFire then
            existingFire:Destroy()
        end
    end
end

-- --- FAKE COSMETICS R15 ---
local function applyCustomCosmeticsToCharacter(char)
    if not char then return end

    local head = char:FindFirstChild("Head")
    if head and fakeHeadlessActive then
        head.Transparency = 1
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child.Transparency = 1
            end
        end
    end

    if fakeKorbloxActive then
        local rightLowerLeg = char:FindFirstChild("RightLowerLeg")
        if rightLowerLeg and rightLowerLeg:IsA("MeshPart") then
            rightLowerLeg.MeshId = "rbxassetid://902942093"
            rightLowerLeg.TextureID = "rbxassetid://902829924"
        end
        local rightFoot = char:FindFirstChild("RightFoot")
        if rightFoot and rightFoot:IsA("MeshPart") then
            rightFoot.Transparency = 1
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        originalJumpPower = humanoid.JumpPower
    end
    if toxicInfernoActive then
        toggleToxicFireAura(true)
    end
    applyCustomCosmeticsToCharacter(char)
end)

if LocalPlayer.Character then
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        originalJumpPower = humanoid.JumpPower
    end
    applyCustomCosmeticsToCharacter(LocalPlayer.Character)
end

-- --- VÒNG LẶP AUTO FARM TICKET & VOID PHỐI HỢP ---
task.spawn(function()
    while true do
        task.wait(0.1)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local didAction = false
            
            if autoFarmTicketActive then
                local foundTicket = false
                local targetPrompt = nil
                local targetPos = nil

                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if not autoFarmTicketActive then break end
                    if prompt:IsA("ProximityPrompt") then
                        local parent = prompt.Parent
                        local parentName = string.lower(parent and parent.Name or "")
                        local promptText = string.lower(prompt.ObjectText .. prompt.ActionText)
                        
                        if parentName:find("ticket") or parentName:find("candy") or parentName:find("event") or parentName:find("collectible") or parentName:find("pumpkin") or parentName:find("wisp") or parentName:find("gift") or
                           promptText:find("ticket") or promptText:find("candy") or promptText:find("event") or promptText:find("collect") or promptText:find("take") then
                            
                            local pos = parent:IsA("BasePart") and parent.Position or (parent:IsA("Model") and parent:GetPivot().Position)
                            if pos then
                                foundTicket = true
                                targetPrompt = prompt
                                targetPos = pos
                                break
                            end
                        end
                    end
                end

                if foundTicket and targetPos then
                    hrp.Anchored = false
                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 1.5, 0))
                    
                    task.wait(0.05)
                    pcall(function() fireproximityprompt(targetPrompt) end)
                    
                    pcall(function()
                        local events = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage
                        for _, ev in ipairs(events:GetDescendants()) do
                            if ev:IsA("RemoteEvent") and (string.lower(ev.Name):find("ticket") or string.lower(ev.Name):find("collect") or string.lower(ev.Name):find("event")) then
                                ev:FireServer()
                            end
                        end
                    end)
                    
                    didAction = true
                    task.wait(1.0)
                    
                    if safeAutoFarmActive then
                        hrp.CFrame = CFrame.new(0, 20000, 0)
                        hrp.Anchored = true
                        pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
                    end
                end
            end
            
            if not didAction and autoFarmMoneyActive then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local isDowned = hum and (hum.Health <= 0 or p.Character:FindFirstChild("Downed") or p.Character:FindFirstChild("IsDowned"))
                        
                        if isDowned and targetHrp then
                            hrp.Anchored = false
                            hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 1.5, 0)
                            for _, prompt in ipairs(p.Character:GetDescendants()) do
                                if prompt:IsA("ProximityPrompt") then
                                    pcall(function() fireproximityprompt(prompt) end)
                                end
                            end
                            pcall(function()
                                local revEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Revive")
                                if revEvent then revEvent:FireServer(p.Name) end
                            end)
                            didAction = true
                            task.wait(0.25)
                            break
                        end
                    end
                end
            end
            
            if not didAction and safeAutoFarmActive then
                hrp.CFrame = CFrame.new(0, 20000, 0)
                hrp.Anchored = true
                pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
            else
                if not safeAutoFarmActive and hrp.Anchored and not autoFarmTicketActive and not autoFarmMoneyActive and not lagSwitchActive then
                    hrp.Anchored = false
                end
            end
        end
    end
end)

-- --- VÒNG LẶP RENDERSTEPPED ---
local lastMoveDir = Vector3.zero
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char or lagSwitchActive then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if fakeHeadlessActive then
        local head = char:FindFirstChild("Head")
        if head and head.Transparency ~= 1 then head.Transparency = 1 end
    end

    if fakeKorbloxActive then
        local rightLowerLeg = char:FindFirstChild("RightLowerLeg")
        if rightLowerLeg and rightLowerLeg:IsA("MeshPart") then
            if rightLowerLeg.MeshId ~= "rbxassetid://902942093" then
                rightLowerLeg.MeshId = "rbxassetid://902942093"
                rightLowerLeg.TextureID = "rbxassetid://902829924"
            end
        end
    end

    if speedToggleActive and humanoid and hrp and humanoid.Health > 0 then
        local moveDir = humanoid.MoveDirection
        local currentVel = hrp.AssemblyLinearVelocity
        
        if moveDir.Magnitude > 0 then
            local angleChange = 0
            if lastMoveDir.Magnitude > 0 then
                local dot = math.clamp(lastMoveDir:Dot(moveDir), -1, 1)
                angleChange = math.acos(dot)
            end
            
            if angleChange > 0.05 then
                currentStrafeBoost = math.min(currentStrafeBoost + (angleChange * 4), 25)
            else
                currentStrafeBoost = math.max(currentStrafeBoost - 0.2, 0)
            end
            
            lastMoveDir = moveDir
            local totalSpeed = customWalkSpeed + currentStrafeBoost
            local targetVel = moveDir * totalSpeed
            
            hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, currentVel.Y, targetVel.Z)
        else
            currentStrafeBoost = 0
            lastMoveDir = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X * 0.98, currentVel.Y, currentVel.Z * 0.98)
        end
    else
        currentStrafeBoost = 0
        lastMoveDir = Vector3.zero
    end

    if jumpToggleActive and humanoid and humanoid.Health > 0 then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = customJumpPower
    end

    if systemEnabled and bhopActive and humanoid and humanoid.Health > 0 then
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    
    if autoReviveActive and humanoid and humanoid.Health <= 0 then
        pcall(function()
            humanoid.Health = humanoid.MaxHealth
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    
    if autoTrimpActive and hrp and humanoid and humanoid.Health > 0 then
        if tick() - lastLaunchTime > 0.25 then
            local rayParams = RaycastParams.new()
            rayParams.FilterAncestorsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local rayForward = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3, rayParams)
            if rayForward and rayForward.Normal then
                local normal = rayForward.Normal
                if normal.Y > 0.05 and normal.Y < 0.9 then
                    lastLaunchTime = tick()
                    local currentVel = hrp.AssemblyLinearVelocity
                    local forwardSpeed = math.max(currentVel.Magnitude, 30)
                    
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    local launchDirection = (hrp.CFrame.LookVector + Vector3.new(0, normal.Y * 1.2, 0)).Unit
                    hrp.AssemblyLinearVelocity = launchDirection * (forwardSpeed * trimpPower)
                    
                    notifyStatus("🚀 AUTO TRIMP ACTIVATED!", Color3.fromRGB(0, 255, 255))
                end
            end
        end
    end
end)

-- -----------------------------------------------------------------------------
-- GIAO DIỆN TABBED GUI
-- -----------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EvadeStrafeAccelUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.25, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 480, 0, 380)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "EVADE HUB | STRAFE ACCELERATION"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 14

local TabBar = Instance.new("Frame")
TabBar.Parent = MainFrame
TabBar.Position = UDim2.new(0, 0, 0, 35)
TabBar.Size = UDim2.new(0, 110, 1, -35)
TabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabBar
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 2)

local function createTabBtn(name)
    local btn = Instance.new("TextButton")
    btn.Parent = TabBar
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    return btn
end

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.Position = UDim2.new(0, 115, 0, 40)
ContentContainer.Size = UDim2.new(1, -120, 1, -45)
ContentContainer.BackgroundTransparency = 1

local function createContentFrame()
    local f = Instance.new("ScrollingFrame")
    f.Parent = ContentContainer
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.CanvasSize = UDim2.new(0, 0, 1.8, 0)
    f.ScrollBarThickness = 5
    local l = Instance.new("UIListLayout")
    l.Parent = f
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 8)
    f.Visible = false
    return f
end

local TabMain = createContentFrame()
local TabFarm = createContentFrame()
local TabLag = createContentFrame()
local TabVisual = createContentFrame()
local TabSpeedHeight = createContentFrame()
local TabFakeCO = createContentFrame()
local TabRevive = createContentFrame()
local TabEffects = createContentFrame()
local TabFPS = createContentFrame()
local TabSetting = createContentFrame()

TabMain.Visible = true

local btnMain = createTabBtn("MAIN")
local btnFarm = createTabBtn("🌽 FARM")
local btnLag = createTabBtn("LAG")
local btnVisual = createTabBtn("VISUAL")
local btnSpeedHeight = createTabBtn("SPEED")
local btnFakeCO = createTabBtn("FAKE CO")
local btnRevive = createTabBtn("REVIVE")
local btnEffects = createTabBtn("EFFECTS")
local btnFPS = createTabBtn("FPS")
local btnSetting = createTabBtn("SETTING")

local function switchTab(activeBtn, activeFrame)
    TabMain.Visible = false; TabFarm.Visible = false; TabLag.Visible = false; TabVisual.Visible = false; TabSpeedHeight.Visible = false; TabFakeCO.Visible = false; TabRevive.Visible = false; TabEffects.Visible = false; TabFPS.Visible = false; TabSetting.Visible = false
    btnMain.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnFarm.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnLag.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnVisual.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnSpeedHeight.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnFakeCO.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnRevive.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnEffects.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnFPS.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btnSetting.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    
    activeFrame.Visible = true
    activeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
end

btnMain.MouseButton1Click:Connect(function() switchTab(btnMain, TabMain) end)
btnFarm.MouseButton1Click:Connect(function() switchTab(btnFarm, TabFarm) end)
btnLag.MouseButton1Click:Connect(function() switchTab(btnLag, TabLag) end)
btnVisual.MouseButton1Click:Connect(function() switchTab(btnVisual, TabVisual) end)
btnSpeedHeight.MouseButton1Click:Connect(function() switchTab(btnSpeedHeight, TabSpeedHeight) end)
btnFakeCO.MouseButton1Click:Connect(function() switchTab(btnFakeCO, TabFakeCO) end)
btnRevive.MouseButton1Click:Connect(function() switchTab(btnRevive, TabRevive) end)
btnEffects.MouseButton1Click:Connect(function() switchTab(btnEffects, TabEffects) end)
btnFPS.MouseButton1Click:Connect(function() switchTab(btnFPS, TabFPS) end)
btnSetting.MouseButton1Click:Connect(function() switchTab(btnSetting, TabSetting) end)

btnMain.BackgroundColor3 = Color3.fromRGB(0, 120, 215)

local function addBtn(parent, text, color, cb)
    local b = Instance.new("TextButton")
    b.Parent = parent
    b.Size = UDim2.new(0.96, 0, 0, 35)
    b.BackgroundColor3 = color
    b.Font = Enum.Font.SourceSansBold
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 12
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

-- --- TAB FARM ---
local FarmTitle = Instance.new("TextLabel")
FarmTitle.Parent = TabFarm
FarmTitle.Size = UDim2.new(0.96, 0, 0, 25)
FarmTitle.BackgroundTransparency = 1
FarmTitle.Font = Enum.Font.SourceSansBold
FarmTitle.Text = "🎃 FARM TICKET & NÉ BOT"
FarmTitle.TextColor3 = Color3.fromRGB(255, 170, 0)
FarmTitle.TextSize = 12

addBtn(TabFarm, "🎟️ AUTO FARM TICKET / KẸO: OFF", Color3.fromRGB(180, 50, 50), function(b)
    autoFarmTicketActive = not autoFarmTicketActive
    b.Text = autoFarmTicketActive and "🎟️ AUTO FARM TICKET / KẸO: ON" or "🎟️ AUTO FARM TICKET / KẸO: OFF"
    b.BackgroundColor3 = autoFarmTicketActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(autoFarmTicketActive and "FARM TICKET / KẸO: BẬT" or "FARM TICKET / KẸO: TẮT", autoFarmTicketActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

addBtn(TabFarm, "💰 AUTO FARM MONEY (CỨU NGƯỜI): OFF", Color3.fromRGB(180, 50, 50), function(b)
    autoFarmMoneyActive = not autoFarmMoneyActive
    b.Text = autoFarmMoneyActive and "💰 AUTO FARM MONEY: ON" or "💰 AUTO FARM MONEY (CỨU NGƯỜI): OFF"
    b.BackgroundColor3 = autoFarmMoneyActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(autoFarmMoneyActive and "FARM MONEY (CỨU): BẬT" or "FARM MONEY (CỨU): TẮT", autoFarmMoneyActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

addBtn(TabFarm, "🛡️ SAFE AUTO FARM (TRỐN VOID 20K): OFF", Color3.fromRGB(180, 50, 50), function(b)
    safeAutoFarmActive = not safeAutoFarmActive
    b.Text = safeAutoFarmActive and "🛡️ SAFE AUTO FARM: ON" or "🛡️ SAFE AUTO FARM (TRỐN VOID): OFF"
    b.BackgroundColor3 = safeAutoFarmActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(safeAutoFarmActive and "SAFE FARM 20K: BẬT" or "SAFE FARM: TẮT", safeAutoFarmActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

-- --- TAB LAGSWITCH ---
local LagTitle = Instance.new("TextLabel")
LagTitle.Parent = TabLag
LagTitle.Size = UDim2.new(0.96, 0, 0, 25)
LagTitle.BackgroundTransparency = 1
LagTitle.Font = Enum.Font.SourceSansBold
LagTitle.Text = "CÀI ĐẶT LAGSWITCH"
LagTitle.TextColor3 = Color3.fromRGB(255, 170, 0)
LagTitle.TextSize = 13

local InputMS = Instance.new("TextBox")
InputMS.Parent = TabLag
InputMS.Size = UDim2.new(0.96, 0, 0, 35)
InputMS.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputMS.Font = Enum.Font.SourceSansBold
InputMS.PlaceholderText = "Nhập MS (vd: 150, 200, 300)"
InputMS.Text = "200"
InputMS.TextColor3 = Color3.fromRGB(255, 255, 255)
InputMS.TextSize = 12

local InputKey = Instance.new("TextBox")
InputKey.Parent = TabLag
InputKey.Size = UDim2.new(0.96, 0, 0, 35)
InputKey.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputKey.Font = Enum.Font.SourceSansBold
InputKey.PlaceholderText = "Nút bấm (MD hoặc X)"
InputKey.Text = "MD"
InputKey.TextColor3 = Color3.fromRGB(255, 255, 255)
InputKey.TextSize = 12

addBtn(TabLag, "LƯU CÀI ĐẶT LAGSWITCH", Color3.fromRGB(0, 120, 215), function()
    local msVal = tonumber(InputMS.Text)
    if msVal then 
        lagDelay = math.clamp(msVal, 1, 5000) / 1000 
    end
    local keyStr = string.upper(InputKey.Text:gsub("%s+", ""))
    if keyStr == "MD" or keyStr == "MB3" then
        isMiddleMouseBound = true
        InputKey.Text = "MD"
    else
        isMiddleMouseBound = false
        pcall(function()
            lagKey = Enum.KeyCode[keyStr:sub(1,1)]
            InputKey.Text = keyStr:sub(1,1)
        end)
    end
    notifyStatus("ĐÃ LƯU MS: " .. (lagDelay * 1000) .. "ms!", Color3.fromRGB(0, 255, 255))
end)

-- --- TAB SETTING ---
local SettingTitle = Instance.new("TextLabel")
SettingTitle.Parent = TabSetting
SettingTitle.Size = UDim2.new(0.96, 0, 0, 25)
SettingTitle.BackgroundTransparency = 1
SettingTitle.Font = Enum.Font.SourceSansBold
SettingTitle.Text = "⚙️ CÀI ĐẶT GIAO DIỆN & PHÍM TẮT"
SettingTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
SettingTitle.TextSize = 12

addBtn(TabSetting, "🔒 KÉO THẢ ICON RỒNG: OFF", Color3.fromRGB(180, 50, 50), function(b)
    moveIconEnabled = not moveIconEnabled
    b.Text = moveIconEnabled and "🔓 KÉO THẢ ICON RỒNG: ON" or "🔒 KÉO THẢ ICON RỒNG: OFF"
    b.BackgroundColor3 = moveIconEnabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(moveIconEnabled and "ĐÃ MỞ KHÓA KÉO THẢ ICON!" or "ĐÃ KHÓA KÉO THẢ ICON!", moveIconEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

local KeybindBox = Instance.new("TextBox")
KeybindBox.Parent = TabSetting
KeybindBox.Size = UDim2.new(0.96, 0, 0, 35)
KeybindBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeybindBox.Font = Enum.Font.SourceSansBold
KeybindBox.PlaceholderText = "Nhập phím cho Inviswalls (vd: Z)"
KeybindBox.Text = "Z"
KeybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindBox.TextSize = 12

addBtn(TabSetting, "LƯU PHÍM TẮT INVISWALLS", Color3.fromRGB(0, 120, 215), function()
    local keyStr = string.upper(KeybindBox.Text:gsub("%s+", ""))
    if #keyStr > 0 then
        pcall(function()
            invisWallKey = Enum.KeyCode[keyStr:sub(1,1)]
            notifyStatus("ĐÃ ĐỔI PHÍM INVISWALLS: " .. keyStr:sub(1,1), Color3.fromRGB(50, 255, 50))
        end)
    end
end)

local CrouchKeyBox = Instance.new("TextBox")
CrouchKeyBox.Parent = TabSetting
CrouchKeyBox.Size = UDim2.new(0.96, 0, 0, 35)
CrouchKeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CrouchKeyBox.Font = Enum.Font.SourceSansBold
CrouchKeyBox.PlaceholderText = "Nhập phím bật Auto Crouch (vd: C)"
CrouchKeyBox.Text = "C"
CrouchKeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CrouchKeyBox.TextSize = 12

addBtn(TabSetting, "LƯU PHÍM BẬT AUTO CROUCH", Color3.fromRGB(0, 120, 215), function()
    local keyStr = string.upper(CrouchKeyBox.Text:gsub("%s+", ""))
    if #keyStr > 0 then
        pcall(function()
            autoCrouchKey = Enum.KeyCode[keyStr:sub(1,1)]
            notifyStatus("ĐÃ ĐỔI PHÍM AUTO CROUCH: " .. keyStr:sub(1,1), Color3.fromRGB(50, 255, 50))
        end)
    end
end)

local ThemeTitle = Instance.new("TextLabel")
ThemeTitle.Parent = TabSetting
ThemeTitle.Size = UDim2.new(0.96, 0, 0, 25)
ThemeTitle.BackgroundTransparency = 1
ThemeTitle.Font = Enum.Font.SourceSansBold
ThemeTitle.Text = "🎨 ĐỔI MÀU BACKGROUND GIAO DIỆN"
ThemeTitle.TextColor3 = Color3.fromRGB(255, 100, 255)
ThemeTitle.TextSize = 12

addBtn(TabSetting, "⚫ NỀN ĐEN MẶC ĐỊNH", Color3.fromRGB(30, 30, 30), function()
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    notifyStatus("ĐÃ CHUYỂN NỀN: ĐEN", Color3.fromRGB(255, 255, 255))
end)

addBtn(TabSetting, "🔴 NỀN ĐỎ HUYẾT", Color3.fromRGB(150, 30, 30), function()
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
    TabBar.BackgroundColor3 = Color3.fromRGB(25, 10, 10)
    Title.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
    notifyStatus("ĐÃ CHUYỂN NỀN: ĐỎ", Color3.fromRGB(255, 100, 100))
end)

addBtn(TabSetting, "🌸 NỀN HỒNG DỄ THƯƠNG", Color3.fromRGB(180, 80, 150), function()
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 35)
    TabBar.BackgroundColor3 = Color3.fromRGB(30, 15, 25)
    Title.BackgroundColor3 = Color3.fromRGB(60, 30, 50)
    notifyStatus("ĐÃ CHUYỂN NỀN: HỒNG", Color3.fromRGB(255, 150, 220))
end)

addBtn(TabSetting, "🟣 NỀN TÍM HUYỀN BÍ", Color3.fromRGB(100, 50, 180), function()
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
    TabBar.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    Title.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    notifyStatus("ĐÃ CHUYỂN NỀN: TÍM", Color3.fromRGB(200, 150, 255))
end)

-- --- TAB MAIN ---
addBtn(TabMain, "🤖 AUTO CROUCH (SPAM CTRL): OFF", Color3.fromRGB(180, 50, 50), function(b)
    autoCrouchActive = not autoCrouchActive
    b.Text = autoCrouchActive and "🤖 AUTO CROUCH: ON (C)" or "🤖 AUTO CROUCH (SPAM CTRL): OFF"
    b.BackgroundColor3 = autoCrouchActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(autoCrouchActive and "AUTO CROUCH: BẬT" or "AUTO CROUCH: TẮT", autoCrouchActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

addBtn(TabMain, "INFINITE JUMP: OFF", Color3.fromRGB(180, 50, 50), function(b)
    infiniteJumpActive = not infiniteJumpActive
    b.Text = infiniteJumpActive and "INFINITE JUMP: ON" or "INFINITE JUMP: OFF"
    b.BackgroundColor3 = infiniteJumpActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(infiniteJumpActive and "NHẢY VÔ HẠN: BẬT" or "NHẢY VÔ HẠN: TẮT", infiniteJumpActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

addBtn(TabMain, "AUTO TRIMP (LƯỚT CẠNH TƯỜNG): OFF", Color3.fromRGB(180, 50, 50), function(b)
    autoTrimpActive = not autoTrimpActive
    b.Text = autoTrimpActive and "AUTO TRIMP: ON" or "AUTO TRIMP (LƯỚT CẠNH TƯỜNG): OFF"
    b.BackgroundColor3 = autoTrimpActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(autoTrimpActive and "AUTO TRIMP: BẬT" or "AUTO TRIMP: TẮT", autoTrimpActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

local InputTrimpBox = Instance.new("TextBox")
InputTrimpBox.Parent = TabMain
InputTrimpBox.Size = UDim2.new(0.96, 0, 0, 35)
InputTrimpBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputTrimpBox.Font = Enum.Font.SourceSansBold
InputTrimpBox.PlaceholderText = "Hệ số lực Trimp (Mặc định: 1.2)"
InputTrimpBox.Text = "1.2"
InputTrimpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputTrimpBox.TextSize = 12

addBtn(TabMain, "LƯU LỰC TRIMP", Color3.fromRGB(0, 120, 215), function()
    local val = tonumber(InputTrimpBox.Text)
    if val then
        trimpPower = math.clamp(val, 1, 3)
        notifyStatus("ĐÃ LƯU LỰC TRIMP: " .. trimpPower .. "x", Color3.fromRGB(0, 255, 255))
    end
end)

addBtn(TabMain, "AUTO BHOP: OFF", Color3.fromRGB(180, 50, 50), function(b)
    systemEnabled = not systemEnabled
    b.Text = systemEnabled and "AUTO BHOP: ON (B)" or "AUTO BHOP: OFF"
    b.BackgroundColor3 = systemEnabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

addBtn(TabMain, "AUTO REVIVE (AN TOÀN): OFF", Color3.fromRGB(180, 50, 50), function(b)
    autoReviveActive = not autoReviveActive
    b.Text = autoReviveActive and "AUTO REVIVE: ON" or "AUTO REVIVE: OFF"
    b.BackgroundColor3 = autoReviveActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

addBtn(TabMain, "XÓA TƯỜNG TÀNG HÌNH: OFF", Color3.fromRGB(180, 50, 50), function(b)
    toggleInvisWallsState()
    b.Text = wallToggleActive and "XÓA TƯỜNG TÀNG HÌNH: ON" or "XÓA TƯỜNG TÀNG HÌNH: OFF"
    b.BackgroundColor3 = wallToggleActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

-- --- TAB VISUAL EMOTE CHANGER ---
local VisualTitle = Instance.new("TextLabel")
VisualTitle.Parent = TabVisual
VisualTitle.Size = UDim2.new(0.96, 0, 0, 25)
VisualTitle.BackgroundTransparency = 1
VisualTitle.Font = Enum.Font.SourceSansBold
VisualTitle.Text = "Visual Emote Changer"
VisualTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
VisualTitle.TextSize = 13

local lblCurrent = Instance.new("TextLabel")
lblCurrent.Parent = TabVisual
lblCurrent.Size = UDim2.new(0.96, 0, 0, 20)
lblCurrent.BackgroundTransparency = 1
lblCurrent.Font = Enum.Font.SourceSansBold
lblCurrent.Text = "Current Emote"
lblCurrent.TextColor3 = Color3.fromRGB(200, 200, 200)
lblCurrent.TextSize = 11
lblCurrent.TextXAlignment = Enum.TextXAlignment.Left

local boxCurrent = Instance.new("TextBox")
boxCurrent.Parent = TabVisual
boxCurrent.Size = UDim2.new(0.96, 0, 0, 35)
boxCurrent.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
boxCurrent.Font = Enum.Font.SourceSansBold
boxCurrent.PlaceholderText = "Nhập tên emote (vd: Kickback)"
boxCurrent.Text = "Kickback"
boxCurrent.TextColor3 = Color3.fromRGB(255, 255, 255)
boxCurrent.TextSize = 12

local lblSelect = Instance.new("TextLabel")
lblSelect.Parent = TabVisual
lblSelect.Size = UDim2.new(0.96, 0, 0, 20)
lblSelect.BackgroundTransparency = 1
lblSelect.Font = Enum.Font.SourceSansBold
lblSelect.Text = "Select Emote"
lblSelect.TextColor3 = Color3.fromRGB(200, 200, 200)
lblSelect.TextSize = 11
lblSelect.TextXAlignment = Enum.TextXAlignment.Left

local boxSelect = Instance.new("TextBox")
boxSelect.Parent = TabVisual
boxSelect.Size = UDim2.new(0.96, 0, 0, 35)
boxSelect.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
boxSelect.Font = Enum.Font.SourceSansBold
boxSelect.PlaceholderText = "Nhập tên emote muốn đổi (vd: RockinStride)"
boxSelect.Text = "RockinStride"
boxSelect.TextColor3 = Color3.fromRGB(255, 255, 255)
boxSelect.TextSize = 12

addBtn(TabVisual, "Changer Emote", Color3.fromRGB(0, 120, 215), function()
    playFixedEmote(boxSelect.Text)
    notifyStatus("CHANGED EMOTE TO: " .. boxSelect.Text, Color3.fromRGB(0, 255, 255))
end)

addBtn(TabVisual, "⏹️ DỪNG EMOTE ĐANG NHẢY", Color3.fromRGB(120, 40, 40), function()
    if currentTrack then pcall(function() currentTrack:Stop() end) end
    notifyStatus("ĐÃ DỪNG EMOTE!", Color3.fromRGB(255, 170, 0))
end)

-- --- TAB SPEED & HEIGHT ---
local SpeedHeightTitle = Instance.new("TextLabel")
SpeedHeightTitle.Parent = TabSpeedHeight
SpeedHeightTitle.Size = UDim2.new(0.96, 0, 0, 25)
SpeedHeightTitle.BackgroundTransparency = 1
SpeedHeightTitle.Font = Enum.Font.SourceSansBold
SpeedHeightTitle.Text = "⚡ STRAFE SPEED & BOOST (EVADE DEFAULT: 33.3)"
SpeedHeightTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
SpeedHeightTitle.TextSize = 12

addBtn(TabSpeedHeight, "⚡ STRAFE SPEED BOOST: OFF", Color3.fromRGB(180, 50, 50), function(b)
    speedToggleActive = not speedToggleActive
    b.Text = speedToggleActive and "⚡ STRAFE SPEED BOOST: ON" or "⚡ STRAFE SPEED BOOST: OFF"
    b.BackgroundColor3 = speedToggleActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(speedToggleActive and "STRAFE ACCEL: BẬT (KHÔNG MẤT TỐC)" or "STRAFE ACCEL: TẮT (BÌNH THƯỜNG)", speedToggleActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

local InputSpeedBox = Instance.new("TextBox")
InputSpeedBox.Parent = TabSpeedHeight
InputSpeedBox.Size = UDim2.new(0.96, 0, 0, 35)
InputSpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputSpeedBox.Font = Enum.Font.SourceSansBold
InputSpeedBox.PlaceholderText = "Nhập WalkSpeed (vd: 33.3, 45...)"
InputSpeedBox.Text = "33.3"
InputSpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputSpeedBox.TextSize = 12

addBtn(TabSpeedHeight, "LƯU MỨC TỐC ĐỘ", Color3.fromRGB(0, 120, 215), function()
    local val = tonumber(InputSpeedBox.Text)
    if val then
        customWalkSpeed = math.clamp(val, 1, 250)
        notifyStatus("ĐÃ LƯU MỨC SPEED: " .. customWalkSpeed, Color3.fromRGB(0, 255, 255))
    else
        notifyStatus("VUI LÒNG NHẬP SỐ HỢP LỆ!", Color3.fromRGB(255, 50, 50))
    end
end)

addBtn(TabSpeedHeight, "TÙY CHỈNH NHẢY CAO: OFF", Color3.fromRGB(180, 50, 50), function(b)
    jumpToggleActive = not jumpToggleActive
    b.Text = jumpToggleActive and "TÙY CHỈNH NHẢY CAO: ON" or "TÙY CHỈNH NHẢY CAO: OFF"
    b.BackgroundColor3 = jumpToggleActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if jumpToggleActive then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = customJumpPower
        else
            humanoid.UseJumpPower = true
            humanoid.JumpPower = originalJumpPower
        end
    end
    
    notifyStatus(jumpToggleActive and "JUMP HIGH: BẬT" or "JUMP HIGH: TẮT", jumpToggleActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

local InputJumpBox = Instance.new("TextBox")
InputJumpBox.Parent = TabSpeedHeight
InputJumpBox.Size = UDim2.new(0.96, 0, 0, 35)
InputJumpBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputJumpBox.Font = Enum.Font.SourceSansBold
InputJumpBox.PlaceholderText = "Nhập độ cao nhảy (vd: 50, 80...)"
InputJumpBox.Text = "50"
InputJumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputJumpBox.TextSize = 12

addBtn(TabSpeedHeight, "LƯU MỨC NHẢY CAO", Color3.fromRGB(0, 120, 215), function()
    local val = tonumber(InputJumpBox.Text)
    if val then
        customJumpPower = math.clamp(val, 10, 350)
        notifyStatus("ĐÃ LƯU MỨC NHẢY CAO: " .. customJumpPower, Color3.fromRGB(0, 255, 255))
    else
        notifyStatus("VUI LÒNG NHẬP SỐ HỢP LỆ!", Color3.fromRGB(255, 50, 50))
    end
end)

-- --- TAB FAKE CO (VISUAL COSMETICS) ---
local FakeCOTitle = Instance.new("TextLabel")
FakeCOTitle.Parent = TabFakeCO
FakeCOTitle.Size = UDim2.new(0.96, 0, 0, 25)
FakeCOTitle.BackgroundTransparency = 1
FakeCOTitle.Font = Enum.Font.SourceSansBold
FakeCOTitle.Text = "👤 FAKE COSMETICS (MESHART R15)"
FakeCOTitle.TextColor3 = Color3.fromRGB(255, 100, 255)
FakeCOTitle.TextSize = 12

addBtn(TabFakeCO, "FAKE HEADLESS: OFF", Color3.fromRGB(180, 50, 50), function(b)
    fakeHeadlessActive = not fakeHeadlessActive
    b.Text = fakeHeadlessActive and "FAKE HEADLESS: ON" or "FAKE HEADLESS: OFF"
    b.BackgroundColor3 = fakeHeadlessActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(fakeHeadlessActive and "FAKE HEADLESS: BẬT" or "FAKE HEADLESS: TẮT", fakeHeadlessActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

addBtn(TabFakeCO, "FAKE KORBLOX: OFF", Color3.fromRGB(180, 50, 50), function(b)
    fakeKorbloxActive = not fakeKorbloxActive
    b.Text = fakeKorbloxActive and "FAKE KORBLOX: ON" or "FAKE KORBLOX: OFF"
    b.BackgroundColor3 = fakeKorbloxActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(fakeKorbloxActive and "FAKE KORBLOX: BẬT" or "FAKE KORBLOX: TẮT", fakeKorbloxActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50))
end)

-- --- TAB REVIVE ---
local ReviveTitle = Instance.new("TextLabel")
ReviveTitle.Parent = TabRevive
ReviveTitle.Size = UDim2.new(0.96, 0, 0, 25)
ReviveTitle.BackgroundTransparency = 1
ReviveTitle.Font = Enum.Font.SourceSansBold
ReviveTitle.Text = "🏥 NGƯỜI CHƠI ĐANG GỤC"
ReviveTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
ReviveTitle.TextSize = 12

local DownedScroll = Instance.new("ScrollingFrame")
DownedScroll.Parent = TabRevive
DownedScroll.Size = UDim2.new(0.96, 0, 0, 200)
DownedScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
DownedScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
DownedScroll.ScrollBarThickness = 5

local DownedLayout = Instance.new("UIListLayout")
DownedLayout.Parent = DownedScroll
DownedLayout.SortOrder = Enum.SortOrder.LayoutOrder
DownedLayout.Padding = UDim.new(0, 5)

task.spawn(function()
    while true do
        task.wait(1)
        if not TabRevive.Visible then continue end
        
        for _, child in ipairs(DownedScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                
                local isDowned = false
                if hum and (hum.Health <= 0 or p.Character:FindFirstChild("Downed") or p.Character:FindFirstChild("IsDowned")) then
                    isDowned = true
                end
                
                if isDowned and hrp and myHrp then
                    local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                    
                    local itemFrame = Instance.new("Frame")
                    itemFrame.Parent = DownedScroll
                    itemFrame.Size = UDim2.new(1, -5, 0, 35)
                    itemFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 30)
                    
                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Parent = itemFrame
                    nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Font = Enum.Font.SourceSansBold
                    nameLbl.Text = " " .. p.Name .. " (" .. dist .. "m)"
                    nameLbl.TextColor3 = Color3.fromRGB(255, 200, 200)
                    nameLbl.TextSize = 11
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local bringBtn = Instance.new("TextButton")
                    bringBtn.Parent = itemFrame
                    bringBtn.Position = UDim2.new(0.52, 0, 0.1, 0)
                    bringBtn.Size = UDim2.new(0.45, 0, 0.8, 0)
                    bringBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                    bringBtn.Font = Enum.Font.SourceSansBold
                    bringBtn.Text = "🧲 BRING & GIỮ"
                    bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    bringBtn.TextSize = 10
                    
                    bringBtn.MouseButton1Click:Connect(function()
                        pcall(function()
                            task.spawn(function()
                                local startTime = tick()
                                while tick() - startTime < 3.5 do
                                    local currentMyHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if hrp and currentMyHrp then
                                        hrp.CFrame = currentMyHrp.CFrame + Vector3.new(2, 0, 2)
                                        pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
                                    end
                                    task.wait()
                                end
                            end)
                            notifyStatus("ĐÃ KÉO VÀ GIỮ " .. p.Name .. " BÊN BẠN!", Color3.fromRGB(50, 255, 50))
                        end)
                    end)
                end
            end
        end
    end
end)

-- --- TAB EFFECTS ---
local EffectsTitle = Instance.new("TextLabel")
EffectsTitle.Parent = TabEffects
EffectsTitle.Size = UDim2.new(0.96, 0, 0, 25)
EffectsTitle.BackgroundTransparency = 1
EffectsTitle.Font = Enum.Font.SourceSansBold
EffectsTitle.Text = "✨ HIỆU ỨNG ĐẶC BIỆT (EFFECTS)"
EffectsTitle.TextColor3 = Color3.fromRGB(0, 255, 100)
EffectsTitle.TextSize = 12

addBtn(TabEffects, "TOXIC INFERNO (FIRE AURA): OFF", Color3.fromRGB(180, 50, 50), function(b)
    toxicInfernoActive = not toxicInfernoActive
    toggleToxicFireAura(toxicInfernoActive)
    b.Text = toxicInfernoActive and "TOXIC INFERNO: ON" or "TOXIC INFERNO: OFF"
    b.BackgroundColor3 = toxicInfernoActive and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    notifyStatus(toxicInfernoActive and "GREEN FIRE AURA: BẬT" or "GREEN FIRE AURA: TẮT", toxicInfernoActive and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end)

-- --- TAB FPS ---
local FPSTitle = Instance.new("TextLabel")
FPSTitle.Parent = TabFPS
FPSTitle.Size = UDim2.new(0.96, 0, 0, 25)
FPSTitle.BackgroundTransparency = 1
FPSTitle.Font = Enum.Font.SourceSansBold
FPSTitle.Text = "⚡ ULTRA FPS & GREY SKY BOOSTER"
FPSTitle.TextColor3 = Color3.fromRGB(0, 255, 170)
FPSTitle.TextSize = 12

local FPSLiveLabel = Instance.new("TextLabel")
FPSLiveLabel.Parent = TabFPS
FPSLiveLabel.Size = UDim2.new(0.96, 0, 0, 25)
FPSLiveLabel.BackgroundTransparency = 1
FPSLiveLabel.Font = Enum.Font.GothamBold
FPSLiveLabel.Text = "FPS HIỆN TẠI: 60"
FPSLiveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLiveLabel.TextSize = 11

local lastTick = tick()
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTick = tick()
    if currentTick - lastTick >= 1 then
        FPSLiveLabel.Text = "FPS HIỆN TẠI: " .. tostring(math.floor(frameCount / (currentTick - lastTick)))
        frameCount = 0
        lastTick = currentTick
    end
end)

local function LowGraphicsObject(v)
    if v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
        v.CastShadow = false
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = 1
    elseif v:IsA("SpecialMesh") then
        v.TextureId = ""
    end
end

local function DestroyEffects(v)
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Explosion") or v:IsA("Highlight") then
        v:Destroy()
    end
end

addBtn(TabFPS, "💥 GIẢM LAG CỰC MẠNH", Color3.fromRGB(200, 40, 40), function(b)
    b.Text = "ĐÃ TỐI ƯU CỰC MẠNH!"
    b.BackgroundColor3 = Color3.fromRGB(40, 180, 80)

    Lighting.GlobalShadows = false
    Lighting.Technology = Enum.Technology.Compatibility

    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end

    if workspace:FindFirstChildOfClass("Terrain") then
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
    end

    for _, v in pairs(workspace:GetDescendants()) do
        LowGraphicsObject(v)
    end

    workspace.DescendantAdded:Connect(function(v)
        LowGraphicsObject(v)
    end)
    notifyStatus("ĐÃ TỐI ƯU ĐỒ HỌA VÀ TEXTURE!", Color3.fromRGB(50, 255, 50))
end)

local isGreySky = false
addBtn(TabFPS, "☁️ BẦU TRỜI XÁM XỊT", Color3.fromRGB(90, 90, 90), function(b)
    isGreySky = not isGreySky
    
    if isGreySky then
        b.Text = "☁️ BẦU TRỜI XÁM: [ON]"
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") or v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
        
        Lighting.ClockTime = 12
        Lighting.Brightness = 0
        Lighting.GlobalShadows = false
        Lighting.FogStart = 0
        Lighting.FogEnd = 9e9
        Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
        Lighting.Ambient = Color3.fromRGB(100, 100, 100)
        notifyStatus("BẬT BẦU TRỜI XÁM XỊT!", Color3.fromRGB(0, 255, 255))
    else
        b.Text = "☁️ BẦU TRỜI XÁM XỊT"
        b.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        notifyStatus("TẮT BẦU TRỜI XÁM XỊT!", Color3.fromRGB(255, 170, 0))
    end
end)

addBtn(TabFPS, "🔥 XÓA HIỆU ỨNG THỪA", Color3.fromRGB(220, 100, 0), function(b)
    b.Text = "ĐÃ XÓA HIỆU ỨNG!"
    b.BackgroundColor3 = Color3.fromRGB(40, 180, 80)

    for _, v in pairs(workspace:GetDescendants()) do
        DestroyEffects(v)
    end

    workspace.DescendantAdded:Connect(function(v)
        DestroyEffects(v)
    end)
    notifyStatus("ĐÃ XÓA SẠCH HIỆU ỨNG THỪA!", Color3.fromRGB(50, 255, 50))
end)

local isShortDistance = false
local renderConnection = nil
addBtn(TabFPS, "🔍 TẦM NHÌN GẦN: [OFF]", Color3.fromRGB(130, 50, 210), function(b)
    isShortDistance = not isShortDistance
    
    if isShortDistance then
        b.Text = "🔍 TẦM NHÌN GẦN: [ON]"
        b.BackgroundColor3 = Color3.fromRGB(0, 180, 220)
        
        Lighting.FogStart = 30
        Lighting.FogEnd = 120
        Lighting.FogColor = Color3.fromRGB(50, 50, 50)
        
        renderConnection = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrpPos = LocalPlayer.Character.HumanoidRootPart.Position
                for _, v in pairs(workspace:GetChildren()) do
                    if v:IsA("Model") or v:IsA("BasePart") then
                        if v ~= LocalPlayer.Character and not v:IsA("Terrain") then
                            local partPos = v:IsA("Model") and (v.PrimaryPart and v.PrimaryPart.Position or nil) or v.Position
                            if partPos then
                                local dist = (hrpPos - partPos).Magnitude
                                if dist > 200 then
                                    v.Parent = game:GetService("ReplicatedStorage")
                                end
                            end
                        end
                    end
                end
            end
        end)
        notifyStatus("BẬT TẦM NHÌN GẦN!", Color3.fromRGB(0, 255, 255))
    else
        b.Text = "🔍 TẦM NHÌN GẦN: [OFF]"
        b.BackgroundColor3 = Color3.fromRGB(130, 50, 210)
        Lighting.FogStart = 0
        Lighting.FogEnd = 9e9
        if renderConnection then
            renderConnection:Disconnect()
        end
        notifyStatus("TẮT TẦM NHÌN GẦN!", Color3.fromRGB(255, 170, 0))
    end
end)

-- --- NÚT THU NHỎ MENU HÌNH CON RỒNG ---
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "EvadeAllToggle"
ToggleGui.Parent = CoreGui
ToggleGui.ResetOnSpawn = false

MainFrame.Visible = true

local MiniBtn = Instance.new("TextButton")
MiniBtn.Parent = ToggleGui
MiniBtn.Position = UDim2.new(0.02, 0, 0.35, 0)
MiniBtn.Size = UDim2.new(0, 48, 0, 48)
MiniBtn.BackgroundColor3 = Color3.fromRGB(35, 10, 15)
MiniBtn.Font = Enum.Font.SourceSansBold
MiniBtn.Text = "🐉"
MiniBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
MiniBtn.TextSize = 22

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = MiniBtn

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(50, 255, 50)
UIStroke.Thickness = 2
UIStroke.Parent = MiniBtn

local dragging, dragInput, dragStart, startPos
local dragThreshold = 5
local totalMoved = 0

MiniBtn.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        if moveIconEnabled then
            dragging = true
            dragStart = input.Position
            startPos = MiniBtn.Position
            totalMoved = 0
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end
end)

MiniBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and moveIconEnabled then
        local delta = input.Position - dragStart
        totalMoved = delta.Magnitude
        MiniBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local lastClickTick = 0
MiniBtn.MouseButton1Click:Connect(function()
    if totalMoved < dragThreshold then
        local currentTick = tick()
        if currentTick - lastClickTick < 0.4 then
            MainFrame.Visible = not MainFrame.Visible
            UIStroke.Color = MainFrame.Visible and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
            lastClickTick = 0
        else
            lastClickTick = currentTick
        end
    end
end)