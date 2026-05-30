return function(env)
    local Library = env.Library
    local TeleportPage = env.Page
    local Players = env.Players
    local Workspace = env.Workspace
    local LocalPlayer = env.LocalPlayer
    local SendNotification = env.SendNotification
    local ScreenGui = env.ScreenGui
    local UserInputService = env.UserInputService

    local TweenService = game:GetService("TweenService")

    -- Fallback de segurança para o Theme caso não seja passado pelo host
    local Theme = env.Theme or {
        ItemStroke = Color3.fromRGB(60, 60, 60),
        Accent = Color3.fromRGB(240, 240, 240),
        Font = Enum.Font.GothamBold
    }

    local savedCFrame = nil
    local checkpointMarker = nil
    local currentPCIndex = 0
    local currentDoorIndex = 0
    local currentPodIndex = 0
    local tpKeybindConn = nil

    -- ==========================================
    -- COLUNA ESQUERDA: MAP OBJECTS
    -- ==========================================
    Library:CreateSection(TeleportPage, "Map Objects", "Left")

    Library:CreateButton(TeleportPage, "TP Computer", function()
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

    Library:CreateButton(TeleportPage, "TP Exitdoor", function()
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

    Library:CreateButton(TeleportPage, "TP Freezepods", function()
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

    Library:CreateButton(TeleportPage, "Tp Map", function() end)
    Library:CreateButton(TeleportPage, "TP Crystal Cove", function() end)
    Library:CreateButton(TeleportPage, "TP Beast Cave", function() end)


    -- ==========================================
    -- COLUNA DIREITA: EXTRAS
    -- ==========================================
    Library:CreateSection(TeleportPage, "Extras", "Right")

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

    Library:CreateButton(TeleportPage, "Reset Character", function() end)
    Library:CreateButton(TeleportPage, "Server Rejoin", function() end)
    Library:CreateButton(TeleportPage, "Random Servers", function() end)
    Library:CreateButton(TeleportPage, "Teleport to Beast", function() end)


    -- ==========================================
    -- COLUNA DIREITA: PLAYERS TELEPORT
    -- ==========================================
    Library:CreateSection(TeleportPage, "Players Teleport", "Right")
    
    -- Obtém a caixa da seção recém-criada (o card da direita)
    local targetSectionBox = Library.CurrentSections[TeleportPage]

    if targetSectionBox then
        -- Botão de Atualizar (Inserido de forma correta e limpa no topo do card)
        local RefreshBtn = Instance.new("TextButton")
        RefreshBtn.Name = "RefreshBtnStatic"
        RefreshBtn.Size = UDim2.new(1, 0, 0, 32)
        RefreshBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        RefreshBtn.BackgroundTransparency = 0.4
        RefreshBtn.Text = "Refresh List"
        RefreshBtn.TextColor3 = Theme.Accent
        RefreshBtn.Font = Theme.Font
        RefreshBtn.TextSize = 12
        RefreshBtn.Parent = targetSectionBox
        Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

        local btnStroke = Instance.new("UIStroke", RefreshBtn)
        btnStroke.Color = Theme.ItemStroke
        btnStroke.Thickness = 1

        -- Efeito de transição de hover no botão de Refresh
        RefreshButtonConn = RefreshBtn.MouseEnter:Connect(function()
            TweenService:Create(RefreshBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
        end)
        RefreshButtonLeaveConn = RefreshBtn.MouseLeave:Connect(function()
            TweenService:Create(RefreshBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
        end)

        -- Função auxiliar para criar as linhas de jogadores ("cards deitados")
        local function CreateCustomPlayerCard(player, callback)
            local Card = Instance.new("Frame")
            Card.Name = "PlayerCard"
            Card.Size = UDim2.new(1, 0, 0, 48)
            Card.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Card.BackgroundTransparency = 0.65 -- Fundo transparente
            Card.BorderSizePixel = 0
            Card.Parent = targetSectionBox

            Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
            local cardStroke = Instance.new("UIStroke", Card)
            cardStroke.Color = Color3.fromRGB(40, 40, 40)
            cardStroke.Thickness = 1

            -- Avatar
            local Avatar = Instance.new("ImageLabel")
            Avatar.Size = UDim2.new(0, 32, 0, 32)
            Avatar.Position = UDim2.new(0, 8, 0.5, -16)
            Avatar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            Avatar.BackgroundTransparency = 0.5
            Avatar.BorderSizePixel = 0
            Avatar.Parent = Card
            Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 6)

            task.spawn(function()
                local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                if isReady then Avatar.Image = content end
            end)

            -- Informações do Jogador
            local LabelContainer = Instance.new("Frame")
            LabelContainer.Size = UDim2.new(1, -135, 1, 0)
            LabelContainer.Position = UDim2.new(0, 48, 0, 0)
            LabelContainer.BackgroundTransparency = 1
            LabelContainer.Parent = Card

            local DisplayName = Instance.new("TextLabel")
            DisplayName.Size = UDim2.new(1, 0, 0, 18)
            DisplayName.Position = UDim2.new(0, 0, 0.5, -15)
            DisplayName.BackgroundTransparency = 1
            DisplayName.Text = player.DisplayName
            DisplayName.Font = Enum.Font.GothamBold
            DisplayName.TextSize = 12
            DisplayName.TextColor3 = Color3.fromRGB(255, 255, 255)
            DisplayName.TextXAlignment = Enum.TextXAlignment.Left
            DisplayName.Parent = LabelContainer

            local Username = Instance.new("TextLabel")
            Username.Size = UDim2.new(1, 0, 0, 14)
            Username.Position = UDim2.new(0, 0, 0.5, 2)
            Username.BackgroundTransparency = 1
            Username.Text = "@" .. player.Name
            Username.Font = Enum.Font.Gotham
            Username.TextSize = 10
            Username.TextColor3 = Color3.fromRGB(150, 150, 150)
            Username.TextXAlignment = Enum.TextXAlignment.Left
            Username.Parent = LabelContainer

            -- Botão de Teleporte (Branco Sólido com Texto Escuro)
            local TpBtn = Instance.new("TextButton")
            TpBtn.Size = UDim2.new(0, 70, 0, 24)
            TpBtn.Position = UDim2.new(1, -78, 0.5, -12)
            TpBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Branco sólido
            TpBtn.Text = "Teleport"
            TpBtn.Font = Enum.Font.GothamBold
            TpBtn.TextSize = 10
            TpBtn.TextColor3 = Color3.fromRGB(15, 15, 15) -- Texto escuro
            TpBtn.Parent = Card

            Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0, 5)
            local tpStroke = Instance.new("UIStroke", TpBtn)
            tpStroke.Color = Color3.fromRGB(200, 200, 200)
            tpStroke.Thickness = 1

            -- Transição Hover Suave para o botão branco
            TpBtn.MouseEnter:Connect(function()
                TweenService:Create(TpBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
            end)
            TpBtn.MouseLeave:Connect(function()
                TweenService:Create(TpBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            end)

            TpBtn.MouseButton1Click:Connect(callback)
        end

        -- Atualização dinâmica da lista de jogadores
        local function UpdateTeleportList()
            for _, child in pairs(targetSectionBox:GetChildren()) do 
                if child.Name == "PlayerCard" then 
                    child:Destroy() 
                end 
            end
            for _, player in pairs(Players:GetPlayers()) do 
                if player ~= LocalPlayer then 
                    CreateCustomPlayerCard(player, function()
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                            LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0) 
                            SendNotification("Teleported to " .. player.DisplayName, 2)
                        else
                            SendNotification("Character not loaded!", 2)
                        end
                    end)
                end 
            end
        end

        RefreshBtn.MouseButton1Click:Connect(function() 
            UpdateTeleportList() 
        end)

        UpdateTeleportList()
    end
end
