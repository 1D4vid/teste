return function(env)
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local RunService = env.RunService
    local CoreGui = env.CoreGui
    local Theme = env.Theme
    local UserConfigs = env.UserConfigs
    local SendNotification = env.SendNotification
    local isMobile = env.isMobile
    local UserInputService = game:GetService("UserInputService")

    -- Helper de Otimização: Processamento de loops em blocos para evitar congelar o jogo
    local function batchProcess(instances, processFunc, batchSize)
        batchSize = batchSize or 250
        local count = 0
        for _, obj in ipairs(instances) do
            processFunc(obj)
            count = count + 1
            if count >= batchSize then
                task.wait()
                count = 0
            end
        end
    end

    -- Modificação local temporária para estilizar e ampliar os Inputs de texto do módulo
    local originalCreateInput = Library.CreateInput
    Library.CreateInput = function(self, targetPage, Text, Default, Callback)
        originalCreateInput(self, targetPage, Text, Default, Callback)
        task.defer(function()
            for _, descendant in ipairs(targetPage:GetDescendants()) do
                if descendant:IsA("TextBox") then
                    -- Fundo preto transparente
                    descendant.BackgroundColor3 = Color3.new(0, 0, 0)
                    descendant.BackgroundTransparency = 0.55
                    
                    -- Ampliação do espaço para evitar corte de texto
                    descendant.Size = UDim2.new(0, 110, 0, 24)
                    descendant.Position = UDim2.new(1, -115, 0.5, -12)
                    descendant.TextXAlignment = Enum.TextXAlignment.Center
                    
                    -- Ajuste dinâmico do texto do rótulo para não sobrepor
                    local container = descendant.Parent
                    if container then
                        local label = container:FindFirstChildWhichIsA("TextLabel")
                        if label and label ~= descendant then
                            label.Size = UDim2.new(1, -125, 1, 0)
                        end
                    end
                end
            end
        end)
    end

    -- Modificação local temporária para alinhar perfeitamente as setas (▼) de todos os Dropdowns
    local originalCreateDropdown = Library.CreateDropdown
    Library.CreateDropdown = function(self, targetPage, Text, Options, Default, Callback)
        originalCreateDropdown(self, targetPage, Text, Options, Default, Callback)
        task.defer(function()
            for _, descendant in ipairs(targetPage:GetDescendants()) do
                if descendant:IsA("TextLabel") and (descendant.Text == "▼" or descendant.Text == "▲") then
                    descendant.Position = UDim2.new(1, -20, 0.5, -10)
                end
            end
        end)
    end

    local originalCreatePlayerDropdown = Library.CreatePlayerDropdown
    Library.CreatePlayerDropdown = function(self, targetPage, Text, Default, Callback)
        originalCreatePlayerDropdown(self, targetPage, Text, Default, Callback)
        task.defer(function()
            for _, descendant in ipairs(targetPage:GetDescendants()) do
                if descendant:IsA("TextLabel") and (descendant.Text == "▼" or descendant.Text == "▲") then
                    descendant.Position = UDim2.new(1, -20, 0.5, -10)
                end
            end
        end)
    end

    local HideLeavesConnection = nil
    local hiddenParts = setmetatable({}, {__mode = "k"}) 
    local currentFont = "Default"
    local originalFonts = setmetatable({}, {__mode = "k"})
    
    local originalName = LocalPlayer.Name
    local originalDisplayName = LocalPlayer.DisplayName
    local originalLevel = "1"
    local spoofName = LocalPlayer.Name
    local spoofLevel = 100
    local spoofIconId = "rbxassetid://1188562340"

    local spoofVisualsEnabled = false
    local spoofVisualsLoop
    local meusIcones = {
        VIP = "rbxassetid://1188562340",
        QA = "rbxassetid://105177418407648",
        CON = "rbxassetid://76898592264692",
        Mod = "rbxassetid://105155010224102",
        Dev = "rbxassetid://18940006678",
        Manager = "rbxassetid://131476591459702",
        MrWindy = "rbxassetid://18937953345",
        Nenhum = ""
    }
    local originalTexts = setmetatable({}, {__mode = "k"})
    
    -- Configurações de Spoof de outros jogadores
    local spoofOthersEnabled = false
    local targetOrigName = "Select Player"
    local targetFakeName = "Fake Name"
    local targetFakeLevel = 100
    local targetFakeIcon = ""
    local spoofedOthers = {}
    local othersOriginalData = {}

    -- Variáveis e mecânicas internas de Touch Sensitivity
    local touchSensEnabled = false
    local touchSensValue = 1.0
    local hookActive = false

    local function setupCameraHook()
        local success = false
        pcall(function()
            local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
            if not playerScripts then return end
            local playerModule = playerScripts:FindFirstChild("PlayerModule")
            if not playerModule then return end
            local cameraModule = playerModule:FindFirstChild("CameraModule")
            if cameraModule then
                local cameraInput = cameraModule:FindFirstChild("CameraInput")
                if cameraInput then
                    local cameraInputModule = require(cameraInput)
                    if cameraInputModule and cameraInputModule.getRotation then
                        local originalGetRotation = cameraInputModule.getRotation
                        cameraInputModule.getRotation = function(disableRotation)
                            local rotation = originalGetRotation(disableRotation)
                            if touchSensEnabled and UserInputService.TouchEnabled then
                                return rotation * touchSensValue
                            end
                            return rotation
                        end
                        success = true
                        hookActive = true
                    end
                end
            end
        end)
        if not success then
            pcall(function()
                local oldIndex
                oldIndex = hookmetamethod(game, "__index", function(self, key)
                    if self == UserInputService and key == "MouseDelta" then
                        local original = oldIndex(self, key)
                        if touchSensEnabled and UserInputService.TouchEnabled then
                            return original * touchSensValue
                        end
                        return original
                    end
                    return oldIndex(self, key)
                end)
                success = true
                hookActive = true
            end)
        end
        return success
    end
    setupCameraHook()

    -- Variáveis e mecânicas internas do Remove Black Screen
    local removeBlackScreenEnabled = false
    local blackoutConn = nil
    local blackoutCharConn = nil

    local function bypassScreen(child)
        if removeBlackScreenEnabled and child.Name == "BlackOutScreenGui" then
            task.wait()
            child:Destroy()
            local cam = workspace.CurrentCamera
            if cam then cam.CameraType = Enum.CameraType.Custom end
        end
    end

    local function setupBlackoutBypass(state)
        removeBlackScreenEnabled = state
        if state then
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
            if PlayerGui then
                local existing = PlayerGui:FindFirstChild("BlackOutScreenGui")
                if existing then
                    existing:Destroy()
                    local cam = workspace.CurrentCamera
                    if cam then cam.CameraType = Enum.CameraType.Custom end
                end
                blackoutConn = PlayerGui.ChildAdded:Connect(bypassScreen)
            end
            
            blackoutCharConn = LocalPlayer.CharacterAdded:Connect(function()
                local pGui = LocalPlayer:WaitForChild("PlayerGui", 5)
                if pGui then
                    local existingOnSpawn = pGui:FindFirstChild("BlackOutScreenGui")
                    if existingOnSpawn then
                        existingOnSpawn:Destroy()
                        local cam = workspace.CurrentCamera
                        if cam then cam.CameraType = Enum.CameraType.Custom end
                    end
                    if blackoutConn then blackoutConn:Disconnect() end
                    blackoutConn = pGui.ChildAdded:Connect(bypassScreen)
                end
            end)
        else
            if blackoutConn then blackoutConn:Disconnect() blackoutConn = nil end
            if blackoutCharConn then blackoutCharConn:Disconnect() blackoutCharConn = nil end
        end
    end

    -- Variáveis e mecânicas internas do Ocultar Nomes dos Jogadores
    local hidePlayerNamesEnabled = false
    local playerNamesConnections = {}
    local originalHeadDisplayTypes = {}
    local originalUiTexts = setmetatable({}, {__mode = "k"})
    local changingUi = false
    local playerNamesCache = {}

    local function updatePlayerNamesCache()
        table.clear(playerNamesCache)
        for _, p in ipairs(Players:GetPlayers()) do
            local name = p.Name
            local disp = p.DisplayName
            if name then playerNamesCache[name] = true end
            if disp and disp ~= "" then playerNamesCache[disp] = true end
        end
    end

    local function applyOcultarNomeCabeca(player)
        local function aplicar(char)
            local hum = char:WaitForChild("Humanoid", 10)
            if hum then
                if not originalHeadDisplayTypes[hum] then
                    originalHeadDisplayTypes[hum] = hum.DisplayDistanceType
                end
                if hidePlayerNamesEnabled then
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                end
            end
        end
        if hidePlayerNamesEnabled then
            local charAddedConn = player.CharacterAdded:Connect(aplicar)
            table.insert(playerNamesConnections, charAddedConn)
            if player.Character then aplicar(player.Character) end
        end
    end

    local function limparTextoUI(element)
        if not hidePlayerNamesEnabled then return end
        if not element:IsA("TextLabel") and not element:IsA("TextButton") and not element:IsA("TextBox") then return end
        
        local function verificar()
            if changingUi then return end
            local txt = element.Text
            if txt == "" then return end
            
            if not originalUiTexts[element] then
                originalUiTexts[element] = txt
            end
            
            local mudou = false
            for targetName, _ in pairs(playerNamesCache) do
                if txt:find(targetName, 1, true) then
                    txt = txt:gsub(targetName, "")
                    mudou = true
                end
            end
            
            if mudou then
                changingUi = true
                pcall(function() element.Text = txt end)
                changingUi = false
            end
        end
        
        verificar()
        local textConn = element:GetPropertyChangedSignal("Text"):Connect(verificar)
        table.insert(playerNamesConnections, textConn)
    end

    local function setHidePlayerNames(state)
        hidePlayerNamesEnabled = state
        if state then
            updatePlayerNamesCache()
            table.insert(playerNamesConnections, Players.PlayerAdded:Connect(function(p)
                updatePlayerNamesCache()
                applyOcultarNomeCabeca(p)
            end))
            table.insert(playerNamesConnections, Players.PlayerRemoving:Connect(updatePlayerNamesCache))

            for _, player in ipairs(Players:GetPlayers()) do 
                applyOcultarNomeCabeca(player) 
            end

            local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
            if playerGui then
                task.spawn(function()
                    local desc = playerGui:GetDescendants()
                    batchProcess(desc, limparTextoUI, 150)
                end)
                local pgConn = playerGui.DescendantAdded:Connect(limparTextoUI)
                table.insert(playerNamesConnections, pgConn)
            end

            pcall(function()
                task.spawn(function()
                    local desc = CoreGui:GetDescendants()
                    batchProcess(desc, limparTextoUI, 150)
                end)
                local cgConn = CoreGui.DescendantAdded:Connect(limparTextoUI)
                table.insert(playerNamesConnections, cgConn)
            end)
        else
            for _, conn in ipairs(playerNamesConnections) do
                if conn then conn:Disconnect() end
            end
            table.clear(playerNamesConnections)

            for hum, originalType in pairs(originalHeadDisplayTypes) do
                if hum and hum.Parent then
                    pcall(function() hum.DisplayDistanceType = originalType end)
                end
            end
            table.clear(originalHeadDisplayTypes)

            changingUi = true
            for element, originalText in pairs(originalUiTexts) do
                if element and element.Parent then
                    pcall(function() element.Text = originalText end)
                end
            end
            changingUi = false
            table.clear(originalUiTexts)
            table.clear(playerNamesCache)
        end
    end

    -- Variáveis e mecânicas internas de Cam Blur (Motion Blur)
    local camBlurEnabled = false
    local motionBlur = nil
    local camBlurConn = nil
    local camChangeConn = nil

    local function setupCamBlur(state)
        camBlurEnabled = state
        if state then
            local camera = workspace.CurrentCamera
            if not motionBlur then
                motionBlur = Instance.new("BlurEffect")
                motionBlur.Name = "NexMotionBlur"
            end
            motionBlur.Parent = camera
            
            local lastVector = camera.CFrame.LookVector
            
            camChangeConn = workspace.Changed:Connect(function(property)
                if property == "CurrentCamera" then
                    local newCam = workspace.CurrentCamera
                    if motionBlur then
                        motionBlur.Parent = newCam
                    end
                end
            end)
            
            camBlurConn = RunService.Heartbeat:Connect(function()
                local currentCam = workspace.CurrentCamera
                if not currentCam then return end
                if not motionBlur or motionBlur.Parent == nil then
                    motionBlur = Instance.new("BlurEffect")
                    motionBlur.Name = "NexMotionBlur"
                    motionBlur.Parent = currentCam
                end
                
                local magnitude = (currentCam.CFrame.LookVector - lastVector).magnitude
                motionBlur.Size = math.abs(magnitude) * 20 * 10 / 2
                lastVector = currentCam.CFrame.LookVector
            end)
        else
            if camBlurConn then camBlurConn:Disconnect() camBlurConn = nil end
            if camChangeConn then camChangeConn:Disconnect() camChangeConn = nil end
            if motionBlur then
                motionBlur:Destroy()
                motionBlur = nil
            end
        end
    end

    -- Variáveis e motor interno do Players Cam (Mini Spectate Viewport)
    local playersCamEnabled = false
    local spectateConnection = nil
    local targetPlayer = nil
    local activePlayers = {} 
    local clonedEnvironment = {}
    local wasCharacterActive = false
    local mapLoadingSession = 0
    local playerCharacters = {}
    local spectateGui = nil
    local spectateConnsList = {}
    
    local OUT_OF_BOUNDS_CFRAME = CFrame.new(0, -9999, 0)
    local CAMERA_OFFSET = CFrame.new(0, 0.1, -0.15)

    local function getSpectateablePlayers()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(list, p) end
        end
        return list
    end

    local function cloneAndMap(originalInstance)
        local originalToClone = {}
        local parts = {}
        for _, d in ipairs(originalInstance:GetDescendants()) do
            table.insert(parts, d)
            d:SetAttribute("TempSyncID", #parts)
        end
        local originalArchivables = {}
        for _, child in ipairs(originalInstance:GetDescendants()) do
            if child:IsA("LuaSourceContainer") or child:IsA("Sound") or child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") or child:IsA("Attachment") or child:IsA("Light") then
                originalArchivables[child] = child.Archivable
                child.Archivable = false
            end
        end
        local wasArchivable = originalInstance.Archivable
        originalInstance.Archivable = true
        local clone
        pcall(function() clone = originalInstance:Clone() end)
        originalInstance.Archivable = wasArchivable
        for _, d in ipairs(parts) do d:SetAttribute("TempSyncID", nil) end
        for inst, state in pairs(originalArchivables) do
            if inst and inst.Parent then inst.Archivable = state end
        end
        if not clone then return nil, {} end
        for _, d in ipairs(clone:GetDescendants()) do
            local id = d:GetAttribute("TempSyncID")
            if id then
                local originalItem = parts[id]
                if originalItem then originalToClone[originalItem] = d end
                d:SetAttribute("TempSyncID", nil)
            end
        end
        return clone, originalToClone
    end

    local function shouldCloneMapPart(part)
        if not part:IsA("BasePart") then return false end
        if part.Transparency >= 1 then return false end
        if part.Size.X < 0.1 or part.Size.Y < 0.1 or part.Size.Z < 0.1 then return false end
        if spectateGui and part:IsDescendantOf(spectateGui) then return false end
        local current = part.Parent
        while current and current ~= workspace do
            if playerCharacters[current] then return false end
            current = current.Parent
        end
        return true
    end

    local function cloneMapPart(part, folder)
        if clonedEnvironment[part] then return end
        local wasArchivable = part.Archivable
        part.Archivable = true
        local success, clone = pcall(function() return part:Clone() end)
        part.Archivable = wasArchivable
        if success and clone then
            clone.Parent = folder
            clone.Anchored = true
            clone.CanCollide = false
            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
                    d:Destroy()
                elseif d:IsA("BasePart") then
                    d.Anchored = true
                    d.CanCollide = false
                end
            end
            clonedEnvironment[part] = clone
        end
    end

    local function reloadMapProgressively(folder)
        mapLoadingSession = mapLoadingSession + 1
        local currentSession = mapLoadingSession
        for originalPart, clonedPart in pairs(clonedEnvironment) do
            if clonedPart then clonedPart:Destroy() end
        end
        table.clear(clonedEnvironment)
        folder:ClearAllChildren()

        task.spawn(function()
            local allInstances = workspace:GetDescendants()
            local batchSize = 100
            local count = 0
            for _, obj in ipairs(allInstances) do
                if not playersCamEnabled or currentSession ~= mapLoadingSession then return end
                if obj:IsA("BasePart") and shouldCloneMapPart(obj) then
                    cloneMapPart(obj, folder)
                end
                count = count + 1
                if count >= batchSize then
                    task.wait()
                    count = 0
                end
            end
        end)
    end

    local function removePlayerClone(player)
        local data = activePlayers[player]
        if data then
            if data.clone then data.clone:Destroy() end
            for _, conn in ipairs(data.connections) do
                if conn then conn:Disconnect() end
            end
            activePlayers[player] = nil
        end
    end

    local function clearViewportSpectate(keepMap, cam, folder)
        for player, _ in pairs(activePlayers) do
            removePlayerClone(player)
        end
        table.clear(activePlayers)
        if not keepMap then
            for originalPart, clonedPart in pairs(clonedEnvironment) do
                if clonedPart then clonedPart:Destroy() end
            end
            table.clear(clonedEnvironment)
            folder:ClearAllChildren()
            if cam then cam.CFrame = OUT_OF_BOUNDS_CFRAME end
        end
    end

    local setupPlayerCloneSpectate
    setupPlayerCloneSpectate = function(player, isTarget, viewportFrame)
        if not playersCamEnabled then return end
        local realChar = player.Character
        if not realChar then return end
        local clone, mapping = cloneAndMap(realChar)
        if not clone then return end

        if isTarget then
            local head = clone:FindFirstChild("Head")
            if head then head.Transparency = 1 end
            for _, acc in ipairs(clone:GetChildren()) do
                if acc:IsA("Accessory") then
                    local handle = acc:FindFirstChild("Handle")
                    if handle then handle.Transparency = 1 end
                end
            end
        end
        clone.Parent = viewportFrame

        local conns = {}
        local data = {
            clone = clone,
            connections = conns,
            realParts = {},
            cloneParts = {},
            instanceMap = mapping
        }

        for realItem, cloneItem in pairs(mapping) do
            if realItem:IsA("BasePart") then
                cloneItem.CanCollide = false
                cloneItem.Anchored = true
                table.insert(data.realParts, realItem)
                table.insert(data.cloneParts, cloneItem)
            end
        end

        table.insert(conns, realChar.DescendantAdded:Connect(function(descendant)
            task.defer(function()
                if not playersCamEnabled or not data.clone or not descendant.Parent then return end
                if data.instanceMap[descendant] then return end
                local cloneParent = data.instanceMap[descendant.Parent] or data.clone
                local wasArchivable = descendant.Archivable
                descendant.Archivable = true
                local success, cloneItem = pcall(function() return descendant:Clone() end)
                descendant.Archivable = wasArchivable
                if success and cloneItem then
                    cloneItem.Parent = cloneParent
                    data.instanceMap[descendant] = cloneItem
                    if descendant:IsA("BasePart") then
                        cloneItem.CanCollide = false
                        cloneItem.Anchored = true
                        table.insert(data.realParts, descendant)
                        table.insert(data.cloneParts, cloneItem)
                    end
                    for _, d in ipairs(cloneItem:GetDescendants()) do
                        if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
                            d:Destroy()
                        elseif d:IsA("BasePart") then
                            d.Anchored = true
                            d.CanCollide = false
                        end
                    end
                end
            end)
        end))

        table.insert(conns, player.CharacterAdded:Connect(function()
            if not playersCamEnabled then return end
            removePlayerClone(player)
            task.spawn(function()
                task.wait(0.2)
                if playersCamEnabled and player.Character then
                    setupPlayerCloneSpectate(player, (player == targetPlayer), viewportFrame)
                end
            end)
        end))
        activePlayers[player] = data
    end

    local function updatePlayersTrackingSpectate(centerPos, viewportFrame)
        local maxTrackDistance = 30 
        for p, _ in pairs(activePlayers) do
            if not p or not p.Parent or not p.Character or not p.Character:FindFirstChild("Head") then
                removePlayerClone(p)
            else
                local head = p.Character.Head
                if (head.Position - centerPos).Magnitude >= (maxTrackDistance + 10) then
                    removePlayerClone(p)
                end
            end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local head = char and char:FindFirstChild("Head")
            if head and (head.Position - centerPos).Magnitude < maxTrackDistance then
                if not activePlayers[p] then
                    setupPlayerCloneSpectate(p, (p == targetPlayer), viewportFrame)
                end
            end
        end
    end

    local function syncAllPlayerPositionsSpectate()
        for _, data in pairs(activePlayers) do
            local realParts = data.realParts
            local cloneParts = data.cloneParts
            if realParts then
                for i = #realParts, 1, -1 do
                    local realPart = realParts[i]
                    local clonePart = cloneParts[i]
                    local success = false
                    if realPart and realPart.Parent and clonePart and clonePart.Parent then
                        success = pcall(function() clonePart.CFrame = realPart.CFrame end)
                    end
                    if not success then
                        if clonePart then pcall(function() clonePart:Destroy() end) end
                        table.remove(realParts, i)
                        table.remove(cloneParts, i)
                    end
                end
            end
        end
    end

    local function startSpectateEngine(player, titleLabel, viewportFrame, cam, folder)
        if spectateConnection then
            spectateConnection:Disconnect()
            spectateConnection = nil
        end
        clearViewportSpectate(true, cam, folder)
        if not player or player == LocalPlayer then
            targetPlayer = nil
            wasCharacterActive = false
            titleLabel.Text = "Spectating: None"
            return
        end
        targetPlayer = player
        titleLabel.Text = "Spectating: " .. targetPlayer.DisplayName
        wasCharacterActive = false

        local realChar = targetPlayer.Character
        local head = realChar and realChar:FindFirstChild("Head")
        if head then
            task.spawn(updatePlayersTrackingSpectate, head.Position, viewportFrame)
        end

        spectateConnection = RunService.RenderStepped:Connect(function()
            if not playersCamEnabled then return end
            if not targetPlayer or not targetPlayer.Parent then
                startSpectateEngine(nil, titleLabel, viewportFrame, cam, folder)
                return
            end
            local character = targetPlayer.Character
            if character and character:FindFirstChild("Head") then
                wasCharacterActive = true
                local targetHead = character.Head
                syncAllPlayerPositionsSpectate()
                if cam then
                    cam.CFrame = targetHead.CFrame * CAMERA_OFFSET
                end
            else
                if wasCharacterActive then
                    clearViewportSpectate(true, cam, folder)
                    wasCharacterActive = false
                end
            end
        end)
    end

    local function cycleSpectateEngine(direction, titleLabel, viewportFrame, cam, folder)
        local list = getSpectateablePlayers()
        if #list == 0 then
            startSpectateEngine(nil, titleLabel, viewportFrame, cam, folder)
            return
        end
        local currentIndex = 0
        if targetPlayer then
            for i, p in ipairs(list) do
                if p == targetPlayer then currentIndex = i break end
            end
        end
        local nextIndex = currentIndex + direction
        if nextIndex > #list then nextIndex = 1
        elseif nextIndex < 1 then nextIndex = #list end
        startSpectateEngine(list[nextIndex], titleLabel, viewportFrame, cam, folder)
    end

    local function setupPlayersCam(state)
        playersCamEnabled = state
        if state then
            local pGui = LocalPlayer:WaitForChild("PlayerGui")
            if pGui:FindFirstChild("MiniSpectateGUI") then pGui.MiniSpectateGUI:Destroy() end

            spectateGui = Instance.new("ScreenGui")
            spectateGui.Name = "MiniSpectateGUI"
            spectateGui.ResetOnSpawn = false
            spectateGui.Parent = pGui

            local mainFrame = Instance.new("Frame")
            mainFrame.Name = "MainFrame"
            mainFrame.Size = UDim2.new(0, 260, 0, 160)
            mainFrame.Position = UDim2.new(0.5, -130, 0.2, 0)
            mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
            mainFrame.BorderSizePixel = 1
            mainFrame.Active = true
            mainFrame.Parent = spectateGui

            local topBar = Instance.new("Frame")
            topBar.Name = "TopBar"
            topBar.Size = UDim2.new(1, 0, 0, 22)
            topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            topBar.BorderSizePixel = 0
            topBar.Parent = mainFrame

            local divider = Instance.new("Frame")
            divider.Name = "Divider"
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Position = UDim2.new(0, 0, 1, 0)
            divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            divider.BorderSizePixel = 0
            divider.Parent = topBar

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Name = "PlayerNameLabel"
            titleLabel.Size = UDim2.new(1, 0, 1, 0)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = "Spectating: None"
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLabel.Font = Enum.Font.SourceSansBold
            titleLabel.TextSize = 13
            titleLabel.Parent = topBar

            local viewport = Instance.new("ViewportFrame")
            viewport.Name = "Viewport"
            viewport.Size = UDim2.new(1, 0, 1, -23)
            viewport.Position = UDim2.new(0, 0, 0, 23)
            viewport.BackgroundTransparency = 1
            viewport.BorderSizePixel = 0
            viewport.Parent = mainFrame
            viewport.Ambient = Color3.fromRGB(255, 255, 255)
            viewport.LightColor = Color3.fromRGB(255, 255, 255)
            viewport.LightDirection = Vector3.new(0, -1, 0)

            local cam = Instance.new("Camera")
            cam.FieldOfView = 75
            viewport.CurrentCamera = cam
            cam.Parent = viewport

            local clonedMapFolder = Instance.new("Folder")
            clonedMapFolder.Name = "ClonedMap"
            clonedMapFolder.Parent = viewport

            local leftBtn = Instance.new("TextButton")
            leftBtn.Name = "LeftBtn"
            leftBtn.Size = UDim2.new(0, 20, 0, 20)
            leftBtn.Position = UDim2.new(0, 10, 1, -25)
            leftBtn.BackgroundTransparency = 1
            leftBtn.BorderSizePixel = 0
            leftBtn.Text = "<"
            leftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            leftBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            leftBtn.TextStrokeTransparency = 0.5
            leftBtn.Font = Enum.Font.SourceSansBold
            leftBtn.TextSize = 20
            leftBtn.ZIndex = 10
            leftBtn.Parent = mainFrame

            local zBtn = Instance.new("TextButton")
            zBtn.Name = "ZBtn"
            zBtn.Size = UDim2.new(0, 20, 0, 20)
            zBtn.Position = UDim2.new(0.5, -10, 1, -25)
            zBtn.BackgroundTransparency = 1
            zBtn.BorderSizePixel = 0
            zBtn.Text = "z"
            zBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            zBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            zBtn.TextStrokeTransparency = 0.5
            zBtn.Font = Enum.Font.SourceSansBold
            zBtn.TextSize = 20
            zBtn.ZIndex = 10
            zBtn.Parent = mainFrame

            local rightBtn = Instance.new("TextButton")
            rightBtn.Name = "RightBtn"
            rightBtn.Size = UDim2.new(0, 20, 0, 20)
            rightBtn.Position = UDim2.new(1, -30, 1, -25)
            rightBtn.BackgroundTransparency = 1
            rightBtn.BorderSizePixel = 0
            rightBtn.Text = ">"
            rightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            rightBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            rightBtn.TextStrokeTransparency = 0.5
            rightBtn.Font = Enum.Font.SourceSansBold
            rightBtn.TextSize = 20
            rightBtn.ZIndex = 10
            rightBtn.Parent = mainFrame

            local function trackCharacter(char)
                if char then playerCharacters[char] = true end
            end
            local function untrackCharacter(char)
                if char then playerCharacters[char] = nil end
            end
            local function setupCharacterTracking(player)
                if player.Character then trackCharacter(player.Character) end
                table.insert(spectateConnsList, player.CharacterAdded:Connect(trackCharacter))
                table.insert(spectateConnsList, player.CharacterRemoving:Connect(untrackCharacter))
            end

            for _, p in ipairs(Players:GetPlayers()) do setupCharacterTracking(p) end
            table.insert(spectateConnsList, Players.PlayerAdded:Connect(setupCharacterTracking))
            table.insert(spectateConnsList, Players.PlayerRemoving:Connect(function(p)
                if p.Character then untrackCharacter(p.Character) end
                removePlayerClone(p)
            end))

            leftBtn.MouseButton1Click:Connect(function() cycleSpectateEngine(-1, titleLabel, viewport, cam, clonedMapFolder) end)
            zBtn.MouseButton1Click:Connect(function() cycleSpectateEngine(1, titleLabel, viewport, cam, clonedMapFolder) end)
            rightBtn.MouseButton1Click:Connect(function() cycleSpectateEngine(1, titleLabel, viewport, cam, clonedMapFolder) end)

            table.insert(spectateConnsList, UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode == Enum.KeyCode.Z then cycleSpectateEngine(1, titleLabel, viewport, cam, clonedMapFolder) end
            end))

            table.insert(spectateConnsList, workspace.DescendantAdded:Connect(function(descendant)
                if not descendant:IsA("BasePart") then return end
                if shouldCloneMapPart(descendant) then cloneMapPart(descendant, clonedMapFolder) end
            end))

            table.insert(spectateConnsList, workspace.DescendantRemoving:Connect(function(descendant)
                if not descendant:IsA("BasePart") then return end
                local clonePart = clonedEnvironment[descendant]
                if clonePart then pcall(function() clonePart:Destroy() end) clonedEnvironment[descendant] = nil end
            end))

            local draggingFrame, dragInputFrame, dragStartFrame, startPosFrame
            mainFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingFrame = true
                    dragStartFrame = input.Position
                    startPosFrame = mainFrame.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then draggingFrame = false end
                    end)
                end
            end)
            mainFrame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    dragInputFrame = input
                end
            end)
            table.insert(spectateConnsList, UserInputService.InputChanged:Connect(function(input)
                if input == dragInputFrame and draggingFrame then
                    local delta = input.Position - dragStartFrame
                    mainFrame.Position = UDim2.new(startPosFrame.X.Scale, startPosFrame.X.Offset + delta.X, startPosFrame.Y.Scale, startPosFrame.Y.Offset + delta.Y)
                end
            end))

            task.spawn(function()
                while playersCamEnabled and task.wait(0.5) do
                    if targetPlayer and targetPlayer.Parent then
                        local realChar = targetPlayer.Character
                        local head = realChar and realChar:FindFirstChild("Head")
                        if head then updatePlayersTrackingSpectate(head.Position, viewport) end
                    else
                        task.wait(1)
                    end
                end
            end)

            reloadMapProgressively(clonedMapFolder)
            cycleSpectateEngine(1, titleLabel, viewport, cam, clonedMapFolder)
        else
            if spectateGui then spectateGui:Destroy() spectateGui = nil end
            if spectateConnection then spectateConnection:Disconnect() spectateConnection = nil end
            for _, conn in ipairs(spectateConnsList) do if conn then conn:Disconnect() end end
            table.clear(spectateConnsList)
            clearViewportSpectate(false, nil, nil)
        end
    end

    local function patchElement(e)
        if not e or not e:IsA("GuiObject") then return end
        if not (e:IsA("TextLabel") or e:IsA("TextButton") or e:IsA("TextBox")) then return end
        local ok, txt = pcall(function() return e.Text end)
        if not ok or not txt or txt == "" then return end
        
        local changed = false
        local newTxt = txt
        
        if spoofVisualsEnabled then
            if newTxt:find(originalName, 1, true) then
                newTxt = newTxt:gsub(originalName, spoofName)
                changed = true
            end
            if originalDisplayName and newTxt:find(originalDisplayName, 1, true) then
                newTxt = newTxt:gsub(originalDisplayName, spoofName)
                changed = true
            end
        end
        
        if spoofOthersEnabled then
            for origNameKey, fakeData in pairs(spoofedOthers) do
                local fakeName = fakeData.spoofName
                if newTxt:find(origNameKey, 1, true) then
                    newTxt = newTxt:gsub(origNameKey, fakeName)
                    changed = true
                end
                local backup = othersOriginalData[origNameKey]
                local origDisp = backup and backup.DisplayName
                if origDisp and newTxt:find(origDisp, 1, true) then
                    newTxt = newTxt:gsub(origDisp, fakeName)
                    changed = true
                end
            end
        end
        
        if changed then
            if not originalTexts[e] then originalTexts[e] = txt end
            pcall(function() e.Text = newTxt end)
        else
            if originalTexts[e] and txt ~= originalTexts[e] then
                local orig = originalTexts[e]
                local shouldBeSpoofed = false
                
                if spoofVisualsEnabled and (orig:find(originalName, 1, true) or (originalDisplayName and orig:find(originalDisplayName, 1, true))) then
                    shouldBeSpoofed = true
                end
                
                if spoofOthersEnabled and not shouldBeSpoofed then
                    for origNameKey, _ in pairs(spoofedOthers) do
                        local backup = othersOriginalData[origNameKey]
                        local origDisp = backup and backup.DisplayName
                        if orig:find(origNameKey, 1, true) or (origDisp and orig:find(origDisp, 1, true)) then
                            shouldBeSpoofed = true
                            break
                        end
                    end
                end
                
                if not shouldBeSpoofed then
                    pcall(function() e.Text = orig end)
                end
            end
        end
    end
    
    local function trackElement(e)
        if not e then return end
        if e:IsA("TextLabel") or e:IsA("TextButton") or e:IsA("TextBox") then
            patchElement(e)
            pcall(function() e:GetPropertyChangedSignal("Text"):Connect(function() patchElement(e) end) end)
        end
    end
    
    local trackersInitialized = false
    local function updateTrackers()
        if not trackersInitialized then
            trackersInitialized = true
            pcall(function()
                task.spawn(function()
                    local coreDesc = CoreGui:GetDescendants()
                    batchProcess(coreDesc, trackElement, 150)
                end)
                CoreGui.DescendantAdded:Connect(trackElement)
                
                local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
                if playerGui then
                    task.spawn(function()
                        local playerDesc = playerGui:GetDescendants()
                        batchProcess(playerDesc, trackElement, 150)
                    end)
                    playerGui.DescendantAdded:Connect(trackElement)
                end
            end)
        end
        for e, origTxt in pairs(originalTexts) do
            if e and e.Parent then 
                pcall(function() e.Text = origTxt end)
                patchElement(e)
            end
        end
    end

    local cachedNamesFrame = nil
    local function getNamesFrame()
        if cachedNamesFrame and cachedNamesFrame.Parent then
            return cachedNamesFrame
        end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local namesFrame = playerGui and playerGui:FindFirstChild("PlayerNamesFrame", true)
        cachedNamesFrame = namesFrame
        return namesFrame
    end

    local updateAccumulator = 0
    spoofVisualsLoop = RunService.Heartbeat:Connect(function(dt)
        if not spoofVisualsEnabled and not spoofOthersEnabled then return end
        
        -- Cap das atualizações de nomes para 20 vezes por segundo para economizar CPU
        updateAccumulator = updateAccumulator + dt
        if updateAccumulator < 0.05 then return end
        updateAccumulator = 0
        
        pcall(function()
            local namesFrame = getNamesFrame()

            if spoofOthersEnabled then
                for origNameKey, data in pairs(spoofedOthers) do
                    local player = Players:FindFirstChild(origNameKey)
                    if player and player.Character then
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum then pcall(function() hum.DisplayName = data.spoofName end) end
                    end
                    
                    if namesFrame then
                        local playerFrame = namesFrame:FindFirstChild(origNameKey .. "PlayerFrame")
                        if playerFrame then
                            local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                            local nameLabel  = playerFrame:FindFirstChild("NameLabel")
                            local iconLabel  = playerFrame:FindFirstChild("IconLabel")
                            
                            if levelLabel then levelLabel.Text = tostring(data.spoofLevel) end
                            if nameLabel then nameLabel.Text = data.spoofName end
                            if iconLabel then 
                                iconLabel.ImageTransparency = 1
                                local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                                if not fakeIcon then
                                    fakeIcon = Instance.new("ImageLabel")
                                    fakeIcon.Name = "IconeFakeCorrigido"
                                    fakeIcon.BackgroundTransparency = 1
                                    fakeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                                    fakeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
                                    fakeIcon.ZIndex = iconLabel.ZIndex + 1
                                    fakeIcon.Parent = iconLabel
                                end
                                fakeIcon.Image = data.spoofIcon
                                fakeIcon.Visible = true
                                fakeIcon.ScaleType = Enum.ScaleType.Fit
                                
                                if data.spoofIcon == meusIcones.QA or data.spoofIcon == meusIcones.CON then
                                    fakeIcon.Size = UDim2.new(1.35, 0, 1.35, 0) 
                                else
                                    fakeIcon.Size = UDim2.new(1.0, 0, 1.0, 0)
                                end
                            end
                        end
                    end
                end
            end
            
            if spoofVisualsEnabled then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum.DisplayName = spoofName end) end
                    local head = char:FindFirstChild("Head")
                    if head then
                        for _, gui in ipairs(head:GetChildren()) do
                            if gui:IsA("BillboardGui") then
                                for _, d in ipairs(gui:GetDescendants()) do trackElement(d) end
                            end
                        end
                    end
                end
                
                if not namesFrame then return end
                local playerFrame = namesFrame:FindFirstChild(LocalPlayer.Name .. "PlayerFrame")
                if not playerFrame then return end
                local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                local nameLabel  = playerFrame:FindFirstChild("NameLabel")
                local iconLabel  = playerFrame:FindFirstChild("IconLabel")
                if levelLabel and originalLevel == "1" and levelLabel.Text ~= tostring(spoofLevel) then
                    originalLevel = levelLabel.Text
                end
                if levelLabel then levelLabel.Text = tostring(spoofLevel) end
                if nameLabel then nameLabel.Text = spoofName end
                if iconLabel then 
                    iconLabel.ImageTransparency = 1
                    local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                    if not fakeIcon then
                        fakeIcon = Instance.new("ImageLabel")
                        fakeIcon.Name = "IconeFakeCorrigido"
                        fakeIcon.BackgroundTransparency = 1
                        fakeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                        fakeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
                        fakeIcon.ZIndex = iconLabel.ZIndex + 1
                        fakeIcon.Parent = iconLabel
                    end
                    fakeIcon.Image = spoofIconId
                    fakeIcon.Visible = true
                    fakeIcon.ScaleType = Enum.ScaleType.Fit
                    if spoofIconId == meusIcones.QA or spoofIconId == meusIcones.CON then
                        fakeIcon.Size = UDim2.new(1.35, 0, 1.35, 0) 
                    else
                        fakeIcon.Size = UDim2.new(1.0, 0, 1.0, 0)
                    end
                end
                playerFrame.LayoutOrder = -spoofLevel
            end
        end)
    end)

    local stretchConnection = nil

    Library:CreateSection(Page, "Camera & UI", "Left")
    local FovVal = 70
    Library:CreateSlider(Page, "Fov Changer", 70, 120, 70, function(v) 
        FovVal = v 
    end)
    RunService.RenderStepped:Connect(function() 
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = FovVal end
    end)
    
    local fontOptions = {"Default"}
    for _, font in ipairs(Enum.Font:GetEnumItems()) do
        if font.Name ~= "Unknown" and font.Name ~= "Legacy" then table.insert(fontOptions, font.Name) end
    end
    Library:CreateDropdown(Page, "Font Changer", fontOptions, "Default", function(val) 
        currentFont = val
        local function applyFont(obj)
            if not originalFonts[obj] then originalFonts[obj] = obj.FontFace end
            if currentFont == "Default" then
                pcall(function() obj.FontFace = originalFonts[obj] end)
            else
                local selectedFont = Enum.Font[currentFont]
                if selectedFont then
                    pcall(function() obj.FontFace = Font.fromEnum(selectedFont) end)
                end
            end
        end
        for _, obj in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then applyFont(obj) end
        end
        LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d) 
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then task.defer(applyFont, d) end 
        end)
    end)

    -- Touch Sensitivity com proteção para apenas mobiles
    local touchToggle
    touchToggle = Library:CreateToggle(Page, "Touch Sensitivity", false, function(state)
        if state then
            if not isMobile and not UserInputService.TouchEnabled then
                SendNotification("This feature is only available on Touch/Mobile devices!", 3)
                task.spawn(function()
                    if touchToggle then touchToggle.Set(false) end
                end)
                touchSensEnabled = false
                return
            end
            touchSensEnabled = true
        else
            touchSensEnabled = false
        end
    end)

    Library:CreateSlider(Page, "Sensitivity Value", 1, 100, 10, function(val)
        touchSensValue = val / 10
    end)

    -- Seção Visual Environment reunida
    Library:CreateSection(Page, "Visual Environment", "Left")
    
    Library:CreateToggle(Page, "stretch screen", false, function(state) 
        if state then 
            getgenv().Resolution = {[".gg/scripters"] = 0.65}
            local Cam = workspace.CurrentCamera
            stretchConnection = game:GetService("RunService").RenderStepped:Connect(function() 
                Cam.CFrame = Cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1) 
            end) 
        else 
            if stretchConnection then 
                stretchConnection:Disconnect()
                stretchConnection = nil 
            end
            getgenv().Resolution = {[".gg/scripters"] = 1} 
        end 
    end)

    Library:CreateToggle(Page, "Hide Leaves (Only Homestead)", false, function(state) 
        if state then
            local function isGreen(part)
                local c = part.Color
                return (c.G > c.R * 1.1) and (c.G > c.B * 1.1)
            end
            local function cleanPart(part)
                if not part:IsA("BasePart") then return end
                if part.Transparency == 1 then return end
                if part.Name == "HumanoidRootPart" then return end
                if not part.CanCollide then
                    local mat = part.Material
                    local name = part.Name:lower()
                    if name:find("leaf") or name:find("bush") or name:find("grass") or name:find("tree") or mat == Enum.Material.Grass or mat == Enum.Material.LeafyGrass or isGreen(part) then
                        if not (part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")) then
                             if not hiddenParts[part] then
                                hiddenParts[part] = part.Transparency 
                                part.Transparency = 1
                            end
                        end
                    end
                end
            end
            task.spawn(function()
                local desc = workspace:GetDescendants()
                batchProcess(desc, cleanPart, 300)
            end)
            HideLeavesConnection = workspace.DescendantAdded:Connect(cleanPart)
        else
            if HideLeavesConnection then HideLeavesConnection:Disconnect() end
            for part, originalTrans in pairs(hiddenParts) do
                if part and part.Parent then part.Transparency = originalTrans end
            end
            table.clear(hiddenParts)
        end
    end)

    Library:CreateToggle(Page, "Hide Player Names", false, function(state)
        setHidePlayerNames(state)
    end)

    Library:CreateToggle(Page, "Players Cam", false, function(state)
        setupPlayersCam(state)
    end)

    Library:CreateToggle(Page, "Remove Black Screen", false, function(state)
        setupBlackoutBypass(state)
    end)

    Library:CreateToggle(Page, "Cam Blur", false, function(state)
        setupCamBlur(state)
    end)

    local WallhopFolder = nil
    local WallhopConn = nil

    local function applyWallhopESP(part)
        if part.ClassName == "Part" or part.ClassName == "TrussPart" then
            if part.ClassName == "Part" and part.Shape ~= Enum.PartType.Block then return end
            if part.Transparency > 0.8 or not part.CanCollide then return end
            if part:FindFirstChildWhichIsA("DataModelMesh") then return end
            if part.Size.Y <= 2 then return end

            local ancestorModel = part:FindFirstAncestorOfClass("Model")
            if ancestorModel and ancestorModel:FindFirstChildOfClass("Humanoid") then return end

            if WallhopFolder and not part:FindFirstChild("WallhopSelectionBox") then
                local box = Instance.new("SelectionBox")
                box.Name = "WallhopSelectionBox"
                box.Adornee = part
                box.Color3 = Color3.fromRGB(255, 255, 255)
                box.LineThickness = 0.03
                box.SurfaceTransparency = 1
                box.Parent = WallhopFolder
            end
        end
    end

    Library:CreateToggle(Page, "Wallhop Lines", false, function(state)
        if state then
            if not WallhopFolder then
                WallhopFolder = Instance.new("Folder")
                WallhopFolder.Name = "WallhopESPFolder"
                local s = pcall(function() WallhopFolder.Parent = CoreGui end)
                if not s then WallhopFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
            end

            task.spawn(function()
                local desc = Workspace:GetDescendants()
                batchProcess(desc, applyWallhopESP, 300)
            end)

            WallhopConn = Workspace.DescendantAdded:Connect(function(part)
                task.defer(function()
                    if WallhopFolder then applyWallhopESP(part) end
                end)
            end)
        else
            if WallhopConn then WallhopConn:Disconnect() WallhopConn = nil end
            if WallhopFolder then WallhopFolder:Destroy() WallhopFolder = nil end
        end
    end)

    Library:CreateSection(Page, "Visual Name/Level", "Right")
    Library:CreateToggle(Page, "Enable Visuals", false, function(state) 
        spoofVisualsEnabled = state
        if state then
            updateTrackers()
        else
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum.DisplayName = originalDisplayName end) end
                end
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if not playerGui then return end
                local namesFrame = playerGui:FindFirstChild("PlayerNamesFrame", true)
                if namesFrame then
                    local playerFrame = namesFrame:FindFirstChild(LocalPlayer.Name .. "PlayerFrame")
                    if playerFrame then
                        local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                        local nameLabel  = playerFrame:FindFirstChild("NameLabel")
                        local iconLabel  = playerFrame:FindFirstChild("IconLabel")
                        if levelLabel then levelLabel.Text = tostring(originalLevel) end
                        if nameLabel then nameLabel.Text = originalDisplayName end
                        if iconLabel then 
                            iconLabel.ImageTransparency = 0
                            local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                            if fakeIcon then fakeIcon.Visible = false end
                        end
                        playerFrame.LayoutOrder = -tonumber(originalLevel)
                    end
                end
            end)
            updateTrackers()
        end
    end)
    Library:CreateInput(Page, "Fake Name", LocalPlayer.Name, function(val) 
        spoofName = val 
        if spoofVisualsEnabled then updateTrackers() end
    end)
    Library:CreateInput(Page, "Fake Level", "67", function(val) 
        spoofLevel = tonumber(val) or 100 
    end)
    Library:CreateDropdown(Page, "Select Icon", {"VIP", "QA", "CON", "Mod", "Dev", "Manager", "MrWindy", "Nenhum"}, "VIP", function(val) 
        spoofIconId = meusIcones[val] or "" 
    end)

    -- Seção de Spoof de outros jogadores
    Library:CreateSection(Page, "Change names other players232323.", "Right")
    
    Library:CreateToggle(Page, "Enable Others Spoofing", false, function(state)
        spoofOthersEnabled = state
        if state then
            applySpoofToTarget()
        else
            for origNameKey, _ in pairs(spoofedOthers) do
                restoreOtherPlayer(origNameKey)
            end
            table.clear(spoofedOthers)
        end
    end)

    Library:CreatePlayerDropdown(Page, "Target Player", "Select Player", function(val) 
        targetOrigName = val
        if spoofOthersEnabled then
            applySpoofToTarget()
        end
    end)

    Library:CreateDropdown(Page, "Target Fake Icon", {"VIP", "QA", "CON", "Mod", "Dev", "Manager", "MrWindy", "Nenhum"}, "VIP", function(val) 
        targetFakeIcon = meusIcones[val] or ""
        if spoofOthersEnabled then
            applySpoofToTarget()
        end
    end)

    Library:CreateInput(Page, "Target Fake Name", "Fake Name", function(val) 
        targetFakeName = val
        if spoofOthersEnabled then
            applySpoofToTarget()
        end
    end)
    
    Library:CreateInput(Page, "Target Fake Level", "100", function(val) 
        targetFakeLevel = tonumber(val) or 100
        if spoofOthersEnabled then
            applySpoofToTarget()
        end
    end)

    Library:CreateButton(Page, "Reset Selected Player", function()
        if targetOrigName ~= "Select Player" and targetOrigName ~= "" then
            restoreOtherPlayer(targetOrigName)
            SendNotification("Restored " .. targetOrigName .. " back to normal.", 3)
        else
            SendNotification("Please select a valid player first!", 3)
        end
    end)

    -- Restaura as funções originais da Library para evitar efeitos colaterais em outras abas
    Library.CreateInput = originalCreateInput
    Library.CreateDropdown = originalCreateDropdown
    Library.CreatePlayerDropdown = originalCreatePlayerDropdown
end
