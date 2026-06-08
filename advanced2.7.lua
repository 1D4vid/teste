return function(env)
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local RunService = env.RunService
    local UserInputService = env.UserInputService
    local ReplicatedStorage = env.ReplicatedStorage
    local CoreGui = env.CoreGui
    local Camera = Workspace.CurrentCamera
    
    local flyEnabled = false
    local flySpeed = 50
    local flyBg, flyBv
    local jpEnabled = false
    local jpVal = 120
    local originalJP = {}
    local jpRunConnection
    local wsEnabled = false
    local wsValue = 16
    local originalWS = {}
    local wsRunConnection
    
    -- Hitbox Extender Variables
    local hbEnabled = false
    local hbShowVisual = false
    local hbSizeX, hbSizeY, hbSizeZ = 2, 2, 2
    local targetHitboxSize = Vector3.new(2, 2, 2)
    local hbLoop = nil
    
    local infJumpEnabled = false
    local infJumpConnection = nil
    local shiftlockEnabled = false
    local ShiftLockCrosshair = nil
    local userGameSettings = nil
    local fastDoubleJumpConns = {}
    local disabledJumpConns = {}
    local fdjBackupState = {}
    local noHackFailEnabled = false
    local noHackFailThread = nil
    local autoTieDistancia = 15
    local hitAuraRange = 10
    local slowBeastAuraRange = 15 

    -- Variáveis e conexões do No Jump Delay (NJD)
    local njdEnabledLocal = false
    local njdConnectionLocal = nil
    local njdCharAdded = nil

    -- Variáveis e conexões do Anti Ragdoll V2
    local arV2Enabled = false
    local arV2Swimming = false
    local arV2OldGrav = workspace.Gravity
    local arV2Swimbeat = nil
    local arV2LastHealth = 100
    local arV2CharConn = nil
    local arV2HpConn = nil
    local arV2StateConn = nil

    -- Cache local de dados do jogador local para altíssima performance
    local localCharacter = nil
    local localHumanoid = nil
    local localHrp = nil

    -- Caches locais para otimização de busca de instâncias
    local cachedHammerEvent = nil
    local cachedPowersEvent = nil
    local cachedStaminaValue = nil

    local function updateLocalCharacterCache(char)
        localCharacter = char
        if char then
            localHumanoid = char:WaitForChild("Humanoid", 5)
            localHrp = char:WaitForChild("HumanoidRootPart", 5)
        else
            localHumanoid = nil
            localHrp = nil
        end
    end

    LocalPlayer.CharacterAdded:Connect(updateLocalCharacterCache)
    if LocalPlayer.Character then
        updateLocalCharacterCache(LocalPlayer.Character)
    end

    local function checkNJD(char)
        if not char then return false end
        return char:FindFirstChild("BeastPowers") or char:FindFirstChild("Hammer") or (LocalPlayer.Team and LocalPlayer.Team.Name == "Beast")
    end

    local function bindNJDLocal(char)
        if njdConnectionLocal then 
            njdConnectionLocal:Disconnect() 
            njdConnectionLocal = nil 
        end
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        
        njdConnectionLocal = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if njdEnabledLocal and checkNJD(char) then
                if hum.WalkSpeed < 16 then
                    hum.WalkSpeed = 16.5
                end
            end
        end)
    end

    local function arV2Unswim()
        if not arV2Swimming then return end
        arV2Swimming = false
        if arV2Swimbeat then arV2Swimbeat:Disconnect() arV2Swimbeat = nil end
        workspace.Gravity = arV2OldGrav
        if localHumanoid then
            local enums = Enum.HumanoidStateType:GetEnumItems()
            for _, s in ipairs(enums) do localHumanoid:SetStateEnabled(s, true) end
            localHumanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    local function arV2Swim()
        if arV2Swimming then return end
        if not localCharacter or not localHumanoid or localHumanoid.Health <= 0 then return end
        
        arV2OldGrav = workspace.Gravity
        workspace.Gravity = 0
        arV2Swimming = true
        
        if arV2Swimbeat then arV2Swimbeat:Disconnect() end
        localHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        for _, s in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            if s ~= Enum.HumanoidStateType.None and s ~= Enum.HumanoidStateType.Swimming then
                localHumanoid:SetStateEnabled(s, false)
            end
        end
        localHumanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        
        arV2Swimbeat = RunService.Heartbeat:Connect(function()
            pcall(function()
                if localHrp and localHumanoid then
                    local moving = (localHumanoid.MoveDirection ~= Vector3.new() or UserInputService:IsKeyDown(Enum.KeyCode.Space))
                    if not moving then
                        localHrp.Velocity = Vector3.new(0, 0, 0)
                        if pcall(function() return localHrp.AssemblyLinearVelocity end) then
                            localHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        end
                    end
                end
            end)
        end)
        
        task.delay(5, function()
            if arV2Swimming and arV2Enabled then arV2Unswim() end
        end)
    end

    local function arV2Monitor(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 15)
        local hrp = char:WaitForChild("HumanoidRootPart", 15)
        if not hum or not hrp then return end
        
        arV2LastHealth = hum.Health
        
        if arV2HpConn then arV2HpConn:Disconnect() end
        arV2HpConn = hum.HealthChanged:Connect(function(health)
            if arV2Enabled and health < arV2LastHealth and health > 0 then
                if not arV2Swimming then task.spawn(arV2Swim) end
            end
            arV2LastHealth = health
        end)
        
        if arV2StateConn then arV2StateConn:Disconnect() end
        arV2StateConn = RunService.Heartbeat:Connect(function()
            if not arV2Enabled or not char.Parent or not hum.Parent or not hrp.Parent then
                if arV2HpConn then arV2HpConn:Disconnect() arV2HpConn = nil end
                if arV2StateConn then arV2StateConn:Disconnect() arV2StateConn = nil end
                arV2Unswim()
                return
            end
            local isRagdoll = hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics
            local isDead = hum.Health <= 0
            if isRagdoll and not isDead and not arV2Swimming then
                task.spawn(arV2Swim)
            end
        end)
    end

    local function backupFDJ(c)
        local h = c:FindFirstChild("Humanoid")
        if h then
            fdjBackupState[c] = {
                UseJumpPower = h.UseJumpPower,
                JumpPower = h.JumpPower,
                JumpHeight = h.JumpHeight
            }
        end
    end
    
    local function restoreFDJBackup(c)
        local h = c and c:FindFirstChild("Humanoid")
        if h and fdjBackupState[c] then
            h.UseJumpPower = fdjBackupState[c].UseJumpPower
            h.JumpPower = fdjBackupState[c].JumpPower
            h.JumpHeight = fdjBackupState[c].JumpHeight
        end
    end
    
    local function killJumpFDJ(c)
        if not getconnections then return end
        for _,x in ipairs(getconnections(UserInputService.JumpRequest))do
            pcall(function()
                local f=x.Function
                if type(f)=="function"then
                    local e=getfenv(f)
                    if e.script and e.script:IsDescendantOf(c)then
                        x:Disable()
                        table.insert(disabledJumpConns, x)
                    end
                end
            end)
        end
    end
    
    local function restoreJumpFDJ()
        for _, x in ipairs(disabledJumpConns) do
            pcall(function() x:Enable() end)
        end
        table.clear(disabledJumpConns)
    end
    
    local function enforceOfficialSync()
        if not localHumanoid then return end
        if not userGameSettings then pcall(function() userGameSettings = UserSettings():GetService("UserGameSettings") end) end
        if userGameSettings then
            if userGameSettings.RotationType ~= Enum.RotationType.CameraRelative then
                pcall(function() userGameSettings.RotationType = Enum.RotationType.CameraRelative end)
            end
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        local dist = (Camera.Focus.Position - Camera.CFrame.Position).Magnitude
        if dist > 1 then 
            local rawCFrame = Camera.CFrame
            Camera.CFrame = rawCFrame * CFrame.new(1.75, 0, 0)
            Camera.Focus = Camera.CFrame * CFrame.new(0, 0, -dist)
        end
    end
    
    local function BackupJump(character)
        local hum = character:FindFirstChild("Humanoid")
        if hum then
            originalJP[character] = {
                JumpPower = hum.JumpPower,
                UseJumpPower = hum.UseJumpPower,
                JumpHeight = hum.JumpHeight
            }
        end
    end
    
    local function RestoreJump(character)
        local hum = character:FindFirstChild("Humanoid")
        if hum and originalJP[character] then
            hum.UseJumpPower = originalJP[character].UseJumpPower
            hum.JumpPower = originalJP[character].JumpPower
            hum.JumpHeight = originalJP[character].JumpHeight
        end
    end
    
    local function BackupSpeed(char)
        local hum = char:FindFirstChild("Humanoid")
        if hum then originalWS[char] = hum.WalkSpeed end
    end
    
    local function RestoreSpeed(char)
        local hum = char:FindFirstChild("Humanoid")
        if hum and originalWS[char] then hum.WalkSpeed = originalWS[char] end
    end

    -- Otimizado: Busca o Martelo uma única vez e mantém cache local enquanto for válido
    local function ObterEventoMarreta()
        if cachedHammerEvent and cachedHammerEvent.Parent and cachedHammerEvent:IsDescendantOf(workspace) then
            return cachedHammerEvent
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hammer = player.Character:FindFirstChild("Hammer")
                if hammer then
                    local event = hammer:FindFirstChild("HammerEvent", true)
                    if event then
                        cachedHammerEvent = event
                        return event
                    end
                end
            end
        end
        return nil
    end

    -- Otimizado: Precomputa o vetor de tamanho para evitar alocações de memória desnecessárias
    local function updateTargetHitboxSize()
        targetHitboxSize = Vector3.new(hbSizeX, hbSizeY, hbSizeZ)
    end
    
    local function updateHitboxes()
        local targetTrans = hbShowVisual and 0.6 or 1
        for _, v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer then
                local char = v.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if hrp.Size ~= targetHitboxSize then hrp.Size = targetHitboxSize end
                    if hrp.Transparency ~= targetTrans then hrp.Transparency = targetTrans end
                    hrp.CanCollide = false
                end
            end
        end
    end

    Library:CreateSection(Page, "Survivor")

    Library:CreateToggle(Page, "Beast Untie Player", false, function(state)
        getgenv().BeastUntieLigado = state
        if state then
            task.spawn(function()
                while getgenv().BeastUntieLigado do
                    local eventoMarreta = ObterEventoMarreta()
                    if eventoMarreta and eventoMarreta:IsA("RemoteEvent") then
                        pcall(function()
                            eventoMarreta:FireServer("HammerClick", true)
                        end)
                    end
                    task.wait(0.05) 
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Anti Ragdoll", false, function(state)
        getgenv().AntiRagdollLigado = state
        if state then
            task.spawn(function()
                while getgenv().AntiRagdollLigado do
                    task.wait() 
                    pcall(function()
                        local Character = LocalPlayer.Character
                        if not Character then return end
                        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
                        if not Humanoid then return end

                        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                        Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)

                        local Stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                        if Stats then
                            local Ragdoll = Stats:FindFirstChild("Ragdoll")
                            if Ragdoll and Ragdoll:IsA("BoolValue") and Ragdoll.Value then
                                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                                Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            end
                        end
                    end)
                end
            end)
        else
            pcall(function()
                local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                if Humanoid then
                    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
                    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                    Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Anti Ragdoll V2", false, function(state)
        arV2Enabled = state
        if state then
            if LocalPlayer.Character then task.spawn(arV2Monitor, LocalPlayer.Character) end
            arV2CharConn = LocalPlayer.CharacterAdded:Connect(arV2Monitor)
        else
            arV2Enabled = false
            if arV2CharConn then arV2CharConn:Disconnect() arV2CharConn = nil end
            if arV2HpConn then arV2HpConn:Disconnect() arV2HpConn = nil end
            if arV2StateConn then arV2StateConn:Disconnect() arV2StateConn = nil end
            arV2Unswim()
        end
    end)

    Library:CreateToggle(Page, "Slow Beast", false, function(state)
        getgenv().SlowBeastLigado = state
        if state then
            task.spawn(function()
                local function ObterEventoMarretaao()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            if player.Character:FindFirstChild("BeastPowers") then
                                return player.Character:FindFirstChild("PowersEvent", true)
                            end
                        end
                    end
                    return nil
                end

                while getgenv().SlowBeastLigado do
                    local eventoPoderes = ObterEventoMarretaao()
                    if eventoPoderes and eventoPoderes:IsA("RemoteEvent") then
                        pcall(function()
                            eventoPoderes:FireServer("Jumped")
                        end)
                    end
                    task.wait(0.05) 
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Slow Runner Beast", false, function(state) 
        getgenv().SmartSlowBeastLigado = state
        if state then
            task.spawn(function()
                local energiaAnterior = 100
                local function ObterDadosDaFera()
                    if cachedPowersEvent and cachedPowersEvent.Parent and cachedStaminaValue and cachedStaminaValue.Parent then
                        return cachedPowersEvent, cachedStaminaValue
                    end
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local beastPowers = player.Character:FindFirstChild("BeastPowers")
                            if beastPowers then
                                local powersEvent = player.Character:FindFirstChild("PowersEvent", true)
                                local staminaValue = beastPowers:FindFirstChildOfClass("NumberValue")
                                
                                if powersEvent and staminaValue then
                                    cachedPowersEvent = powersEvent
                                    cachedStaminaValue = staminaValue
                                    return powersEvent, staminaValue
                                end
                            end
                        end
                    end
                    return nil, nil
                end
                while getgenv().SmartSlowBeastLigado do
                    local eventoPoderes, valorStamina = ObterDadosDaFera()
                    if eventoPoderes and valorStamina then
                        local energiaAtual = valorStamina.Value
                        if energiaAtual < energiaAnterior then
                            pcall(function()
                                eventoPoderes:FireServer("Jumped")
                            end)
                        end
                        energiaAnterior = energiaAtual
                    else
                        energiaAnterior = 100 
                    end
                    task.wait(0.05) 
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Touch Fling", false, function(state)
        getgenv().TouchFlingEnabled = state
        if state then
            task.spawn(function()
                local movel = 0.05
                while getgenv().TouchFlingEnabled do
                    RunService.Heartbeat:Wait()
                    local Character = LocalPlayer.Character
                    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                    if RootPart then
                        local oldVel = RootPart.Velocity
                        RootPart.Velocity = (oldVel * 9e8) + Vector3.new(0, 9e8, 0)
                        RunService.RenderStepped:Wait()
                        if RootPart then RootPart.Velocity = oldVel end
                        RunService.Stepped:Wait()
                        if RootPart then
                            RootPart.Velocity = oldVel + Vector3.new(0, movel, 0)
                            movel = movel * -1
                        end
                    end
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "No Hack Fail", false, function(state) 
        noHackFailEnabled = state
        getgenv().AutoAcertar = state
        if state then
            if noHackFailThread then task.cancel(noHackFailThread) end
            noHackFailThread = task.spawn(function()
                local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
                while getgenv().AutoAcertar do
                    task.wait(0.1) 
                    pcall(function()
                        if remoteEvent then
                            remoteEvent:FireServer("SetPlayerMinigameResult", true)
                        end
                    end)
                end
            end)
        else
            getgenv().AutoAcertar = false
            if noHackFailThread then task.cancel(noHackFailThread) noHackFailThread = nil end
        end
    end)

    Library:CreateToggle(Page, "Slow Beast Aura", false, function(state) 
        getgenv().AuraSlowBeastLigado = state
        if state then
            task.spawn(function()
                local function ObterDadosDaFera()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            if player.Character:FindFirstChild("BeastPowers") then
                                local powersEvent = player.Character:FindFirstChild("PowersEvent", true)
                                local feraHRP = player.Character:FindFirstChild("HumanoidRootPart")
                                if powersEvent and feraHRP then
                                    return powersEvent, feraHRP
                                end
                            end
                        end
                    end
                    return nil, nil
                end
                while getgenv().AuraSlowBeastLigado do
                    local meuPersonagem = LocalPlayer.Character
                    local meuHRP = meuPersonagem and meuPersonagem:FindFirstChild("HumanoidRootPart")
                    local eventoPoderes, feraHRP = ObterDadosDaFera()
                    if eventoPoderes and feraHRP and meuHRP then
                        local distancia = (meuHRP.Position - feraHRP.Position).Magnitude
                        if distancia <= slowBeastAuraRange then
                            pcall(function()
                                eventoPoderes:FireServer("Jumped")
                            end)
                        end
                    end
                    task.wait(0.05) 
                end
            end)
        end
    end)

    Library:CreateSlider(Page, "Slow Beast Aura Range", 5, 100, 15, function(val)
        slowBeastAuraRange = val
    end)

    Library:CreateSection(Page, "Beast")

    local cameraOriginal = LocalPlayer.CameraMode
    local beastCamInit = false

    Library:CreateToggle(Page, "Beast Camera Mode", false, function(state)
        getgenv().CamDModeEnabled = state
        if not state then
            pcall(function()
                local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                local isBeast = stats and stats:FindFirstChild("IsBeast")
                if isBeast and isBeast.Value == true then
                    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                else
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                end
            end)
        end
        
        if not beastCamInit then
            beastCamInit = true
            
            LocalPlayer.CharacterAdded:Connect(function()
                cameraOriginal = Enum.CameraMode.Classic
            end)
            
            LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(function()
                if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
                    cameraOriginal = Enum.CameraMode.LockFirstPerson
                elseif LocalPlayer.CameraMode == Enum.CameraMode.Classic and not getgenv().CamDModeEnabled then
                    cameraOriginal = Enum.CameraMode.Classic
                end
            end)
            
            task.spawn(function()
                while task.wait(0.1) do
                    if getgenv().CamDModeEnabled then
                        if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                            LocalPlayer.CameraMode = Enum.CameraMode.Classic
                        end
                    else
                        pcall(function()
                            local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                            local isBeast = stats and stats:FindFirstChild("IsBeast")
                            if isBeast and isBeast.Value == true then
                                if LocalPlayer.CameraMode ~= Enum.CameraMode.LockFirstPerson then
                                    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                                end
                            end
                        end)
                    end
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Crawl Beast", false, function(state)
        getgenv().AutoCrawlLigado = state
        if state then
            task.spawn(function()
                local function RemoverVentBlocks()
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and obj.Name == "VentBlock" then
                            obj.CFrame = CFrame.new(0, -10000, 0)
                            obj.CanCollide = false
                            pcall(function() obj:Destroy() end)
                        end
                    end
                end
                while getgenv().AutoCrawlLigado do
                    pcall(function()
                        local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                        if stats then
                            local isBeast = stats:FindFirstChild("IsBeast")
                            local disableCrawl = stats:FindFirstChild("DisableCrawl")
                            if isBeast and isBeast.Value == true then
                                if disableCrawl and disableCrawl.Value == true then
                                    disableCrawl.Value = false
                                    RemoverVentBlocks()
                                end
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
        else
            pcall(function()
                local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                if stats then
                    local isBeast = stats:FindFirstChild("IsBeast")
                    local disableCrawl = stats:FindFirstChild("DisableCrawl")
                    if isBeast and isBeast.Value == true then
                        if disableCrawl then
                            disableCrawl.Value = true
                        end
                    end
                end
            end)
        end
    end)

    local autoTieCrosshairEnabled = false
    local lookSensitivity = 0.85
    local function EstaOlhandoPara(raizAlvo)
        if not Camera or not raizAlvo then return false end
        local direcaoParaAlvo = (raizAlvo.Position - Camera.CFrame.Position).Unit
        local direcaoOlhar = Camera.CFrame.LookVector
        local dotProduct = direcaoOlhar:Dot(direcaoParaAlvo)
        return dotProduct >= lookSensitivity
    end

    Library:CreateToggle(Page, "Auto Tie at Crosshair", false, function(state)
        autoTieCrosshairEnabled = state
        if state then
            task.spawn(function()
                local function ObterRaiz(character)
                    if not character then return nil end
                    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                end
                while autoTieCrosshairEnabled do
                    task.wait(0.1) 
                    pcall(function()
                        local MeuPersonagem = LocalPlayer.Character
                        if not MeuPersonagem then return end
                        local MeuEventoMarreta = MeuPersonagem:FindFirstChild("HammerEvent", true)
                        local MinhaRaiz = ObterRaiz(MeuPersonagem)
                        if not MeuEventoMarreta or not MinhaRaiz then return end

                        for _, alvo in ipairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                                local Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                if Stats then
                                    local alvoCaido = Stats:FindFirstChild("Ragdoll")
                                    local alvoCapturado = Stats:FindFirstChild("Captured")
                                    if alvoCaido and alvoCapturado then
                                        if alvoCaido.Value == true and alvoCapturado.Value == false then
                                            local RaizAlvo = ObterRaiz(alvo.Character)
                                            if RaizAlvo then
                                                local distancia = (RaizAlvo.Position - MinhaRaiz.Position).Magnitude
                                                if distancia <= autoTieDistancia and EstaOlhandoPara(RaizAlvo) then
                                                    MeuEventoMarreta:FireServer("HammerTieUp", RaizAlvo, RaizAlvo.Position)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end)

    local autoTieAfterHit = false
    Library:CreateToggle(Page, "Auto Tie After Hit", false, function(state)
        autoTieAfterHit = state
        if state then
            task.spawn(function()
                local function ObterRaiz(character)
                    if not character then return nil end
                    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                end
                local JaAmarrados = {}
                while autoTieAfterHit do
                    task.wait(0.05)
                    pcall(function()
                        local MeuPersonagem = LocalPlayer.Character
                        local MeuEventoMarreta = MeuPersonagem and MeuPersonagem:FindFirstChild("HammerEvent", true)
                        local MinhaRaiz = ObterRaiz(MeuPersonagem)
                        if not MeuEventoMarreta or not MinhaRaiz then return end

                        for _, alvo in ipairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                                local Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                if Stats then
                                    local alvoCaido = Stats:FindFirstChild("Ragdoll")
                                    local alvoCapturado = Stats:FindFirstChild("Captured")
                                    if alvoCaido and alvoCapturado then
                                        if alvoCaido.Value == true and alvoCapturado.Value == false then
                                            if not JaAmarrados[alvo.Name] then
                                                local RaizAlvo = ObterRaiz(alvo.Character)
                                                if RaizAlvo then
                                                    local distancia = (RaizAlvo.Position - MinhaRaiz.Position).Magnitude
                                                    if distancia <= 15 then
                                                        MeuEventoMarreta:FireServer("HammerTieUp", RaizAlvo, RaizAlvo.Position)
                                                        JaAmarrados[alvo.Name] = true
                                                    end
                                                end
                                            end
                                        else
                                            if alvoCaido.Value == false then
                                                JaAmarrados[alvo.Name] = false
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end)

    Library:CreateToggleKeybind(Page, "No Jump Delay", false, "None", function(state) 
        njdEnabledLocal = state
        if state then
            if LocalPlayer.Character then bindNJDLocal(LocalPlayer.Character) end
            if not njdCharAdded then
                njdCharAdded = LocalPlayer.CharacterAdded:Connect(function(c) bindNJDLocal(c) end)
            end
        else
            if njdConnectionLocal then 
                njdConnectionLocal:Disconnect() 
                njdConnectionLocal = nil 
            end
            if njdCharAdded then
                njdCharAdded:Disconnect()
                njdCharAdded = nil
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = checkNJD(LocalPlayer.Character) and 16.5 or 16
            end
        end
    end)

    Library:CreateToggle(Page, "Auto Tie Aura", false, function(state)
        getgenv().AutoTieLigado = state
        if state then
            task.spawn(function()
                local function ObterRaiz(character)
                    if not character then return nil end
                    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                end

                while getgenv().AutoTieLigado do
                    task.wait(0.15) 
                    pcall(function()
                        local MeuPersonagem = LocalPlayer.Character
                        if not MeuPersonagem then return end
                        
                        local MeuEventoMarreta = MeuPersonagem:FindFirstChild("HammerEvent", true)
                        local MinhaRaiz = ObterRaiz(MeuPersonagem)
                        
                        if not MeuEventoMarreta or not MinhaRaiz then return end

                        for _, alvo in ipairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                               _G.Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                local Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                if Stats then
                                    local alvoCaido = Stats:FindFirstChild("Ragdoll")
                                    local alvoCapturado = Stats:FindFirstChild("Captured")
                                    
                                    if alvoCaido and alvoCapturado then
                                        if alvoCaido.Value == true and alvoCapturado.Value == false then
                                            local RaizAlvo = ObterRaiz(alvo.Character)
                                            if RaizAlvo then
                                                local distancia = (RaizAlvo.Position - MinhaRaiz.Position).Magnitude
                                                if distancia <= autoTieDistancia then
                                                    MeuEventoMarreta:FireServer("HammerTieUp", RaizAlvo, RaizAlvo.Position)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end)

    Library:CreateSlider(Page, "Auto Tie Range", 5, 30, 15, function(val)
        autoTieDistancia = val
    end)

    local runnerSpeedBoostEnabled = false
    local runnerSpeedVal = 26
    local conexaoRunnerBoost = nil
    Library:CreateToggle(Page, "Runner Speed Boost", false, function(state)
        runnerSpeedBoostEnabled = state
        if state then
            local ultimaEnergia = 1
            if conexaoRunnerBoost then conexaoRunnerBoost:Disconnect() end
            conexaoRunnerBoost = RunService.Stepped:Connect(function()
                pcall(function()
                    if localCharacter then
                        local beastPowers = localCharacter:FindFirstChild("BeastPowers")
                        if not beastPowers then return end
                        local numberValue = beastPowers:FindFirstChildOfClass("NumberValue")
                        if not numberValue then return end
                        local energiaAtual = numberValue.Value
                        
                        if energiaAtual < ultimaEnergia and localHumanoid then
                            localHumanoid.WalkSpeed = runnerSpeedVal
                        end
                        ultimaEnergia = energiaAtual
                    end
                end)
            end)
        else
            if conexaoRunnerBoost then
                conexaoRunnerBoost:Disconnect()
                conexaoRunnerBoost = nil
            end
        end
    end)

    Library:CreateSlider(Page, "Runner Speed Boost Val", 16, 50, 26, function(val)
        runnerSpeedVal = val
    end)

    Library:CreateToggle(Page, "Hit Aura", false, function(state)
        getgenv().HitAuraAtivo = state
        if state then
            task.spawn(function()
                local function getRoot(character)
                    if not character then return nil end
                    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                end

                while getgenv().HitAuraAtivo do
                    task.wait(0.15) 

                    local meChar = LocalPlayer.Character
                    local meRoot = getRoot(meChar)

                    if not meChar or not meRoot then continue end

                    local HammerEvent = meChar:FindFirstChild("HammerEvent", true)
                    if not HammerEvent then continue end

                    for _, alvo in ipairs(Players:GetPlayers()) do
                        if alvo ~= LocalPlayer then
                            local stats = alvo:FindFirstChild("TempPlayerStatsModule")
                            if not stats then continue end
                            
                            local isRagdoll = stats:FindFirstChild("Ragdoll")
                            local isCaptured = stats:FindFirstChild("Captured")
                            
                            if isRagdoll and isCaptured then
                                if not isRagdoll.Value and not isCaptured.Value then
                                    local alvoChar = alvo.Character
                                    local alvoRoot = getRoot(alvoChar)
                                    
                                    if alvoRoot then
                                        local distanciaAtual = (alvoRoot.Position - meRoot.Position).Magnitude
                                        if distanciaAtual <= hitAuraRange then
                                            HammerEvent:FireServer("HammerHit", alvoRoot)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    Library:CreateSlider(Page, "Hit Aura Range", 5, 15, 10, function(val)
        hitAuraRange = val
    end)

    Library:CreateToggle(Page, "Hitbox Extender", false, function(state) 
        hbEnabled = state
        if state then 
            hbLoop = task.spawn(function()
                while hbEnabled do
                    updateHitboxes()
                    task.wait(1)
                end
            end)
        else 
            if hbLoop then task.cancel(hbLoop) hbLoop = nil end
            for _, v in ipairs(Players:GetPlayers()) do 
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then 
                    v.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                    v.Character.HumanoidRootPart.Transparency = 1
                    v.Character.HumanoidRootPart.CanCollide = true 
                end 
            end 
        end 
    end)

    Library:CreateSlider(Page, "Hitbox X", 2, 10, 2, function(val)
        hbSizeX = val
        updateTargetHitboxSize()
    end)

    Library:CreateSlider(Page, "Hitbox Y", 2, 10, 2, function(val)
        hbSizeY = val
        updateTargetHitboxSize()
    end)

    Library:CreateSlider(Page, "Hitbox Z", 2, 10, 2, function(val)
        hbSizeZ = val
        updateTargetHitboxSize()
    end)

    Library:CreateToggle(Page, "Show Hitbox", false, function(state)
        hbShowVisual = state
    end)

    Library:CreateSection(Page, "Players Pt. 1")

    local emotesTable = {
        ["Dance 1"] = {R6 = "27789359", R15 = "3333432454"},
        ["Dance 2"] = {R6 = "30196114", R15 = "4555808220"},
        ["Dance 3"] = {R6 = "248263260", R15 = "4049037604"},
        ["Dance 4"] = {R6 = "45834924", R15 = "4555782893"},
        ["Dance 5"] = {R6 = "33796059", R15 = "10214311282"},
        ["Dance 6"] = {R6 = "28488254", R15 = "10714010337"},
        ["Wave"]    = {R6 = "128777973", R15 = "507722262"},
        ["Cheer"]   = {R6 = "129423030", R15 = "507710771"}
    }
    local currentTrack = nil
    local function stopActiveEmote()
        if currentTrack then
            currentTrack:Stop()
            currentTrack:Destroy()
            currentTrack = nil
        end
    end
    local function isR15(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        return humanoid and humanoid.RigType == Enum.HumanoidRigType.R15
    end
    local function playEmote(id)
        stopActiveEmote()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. id
        local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
        local success, track = pcall(function()
            return animator:LoadAnimation(animation)
        end)
        if success and track then
            currentTrack = track
            currentTrack:Play()
        end
    end

    Library:CreateDropdown(Page, "Emotes", {"None", "Dance 1", "Dance 2", "Dance 3", "Dance 4", "Dance 5", "Dance 6", "Wave", "Cheer"}, "None", function(val)
        if val == "None" then
            stopActiveEmote()
        else
            local data = emotesTable[val]
            if data then
                local char = LocalPlayer.Character
                if char then
                    if isR15(char) then
                        playEmote(data.R15)
                    else
                        playEmote(data.R6)
                    end
                end
            end
        end
    end)

    local wsCharAdded
    Library:CreateToggleKeybind(Page, "Walkspeed", false, "None", function(state) 
        wsEnabled = state 
        if state then
            if LocalPlayer.Character then BackupSpeed(LocalPlayer.Character) end
            if not wsRunConnection then
                wsRunConnection = RunService.Stepped:Connect(function()
                    if wsEnabled and localHumanoid and localHumanoid.Parent then
                        if not originalWS[localCharacter] then BackupSpeed(localCharacter) end
                        localHumanoid.WalkSpeed = wsValue
                    end
                end)
            end
            if not wsCharAdded then
                wsCharAdded = LocalPlayer.CharacterAdded:Connect(function(char)
                    char:WaitForChild("Humanoid", 5)
                    if wsEnabled then BackupSpeed(char) end
                end)
            end
        else
            if wsRunConnection then wsRunConnection:Disconnect() wsRunConnection = nil end
            if wsCharAdded then wsCharAdded:Disconnect() wsCharAdded = nil end
            if LocalPlayer.Character then RestoreSpeed(LocalPlayer.Character) end
        end
    end)

    Library:CreateSlider(Page, "Speed Value", 16, 200, 16, function(val) wsValue = val end)

    local jpCharAdded
    Library:CreateToggleKeybind(Page, "Jump Power", false, "None", function(state) 
        jpEnabled = state 
        if state then
            if LocalPlayer.Character then BackupJump(LocalPlayer.Character) end
            if not jpRunConnection then
                jpRunConnection = RunService.Stepped:Connect(function()
                    if jpEnabled and localHumanoid and localHumanoid.Parent then
                        if not originalJP[localCharacter] then BackupJump(localCharacter) end
                        localHumanoid.UseJumpPower = true
                        localHumanoid.JumpPower = jpVal
                        localHumanoid.JumpHeight = jpVal / 2
                    end
                end)
            end
            if not jpCharAdded then
                jpCharAdded = LocalPlayer.CharacterAdded:Connect(function(char)
                    char:WaitForChild("Humanoid", 5)
                    if jpEnabled then BackupJump(char) end
                end)
            end
        else
            if jpRunConnection then jpRunConnection:Disconnect() jpRunConnection = nil end
            if jpCharAdded then jpCharAdded:Disconnect() jpCharAdded = nil end
            if LocalPlayer.Character then RestoreJump(LocalPlayer.Character) end
        end
    end)

    Library:CreateSlider(Page, "Jump Power Val", 50, 300, 120, function(val) jpVal = val end)

    local flyConnection
    local flyCharAdded
    Library:CreateToggleKeybind(Page, "Fly", false, "None", function(state) 
        flyEnabled = state
        
        local function setupFly(char)
            if not char then return end
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            local hum = char:WaitForChild("Humanoid", 5)
            if not hrp or not hum then return end
            
            if flyEnabled then
                hum.PlatformStand = true
                if flyBg then flyBg:Destroy() end
                if flyBv then flyBv:Destroy() end
                
                flyBg = Instance.new("BodyGyro", hrp)
                flyBg.P = 9e4
                flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyBg.CFrame = hrp.CFrame
                flyBv = Instance.new("BodyVelocity", hrp)
                flyBv.Velocity = Vector3.new(0, 0, 0)
                flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            end
        end

        if state then
            setupFly(LocalPlayer.Character)
            if not flyCharAdded then
                flyCharAdded = LocalPlayer.CharacterAdded:Connect(setupFly)
            end
            if not flyConnection then
                flyConnection = RunService.RenderStepped:Connect(function()
                    if flyEnabled and flyBg and flyBv and localHrp and localHumanoid and localHumanoid.Parent then
                        localHumanoid.PlatformStand = true
                        flyBg.CFrame = CFrame.new(localHrp.Position, localHrp.Position + Camera.CFrame.LookVector)
                        local moveDir = localHumanoid.MoveDirection
                        if moveDir.Magnitude > 0 then
                            local camLook = Camera.CFrame.LookVector
                            local camRight = Camera.CFrame.RightVector
                            local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
                            local flatRight = Vector3.new(camRight.X, 0, camRight.Z).Unit
                            local forwardInput = moveDir:Dot(flatLook)
                            local rightInput = moveDir:Dot(flatRight)
                            local flyVelocity = (Camera.CFrame.LookVector * forwardInput) + (Camera.CFrame.RightVector * rightInput)
                            flyBv.Velocity = flyVelocity.Unit * flySpeed
                        else
                            flyBv.Velocity = Vector3.new(0, 0, 0)
                        end
                    end
                end)
            end
        else
            if flyConnection then flyConnection:Disconnect() flyConnection = nil end
            if flyCharAdded then flyCharAdded:Disconnect() flyCharAdded = nil end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then 
                LocalPlayer.Character.Humanoid.PlatformStand = false 
            end
            if flyBg then flyBg:Destroy() flyBg = nil end
            if flyBv then flyBv:Destroy() flyBv = nil end
        end
    end)

    Library:CreateSlider(Page, "Fly Speed", 10, 200, 50, function(val) flySpeed = val end)

    local crawlBoostEnabled = false
    local crawlBoostSpeed = 6
    local crawlConnection = nil
    Library:CreateToggle(Page, "Crawl Boost", false, function(state)
        crawlBoostEnabled = state
        if state then
            if crawlConnection then crawlConnection:Disconnect() end
            crawlConnection = RunService.RenderStepped:Connect(function()
                if localHumanoid and localHumanoid.Parent then
                    if localHumanoid.WalkSpeed > 1 and localHumanoid.WalkSpeed < 11 then
                        localHumanoid.WalkSpeed = crawlBoostSpeed
                    end
                end
            end)
        else
            if crawlConnection then
                crawlConnection:Disconnect()
                crawlConnection = nil
            end
        end
    end)

    Library:CreateSlider(Page, "Crawl Boost Val", 1, 50, 6, function(val)
        crawlBoostSpeed = val
    end)

    Library:CreateSection(Page, "Players Pt. 2")

    local fdjConnection = nil
    Library:CreateToggle(Page, "Fast Double Jump", false, function(state)
        local P = game:GetService("Players")
        local U = game:GetService("UserInputService")
        local R = game:GetService("RunService")
        local D = game:GetService("Debris")
        local plr = P.LocalPlayer
        if state then
            local CD = 0.6
            local JP = 36

            if getgenv().ConexoesFTF then
                for _,c in ipairs(getgenv().ConexoesFTF)do pcall(function()c:Disconnect()end) end
            end
            getgenv().ConexoesFTF={}

            if getgenv().PulosOriginais then
                for _,x in ipairs(getgenv().PulosOriginais)do pcall(function()x:Enable()end) end
            end
            getgenv().PulosOriginais={}

            local function killJump(c)
                if not getconnections then return end
                for _,x in ipairs(getconnections(U.JumpRequest))do
                    pcall(function()
                        local f=x.Function
                        if type(f)=="function"then
                            local e=getfenv(f)
                            if e.script and e.script:IsDescendantOf(c)then
                                table.insert(getgenv().PulosOriginais,x)
                                x:Disable()
                            end
                        end
                    end)
                end
            end

            local function cloud(r)
                if not r then return end
                local p=Instance.new("Part")
                p.Transparency=1
                p.Size=Vector3.new(.1,.1,.1)
                p.CanCollide=false
                p.Massless=true
                p.Anchored=true
                p.CFrame=CFrame.new(r.Position.X,r.Position.Y-3.2,r.Position.Z)*r.CFrame.Rotation
                p.Parent=workspace

                local pe=Instance.new("ParticleEmitter")
                pe.LightInfluence=0
                pe.Brightness=2
                pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.6),NumberSequenceKeypoint.new(.05,1.2),NumberSequenceKeypoint.new(1,.4)})
                pe.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.7,0),NumberSequenceKeypoint.new(1,1)})
                pe.EmissionDirection=Enum.NormalId.Front
                pe.Lifetime=NumberRange.new(.3)
                pe.Rate=0
                pe.Speed=NumberRange.new(12)
                pe.Acceleration=Vector3.new(0,4,0)
                pe.SpreadAngle=Vector2.new(0,180)
                pe.Shape=Enum.ParticleEmitterShape.Disc
                pe.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
                pe.LockedToPart=true
                pe.Parent=p
                pe:Emit(24)
                D:AddItem(p,.5)
            end

            local function spark(c)
                if not c then return end
                local g=c:FindFirstChild("PackedGemstone")
                local a=(g and g:FindFirstChild("Handle")) or c:FindFirstChild("Right Arm")
                if not a then return end

                local p=Instance.new("Part")
                p.Transparency=1
                p.Size=Vector3.new(.1,.1,.1)
                p.CanCollide=false
                p.Massless=true
                p.Parent=workspace

                local w=Instance.new("Weld")
                w.Part0=p
                w.Part1=a
                w.C0=g and CFrame.new() or CFrame.new(.4,.6,.7)
                w.Parent=p

                local pe=Instance.new("ParticleEmitter")
                pe.LightInfluence=0
                pe.Brightness=2
                pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.1,.6),NumberSequenceKeypoint.new(1,0)})
                pe.EmissionDirection=Enum.NormalId.Top
                pe.Lifetime=NumberRange.new(.8)
                pe.Rate=0
                pe.RotSpeed=NumberRange.new(270)
                pe.Speed=NumberRange.new(0)
                pe.Shape=g and Enum.ParticleEmitterShape.Disc or Enum.ParticleEmitterShape.Sphere
                pe.ShapeStyle=g and Enum.ParticleEmitterShapeStyle.Surface or Enum.ParticleEmitterShapeStyle.Volume
                pe.LockedToPart=true
                pe.Parent=p

                pe:Emit(1)
                D:AddItem(p,1)
            end

            local function start(c)
                task.spawn(function()
                    task.wait(1)
                    killJump(c)
                end)

                local h=c:WaitForChild("Humanoid",5)
                local r=c:WaitForChild("HumanoidRootPart",5)
                if not h or not r then return end

                local air=true
                local lj=0
                local ld=0
                local cd=false
                local j=false

                local hb=R.Heartbeat:Connect(function()
                    if not h or not h.Parent then return end
                    if j and not h.Jump then lj=time() end
                    if cd and time()-ld>=CD then
                        cd=false
                        task.spawn(function()spark(c)end)
                    end
                    j=h.Jump
                end)
                table.insert(getgenv().ConexoesFTF,hb)

                local st=h.StateChanged:Connect(function(_,n)
                    if n==Enum.HumanoidStateType.Landed and not h.Jump then
                        air=true
                    end
                end)
                table.insert(getgenv().ConexoesFTF,st)

                local jm=U.JumpRequest:Connect(function()
                    if not h or not r or not r.Parent then return end

                        local p=RaycastParams.new()
                        p.FilterType=Enum.RaycastFilterType.Exclude
                        p.FilterDescendantsInstances={c}
                        p.RespectCanCollide=true
                        pcall(function()p.CollisionGroup="PLAYERS_BODIES"end)

                        local d=16
                        local ok,hit=pcall(function()
                            return workspace:Blockcast(r.CFrame,Vector3.new(2.2,2,1.4),Vector3.new(0,-16,0),p)
                        end)
                        if ok and hit then d=hit.Distance end

                        local s=h:GetState()

                        if air and d>3.5 and r.AssemblyLinearVelocity.Y<16
                        and s==Enum.HumanoidStateType.Freefall
                        and h.FloorMaterial==Enum.Material.Air
                        and time()-lj>=.05
                        and time()-ld>=CD then

                            air=false
                            r.AssemblyLinearVelocity=Vector3.new(0,JP,0)
                            ld=time()
                            cd=true
                            cloud(r)
                        end
                end)
                table.insert(getgenv().ConexoesFTF,jm)
            end

            if plr.Character then start(plr.Character) end
            fdjConnection = plr.CharacterAdded:Connect(function(c)
                start(c)
            end)
            table.insert(getgenv().ConexoesFTF, fdjConnection)
        else
            if fdjConnection then fdjConnection:Disconnect(); fdjConnection = nil end
            if getgenv().ConexoesFTF then
                for _,c in ipairs(getgenv().ConexoesFTF)do pcall(function()c:Disconnect()end) end
            end
            getgenv().ConexoesFTF={}

            if getgenv().PulosOriginais then
                for _,x in ipairs(getgenv().PulosOriginais)do pcall(function()x:Enable()end) end
            end
            getgenv().PulosOriginais={}
        end
    end)

    local noclipConnection
    Library:CreateToggleKeybind(Page, "Noclip", false, "None", function(state) 
        if state then
            if not noclipConnection then
                noclipConnection = RunService.Stepped:Connect(function()
                    if LocalPlayer.Character then
                        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
        end
    end)

    local slCharAdded
    Library:CreateToggleKeybind(Page, "ShiftLock", false, "None", function(state)
        shiftlockEnabled = state
        if state then
            if not ShiftLockCrosshair then
                ShiftLockCrosshair = Instance.new("ImageLabel")
                ShiftLockCrosshair.Name = "ShiftLockCrosshair"
                ShiftLockCrosshair.AnchorPoint = Vector2.new(0.5, 0.5)
                ShiftLockCrosshair.Position = UDim2.new(0.5, 0, 0.5, -29)
                ShiftLockCrosshair.Size = UDim2.new(0.04, 0, 0.04, 0) 
                ShiftLockCrosshair.BackgroundTransparency = 1
                ShiftLockCrosshair.Image = "rbxasset://textures/MouseLockedCursor.png"
                ShiftLockCrosshair.Visible = true
                ShiftLockCrosshair.ZIndex = 10
                local aspect = Instance.new("UIAspectRatioConstraint")
                aspect.AspectRatio = 1
                aspect.Parent = ShiftLockCrosshair
                local sg = CoreGui:FindFirstChild("NexVoidHub") or LocalPlayer.PlayerGui:FindFirstChild("NexVoidHub")
                ShiftLockCrosshair.Parent = sg 
            else
                ShiftLockCrosshair.Visible = true
            end
            RunService:BindToRenderStep("FinalNailSync", Enum.RenderPriority.Camera.Value + 1, enforceOfficialSync)
            
            if not slCharAdded then
                slCharAdded = LocalPlayer.CharacterAdded:Connect(function(c)
                    if shiftlockEnabled then
                        RunService:UnbindFromRenderStep("FinalNailSync")
                        task.wait(0.000005)
                        RunService:BindToRenderStep("FinalNailSync", Enum.RenderPriority.Camera.Value + 1, enforceOfficialSync)
                    end
                end)
            end
        else
            if ShiftLockCrosshair then ShiftLockCrosshair.Visible = false end
            RunService:UnbindFromRenderStep("FinalNailSync")
            if slCharAdded then slCharAdded:Disconnect() slCharAdded = nil end
            
            pcall(function()
                if userGameSettings then
                    userGameSettings.RotationType = Enum.RotationType.MovementRelative
                end
            end)
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    Library:CreateToggle(Page, "Inf Jump", false, function(state)
        infJumpEnabled = state
        if state then
            if not infJumpConnection then
                infJumpConnection = RunService.Heartbeat:Connect(function()
                    if infJumpEnabled and localHumanoid and localHrp and localHumanoid.Parent then
                        local isHoldingJump = UserInputService:IsKeyDown(Enum.KeyCode.Space) or localHumanoid.Jump
                        if isHoldingJump then
                            local jumpPowerValue = 50
                            if localHumanoid.UseJumpPower then
                                jumpPowerValue = localHumanoid.JumpPower
                            else
                                jumpPowerValue = math.sqrt(2 * Workspace.Gravity * localHumanoid.JumpHeight)
                            end
                            local currentVel = localHrp.AssemblyLinearVelocity
                            localHrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, jumpPowerValue, currentVel.Z)
                        end
                    end
                end)
            end
        else
            if infJumpConnection then
                infJumpConnection:Disconnect()
                infJumpConnection = nil
            end
        end
    end)
end
