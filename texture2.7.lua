return function(env)
    -- Importando as variáveis do script principal
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local RunService = env.RunService
    local TweenService = env.TweenService
    local UserInputService = env.UserInputService
    local Theme = env.Theme
    local UserConfigs = env.UserConfigs
    local GetParentTarget = env.GetParentTarget
    local MobileCrosshair = env.MobileCrosshair
    local PCSoftwareCursor = env.PCSoftwareCursor
    local SetPCCursorActive = env.SetPCCursorActive
    local UpdateCursorSizes = env.UpdateCursorSizes

    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    local formatID = function(id)
        if type(id) == "number" and id > 0 then return "rbxassetid://" .. id
        elseif type(id) == "string" and id ~= "" and id ~= "0" then
            if not id:find("rbxassetid://") then return "rbxassetid://" .. id else return id end
        end
        return nil
    end

    Library:CreateSection(Page, "Map Textures")

    -- [ WHITE BRICKS ]
    local wbEnabled = false
    local wbDescConn
    local wbBkp = setmetatable({}, {__mode = "k"})
    
    local function applyWhiteBrick(part)
        if not wbEnabled then return end
        if not part:IsA("BasePart") or part:IsA("Terrain") then return end
        
        local parentModel = part:FindFirstAncestorOfClass("Model")
        if parentModel and parentModel:FindFirstChildOfClass("Humanoid") then return end

        if not wbBkp[part] then 
            wbBkp[part] = {M = part.Material, C = part.Color} 
        end
        
        pcall(function()
            part.Material = Enum.Material.Brick
            part.Color = Color3.fromRGB(255, 255, 255)
        end)
    end

    Library:CreateToggle(Page, "White Bricks", false, function(state)
        wbEnabled = state
        if state then
            task.spawn(function()
                local desc = Workspace:GetDescendants()
                local t = os.clock()
                for i = 1, #desc do
                    if not wbEnabled then break end
                    applyWhiteBrick(desc[i])
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
            wbDescConn = Workspace.DescendantAdded:Connect(function(child)
                if wbEnabled then task.defer(function() applyWhiteBrick(child) end) end
            end)
        else
            if wbDescConn then wbDescConn:Disconnect() wbDescConn = nil end
            local currentBkp = wbBkp
            wbBkp = setmetatable({}, {__mode = "k"})
            local toRevert = {}
            for p, d in pairs(currentBkp) do table.insert(toRevert, {part = p, mat = d.M, col = d.C}) end
            task.spawn(function()
                local t = os.clock()
                for i = 1, #toRevert do
                    local item = toRevert[i]
                    local p = item.part
                    if p and p.Parent then
                        pcall(function() p.Material = item.mat; p.Color = item.col end)
                    end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
        end
    end)

    -- [ SNOW TEXTURES ]
    local snowEnabled = false
    local snowDescConn
    local snowBkp = setmetatable({}, {__mode = "k"})
    local IgnoreNames = { ComputerTable = true, ExitDoor = true }
    
    local function applySnowTexture(part)
        if not snowEnabled then return end
        if not part:IsA("BasePart") or part:IsA("Terrain") then return end
        if not part.Anchored or IgnoreNames[part.Name] then return end

        if not snowBkp[part] then snowBkp[part] = {M = part.Material, C = part.Color} end
        
        pcall(function()
            part.Material = Enum.Material.Snow
            part.Color = Color3.fromRGB(255, 255, 255)
        end)
    end

    Library:CreateToggle(Page, "Snow Textures", false, function(state)
        snowEnabled = state
        if state then
            task.spawn(function()
                local desc = Workspace:GetDescendants()
                local t = os.clock()
                for i = 1, #desc do
                    if not snowEnabled then break end
                    applySnowTexture(desc[i])
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
            snowDescConn = Workspace.DescendantAdded:Connect(function(child)
                if snowEnabled then task.defer(function() applySnowTexture(child) end) end
            end)
        else
            if snowDescConn then snowDescConn:Disconnect() snowDescConn = nil end
            local currentBkp = snowBkp
            snowBkp = setmetatable({}, {__mode = "k"})
            local toRevert = {}
            for p, d in pairs(currentBkp) do table.insert(toRevert, {part = p, mat = d.M, col = d.C}) end
            task.spawn(function()
                local t = os.clock()
                for i = 1, #toRevert do
                    local item = toRevert[i]
                    local p = item.part
                    if p and p.Parent then
                        pcall(function() p.Material = item.mat; p.Color = item.col end)
                    end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Remove Textures", false, function(state) 
        if not getgenv().NexOptimization then
            getgenv().NexOptimization = loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/fps%20booster%20e%20remove%20textures.lua"))()
        end
        getgenv().NexOptimization.ToggleTextures(state)
    end)
    
    Library:CreateToggle(Page, "FpsBooster", false, function(state) 
        if not getgenv().NexOptimization then
            getgenv().NexOptimization = loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/fps%20booster%20e%20remove%20textures.lua"))()
        end
        getgenv().NexOptimization.ToggleFPSBooster(state)
    end)

    -- [ ULTRA HD GRAPHICS ]
    local ultraHDConns = {}
    local createdMaterials = {}
    Library:CreateToggle(Page, "Ultra HD Graphics", false, function(state) 
        local MaterialService = game:GetService("MaterialService")
        local StarterGui = game:GetService("StarterGui")
        local Cam = Workspace.CurrentCamera
        
        if state then
            local function createMaterial(name, baseMaterial, colorMap, normalMap, roughnessMap)
                local Mat = Instance.new("MaterialVariant")
                Mat.Name = name .. "_TextureOnly"
                Mat.BaseMaterial = baseMaterial
                Mat.ColorMap = colorMap
                Mat.NormalMap = normalMap
                Mat.RoughnessMap = roughnessMap
                Mat.Parent = MaterialService
                pcall(function() MaterialService:SetBaseMaterialOverride(baseMaterial, Mat) end)
                table.insert(createdMaterials, {Variant = Mat, Base = baseMaterial})
            end
            createMaterial("Concrete", Enum.Material.Concrete, "rbxassetid://6223521473", "rbxassetid://6223521257", "rbxassetid://6223521360")
            createMaterial("Brick", Enum.Material.Brick, "rbxassetid://6396996328", "rbxassetid://6396996024", "rbxassetid://6396996160")
            createMaterial("Wood", Enum.Material.Wood, "rbxassetid://924320031", "rbxassetid://924320256", "rbxassetid://924305001")
            createMaterial("WoodPlanks", Enum.Material.WoodPlanks, "rbxassetid://924320031", "rbxassetid://924320256", "rbxassetid://924305001")
            pcall(function() MaterialService.Use2022Materials = true end)

            local spectateIndex = 1
            local allPlayers = {}
            local function updatePlayerList()
                allPlayers = {}
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
                        table.insert(allPlayers, plr)
                    end
                end
            end
            local function spectatePlayer(direction)
                updatePlayerList()
                if #allPlayers == 0 then return end
                spectateIndex = spectateIndex + direction
                if spectateIndex > #allPlayers then spectateIndex = 1 end
                if spectateIndex < 1 then spectateIndex = #allPlayers end
                local target = allPlayers[spectateIndex]
                if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                    Cam.CameraType = Enum.CameraType.Custom
                    Cam.CameraSubject = target.Character.Humanoid
                    pcall(function() StarterGui:SetCore("SendNotification", {Title = "Spectating", Text = target.Name, Duration = 1}) end)
                end
            end
            local function stopSpectating()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Cam.CameraType = Enum.CameraType.Custom
                    Cam.CameraSubject = LocalPlayer.Character.Humanoid
                    pcall(function() StarterGui:SetCore("SendNotification", {Title = "Reset", Text = "Camera no Jogador", Duration = 2}) end)
                end
            end
            table.insert(ultraHDConns, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.Right then spectatePlayer(1)
                elseif input.KeyCode == Enum.KeyCode.Left then spectatePlayer(-1)
                elseif input.KeyCode == Enum.KeyCode.Backspace then stopSpectating() end
            end))
        else
            for _, m in ipairs(createdMaterials) do
                pcall(function() MaterialService:SetBaseMaterialOverride(m.Base, "") end)
                if m.Variant then m.Variant:Destroy() end
            end
            table.clear(createdMaterials)
            pcall(function() MaterialService.Use2022Materials = false end)
            for _, c in ipairs(ultraHDConns) do c:Disconnect() end
            table.clear(ultraHDConns)
            if Cam.CameraSubject and Cam.CameraSubject:IsA("Humanoid") and Cam.CameraSubject.Parent ~= LocalPlayer.Character then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Cam.CameraType = Enum.CameraType.Custom
                    Cam.CameraSubject = LocalPlayer.Character.Humanoid
                end
            end
        end
    end)

    -- [ MINECRAFT TEXTURE ]
    local mcOriginalMaterials = setmetatable({}, {__mode = "k"})
    local mcDescendantConn
    local mcLoopConn
    local mcFila = {}
    local mcEnabled = false
    local mcFaces = {"Front", "Back", "Bottom", "Top", "Right", "Left"}
    local mcMaterials = {
        Wood = "3258599312", WoodPlanks = "8676581022", Brick = "8558400252", Cobblestone = "5003953441",
        Concrete = "7341687607", DiamondPlate = "6849247561", Fabric = "118776397", Granite = "4722586771",
        Grass = "4722588177", Ice = "3823766459", Marble = "62967586", Metal = "62967586", Sand = "152572215"
    }

    local function processMCPart(part)
        if not mcEnabled then return end
        if part:IsA("BasePart") and part.Transparency < 1 then
            if part:FindFirstChild("McTexture_Front") then return end
            local textureId = mcMaterials[part.Material.Name]
            if textureId then
                mcOriginalMaterials[part] = part.Material
                for _, face in ipairs(mcFaces) do
                    local newTex = Instance.new("Texture")
                    newTex.Name = "McTexture_" .. face
                    newTex.ZIndex = 2147483647
                    newTex.Texture = "rbxassetid://" .. textureId
                    newTex.Face = Enum.NormalId[face]
                    newTex.StudsPerTileU = 4
                    newTex.StudsPerTileV = 4
                    newTex.Color3 = part.Color
                    newTex.Transparency = part.Transparency
                    newTex.Parent = part
                end
                part.Material = Enum.Material.SmoothPlastic
            end
        end
    end

    Library:CreateToggle(Page, "Minecraft Texture", false, function(state)
        mcEnabled = state
        if state then
            task.spawn(function()
                local desc = Workspace:GetDescendants()
                local t = os.clock()
                for i = 1, #desc do
                    if not mcEnabled then break end
                    processMCPart(desc[i])
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
            mcDescendantConn = Workspace.DescendantAdded:Connect(function(newObj)
                if mcEnabled then table.insert(mcFila, newObj) end
            end)
            mcLoopConn = RunService.Heartbeat:Connect(function()
                if not mcEnabled then return end
                local t = os.clock()
                while #mcFila > 0 do
                    if os.clock() - t > 0.005 then break end 
                    local obj = table.remove(mcFila) 
                    processMCPart(obj)
                end
            end)
        else
            if mcDescendantConn then mcDescendantConn:Disconnect() end
            if mcLoopConn then mcLoopConn:Disconnect() end
            table.clear(mcFila)
            
            local currentBkp = mcOriginalMaterials
            mcOriginalMaterials = setmetatable({}, {__mode = "k"})
            local toRevert = {}
            for part, origMat in pairs(currentBkp) do table.insert(toRevert, {part = part, mat = origMat}) end
            
            task.spawn(function()
                local t = os.clock()
                for i = 1, #toRevert do
                    local p = toRevert[i].part
                    if p and p.Parent then
                        pcall(function()
                            for _, face in ipairs(mcFaces) do
                                local tex = p:FindFirstChild("McTexture_" .. face)
                                if tex then tex:Destroy() end
                            end
                            p.Material = toRevert[i].mat
                        end)
                    end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
        end
    end)

    -- [ DOUBLE JUMP EFFECTS ]
    local currentDoubleJumpConns = {}
    local originalTextures = setmetatable({}, {__mode = "k"})
    local OriginalSparkleColors = setmetatable({}, {__mode = "k"})
    
    local function EnableDoubleJumpEffect(texturaID)
        UserConfigs["TexturesPage_DoubleJump"] = texturaID
        for _, c in ipairs(currentDoubleJumpConns) do c:Disconnect() end
        table.clear(currentDoubleJumpConns)
        
        local function aplicarTextura(obj)
            if texturaID == "Default" then
                obj:SetAttribute("CurrentTexture", nil)
                if obj.ClassName == "ParticleEmitter" then
                    if originalTextures[obj] then obj.Texture = originalTextures[obj] end
                elseif obj.ClassName == "Sparkles" then
                    local oldClone = obj.Parent:FindFirstChild("CustomSparkleClone_" .. obj.Name)
                    if oldClone then oldClone:Destroy() end
                    if OriginalSparkleColors[obj] then pcall(function() obj.SparkleColor = OriginalSparkleColors[obj] end)
                    else pcall(function() obj.SparkleColor = Color3.new(1, 1, 1) end) end
                end
                return
            end

            if obj:GetAttribute("CurrentTexture") == texturaID then return end
            obj:SetAttribute("CurrentTexture", texturaID)
            
            local classe = obj.ClassName
            if classe == "ParticleEmitter" then
                local sucesso, texturaAtual = pcall(function() return obj.Texture end)
                if sucesso and texturaAtual and string.find(string.lower(texturaAtual), "sparkles_main") then
                    if not originalTextures[obj] then originalTextures[obj] = obj.Texture end
                    obj.Texture = texturaID
                end
            elseif classe == "Sparkles" then
                if not OriginalSparkleColors[obj] then OriginalSparkleColors[obj] = obj.SparkleColor end
                pcall(function() obj.SparkleColor = Color3.new(0, 0, 0) end)
                
                local oldClone = obj.Parent:FindFirstChild("CustomSparkleClone_" .. obj.Name)
                if oldClone then oldClone:Destroy() end
                
                local clone = Instance.new("ParticleEmitter")
                clone.Name = "CustomSparkleClone_" .. obj.Name
                clone.Texture = texturaID
                clone.Rate = 20
                clone.Speed = NumberRange.new(2, 4)
                clone.Lifetime = NumberRange.new(1.5, 2)
                clone.Rotation = NumberRange.new(0, 360)
                clone.RotSpeed = NumberRange.new(-50, 50)
                clone.LightEmission = 0.8
                clone.ZOffset = 1
                clone.Brightness = 2
                clone.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0)})
                clone.Parent = obj.Parent
                clone.Enabled = obj.Enabled
                
                local conexao = obj:GetPropertyChangedSignal("Enabled"):Connect(function() 
                    if clone then clone.Enabled = obj.Enabled end
                end)
                local destConn = obj.Destroying:Connect(function()
                    if conexao then conexao:Disconnect() end
                    if clone then clone:Destroy() end
                end)
                
                table.insert(currentDoubleJumpConns, conexao)
                table.insert(currentDoubleJumpConns, destConn)
            end
        end

        task.spawn(function()
            local pastasSeguras = {Workspace, game:GetService("ReplicatedStorage"), Players}
            local t = os.clock()
            for _, pasta in ipairs(pastasSeguras) do
                local desc = pasta:GetDescendants()
                for i = 1, #desc do
                    local obj = desc[i]
                    if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then aplicarTextura(obj) end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
                if texturaID ~= "Default" then
                    table.insert(currentDoubleJumpConns, pasta.DescendantAdded:Connect(function(obj)
                        if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then task.defer(function() aplicarTextura(obj) end) end
                    end))
                end
            end
        end)
    end

    Library:CreateSection(Page, "Double Jump Effects")
    local targetParentDJ = GetParentTarget(Page)

    local CustomInputContainer = Instance.new("Frame")
    CustomInputContainer.Size = UDim2.new(1, 0, 0, 30)
    CustomInputContainer.BackgroundTransparency = 1
    CustomInputContainer.Parent = targetParentDJ

    local CustomInputBox = Instance.new("TextBox")
    CustomInputBox.Size = UDim2.new(1, -75, 1, 0)
    CustomInputBox.Position = UDim2.new(0, 5, 0, 0)
    CustomInputBox.BackgroundTransparency = 1
    CustomInputBox.Text = ""
    local savedDJ = UserConfigs["TexturesPage_DoubleJump"]
    if savedDJ and savedDJ ~= "Default" then CustomInputBox.Text = savedDJ:gsub("rbxassetid://", "") end
    CustomInputBox.PlaceholderText = "Enter Texture ID..."
    CustomInputBox.TextColor3 = Theme.Text
    CustomInputBox.PlaceholderColor3 = Theme.TextDark
    CustomInputBox.Font = Theme.Font
    CustomInputBox.TextSize = 11
    CustomInputBox.TextXAlignment = Enum.TextXAlignment.Left
    CustomInputBox.ClearTextOnFocus = false
    CustomInputBox.Parent = CustomInputContainer

    local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Size = UDim2.new(0, 60, 0, 22)
    ApplyBtn.Position = UDim2.new(1, -65, 0.5, -11)
    ApplyBtn.BackgroundColor3 = Theme.Accent
    ApplyBtn.Text = "Apply"
    ApplyBtn.Font = Enum.Font.GothamBold
    ApplyBtn.TextSize = 10
    ApplyBtn.TextColor3 = Color3.new(0,0,0)
    ApplyBtn.Parent = CustomInputContainer
    Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)

    ApplyBtn.MouseButton1Click:Connect(function()
        local val = CustomInputBox.Text
        if val and val ~= "" then
            local formatted = formatID(val)
            if formatted then
                UserConfigs["TexturesPage_DoubleJump"] = formatted
                EnableDoubleJumpEffect(formatted)
            end
        end
    end)

    local GridWrapper = Instance.new("Frame")
    GridWrapper.Size = UDim2.new(1, 0, 0, 0)
    GridWrapper.AutomaticSize = Enum.AutomaticSize.Y
    GridWrapper.BackgroundTransparency = 1
    GridWrapper.Parent = targetParentDJ
    
    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0, 36, 0, 36)
    Grid.CellPadding = UDim2.new(0, 8, 0, 8)
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Grid.Parent = GridWrapper
    
    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingTop = UDim.new(0, 5)
    UIPadding.PaddingBottom = UDim.new(0, 5)
    UIPadding.Parent = GridWrapper

    local defaultBtn = Instance.new("TextButton")
    defaultBtn.Text = "Default"
    defaultBtn.Font = Enum.Font.GothamBold
    defaultBtn.TextSize = 9
    defaultBtn.TextColor3 = Theme.TextDark
    defaultBtn.BackgroundColor3 = Color3.new(0,0,0)
    defaultBtn.BackgroundTransparency = 0.45
    defaultBtn.Parent = GridWrapper
    Instance.new("UICorner", defaultBtn).CornerRadius = UDim.new(0, 4)
    local dbStr = Instance.new("UIStroke", defaultBtn)
    dbStr.Color = Color3.fromRGB(40,40,40)
    
    defaultBtn.MouseEnter:Connect(function() TweenService:Create(dbStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.Accent}):Play() end)
    defaultBtn.MouseLeave:Connect(function() TweenService:Create(dbStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.TextDark}):Play() end)
    defaultBtn.MouseButton1Click:Connect(function() UserConfigs["TexturesPage_DoubleJump"] = "Default" EnableDoubleJumpEffect("Default") end)

    local effectIDs = {
        "81110491136307", "117864251880006", "120181545812734", "74056211768119", 
        "116419901031627", "92247449256845", "113423466689563", "90279999098357", 
        "94123299347751", "105065705443269", "122902019815288", "138617722401997", 
        "75192344666220", "139646605021296", "133105930199997", "96482830256985", 
        "107964624563909", "122185636007520", "130200330618832", "84159990264787",
        "87265760472097", "125925535971201", "99196076742919", "80555494674270", 
        "77364460442867", "84014330993791", "80081088131892", "70463296258416",
        "84683340454265", "110707827597886", "94615398600162", "136555497393349", 
        "115660311620643", "87528090276578", "91090339346537", "104273334466284", 
        "125877054664162", "99696281853254", "115091366896134", "118044368508403"
    }

    for _, id in ipairs(effectIDs) do
        local btn = Instance.new("ImageButton")
        btn.BackgroundColor3 = Color3.new(0,0,0)
        btn.BackgroundTransparency = 0.45
        btn.Image = "rbxassetid://" .. id
        btn.ScaleType = Enum.ScaleType.Crop 
        btn.Parent = GridWrapper
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local ebStr = Instance.new("UIStroke", btn)
        ebStr.Color = Color3.fromRGB(40,40,40)

        btn.MouseEnter:Connect(function() TweenService:Create(ebStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(ebStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() end)
        btn.MouseButton1Click:Connect(function() 
            UserConfigs["TexturesPage_DoubleJump"] = "rbxassetid://" .. id
            EnableDoubleJumpEffect("rbxassetid://" .. id)
        end)
    end

    -- [ MOBILE JUMP BUTTON ]
    if isMobile then
        Library:CreateSection(Page, "Mobile Button Jump")
        local targetParentMJ = GetParentTarget(Page)

        local mobileJumpConns = {}
        local function EnableMobileButtonJump(texturaID)
            UserConfigs["TexturesPage_MobileJump"] = texturaID
            if not isMobile then return end
            
            for _, c in ipairs(mobileJumpConns) do c:Disconnect() end
            table.clear(mobileJumpConns)

            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local function applyCustomButton(touchGui)
                local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame") or touchGui:WaitForChild("TouchControlFrame", 2)
                if not touchControlFrame then return end
                local jumpButton = touchControlFrame:FindFirstChild("JumpButton") or touchControlFrame:WaitForChild("JumpButton", 2)
                if not jumpButton then return end

                if texturaID == "Default" then
                    jumpButton.ImageTransparency = 0
                    local existingIcon = jumpButton:FindFirstChild("CustomJumpIcon")
                    if existingIcon then existingIcon:Destroy() end
                    return
                end
                
                jumpButton.ImageTransparency = 1 
                local existingIcon = jumpButton:FindFirstChild("CustomJumpIcon")
                if existingIcon then existingIcon:Destroy() end
                
                local customIcon = Instance.new("ImageLabel")
                customIcon.Name = "CustomJumpIcon"
                customIcon.Size = UDim2.new(1, 0, 1, 0)
                customIcon.Position = UDim2.new(0, 0, 0, 0)
                customIcon.BackgroundTransparency = 1
                customIcon.Image = texturaID
                customIcon.ZIndex = jumpButton.ZIndex + 50
                customIcon.Parent = jumpButton
                
                local c1 = jumpButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        customIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
                    end
                end)
                local c2 = jumpButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        customIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end)
                table.insert(mobileJumpConns, c1)
                table.insert(mobileJumpConns, c2)
            end

            if playerGui:FindFirstChild("TouchGui") then task.spawn(applyCustomButton, playerGui.TouchGui) end
            if texturaID ~= "Default" then
                table.insert(mobileJumpConns, playerGui.ChildAdded:Connect(function(child)
                    if child.Name == "TouchGui" then task.spawn(applyCustomButton, child) end
                end))
            end
        end

        local MJInputContainer = Instance.new("Frame")
        MJInputContainer.Size = UDim2.new(1, 0, 0, 30)
        MJInputContainer.BackgroundTransparency = 1
        MJInputContainer.Parent = targetParentMJ

        local MJumpTextBox = Instance.new("TextBox")
        MJumpTextBox.Size = UDim2.new(1, -75, 1, 0)
        MJumpTextBox.Position = UDim2.new(0, 5, 0, 0)
        MJumpTextBox.BackgroundTransparency = 1
        MJumpTextBox.Text = ""
        local savedMJ = UserConfigs["TexturesPage_MobileJump"]
        if savedMJ and savedMJ ~= "Default" then MJumpTextBox.Text = savedMJ:gsub("rbxassetid://", "") end
        MJumpTextBox.PlaceholderText = "Enter Texture ID..."
        MJumpTextBox.TextColor3 = Theme.Text
        MJumpTextBox.PlaceholderColor3 = Theme.TextDark
        MJumpTextBox.Font = Theme.Font
        MJumpTextBox.TextSize = 11
        MJumpTextBox.TextXAlignment = Enum.TextXAlignment.Left
        MJumpTextBox.ClearTextOnFocus = false
        MJumpTextBox.Parent = MJInputContainer

        local MJumpApplyBtn = Instance.new("TextButton")
        MJumpApplyBtn.Size = UDim2.new(0, 60, 0, 22)
        MJumpApplyBtn.Position = UDim2.new(1, -65, 0.5, -11)
        MJumpApplyBtn.BackgroundColor3 = Theme.Accent
        MJumpApplyBtn.Text = "Apply"
        MJumpApplyBtn.Font = Enum.Font.GothamBold
        MJumpApplyBtn.TextSize = 10
        MJumpApplyBtn.TextColor3 = Color3.new(0,0,0)
        MJumpApplyBtn.Parent = MJInputContainer
        Instance.new("UICorner", MJumpApplyBtn).CornerRadius = UDim.new(0, 4)

        MJumpApplyBtn.MouseButton1Click:Connect(function()
            local val = MJumpTextBox.Text
            if val and val ~= "" then
                local formatted = formatID(val)
                if formatted then
                    UserConfigs["TexturesPage_MobileJump"] = formatted
                    EnableMobileButtonJump(formatted)
                end
            end
        end)

        local MJGridWrapper = Instance.new("Frame")
        MJGridWrapper.Size = UDim2.new(1, 0, 0, 0)
        MJGridWrapper.AutomaticSize = Enum.AutomaticSize.Y
        MJGridWrapper.BackgroundTransparency = 1
        MJGridWrapper.Parent = targetParentMJ
        
        local MJumpGrid = Instance.new("UIGridLayout")
        MJumpGrid.CellSize = UDim2.new(0, 36, 0, 36)
        MJumpGrid.CellPadding = UDim2.new(0, 8, 0, 8)
        MJumpGrid.SortOrder = Enum.SortOrder.LayoutOrder
        MJumpGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        MJumpGrid.Parent = MJGridWrapper
        
        local MJumpPadding = Instance.new("UIPadding")
        MJumpPadding.PaddingTop = UDim.new(0, 5)
        MJumpPadding.PaddingBottom = UDim.new(0, 5)
        MJumpPadding.Parent = MJGridWrapper

        local mDefaultBtn = Instance.new("TextButton")
        mDefaultBtn.Text = "Default"
        mDefaultBtn.Font = Enum.Font.GothamBold
        mDefaultBtn.TextSize = 9
        mDefaultBtn.TextColor3 = Theme.TextDark
        mDefaultBtn.BackgroundColor3 = Color3.new(0,0,0)
        mDefaultBtn.BackgroundTransparency = 0.45
        mDefaultBtn.Parent = MJGridWrapper
        Instance.new("UICorner", mDefaultBtn).CornerRadius = UDim.new(0, 4)
        local mDStr = Instance.new("UIStroke", mDefaultBtn)
        mDStr.Color = Color3.fromRGB(40,40,40)
        
        mDefaultBtn.MouseEnter:Connect(function() TweenService:Create(mDStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() TweenService:Create(mDefaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.Accent}):Play() end)
        mDefaultBtn.MouseLeave:Connect(function() TweenService:Create(mDStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() TweenService:Create(mDefaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.TextDark}):Play() end)
        mDefaultBtn.MouseButton1Click:Connect(function() UserConfigs["TexturesPage_MobileJump"] = "Default" EnableMobileButtonJump("Default") end)

        local mJumpIDs = {
            "126321670529682", "77430663366893", "115979689020396", "101678026501268", 
            "100604012502918", "107988778180975", "106355869384286", "119823685069603"
        }

        for _, id in ipairs(mJumpIDs) do
            local btn = Instance.new("ImageButton")
            btn.BackgroundColor3 = Color3.new(0,0,0)
            btn.BackgroundTransparency = 0.45
            btn.Image = "rbxassetid://" .. id
            btn.ScaleType = Enum.ScaleType.Crop 
            btn.Parent = MJGridWrapper
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            local str = Instance.new("UIStroke", btn)
            str.Color = Color3.fromRGB(40,40,40)
            
            btn.MouseEnter:Connect(function() TweenService:Create(str, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() end)
            btn.MouseLeave:Connect(function() TweenService:Create(str, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() end)
            btn.MouseButton1Click:Connect(function() 
                UserConfigs["TexturesPage_MobileJump"] = "rbxassetid://" .. id
                EnableMobileButtonJump("rbxassetid://" .. id)
            end)
        end
    end

    -- [ CROSSHAIR SETTINGS ]
    Library:CreateSection(Page, "Crosshair Settings")
    Library:CreateSlider(Page, "Cursor Size", 10, 100, 24, UpdateCursorSizes)
    
    local CursorList = {
        {Name = "Default", ID = "RESET"},
        {Name = "Use Cursor", ID = "15368174199"}, {Name = "Use Cursor", ID = "12701650945"},
        {Name = "Use Cursor", ID = "128514706094926"}, {Name = "Use Cursor", ID = "119350232226515"},
        {Name = "Use Cursor", ID = "5060823578"}, {Name = "Use Cursor", ID = "9896571799"},
        {Name = "Use Cursor", ID = "139654963330788"}, {Name = "Use Cursor", ID = "13441649168"},
        {Name = "Use Cursor", ID = "88005681147215"}, {Name = "Use Cursor", ID = "72902755839437"},
        {Name = "Use Cursor", ID = "128926155948846"}, {Name = "Use Cursor", ID = "95348763251820"},
        {Name = "Use Cursor", ID = "138513473967293"}, {Name = "Use Cursor", ID = "82043397777881"},
        {Name = "Use Cursor", ID = "84583215296063"}, {Name = "Use Cursor", ID = "120058675182639"},
        {Name = "Use Cursor", ID = "130210380679877"}, {Name = "Use Cursor", ID = "74264514489577"},
        {Name = "Use Cursor", ID = "115877213393063"}, {Name = "Use Cursor", ID = "133579119074302"},
        {Name = "Use Cursor", ID = "137970082797101"}, {Name = "Use Cursor", ID = "116865736993390"},
        {Name = "Use Cursor", ID = "70613337612134"}, {Name = "Use Cursor", ID = "75670552980458"}, 
        {Name = "Use Cursor", ID = "100822311002882"}, {Name = "Use Cursor", ID = "135331308026486"},
        {Name = "Use Cursor", ID = "91090339346537"}, {Name = "Use Cursor", ID = "99626703938913"},
        {Name = "Use Cursor", ID = "112195317343485"}, {Name = "Use Cursor", ID = "89746976355403"},
        {Name = "Use Cursor", ID = "132191954497107"}, {Name = "Use Cursor", ID = "93050147531878"},
        {Name = "Use Cursor", ID = "88343941218179"}, {Name = "Use Cursor", ID = "81277812126144"},
        {Name = "Use Cursor", ID = "131422226977434"}, {Name = "Use Cursor", ID = "116499481211766"}
    }

    local function CreateCursorSystem(isMob)
        local targetParentCur = GetParentTarget(Page)

        local CInputContainer = Instance.new("Frame")
        CInputContainer.Size = UDim2.new(1, 0, 0, 30)
        CInputContainer.BackgroundTransparency = 1
        CInputContainer.Parent = targetParentCur
        
        local TextBox = Instance.new("TextBox")
        TextBox.Size = UDim2.new(1, -75, 1, 0)
        TextBox.Position = UDim2.new(0, 5, 0, 0)
        TextBox.BackgroundTransparency = 1
        TextBox.Text = ""
        local flagKey = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
        local savedCross = UserConfigs[flagKey]
        if savedCross and savedCross ~= "RESET" then TextBox.Text = savedCross:gsub("rbxassetid://", "") end
        TextBox.PlaceholderText = "Enter Texture ID..."
        TextBox.TextColor3 = Theme.Text
        TextBox.PlaceholderColor3 = Theme.TextDark
        TextBox.Font = Theme.Font
        TextBox.TextSize = 11
        TextBox.TextXAlignment = Enum.TextXAlignment.Left
        TextBox.ClearTextOnFocus = false
        TextBox.Parent = CInputContainer
        
        local ApplyBtn = Instance.new("TextButton")
        ApplyBtn.Size = UDim2.new(0, 60, 0, 22)
        ApplyBtn.Position = UDim2.new(1, -65, 0.5, -11)
        ApplyBtn.BackgroundColor3 = Theme.Accent
        ApplyBtn.Text = "Apply"
        ApplyBtn.Font = Enum.Font.GothamBold
        ApplyBtn.TextSize = 10
        ApplyBtn.TextColor3 = Color3.new(0,0,0)
        ApplyBtn.Parent = CInputContainer
        Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)
        
        ApplyBtn.MouseButton1Click:Connect(function() 
            local id = TextBox.Text
            if id ~= "" then 
                local fullID = formatID(id)
                local flag = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
                UserConfigs[flag] = fullID
                if isMob then 
                    MobileCrosshair.Image = fullID
                    MobileCrosshair.Visible = true 
                else 
                    PCSoftwareCursor.Image = fullID
                    SetPCCursorActive(true)
                    PCSoftwareCursor.Visible = true 
                end 
            end 
        end)

        local CGridWrapper = Instance.new("Frame")
        CGridWrapper.Size = UDim2.new(1, 0, 0, 0)
        CGridWrapper.AutomaticSize = Enum.AutomaticSize.Y
        CGridWrapper.BackgroundTransparency = 1
        CGridWrapper.Parent = targetParentCur
        
        local Grid = Instance.new("UIGridLayout")
        Grid.CellSize = UDim2.new(0, 36, 0, 36)
        Grid.CellPadding = UDim2.new(0, 8, 0, 8)
        Grid.SortOrder = Enum.SortOrder.LayoutOrder
        Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Grid.Parent = CGridWrapper
        
        local UIPadding = Instance.new("UIPadding")
        UIPadding.PaddingTop = UDim.new(0, 5)
        UIPadding.PaddingBottom = UDim.new(0, 5)
        UIPadding.Parent = CGridWrapper
        
        for _, item in pairs(CursorList) do
            if item.ID == "RESET" then
                local defaultBtn = Instance.new("TextButton")
                defaultBtn.Text = "Default"
                defaultBtn.Font = Enum.Font.GothamBold
                defaultBtn.TextSize = 9
                defaultBtn.TextColor3 = Theme.TextDark
                defaultBtn.BackgroundColor3 = Color3.new(0,0,0)
                defaultBtn.BackgroundTransparency = 0.45
                defaultBtn.Parent = CGridWrapper
                Instance.new("UICorner", defaultBtn).CornerRadius = UDim.new(0, 4)
                local dStr = Instance.new("UIStroke", defaultBtn)
                dStr.Color = Color3.fromRGB(40,40,40)
                
                defaultBtn.MouseEnter:Connect(function() TweenService:Create(dStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.Accent}):Play() end)
                defaultBtn.MouseLeave:Connect(function() TweenService:Create(dStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.TextDark}):Play() end)
                
                defaultBtn.MouseButton1Click:Connect(function() 
                    local flag = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
                    UserConfigs[flag] = "RESET"
                    if isMob then 
                        MobileCrosshair.Visible = false 
                    else 
                        SetPCCursorActive(false)
                        PCSoftwareCursor.Visible = false
                        UserInputService.MouseIconEnabled = true 
                    end 
                end)
            else
                local btn = Instance.new("ImageButton")
                btn.BackgroundColor3 = Color3.new(0,0,0)
                btn.BackgroundTransparency = 0.45
                btn.Image = "rbxassetid://" .. item.ID
                btn.ScaleType = Enum.ScaleType.Crop 
                btn.Parent = CGridWrapper
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                local imgStr = Instance.new("UIStroke", btn)
                imgStr.Color = Color3.fromRGB(40,40,40)
                
                btn.MouseEnter:Connect(function() TweenService:Create(imgStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() end)
                btn.MouseLeave:Connect(function() TweenService:Create(imgStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() end)
                
                btn.MouseButton1Click:Connect(function() 
                    local fullID = "rbxassetid://" .. item.ID
                    local flag = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
                    UserConfigs[flag] = fullID
                    if isMob then 
                        MobileCrosshair.Image = fullID
                        MobileCrosshair.Visible = true 
                    else 
                        PCSoftwareCursor.Image = fullID
                        SetPCCursorActive(true)
                        PCSoftwareCursor.Visible = true 
                    end 
                end)
            end
        end
    end

    local usePCCursor = UserInputService.MouseEnabled
    if usePCCursor then CreateCursorSystem(false) else CreateCursorSystem(true) end

    -- INICIALIZADOR DE SALVOS
    if UserConfigs["TexturesPage_DoubleJump"] then task.spawn(function() EnableDoubleJumpEffect(UserConfigs["TexturesPage_DoubleJump"]) end) end
    if isMobile and UserConfigs["TexturesPage_MobileJump"] then task.spawn(function() EnableMobileButtonJump(UserConfigs["TexturesPage_MobileJump"]) end) end

    task.spawn(function()
        if usePCCursor then
            local saved = UserConfigs["TexturesPage_Crosshair_PC"]
            if saved and saved ~= "RESET" then
                PCSoftwareCursor.Image = saved
                SetPCCursorActive(true)
                PCSoftwareCursor.Visible = true 
            end
        else
            local saved = UserConfigs["TexturesPage_Crosshair_Mobile"]
            if saved and saved ~= "RESET" then
                MobileCrosshair.Image = saved
                MobileCrosshair.Visible = true 
            end
        end
    end)
end
