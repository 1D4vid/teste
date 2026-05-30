return function(env)
    local Library = env.Library
    local TeleportPage = env.Page
    local Players = env.Players
    local Workspace = env.Workspace
    local LocalPlayer = env.LocalPlayer
    local Theme = env.Theme or {
        Accent = Color3.fromRGB(240, 240, 240),
        ItemStroke = Color3.fromRGB(60, 60, 60),
        Font = Enum.Font.GothamBold
    }
    local ScreenGui = env.ScreenGui
    local SendNotification = env.SendNotification
    local UserInputService = env.UserInputService or game:GetService("UserInputService")

    -- Lógica para buscar locais específicos no mapa atual
    local function teleportToLandmark(nameQuery)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local objName = string.lower(obj.Name)
                if string.find(objName, string.lower(nameQuery)) then
                    local targetCFrame = obj:IsA("Model") and obj:GetPivot() or obj.CFrame
                    char.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 4, 0)
                    SendNotification("Teleported to " .. nameQuery .. "!", 2)
                    return
                end
            end
        end
        SendNotification(nameQuery .. " not found on this map!", 2)
    end

    -- Lógica para detectar a besta da partida
    local function getBeastRoot()
        local BEAST_WEAPON_NAMES = {["Hammer"] = true, ["Gemstone Hammer"] = true, ["Iron Hammer"] = true, ["Mallet"] = true}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local backpack = p:FindFirstChild("Backpack")
                local character = p.Character
                local isBst = false
                for name in pairs(BEAST_WEAPON_NAMES) do
                    if backpack and backpack:FindFirstChild(name) then isBst = true break end
                    if character and character:FindFirstChild(name) then isBst = true break end
                end
                if p.Team and p.Team.Name == "Beast" then isBst = true end
                if isBst and character and character:FindFirstChild("HumanoidRootPart") then
                    return character.HumanoidRootPart
                end
            end
        end
        return nil
    end

    -- ==========================================
    -- COLUNA ESQUERDA: MAP OBJECTS (DESIGN ORIGINAL)
    -- ==========================================
    Library:CreateSection(TeleportPage, "Map Objects", "Left")
    
    local currentPCIndex = 0
    Library:CreateButton(TeleportPage, "Teleport Computer", function()
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

    local currentDoorIndex = 0
    Library:CreateButton(TeleportPage, "Teleport Exitdoor", function()
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

    local currentPodIndex = 0
    Library:CreateButton(TeleportPage, "Teleport Freezepods", function()
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

    Library:CreateButton(TeleportPage, "TP Crystal Cove", function()
        teleportToLandmark("Crystal Cove")
    end)

    Library:CreateButton(TeleportPage, "TP Beast Cave", function()
        teleportToLandmark("Beast Cave")
    end)

    Library:CreateButton(TeleportPage, "Tp Map", function()
        -- Implementação futura
    end)

    -- ==========================================
    -- COLUNA DIREITA: EXTRAS (DESIGN ORIGINAL)
    -- ==========================================
    Library:CreateSection(TeleportPage, "Extras", "Right")

    local savedCFrame = nil
    local checkpointMarker = nil
    local tpKeybindConn = nil

    local CheckpointFrame = ScreenGui:FindFirstChild("CheckpointFrame")
    if CheckpointFrame then CheckpointFrame:Destroy() end

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

    SetBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            savedCFrame = char.HumanoidRootPart.CFrame
            if checkpointMarker then checkpointMarker:Destroy() end
            checkpointMarker = Instance.new("Part")
            checkpointMarker.Name = "FleeCheckpointMarker"
            checkpointMarker.Shape = Enum.PartType.Cylinder
            checkpointMarker.Size = Vector3.new(0.2, 4, 4)
            checkpointMarker.CFrame = savedCFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.rad(90))
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

            SetBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)
            task.delay(0.15, function() SetBtn.ImageColor3 = Color3.fromRGB(255, 255, 255) end)
            SendNotification("Checkpoint Set!", 2)
        end
    end)

    TpBtn.MouseButton1Click:Connect(function()
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
    end)

    Library:CreateToggle(TeleportPage, "Checkpoint (UI+R)", false, function(state)
        CheckpointFrame.Visible = state 
        if state then
            if not tpKeybindConn then
                tpKeybindConn = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.KeyCode == Enum.KeyCode.R and savedCFrame then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = savedCFrame
                        end
                    end
                end)
            end
        else
            if tpKeybindConn then tpKeybindConn:Disconnect() tpKeybindConn = nil end
            if checkpointMarker then checkpointMarker:Destroy() checkpointMarker = nil end
            savedCFrame = nil
        end
    end)

    Library:CreateButton(TeleportPage, "Reset Character", function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end)

    Library:CreateButton(TeleportPage, "Server Rejoin", function()
        local TeleportService = game:GetService("TeleportService")
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)

    Library:CreateButton(TeleportPage, "Random Servers", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)

    Library:CreateButton(TeleportPage, "Teleport to Beast", function()
        local beastRoot = getBeastRoot()
        if beastRoot then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = beastRoot.CFrame + Vector3.new(0, 3, 0)
                SendNotification("Teleported to Beast!", 2)
            end
        else
            SendNotification("Beast not found or not spawned!", 2)
        end
    end)

    -- ==========================================
    -- SEÇÃO EXCLUSIVA: PLAYERS TELEPORT (SISTEMA SEPARADO)
    -- ==========================================
    Library:CreateSection(TeleportPage, "Players Teleport", "Right")
    
    -- Captura a caixa de seção (SectionBox) recém-criada para abrigar nossos elementos customizados
    local playersBox = Library.CurrentSections[TeleportPage]

    -- Botão "Refresh" Customizado (Desenhado manualmente dentro do contêiner)
    local RefreshBtn = Instance.new("TextButton")
    RefreshBtn.Name = "RefreshBtnStatic"
    RefreshBtn.Size = UDim2.new(1, 0, 0, 26)
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    RefreshBtn.BackgroundTransparency = 0.2
    RefreshBtn.Text = "Refresh"
    RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshBtn.Font = Enum.Font.GothamBold
    RefreshBtn.TextSize = 10
    RefreshBtn.Parent = playersBox
    Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 4)
    local rStr = Instance.new("UIStroke", RefreshBtn)
    rStr.Color = Color3.fromRGB(50, 50, 50)
    rStr.Thickness = 1

    -- Renderização dos Cards do jogador de forma independente do Hub Principal
    local function CreateCustomPlayerCard(parent, player)
        local Card = Instance.new("Frame")
        Card.Name = "PlayerCard"
        Card.Size = UDim2.new(1, 0, 0, 50)
        Card.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Card.BackgroundTransparency = 0.55
        Card.BorderSizePixel = 0
        Card.Parent = parent

        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        
        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(45, 45, 45)
        Stroke.Thickness = 1
        Stroke.Parent = Card

        -- Avatar Redondo
        local Avatar = Instance.new("ImageLabel")
        Avatar.Size = UDim2.new(0, 32, 0, 32)
        Avatar.Position = UDim2.new(0, 6, 0.5, -16)
        Avatar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        Avatar.BackgroundTransparency = 0.3
        Avatar.Parent = Card
        Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 6)

        task.spawn(function()
            local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            if isReady then Avatar.Image = content end
        end)

        -- Nome de Exibição
        local Display = Instance.new("TextLabel")
        Display.Text = player.DisplayName
        Display.Size = UDim2.new(1, -115, 0, 15)
        Display.Position = UDim2.new(0, 44, 0, 6)
        Display.BackgroundTransparency = 1
        Display.Font = Enum.Font.GothamBold
        Display.TextSize = 11
        Display.TextColor3 = Color3.fromRGB(255, 255, 255)
        Display.TextXAlignment = Enum.TextXAlignment.Left
        Display.Parent = Card

        -- @NomeDeUsuario
        local User = Instance.new("TextLabel")
        User.Text = "@" .. player.Name
        User.Size = UDim2.new(1, -115, 0, 13)
        User.Position = UDim2.new(0, 44, 0, 22)
        User.BackgroundTransparency = 1
        User.Font = Enum.Font.Gotham
        User.TextSize = 9
        User.TextColor3 = Color3.fromRGB(150, 150, 150)
        User.TextXAlignment = Enum.TextXAlignment.Left
        User.Parent = Card

        -- Botão de Teleporte Estilizado
        local TpBtn = Instance.new("TextButton")
        TpBtn.Size = UDim2.new(0, 55, 0, 24)
        TpBtn.Position = UDim2.new(1, -61, 0.5, -12)
        TpBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        TpBtn.Text = "Teleport"
        TpBtn.Font = Enum.Font.GothamBold
        TpBtn.TextSize = 9
        TpBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
        TpBtn.Parent = Card

        Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0, 4)

        -- Gradiente do Botão
        local btnGrad = Instance.new("UIGradient")
        btnGrad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 240, 240)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160))
        }
        btnGrad.Rotation = 90
        btnGrad.Parent = TpBtn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(80, 80, 80)
        btnStroke.Thickness = 1
        btnStroke.Parent = TpBtn

        TpBtn.MouseButton1Click:Connect(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
            end
        end)
    end

    -- Atualização dinâmica dos cards dentro da categoria
    local function UpdateTeleportList()
        for _, child in pairs(playersBox:GetChildren()) do 
            if child.Name == "PlayerCard" then 
                child:Destroy() 
            end 
        end
        for _, player in pairs(Players:GetPlayers()) do 
            if player ~= LocalPlayer then 
                CreateCustomPlayerCard(playersBox, player)
            end 
        end
    end

    RefreshBtn.MouseButton1Click:Connect(function() 
        UpdateTeleportList() 
    end)

    UpdateTeleportList()
end
