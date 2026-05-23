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

    -- =========================================================================
    -- VARIÁVEIS DE CONTROLE GLOBAL (Módulo)
    -- =========================================================================
    
    -- Vars Beast Power
    local BeastPowerConnection1 = nil
    local BeastPowerConnection2 = nil
    local uiFrameBP, uiLabelBP = nil, nil
    local trackedPowerValue = nil
    local lastPercent = 0
    local isDraining = false
    local BeastPowerLoop2 = nil

    -- Vars Computer Progress
    local CompProgLoop = nil
    local CompProgConns = {}
    local compHighlightEnabled = false
    local currentComputerStyle = "Default"

    -- Vars Door Progress
    local DoorProgLoop = nil
    local DoorProgHeartbeat = nil
    local doorAddedConn = nil
    local trackedNormalDoors = {}
    local doorHighlightEnabled = false
    local currentDoorStyle = "Default"
    local doorMaxDistance = 150
    local lastMap = nil

    -- Vars ExitDoor Progress
    local ExitDoorConn = nil
    local ExitDoorAdded = nil
    local ExitDoorRemoving = nil
    local trackedExitDoors = {}
    local actionValCache = {}
    local exitHighlightEnabled = false

    -- Vars WalkSpeed Detector
    local speedRenderConn = nil
    local speedPlayerAdded = nil
    local speedPlayerRemoving = nil
    local activePlayers = {}
    local speedCharConns = {}

    -- Vars Wallhop Counter
    local WallhopStateConn = nil
    local WallhopCharConn = nil
    local WallhopTimerConn = nil

    -- Vars GetUp Timer
    local getupActive = false
    local getupConns = {} 
    local activeConnections = {} 
    local getupGui = nil
    local getupList = nil
    local activeGetUp = {}

    -- Vars Beast Spawn Timer
    local BeastSpawnActive = false
    local BeastSpawnLoopThread = nil
    local BeastSpawnRenderConn = nil
    
    -- IsGameActive carregado de forma assíncrona para não travar a UI em outros jogos
    local IsGameActive = nil
    task.spawn(function()
        IsGameActive = ReplicatedStorage:WaitForChild("IsGameActive", 2)
    end)

    -- =========================================================================
    -- SECTION: ACTION TIMERS (Coluna Esquerda)
    -- =========================================================================
    Library:CreateSection(Page, "Action Timers")
    
    -- 1. Computer Progress
    Library:CreateToggle(Page, "Computer Progress", false, function(state)
        if state then
            local function createProgressBar(parent)
                if currentComputerStyle == "Default" or currentComputerStyle == "Style 1" then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "ProgressBar"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 80, 0, 26)
                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = parent

                    local background = Instance.new("Frame")
                    background.Name = "BgBar"
                    background.Size = UDim2.new(1, 0, 1, 0)
                    background.BackgroundTransparency = 1
                    background.BorderSizePixel = 0
                    background.Parent = billboard

                    local text = Instance.new("TextLabel")
                    text.Name = "ProgressText"
                    text.Size = UDim2.new(1, 0, 0, 14)
                    text.Position = UDim2.new(0, 0, 0, 0)
                    text.BackgroundTransparency = 1
                    text.TextColor3 = Color3.fromRGB(255, 255, 255)
                    text.TextSize = 12
                    text.Font = Enum.Font.GothamBold
                    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    text.TextStrokeTransparency = 0
                    text.Text = "0.0%"
                    text.Parent = background

                    local track = Instance.new("Frame")
                    track.Name = "Track"
                    track.Size = UDim2.new(0, 70, 0, 6)
                    track.Position = UDim2.new(0.5, -35, 0, 16)
                    
                    if currentComputerStyle == "Default" then
                        track.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                    else
                        track.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    end
                    
                    track.BorderSizePixel = 0
                    track.Parent = background

                    local trackCorner = Instance.new("UICorner")
                    trackCorner.CornerRadius = UDim.new(0, 2)
                    trackCorner.Parent = track

                    local trackStroke = Instance.new("UIStroke")
                    trackStroke.Thickness = 1
                    trackStroke.Color = Color3.fromRGB(0, 0, 0)
                    trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    trackStroke.Parent = track

                    local bar = Instance.new("Frame")
                    bar.Name = "Bar"
                    bar.Size = UDim2.new(0, 0, 1, 0)
                    
                    if currentComputerStyle == "Default" then
                        bar.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
                    else
                        bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    end
                    
                    bar.BorderSizePixel = 0
                    bar.Parent = track

                    local barCorner = Instance.new("UICorner")
                    barCorner.CornerRadius = UDim.new(0, 2)
                    barCorner.Parent = bar

                    return billboard, bar, text
                elseif currentComputerStyle == "Style 1" then
                    -- Design: design computer 2.txt
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "ProgressBar"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 110, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 4.5, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = parent

                    local text = Instance.new("TextLabel")
                    text.Name = "ProgressText"
                    text.Size = UDim2.new(1, 0, 0, 20)
                    text.BackgroundTransparency = 1
                    text.TextColor3 = Color3.fromRGB(255, 255, 255)
                    text.TextStrokeTransparency = 0
                    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    text.Font = Enum.Font.GothamBold
                    text.TextSize = 16
                    text.Text = "0%"
                    text.Parent = billboard

                    local bgBar = Instance.new("Frame")
                    bgBar.Name = "BackgroundBar"
                    bgBar.Size = UDim2.new(1, 0, 0, 6)
                    bgBar.Position = UDim2.new(0, 0, 1, -6)
                    bgBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    bgBar.BorderSizePixel = 1
                    bgBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    bgBar.Parent = billboard

                    local bar = Instance.new("Frame")
                    bar.Name = "Bar"
                    bar.Size = UDim2.new(0, 0, 1, 0)
                    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    bar.BorderSizePixel = 0
                    bar.Parent = bgBar

                    return billboard, bar, text
                else
                    -- Design: design computer 3.txt (Style 2)
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "ProgressBar"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 120, 0, 12)
                    billboard.StudsOffset = Vector3.new(0, 4.2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = parent

                    local background = Instance.new("Frame")
                    background.Name = "BgBar"
                    background.Size = UDim2.new(1, 0, 1, 0)
                    background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
                    background.BorderSizePixel = 2
                    background.BorderColor3 = Color3.fromRGB(255, 255, 255)
                    background.Parent = billboard

                    local bar = Instance.new("Frame")
                    bar.Name = "Bar"
                    bar.Size = UDim2.new(0, 0, 1, 0)
                    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    bar.BorderSizePixel = 0
                    bar.Parent = background

                    local text = Instance.new("TextLabel")
                    text.Name = "ProgressText"
                    text.Size = UDim2.new(1, 0, 1, 0)
                    text.BackgroundTransparency = 1
                    text.TextColor3 = Color3.fromRGB(255, 255, 255)
                    text.TextStrokeTransparency = 0
                    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    text.TextScaled = true
                    text.Font = Enum.Font.SciFi
                    text.Text = "0.0%"
                    text.Parent = background

                    return billboard, bar, text
                end
            end

            local function setupComputer(tableModel)
                if tableModel:FindFirstChild("ProgressBar") then return end

                local billboard, bar, text = createProgressBar(tableModel)
                
                local highlight = tableModel:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
                highlight.Name = "ComputerHighlight"
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                highlight.OutlineTransparency = 0
                highlight.Enabled = compHighlightEnabled
                highlight.Parent = tableModel

                local screen = tableModel:FindFirstChild("Screen")
                local triggers = {}
                for _, child in ipairs(tableModel:GetChildren()) do
                    if child:IsA("BasePart") and child.Name:find("ComputerTrigger") then
                        table.insert(triggers, child)
                    end
                end

                local savedProgress = 0
                local lastSize = -1
                local overlapParams = OverlapParams.new()
                overlapParams.FilterType = Enum.RaycastFilterType.Include

                local updateInterval = 0.08
                local accumulatedTime = 0

                local connection
                connection = RunService.Heartbeat:Connect(function(dt)
                    accumulatedTime = accumulatedTime + dt
                    if accumulatedTime < updateInterval then return end
                    accumulatedTime = 0

                    if not tableModel or not tableModel.Parent or not bar or not text then
                        connection:Disconnect()
                        return
                    end

                    local isGreen = false
                    if screen and screen.Parent then
                        highlight.FillColor = screen.Color
                        if screen.Color.G > screen.Color.R and screen.Color.G > screen.Color.B then
                            isGreen = true
                        end
                    end

                    highlight.Enabled = compHighlightEnabled

                    if isGreen then
                        savedProgress = 1
                    else
                        local highestTouch = 0
                        local characterParts = {}
                        local playersList = Players:GetPlayers()
                        
                        for i = 1, #playersList do
                            local char = playersList[i].Character
                            if char then
                                table.insert(characterParts, char)
                            end
                        end

                        if #characterParts > 0 then
                            overlapParams.FilterDescendantsInstances = characterParts
                            for i = 1, #triggers do
                                local part = triggers[i]
                                if part and part.Parent then
                                    local touchingParts = Workspace:GetPartsInPart(part, overlapParams)
                                    for j = 1, #touchingParts do
                                        local character = touchingParts[j].Parent
                                        local plr = Players:GetPlayerFromCharacter(character)
                                        if plr then
                                            local tpsm = plr:FindFirstChild("TempPlayerStatsModule")
                                            if tpsm then
                                                local ragdoll = tpsm:FindFirstChild("Ragdoll")
                                                local ap = tpsm:FindFirstChild("ActionProgress")
                                                if ragdoll and typeof(ragdoll.Value) == "boolean" and not ragdoll.Value then
                                                    if ap and typeof(ap.Value) == "number" then
                                                        highestTouch = math.max(highestTouch, ap.Value)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        savedProgress = math.max(savedProgress, highestTouch)
                    end

                    if savedProgress ~= lastSize then
                        lastSize = savedProgress
                        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                        local tween = TweenService:Create(bar, tweenInfo, {Size = UDim2.new(savedProgress, 0, 1, 0)})
                        tween:Play()
                    end

                    if currentComputerStyle == "Default" then
                        if savedProgress >= 1 then
                            bar.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
                            text.TextColor3 = Color3.fromRGB(0, 255, 140)
                            text.Text = "COMPLETED"
                        else
                            bar.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
                            text.TextColor3 = Color3.fromRGB(255, 255, 255)
                            text.Text = string.format("%.1f%%", math.floor(savedProgress * 200 + 0.1) / 2)
                        end
                    elseif currentComputerStyle == "Style 1" then
                        if savedProgress >= 0.99 then
                            bar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                            text.TextColor3 = Color3.fromRGB(0, 255, 100)
                            text.Text = "DONE"
                        else
                            bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            text.TextColor3 = Color3.fromRGB(255, 255, 255)
                            text.Text = string.format("%d%%", math.floor(savedProgress * 100))
                        end
                    else
                        if savedProgress >= 1 then
                            bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                            text.Text = "COMPLETED"
                        else
                            bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            text.Text = string.format("%.1f%%", math.floor(savedProgress * 200 + 0.1) / 2)
                        end
                    end
                end)
                table.insert(CompProgConns, connection)
            end

            CompProgLoop = task.spawn(function()
                while state do
                    local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
                    if currentMap and currentMap.Value ~= "" then
                        local mapName = tostring(currentMap.Value)
                        local map = Workspace:FindFirstChild(mapName)
                        if map then
                            for _, obj in ipairs(map:GetChildren()) do
                                if obj.Name == "ComputerTable" then
                                    setupComputer(obj)
                                end
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        else
            if CompProgLoop then task.cancel(CompProgLoop); CompProgLoop = nil end
            for _, c in ipairs(CompProgConns) do 
                if c then c:Disconnect() end 
            end
            table.clear(CompProgConns)
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "ProgressBar" and obj:IsA("BillboardGui") then obj:Destroy() end
                if obj.Name == "ComputerHighlight" and obj:IsA("Highlight") then obj:Destroy() end
            end
        end
    end)
    
    -- 2. Door Progress
    Library:CreateToggle(Page, "Door Progress", false, function(state)
        if state then
            local DT_CONFIG = { 
                DOOR_NAMES = {["SingleDoor"]=true,["DoubleDoor"]=true,["SlidingDoor"]=true}, 
                BLACKLIST = {["ExitDoor"]=true,["Decorative"]=true,["FakeDoor"]=true,["ElevatorDoor"]=true, ["Closet"]=false} 
            }

            local DT_COLORS = { 
                BAR_BG = Color3.fromRGB(35, 30, 30), 
                MUSTARD = Color3.fromRGB(205, 135, 25), 
                WHITE = Color3.fromRGB(230, 230, 230),
                HL_CLOSE = Color3.fromRGB(255, 0, 0),
                HL_OPENING = Color3.fromRGB(255, 200, 0),
                HL_OPEN = Color3.fromRGB(0, 255, 100)
            }

            local function createDoorHUD(parent)
                if currentDoorStyle == "Default" then
                    -- Default design
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "NormalDoorGUI"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 90, 0, 35) 
                    billboard.StudsOffset = Vector3.new(0, 1, 0)
                    billboard.AlwaysOnTop = true
                    billboard.MaxDistance = doorMaxDistance
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
                    
                    return billboard, fill, text, bgBar
                elseif currentDoorStyle == "Style 1" then
                    -- Design: design door progress 2.txt
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "NormalDoorGUI"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.fromOffset(90, 22)
                    billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 0.1)
                    billboard.AlwaysOnTop = true
                    billboard.MaxDistance = doorMaxDistance
                    billboard.Parent = parent

                    local text = Instance.new("TextLabel")
                    text.Name = "PercentText"
                    text.Size = UDim2.new(1, 0, 0.45, 0)
                    text.BackgroundTransparency = 1
                    text.Text = "0.0%"
                    text.TextColor3 = Color3.fromRGB(255, 210, 140)
                    text.TextStrokeTransparency = 0.6
                    text.Font = Enum.Font.GothamMedium
                    text.TextScaled = true
                    text.ZIndex = 6
                    text.Parent = billboard

                    local bgBar = Instance.new("Frame")
                    bgBar.Name = "BgBar"
                    bgBar.Size = UDim2.new(1, 0, 0.35, 0)
                    bgBar.Position = UDim2.new(0, 0, 0.6, 0)
                    bgBar.BackgroundColor3 = Color3.fromRGB(25, 15, 5)
                    bgBar.BackgroundTransparency = 0.5
                    bgBar.BorderSizePixel = 0
                    bgBar.ZIndex = 5
                    bgBar.Parent = billboard

                    local fill = Instance.new("Frame")
                    fill.Name = "Fill"
                    fill.Size = UDim2.new(0, 0, 1, 0)
                    fill.BackgroundColor3 = Color3.fromRGB(170, 100, 40)
                    fill.BorderSizePixel = 0
                    fill.ZIndex = 6
                    fill.Parent = bgBar

                    return billboard, fill, text, bgBar
                else
                    -- Design: design door progress.txt (Style 2)
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "NormalDoorGUI"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 100, 0, 40) 
                    billboard.StudsOffset = Vector3.new(0, 0, 0)
                    billboard.AlwaysOnTop = true
                    billboard.MaxDistance = doorMaxDistance
                    billboard.Parent = parent

                    local text = Instance.new("TextLabel")
                    text.Name = "PercentText"
                    text.Size = UDim2.new(1, 0, 0, 15)
                    text.Position = UDim2.new(0, 0, 0.3, 0)
                    text.BackgroundTransparency = 1
                    text.Text = "CLOSE"
                    text.TextColor3 = Color3.fromRGB(255, 0, 0)
                    text.TextStrokeTransparency = 0.8
                    text.TextStrokeColor3 = Color3.new(0,0,0)
                    text.Font = Enum.Font.GothamBold
                    text.TextSize = 13
                    text.ZIndex = 5
                    text.Parent = billboard

                    local bgBar = Instance.new("Frame")
                    bgBar.Name = "BgBar"
                    bgBar.Size = UDim2.new(0.8, 0, 0, 6)
                    bgBar.Position = UDim2.new(0.1, 0, 0.7, 0)
                    bgBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    bgBar.BorderSizePixel = 1
                    bgBar.Visible = false
                    bgBar.ZIndex = 5
                    bgBar.Parent = billboard

                    local fill = Instance.new("Frame")
                    fill.Name = "Fill"
                    fill.Size = UDim2.new(0, 0, 1, 0)
                    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                    fill.BorderSizePixel = 0
                    fill.ZIndex = 6
                    fill.Parent = bgBar

                    return billboard, fill, text, bgBar
                end
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
                hl.Enabled = doorHighlightEnabled
                hl.Parent = model
                return hl
            end

            local function getRealDoorPart(model)
                local explicitDoor = model:FindFirstChild("Door") or model:FindFirstChild("Left") or model:FindFirstChild("Right")
                if explicitDoor and explicitDoor:IsA("BasePart") then return explicitDoor end
                
                local biggestPart = nil
                local maxVolume = 0
                local descendants = model:GetDescendants()
                
                for i = 1, #descendants do
                    local part = descendants[i]
                    if part:IsA("BasePart") then
                        local name = part.Name
                        if not string.find(name, "Frame", 1, true) and not string.find(name, "Wall", 1, true) and part.Transparency < 1 then
                            local size = part.Size
                            local v = size.X * size.Y * size.Z
                            if v > maxVolume then 
                                maxVolume = v
                                biggestPart = part 
                            end
                        end
                    end
                end
                return biggestPart or model.PrimaryPart
            end

            local function setupNormalDoor(doorModel)
                if trackedNormalDoors[doorModel] then return end
                if DT_CONFIG.BLACKLIST[doorModel.Name] then return end
                
                local name = doorModel.Name
                if string.find(name, "Exit", 1, true) or string.find(name, "Decor", 1, true) then return end
                
                local anchorPart = getRealDoorPart(doorModel)
                if not anchorPart then return end
                
                if anchorPart:FindFirstChild("NormalDoorGUI") then anchorPart.NormalDoorGUI:Destroy() end
                
                local billboard, bar, text, bgBar = createDoorHUD(anchorPart)
                local highlight = createHighlight(doorModel)
                
                trackedNormalDoors[doorModel] = { 
                    Model = doorModel, 
                    Anchor = anchorPart, 
                    InitialCFrame = anchorPart.CFrame, 
                    Billboard = billboard, 
                    Bar = bar, 
                    Text = text,
                    BgBar = bgBar,
                    Highlight = highlight,
                    LastState = "Closed",
                    LastProgress = -1
                }
            end

            local function cleanupNormalDoors()
                if doorAddedConn then doorAddedConn:Disconnect(); doorAddedConn = nil end
                for doorModel, data in pairs(trackedNormalDoors) do
                    if data.Billboard then data.Billboard:Destroy() end
                    if data.Highlight then data.Highlight:Destroy() end
                end
                table.clear(trackedNormalDoors)
            end

            DoorProgLoop = task.spawn(function()
                while state do
                    local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
                    local mapName = currentMap and tostring(currentMap.Value) or ""
                    
                    if mapName ~= "" and lastMap ~= mapName then
                        lastMap = mapName
                        cleanupNormalDoors()

                        local map = Workspace:FindFirstChild(mapName)
                        if map then
                            for _, obj in ipairs(map:GetDescendants()) do
                                if obj:IsA("Model") and DT_CONFIG.DOOR_NAMES[obj.Name] and not DT_CONFIG.BLACKLIST[obj.Name] then 
                                    setupNormalDoor(obj) 
                                end
                            end
                            
                            doorAddedConn = map.DescendantAdded:Connect(function(obj)
                                if obj:IsA("Model") and DT_CONFIG.DOOR_NAMES[obj.Name] and not DT_CONFIG.BLACKLIST[obj.Name] then 
                                    task.defer(setupNormalDoor, obj)
                                end
                            end)
                        end
                    elseif mapName == "" and lastMap ~= "" then
                        lastMap = ""
                        cleanupNormalDoors()
                    end
                    task.wait(1.5)
                end
            end)

            local accum = 0
            local currentDoorInteractions = {}

            DoorProgHeartbeat = RunService.Heartbeat:Connect(function(dt)
                accum = accum + dt
                if accum < 0.1 then return end
                accum = 0
                
                table.clear(currentDoorInteractions)
                local playersList = Players:GetPlayers()

                for i = 1, #playersList do
                    local player = playersList[i]
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
                                    local minDistanceSq = 225
                                    local hrpPos = hrp.Position
                                    
                                    for doorModel, data in pairs(trackedNormalDoors) do
                                        if data.Anchor and data.Anchor.Parent then
                                            local anchorPos = data.Anchor.Position
                                            local dx = anchorPos.X - hrpPos.X
                                            local dy = anchorPos.Y - hrpPos.Y
                                            local dz = anchorPos.Z - hrpPos.Z
                                            local distSq = dx*dx + dy*dy + dz*dz
                                            
                                            if distSq < minDistanceSq then
                                                minDistanceSq = distSq
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
                
                local cam = Workspace.CurrentCamera
                local camPos = cam and cam.CFrame.Position or Vector3.new(0, 0, 0)

                for doorModel, data in pairs(trackedNormalDoors) do
                    if not doorModel.Parent or not data.Anchor or not data.Anchor.Parent then
                        if data.Billboard then data.Billboard:Destroy() end
                        if data.Highlight then data.Highlight:Destroy() end
                        trackedNormalDoors[doorModel] = nil
                        continue
                    end

                    -- Otimização Matemática de Distância sem alocação de Vector3
                    local anchorPos = data.Anchor.Position
                    local dx = anchorPos.X - camPos.X
                    local dy = anchorPos.Y - camPos.Y
                    local dz = anchorPos.Z - camPos.Z
                    local distSq = dx*dx + dy*dy + dz*dz
                    local dist = math.sqrt(distSq)

                    if dist > doorMaxDistance then
                        if data.Billboard.Enabled then
                            data.Billboard.Enabled = false
                            data.Highlight.Enabled = false
                        end
                        continue
                    else
                        data.Billboard.Enabled = true
                        data.Highlight.Enabled = doorHighlightEnabled
                    end

                    local currentCF = data.Anchor.CFrame
                    local initialPos = data.InitialCFrame.Position
                    local currentPos = currentCF.Position
                    
                    local mx = currentPos.X - initialPos.X
                    local my = currentPos.Y - initialPos.Y
                    local mz = currentPos.Z - initialPos.Z
                    local distMovedSq = mx*mx + my*my + mz*mz
                    
                    local dot = currentCF.LookVector:Dot(data.InitialCFrame.LookVector)
                    
                    if data.Anchor.CanCollide == true then
                        if dot < 0.9 or distMovedSq > 0.25 then
                            data.InitialCFrame = currentCF
                            dot = 1
                            distMovedSq = 0
                        end
                    end

                    local isPhysicallyOpen = false
                    if not data.Anchor.CanCollide or dot < 0.85 or distMovedSq > 0.25 or data.Anchor.Transparency > 0.8 then
                        isPhysicallyOpen = true
                    end
                    
                    local interactionVal = currentDoorInteractions[doorModel] or 0

                    if currentDoorStyle == "Default" or currentDoorStyle == "Style 1" then
                        local baseColor = (currentDoorStyle == "Default") and Color3.fromRGB(205, 135, 25) or Color3.fromRGB(255, 210, 140)
                        local barColor = (currentDoorStyle == "Default") and Color3.fromRGB(205, 135, 25) or Color3.fromRGB(170, 100, 40)

                        if isPhysicallyOpen then
                            if data.LastState ~= "Open" then
                                data.LastState = "Open"
                                data.Bar.Size = UDim2.new(1, 0, 1, 0)
                                data.Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                data.Text.TextColor3 = Color3.fromRGB(255, 255, 255)
                                data.Text.Text = "100.0%"
                                data.Highlight.FillColor = DT_COLORS.HL_OPEN
                            end
                        elseif interactionVal > 0.001 then 
                            if data.LastState ~= "Opening" or math.abs(data.LastProgress - interactionVal) > 0.005 then
                                data.LastState = "Opening"
                                data.LastProgress = interactionVal
                                data.Bar.Size = UDim2.new(math.clamp(interactionVal, 0, 1), 0, 1, 0)
                                data.Bar.BackgroundColor3 = barColor
                                data.Text.TextColor3 = baseColor
                                data.Text.Text = string.format("%.1f%%", interactionVal * 100)
                                data.Highlight.FillColor = Color3.fromRGB(255, 200, 0)
                            end
                        else
                            if data.LastState ~= "Closed" then
                                data.LastState = "Closed"
                                data.Bar.Size = UDim2.new(0, 0, 1, 0)
                                data.Bar.BackgroundColor3 = barColor
                                data.Text.TextColor3 = baseColor
                                data.Text.Text = "0.0%"
                                data.Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                            end
                        end
                    else
                        local COLORS_STYLE2 = {
                            CLOSE = Color3.fromRGB(255, 0, 0),
                            OPENING = Color3.fromRGB(255, 255, 0),
                            OPEN = Color3.fromRGB(0, 255, 100)
                        }

                        if isPhysicallyOpen then
                            if data.LastState ~= "Open" then
                                data.LastState = "Open"
                                data.Text.Text = "OPEN"
                                data.Text.TextColor3 = COLORS_STYLE2.OPEN
                                data.Highlight.FillColor = COLORS_STYLE2.OPEN
                                data.BgBar.Visible = false
                            end
                        elseif interactionVal > 0.05 then 
                            data.LastState = "Opening"
                            data.Text.Text = "OPENING"
                            data.Text.TextColor3 = COLORS_STYLE2.OPENING
                            data.Highlight.FillColor = COLORS_STYLE2.OPENING
                            data.BgBar.Visible = true
                            data.Bar.Size = UDim2.new(math.clamp(interactionVal, 0, 1), 0, 1, 0)
                        else
                            if data.LastState ~= "Closed" then
                                data.LastState = "Closed"
                                data.Text.Text = "CLOSE"
                                data.Text.TextColor3 = COLORS_STYLE2.CLOSE
                                data.Highlight.FillColor = COLORS_STYLE2.CLOSE
                                data.BgBar.Visible = false
                            end
                        end
                    end
                    
                    if data.Highlight then
                        data.Highlight.Enabled = doorHighlightEnabled
                    end
                end
            end)
        else
            if DoorProgLoop then task.cancel(DoorProgLoop); DoorProgLoop = nil end
            if DoorProgHeartbeat then DoorProgHeartbeat:Disconnect(); DoorProgHeartbeat = nil end
            if doorAddedConn then doorAddedConn:Disconnect(); doorAddedConn = nil end
            lastMap = nil -- Reseta para permitir remontagem imediata ao ligar
            for doorModel, data in pairs(trackedNormalDoors) do
                if data.Billboard then data.Billboard:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
            end
            table.clear(trackedNormalDoors)
        end
    end)
    
    -- 3. ExitDoor Progress
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
                highlight.Enabled = exitHighlightEnabled
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
                        
                        if data.Highlight then
                            data.Highlight.Enabled = exitHighlightEnabled
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
    
    -- 4. WalkSpeed Detector
    Library:CreateToggle(Page, "WalkSpeed Detector", false, function(state)
        if state then
            local function createSpeedTag(character, head)
                local tag = character:FindFirstChild("SpeedTag")
                local label
                
                if not tag then
                    tag = Instance.new("BillboardGui")
                    tag.Name = "SpeedTag"
                    tag.Adornee = head
                    tag.Size = UDim2.new(0, 60, 0, 20)
                    tag.StudsOffset = Vector3.new(0, 2.5, 0)
                    tag.AlwaysOnTop = true

                    label = Instance.new("TextLabel")
                    label.Name = "SpeedText"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextSize = 18
                    label.Font = Enum.Font.Code
                    label.TextStrokeTransparency = 0
                    label.TextStrokeColor3 = Color3.new(0, 0, 0)
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.Parent = tag
                    
                    tag.Parent = character
                else
                    label = tag:FindFirstChild("SpeedText")
                end
                
                return label
            end

            local function setupCharacter(player, character)
                local humanoid = character:WaitForChild("Humanoid", 5)
                local root = character:WaitForChild("HumanoidRootPart", 5)
                local head = character:WaitForChild("Head", 5)
                
                if not (humanoid and root and head) then return end
                
                local label = createSpeedTag(character, head)
                if label then
                    activePlayers[player] = {
                        root = root,
                        humanoid = humanoid,
                        label = label
                    }
                end
            end

            local function onPlayerAdded(player)
                local connection = player.CharacterAdded:Connect(function(character)
                    setupCharacter(player, character)
                end)
                speedCharConns[player] = connection
                
                if player.Character then
                    setupCharacter(player, player.Character)
                end
            end

            speedPlayerAdded = Players.PlayerAdded:Connect(onPlayerAdded)
            speedPlayerRemoving = Players.PlayerRemoving:Connect(function(player)
                activePlayers[player] = nil
                if speedCharConns[player] then
                    speedCharConns[player]:Disconnect()
                    speedCharConns[player] = nil
                end
            end)

            for _, player in ipairs(Players:GetPlayers()) do
                onPlayerAdded(player)
            end

            speedRenderConn = RunService.RenderStepped:Connect(function()
                for player, data in pairs(activePlayers) do
                    local root = data.root
                    local humanoid = data.humanoid
                    
                    if root and root.Parent and humanoid and humanoid.Health > 0 then
                        if humanoid.MoveDirection.Magnitude == 0 then
                            data.label.Text = "0.0"
                        else
                            local vel = root.AssemblyLinearVelocity
                            local vx = vel.X
                            local vz = vel.Z
                            
                            local speed = math.sqrt(vx * vx + vz * vz)
                            data.label.Text = string.format("%.1f", speed)
                        end
                    else
                        activePlayers[player] = nil
                    end
                end
            end)
        else
            if speedPlayerAdded then speedPlayerAdded:Disconnect(); speedPlayerAdded = nil end
            if speedPlayerRemoving then speedPlayerRemoving:Disconnect(); speedPlayerRemoving = nil end
            if speedRenderConn then speedRenderConn:Disconnect(); speedRenderConn = nil end
            for player, conn in pairs(speedCharConns) do
                if conn then conn:Disconnect() end
            end
            table.clear(speedCharConns)
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char and char:FindFirstChild("SpeedTag") then
                    char.SpeedTag:Destroy()
                end
            end
            table.clear(activePlayers)
        end
    end)

    -- 5. Wallhop Counter
    Library:CreateToggle(Page, "Wallhop Counter", false, function(state)
        if state then
            if CoreGui:FindFirstChild("WallhopCounterUI") then
                CoreGui.WallhopCounterUI:Destroy()
            end

            local sg = Instance.new("ScreenGui")
            sg.Name = "WallhopCounterUI"
            sg.DisplayOrder = 1000
            sg.Parent = CoreGui

            local label = Instance.new("TextLabel")
            label.Name = "ComboLabel"
            label.Size = UDim2.new(0, 200, 0, 40)
            label.Position = UDim2.new(0.85, 0, 0.6, 0)
            label.AnchorPoint = Vector2.new(0.5, 0.5)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBlack
            label.TextSize = 28
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextTransparency = 1
            label.Text = "Wallhops: 0"
            label.Parent = sg

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 2.5
            stroke.Transparency = 1
            stroke.Parent = label

            local timerLabel = Instance.new("TextLabel")
            timerLabel.Name = "TimerLabel"
            timerLabel.Size = UDim2.new(1, 0, 0, 20)
            timerLabel.Position = UDim2.new(0.5, 0, 1, 0)
            timerLabel.AnchorPoint = Vector2.new(0.5, 0)
            timerLabel.BackgroundTransparency = 1
            timerLabel.Font = Enum.Font.GothamBold
            timerLabel.TextSize = 18
            timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            timerLabel.TextTransparency = 1
            timerLabel.Text = "0.0s"
            timerLabel.Parent = label

            local timerStroke = Instance.new("UIStroke")
            timerStroke.Color = Color3.fromRGB(0, 0, 0)
            timerStroke.Thickness = 2
            timerStroke.Transparency = 1
            timerStroke.Parent = timerLabel

            local uiVisivel = false

            local function MostrarUI()
                if not uiVisivel then
                    uiVisivel = true
                    TweenService:Create(label, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
                    TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
                    TweenService:Create(timerLabel, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
                    TweenService:Create(timerStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
                end
            end

            local function EsconderUI()
                if uiVisivel then
                    uiVisivel = false
                    TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                    TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
                    TweenService:Create(timerLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                    TweenService:Create(timerStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
                end
            end

            local function EfeitoPulo()
                label.TextSize = 38
                TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {TextSize = 28}):Play()
            end

            local function AtualizarCor(combo)
                local cor = Color3.fromRGB(255, 255, 255)
                if combo >= 3 and combo <= 4 then cor = Color3.fromRGB(255, 215, 0)
                elseif combo >= 5 and combo <= 6 then cor = Color3.fromRGB(255, 100, 0)
                elseif combo >= 7 then cor = Color3.fromRGB(255, 0, 0) end
                
                TweenService:Create(label, TweenInfo.new(0.15), {TextColor3 = cor}):Play()
                TweenService:Create(timerLabel, TweenInfo.new(0.15), {TextColor3 = cor}):Play()
            end

            local hopCount = 0
            local tempoInicioCombo = 0

            WallhopTimerConn = RunService.RenderStepped:Connect(function()
                if hopCount > 0 then
                    local tempoDecorrido = os.clock() - tempoInicioCombo
                    timerLabel.Text = string.format("%.1fs", tempoDecorrido)
                end
            end)

            local function IniciarMonitoramento(char)
                local humanoid = char:WaitForChild("Humanoid", 3)
                local hrp = char:WaitForChild("HumanoidRootPart", 3)
                if not humanoid or not hrp then return end

                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude

                WallhopStateConn = humanoid.StateChanged:Connect(function(velho, novo)
                    if novo == Enum.HumanoidStateType.Jumping then
                        if velho == Enum.HumanoidStateType.Climbing then return end

                        local hit = Workspace:Blockcast(CFrame.new(hrp.Position), Vector3.new(1.2, 0.1, 1.2), Vector3.new(0, -4.5, 0), rayParams)
                        
                        if not hit then
                            if hopCount == 0 then
                                tempoInicioCombo = os.clock()
                            end
                            
                            hopCount = hopCount + 1
                            label.Text = "Wallhops: " .. hopCount
                            AtualizarCor(hopCount)
                            EfeitoPulo()
                            MostrarUI()
                        else
                            hopCount = 0
                            EsconderUI()
                        end

                    elseif novo == Enum.HumanoidStateType.Landed then
                        task.delay(0.15, function()
                            pcall(function()
                                local estadoAtual = humanoid:GetState()
                                if estadoAtual == Enum.HumanoidStateType.Running or estadoAtual == Enum.HumanoidStateType.RunningNoPhysics then
                                    if hopCount > 0 then
                                        hopCount = 0
                                        EsconderUI()
                                    end
                                end
                            end)
                        end)
                    end
                end)
            end

            if LocalPlayer.Character then
                IniciarMonitoramento(LocalPlayer.Character)
            end

            WallhopCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
                hopCount = 0
                EsconderUI()
                IniciarMonitoramento(char)
            end)
        else
            if WallhopStateConn then WallhopStateConn:Disconnect(); WallhopStateConn = nil end
            if WallhopCharConn then WallhopCharConn:Disconnect(); WallhopCharConn = nil end
            if WallhopTimerConn then WallhopTimerConn:Disconnect(); WallhopTimerConn = nil end
            if CoreGui:FindFirstChild("WallhopCounterUI") then
                CoreGui.WallhopCounterUI:Destroy()
            end
        end
    end)

    -- =========================================================================
    -- SECTION: BEAST INDICATORS (Coluna Direita)
    -- =========================================================================
    Library:CreateSection(Page, "Beast Indicators")
    
    -- 1. GetUp Timer
    Library:CreateToggle(Page, "GetUp Timer", false, function(state)
        if state then
            getupActive = true
            local CONFIG_GETUP = {
                Font = Enum.Font.Garamond,
                NameColor = Color3.fromRGB(255, 255, 255),
                StrokeColor = Color3.fromRGB(0, 0, 0),
                StrokeThickness = 2.5,
                Duration = 28
            }
            local UI_UPDATE_INTERVAL = 0.033 

            local function colorGetUp(t)
                local red = Color3.fromRGB(255, 0, 0) 
                local yellow = Color3.fromRGB(255, 220, 40)
                local green = Color3.fromRGB(60, 255, 60)
                if t > 0.5 then
                    return yellow:Lerp(green, (t - 0.5) * 2)
                else
                    return red:Lerp(yellow, t * 2)
                end
            end

            local function applyStroke(parent)
                local stroke = Instance.new("UIStroke")
                stroke.Color = CONFIG_GETUP.StrokeColor
                stroke.Thickness = CONFIG_GETUP.StrokeThickness
                stroke.Transparency = 0
                stroke.LineJoinMode = Enum.LineJoinMode.Round
                stroke.Parent = parent
                return stroke
            end

            local function getUIContainer()
                local success, container = pcall(function() return CoreGui end)
                return (success and container) or LocalPlayer:WaitForChild("PlayerGui")
            end

            local function cleanupPlayer(p, con, frame, char)
                if char then
                    local head = char:FindFirstChild("Head")
                    local bb = head and head:FindFirstChild("RC")
                    if bb then bb:Destroy() end
                end
                if frame then frame:Destroy() end
                activeGetUp[p] = nil
                if con then
                    con:Disconnect()
                    activeConnections[p] = nil
                end
            end

            local uiParent = getUIContainer()
            if uiParent:FindFirstChild("RagdollCounterGui") then 
                uiParent.RagdollCounterGui:Destroy() 
            end

            getupGui = Instance.new("ScreenGui")
            getupGui.Name = "RagdollCounterGui"
            getupGui.ResetOnSpawn = false
            getupGui.Parent = uiParent

            getupList = Instance.new("Frame", getupGui)
            getupList.Size = UDim2.new(0, 160, 0, 400)
            getupList.Position = UDim2.new(1, -60, 0.32, 0) 
            getupList.AnchorPoint = Vector2.new(1, 0) 
            getupList.BackgroundTransparency = 1

            local layout = Instance.new("UIListLayout", getupList)
            layout.VerticalAlignment = Enum.VerticalAlignment.Top
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            layout.Padding = UDim.new(0, 8)

            local function billboard(p, head)
                if p == LocalPlayer or not head then return nil end 
                local old = head:FindFirstChild("RC")
                if old then old:Destroy() end
                
                local bb = Instance.new("BillboardGui", head)
                bb.Name = "RC"
                bb.Size = UDim2.new(5, 0, 3, 0) 
                bb.StudsOffset = Vector3.new(0, 3, 0) 
                bb.AlwaysOnTop = true
                
                local container = Instance.new("Frame", bb)
                container.Size = UDim2.fromScale(1, 1)
                container.BackgroundTransparency = 1
                
                local nameLbl = Instance.new("TextLabel", container)
                nameLbl.Size = UDim2.new(1, 0, 0.45, 0)
                nameLbl.Position = UDim2.new(0, 0, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.TextScaled = true
                nameLbl.Font = CONFIG_GETUP.Font
                nameLbl.TextColor3 = CONFIG_GETUP.NameColor
                nameLbl.TextStrokeTransparency = 1 
                nameLbl.Text = p.Name
                applyStroke(nameLbl) 
                
                local timeLbl = Instance.new("TextLabel", container)
                timeLbl.Size = UDim2.new(1, 0, 0.55, 0)
                timeLbl.Position = UDim2.new(0, 0, 0.45, 0) 
                timeLbl.BackgroundTransparency = 1
                timeLbl.TextScaled = true
                timeLbl.Font = CONFIG_GETUP.Font
                timeLbl.TextStrokeTransparency = 1
                applyStroke(timeLbl)
                
                return timeLbl
            end

            local function start(p, char, hum, hrp)
                if p == LocalPlayer then return end 
                
                if activeConnections[p] then
                    activeConnections[p]:Disconnect()
                    activeConnections[p] = nil
                end
                local oldFrame = getupList:FindFirstChild(p.Name)
                if oldFrame then oldFrame:Destroy() end
                
                activeGetUp[p] = os.clock()
                local lastHealth = hum.Health
                
                local head = char:FindFirstChild("Head")
                local headTimer = billboard(p, head)
                
                local playerFrame = Instance.new("Frame", getupList)
                playerFrame.Name = p.Name 
                playerFrame.Size = UDim2.new(1, 0, 0, 45) 
                playerFrame.BackgroundTransparency = 1
                
                local listName = Instance.new("TextLabel", playerFrame)
                listName.Size = UDim2.new(1, 0, 0.45, 0)
                listName.BackgroundTransparency = 1
                listName.Font = CONFIG_GETUP.Font
                listName.TextSize = 20
                listName.TextXAlignment = Enum.TextXAlignment.Right 
                listName.TextColor3 = CONFIG_GETUP.NameColor
                listName.TextStrokeTransparency = 1
                listName.Text = p.Name
                applyStroke(listName)
                
                local listTimer = Instance.new("TextLabel", playerFrame)
                listTimer.Size = UDim2.new(1, 0, 0.55, 0)
                listTimer.Position = UDim2.new(0, 0, 0.45, 0)
                listTimer.BackgroundTransparency = 1
                listTimer.Font = CONFIG_GETUP.Font
                listTimer.TextSize = 24
                listTimer.TextXAlignment = Enum.TextXAlignment.Right 
                listTimer.TextStrokeTransparency = 1
                applyStroke(listTimer)
                
                local lastUpdate = 0
                local con
                
                con = RunService.Heartbeat:Connect(function()
                    if not p.Parent or not char.Parent or not hum.Parent or not hrp.Parent then
                        cleanupPlayer(p, con, playerFrame, char)
                        return
                    end
                    
                    local isRagdoll = hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics
                    local isCaptured = hrp.Anchored
                    local isDead = hum.Health <= 0
                    
                    local currentHealth = hum.Health
                    if currentHealth < lastHealth then
                        activeGetUp[p] = os.clock()
                    end
                    lastHealth = currentHealth
                    
                    local now = os.clock()
                    local elapsed = now - (activeGetUp[p] or now)
                    local forceExpired = elapsed >= (CONFIG_GETUP.Duration + 1.0)
                    
                    if not getupActive or not isRagdoll or isCaptured or isDead or forceExpired then
                        cleanupPlayer(p, con, playerFrame, char)
                        return
                    end
                    
                    if now - lastUpdate >= UI_UPDATE_INTERVAL then
                        lastUpdate = now
                        
                        local r = math.max(CONFIG_GETUP.Duration - elapsed, 0)
                        local c = colorGetUp(r / CONFIG_GETUP.Duration)
                        local timeString = string.format("%.2f", r)
                        
                        if headTimer and headTimer.Parent then
                            headTimer.Text = timeString
                            headTimer.TextColor3 = c
                        end
                        listTimer.Text = timeString
                        listTimer.TextColor3 = c
                        
                        if r <= 0 then
                            listTimer.Text = "0.00"
                            if headTimer and headTimer.Parent then 
                                headTimer.Text = "0.00" 
                            end
                        end
                    end
                end)
                
                activeConnections[p] = con
            end

            local hb = task.spawn(function()
                while getupActive and task.wait(0.15) do 
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and not activeGetUp[p] then
                            local char = p.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            
                            if hum then
                                local isRagdoll = hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics
                                if isRagdoll then
                                    local hrp = char:FindFirstChild("HumanoidRootPart")
                                    local isCaptured = hrp and hrp.Anchored
                                    
                                    if not isCaptured then
                                        task.spawn(start, p, char, hum, hrp)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            table.insert(getupConns, hb)

            local pr = Players.PlayerRemoving:Connect(function(p)
                activeGetUp[p] = nil
                if activeConnections[p] then
                    activeConnections[p]:Disconnect()
                    activeConnections[p] = nil
                end
                local oldFrame = getupList:FindFirstChild(p.Name)
                if oldFrame then oldFrame:Destroy() end
            end)
            table.insert(getupConns, pr)
        else
            getupActive = false
            for _, c in ipairs(getupConns) do
                if typeof(c) == "thread" then 
                    task.cancel(c) 
                else 
                    c:Disconnect() 
                end
            end
            table.clear(getupConns)
            
            for p, con in pairs(activeConnections) do
                if con then con:Disconnect() end
            end
            activeConnections = {}
            activeGetUp = {}
            
            if getupGui then 
                getupGui:Destroy() 
                getupGui = nil 
            end
            
            for _, p in ipairs(Players:GetPlayers()) do
                local char = p.Character
                local head = char and char:FindFirstChild("Head")
                local bb = head and head:FindFirstChild("RC")
                if bb then bb:Destroy() end
            end
        end
    end)
    
    -- 2. Beast Power Timer
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
                    local plist = Players:GetPlayers()
                    for i = 1, #plist do
                        local char = plist[i].Character
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

                    if foundValue then
                        if not BeastPowerConnection2 or not BeastPowerConnection2.Connected then
                            updateUI(foundValue.Value)
                            BeastPowerConnection2 = foundValue:GetPropertyChangedSignal("Value"):Connect(function()
                                updateUI(foundValue.Value)
                            end)
                        end
                    else
                        if BeastPowerConnection2 then
                            BeastPowerConnection2:Disconnect()
                            BeastPowerConnection2 = nil
                        end
                        updateUI(nil)
                    end
                    task.wait(1)
                end
            end)
        else
            if BeastPowerConnection1 then task.cancel(BeastPowerConnection1); BeastPowerConnection1 = nil end
            if BeastPowerConnection2 then BeastPowerConnection2:Disconnect(); BeastPowerConnection2 = nil end
            if uiFrameBP and uiFrameBP.Parent then uiFrameBP.Parent:Destroy() end
        end
    end)
    
    -- 3. Beast Power Timer V2
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
                            end
                        end
                    end
                end
            end)
        else
            if BeastPowerLoop2 then task.cancel(BeastPowerLoop2); BeastPowerLoop2 = nil end
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local bb = player.Character.HumanoidRootPart:FindFirstChild("BeastPowerBillboard")
                    if bb then bb:Destroy() end
                end
            end
        end
    end)
    
    -- 4. Beast Spawn Timer
    Library:CreateToggle(Page, "Beast Spawn Timer", false, function(state)
        if state then
            BeastSpawnActive = true
            
            if CoreGui:FindFirstChild("ElegantBeastTimer") then
                CoreGui.ElegantBeastTimer:Destroy()
            end

            local sg = Instance.new("ScreenGui")
            sg.Name = "ElegantBeastTimer"
            sg.DisplayOrder = 999
            sg.Parent = CoreGui

            local label = Instance.new("TextLabel")
            label.Name = "TimerLabel"
            label.Size = UDim2.new(0, 400, 0, 50)
            label.Position = UDim2.new(0.5, 0, 0.8, 0)
            label.AnchorPoint = Vector2.new(0.5, 0.5)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBlack
            label.TextSize = 26
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextTransparency = 1
            label.Text = ""
            label.Parent = sg

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 2
            stroke.Transparency = 1
            stroke.Parent = label

            local infoSeno = TweenInfo.new(0.8, Enum.EasingStyle.Sine)
            local infoLinear = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

            local function FadeIn()
                TweenService:Create(label, infoSeno, {TextTransparency = 0}):Play()
                TweenService:Create(stroke, infoSeno, {Transparency = 0.3}):Play()
            end

            local function FadeOut()
                TweenService:Create(label, infoSeno, {TextTransparency = 1}):Play()
                TweenService:Create(stroke, infoSeno, {Transparency = 1}):Play()
            end

            local function TweenColor(color)
                TweenService:Create(label, infoLinear, {TextColor3 = color}):Play()
            end

            local function TemMapaCarregado()
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Model") or obj:IsA("Folder") then
                        if obj:FindFirstChild("ComputerTable") or obj:FindFirstChild("FreezePod") then
                            return true
                        end
                    end
                end
                return false
            end

            local isMapLoaded = false 

            local function IniciarContagem()
                local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                if not stats then return end
                
                local isBeast = stats:FindFirstChild("IsBeast")
                if isBeast and isBeast.Value then return end

                local vida = stats:FindFirstChild("Health")
                if not vida or vida.Value <= 0 then return end

                FadeIn()
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                
                local tempoInicio = os.clock()
                local isRed = false
                local conexao

                conexao = RunService.RenderStepped:Connect(function()
                    local vivo = vida and vida.Value > 0
                    
                    if not vivo or not isMapLoaded or not BeastSpawnActive then
                        conexao:Disconnect()
                        FadeOut()
                        return
                    end

                    if IsGameActive and IsGameActive.Value == true then
                        conexao:Disconnect()
                        label.Text = "The Beast has been released!"
                        TweenColor(Color3.fromRGB(255, 255, 255))
                        task.delay(3, FadeOut)
                        return
                    end

                    local tempoRestante = 15 - (os.clock() - tempoInicio)

                    if tempoRestante <= 0 then
                        label.Text = "Beast Spawns In: 0.0"
                    else
                        label.Text = string.format("Beast Spawns In: %.1f", tempoRestante)
                        
                        if tempoRestante <= 5 and not isRed then
                            isRed = true
                            TweenColor(Color3.fromRGB(255, 85, 85))
                        end
                    end
                end)
                BeastSpawnRenderConn = conexao
            end

            BeastSpawnLoopThread = task.spawn(function()
                local estadoAnterior = "LOBBY"
                
                while BeastSpawnActive do
                    isMapLoaded = TemMapaCarregado() 
                    
                    local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                    local hp = stats and stats:FindFirstChild("Health")
                    
                    local naPartida = (hp and hp.Value > 0) and isMapLoaded
                    local jogoAtivo = IsGameActive and IsGameActive.Value or false

                    if not naPartida then
                        estadoAnterior = "LOBBY"
                    elseif naPartida and not jogoAtivo then
                        if estadoAnterior ~= "CAGE" then
                            estadoAnterior = "CAGE"
                            IniciarContagem()
                        end
                    elseif naPartida and jogoAtivo then
                        estadoAnterior = "PLAYING"
                    end
                    
                    task.wait(0.2)
                end
            end)
        else
            BeastSpawnActive = false
            if BeastSpawnRenderConn then BeastSpawnRenderConn:Disconnect(); BeastSpawnRenderConn = nil end
            if BeastSpawnLoopThread then task.cancel(BeastSpawnLoopThread); BeastSpawnLoopThread = nil end
            if CoreGui:FindFirstChild("ElegantBeastTimer") then
                CoreGui.ElegantBeastTimer:Destroy()
            end
        end
    end)

    -- =========================================================================
    -- SECTION: HIGHLIGHT SETTINGS (Coluna Esquerda - Abaixo de Action Timers)
    -- =========================================================================
    Library:CreateSection(Page, "HighLight Settings")
    
    -- 1. Computer Highlight
    Library:CreateToggle(Page, "Computer Highlight", false, function(state)
        compHighlightEnabled = state
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "ComputerHighlight" and obj:IsA("Highlight") then
                obj.Enabled = state
            end
        end
    end)

    -- 2. Door Highlight
    Library:CreateToggle(Page, "Door Highlight", false, function(state)
        doorHighlightEnabled = state
        for _, data in pairs(trackedNormalDoors) do
            if data.Highlight then
                data.Highlight.Enabled = state
            end
        end
    end)

    -- 3. ExitDoor Highlight
    Library:CreateToggle(Page, "ExitDoor Highlight", false, function(state)
        exitHighlightEnabled = state
        for _, data in pairs(trackedExitDoors) do
            if data.Highlight then
                data.Highlight.Enabled = state
            end
        end
    end)

    -- =========================================================================
    -- SECTION: PROGRESS SETTINGS (Coluna Direita - Abaixo de Beast Indicators)
    -- =========================================================================
    Library:CreateSection(Page, "Progress Settings")
    
    -- 1. PC Progress Design (Dropdown)
    Library:CreateDropdown(Page, "PC Progress Design", {"Default", "Style 1", "Style 2"}, "Default", function(val)
        currentComputerStyle = val
        -- Limpa computadores para redesenhar com o estilo selecionado
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "ProgressBar" and obj:IsA("BillboardGui") then obj:Destroy() end
            if obj.Name == "ComputerHighlight" and obj:IsA("Highlight") then obj:Destroy() end
        end
        table.clear(CompProgConns)
    end)

    -- 2. Door Progress Design (Dropdown)
    Library:CreateDropdown(Page, "Door Progress Design", {"Default", "Style 1", "Style 2"}, "Default", function(val)
        currentDoorStyle = val
        lastMap = nil -- Reseta o rastreador de mapa para forçar varredura instantânea
        
        -- Limpa portas para redesenhar com o estilo selecionado
        if doorAddedConn then doorAddedConn:Disconnect(); doorAddedConn = nil end
        for doorModel, data in pairs(trackedNormalDoors) do
            if data.Billboard then data.Billboard:Destroy() end
            if data.Highlight then data.Highlight:Destroy() end
        end
        table.clear(trackedNormalDoors)
    end)

    -- 3. Door Progress Distance (Slider)
    Library:CreateSlider(Page, "Door progress distance", 30, 300, 150, function(val)
        doorMaxDistance = val
        -- Atualiza dinamicamente as portas ativas no mapa
        for _, data in pairs(trackedNormalDoors) do
            if data.Billboard then
                data.Billboard.MaxDistance = val
            end
        end
    end)
end
