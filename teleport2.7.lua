return function(env)
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local ScreenGui = env.ScreenGui
    local SendNotification = env.SendNotification
    local UserInputService = env.UserInputService

    local TweenService = game:GetService("TweenService")

    local savedCFrame = nil
    local checkpointMarker = nil
    local currentPCIndex = 0
    local currentDoorIndex = 0
    local currentPodIndex = 0
    local tpKeybindConn = nil

    -- Cores do Tema
    local Theme = {
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(150, 150, 150),
        CardBg = Color3.fromRGB(0, 0, 0),             -- Preto Puro
        ItemBg = Color3.fromRGB(0, 0, 0),             -- Fundo interno preto
        Stroke = Color3.fromRGB(45, 45, 45),
        ButtonWhite = Color3.fromRGB(255, 255, 255),  -- Botão Branco Sólido
        ButtonWhiteHover = Color3.fromRGB(220, 220, 220)
    }

    -- ==========================================
    -- COLUNA ESQUERDA: MAP OBJECTS
    -- ==========================================
    Library:CreateSection(Page, "Map Objects", "Left")

    Library:CreateButton(Page, "TP Computer", function() 
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local pcs = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "ComputerTable" then table.insert(pcs, obj) end
        end
        if #pcs == 0 then SendNotification("Map not loaded!", 2) return end
        currentPCIndex = currentPCIndex + 1
        if currentPCIndex > #pcs then currentPCIndex = 1 end
        local pc = pcs[currentPCIndex]
        local pcCFrame
        if pc:IsA("Model") then pcCFrame = pc:GetPivot() else
            local part = pc:FindFirstChildWhichIsA("BasePart")
            if part then pcCFrame = part.CFrame end
        end
        if pcCFrame then char.HumanoidRootPart.CFrame = pcCFrame * CFrame.new(0, 3, -3) end
    end)

    Library:CreateButton(Page, "TP Exitdoor", function() 
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local doors = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local name = string.lower(obj.Name)
                if string.find(name, "exit") and string.find(name, "door") then table.insert(doors, obj) end
            end
        end
        if #doors == 0 then SendNotification("ExitDoors not found!", 2) return end
        currentDoorIndex = currentDoorIndex + 1
        if currentDoorIndex > #doors then currentDoorIndex = 1 end
        local door = doors[currentDoorIndex]
        local part = door.PrimaryPart or door:FindFirstChildWhichIsA("BasePart")
        if part then char.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0) end
    end)

    Library:CreateButton(Page, "TP Freezepods", function() 
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local pods = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "FreezePod" then table.insert(pods, obj) end
        end
        if #pods == 0 then SendNotification("Map not loaded!", 2) return end
        currentPodIndex = currentPodIndex + 1
        if currentPodIndex > #pods then currentPodIndex = 1 end
        local pod = pods[currentPodIndex]
        local base = pod:FindFirstChild("BasePart") or pod:FindFirstChildWhichIsA("Part")
        if base then char.HumanoidRootPart.CFrame = base.CFrame * CFrame.new(0, 1, -3) end
    end)

    Library:CreateButton(Page, "Tp Map", function() end)
    Library:CreateButton(Page, "TP Crystal Cove", function() end)
    Library:CreateButton(Page, "TP Beast Cave", function() end)

    -- ==========================================
    -- COLUNA DIREITA: EXTRAS
    -- ==========================================
    Library:CreateSection(Page, "Extras", "Right")

    -- Lógica de suporte do Checkpoint
    local CheckpointFrame = ScreenGui:FindFirstChild("CheckpointFrame")
    if not CheckpointFrame then
        CheckpointFrame = Instance.new("Frame")
        CheckpointFrame.Name = "CheckpointFrame"
        CheckpointFrame.Size = UDim2.new(0, 40, 0, 90)
        CheckpointFrame.Position = UDim2.new(0, 2, 0.5, -45)
        CheckpointFrame.BackgroundTransparency = 1
        CheckpointFrame.Visible = false
        CheckpointFrame.ZIndex = 50
        CheckpointFrame.Parent = ScreenGui

        local CPListLayout = Instance.new("UIListLayout")
        CPListLayout.Parent = CheckpointFrame
        CPListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        CPListLayout.Padding = UDim.new(0, 8)

        local SetBtn = Instance.new("ImageButton")
        SetBtn.Size = UDim2.new(1, 0, 0, 40)
        SetBtn.BackgroundTransparency = 1
        SetBtn.Image = "rbxassetid://6723742952"
        SetBtn.Parent = CheckpointFrame

        local TpBtn = Instance.new("ImageButton")
        TpBtn.Size = UDim2.new(1, 0, 0, 40)
        TpBtn.BackgroundTransparency = 1
        TpBtn.Image = "rbxassetid://6723921202"
        TpBtn.Parent = CheckpointFrame

        local function createMarker(cframe)
            if checkpointMarker and checkpointMarker.Parent then
                checkpointMarker:Destroy()
            end
            checkpointMarker = Instance.new("Part")
            checkpointMarker.Name = "FleeCheckpointMarker"
            checkpointMarker.Shape = Enum.PartType.Cylinder
            checkpointMarker.Size = Vector3.new(0.2, 4, 4)
            checkpointMarker.CFrame = cframe * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.rad(90))
            checkpointMarker.Anchored = true
            checkpointMarker.CanCollide = false
            checkpointMarker.Material = Enum.Material.Neon
            checkpointMarker.Color = Color3.fromRGB(0, 255, 128)
            checkpointMarker.Transparency = 0.4
            checkpointMarker.Parent = Workspace
            
            local light = Instance.new("PointLight")
            light.Color = checkpointMarker.Color
            light.Range = 8
            light.Brightness = 2
            light.Parent = checkpointMarker
        end

        local function teleportToCheckpoint()
            if savedCFrame then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = savedCFrame
                    TpBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)
                    task.delay(0.15, function() TpBtn.ImageColor3 = Color3.fromRGB(255, 255, 255) end)
                end
            else
                SendNotification("No checkpoint set!", 2)
            end
        end

        SetBtn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                savedCFrame = char.HumanoidRootPart.CFrame
                createMarker(savedCFrame)
                SetBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)
                task.delay(0.15, function() SetBtn.ImageColor3 = Color3.fromRGB(255, 255, 255) end)
                SendNotification("Checkpoint Set!", 2)
            end
        end)

        TpBtn.MouseButton1Click:Connect(teleportToCheckpoint)
    end

    local function toggleCheckpointLogic(state)
        CheckpointFrame.Visible = state 
        if state then
            if not tpKeybindConn then
                tpKeybindConn = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.KeyCode == Enum.KeyCode.R then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") and savedCFrame then
                            char.HumanoidRootPart.CFrame = savedCFrame
                        end
                    end
                end)
            end
        else
            if tpKeybindConn then 
                tpKeybindConn:Disconnect() 
                tpKeybindConn = nil 
            end
            if checkpointMarker then
                checkpointMarker:Destroy()
                checkpointMarker = nil
            end
            savedCFrame = nil
        end
    end

    Library:CreateToggle(Page, "Checkpoint (UI+R)", false, function(state)
        toggleCheckpointLogic(state)
    end)

    Library:CreateButton(Page, "Reset Character", function() end)
    Library:CreateButton(Page, "Server Rejoin", function() end)
    Library:CreateButton(Page, "Random Servers", function() end)
    Library:CreateButton(Page, "Teleport to Beast", function() end)

    -- ==========================================
    -- SISTEMA DE TELEPORTE HORIZONTAL (CARROSSEL DE CARDS DEITADOS)
    -- ==========================================
    Library:CreateSection(Page, "Players Teleport", "Right")
    local TargetBox = Library.CurrentSections[Page]

    -- Função local para desenhar o Card Horizontal deitado
    local function CreateCustomPlayerCard(parent, player, callback)
        local Card = Instance.new("Frame")
        Card.Name = "CustomPlayerCard"
        Card.Size = UDim2.new(0, 170, 1, -8) -- Dimensão horizontal (deitado) para caber no carrossel
        Card.BackgroundColor3 = Theme.ItemBg
        Card.BackgroundTransparency = 0.45 
        Card.BorderSizePixel = 0
        Card.Parent = parent

        local CardCorner = Instance.new("UICorner", Card)
        CardCorner.CornerRadius = UDim.new(0, 6)

        local CardStroke = Instance.new("UIStroke", Card)
        CardStroke.Color = Theme.Stroke
        CardStroke.Thickness = 1

        -- Imagem do Avatar (Esquerda)
        local Avatar = Instance.new("ImageLabel")
        Avatar.Size = UDim2.new(0, 32, 0, 32)
        Avatar.Position = UDim2.new(0, 8, 0.5, -16)
        Avatar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        Avatar.BorderSizePixel = 0
        Avatar.Image = "rbxassetid://0"
        Avatar.Parent = Card
        Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 6)

        task.spawn(function()
            local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            if isReady then Avatar.Image = content end
        end)

        -- Nome de Exibição (Display Name)
        local DisplayName = Instance.new("TextLabel")
        DisplayName.Text = player.DisplayName
        DisplayName.Size = UDim2.new(0, 75, 0, 14)
        DisplayName.Position = UDim2.new(0, 46, 0.5, -14)
        DisplayName.BackgroundTransparency = 1
        DisplayName.Font = Enum.Font.GothamBold
        DisplayName.TextColor3 = Theme.Text
        DisplayName.TextXAlignment = Enum.TextXAlignment.Left
        DisplayName.TextSize = 10
        DisplayName.TextScaled = true
        DisplayName.Parent = Card
        local dConst = Instance.new("UITextSizeConstraint", DisplayName)
        dConst.MaxTextSize = 10

        -- Nome de Usuário (Username com @)
        local Username = Instance.new("TextLabel")
        Username.Text = "@" .. player.Name
        Username.Size = UDim2.new(0, 75, 0, 12)
        Username.Position = UDim2.new(0, 46, 0.5, 1)
        Username.BackgroundTransparency = 1
        Username.Font = Enum.Font.Gotham
        Username.TextColor3 = Theme.TextDark
        Username.TextXAlignment = Enum.TextXAlignment.Left
        Username.TextSize = 8
        Username.TextScaled = true
        Username.Parent = Card
        local uConst = Instance.new("UITextSizeConstraint", Username)
        uConst.MaxTextSize = 8

        -- Botão de Teleporte Branco Sólido (Direita)
        local ActionBtn = Instance.new("TextButton")
        ActionBtn.Size = UDim2.new(0, 38, 0, 22)
        ActionBtn.Position = UDim2.new(1, -44, 0.5, -11)
        ActionBtn.BackgroundColor3 = Theme.ButtonWhite
        ActionBtn.Text = "TP"
        ActionBtn.Font = Enum.Font.GothamBold
        ActionBtn.TextSize = 10
        ActionBtn.TextColor3 = Color3.fromRGB(15, 15, 15) -- Texto Escuro
        ActionBtn.Parent = Card
        Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)

        local btnStroke = Instance.new("UIStroke", ActionBtn)
        btnStroke.Color = Color3.fromRGB(200, 200, 200)
        btnStroke.Thickness = 1

        ActionBtn.MouseEnter:Connect(function()
            TweenService:Create(ActionBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.ButtonWhiteHover}):Play()
        end)
        ActionBtn.MouseLeave:Connect(function()
            TweenService:Create(ActionBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.ButtonWhite}):Play()
        end)

        ActionBtn.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end

    if TargetBox then
        -- Container Geral (Preto Transparente)
        local UnifiedCard = Instance.new("Frame")
        UnifiedCard.Name = "PlayersTeleportContainer"
        UnifiedCard.Size = UDim2.new(1, 0, 0, 115) -- Altura otimizada para o carrossel horizontal
        UnifiedCard.BackgroundColor3 = Theme.CardBg
        UnifiedCard.BackgroundTransparency = 0.55
        UnifiedCard.BorderSizePixel = 0
        UnifiedCard.Parent = TargetBox

        local CardCorner = Instance.new("UICorner", UnifiedCard)
        CardCorner.CornerRadius = UDim.new(0, 8)
        
        local CardStroke = Instance.new("UIStroke", UnifiedCard)
        CardStroke.Color = Theme.Stroke
        CardStroke.Thickness = 1

        -- Botão de Refresh reduzido e integrado
        local RefreshBtn = Instance.new("TextButton")
        RefreshBtn.Name = "RefreshBtnStatic"
        RefreshBtn.Size = UDim2.new(1, -16, 0, 24)
        RefreshBtn.Position = UDim2.new(0, 8, 0, 6)
        RefreshBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        RefreshBtn.BackgroundTransparency = 0.4
        RefreshBtn.Text = "Refresh List"
        RefreshBtn.TextColor3 = Theme.Text
        RefreshBtn.Font = Enum.Font.GothamBold
        RefreshBtn.TextSize = 11
        RefreshBtn.Parent = UnifiedCard
        Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 5)
        
        local refStroke = Instance.new("UIStroke", RefreshBtn)
        refStroke.Color = Theme.Stroke

        -- Lista Horizontal (Carrossel)
        local ScrollList = Instance.new("ScrollingFrame")
        ScrollList.Name = "PlayerScrollList"
        ScrollList.Size = UDim2.new(1, -16, 1, -40)
        ScrollList.Position = UDim2.new(0, 8, 0, 34)
        ScrollList.BackgroundTransparency = 1
        ScrollList.BorderSizePixel = 0
        ScrollList.ScrollBarThickness = 3
        ScrollList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        ScrollList.ScrollingDirection = Enum.ScrollingDirection.Horizontal -- ROLAGEM HORIZONTAL
        ScrollList.Parent = UnifiedCard

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.FillDirection = Enum.FillDirection.Horizontal -- ALINHAMENTO LADO A LADO
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.Parent = ScrollList

        local function UpdateTeleportList()
            -- Limpar itens anteriores
            for _, child in ipairs(ScrollList:GetChildren()) do 
                if child.Name == "CustomPlayerCard" then 
                    child:Destroy() 
                end 
            end
            
            local addedCount = 0
            -- Recriar os cards horizontalmente
            for _, player in ipairs(Players:GetPlayers()) do 
                if player ~= LocalPlayer then 
                    addedCount = addedCount + 1
                    CreateCustomPlayerCard(ScrollList, player, function()
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                            LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0) 
                            SendNotification("Teleported to " .. player.DisplayName, 2)
                        else
                            SendNotification("Player character not loaded!", 2)
                        end
                    end) 
                end 
            end

            -- Ajustar dinamicamente o tamanho horizontal do Canvas
            ScrollList.CanvasSize = UDim2.new(0, addedCount * 178, 0, 0)
        end

        RefreshBtn.MouseButton1Click:Connect(function() 
            UpdateTeleportList() 
            SendNotification("Player list updated!", 2)
        end)

        UpdateTeleportList()
    end
end
