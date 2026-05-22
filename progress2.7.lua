return function(env)
    local Library = env.Library
    local Page = env.Page
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local Workspace = env.Workspace
    local CoreGui = env.CoreGui
    local ReplicatedStorage = env.ReplicatedStorage
    local RunService = env.RunService
    local TweenService = env.TweenService
    local Theme = env.Theme
    local SendNotification = env.SendNotification

    -- Vars Beast Power
    local BeastPowerConnection1 = nil
    local BeastPowerConnection2 = nil
    local uiFrameBP, uiLabelBP = nil, nil
    local trackedPowerValue = nil
    local lastPercent = 0
    local isDraining = false
    local BeastPowerLoop2
    
    -- Vars Door Progress
    local DoorProgLoop = nil
    local DoorProgHeartbeat = nil
    local trackedNormalDoors = {}
    local DT_CONFIG = { VISIBILITY_DISTANCE = 75, DOOR_NAMES = {["SingleDoor"]=true,["DoubleDoor"]=true,["SlidingDoor"]=true}, BLACKLIST = {["ExitDoor"]=true,["Decorative"]=true,["FakeDoor"]=true,["ElevatorDoor"]=true, ["Closet"]=false} }
    local DT_COLORS = { 
        BAR_BG = Color3.fromRGB(35, 30, 30), 
        MUSTARD = Color3.fromRGB(205, 135, 25), 
        WHITE = Color3.fromRGB(230, 230, 230),
        HL_CLOSE = Color3.fromRGB(255, 0, 0),
        HL_OPENING = Color3.fromRGB(255, 200, 0),
        HL_OPEN = Color3.fromRGB(0, 255, 0)
    }
    
    -- Vars ExitDoor Progress
    local ExitDoorConn = nil
    local ExitDoorAdded = nil
    local ExitDoorRemoving = nil
    local trackedExitDoors = {}
    local actionValCache = {}

    -- =========================================================================
    -- SECTION: ACTION TIMERS (Coluna Esquerda)
    -- =========================================================================
    Library:CreateSection(Page, "Action Timers")
    
    Library:CreateToggle(Page, "Computer Progress", false, function(state)
        -- Código removido. Toggle vazia pronta para novos scripts.
    end)
    
    Library:CreateToggle(Page, "Door Progress", false, function(state)
        if state then
            local function createDoorHUD(parent)
                if parent:FindFirstChild("NormalDoorGUI") then parent.NormalDoorGUI:Destroy() end
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "NormalDoorGUI"
                billboard.Adornee = parent
                billboard.Size = UDim2.new(0, 90, 0, 35) 
                billboard.StudsOffset = Vector3.new(0, 1, 0)
                billboard.AlwaysOnTop = true
                billboard.MaxDistance = DT_CONFIG.VISIBILITY_DISTANCE
                billboard.Parent = parent
                
                local text = Instance.new("TextLabel")
                text.Name = "PercentText"
                text.Size = UDim2.new(1, 0, 0.55, 0)
                text.Position = UDim2.new(0, 0, 0, 0)
                text.BackgroundTransparency = 1
                text.Text = "0.0%"
                text.TextColor3 = DT_COLORS.MUSTARD
                text.TextStrokeTransparency = 0.7
                text.TextStrokeColor3 = Color3.new(0,0,0)
                text.Font = Enum.Font.GothamMedium
                text.TextScaled = true 
                text.ZIndex = 6
                text.Parent = billboard

                local bgBar = Instance.new("Frame")
                bgBar.Name = "BgBar"
                bgBar.Size = UDim2.new(1, 0, 0.35, 0) 
                bgBar.Position = UDim2.new(0, 0, 0.65, 0)
                bgBar.BackgroundColor3 = DT_COLORS.BAR_BG
                bgBar.BackgroundTransparency = 0.3
                bgBar.BorderSizePixel = 0
                bgBar.ZIndex = 5
                bgBar.Parent = billboard
                
                local fill = Instance.new("Frame")
                fill.Name = "Fill"
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = DT_COLORS.MUSTARD
                fill.BackgroundTransparency = 0.1
                fill.BorderSizePixel = 0
                fill.ZIndex = 6
                fill.Parent = bgBar
                
                return billboard, fill, text
            end

            local function createHighlight(model)
                if model:FindFirstChild("NormalDoorESP") then model.NormalDoorESP:Destroy() end
                local hl = Instance.new("Highlight")
                hl.Name = "NormalDoorESP"
                hl.FillColor = DT_COLORS.HL_CLOSE
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                hl.FillTransparency = 0.55
                hl.OutlineTransparency = 0 
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Enabled = true
                hl.Parent = model
                return hl
            end

            local function getRealDoorPart(model)
                local explicitDoor = model:FindFirstChild("Door") or model:FindFirstChild("Left") or model:FindFirstChild("Right")
                if explicitDoor and explicitDoor:IsA("BasePart") then return explicitDoor end
                local biggestPart = nil
                local maxVolume = 0
                for _, part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") and not string.match(part.Name, "Frame") and not string.match(part.Name, "Wall") and part.Transparency < 1 then
                        local v = part.Size.X * part.Size.Y * part.Size.Z
                        if v > maxVolume then maxVolume = v; biggestPart = part end
                    end
                end
                return biggestPart or model.PrimaryPart
            end

            local function setupNormalDoor(doorModel)
                if trackedNormalDoors[doorModel] then return end
                if DT_CONFIG.BLACKLIST[doorModel.Name] then return end
                if string.match(doorModel.Name, "Exit") or string.match(doorModel.Name, "Decor") then return end
                
                local anchorPart = getRealDoorPart(doorModel)
                if not anchorPart then return end
                
                if anchorPart:FindFirstChild("NormalDoorGUI") then anchorPart.NormalDoorGUI:Destroy() end
                
                local billboard, bar, text = createDoorHUD(anchorPart)
                local highlight = createHighlight(doorModel)
                
                trackedNormalDoors[doorModel] = { 
                    Model = doorModel, 
                    Anchor = anchorPart, 
                    InitialCFrame = anchorPart.CFrame, 
                    Billboard = billboard, 
                    Bar = bar, 
                    Text = text,
                    Highlight = highlight
                }
            end

            local lastMap = nil
            DoorProgLoop = task.spawn(function()
                while state do
                    local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
                    local mapName = currentMap and tostring(currentMap.Value) or ""
                    
                    if mapName ~= "" and lastMap ~= mapName then
                        lastMap = mapName
                        local map = Workspace:FindFirstChild(mapName)
                        
                        for doorModel, data in pairs(trackedNormalDoors) do
                            if data.Billboard then data.Billboard:Destroy() end
                            if data.Highlight then data.Highlight:Destroy() end
                        end
                        table.clear(trackedNormalDoors)

                        if map then
                            for _, obj in ipairs(map:GetDescendants()) do
                                if obj:IsA("Model") and DT_CONFIG.DOOR_NAMES[obj.Name] and not DT_CONFIG.BLACKLIST[obj.Name] then 
                                    setupNormalDoor(obj) 
                                end
                            end
                        end
                    elseif mapName == "" and lastMap ~= "" then
                        lastMap = ""
                        for doorModel, data in pairs(trackedNormalDoors) do
                            if data.Billboard then data.Billboard:Destroy() end
                            if data.Highlight then data.Highlight:Destroy() end
                        end
                        table.clear(trackedNormalDoors)
                    end
                    task.wait(2)
                end
            end)

            local accum = 0
            DoorProgHeartbeat = RunService.Heartbeat:Connect(function(dt)
                accum = accum + dt
                if accum < 0.1 then return end
                accum = 0
                
                local currentDoorInteractions = {}

                for _, player in ipairs(Players:GetPlayers()) do
                    local stats = player:FindFirstChild("TempPlayerStatsModule")
                    if stats then
                        local action = stats:FindFirstChild("ActionProgress")
                        local isRagdolled = stats:FindFirstChild("Ragdoll")
                        
                        if action and action.Value > 0 then
                            local playerFallen = false
                            if isRagdolled and isRagdolled:IsA("BoolValue") then
                                playerFallen = isRagdolled.Value
                            end
                            
                            if not playerFallen then
                                local char = player.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                
                                if hrp then
                                    local closestDoor = nil
                                    local minDistance = 15
                                    
                                    for doorModel, data in pairs(trackedNormalDoors) do
                                        if data.Anchor and data.Anchor.Parent then
                                            local dist = (data.Anchor.Position - hrp.Position).Magnitude
                                            if dist < minDistance then
                                                minDistance = dist
                                                closestDoor = doorModel
                                            end
                                        end
                                    end
                                    
                                    if closestDoor then
                                        local rawVal = action.Value
                                        local progress = (rawVal > 1) and (rawVal / 100) or rawVal 
                                        
                                        local currentMax = currentDoorInteractions[closestDoor] or 0
                                        currentDoorInteractions[closestDoor] = math.max(currentMax, progress)
                                    end
                                end
                            end
                        end
                    end
                end
                
                for doorModel, data in pairs(trackedNormalDoors) do
                    if not doorModel.Parent or not data.Anchor or not data.Anchor.Parent then
                        if data.Billboard then data.Billboard:Destroy() end
                        if data.Highlight then data.Highlight:Destroy() end
                        trackedNormalDoors[doorModel] = nil
                        continue
                    end

                    local currentCF = data.Anchor.CFrame
                    local distMoved = (currentCF.Position - data.InitialCFrame.Position).Magnitude
                    local dot = currentCF.LookVector:Dot(data.InitialCFrame.LookVector)
                    
                    if data.Anchor.CanCollide == true then
                        if dot < 0.9 or distMoved > 0.5 then
                            data.InitialCFrame = currentCF
                            dot = 1
                        end
                    end

                    local isPhysicallyOpen = false
                    if not data.Anchor.CanCollide or dot < 0.85 or distMoved > 0.5 or data.Anchor.Transparency > 0.8 then
                        isPhysicallyOpen = true
                    end
                    
                    local interactionVal = currentDoorInteractions[doorModel] or 0

                    if isPhysicallyOpen then
                        data.Bar.Size = UDim2.new(1, 0, 1, 0)
                        data.Bar.BackgroundColor3 = DT_COLORS.WHITE
                        data.Text.TextColor3 = DT_COLORS.WHITE
                        data.Text.Text = "100.0%"
                        data.Highlight.FillColor = DT_COLORS.HL_OPEN
                        
                    elseif interactionVal > 0.001 then 
                        data.Bar.Size = UDim2.new(math.clamp(interactionVal, 0, 1), 0, 1, 0)
                        data.Bar.BackgroundColor3 = DT_COLORS.MUSTARD
                        data.Text.TextColor3 = DT_COLORS.MUSTARD
                        data.Text.Text = string.format("%.1f%%", interactionVal * 100)
                        data.Highlight.FillColor = DT_COLORS.HL_OPENING
                        
                    else
                        data.Bar.Size = UDim2.new(0, 0, 1, 0)
                        data.Bar.BackgroundColor3 = DT_COLORS.MUSTARD
                        data.Text.TextColor3 = DT_COLORS.MUSTARD
                        data.Text.Text = "0.0%"
                        data.Highlight.FillColor = DT_COLORS.HL_CLOSE
                    end
                end
            end)
        else
            if DoorProgLoop then task.cancel(DoorProgLoop); DoorProgLoop = nil end
            if DoorProgHeartbeat then DoorProgHeartbeat:Disconnect(); DoorProgHeartbeat = nil end
            for doorModel, data in pairs(trackedNormalDoors) do
                if data.Billboard then data.Billboard:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
            end
            table.clear(trackedNormalDoors)
        end
    end)
    
    Library:CreateToggle(Page, "ExitDoor Progress", false, function(state)
        if state then
            local guiName = "FTF_ExitDoorESP_Premium"
            local targetGuiParent = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
            
            if targetGuiParent:FindFirstChild(guiName) then
                targetGuiParent[guiName]:Destroy()
            end

            local folder = Instance.new("Folder")
            folder.Name = guiName
            folder.Parent = targetGuiParent

            local function getPlayerProgress(plr)
                local actionVal = actionValCache[plr]
                if not actionVal or not actionVal.Parent then
                    actionVal = plr:FindFirstChild("ActionProgress", true)
                    if actionVal and actionVal:IsA("NumberValue") then
                        actionValCache[plr] = actionVal
                    else
                        actionValCache[plr] = nil
                    end
                end
                
                if actionVal then
                    return actionVal.Value
                end
                
                return 0
            end

            ExitDoorRemoving = Players.PlayerRemoving:Connect(function(plr)
                actionValCache[plr] = nil
            end)

            local function registerExitDoor(door)
                if trackedExitDoors[door] then return end 
                
                local mainPart = door.PrimaryPart
                if not mainPart then
                    local descendants = door:GetDescendants()
                    for i = 1, #descendants do
                        local p = descendants[i]
                        if p:IsA("BasePart") and p.Transparency < 1 then
                            mainPart = p
                            break
                        end
                    end
                    if not mainPart then
                        mainPart = door:FindFirstChildWhichIsA("BasePart")
                    end
                end
                if not mainPart then return end

                local doorParts = {}
                local lightParts = {}
                
                local descendants = door:GetDescendants()
                for i = 1, #descendants do
                    local part = descendants[i]
                    if part:IsA("BasePart") then
                        table.insert(doorParts, part)
                        local lowerName = string.lower(part.Name)
                        if string.find(lowerName, "light", 1, true) or string.find(lowerName, "screen", 1, true) then
                            table.insert(lightParts, part)
                        end
                    end
                end

                local highlight = Instance.new("Highlight")
                highlight.Name = "ExitDoorHighlight"
                highlight.Adornee = door
                highlight.FillColor = Color3.fromRGB(255, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                highlight.FillTransparency = 0.55
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = folder

                local bgui = Instance.new("BillboardGui")
                bgui.Name = "UI"
                bgui.Size = UDim2.new(0, 140, 0, 45) 
                bgui.StudsOffset = Vector3.new(0, 5, 0)
                bgui.AlwaysOnTop = true
                bgui.Adornee = mainPart
                bgui.Parent = folder
                
                local txt = Instance.new("TextLabel", bgui)
                txt.Name = "Text"
                txt.Size = UDim2.new(1, 0, 0.6, 0)
                txt.Position = UDim2.new(0, 0, 0, 0)
                txt.BackgroundTransparency = 1
                txt.Text = "EXIT"
                txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                txt.Font = Enum.Font.GothamBlack
                txt.TextSize = 13
                txt.TextStrokeTransparency = 0 
                txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                
                local barBg = Instance.new("Frame", bgui)
                barBg.Name = "BarBg"
                barBg.Size = UDim2.new(0.8, 0, 0, 6) 
                barBg.Position = UDim2.new(0.1, 0, 0.7, 0) 
                barBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                barBg.BackgroundTransparency = 0.4
                barBg.BorderSizePixel = 0
                
                local bgCorner = Instance.new("UICorner", barBg)
                bgCorner.CornerRadius = UDim.new(1, 0)
                
                local bgStroke = Instance.new("UIStroke", barBg)
                bgStroke.Color = Color3.fromRGB(0, 0, 0)
                bgStroke.Thickness = 1.2
                bgStroke.Transparency = 0.2
                
                local fill = Instance.new("Frame", barBg)
                fill.Name = "Fill"
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(255, 160, 20) 
                fill.BorderSizePixel = 0
                
                local fillCorner = Instance.new("UICorner", fill)
                fillCorner.CornerRadius = UDim.new(1, 0)
                
                trackedExitDoors[door] = {
                    UI = bgui,
                    Highlight = highlight,
                    Progress = 0,
                    Completed = false,
                    MainPart = mainPart,
                    DoorParts = doorParts,
                    LightParts = lightParts,
                    TextElement = txt,
                    FillElement = fill
                }
            end

            task.spawn(function()
                local workspaceDescendants = workspace:GetDescendants()
                for i = 1, #workspaceDescendants do
                    local obj = workspaceDescendants[i]
                    if obj.Name == "ExitDoor" and obj:IsA("Model") then
                        registerExitDoor(obj)
                    end
                end
            end)

            ExitDoorAdded = workspace.DescendantAdded:Connect(function(obj)
                if obj.Name == "ExitDoor" and obj:IsA("Model") then
                    task.defer(function()
                        registerExitDoor(obj)
                    end)
                end
            end)

            ExitDoorConn = task.spawn(function()
                while state and task.wait(0.1) do
                    local openingNow = {}
                    local playersList = Players:GetPlayers()

                    for i = 1, #playersList do
                        local plr = playersList[i]
                        local char = plr.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local playerFallen = false
                            local stats = plr:FindFirstChild("TempPlayerStatsModule")
                            if stats then
                                local ragdoll = stats:FindFirstChild("Ragdoll")
                                if ragdoll and ragdoll:IsA("BoolValue") and ragdoll.Value == true then
                                    playerFallen = true
                                end
                            end
                            
                            if not playerFallen then
                                local currentProgress = getPlayerProgress(plr)
                                
                                if currentProgress > 0 then
                                    local plrPos = hrp.Position
                                    local closestDoor = nil
                                    local minDist = 5 
                                    
                                    for door, data in pairs(trackedExitDoors) do
                                        if door.Parent then
                                            local parts = data.DoorParts
                                            for j = 1, #parts do
                                                local part = parts[j]
                                                if part.Parent then
                                                    local dist = (part.Position - plrPos).Magnitude
                                                    if dist < minDist then
                                                        minDist = dist
                                                        closestDoor = door
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    
                                    if closestDoor then
                                        openingNow[closestDoor] = currentProgress
                                    end
                                end
                            end
                        end
                    end

                    for door, data in pairs(trackedExitDoors) do
                        if not door.Parent then
                            if data.UI then data.UI:Destroy() end
                            if data.Highlight then data.Highlight:Destroy() end
                            trackedExitDoors[door] = nil
                            continue
                        end
                        
                        if not data.MainPart or not data.MainPart.Parent then
                            local newMain = nil
                            local doorDescendants = door:GetDescendants()
                            for i = 1, #doorDescendants do
                                local p = doorDescendants[i]
                                if p:IsA("BasePart") and p.Name ~= "Trigger" then
                                    newMain = p
                                    break
                                end
                            end
                            
                            if newMain then
                                data.MainPart = newMain
                                data.UI.Adornee = newMain
                            end
                        end
                        
                        if not data.Completed then
                            local nativelyOpen = false
                            local lParts = data.LightParts
                            
                            for i = 1, #lParts do
                                local part = lParts[i]
                                if part.Parent and string.find(string.lower(part.BrickColor.Name), "green", 1, true) then
                                    nativelyOpen = true
                                    break
                                end
                            end
                            
                            if nativelyOpen then
                                data.Completed = true
                                data.Progress = 1
                            elseif openingNow[door] then
                                data.Progress = openingNow[door]
                            else
                                data.Progress = 0
                            end
                            
                            if data.Progress >= 0.99 then
                                data.Completed = true
                                data.Progress = 1
                            end
                        end
                        
                        if data.Completed then
                            data.FillElement.Size = UDim2.new(1, 0, 1, 0)
                            data.FillElement.BackgroundColor3 = Color3.fromRGB(40, 255, 80)
                            data.TextElement.Text = "DOOR OPENED!"
                            data.TextElement.TextColor3 = Color3.fromRGB(40, 255, 80)
                            
                            if data.Highlight then
                                data.Highlight.FillColor = Color3.fromRGB(40, 255, 80)
                            end
                        else
                            data.FillElement.Size = UDim2.new(data.Progress, 0, 1, 0)
                            data.FillElement.BackgroundColor3 = Color3.fromRGB(255, 160, 20)
                            
                            if data.Highlight then
                                data.Highlight.FillColor = Color3.fromRGB(255, 255, 0)
                            end
                            
                            if data.Progress > 0 then
                                data.TextElement.Text = "OPENING: " .. math.floor(data.Progress * 100) .. "%"
                            else
                                data.TextElement.Text = "EXIT"
                            end
                            data.TextElement.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end
                end
            end)
        else
            if ExitDoorRemoving then ExitDoorRemoving:Disconnect(); ExitDoorRemoving = nil end
            if ExitDoorAdded then ExitDoorAdded:Disconnect(); ExitDoorAdded = nil end
            if ExitDoorConn then task.cancel(ExitDoorConn); ExitDoorConn = nil end
            local targetGuiParent = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
            if targetGuiParent:FindFirstChild("FTF_ExitDoorESP_Premium") then targetGuiParent.FTF_ExitDoorESP_Premium:Destroy() end
            table.clear(trackedExitDoors)
            table.clear(actionValCache)
        end
    end)
    
    Library:CreateToggle(Page, "WalkSpeed Detector", false, function(state)
        -- Código removido. Toggle vazia pronta para novos scripts.
    end)

    Library:CreateToggle(Page, "Wallhop Counter", false, function(state)
        -- Código removido. Toggle vazia pronta para novos scripts.
    end)

    -- =========================================================================
    -- SECTION: BEAST INDICATORS (Coluna Direita)
    -- =========================================================================
    Library:CreateSection(Page, "Beast Indicators")
    
    Library:CreateToggle(Page, "GetUp Timer", false, function(state)
        -- Código removido. Toggle vazia pronta para novos scripts.
    end)
    
    Library:CreateToggle(Page, "Beast Power Timer", false, function(state)
        if state then
            local function getUIContainer()
                local success, result = pcall(function() return CoreGui end)
                if success then return result else return LocalPlayer:WaitForChild("PlayerGui") end
            end
            local container = getUIContainer()
            
            if container:FindFirstChild("BeastTextHUD") then
                container.BeastTextHUD:Destroy()
            end

            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "BeastTextHUD"
            screenGui.IgnoreGuiInset = true
            screenGui.ResetOnSpawn = false
            screenGui.Parent = container

            uiFrameBP = Instance.new("Frame")
            uiFrameBP.Name = "MainFrame"
            uiFrameBP.AnchorPoint = Vector2.new(0.5, 1)
            uiFrameBP.Position = UDim2.new(0.5, 0, 0.85, 0) 
            uiFrameBP.Size = UDim2.new(0, 0, 0, 30) 
            uiFrameBP.AutomaticSize = Enum.AutomaticSize.X 
            uiFrameBP.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            uiFrameBP.BackgroundTransparency = 0.5 
            uiFrameBP.BorderSizePixel = 0 
            uiFrameBP.Visible = false
            uiFrameBP.Parent = screenGui

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 6) 
            uiCorner.Parent = uiFrameBP

            local uiPadding = Instance.new("UIPadding")
            uiPadding.PaddingLeft = UDim.new(0, 10) 
            uiPadding.PaddingRight = UDim.new(0, 10) 
            uiPadding.Parent = uiFrameBP

            uiLabelBP = Instance.new("TextLabel")
            uiLabelBP.Name = "StatusText"
            uiLabelBP.Size = UDim2.new(0, 0, 1, 0) 
            uiLabelBP.AutomaticSize = Enum.AutomaticSize.X
            uiLabelBP.BackgroundTransparency = 1
            uiLabelBP.Text = "Carregando..."
            uiLabelBP.TextColor3 = Color3.fromRGB(255, 255, 255) 
            uiLabelBP.Font = Enum.Font.GothamBold 
            uiLabelBP.TextSize = 18 
            uiLabelBP.TextXAlignment = Enum.TextXAlignment.Center
            uiLabelBP.Parent = uiFrameBP
            
            trackedPowerValue = nil
            lastPercent = 0
            isDraining = false

            BeastPowerConnection1 = task.spawn(function()
                while state and task.wait(1) do
                    local foundValue = nil
                    for _, player in ipairs(Players:GetPlayers()) do
                        local char = player.Character
                        if char then
                            local beastPowers = char:FindFirstChild("BeastPowers")
                            if beastPowers then
                                foundValue = beastPowers:FindFirstChildOfClass("NumberValue", true)
                                if foundValue then
                                    break 
                                end
                            end
                        end
                    end
                    trackedPowerValue = foundValue 
                end
            end)

            BeastPowerConnection2 = RunService.RenderStepped:Connect(function()
                if trackedPowerValue and trackedPowerValue.Parent then
                    uiFrameBP.Visible = true
                    
                    local percent = math.clamp(trackedPowerValue.Value, 0, 1)
                    local percentInt = math.floor(percent * 100)
                    
                    uiLabelBP.Text = "BeastPower Back In: " .. percentInt .. "%"
                    
                    if percent < lastPercent then
                        isDraining = true 
                    elseif percent > lastPercent then
                        isDraining = false 
                    end
                    
                    lastPercent = percent 
                    
                    if isDraining then
                        uiLabelBP.TextColor3 = Color3.fromRGB(255, 255, 255)
                    else
                        if percent >= 0.99 then
                            uiLabelBP.TextColor3 = Color3.fromRGB(50, 255, 50) 
                        elseif percent >= 0.80 then
                            uiLabelBP.TextColor3 = Color3.fromRGB(255, 50, 50) 
                        else
                            uiLabelBP.TextColor3 = Color3.fromRGB(255, 255, 255) 
                        end
                    end
                else
                    if uiFrameBP then uiFrameBP.Visible = false end
                    lastPercent = 0 
                    isDraining = false
                end
            end)
        else
            if BeastPowerConnection1 then task.cancel(BeastPowerConnection1); BeastPowerConnection1 = nil end
            if BeastPowerConnection2 then BeastPowerConnection2:Disconnect(); BeastPowerConnection2 = nil end
            if uiFrameBP and uiFrameBP.Parent then uiFrameBP.Parent:Destroy() end
        end
    end)
    
    Library:CreateToggle(Page, "Beast Power Timer V2", false, function(state)
        local function CreateLabelBP(player)
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local billboard = humanoidRootPart:FindFirstChild("BeastPowerBillboard")
                    if not billboard then
                        billboard = Instance.new("BillboardGui")
                        billboard.Name = "BeastPowerBillboard"
                        billboard.Size = UDim2.new(2, 0, 1, 0)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop = true
                        billboard.MaxDistance = math.huge
                        billboard.LightInfluence = 1
                        billboard.Parent = humanoidRootPart
                        local label = Instance.new("TextLabel")
                        label.Name = "BeastPowerLabel"
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Font = Enum.Font.Arcade
                        label.TextSize = 20
                        label.Text = ""
                        label.TextStrokeTransparency = 0.5
                        label.TextColor3 = Color3.new(1, 1, 1)
                        label.TextStrokeColor3 = Color3.new(0, 0, 0)
                        label.Parent = billboard
                    end
                    return billboard.BeastPowerLabel
                end
            end
            return nil
        end
        if state then
            BeastPowerLoop2 = task.spawn(function()
                while state do
                    task.wait(0.5)
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local label = CreateLabelBP(player)
                            if label then
                                local beastPowers = player.Character:FindFirstChild("BeastPowers")
                                if beastPowers then
                                    local numberValue = beastPowers:FindFirstChildOfClass("NumberValue")
                                    if numberValue then
                                        local roundedValue = math.round(numberValue.Value * 100)
                                        label.Text = tostring(roundedValue) .. "%"
                                    else
                                        label.Text = ""
                                    end
                                else
                                    label.Text = ""
                                end
                            else
                                label.Text = ""
                            end
                        end
                    end
                end
            end)
        else
            if BeastPowerLoop2 then task.cancel(BeastPowerLoop2) BeastPowerLoop2 = nil end
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local bb = player.Character.HumanoidRootPart:FindFirstChild("BeastPowerBillboard")
                    if bb then bb:Destroy() end
                end
            end
        end
    end)
    
    Library:CreateToggle(Page, "Beast Spawn Timer", false, function(state)
        -- Código removido. Toggle vazia pronta para novos scripts.
    end)
end
