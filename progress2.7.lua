return function(env)
    local Library = env.Library
    local Page = env.Page
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local Workspace = env.Workspace
    local CoreGui = env.CoreGui
    local ReplicatedStorage = env.ReplicatedStorage
    local RunService = game:GetService("RunService")
    local TweenService = env.TweenService
    local Theme = env.Theme
    local SendNotification = env.SendNotification

    -- =========================================================================
    -- VARIÁVEIS DE CONTROLE GLOBAL (Módulo)
    -- =========================================================================
    
    -- Instância global de OverlapParams para evitar alocação de memória contínua
    local globalOverlapParams = OverlapParams.new()
    globalOverlapParams.FilterType = Enum.RaycastFilterType.Include

    -- Vars Beast Power
    local BeastPowerConnection1 = nil
    local BeastPowerConnection2 = nil
    local uiFrameBP, uiLabelBP = nil, nil
    local trackedPowerValue = nil
    local lastPercent = 0
    local isDraining = false
    local BeastPowerLoop2 = nil

    -- Vars Computer Progress & Highlight Outlines
    local CompProgLoop = nil
    local CompProgConns = {}
    local compHighlightEnabled = false
    local compOutlineEnabled = false
    local currentComputerStyle = "Default"

    -- Vars Door Progress & Highlight Outlines
    local DoorProgLoop = nil
    local DoorProgHeartbeat = nil
    local doorAddedConn = nil
    local trackedNormalDoors = {}
    local doorHighlightEnabled = false
    local doorOutlineEnabled = false
    local currentDoorStyle = "Default"
    local doorMaxDistance = 150
    local lastMap = nil

    -- Vars ExitDoor Progress & Highlight Outlines
    local ExitDoorConn = nil
    local ExitDoorAdded = nil
    local ExitDoorRemoving = nil
    local trackedExitDoors = {}
    local actionValCache = {}
    local exitHighlightEnabled = false
    local exitOutlineEnabled = false

    -- Vars WalkSpeed Detector (Unified Speed Tracker)
    local speedActive = false
    local lateralSpeedActive = false
    local speedRenderConn = nil
    local speedLabels2D = {}
    local speedScreenGui = nil
    local speedListFrame = nil

    -- Vars Wallhop Counter
    local WallhopStateConn = nil
    local WallhopCharConn = nil
    local WallhopTimerConn = nil

    -- Vars GetUp Timer & Hide Setting
    local getupActive = false
    local hideHeadGetUp = false
    local getupConns = {} 
    local activeConnections = {} 
    local getupGui = nil
    local getupList = nil
    local activeGetUp = {}

    -- Vars Beast Spawn Timer
    local BeastSpawnActive = false
    local BeastSpawnLoopThread = nil
    local BeastSpawnRenderConn = nil

    -- Vars Life Timer (New Electric Blue Version)
    local lifeActive = false
    local lifeConns = {}
    local lifePlayerConns = {}
    local lifeCachedStats = {}
    local lifeTimerOrigin = "Head"
    
    -- IsGameActive carregado de forma assíncrona para não travar a UI
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
                highlight.Enabled = compHighlightEnabled or compOutlineEnabled
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

                local updateInterval = 0.12 
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
                        if screen.Color.G > screen.Color.R and screen.Color.G > screen.Color.B then
                            isGreen = true
                        end
                    end

                    highlight.Enabled = compHighlightEnabled or compOutlineEnabled

                    if compOutlineEnabled then
                        highlight.FillTransparency = 1
                        highlight.OutlineTransparency = 0
                        if isGreen then
                            highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                        else
                            if screen then
                                local color = screen.Color
                                if color.R > color.G and color.R > color.B then
                                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                                else
                                    highlight.OutlineColor = Color3.fromRGB(0, 180, 255)
                                end
                            end
                        end
                    else
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                        if screen then
                            highlight.FillColor = screen.Color
                        end
                    end

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
                            globalOverlapParams.FilterDescendantsInstances = characterParts
                            for i = 1, #triggers do
                                local part = triggers[i]
                                if part and part.Parent then
                                    local touchingParts = Workspace:GetPartsInPart(part, globalOverlapParams)
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
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "NormalDoorGUI"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 90, 0, 22) 
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
                    bgBar.Position = UDim2.new(0, 0, 0.6, 0) 
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
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                hl.OutlineTransparency = 0 
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Enabled = doorHighlightEnabled or doorOutlineEnabled
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
                            for _, obj in ipairs(map:GetChildren()) do
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
                        data.Highlight.Enabled = doorHighlightEnabled or doorOutlineEnabled
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

                    if doorOutlineEnabled then
                        data.Highlight.FillTransparency = 1
                        data.Highlight.OutlineTransparency = 0
                        if isPhysicallyOpen then
                            data.Highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
                        elseif interactionVal > 0.001 then
                            data.Highlight.OutlineColor = Color3.fromRGB(255, 200, 0)
                        else
                            data.Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                        end
                    else
                        data.Highlight.FillTransparency = 0.55
                        data.Highlight.OutlineTransparency = 0
                        data.Highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                        if isPhysicallyOpen then
                            data.Highlight.FillColor = Color3.fromRGB(0, 255, 100)
                        elseif interactionVal > 0.001 then
                            data.Highlight.FillColor = Color3.fromRGB(255, 200, 0)
                        else
                            data.Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        end
                    end

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
                            end
                        elseif interactionVal > 0.001 then 
                            if data.LastState ~= "Opening" or math.abs(data.LastProgress - interactionVal) > 0.005 then
                                data.LastState = "Opening"
                                data.LastProgress = interactionVal
                                data.Bar.Size = UDim2.new(math.clamp(interactionVal, 0, 1), 0, 1, 0)
                                data.Bar.BackgroundColor3 = barColor
                                data.Text.TextColor3 = baseColor
                                data.Text.Text = string.format("%.1f%%", interactionVal * 100)
                            end
                        else
                            if data.LastState ~= "Closed" then
                                data.LastState = "Closed"
                                data.Bar.Size = UDim2.new(0, 0, 1, 0)
                                data.Bar.BackgroundColor3 = barColor
                                data.Text.TextColor3 = baseColor
                                data.Text.Text = "0.0%"
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
                                data.BgBar.Visible = false
                            end
                        elseif interactionVal > 0.05 then 
                            data.LastState = "Opening"
                            data.Text.Text = "OPENING"
                            data.Text.TextColor3 = COLORS_STYLE2.OPENING
                            data.BgBar.Visible = true
                            data.Bar.Size = UDim2.new(math.clamp(interactionVal, 0, 1), 0, 1, 0)
                        else
                            if data.LastState ~= "Closed" then
                                data.LastState = "Closed"
                                data.Text.Text = "CLOSE"
                                data.Text.TextColor3 = COLORS_STYLE2.CLOSE
                                data.BgBar.Visible = false
                            end
                        end
                    end
                end
            end)
        else
            if DoorProgLoop then task.cancel(DoorProgLoop); DoorProgLoop = nil end
            if DoorProgHeartbeat then DoorProgHeartbeat:Disconnect(); DoorProgHeartbeat = nil end
            if doorAddedConn then doorAddedConn:Disconnect(); doorAddedConn = nil end
            lastMap = nil 
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
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Enabled = exitHighlightEnabled or exitOutlineEnabled
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
                while state and task.wait(0.15) do 
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
                        
                        if data.Highlight then
                            data.Highlight.Enabled = exitHighlightEnabled or exitOutlineEnabled
                            
                            if exitOutlineEnabled then
                                data.Highlight.FillTransparency = 1
                                data.Highlight.OutlineTransparency = 0
                                if data.Completed then
                                    data.Highlight.OutlineColor = Color3.fromRGB(40, 255, 80)
                                else
                                    data.Highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                                end
                            else
                                data.Highlight.FillTransparency = 0.55
                                data.Highlight.OutlineTransparency = 0
                                if data.Completed then
                                    data.Highlight.FillColor = Color3.fromRGB(40, 255, 80)
                                else
                                    data.Highlight.FillColor = Color3.fromRGB(255, 255, 0)
                                end
                            end
                        end
                        
                        if data.Completed then
                            data.FillElement.Size = UDim2.new(1, 0, 1, 0)
                            data.FillElement.BackgroundColor3 = Color3.fromRGB(40, 255, 80)
                            data.TextElement.Text = "DOOR OPENED!"
                            data.TextElement.TextColor3 = Color3.fromRGB(40, 255, 80)
                        else
                            data.FillElement.Size = UDim2.new(data.Progress, 0, 1, 0)
                            data.FillElement.BackgroundColor3 = Color3.fromRGB(255, 160, 20)
                            
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
    
    -- 4. WalkSpeed Detector (Unified Speed Tracker)
    Library:CreateToggle(Page, "WalkSpeed Detector", false, function(state)
        speedActive = state
        if state then
            if not speedRenderConn then
                local speedUpdateAccum = 0 
                
                speedRenderConn = RunService.RenderStepped:Connect(function(dt)
                    if not speedActive then return end
                    
                    speedUpdateAccum = speedUpdateAccum + dt
                    if speedUpdateAccum < 0.08 then return end 
                    speedUpdateAccum = 0

                    local roundActive = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p:FindFirstChild("TempPlayerStatsModule", true) then
                            roundActive = true
                            break
                        end
                    end

                    if lateralSpeedActive then
                        if not speedScreenGui then
                            local targetGuiParent = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
                            speedScreenGui = Instance.new("ScreenGui")
                            speedScreenGui.Name = "SpeedListGui"
                            speedScreenGui.ResetOnSpawn = false
                            speedScreenGui.Parent = targetGuiParent

                            speedListFrame = Instance.new("Frame")
                            speedListFrame.Name = "ListFrame"
                            speedListFrame.BackgroundTransparency = 1
                            speedListFrame.Position = UDim2.new(0, 25, 0.65, 0)
                            speedListFrame.Size = UDim2.new(0, 280, 0.3, 0)
                            speedListFrame.Parent = speedScreenGui

                            local uiListLayout = Instance.new("UIListLayout")
                            uiListLayout.SortOrder = Enum.SortOrder.Name
                            uiListLayout.Padding = UDim.new(0, 5)
                            uiListLayout.Parent = speedListFrame
                        end
                        speedScreenGui.Enabled = true
                    else
                        if speedScreenGui then
                            speedScreenGui.Enabled = false
                        end
                    end

                    for _, player in ipairs(Players:GetPlayers()) do
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        local head = char and char:FindFirstChild("Head")

                        local showThisPlayer = true
                        if roundActive then
                            local hasStats = player:FindFirstChild("TempPlayerStatsModule", true)
                            if not hasStats then
                                showThisPlayer = false
                            end
                        end

                        if showThisPlayer and root and humanoid and humanoid.Health > 0 then
                            local speedStr = "0.0"
                            if humanoid.MoveDirection.Magnitude > 0 then
                                local vel = root.AssemblyLinearVelocity
                                speedStr = string.format("%.1f", math.sqrt(vel.X * vel.X + vel.Z * vel.Z))
                            end

                            if lateralSpeedActive then
                                if char:FindFirstChild("SpeedTag") then
                                    char.SpeedTag.Enabled = false
                                end

                                local label = speedLabels2D[player]
                                if not label or not label.Parent then
                                    label = Instance.new("TextLabel")
                                    label.Name = player.Name
                                    label.Size = UDim2.new(1, 0, 0, 24)
                                    label.BackgroundTransparency = 1
                                    label.Font = Enum.Font.GothamBold
                                    label.TextSize = 16
                                    label.TextXAlignment = Enum.TextXAlignment.Left
                                    label.TextStrokeTransparency = 0.65
                                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    label.Parent = speedListFrame
                                    speedLabels2D[player] = label
                                end
                                label.Visible = true
                                label.Text = player.Name .. ": " .. speedStr
                            else
                                if speedLabels2D[player] then
                                    speedLabels2D[player].Visible = false
                                end

                                local tag = char:FindFirstChild("SpeedTag")
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
                                    
                                    tag.Parent = char
                                else
                                    label = tag:FindFirstChild("SpeedText")
                                end
                                if tag then tag.Enabled = true end
                                if label then label.Text = speedStr end
                            end
                        else
                            if speedLabels2D[player] then
                                speedLabels2D[player].Visible = false
                            end
                            if char and char:FindFirstChild("SpeedTag") then
                                char.SpeedTag.Enabled = false
                            end
                        end
                    end
                end)
            end
        else
            if speedRenderConn then speedRenderConn:Disconnect(); speedRenderConn = nil end
            if speedScreenGui then speedScreenGui:Destroy(); speedScreenGui = nil end
            table.clear(speedLabels2D)
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char and char:FindFirstChild("SpeedTag") then
                    char.SpeedTag:Destroy()
                end
            end
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
                
                if hideHeadGetUp then return nil end 

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
                local headTimer = nil
                if not hideHeadGetUp and head then
                    headTimer = billboard(p, head)
                end
                
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
                    
                    if not hideHeadGetUp then
                        if head and (not headTimer or not headTimer.Parent) then
                            headTimer = billboard(p, head)
                        end
                    else
                        if headTimer then
                            local old = head:FindFirstChild("RC")
                            if old then old:Destroy() end
                            headTimer = nil
                        end
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
            uiLabelBP.Text = "Loading..."
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
                    
                    if percentInt >= 100 then
                        uiLabelBP.Text = "BeastPower is Full"
                    else
                        uiLabelBP.Text = "BeastPower Back In: " .. percentInt .. "%"
                    end
                    
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

    -- 5. Life Timer (New logic integration)
    Library:CreateToggle(Page, "Life Timer", false, function(state)
        lifeActive = state
        
        if state then
            local TIMER_COLOR = Color3.fromRGB(0, 170, 255)

            local function isLifeBeast(player)
                local stats = lifeCachedStats[player]
                return stats and stats.isBeast and stats.isBeast.Value
            end

            local function isCharacterWeldedToPod(character)
                if not character then return false end
                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then return false end

                local rootChildren = root:GetChildren()
                for i = 1, #rootChildren do
                    local child = rootChildren[i]
                    if child:IsA("Weld") or child:IsA("Motor6D") then
                        local part = child.Part1 or child.Part0
                        if part then
                            local nameLower = part.Name:lower()
                            local parentNameLower = part.Parent and part.Parent.Name:lower() or ""
                            if nameLower == "seat" or nameLower:find("pod") or parentNameLower:find("pod") or parentNameLower:find("capsule") then
                                return true
                            end
                        end
                    end
                end
                return false
            end

            local function isPlayerCaptured(player)
                local stats = lifeCachedStats[player]
                if not stats or not stats.module then 
                    return isCharacterWeldedToPod(player.Character) 
                end

                local isCapVal = stats.module:FindFirstChild("IsCaptured") or stats.module:FindFirstChild("Captured")
                if isCapVal then
                    return isCapVal.Value == true
                end

                return isCharacterWeldedToPod(player.Character)
            end

            local function getLifeTimerTarget(char)
                if not char then return nil, Vector3.new(0, 0, 0) end
                if lifeTimerOrigin == "Head" then
                    local head = char:FindFirstChild("Head")
                    return head, Vector3.new(0, 0, 0) -- Centralizado na cabeça
                elseif lifeTimerOrigin == "Torso" then
                    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                    return torso, Vector3.new(0, 0, 0)
                else -- "Inferior"
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    return hrp, Vector3.new(0, -3.2, 0)
                end
            end

            local function cleanupPlayer(player)
                if lifePlayerConns[player] then
                    for _, connection in ipairs(lifePlayerConns[player]) do
                        if connection then connection:Disconnect() end
                    end
                    lifePlayerConns[player] = nil
                end

                local char = player.Character
                if char then
                    local existingTag = char:FindFirstChild("CapsuleLifeTag", true)
                    if existingTag then existingTag:Destroy() end
                end

                lifeCachedStats[player] = nil
            end

            local function updatePlayerTag(player)
                if not lifeActive then return end

                local char = player.Character
                if not char then return end

                local targetPart, offset = getLifeTimerTarget(char)
                if not targetPart then return end

                if isLifeBeast(player) then
                    local tag = char:FindFirstChild("CapsuleLifeTag", true)
                    if tag then tag:Destroy() end
                    return
                end

                local stats = lifeCachedStats[player]
                local health = stats and stats.health

                if health and health.Value > 0 and isPlayerCaptured(player) then
                    local tag = char:FindFirstChild("CapsuleLifeTag", true)
                    
                    if not tag then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "CapsuleLifeTag"
                        billboard.Size = UDim2.new(0, 90, 0, 30)
                        billboard.AlwaysOnTop = true

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 20
                        label.TextStrokeTransparency = 0.5
                        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        label.Parent = billboard

                        billboard.Parent = targetPart
                        tag = billboard
                    else
                        tag.Parent = targetPart
                    end

                    tag.StudsOffset = offset

                    local label = tag:FindFirstChildOfClass("TextLabel")
                    if label then
                        local secondsLeft = health.Value * 0.5
                        label.Text = string.format("%.1f", secondsLeft) .. "s"
                        label.TextColor3 = TIMER_COLOR 
                    end
                else
                    local tag = char:FindFirstChild("CapsuleLifeTag", true)
                    if tag then tag:Destroy() end
                end
            end

            local function monitorPlayer(player)
                cleanupPlayer(player)
                lifePlayerConns[player] = {}

                local function onStatsLoaded(statsInstance)
                    local health = statsInstance:WaitForChild("Health", 5)
                    local isBeastVal = statsInstance:WaitForChild("IsBeast", 5)
                    local isCapVal = statsInstance:FindFirstChild("IsCaptured") or statsInstance:FindFirstChild("Captured")

                    if health and isBeastVal then
                        lifeCachedStats[player] = {
                            health = health,
                            isBeast = isBeastVal,
                            module = statsInstance
                        }

                        local hConn = health:GetPropertyChangedSignal("Value"):Connect(function()
                            updatePlayerTag(player)
                        end)
                        table.insert(lifePlayerConns[player], hConn)

                        local bConn = isBeastVal:GetPropertyChangedSignal("Value"):Connect(function()
                            updatePlayerTag(player)
                        end)
                        table.insert(lifePlayerConns[player], bConn)
                    end

                    if isCapVal then
                        local cConn = isCapVal:GetPropertyChangedSignal("Value"):Connect(function()
                            updatePlayerTag(player)
                        end)
                        table.insert(lifePlayerConns[player], cConn)
                    end

                    updatePlayerTag(player)
                end

                local stats = player:FindFirstChild("TempPlayerStatsModule", true)
                if stats then
                    onStatsLoaded(stats)
                end

                local childConn = player.ChildAdded:Connect(function(child)
                    if child.Name == "TempPlayerStatsModule" or child:FindFirstChild("TempPlayerStatsModule", true) then
                        local freshStats = player:FindFirstChild("TempPlayerStatsModule", true)
                        if freshStats then
                            onStatsLoaded(freshStats)
                        end
                    end
                end)
                table.insert(lifePlayerConns[player], childConn)

                local charConn = player.CharacterAdded:Connect(function()
                    task.wait(0.3)
                    updatePlayerTag(player)
                end)
                table.insert(lifePlayerConns[player], charConn)
            end

            for _, player in ipairs(Players:GetPlayers()) do
                monitorPlayer(player)
            end

            local playerAddedConn = Players.PlayerAdded:Connect(function(player)
                monitorPlayer(player)
            end)
            table.insert(lifeConns, playerAddedConn)

            local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
                cleanupPlayer(player)
            end)
            table.insert(lifeConns, playerRemovingConn)

            local loopThread = task.spawn(function()
                while lifeActive do
                    for _, player in ipairs(Players:GetPlayers()) do
                        updatePlayerTag(player)
                    end
                    task.wait(2)
                end
            end)
            table.insert(lifeConns, loopThread)
        else
            for _, conn in ipairs(lifeConns) do
                if typeof(conn) == "thread" then
                    task.cancel(conn)
                else
                    conn:Disconnect()
                end
            end
            table.clear(lifeConns)

            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    local tag = char:FindFirstChild("CapsuleLifeTag", true)
                    if tag then tag:Destroy() end
                end
                lifePlayerConns[player] = nil
                lifeCachedStats[player] = nil
            end
            table.clear(lifePlayerConns)
            table.clear(lifeCachedStats)
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
                obj.Enabled = state or compOutlineEnabled
            end
        end
    end)

    -- 2. Computer Outline
    Library:CreateToggle(Page, "Computer Outline", false, function(state)
        compOutlineEnabled = state
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "ComputerHighlight" and obj:IsA("Highlight") then
                obj.Enabled = compHighlightEnabled or state
            end
        end
    end)

    -- 3. Door Highlight
    Library:CreateToggle(Page, "Door Highlight", false, function(state)
        doorHighlightEnabled = state
        for _, data in pairs(trackedNormalDoors) do
            if data.Highlight then
                data.Highlight.Enabled = state or doorOutlineEnabled
            end
        end
    end)

    -- 4. Door Outline
    Library:CreateToggle(Page, "Door Outline", false, function(state)
        doorOutlineEnabled = state
        for _, data in pairs(trackedNormalDoors) do
            if data.Highlight then
                data.Highlight.Enabled = doorHighlightEnabled or state
            end
        end
    end)

    -- 5. ExitDoor Highlight
    Library:CreateToggle(Page, "ExitDoor Highlight", false, function(state)
        exitHighlightEnabled = state
        for _, data in pairs(trackedExitDoors) do
            if data.Highlight then
                data.Highlight.Enabled = state or exitOutlineEnabled
            end
        end
    end)

    -- 6. ExitDoor Outline
    Library:CreateToggle(Page, "ExitDoor Outline", false, function(state)
        exitOutlineEnabled = state
        for _, data in pairs(trackedExitDoors) do
            if data.Highlight then
                data.Highlight.Enabled = exitHighlightEnabled or state
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
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "ProgressBar" and obj:IsA("BillboardGui") then obj:Destroy() end
            if obj.Name == "ComputerHighlight" and obj:IsA("Highlight") then obj:Destroy() end
        end
        table.clear(CompProgConns)
    end)

    -- 2. Door Progress Design (Dropdown)
    Library:CreateDropdown(Page, "Door Progress Design", {"Default", "Style 1", "Style 2"}, "Default", function(val)
        currentDoorStyle = val
        lastMap = nil 
        
        if doorAddedConn then doorAddedConn:Disconnect(); doorAddedConn = nil end
        for doorModel, data in pairs(trackedNormalDoors) do
            if data.Billboard then data.Billboard:Destroy() end
            if data.Highlight then data.Highlight:Destroy() end
        end
        table.clear(trackedNormalDoors)
    end)

    -- 3. Hide Head GetUp
    Library:CreateToggle(Page, "Hide Head GetUp", false, function(state)
        hideHeadGetUp = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do
                local char = p.Character
                local head = char and char:FindFirstChild("Head")
                local bb = head and head:FindFirstChild("RC")
                if bb then bb:Destroy() end
            end
        end
    end)

    -- 4. WalkSpeed Lateral
    Library:CreateToggle(Page, "WalkSpeed Lateral", false, function(state)
        lateralSpeedActive = state
        
        if not state then
            if speedScreenGui then speedScreenGui:Destroy(); speedScreenGui = nil end
            table.clear(speedLabels2D)
        end
    end)

    -- 5. Life Timer Origin (Novo Dropdown)
    Library:CreateDropdown(Page, "Life Timer Origin", {"Head", "Torso", "Inferior"}, "Head", function(val)
        lifeTimerOrigin = val
        -- Atualiza dinamicamente as posições dos marcadores ativos se a toggle estiver ligada
        if lifeActive then
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    local tag = char:FindFirstChild("CapsuleLifeTag", true)
                    if tag then
                        local targetPart, offset = nil, Vector3.new(0, 0, 0)
                        if lifeTimerOrigin == "Head" then
                            targetPart = char:FindFirstChild("Head")
                            offset = Vector3.new(0, 0, 0)
                        elseif lifeTimerOrigin == "Torso" then
                            targetPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                            offset = Vector3.new(0, 0, 0)
                        else
                            targetPart = char:FindFirstChild("HumanoidRootPart")
                            offset = Vector3.new(0, -3.2, 0)
                        end
                        if targetPart then
                            tag.Parent = targetPart
                            tag.StudsOffset = offset
                        end
                    end
                end
            end
        end
    end)

    -- 6. Door Progress Distance (slider posicionado como último elemento)
    Library:CreateSlider(Page, "Door progress distance", 30, 300, 150, function(val)
        doorMaxDistance = val
        for _, data in pairs(trackedNormalDoors) do
            if data.Billboard then
                data.Billboard.MaxDistance = val
            end
        end
    end)
end
