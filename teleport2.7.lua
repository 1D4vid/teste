return function(env)
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local ScreenGui = env.ScreenGui
    local SendNotification = env.SendNotification
    local UserInputService = env.UserInputService

    -- Ativa o design clássico ("OldStyle") nativo da library para esta aba
    Page:SetAttribute("OldStyle", true)

    -- Fallback seguro para o Theme caso não seja enviado no env
    local Theme = env.Theme or {
        ItemStroke = Color3.fromRGB(40, 40, 40),
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
    -- SEÇÃO: MAP OBJECTS
    -- ==========================================
    Library:CreateSection(Page, "Map Objects")

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
    -- SEÇÃO: EXTRAS
    -- ==========================================
    Library:CreateSection(Page, "Extras")

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
    -- SEÇÃO: PLAYERS TELEPORT
    -- ==========================================
    Library:CreateSection(Page, "Players Teleport")

    local RefreshBtn = Instance.new("TextButton")
    RefreshBtn.Name = "RefreshBtnStatic"
    RefreshBtn.Size = UDim2.new(1, -2, 0, 32)
    RefreshBtn.Position = UDim2.new(0, 1, 0, 0)
    RefreshBtn.BackgroundColor3 = Theme.ItemStroke
    RefreshBtn.Text = "Refresh List"
    RefreshBtn.TextColor3 = Theme.Accent
    RefreshBtn.Font = Theme.Font
    RefreshBtn.TextSize = 13
    RefreshBtn.Parent = Page
    Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)
    
    local refStroke = Instance.new("UIStroke", RefreshBtn)
    refStroke.Color = Color3.fromRGB(45, 45, 45)

    local Spacer = Instance.new("Frame")
    Spacer.Name = "SpacerStatic"
    Spacer.Size = UDim2.new(1, 0, 0, 5)
    Spacer.BackgroundTransparency = 1
    Spacer.Parent = Page

    local function UpdateTeleportList()
        -- Procura e destrói os cards antigos baseados no formato original
        for _, child in pairs(Page:GetChildren()) do 
            if child.Name == "PlayerCard" then 
                child:Destroy() 
            end 
        end
        
        -- Recria os cards nativos em estilo deitado (OldStyle)
        for _, player in pairs(Players:GetPlayers()) do 
            if player ~= LocalPlayer then 
                Library:CreatePlayerCard(Page, player, function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0) 
                        SendNotification("Teleported to " .. player.DisplayName, 2)
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
