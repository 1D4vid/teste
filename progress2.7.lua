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
    -- ESCOPO DE SEGURANÇA E CACHE DE ALTA PERFORMANCE (Evita gargalos de CPU)
    -- =========================================================================
    local cachedPlayersList = Players:GetPlayers()
    local cachedCharacters = {}
    local globalConnections = {}

    local globalOverlapParams = OverlapParams.new()
    globalOverlapParams.FilterType = Enum.RaycastFilterType.Include

    -- Rastreamento direto na memória para evitar buscas pesadas no Workspace
    local activeCompHighlights = {}

    -- Atualização inteligente do cache de personagens (Evita recriação de tabelas em loops rápidos)
    local function updateCharacterCache()
        table.clear(cachedCharacters)
        for i = 1, #cachedPlayersList do
            local char = cachedPlayersList[i].Character
            if char then
                table.insert(cachedCharacters, char)
            end
        end
        globalOverlapParams.FilterDescendantsInstances = cachedCharacters
    end

    table.insert(globalConnections, Players.PlayerAdded:Connect(function(plr) 
        cachedPlayersList = Players:GetPlayers() 
        updateCharacterCache()
        plr.CharacterAdded:Connect(function()
            task.wait(0.1)
            updateCharacterCache()
        end)
    end))

    table.insert(globalConnections, Players.PlayerRemoving:Connect(function(plr) 
        cachedPlayersList = Players:GetPlayers() 
        updateCharacterCache()
        if speedCache then speedCache[plr] = nil end
    end))

    -- Ativar escuta para os jogadores que já estão no jogo
    for _, plr in ipairs(cachedPlayersList) do
        plr.CharacterAdded:Connect(function()
            task.wait(0.1)
            updateCharacterCache()
        end)
    end
    updateCharacterCache()

    -- Controle de Estados Ativos (Evita loops órfãos)
    local compProgressActive = false
    local doorProgressActive = false
    local exitDoorActive = false

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
    local speedCache = {} 

    -- Vars Wallhop Counter
    local WallhopStateConn = nil
    local WallhopCharConn = nil
    local WallhopTimerConn = nil

    -- Vars GetUp Timer & Hide Setting
    local getupActive = false
    local hideHeadGetUp = false
    local getupScreenGui = nil
    local getupGlobalFrame = nil
    local getupGlobalLabels = {}
    local getupActiveConnections = {}
    local getupLoopConn = nil

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
        compProgressActive = state
        if state then
            local function createProgressBar(parent)
                if currentComputerStyle == "Default" or currentComputerStyle == "Style 1" then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "ProgressBar"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 80, 0, 26)
                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    billboard.AlwaysOnTop = true

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

                    billboard.Parent = parent
                    return billboard, bar, text
                elseif currentComputerStyle == "Style 1" then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "ProgressBar"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 110, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 4.5, 0)
                    billboard.AlwaysOnTop = true

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

                    billboard.Parent = parent
                    return billboard, bar, text
                else
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "ProgressBar"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 120, 0, 12)
                    billboard.StudsOffset = Vector3.new(0, 4.2, 0)
                    billboard.AlwaysOnTop = true

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

                    billboard.Parent = parent
                    return billboard, bar, text
                end
            end

            local function setupComputer(tableModel)
                if tableModel:FindFirstChild("ProgressBar") then return end

                local billboard, bar, text = createProgressBar(tableModel)
                
                local highlight = tableModel:FindFirstChild("ComputerHighlight") or Instance.new("Highlight")
                highlight.Name = "ComputerHighlight"
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                highlight.OutlineTransparency = 0
                highlight.Enabled = compHighlightEnabled or compOutlineEnabled
                highlight.Parent = tableModel

                activeCompHighlights[tableModel] = highlight

                local screen = tableModel:FindFirstChild("Screen")
                local triggers = {}
                for _, child in ipairs(tableModel:GetChildren()) do
                    if child:IsA("BasePart") and child.Name:find("ComputerTrigger") then
                        table.insert(triggers, child)
                    end
                end

                local savedProgress = 0
                local lastSize = -1
                local updateInterval = 0.05 
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

                    if highlight.Enabled ~= (compHighlightEnabled or compOutlineEnabled) then
                        highlight.Enabled = compHighlightEnabled or compOutlineEnabled
                    end

                    if compOutlineEnabled then
                        if highlight.FillTransparency ~= 1 then highlight.FillTransparency = 1 end
                        if highlight.OutlineTransparency ~= 0 then highlight.OutlineTransparency = 0 end
                        if isGreen then
                            if highlight.OutlineColor ~= Color3.fromRGB(0, 255, 0) then
                                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                            end
                        else
                            if screen then
                                local color = screen.Color
                                local targetColor = (color.R > color.G and color.R > color.B) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 180, 255)
                                if highlight.OutlineColor ~= targetColor then
                                    highlight.OutlineColor = targetColor
                                end
                            end
                        end
                    else
                        if highlight.FillTransparency ~= 0.5 then highlight.FillTransparency = 0.5 end
                        if highlight.OutlineTransparency ~= 0 then highlight.OutlineTransparency = 0 end
                        if highlight.OutlineColor ~= Color3.fromRGB(0, 0, 0) then
                            highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                        end
                        if screen and highlight.FillColor ~= screen.Color then
                            highlight.FillColor = screen.Color
                        end
                    end

                    if isGreen then
                        savedProgress = 1
                    else
                        local highestTouch = 0
                        
                        -- Varredura segura contra destruição/erros físicos
                        if #cachedCharacters > 0 then
                            for i = 1, #triggers do
                                local part = triggers[i]
                                if part and part:IsA("BasePart") and part.Parent then
                                    local success, touchingParts = pcall(function()
                                        return Workspace:GetPartsInPart(part, globalOverlapParams)
                                    end)
                                    if success and touchingParts then
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
                        end
                        savedProgress = math.max(savedProgress, highestTouch)
                    end

                    if savedProgress ~= lastSize then
                        lastSize = savedProgress
                        local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                        TweenService:Create(bar, tweenInfo, {Size = UDim2.new(savedProgress, 0, 1, 0)}):Play()
                    end

                    local textLabelText = ""
                    local textLabelColor = Color3.fromRGB(255, 255, 255)
                    local barColor = Color3.fromRGB(255, 255, 255)

                    if currentComputerStyle == "Default" then
                        if savedProgress >= 1 then
                            barColor = Color3.fromRGB(0, 255, 140)
                            textLabelColor = Color3.fromRGB(0, 255, 140)
                            textLabelText = "COMPLETED"
                        else
                            barColor = Color3.fromRGB(0, 180, 255)
                            textLabelColor = Color3.fromRGB(255, 255, 255)
                            textLabelText = string.format("%.1f%%", math.floor(savedProgress * 200 + 0.1) / 2)
                        end
                    elseif currentComputerStyle == "Style 1" then
                        if savedProgress >= 0.99 then
                            barColor = Color3.fromRGB(0, 255, 100)
                            textLabelColor = Color3.fromRGB(0, 255, 100)
                            textLabelText = "DONE"
                        else
                            barColor = Color3.fromRGB(255, 255, 255)
                            textLabelColor = Color3.fromRGB(255, 255, 255)
                            textLabelText = string.format("%d%%", math.floor(savedProgress * 100))
                        end
                    else
                        if savedProgress >= 1 then
                            barColor = Color3.fromRGB(0, 255, 0)
                            textLabelText = "COMPLETED"
                        else
                            barColor = Color3.fromRGB(255, 255, 255)
                            textLabelText = string.format("%.1f%%", math.floor(savedProgress * 200 + 0.1) / 2)
                        end
                    end

                    if text.Text ~= textLabelText then text.Text = textLabelText end
                    if text.TextColor3 ~= textLabelColor then text.TextColor3 = textLabelColor end
                    if bar.BackgroundColor3 ~= barColor then bar.BackgroundColor3 = barColor end
                end)
                table.insert(CompProgConns, connection)
            end

            CompProgLoop = task.spawn(function()
                while compProgressActive do
                    local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
                    if currentMap and currentMap.Value ~= "" then
                        local mapName = tostring(currentMap.Value)
                        local map = Workspace:FindFirstChild(mapName)
                        if map then
                            local children = map:GetChildren()
                            for i = 1, #children do
                                local obj = children[i]
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
            table.clear(activeCompHighlights)
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "ProgressBar" and obj:IsA("BillboardGui") then obj:Destroy() end
                if obj.Name == "ComputerHighlight" and obj:IsA("Highlight") then obj:Destroy() end
            end
        end
    end)
    
    -- 2. Door Progress
    Library:CreateToggle(Page, "Door Progress", false, function(state)
        doorProgressActive = state
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
                    
                    billboard.Parent = parent
                    return billboard, fill, text, bgBar
                elseif currentDoorStyle == "Style 1" then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "NormalDoorGUI"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.fromOffset(90, 22)
                    billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 0.1)
                    billboard.AlwaysOnTop = true
                    billboard.MaxDistance = doorMaxDistance

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

                    billboard.Parent = parent
                    return billboard, fill, text, bgBar
                else
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "NormalDoorGUI"
                    billboard.Adornee = parent
                    billboard.Size = UDim2.new(0, 100, 0, 40) 
                    billboard.StudsOffset = Vector3.new(0, 0, 0)
                    billboard.AlwaysOnTop = true
                    billboard.MaxDistance = doorMaxDistance

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

                    billboard.Parent = parent
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
                while doorProgressActive do
                    local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
                    local mapName = currentMap and tostring(currentMap.Value) or ""
                    
                    if mapName ~= "" and lastMap ~= mapName then
                        lastMap = mapName
                        cleanupNormalDoors()

                        local map = Workspace:FindFirstChild(mapName)
                        if map then
                            local mapChildren = map:GetChildren()
                            for i = 1, #mapChildren do
                                local obj = mapChildren[i]
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
                if accum < 0.05 then return end 
                accum = 0
                
                table.clear(currentDoorInteractions)

                for i = 1, #cachedPlayersList do
                    local player = cachedPlayersList[i]
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
                        if not data.Billboard.Enabled then data.Billboard.Enabled = true end
                        local targetHighlightState = doorHighlightEnabled or doorOutlineEnabled
                        if data.Highlight.Enabled ~= targetHighlightState then
                            data.Highlight.Enabled = targetHighlightState
                        end
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
                        if data.Highlight.FillTransparency ~= 1 then data.Highlight.FillTransparency = 1 end
                        if data.Highlight.OutlineTransparency ~= 0 then data.Highlight.OutlineTransparency = 0 end
                        local targetColor = isPhysicallyOpen and Color3.fromRGB(0, 255, 100) or (interactionVal > 0.001 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 0, 0))
                        if data.Highlight.OutlineColor ~= targetColor then data.Highlight.OutlineColor = targetColor end
                    else
                        if data.Highlight.FillTransparency ~= 0.55 then data.Highlight.FillTransparency = 0.55 end
                        if data.Highlight.OutlineTransparency ~= 0 then data.Highlight.OutlineTransparency = 0 end
                        if data.Highlight.OutlineColor ~= Color3.fromRGB(0, 0, 0) then data.Highlight.OutlineColor = Color3.fromRGB(0, 0, 0) end
                        local targetColor = isPhysicallyOpen and Color3.fromRGB(0, 255, 100) or (interactionVal > 0.001 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 0, 0))
                        if data.Highlight.FillColor ~= targetColor then data.Highlight.FillColor = targetColor end
                    end

                    if currentDoorStyle == "Default" or currentDoorStyle == "Style 1" then
                        local baseColor = (currentDoorStyle == "Default") and Color3.fromRGB(205, 135, 25) or Color3.fromRGB(255, 210, 140)
                        local barColor = (currentDoorStyle == "Default") and Color3.fromRGB(205, 135, 25) or Color3.fromRGB(170, 100, 40)

                        if isPhysicallyOpen then
                            if data.LastState ~= "Open" then
                                data.LastState = "Open"
                                data.Bar.Size = UDim2.new(1, 0, 1, 0)
                                if data.Bar.BackgroundColor3 ~= Color3.fromRGB(255, 255, 255) then data.Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end
                                if data.Text.TextColor3 ~= Color3.fromRGB(255, 255, 255) then data.Text.TextColor3 = Color3.fromRGB(255, 255, 255) end
                                if data.Text.Text ~= "100.0%" then data.Text.Text = "100.0%" end
                            end
                        elseif interactionVal > 0.001 then 
                            if data.LastState ~= "Opening" or math.abs(data.LastProgress - interactionVal) > 0.005 then
                                data.LastState = "Opening"
                                data.LastProgress = interactionVal
                                data.Bar.Size = UDim2.new(math.clamp(interactionVal, 0, 1), 0, 1, 0)
                                if data.Bar.BackgroundColor3 ~= barColor then data.Bar.BackgroundColor3 = barColor end
                                if data.Text.TextColor3 ~= baseColor then data.Text.TextColor3 = baseColor end
                                local targetStr = string.format("%.1f%%", interactionVal * 100)
                                if data.Text.Text ~= targetStr then data.Text.Text = targetStr end
                            end
                        else
                            if data.LastState ~= "Closed" then
                                data.LastState = "Closed"
                                data.Bar.Size = UDim2.new(0, 0, 1, 0)
                                if data.Bar.BackgroundColor3 ~= barColor then data.Bar.BackgroundColor3 = barColor end
                                if data.Text.TextColor3 ~= baseColor then data.Text.TextColor3 = baseColor end
                                if data.Text.Text ~= "0.0%" then data.Text.Text = "0.0%" end
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
                                if data.Text.Text ~= "OPEN" then data.Text.Text = "OPEN" end
                                if data.Text.TextColor3 ~= COLORS_STYLE2.OPEN then data.Text.TextColor3 = COLORS_STYLE2.OPEN end
                                if data.BgBar.Visible ~= false then data.BgBar.Visible = false end
                            end
                        elseif interactionVal > 0.05 then 
                            data.LastState = "Opening"
                            if data.Text.Text ~= "OPENING" then data.Text.Text = "OPENING" end
                            if data.Text.TextColor3 ~= COLORS_STYLE2.OPENING then data.Text.TextColor3 = COLORS_STYLE2.OPENING end
                            if data.BgBar.Visible ~= true then data.BgBar.Visible = true end
                            data.Bar.Size = UDim2.new(math.clamp(interactionVal, 0, 1), 0, 1, 0)
                        else
                            if data.LastState ~= "Closed" then
                                data.LastState = "Closed"
                                if data.Text.Text ~= "CLOSE" then data.Text.Text = "CLOSE" end
                                if data.Text.TextColor3 ~= COLORS_STYLE2.CLOSE then data.Text.TextColor3 = COLORS_STYLE2.CLOSE end
                                if data.BgBar.Visible ~= false then data.BgBar.Visible = false end
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
        exitDoorActive = state
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

                local bgui = Instance.new("BillboardGui")
                bgui.Name = "UI"
                bgui.Size = UDim2.new(0, 140, 0, 45) 
                bgui.StudsOffset = Vector3.new(0, 5, 0)
                bgui.AlwaysOnTop = true
                bgui.Adornee = mainPart
                
                local txt = Instance.new("TextLabel")
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
                txt.Parent = bgui
                
                local barBg = Instance.new("Frame")
                barBg.Name = "BarBg"
                barBg.Size = UDim2.new(0.8, 0, 0, 6) 
                barBg.Position = UDim2.new(0.1, 0, 0.7, 0) 
                barBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                barBg.BackgroundTransparency = 0.4
                barBg.BorderSizePixel = 0
                barBg.Parent = bgui
                
                local bgCorner = Instance.new("UICorner")
                bgCorner.CornerRadius = UDim.new(1, 0)
                bgCorner.Parent = barBg
                
                local bgStroke = Instance.new("UIStroke")
                bgStroke.Color = Color3.fromRGB(0, 0, 0)
                bgStroke.Thickness = 1.2
                bgStroke.Transparency = 0.2
                bgStroke.Parent = barBg
                
                local fill = Instance.new("Frame")
                fill.Name = "Fill"
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(255, 160, 20) 
                fill.BorderSizePixel = 0
                fill.Parent = barBg
                
                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(1, 0)
                fillCorner.Parent = fill
                
                highlight.Parent = folder
                bgui.Parent = folder

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

            local function scanForExitDoors()
                local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
                local activeMap = currentMap and Workspace:FindFirstChild(tostring(currentMap.Value))
                local searchArea = activeMap or Workspace
                
                local children = searchArea:GetChildren()
                for i = 1, #children do
                    local obj = children[i]
                    if obj.Name == "ExitDoor" and obj:IsA("Model") then
                        registerExitDoor(obj)
                    end
                end
                
                local descendants = searchArea:GetDescendants()
                for i = 1, #descendants do
                    local obj = descendants[i]
                    if obj.Name == "ExitDoor" and obj:IsA("Model") then
                        registerExitDoor(obj)
                    end
                end
            end
            
            scanForExitDoors()

            ExitDoorAdded = workspace.DescendantAdded:Connect(function(obj)
                if obj.Name == "ExitDoor" and obj:IsA("Model") then
                    task.defer(function()
                        registerExitDoor(obj)
                    end)
                end
            end)

            ExitDoorConn = task.spawn(function()
                while exitDoorActive do 
                    local openingNow = {}

                    for i = 1, #cachedPlayersList do
                        local plr = cachedPlayersList[i]
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
                            local targetHighlightState = exitHighlightEnabled or exitOutlineEnabled
                            if data.Highlight.Enabled ~= targetHighlightState then
                                data.Highlight.Enabled = targetHighlightState
                            end
                            
                            if exitOutlineEnabled then
                                if data.Highlight.FillTransparency ~= 1 then data.Highlight.FillTransparency = 1 end
                                if data.Highlight.OutlineTransparency ~= 0 then data.Highlight.OutlineTransparency = 0 end
                                local targetColor = data.Completed and Color3.fromRGB(40, 255, 80) or Color3.fromRGB(255, 255, 0)
                                if data.Highlight.OutlineColor ~= targetColor then data.Highlight.OutlineColor = targetColor end
                            else
                                if data.Highlight.FillTransparency ~= 0.55 then data.Highlight.FillTransparency = 0.55 end
                                if data.Highlight.OutlineTransparency ~= 0 then data.Highlight.OutlineTransparency = 0 end
                                local targetColor = data.Completed and Color3.fromRGB(40, 255, 80) or Color3.fromRGB(255, 255, 0)
                                if data.Highlight.FillColor ~= targetColor then data.Highlight.FillColor = targetColor end
                            end
                        end
                        
                        if data.Completed then
                            data.FillElement.Size = UDim2.new(1, 0, 1, 0)
                            if data.FillElement.BackgroundColor3 ~= Color3.fromRGB(40, 255, 80) then data.FillElement.BackgroundColor3 = Color3.fromRGB(40, 255, 80) end
                            if data.TextElement.Text ~= "DOOR OPENED!" then data.TextElement.Text = "DOOR OPENED!" end
                            if data.TextElement.TextColor3 ~= Color3.fromRGB(40, 255, 80) then data.TextElement.TextColor3 = Color3.fromRGB(40, 255, 80) end
                        else
                            data.FillElement.Size = UDim2.new(data.Progress, 0, 1, 0)
                            if data.FillElement.BackgroundColor3 ~= Color3.fromRGB(255, 160, 20) then data.FillElement.BackgroundColor3 = Color3.fromRGB(255, 160, 20) end
                            
                            local targetStr = (data.Progress > 0) and ("OPENING: " .. math.floor(data.Progress * 100) .. "%") or "EXIT"
                            if data.TextElement.Text ~= targetStr then data.TextElement.Text = targetStr end
                            if data.TextElement.TextColor3 ~= Color3.fromRGB(255, 255, 255) then data.TextElement.TextColor3 = Color3.fromRGB(255, 255, 255) end
                        end
                    end
                    task.wait(0.12)
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
                speedRenderConn = RunService.RenderStepped:Connect(function()
                    if not speedActive then return end

                    local roundActive = false
                    for i = 1, #cachedPlayersList do
                        if cachedPlayersList[i]:FindFirstChild("TempPlayerStatsModule", true) then
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
                            
                            speedScreenGui.Parent = targetGuiParent
                        end
                        if not speedScreenGui.Enabled then speedScreenGui.Enabled = true end
                    else
                        if speedScreenGui and speedScreenGui.Enabled then
                            speedScreenGui.Enabled = false
                        end
                    end

                    for i = 1, #cachedPlayersList do
                        local player = cachedPlayersList[i]
                        local char = player.Character
                        
                        -- Sistema de Cache de referências rápidas de personagens
                        local cache = speedCache[player]
                        if not cache or cache.Char ~= char then
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                            local head = char and char:FindFirstChild("Head")
                            cache = {Char = char, Root = root, Humanoid = humanoid, Head = head}
                            speedCache[player] = cache
                        end

                        local root = cache.Root
                        local humanoid = cache.Humanoid
                        local head = cache.Head

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
                                local speedTag = char:FindFirstChild("SpeedTag")
                                if speedTag and speedTag.Enabled then
                                    speedTag.Enabled = false
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
                                if not label.Visible then label.Visible = true end
                                local targetText = player.Name .. ": " .. speedStr
                                if label.Text ~= targetText then label.Text = targetText end
                            else
                                if speedLabels2D[player] and speedLabels2D[player].Visible then
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
                                if tag and not tag.Enabled then tag.Enabled = true end
                                if label and label.Text ~= speedStr then label.Text = speedStr end
                            end
                        else
                            if speedLabels2D[player] and speedLabels2D[player].Visible then
                                speedLabels2D[player].Visible = false
                            end
                            local speedTag = char and char:FindFirstChild("SpeedTag")
                            if speedTag and speedTag.Enabled then
                                speedTag.Enabled = false
                            end
                        end
                    end
                end)
            end
        else
            if speedRenderConn then speedRenderConn:Disconnect(); speedRenderConn = nil end
            if speedScreenGui then speedScreenGui:Destroy(); speedScreenGui = nil end
            table.clear(speedLabels2D)
            table.clear(speedCache)
            for i = 1, #cachedPlayersList do
                local player = cachedPlayersList[i]
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

            sg.Parent = CoreGui

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

            local function hookCountState(combo)
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
                            hookCountState(hopCount)
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
    
    -- 1. GetUp Timer (Substituído e Integrado com Sucesso)
    Library:CreateToggle(Page, "GetUp Timer", false, function(state)
        getupActive = state
        if state then
            local uiParent = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
            
            if uiParent:FindFirstChild("RagdollCountdownScreenUI") then
                uiParent.RagdollCountdownScreenUI:Destroy()
            end

            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Head") then
                    local b = p.Character.Head:FindFirstChild("RagdollCountdown")
                    if b then b:Destroy() end
                end
            end

            getupScreenGui = Instance.new("ScreenGui")
            getupScreenGui.Name = "RagdollCountdownScreenUI"
            getupScreenGui.ResetOnSpawn = false

            getupGlobalFrame = Instance.new("Frame")
            getupGlobalFrame.Size = UDim2.new(0, 300, 0, 400)
            getupGlobalFrame.Position = UDim2.new(1, -310, 0.55, 0)
            getupGlobalFrame.BackgroundTransparency = 1
            getupGlobalFrame.Parent = getupScreenGui

            local uiList = Instance.new("UIListLayout")
            uiList.Padding = UDim.new(0, 5)
            uiList.Parent = getupGlobalFrame

            getupScreenGui.Parent = uiParent

            local COUNTDOWN_DURATION = 28

            local createBillboardCountdown = function(player)
                if hideHeadGetUp then return nil, nil end 
                local character = player.Character
                if not character then return end
                local head = character:FindFirstChild("Head")
                if not head then return end
                local billboard = head:FindFirstChild("RagdollCountdown")
                if not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "RagdollCountdown"
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.new(5, 0, 3, 0)
                    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
                    billboard.Parent = head
                    local label = Instance.new("TextLabel")
                    label.Name = "CountdownLabel"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextScaled = true
                    label.TextStrokeTransparency = 0.2
                    label.TextStrokeColor3 = Color3.new(0, 0, 0)
                    label.Parent = billboard
                end
                return billboard, billboard:FindFirstChild("CountdownLabel")
            end

            local clearCountdown = function(player)
                if player.Character and player.Character:FindFirstChild("Head") then
                    local billboard = player.Character.Head:FindFirstChild("RagdollCountdown")
                    if billboard then billboard:Destroy() end
                end
                if getupGlobalLabels[player.UserId] then
                    getupGlobalLabels[player.UserId]:Destroy()
                    getupGlobalLabels[player.UserId] = nil
                end
                if getupActiveConnections[player.UserId] then
                    getupActiveConnections[player.UserId]:Disconnect()
                    getupActiveConnections[player.UserId] = nil
                end
            end

            local startCountdown = function(player)
                local head = player.Character and player.Character:FindFirstChild("Head")
                if not head then return end
                
                local _, bbLabel = createBillboardCountdown(player)
                local endTime = tick() + COUNTDOWN_DURATION
                if getupActiveConnections[player.UserId] then
                    getupActiveConnections[player.UserId]:Disconnect()
                end
                
                getupActiveConnections[player.UserId] = RunService.RenderStepped:Connect(function()
                    if not getupScreenGui or not getupScreenGui.Parent then
                        clearCountdown(player)
                        return
                    end
                    local remaining = endTime - tick()
                    if remaining <= 0 then
                        clearCountdown(player)
                        return
                    end
                    local formatted = string.format("%.2f", remaining)
                    
                    local richTextFormatted = '<stroke thickness="3" color="rgb(0,0,0)"><font color="rgb(255,255,255)">' .. player.Name .. '</font></stroke>\n<stroke thickness="3" color="rgb(0,0,0)"><font color="rgb(255,0,0)">' .. formatted .. '</font></stroke>'
                    
                    if bbLabel then
                        if not bbLabel.RichText then bbLabel.RichText = true end
                        if bbLabel.Text ~= richTextFormatted then bbLabel.Text = richTextFormatted end
                    end
                    
                    local label = getupGlobalLabels[player.UserId]
                    if not label then
                        label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 0, 70)
                        label.BackgroundTransparency = 1
                        label.TextScaled = true
                        label.Font = Enum.Font.SourceSansBold
                        label.TextStrokeTransparency = 0.2
                        label.TextStrokeColor3 = Color3.new(0, 0, 0)
                        label.Parent = getupGlobalFrame
                        getupGlobalLabels[player.UserId] = label
                    end
                    if not label.RichText then label.RichText = true end
                    if label.Text ~= richTextFormatted then label.Text = richTextFormatted end
                end)
            end

            getupLoopConn = RunService.Heartbeat:Connect(function()
                if not getupScreenGui or not getupScreenGui.Parent then
                    if getupLoopConn then getupLoopConn:Disconnect(); getupLoopConn = nil end
                    for _, player in ipairs(Players:GetPlayers()) do
                        clearCountdown(player)
                    end
                    return
                end
                
                local playersList = Players:GetPlayers()
                for i = 1, #playersList do
                    local player = playersList[i]
                    local character = player.Character
                    if character then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        local inRagdoll = humanoid and humanoid.PlatformStand
                        local head = character:FindFirstChild("Head")
                        local billboard = head and head:FindFirstChild("RagdollCountdown")
                        if inRagdoll then
                            if not billboard and not getupActiveConnections[player.UserId] then
                                startCountdown(player)
                            end
                        else
                            if billboard or getupActiveConnections[player.UserId] then
                                clearCountdown(player)
                            end
                        end
                    end
                end
            end)
        else
            -- Rotina de limpeza ao desativar o GetUp Timer
            if getupLoopConn then
                getupLoopConn:Disconnect()
                getupLoopConn = nil
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("Head") then
                    local b = player.Character.Head:FindFirstChild("RagdollCountdown")
                    if b then b:Destroy() end
                end
                if getupGlobalLabels[player.UserId] then
                    getupGlobalLabels[player.UserId]:Destroy()
                end
                if getupActiveConnections[player.UserId] then
                    getupActiveConnections[player.UserId]:Disconnect()
                end
            end
            table.clear(getupGlobalLabels)
            table.clear(getupActiveConnections)
            
            if getupScreenGui then
                getupScreenGui:Destroy()
                getupScreenGui = nil
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
            
            screenGui.Parent = container

            trackedPowerValue = nil
            lastPercent = 0
            isDraining = false

            BeastPowerConnection1 = task.spawn(function()
                while state do
                    local foundValue = nil
                    for i = 1, #cachedPlayersList do
                        local player = cachedPlayersList[i]
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
                    task.wait(0.5)
                end
            end)

            BeastPowerConnection2 = RunService.RenderStepped:Connect(function()
                if trackedPowerValue and trackedPowerValue.Parent then
                    if not uiFrameBP.Visible then uiFrameBP.Visible = true end
                    
                    local percent = math.clamp(trackedPowerValue.Value, 0, 1)
                    local percentInt = math.floor(percent * 100)
                    local textStr = ""
                    local textColor = Color3.fromRGB(255, 255, 255)

                    if percentInt >= 100 then
                        textStr = "BeastPower is Full"
                    else
                        textStr = "BeastPower Back In: " .. percentInt .. "%"
                    end
                    
                    if percent < lastPercent then
                        isDraining = true 
                    elseif percent > lastPercent then
                        isDraining = false 
                    end
                    
                    lastPercent = percent 
                    
                    if isDraining then
                        textColor = Color3.fromRGB(255, 255, 255)
                    else
                        if percent >= 0.99 then
                            textColor = Color3.fromRGB(50, 255, 50) 
                        elseif percent >= 0.80 then
                            textColor = Color3.fromRGB(255, 50, 50) 
                        else
                            textColor = Color3.fromRGB(255, 255, 255) 
                        end
                    end

                    if uiLabelBP.Text ~= textStr then uiLabelBP.Text = textStr end
                    if uiLabelBP.TextColor3 ~= textColor then uiLabelBP.TextColor3 = textColor end
                else
                    if uiFrameBP and uiFrameBP.Visible then uiFrameBP.Visible = false end
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
                        
                        billboard.Parent = humanoidRootPart
                    end
                    return billboard.BeastPowerLabel
                end
            end
            return nil
        end
        if state then
            BeastPowerLoop2 = task.spawn(function()
                while state do
                    for i = 1, #cachedPlayersList do
                        local player = cachedPlayersList[i]
                        if player ~= LocalPlayer then
                            local label = CreateLabelBP(player)
                            if label then
                                local beastPowers = player.Character and player.Character:FindFirstChild("BeastPowers")
                                if beastPowers then
                                    local numberValue = beastPowers:FindFirstChildOfClass("NumberValue")
                                    if numberValue then
                                        local roundedValue = math.round(numberValue.Value * 100)
                                        local targetStr = tostring(roundedValue) .. "%"
                                        if label.Text ~= targetStr then label.Text = targetStr end
                                    else
                                        if label.Text ~= "" then label.Text = "" end
                                    end
                                else
                                    if label.Text ~= "" then label.Text = "" end
                                end
                            end
                        end
                    end
                    task.wait(0.25)
                end
            end)
        else
            if BeastPowerLoop2 then task.cancel(BeastPowerLoop2); BeastPowerLoop2 = nil end
            for i = 1, #cachedPlayersList do
                local player = cachedPlayersList[i]
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

            sg.Parent = CoreGui

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
                        local targetSuccessText = "The Beast has been released!"
                        if label.Text ~= targetSuccessText then label.Text = targetSuccessText end
                        TweenColor(Color3.fromRGB(255, 255, 255))
                        task.delay(3, FadeOut)
                        return
                    end

                    local tempoRestante = 15 - (os.clock() - tempoInicio)

                    if tempoRestante <= 0 then
                        if label.Text ~= "Beast Spawns In: 0.0" then label.Text = "Beast Spawns In: 0.0" end
                    else
                        local targetTimerText = string.format("Beast Spawns In: %.1f", tempoRestante)
                        if label.Text ~= targetTimerText then label.Text = targetTimerText end
                        
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
                    
                    task.wait(0.1)
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
    
    -- 5. Life Timer
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
                    return head, Vector3.new(0, 0, 0) 
                elseif lifeTimerOrigin == "Torso" then
                    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                    return torso, Vector3.new(0, 0, 0)
                else 
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
                        local timeStr = string.format("%.1f", secondsLeft) .. "s"
                        if label.Text ~= timeStr then label.Text = timeStr end
                        if label.TextColor3 ~= TIMER_COLOR then label.TextColor3 = TIMER_COLOR end
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
                    task.wait(0.1)
                    updatePlayerTag(player)
                end)
                table.insert(lifePlayerConns[player], charConn)
            end

            for i = 1, #cachedPlayersList do
                monitorPlayer(cachedPlayersList[i])
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
                    for i = 1, #cachedPlayersList do
                        updatePlayerTag(cachedPlayersList[i])
                    end
                    task.wait(1) 
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

            for i = 1, #cachedPlayersList do
                local player = cachedPlayersList[i]
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
        local target = state or compOutlineEnabled
        for tableModel, hl in pairs(activeCompHighlights) do
            if hl and hl.Parent then
                hl.Enabled = target
            else
                activeCompHighlights[tableModel] = nil
            end
        end
    end)

    -- 2. Computer Outline
    Library:CreateToggle(Page, "Computer Outline", false, function(state)
        compOutlineEnabled = state
        local target = compHighlightEnabled or state
        for tableModel, hl in pairs(activeCompHighlights) do
            if hl and hl.Parent then
                hl.Enabled = target
            else
                activeCompHighlights[tableModel] = nil
            end
        end
    end)

    -- 3. Door Highlight
    Library:CreateToggle(Page, "Door Highlight", false, function(state)
        doorHighlightEnabled = state
        local target = state or doorOutlineEnabled
        for _, data in pairs(trackedNormalDoors) do
            if data.Highlight then
                data.Highlight.Enabled = target
            end
        end
    end)

    -- 4. Door Outline
    Library:CreateToggle(Page, "Door Outline", false, function(state)
        doorOutlineEnabled = state
        local target = doorHighlightEnabled or state
        for _, data in pairs(trackedNormalDoors) do
            if data.Highlight then
                data.Highlight.Enabled = target
            end
        end
    end)

    -- 5. ExitDoor Highlight
    Library:CreateToggle(Page, "ExitDoor Highlight", false, function(state)
        exitHighlightEnabled = state
        local target = state or exitOutlineEnabled
        for _, data in pairs(trackedExitDoors) do
            if data.Highlight then
                data.Highlight.Enabled = target
            end
        end
    end)

    -- 6. ExitDoor Outline
    Library:CreateToggle(Page, "ExitDoor Outline", false, function(state)
        exitOutlineEnabled = state
        local target = exitHighlightEnabled or state
        for _, data in pairs(trackedExitDoors) do
            if data.Highlight then
                data.Highlight.Enabled = target
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
            if obj.Name == "ProgressBar" && obj:IsA("BillboardGui") then obj:Destroy() end
            if obj.Name == "ComputerHighlight" && obj:IsA("Highlight") then obj:Destroy() end
        end
        table.clear(CompProgConns)
        table.clear(activeCompHighlights)
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

    -- 3. Life Timer Origin (Dropdown posicionado em baixo do Door Progress Design)
    Library:CreateDropdown(Page, "Life Timer Origin", {"Head", "Torso", "Inferior"}, "Head", function(val)
        lifeTimerOrigin = val
        if lifeActive then
            for i = 1, #cachedPlayersList do
                local player = cachedPlayersList[i]
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

    -- 4. Hide Head GetUp
    Library:CreateToggle(Page, "Hide Head GetUp", false, function(state)
        hideHeadGetUp = state
        if state then
            for i = 1, #cachedPlayersList do
                local char = cachedPlayersList[i].Character
                local head = char and char:FindFirstChild("Head")
                local bb = head and head:FindFirstChild("RagdollCountdown")
                if bb then bb:Destroy() end
            end
        end
    end)

    -- 5. WalkSpeed Lateral
    Library:CreateToggle(Page, "WalkSpeed Lateral", false, function(state)
        lateralSpeedActive = state
        
        if not state then
            if speedScreenGui then speedScreenGui:Destroy(); speedScreenGui = nil end
            table.clear(speedLabels2D)
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
