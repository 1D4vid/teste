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

    -- Paleta de Cores Local (para combinar perfeitamente com o tema)
    local Theme = {
        Accent = Color3.fromRGB(240, 240, 240),
        AccentDark = Color3.fromRGB(160, 160, 160),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(150, 150, 150),
        CardBg = Color3.fromRGB(14, 14, 14),
        ItemBg = Color3.fromRGB(22, 22, 22),
        Stroke = Color3.fromRGB(45, 45, 45),
        ButtonBg = Color3.fromRGB(30, 30, 30)
    }

    local function ApplyGradient(instance, color1, color2, rotation)
        local gradient = instance:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, color1), ColorSequenceKeypoint.new(1.00, color2)}
        gradient.Rotation = rotation or 45
        gradient.Parent = instance
        return gradient
    end

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
    -- DESIGN EXCLUSIVO: CARD UNIFICADO DE PLAYERS
    -- ==========================================
    Library:CreateSection(Page, "Players Teleport", "Right")
    local TargetCol = Library.CurrentSections[Page]

    if TargetCol then
        -- Container Unificado (O "Card Único")
        local UnifiedCard = Instance.new("Frame")
        UnifiedCard.Name = "PlayersTeleportContainer"
        UnifiedCard.Size = UDim2.new(1, 0, 0, 240)
        UnifiedCard.BackgroundColor3 = Theme.CardBg
        UnifiedCard.BorderSizePixel = 0
        UnifiedCard.Parent = TargetCol

        local CardCorner = Instance.new("UICorner", UnifiedCard)
        CardCorner.CornerRadius = UDim.new(0, 8)
        
        local CardStroke = Instance.new("UIStroke", UnifiedCard)
        CardStroke.Color = Theme.Stroke
        CardStroke.Thickness = 1

        -- Botão de Refresh Integrado ao Card
        local RefreshButton = Instance.new("TextButton")
        RefreshButton.Name = "RefreshBtn"
        RefreshButton.Size = UDim2.new(1, -16, 0, 32)
        RefreshButton.Position = UDim2.new(0, 8, 0, 8)
        RefreshButton.BackgroundColor3 = Theme.ButtonBg
        RefreshButton.Text = "Refresh List"
        RefreshButton.Font = Enum.Font.GothamBold
        RefreshButton.TextSize = 12
        RefreshButton.TextColor3 = Theme.Text
        RefreshButton.Parent = UnifiedCard

        Instance.new("UICorner", RefreshButton).CornerRadius = UDim.new(0, 6)
        local btnStroke = Instance.new("UIStroke", RefreshButton)
        btnStroke.Color = Theme.Stroke
        btnStroke.Thickness = 1
        
        -- Efeito Hover no botão de Refresh
        RefreshButton.MouseEnter:Connect(function()
            TweenService:Create(RefreshButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Theme.AccentDark}):Play()
        end)
        RefreshButton.MouseLeave:Connect(function()
            TweenService:Create(RefreshButton, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ButtonBg}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
        end)

        -- Lista Interna Rolável para os Players
        local ScrollList = Instance.new("ScrollingFrame")
        ScrollList.Name = "PlayerScrollList"
        ScrollList.Size = UDim2.new(1, -16, 1, -56)
        ScrollList.Position = UDim2.new(0, 8, 0, 48)
        ScrollList.BackgroundTransparency = 1
        ScrollList.BorderSizePixel = 0
        ScrollList.ScrollBarThickness = 3
        ScrollList.ScrollBarImageColor3 = Theme.Accent
        ScrollList.Parent = UnifiedCard

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Padding = UDim.new(0, 6)
        ListLayout.Parent = ScrollList

        -- Função interna para atualizar a lista
        local function BuildPlayerList()
            -- Limpar itens anteriores
            for _, child in ipairs(ScrollList:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end

            local players = Players:GetPlayers()
            local addedCount = 0

            for _, player in ipairs(players) do
                if player ~= LocalPlayer then
                    addedCount = addedCount + 1

                    local Row = Instance.new("Frame")
                    Row.Name = "PlayerRow_" .. player.Name
                    Row.Size = UDim2.new(1, -6, 0, 46)
                    Row.BackgroundColor3 = Theme.ItemBg
                    Row.BorderSizePixel = 0
                    Row.Parent = ScrollList

                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    local rowStroke = Instance.new("UIStroke", Row)
                    rowStroke.Color = Color3.fromRGB(35, 35, 35)
                    rowStroke.Thickness = 1

                    -- Thumbnail do Avatar
                    local Avatar = Instance.new("ImageLabel")
                    Avatar.Size = UDim2.new(0, 32, 0, 32)
                    Avatar.Position = UDim2.new(0, 8, 0.5, -16)
                    Avatar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
                    Avatar.BorderSizePixel = 0
                    Avatar.Image = "rbxassetid://0" -- Fallback vazio inicial
                    Avatar.Parent = Row
                    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 6)

                    task.spawn(function()
                        local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        if isReady then Avatar.Image = content end
                    end)

                    -- Área de Texto (Display Name & Username)
                    local LabelContainer = Instance.new("Frame")
                    LabelContainer.Size = UDim2.new(1, -135, 1, 0)
                    LabelContainer.Position = UDim2.new(0, 48, 0, 0)
                    LabelContainer.BackgroundTransparency = 1
                    LabelContainer.Parent = Row

                    local DisplayName = Instance.new("TextLabel")
                    DisplayName.Size = UDim2.new(1, 0, 0, 20)
                    DisplayName.Position = UDim2.new(0, 0, 0.5, -16)
                    DisplayName.BackgroundTransparency = 1
                    DisplayName.Text = player.DisplayName
                    DisplayName.Font = Enum.Font.GothamBold
                    DisplayName.TextSize = 12
                    DisplayName.TextColor3 = Theme.Text
                    DisplayName.TextXAlignment = Enum.TextXAlignment.Left
                    DisplayName.Parent = LabelContainer

                    local Username = Instance.new("TextLabel")
                    Username.Size = UDim2.new(1, 0, 0, 14)
                    Username.Position = UDim2.new(0, 0, 0.5, 2)
                    Username.BackgroundTransparency = 1
                    Username.Text = "@" .. player.Name
                    Username.Font = Enum.Font.Gotham
                    Username.TextSize = 10
                    Username.TextColor3 = Theme.TextDark
                    Username.TextXAlignment = Enum.TextXAlignment.Left
                    Username.Parent = LabelContainer

                    -- Botão Moderno de Teleporte
                    local TpBtn = Instance.new("TextButton")
                    TpBtn.Size = UDim2.new(0, 75, 0, 26)
                    TpBtn.Position = UDim2.new(1, -83, 0.5, -13)
                    TpBtn.BackgroundColor3 = Theme.Accent
                    TpBtn.Text = "Teleport"
                    TpBtn.Font = Enum.Font.GothamBold
                    TpBtn.TextSize = 11
                    TpBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
                    TpBtn.Parent = Row

                    Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0, 5)
                    local btnGrad = ApplyGradient(TpBtn, Theme.Accent, Theme.AccentDark, 90)

                    -- Efeito Hover no botão de Teleporte
                    TpBtn.MouseEnter:Connect(function()
                        TweenService:Create(TpBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    end)
                    TpBtn.MouseLeave:Connect(function()
                        TweenService:Create(TpBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
                    end)

                    TpBtn.MouseButton1Click:Connect(function()
                        local char = LocalPlayer.Character
                        local targetChar = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") and targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
                            SendNotification("Teleported to " .. player.DisplayName, 2)
                        else
                            SendNotification("Player character not loaded!", 2)
                        end
                    end)
                end
            end

            ScrollList.CanvasSize = UDim2.new(0, 0, 0, addedCount * 52)
        end

        RefreshButton.MouseButton1Click:Connect(function()
            BuildPlayerList()
            SendNotification("Player list updated!", 2)
        end)

        -- Carregar automaticamente na inicialização
        BuildPlayerList()
    end
end
