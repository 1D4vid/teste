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
    local hbEnabled = false
    local hbShowVisual = false
    local hbSize = 2
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
        for _,x in pairs(getconnections(UserInputService.JumpRequest))do
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
        for _, x in pairs(disabledJumpConns) do
            pcall(function() x:Enable() end)
        end
        table.clear(disabledJumpConns)
    end
    
    local function enforceOfficialSync()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = Workspace.CurrentCamera
        if not hum then return end
        if not userGameSettings then pcall(function() userGameSettings = UserSettings():GetService("UserGameSettings") end) end
        if userGameSettings then
            if userGameSettings.RotationType ~= Enum.RotationType.CameraRelative then
                pcall(function() userGameSettings.RotationType = Enum.RotationType.CameraRelative end)
            end
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        local dist = (cam.Focus.Position - cam.CFrame.Position).Magnitude
        if dist > 1 then 
            local rawCFrame = cam.CFrame
            cam.CFrame = rawCFrame * CFrame.new(1.75, 0, 0)
            cam.Focus = cam.CFrame * CFrame.new(0, 0, -dist)
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
    
    local function updateHitboxes()
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = v.Character.HumanoidRootPart
                local targetSize = Vector3.new(hbSize, hbSize, hbSize)
                if hrp.Size ~= targetSize then hrp.Size = targetSize end
                local targetTrans = hbShowVisual and 0.6 or 1
                if hrp.Transparency ~= targetTrans then hrp.Transparency = targetTrans end
                hrp.CanCollide = false
            end
        end
    end

    Library:CreateSection(Page, "Survivor")

    Library:CreateToggle(Page, "Beast Untie Player", false, function(state)
        getgenv().BeastUntieLigado = state
        if state then
            task.spawn(function()
                local function ObterEventoMarreta()
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            if player.Character:FindFirstChild("Hammer") then
                                return player.Character:FindFirstChild("HammerEvent", true)
                            end
                        end
                    end
                    return nil
                end

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
        getgenv().AntiRagdollV2 = state
        if state then
            task.spawn(function()
                while getgenv().AntiRagdollV2 do
                    task.wait()
                    pcall(function()
                        local Character = LocalPlayer.Character
                        local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
                        if Humanoid then
                            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                            Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                            Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                            
                            local currentState = Humanoid:GetState()
                            if currentState == Enum.HumanoidStateType.Ragdoll or currentState == Enum.HumanoidStateType.Physics or currentState == Enum.HumanoidStateType.PlatformStanding then
                                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                            end
                        end
                        
                        local Stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                        if Stats then
                            local Ragdoll = Stats:FindFirstChild("Ragdoll")
                            if Ragdoll and Ragdoll.Value then
                                Ragdoll.Value = false
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
                    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Slow Beast", false, function(state)
        getgenv().SlowBeastLigado = state
        if state then
            task.spawn(function()
                local function ObterEventoMarretaao()
                    for _, player in pairs(Players:GetPlayers()) do
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
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local beastPowers = player.Character:FindFirstChild("BeastPowers")
                            if beastPowers then
                                local powersEvent = player.Character:FindFirstChild("PowersEvent", true)
                                local staminaValue = beastPowers:FindFirstChildOfClass("NumberValue")
                                if powersEvent and staminaValue then
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

    Library:CreateSlider(Page, "Slow Beast Aura Range", 5, 30, 15, function(val)
        slowBeastAuraRange = val
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

    Library:CreateSection(Page, "Beast")

    local cameraOriginal = LocalPlayer.CameraMode
    local beastCamInit = false

    Library:CreateToggle(Page, "Beast Camera Mode", false, function(state)
        getgenv().CamDModeEnabled = state
        
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
                        if LocalPlayer.CameraMode ~= cameraOriginal then
                            LocalPlayer.CameraMode = cameraOriginal
                        end
                    end
                end
            end)
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

                        for _, alvo in pairs(Players:GetPlayers()) do
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

    local originalHipHeight = nil
    Library:CreateToggle(Page, "Crawl Beast", false, function(state)
        getgenv().CrawlBeast = state
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if state then
                    originalHipHeight = hum.HipHeight
                    hum.HipHeight = -1.2
                else
                    hum.HipHeight = originalHipHeight or 0
                end
            end
        end)
    end)

    local runnerSpeedBoostEnabled = false
    Library:CreateToggle(Page, "Runner Speed Boost", false, function(state)
        runnerSpeedBoostEnabled = state
        if state then
            task.spawn(function()
                while runnerSpeedBoostEnabled do
                    task.wait(0.1)
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if char and (char:FindFirstChild("BeastPowers") or char:FindFirstChild("Hammer")) then
                            if hum and hum.WalkSpeed < 24 then
                                hum.WalkSpeed = 24
                            end
                        end
                    end)
                end
            end)
        end
    end)

    local autoTieCrosshairEnabled = false
    Library:CreateToggle(Page, "Auto Tie at Crosshair", false, function(state)
        autoTieCrosshairEnabled = state
        if state then
            task.spawn(function()
                while autoTieCrosshairEnabled do
                    task.wait(0.15)
                    pcall(function()
                        local char = LocalPlayer.Character
                        if not char then return end
                        local hammerEvent = char:FindFirstChild("HammerEvent", true)
                        local myRoot = char:FindFirstChild("HumanoidRootPart")
                        if not hammerEvent or not myRoot then return end

                        local cam = Workspace.CurrentCamera
                        local bestTarget = nil
                        local minAngle = math.huge

                        for _, target in pairs(Players:GetPlayers()) do
                            if target ~= LocalPlayer and target.Character then
                                local stats = target:FindFirstChild("TempPlayerStatsModule")
                                if stats then
                                    local ragdoll = stats:FindFirstChild("Ragdoll")
                                    local captured = stats:FindFirstChild("Captured")
                                    if ragdoll and captured and ragdoll.Value == true and captured.Value == false then
                                        local tRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
                                        if tRoot then
                                            local dist = (tRoot.Position - myRoot.Position).Magnitude
                                            if dist <= autoTieDistancia then
                                                local screenPos, onScreen = cam:WorldToViewportPoint(tRoot.Position)
                                                if onScreen then
                                                    local center = cam.ViewportSize / 2
                                                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                                    if screenDist < minAngle then
                                                        minAngle = screenDist
                                                        bestTarget = tRoot
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        if bestTarget then
                            hammerEvent:FireServer("HammerTieUp", bestTarget, bestTarget.Position)
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
                while autoTieAfterHit do
                    RunService.Heartbeat:Wait()
                    pcall(function()
                        local char = LocalPlayer.Character
                        if not char then return end
                        local hammerEvent = char:FindFirstChild("HammerEvent", true)
                        local myRoot = char:FindFirstChild("HumanoidRootPart")
                        if not hammerEvent or not myRoot then return end

                        for _, target in pairs(Players:GetPlayers()) do
                            if target ~= LocalPlayer and target.Character then
                                local stats = target:FindFirstChild("TempPlayerStatsModule")
                                if stats then
                                    local ragdoll = stats:FindFirstChild("Ragdoll")
                                    local captured = stats:FindFirstChild("Captured")
                                    if ragdoll and captured and ragdoll.Value == true and captured.Value == false then
                                        local tRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
                                        if tRoot then
                                            local dist = (tRoot.Position - myRoot.Position).Magnitude
                                            if dist <= 8 then
                                                hammerEvent:FireServer("HammerTieUp", tRoot, tRoot.Position)
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

                    for _, alvo in pairs(Players:GetPlayers()) do
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
            for _, v in pairs(Players:GetPlayers()) do 
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then 
                    v.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                    v.Character.HumanoidRootPart.Transparency = 1
                    v.Character.HumanoidRootPart.CanCollide = true 
                end 
            end 
        end 
    end)
    Library:CreateInput(Page, "Hitbox Size", 2, function(val) hbSize = tonumber(val) or 2 end)
    Library:CreateToggle(Page, "Show Hitbox", false, function(state)
        hbShowVisual = state
    end)

    local njdEnabledLocal = false
    local njdConnectionLocal = nil
    local njdBackupSpeed = 16
    local njdCharAdded = nil
    local function checkNJD(c)
        if not c then return false end
        if c:FindFirstChildOfClass("Tool") then return true end
        if c:FindFirstChild("Hammer") then return true end
        return false
    end
    local function bindNJDLocal(c)
        local h = c:WaitForChild("Humanoid", 5)
        if not h then return end
        njdBackupSpeed = checkNJD(c) and 16.5 or 16
        njdConnectionLocal = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if njdEnabledLocal and h.WalkSpeed < njdBackupSpeed and checkNJD(c) then
                h.WalkSpeed = njdBackupSpeed
            end
        end)
    end

    Library:CreateToggle(Page, "No Jump Delay", false, function(state) 
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

    Library:CreateSection(Page, "Players Pt. 1")

    local fdjConnection = nil
    local disabledScripts = {}

    local function disableOriginalDoubleJump(c)
        for _, scr in ipairs(c:GetDescendants()) do
            if scr:IsA("LocalScript") and (scr.Name == "DoubleJump" or scr.Name:lower():find("doublejump")) then
                scr.Disabled = true
                disabledScripts[scr] = true
            end
        end
    end

    local function restoreOriginalDoubleJump()
        for scr, _ in pairs(disabledScripts) do
            pcall(function()
                if scr and scr.Parent then
                    scr.Disabled = false
                end
            end)
        end
        table.clear(disabledScripts)
    end

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
                for _,c in pairs(getgenv().ConexoesFTF)do pcall(function()c:Disconnect()end) end
            end
            getgenv().ConexoesFTF={}

            if getgenv().PulosOriginais then
                for _,x in pairs(getgenv().PulosOriginais)do pcall(function()x:Enable()end) end
            end
            getgenv().PulosOriginais={}

            local function killJump(c)
                if not getconnections then return end
                for _,x in pairs(getconnections(U.JumpRequest))do
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
                    task.wait(0.5)
                    killJump(c)
                    disableOriginalDoubleJump(c)
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
                for _,c in pairs(getgenv().ConexoesFTF)do pcall(function()c:Disconnect()end) end
            end
            getgenv().ConexoesFTF={}

            if getgenv().PulosOriginais then
                for _,x in pairs(getgenv().PulosOriginais)do pcall(function()x:Enable()end) end
            end
            getgenv().PulosOriginais={}

            restoreOriginalDoubleJump()
        end
    end)

    Library:CreateDropdown(Page, "Emotes", {"None", "Sit", "Dance", "Wave", "Point"}, "None", function(val)
        -- Implementação futura do script de emotes
    end)
    
    local wsCharAdded
    Library:CreateToggleKeybind(Page, "Walkspeed", false, "None", function(state) 
        wsEnabled = state 
        if state then
            if LocalPlayer.Character then BackupSpeed(LocalPlayer.Character) end
            if not wsRunConnection then
                wsRunConnection = RunService.Stepped:Connect(function()
                    if wsEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        local hum = LocalPlayer.Character.Humanoid
                        if not originalWS[LocalPlayer.Character] then BackupSpeed(LocalPlayer.Character) end
                        hum.WalkSpeed = wsValue
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
                    if jpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        local hum = LocalPlayer.Character.Humanoid
                        if not originalJP[LocalPlayer.Character] then BackupJump(LocalPlayer.Character) end
                        hum.UseJumpPower = true
                        hum.JumpPower = jpVal
                        hum.JumpHeight = jpVal / 2
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
                    if flyEnabled and flyBg and flyBv and LocalPlayer.Character then
                        local charHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local charHum = LocalPlayer.Character:FindFirstChild("Humanoid")
                        if charHrp and charHum then
                            charHum.PlatformStand = true
                            flyBg.CFrame = CFrame.new(charHrp.Position, charHrp.Position + Camera.CFrame.LookVector)
                            local moveDir = charHum.MoveDirection
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

    Library:CreateSection(Page, "Players Pt. 2")
    
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
            task.spawn(function()
                for i = 1, 5 do
                    pcall(function()
                        if LocalPlayer.Character then
                            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                    part.CanCollide = true
                                end
                            end
                        end
                    end)
                    RunService.Stepped:Wait()
                end
            end)
        end
    end)

    local slCharAdded
    Library:CreateToggle(Page, "ShiftLock", false, function(state)
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
                infJumpConnection = UserInputService.JumpRequest:Connect(function()
                    if infJumpEnabled then
                        pcall(function()
                            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                        end)
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
