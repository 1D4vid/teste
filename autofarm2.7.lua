return function(env)
    local Library = env.Library
    local Page = env.Page
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local Workspace = env.Workspace
    local ReplicatedStorage = env.ReplicatedStorage
    local SendNotification = env.SendNotification
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    local MasterAutoFarmState = false
    local AntiAfkToggleObj
    local AutoWinTeleportToggleObj
    local AutoWinFlyToggleObj
    local AutoWinBeastToggleObj
    local AutoSaveSilentToggleObj
    local AutoSaveTeleportToggleObj

    -- ==========================================
    -- VARIÁVEIS DO AUTO WIN SURVIVOR (FLY)
    -- ==========================================
    local fly_Config = {
        FarmTweenSpeed = 22,        
        WaitTweenFast = 8,          
        TriggerPrioritization = 1,  
        CampHackOut = 15,           
        CampEscapeOut = 20,         
        CampTweenAnimOut = 30,      
        HideBeastNearDist = 35,     
        TriggerUnCampOut = 5,       
        ExitCancel = false,         
        AntiPCError = true,         
        HideBeastNear = true        
    }

    local fly_onsurvivorfarm = false
    local fly_bnhide = false
    local fly_isMoving = false          
    local fly_bnhideelapse = 0
    local fly_noelepse = 0
    local fly_lpos = nil
    local fly_cachedBeast = nil         
    local fly_safePlatform = nil        
    local fly_farmtasks = {}
    local fly_TempPlayerStatsModule = nil
    local fly_Comp = 0
    local fly_notifiedLobby = false
    local fly_SouBeastNessaRodada = false

    -- ==========================================
    -- VARIÁVEIS DO AUTO WIN SURVIVOR (TELEPORT)
    -- ==========================================
    local tp_bnhide = false
    local tp_lpos = nil
    local tp_safePlatform = nil

    -- ==========================================
    -- ELEMENTOS DA INTERFACE (UI)
    -- ==========================================
    Library:CreateSection(Page, "Main Farming (scrr)")

    Library:CreateToggle(Page, "Enable Auto Farm", false, function(state)
        MasterAutoFarmState = state
        if state then
            if AntiAfkToggleObj then AntiAfkToggleObj.Set(true) end
        else
            if AutoWinBeastToggleObj then AutoWinBeastToggleObj.Set(false) end
            if AutoWinTeleportToggleObj then AutoWinTeleportToggleObj.Set(false) end
            if AutoWinFlyToggleObj then AutoWinFlyToggleObj.Set(false) end
            if AutoSaveSilentToggleObj then AutoSaveSilentToggleObj.Set(false) end
            if AutoSaveTeleportToggleObj then AutoSaveTeleportToggleObj.Set(false) end
        end
    end)

    AutoWinBeastToggleObj = Library:CreateToggle(Page, "Auto Win Beast", false, function(state)
        if state and not MasterAutoFarmState then
            task.spawn(function()
                task.wait()
                AutoWinBeastToggleObj.Set(false)
                SendNotification("Enable 'Enable Auto Farm' first!", 3)
            end)
            return
        end
        getgenv().AutoWinBeast = state
    end)

    AutoWinTeleportToggleObj = Library:CreateToggle(Page, "Auto Win Survivor (Teleport)", false, function(state)
        if state then
            if not MasterAutoFarmState then
                task.spawn(function()
                    task.wait()
                    AutoWinTeleportToggleObj.Set(false)
                    SendNotification("Enable 'Enable Auto Farm' first!", 3)
                end)
                return
            end
            if AutoWinFlyToggleObj then AutoWinFlyToggleObj.Set(false) end
        end

        getgenv().NexVoidLigado = state
        if not state then
            getgenv().FarmRodando = false
        end
    end)

    local DoSurvivorFarmFly

    AutoWinFlyToggleObj = Library:CreateToggle(Page, "Auto Win Survivor (Fly)", false, function(state)
        if state then
            if not MasterAutoFarmState then
                task.spawn(function()
                    task.wait()
                    AutoWinFlyToggleObj.Set(false)
                    SendNotification("Enable 'Enable Auto Farm' first!", 3)
                end)
                return
            end
            if AutoWinTeleportToggleObj then AutoWinTeleportToggleObj.Set(false) end
        end

        getgenv().AutoWinFlyActive = state
        if state then
            if IsGameActive.Value == true then
                if not fly_AmIBeast() then
                    task.spawn(DoSurvivorFarmFly)
                else
                    fly_SouBeastNessaRodada = true
                    SendNotification("Notification | Beast Mode detected. Fly farm paused.", 5)
                end
            else
                SendNotification("Notification | Waiting for match to start...", 4)
            end
        else
            for i, v in pairs(fly_farmtasks) do
                pcall(function() coroutine.close(v) end)
                fly_farmtasks[i] = nil
            end
            fly_onsurvivorfarm = false
            fly_SouBeastNessaRodada = false
            if fly_safePlatform then
                pcall(function() fly_safePlatform:Destroy() end)
                fly_safePlatform = nil
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
        end
    end)

    AutoSaveSilentToggleObj = Library:CreateToggle(Page, "Auto Save (Silent)", false, function(state)
        if state then
            if not MasterAutoFarmState then
                task.spawn(function()
                    task.wait()
                    AutoSaveSilentToggleObj.Set(false)
                    SendNotification("Enable 'Enable Auto Farm' first!", 3)
                end)
                return
            end
            if AutoSaveTeleportToggleObj then AutoSaveTeleportToggleObj.Set(false) end
        end

        getgenv().AutoHelpSilent = state
        if state then
            SendNotification("Auto Save (Silent) | Players in pod will be saved magically.", 5)
        end
    end)

    AutoSaveTeleportToggleObj = Library:CreateToggle(Page, "Auto Save (Teleport)", false, function(state)
        if state then
            if not MasterAutoFarmState then
                task.spawn(function()
                    task.wait()
                    AutoSaveTeleportToggleObj.Set(false)
                    SendNotification("Enable 'Enable Auto Farm' first!", 3)
                end)
                return
            end
            if AutoSaveSilentToggleObj then AutoSaveSilentToggleObj.Set(false) end
        end

        getgenv().AutoHelpTeleport = state
        if state then
            SendNotification("Auto Save (Teleport) | Teleporting to save players under the pod.", 5)
        end
    end)

    Library:CreateSection(Page, "Farm Settings")

    Library:CreateSlider(Page, "Fly Survivor Speed", 10, 30, 22, function(val)
        fly_Config.FarmTweenSpeed = val
    end)

    Library:CreateToggle(Page, "Moderator Alert / Kick", false, function(state)
        -- Placeholder
    end)

    Library:CreateToggle(Page, "Auto Rejoin (Disconnection)", false, function(state)
        -- Placeholder
    end)

    AntiAfkToggleObj = Library:CreateToggle(Page, "Anti AFK", false, function(state)
        if MasterAutoFarmState and not state then
            task.spawn(function()
                task.wait()
                AntiAfkToggleObj.Set(true)
                SendNotification("Anti AFK cannot be disabled while Auto Farm is active!", 3)
            end)
            return
        end
        _G.AntiAfkEnabled = state
    end)

    -- REFERÊNCIAS DO SISTEMA
    local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
    local IsGameActive = ReplicatedStorage:WaitForChild("IsGameActive")

    -- [[ ANTI AFK ]] --
    task.spawn(function()
        local VirtualUser = game:GetService("VirtualUser")
        if _G.AntiAfkConnection then
            _G.AntiAfkConnection:Disconnect()
        end
        _G.AntiAfkConnection = LocalPlayer.Idled:Connect(function()
            if _G.AntiAfkEnabled then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end
        end)
    end)

    -- [[ AUTO SAVE (TELEPORT) ]] --
    task.spawn(function()
        local helping = false
        local oldCFrame = nil

        local function getRoot(character)
            if not character then return nil end
            return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        end

        while true do
            task.wait(0.05)
            if not getgenv().AutoHelpTeleport or not MasterAutoFarmState then continue end

            local meChar = LocalPlayer.Character
            local meRoot = getRoot(meChar)
            local myStats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
            
            if not meChar or not meRoot or not myStats or helping then continue end

            local myHealth = myStats:FindFirstChild("Health")
            local myRagdoll = myStats:FindFirstChild("Ragdoll")
            local myCaptured = myStats:FindFirstChild("Captured")

            if myHealth and myHealth.Value <= 0 then continue end
            if myRagdoll and myRagdoll.Value then continue end
            if myCaptured and myCaptured.Value then continue end

            for _, alvo in pairs(Players:GetPlayers()) do
                if alvo == LocalPlayer or helping then continue end

                local alvoStats = alvo:FindFirstChild("TempPlayerStatsModule")
                local alvoCaptured = alvoStats and alvoStats:FindFirstChild("Captured")

                if alvoCaptured and alvoCaptured:IsA("BoolValue") and alvoCaptured.Value then
                    local alvoChar = alvo.Character
                    local alvoRoot = getRoot(alvoChar)

                    if alvoRoot then
                        helping = true
                        oldCFrame = meRoot.CFrame

                        repeat
                            task.wait(0.05)
                            if not getgenv().AutoHelpTeleport or not MasterAutoFarmState then break end
                            local atualRoot = getRoot(LocalPlayer.Character)
                            if atualRoot then
                                atualRoot.CFrame = alvoRoot.CFrame * CFrame.new(0, -4.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                            end
                            RemoteEvent:FireServer("Input", "Action", true)
                            
                        until not (alvoCaptured.Value and getgenv().AutoHelpTeleport and MasterAutoFarmState) 
                           or (myRagdoll.Value or myCaptured.Value or myHealth.Value <= 0)

                        if oldCFrame and LocalPlayer.Character then
                            LocalPlayer.Character:PivotTo(oldCFrame)
                        end

                        oldCFrame = nil
                        helping = false
                        break 
                    end
                end
            end
        end
    end)

    -- [[ AUTO WIN BEAST ]] --
    do
        local function ObterRaiz(character)
            if not character then return nil end
            return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        end

        local function ObterMapaAtual()
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj:FindFirstChild("FreezePod") or obj:FindFirstChild("ComputerTable") then
                    return obj
                end
            end
            return nil
        end

        local function ObterTuboVazio(mapa)
            if not mapa then return nil end
            for _, obj in pairs(mapa:GetChildren()) do
                if obj.Name == "FreezePod" then
                    local trigger = obj:FindFirstChild("PodTrigger", true)
                    if trigger then
                        local capturedTorso = trigger:FindFirstChild("CapturedTorso")
                        local event = trigger:FindFirstChild("Event")
                        if capturedTorso and event and capturedTorso.Value == nil then
                            return event
                        end
                    end
                end
            end
            return nil
        end

        task.spawn(function()
            while true do
                task.wait(0.1) 
                if getgenv().AutoWinBeast and MasterAutoFarmState then
                    pcall(function()
                        if not IsGameActive.Value or not LocalPlayer:FindFirstChild("TempPlayerStatsModule") then return end
                        
                        local MeuPersonagem = LocalPlayer.Character
                        local MinhaRaiz = ObterRaiz(MeuPersonagem)
                        
                        if not MeuPersonagem:FindFirstChild("HammerEvent", true) or not MinhaRaiz then return end
                        
                        local AlvoAtual = nil
                        local RaizAlvo = nil
                        
                        for _, alvo in pairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                                local Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                if Stats and Stats:FindFirstChild("Captured") and not Stats.Captured.Value then
                                    local tempRaiz = ObterRaiz(alvo.Character)
                                    if tempRaiz then
                                        AlvoAtual = alvo
                                        RaizAlvo = tempRaiz
                                        break
                                    end
                                end
                            end
                        end
                        
                        if RaizAlvo then
                            MeuPersonagem:PivotTo(RaizAlvo.CFrame * CFrame.new(0, 0, 1.5))
                            MinhaRaiz.Velocity = Vector3.new(0, 0, 0)
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while true do
                task.wait(0.1)
                if getgenv().AutoWinBeast and MasterAutoFarmState then
                    pcall(function()
                        if not IsGameActive.Value or not LocalPlayer:FindFirstChild("TempPlayerStatsModule") then return end

                        local MeuPersonagem = LocalPlayer.Character
                        local MeuEventoMarreta = MeuPersonagem and MeuPersonagem:FindFirstChild("HammerEvent", true)
                        local MinhaRaiz = ObterRaiz(MeuPersonagem)
                        
                        if not MeuEventoMarreta or not MinhaRaiz then return end
                        
                        for _, alvo in pairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                                local Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                if not Stats then continue end
                                
                                local alvoCaido = Stats:FindFirstChild("Ragdoll")
                                local alvoCapturado = Stats:FindFirstChild("Captured")
                                local RaizAlvo = ObterRaiz(alvo.Character)
                                
                                if RaizAlvo and alvoCapturado and not alvoCapturado.Value then
                                    local distancia = (RaizAlvo.Position - MinhaRaiz.Position).Magnitude
                                    
                                    if distancia <= 12 then
                                        if alvoCaido and not alvoCaido.Value then
                                            MeuEventoMarreta:FireServer("HammerHit", RaizAlvo)
                                        end
                                        
                                        if alvoCaido and alvoCaido.Value == true then
                                            MeuEventoMarreta:FireServer("HammerTieUp", RaizAlvo, RaizAlvo.Position)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while true do
                task.wait(0.1)
                if getgenv().AutoWinBeast and MasterAutoFarmState then
                    pcall(function()
                        if not IsGameActive.Value or not LocalPlayer:FindFirstChild("TempPlayerStatsModule") then return end

                        local MeuPersonagem = LocalPlayer.Character
                        if not MeuPersonagem:FindFirstChild("HammerEvent", true) then return end
                        
                        local mapa = ObterMapaAtual()
                        
                        for _, alvo in pairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                                local Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                if not Stats then continue end
                                
                                local alvoCaido = Stats:FindFirstChild("Ragdoll")
                                local alvoCapturado = Stats:FindFirstChild("Captured")
                                
                                if alvoCaido and alvoCaido.Value == true and alvoCapturado and alvoCapturado.Value == false then
                                    local tuboVazio = ObterTuboVazio(mapa)
                                    if tuboVazio then
                                        RemoteEvent:FireServer("Input", "Trigger", true, tuboVazio)
                                        task.wait(0.05)
                                        RemoteEvent:FireServer("Input", "Action", true)
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end)
    end

    -- [[ AUTO WIN SURVIVOR (TELEPORT) ]] --
    do
        local VELOCIDADE_ANTI_CHUTE = 25 
        getgenv().FarmRodando = false
        getgenv().EscapouDaPartida = false 
        getgenv().SouBeastNessaRodada = false

        local function Alertar(titulo, texto, tempo)
            SendNotification(titulo .. " | " .. texto, tempo or 3)
        end

        local function EsperarETeleportar(destinoCFrame)
            local char = LocalPlayer.Character
            if not char then return false end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end

            local distancia = (hrp.Position - destinoCFrame.Position).Magnitude
            local tempoDeEspera = distancia / VELOCIDADE_ANTI_CHUTE

            if tempoDeEspera > 0.5 then
                Alertar("Anti-Cheat Bypass", "Calculating jump... Waiting " .. string.format("%.1f", tempoDeEspera) .. "s", tempoDeEspera)
                hrp.Velocity = Vector3.new(0, 0, 0)
                task.wait(tempoDeEspera)
            end

            hrp.CFrame = destinoCFrame
            hrp.Velocity = Vector3.new(0, 0, 0)
            task.wait(1.2)
            return true
        end

        local function ChecarSeSouBeast()
            local char = LocalPlayer.Character
            if not char then return false end
            if char:FindFirstChild("Hammer") or char:FindFirstChild("BeastPowers") then
                return true
            end
            return false
        end

        local function PossoAgir()
            if getgenv().EscapouDaPartida then return false end 
            if getgenv().SouBeastNessaRodada then return false end
            if tp_bnhide then return false end
            
            local char = LocalPlayer.Character
            if not char then return false end
            
            local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
            
            if not stats then 
                if IsGameActive.Value == true then
                    return true 
                else
                    getgenv().EscapouDaPartida = true
                    getgenv().FarmRodando = false
                    return false 
                end
            end
            
            local ragdoll = stats:FindFirstChild("Ragdoll")
            local captured = stats:FindFirstChild("Captured")
            if (ragdoll and ragdoll.Value) or (captured and captured.Value) then return false end
            
            return true
        end

        local function TemGenteNoPC(pcPos)
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local raiz = player.Character:FindFirstChild("HumanoidRootPart")
                    if raiz and (raiz.Position - pcPos).Magnitude <= 6 then 
                        return true 
                    end
                end
            end
            return false
        end

        local function ObterPCParaHackear()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            local pcMaisPerto = nil
            local menorDistancia = math.huge

            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "ComputerTable" then
                    local tela = obj:FindFirstChild("Screen")
                    local teclado = obj:FindFirstChild("Keyboard") or obj:FindFirstChildWhichIsA("BasePart")
                    local eventoPC = obj:FindFirstChild("Event", true) or obj:FindFirstChildWhichIsA("RemoteEvent", true)
                    
                    if tela and eventoPC and teclado then
                        local corTela = string.lower(tostring(tela.BrickColor))
                        if not string.find(corTela, "green") and not TemGenteNoPC(teclado.Position) then
                            
                            if hrp then
                                local distancia = (hrp.Position - teclado.Position).Magnitude
                                if distancia < menorDistancia then
                                    menorDistancia = distancia
                                    pcMaisPerto = {mesa = obj, tela = tela, evento = eventoPC}
                                end
                            else
                                return obj, tela, eventoPC 
                            end
                        end
                    end
                end
            end
            
            if pcMaisPerto then
                return pcMaisPerto.mesa, pcMaisPerto.tela, pcMaisPerto.evento
            end
            return nil, nil, nil
        end

        local function IniciarRotinaDeFarm()
            task.spawn(function()
                repeat task.wait(0.1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                task.wait(1) 
                
                if ChecarSeSouBeast() then
                    getgenv().SouBeastNessaRodada = true
                    getgenv().FarmRodando = false
                    Alertar("System Status", "Beast Mode Detected. Farm Disabled.", 6)
                    return 
                end
                
                Alertar("NexVoid System", "Targets detected. Farm started.", 3)
                
                while getgenv().FarmRodando and getgenv().NexVoidLigado and MasterAutoFarmState do
                    task.wait(0.2) 
                    
                    if getgenv().EscapouDaPartida then break end
                    if not PossoAgir() then continue end

                    local mesaPC, tela, eventoPC = ObterPCParaHackear()
                    
                    if mesaPC and tela and eventoPC then
                        local pcCFrame
                        if mesaPC:IsA("Model") then 
                            pcCFrame = mesaPC:GetPivot() 
                        else
                            local part = mesaPC:FindFirstChildWhichIsA("BasePart")
                            if part then pcCFrame = part.CFrame end
                        end

                        if pcCFrame then
                            local sucesso = EsperarETeleportar(pcCFrame * CFrame.new(0, 3, -3))
                            
                            if sucesso then
                                while getgenv().FarmRodando and not getgenv().EscapouDaPartida do
                                    if not PossoAgir() then break end
                                    local corAtual = string.lower(tostring(tela.BrickColor))
                                    if string.find(corAtual, "green") then break end
                                    
                                    RemoteEvent:FireServer("Input", "Trigger", true, eventoPC)
                                    RemoteEvent:FireServer("Input", "Action", true)
                                    RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                                    
                                    local char = LocalPlayer.Character
                                    if char and char:FindFirstChild("HumanoidRootPart") then
                                        char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                                    end
                                    task.wait(0.1) 
                                end
                            end
                        end
                        
                    else
                        for _, porta in pairs(Workspace:GetDescendants()) do
                            if porta.Name == "ExitDoor" then
                                local painel = porta:FindFirstChild("Light", true) or porta:FindFirstChild("Lock", true) or porta:FindFirstChildWhichIsA("BasePart")
                                local eventoPorta = porta:FindFirstChild("Event", true) or porta:FindFirstChildWhichIsA("RemoteEvent", true)

                                if painel and eventoPorta and not TemGenteNoPC(painel.Position) then
                                    
                                    Alertar("Target Locked", "Moving to Exit Door.", 4)
                                    
                                    local cframePorta = painel.CFrame * CFrame.new(0, 0, -3)
                                    local sucesso = EsperarETeleportar(cframePorta)
                                    
                                    if sucesso then
                                        
                                        while getgenv().FarmRodando and not getgenv().EscapouDaPartida do
                                            if not PossoAgir() then break end
                                            
                                            local corLuz = string.lower(tostring(painel.BrickColor))
                                            if string.find(corLuz, "green") then break end
                                            
                                            local actionVal = LocalPlayer:FindFirstChild("ActionProgress", true)
                                            if actionVal and actionVal:IsA("NumberValue") then
                                                if actionVal.Value >= 0.99 then break end
                                            end
                                            
                                            RemoteEvent:FireServer("Input", "Trigger", true, eventoPorta)
                                            RemoteEvent:FireServer("Input", "Action", true)
                                            task.wait(0.1)
                                        end
                                        
                                        if getgenv().EscapouDaPartida then break end 
                                        
                                        Alertar("Target Unlocked", "Door opened. Escaping...", 4)
                                        task.wait(3) 
                                        
                                        local char = LocalPlayer.Character
                                        if char and char:FindFirstChild("HumanoidRootPart") then
                                            local hrp = char.HumanoidRootPart
                                            
                                            local centroPortaCFrame = porta:GetBoundingBox()
                                            hrp.CFrame = CFrame.new(centroPortaCFrame.Position)
                                            task.wait(0.5)
                                            
                                            for _, parte in pairs(porta:GetDescendants()) do
                                                if parte:IsA("BasePart") and parte.Transparency >= 0.8 and not parte.CanCollide then
                                                    hrp.CFrame = parte.CFrame
                                                    task.wait(0.2) 
                                                    
                                                    if not LocalPlayer:FindFirstChild("TempPlayerStatsModule") then
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                        
                                        getgenv().EscapouDaPartida = true
                                        getgenv().FarmRodando = false 
                                        Alertar("System Status", "Successfully escaped. Paused.", 6)
                                        break 
                                    end
                                end
                            end
                        end
                        if getgenv().EscapouDaPartida then break end
                    end
                end
            end)
        end

        task.spawn(function()
            while true do
                if getgenv().NexVoidLigado and MasterAutoFarmState then
                    pcall(function() 
                        if IsGameActive.Value == true then
                            if not getgenv().FarmRodando and not getgenv().EscapouDaPartida and not getgenv().SouBeastNessaRodada then
                                getgenv().FarmRodando = true
                                Alertar("NexVoid System", "Auto Farm initialized. Waiting for round.", 5)
                                IniciarRotinaDeFarm()
                            end
                        else
                            if getgenv().FarmRodando or getgenv().EscapouDaPartida or getgenv().SouBeastNessaRodada then
                                getgenv().FarmRodando = false 
                                getgenv().EscapouDaPartida = false 
                                getgenv().SouBeastNessaRodada = false 
                                
                                Alertar("System Status", "Round ended. Resetting to Standby mode.", 5)
                                
                                local char = LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                                end
                            end
                        end
                    end)
                end
                task.wait(1) 
            end
        end)
    end

    -- ==========================================
    -- LOGICA DE SUPORTE DO AUTO WIN FLY
    -- ==========================================
    local function fly_Notify(title, text, duration)
        SendNotification(title .. " | " .. text, duration or 3)
    end

    local function fly_RemoveSafePlatform()
        if fly_safePlatform then
            pcall(function()
                fly_safePlatform:Destroy()
            end)
            fly_safePlatform = nil
        end
    end

    local function fly_IsThereChar(APlr)
        local plr = APlr or LocalPlayer
        local char = plr.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            return humanoid and hrp and humanoid.Health > 0
        end
        return false
    end

    local function fly_TPPlayerSpawn()
        if fly_IsThereChar() then
            local lobby = workspace:FindFirstChild("LobbySpawnPad")
            if lobby then
                LocalPlayer.Character:PivotTo(lobby.CFrame * CFrame.new(0, 3, 0))
            end
        end
    end

    local function fly_IsInLobby()
        local lobby = workspace:FindFirstChild("LobbySpawnPad")
        if not lobby then
            return false 
        end
        if not fly_IsThereChar() then
            return true
        end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return true
        end
        return (hrp.Position - lobby.Position).Magnitude < 150
    end

    local function fly_AmIBeast()
        local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
        if stats then
            local isBeastVal = stats:FindFirstChild("IsBeast")
            if isBeastVal and isBeastVal.Value == true then
                return true
            end
        end
        local char = LocalPlayer.Character
        if char then
            local hammer = char:FindFirstChild("BeastHammer") or char:FindFirstChild("Hammer")
            if hammer and hammer:IsA("Tool") then
                return true
            end
        end
        return false
    end

    local function fly_IsTriggerOccupied(trigger)
        local triggerPos = trigger.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and fly_IsThereChar(p) then
                if (p.Character.HumanoidRootPart.Position - triggerPos).Magnitude < 3.5 then
                    return true
                end
            end
        end
        return false
    end

    local function fly_IsMatchActive()
        local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
        if not currentMap or not currentMap.Value then
            return false
        end
        local status = ReplicatedStorage:FindFirstChild("GameStatus")
        if status then
            local statusText = string.lower(status.Value)
            if string.find(statusText, "intermission") or string.find(statusText, "game over") or string.find(statusText, "lobby") then
                return false
            end
        end
        return true
    end

    local function fly_GetBeast()
        if fly_cachedBeast and fly_cachedBeast.Parent == Players and fly_IsThereChar(fly_cachedBeast) then
            local stats = fly_cachedBeast:FindFirstChild("TempPlayerStatsModule")
            if stats then
                local isBeastVal = stats:FindFirstChild("IsBeast")
                if isBeastVal and isBeastVal.Value == true then
                    return fly_cachedBeast
                end
            end
            local char = fly_cachedBeast.Character
            if char then
                local hammer = char:FindFirstChild("BeastHammer") or char:FindFirstChild("Hammer")
                if hammer and hammer:IsA("Tool") then
                    return fly_cachedBeast
                end
            end
        end

        for _, v in ipairs(Players:GetPlayers()) do
            local stats = v:FindFirstChild("TempPlayerStatsModule")
            if stats then
                local isBeastVal = stats:FindFirstChild("IsBeast")
                if isBeastVal and isBeastVal.Value == true then
                    fly_cachedBeast = v
                    return v
                end
            end
            
            local char = v.Character
            if char then
                local hammer = char:FindFirstChild("BeastHammer") or char:FindFirstChild("Hammer")
                if hammer and hammer:IsA("Tool") then
                    fly_cachedBeast = v
                    return v
                end
            end
            
            local backpack = v:FindFirstChild("Backpack")
            if backpack then
                local hammer = backpack:FindFirstChild("BeastHammer") or backpack:FindFirstChild("Hammer")
                if hammer and hammer:IsA("Tool") then
                    fly_cachedBeast = v
                    return v
                end
            end
        end
        fly_cachedBeast = nil
        return nil
    end

    -- [[ EXECUÇÃO DO FARM DE VOO ]] --
    DoSurvivorFarmFly = function()
        local DoNotTeleport = false
        local forceEscape = false 

        local function PlayerReady()
            if fly_TempPlayerStatsModule then
                local ragdoll = fly_TempPlayerStatsModule:FindFirstChild("Ragdoll")
                if ragdoll and ragdoll.Value then
                    DoNotTeleport = true
                    return false
                end
                local health = fly_TempPlayerStatsModule:FindFirstChild("Health")
                if (health and health.Value <= 0) or fly_TempPlayerStatsModule.IsBeast.Value then
                    return false
                end
            end
            return fly_IsThereChar()
        end

        local function TaskGood()
            return getgenv().AutoWinFlyActive and not fly_AmIBeast() and fly_IsMatchActive() and PlayerReady() and MasterAutoFarmState
        end

        local function GetMapObjects()
            local Result = {Computers = {}, ExitDoors = {}}
            local currentMapVal = ReplicatedStorage.CurrentMap.Value
            if currentMapVal then
                local children = currentMapVal:GetChildren()
                for i = 1, #children do
                    local v = children[i]
                    if v.Name == "ComputerTable" then
                        table.insert(Result.Computers, v)
                    elseif v.Name == "ExitDoor" then
                        table.insert(Result.ExitDoors, v)
                    end
                end
            end
            return Result
        end

        local MapObjects = GetMapObjects()
        local loadAttempts = 0
        while #MapObjects.Computers == 0 and loadAttempts < 10 do
            task.wait(0.5)
            MapObjects = GetMapObjects()
            loadAttempts = loadAttempts + 1
        end

        local fly_GoTween
        fly_GoTween = function(Part)
            if not fly_IsThereChar() then return end
            fly_isMoving = true 
            local Root = LocalPlayer.Character.HumanoidRootPart
            
            Root.Anchored = true
            
            while fly_IsThereChar() and TaskGood() do
                local currentPos = Root.Position
                local targetPos = Part.Position
                local distanceVector = targetPos - currentPos
                local distance = distanceVector.Magnitude
                
                if distance < 1.5 then
                    break
                end
                
                local dt = RunService.Heartbeat:Wait()
                local speed = fly_Config.FarmTweenSpeed
                local step = speed * dt
                
                if step > distance then
                    step = distance
                end
                
                local direction = distanceVector.Unit
                local nextPosition = currentPos + (direction * step)
                
                Root.CFrame = CFrame.new(nextPosition) * Root.CFrame.Rotation
            end

            if fly_IsThereChar() then
                Root.Anchored = false
                Root.CFrame = CFrame.new(Part.Position) * Root.CFrame.Rotation
            end
            fly_isMoving = false
        end

        local OnComputer = false
        local ChosenComputer = nil
        local ComputerBanList = {}
        local CurrentComputer = nil

        local function GetComputer(Computer)
            if TaskGood() and Computer.Screen.BrickColor ~= BrickColor.new("Dark green") and not OnComputer then
                OnComputer = true
                local Prioritize = fly_Config.TriggerPrioritization
                local Triggers = {}

                if Prioritize == 1 then
                    Triggers = { Computer:FindFirstChild("ComputerTrigger1"), Computer:FindFirstChild("ComputerTrigger2"), Computer:FindFirstChild("ComputerTrigger3") }
                elseif Prioritize == 2 then
                    Triggers = { Computer:FindFirstChild("ComputerTrigger2"), Computer:FindFirstChild("ComputerTrigger3"), Computer:FindFirstChild("ComputerTrigger1") }
                else
                    Triggers = { Computer:FindFirstChild("ComputerTrigger3"), Computer:FindFirstChild("ComputerTrigger1"), Computer:FindFirstChild("ComputerTrigger2") }
                end

                for i = 1, #Triggers do
                    local v = Triggers[i]
                    if v and TaskGood() and v.ActionSign.Value == 20 and not fly_IsTriggerOccupied(v) and Computer.Screen.BrickColor ~= BrickColor.new("Dark green") and ChosenComputer == Computer then
                        local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude
                        local travelTime = Distance / fly_Config.FarmTweenSpeed

                        if travelTime < fly_Config.WaitTweenFast then
                            task.wait(math.max(0.1, fly_Config.WaitTweenFast - travelTime))
                        end

                        repeat
                            task.wait()
                        until not TaskGood() or fly_bnhide == false or fly_bnhideelapse >= fly_Config.CampHackOut

                        fly_Notify("Objective", "Moving to computer", 2.5)
                        fly_GoTween(v)

                        if Computer.Screen.BrickColor == BrickColor.new("Dark green") then CurrentComputer = nil; OnComputer = false; return end
                        if not TaskGood() then CurrentComputer = nil; OnComputer = false; return end
                        if v.ActionSign.Value ~= 20 or (ChosenComputer ~= Computer and ChosenComputer ~= nil) then continue end

                        local Tries = 0
                        repeat
                            task.wait()
                            
                            if CurrentComputer ~= Computer and fly_IsTriggerOccupied(v) then
                                fly_Notify("Keypad Occupied", "Another player took this slot.", 3)
                                break
                            end

                            if TaskGood() and not fly_bnhide and fly_TempPlayerStatsModule.CurrentAnimation.Value ~= "Typing" then
                                Tries = Tries + 1
                                if fly_IsThereChar() then
                                    LocalPlayer.Character:PivotTo(v.CFrame)
                                end
                                
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, v.Event)
                                task.wait(0.1)
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                task.wait(0.4)
                            elseif TaskGood() and not fly_bnhide then
                                if CurrentComputer ~= Computer then
                                    fly_Notify("Hacking", "Process started", 3)
                                end
                                CurrentComputer = Computer
                                Tries = 0
                                
                                if fly_Config.AntiPCError then
                                    ReplicatedStorage.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                                end
                            end

                            if fly_bnhideelapse >= fly_Config.CampHackOut then
                                ComputerBanList[math.floor(tick() * 1000)] = Computer
                                fly_RemoveSafePlatform()
                                fly_bnhide = false
                                OnComputer = false
                                CurrentComputer = nil
                                fly_bnhideelapse = 0
                                fly_lpos = nil 
                                if fly_IsThereChar() then
                                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                                end

                                local reqLeftVal = ReplicatedStorage:FindFirstChild("ComputersLeft")
                                if reqLeftVal and reqLeftVal.Value <= 0 then
                                    forceEscape = true
                                    fly_Notify("Forced Escape", "Beast is camping. Head to the exits!", 4)
                                else
                                    fly_Notify("Target Changed", "Beast is camping this PC.", 3.5)
                                end
                                return
                            end

                            if Tries >= 15 and TaskGood() and not fly_bnhide then
                                CurrentComputer = nil
                                OnComputer = false
                                fly_Notify("Error", "Failed to start hack. Trying again.", 3)
                                return
                            end
                        until not TaskGood() or Computer.Screen.BrickColor == BrickColor.new("Dark green") or (ChosenComputer ~= Computer and ChosenComputer ~= nil)
                    end
                end
                CurrentComputer = nil
                OnComputer = false
            end
        end

        local function Run()
            local CancelComputers = false
            local LeastTriggers = 4
            local Closest = math.huge
            local ComputersLeft = 0

            coroutine.wrap(function()
                while TaskGood() do
                    task.wait(0.2)
                    
                    if CurrentComputer then
                        ChosenComputer = CurrentComputer
                        continue
                    end

                    ComputersLeft = 0
                    LeastTriggers = 4
                    Closest = math.huge

                    if ChosenComputer and ChosenComputer.Screen.BrickColor == BrickColor.new("Dark green") then
                        fly_Notify("Completed", "Computer hacked successfully!", 3)
                        ChosenComputer = nil
                    end

                    local BeastObj = fly_GetBeast()
                    local currentTime = tick() * 1000

                    for i = 1, #MapObjects.Computers do
                        local v = MapObjects.Computers[i]
                        local UseTrigger = v:FindFirstChild("ComputerTrigger3")
                        local FoundV = nil

                        for i2, v2 in pairs(ComputerBanList) do
                            if UseTrigger and BeastObj and fly_IsThereChar(BeastObj) and v2 == v and currentTime - i2 > 5000 and (UseTrigger.Position - BeastObj.Character.HumanoidRootPart.Position).Magnitude > fly_Config.HideBeastNearDist + 10 then
                                ComputerBanList[i2] = nil
                            elseif v2 == v then
                                FoundV = v2
                            end
                        end

                        if v.Screen.BrickColor ~= BrickColor.new("Dark green") then
                            ComputersLeft = ComputersLeft + 1
                        end

                        if v.Screen.BrickColor ~= BrickColor.new("Dark green") and not FoundV and fly_IsThereChar() then
                            local Triggers = { v:FindFirstChild("ComputerTrigger3"), v:FindFirstChild("ComputerTrigger2"), v:FindFirstChild("ComputerTrigger1") }
                            local Distance = (Triggers[1].Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            local AmtTriggers = 3

                            for i3 = 1, #Triggers do
                                local v2 = Triggers[i3]
                                if v2 and v2.ActionSign.Value ~= 20 then
                                    AmtTriggers = AmtTriggers - 1
                                end
                            end

                            if v == CurrentComputer and AmtTriggers >= 1 then
                                AmtTriggers = AmtTriggers + 1
                            elseif AmtTriggers < 1 then
                                AmtTriggers = -1
                            end

                            if ((AmtTriggers >= 1 or AmtTriggers == -1) and AmtTriggers <= LeastTriggers) then
                                if AmtTriggers == LeastTriggers and Distance > Closest then
                                    continue
                                end
                                ChosenComputer = v
                                LeastTriggers = AmtTriggers
                                Closest = Distance
                            end
                        end
                    end
                end
            endCode = nil -- Explicit cleanup
            coroutine.wrap(function() end)() -- Dummy for cleaning register

            repeat
                task.wait(0.5)
                local isFinished = (ComputersLeft < 1) or forceEscape

                if isFinished then
                    CancelComputers = true
                    fly_RemoveSafePlatform()
                    fly_bnhide = false
                    fly_lpos = nil
                    if fly_IsThereChar() then
                        LocalPlayer.Character.HumanoidRootPart.Anchored = false
                    end
                elseif ChosenComputer and not OnComputer then
                    GetComputer(ChosenComputer)
                end
            until not TaskGood() or CancelComputers

            if not TaskGood() or fly_Config.ExitCancel then
                return
            end

            fly_Notify("Escape", "Heading to exit doors.", 4)

            repeat
                task.wait(0.5)
                for i = 1, #MapObjects.ExitDoors do
                    local v = MapObjects.ExitDoors[i]
                    if not TaskGood() then continue end

                    repeat
                        task.wait(0.5)
                    until not TaskGood() or fly_bnhide == false or fly_bnhideelapse >= fly_Config.CampEscapeOut

                    if v:FindFirstChild("ExitDoorTrigger") then
                        fly_GoTween(v.ExitDoorTrigger)
                        repeat
                            task.wait()
                            if v:FindFirstChild("ExitDoorTrigger") and v.ExitDoorTrigger.ActionSign.Value ~= 0 and not fly_bnhide and fly_IsThereChar() then
                                LocalPlayer.Character:PivotTo(v.ExitDoorTrigger.CFrame * CFrame.new(0, v.ExitDoorTrigger.Size.Y / 2, 0))
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, v.ExitDoorTrigger.Event)
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                task.wait(0.5)
                            end
                        until not TaskGood() or not v:FindFirstChild("ExitDoorTrigger") or fly_bnhideelapse >= fly_Config.CampEscapeOut

                        if fly_bnhideelapse >= fly_Config.CampEscapeOut and fly_IsThereChar() then
                            fly_RemoveSafePlatform()
                            LocalPlayer.Character.HumanoidRootPart.Anchored = false
                            fly_bnhide = false
                            fly_bnhideelapse = 0
                            fly_lpos = nil
                            continue
                        end
                    end

                    if TaskGood() then
                        task.wait(0.5)
                        if v:FindFirstChild("ExitArea") then
                            fly_Notify("Escape", "Escaping...", 3)
                            fly_GoTween(v.ExitArea)
                        end
                    end
                end
            until not TaskGood()
        end

        local NewFarmTask = coroutine.create(function()
            if PlayerReady() and not fly_onsurvivorfarm then
                fly_onsurvivorfarm = true
                fly_Notify("Auto Farm", "Auto Farm started.", 3)
                Run()
                -- Só teleporta de volta se a partida ainda estiver ativa/normalmente encerrada
                if not DoNotTeleport and fly_IsMatchActive() and getgenv().AutoWinFlyActive and MasterAutoFarmState then
                    task.wait(1)
                    if fly_IsMatchActive() and getgenv().AutoWinFlyActive and MasterAutoFarmState then
                        fly_TPPlayerSpawn()
                    end
                end
                fly_onsurvivorfarm = false
            end
        end)
        coroutine.resume(NewFarmTask)
        table.insert(fly_farmtasks, NewFarmTask)
    end

    -- MONITORAMENTO DOS MAPAS (Voo)
    ReplicatedStorage.CurrentMap.Changed:Connect(function(newMap)
        if newMap and getgenv().AutoWinFlyActive and not fly_onsurvivorfarm and MasterAutoFarmState then
            if fly_AmIBeast() then 
                fly_SouBeastNessaRodada = true
                return 
            end
            while fly_IsInLobby() and fly_IsMatchActive() and getgenv().AutoWinFlyActive and MasterAutoFarmState do
                task.wait(0.2)
            end
            if getgenv().AutoWinFlyActive and not fly_onsurvivorfarm and not fly_IsInLobby() and MasterAutoFarmState then
                if not fly_AmIBeast() then
                    fly_Notify("Match", "Starting farm on new match.", 3)
                    task.spawn(DoSurvivorFarmFly)
                end
            end
        end
    end)

    -- LOOP GERAL DE VERIFICAÇÃO DO VOO
    task.spawn(function()
        while true do
            local dt = task.wait(0.1)
            
            if not fly_IsThereChar() then
                fly_RemoveSafePlatform()
            end

            -- Se formos a Besta, limpa todas as threads de Survivor imediatamente
            if getgenv().AutoWinFlyActive and MasterAutoFarmState and fly_AmIBeast() then
                if not fly_SouBeastNessaRodada then
                    fly_SouBeastNessaRodada = true
                    fly_Notify("Paused", "You are the BEAST. Fly Auto Farm paused.", 5)
                end
                
                for i, v in pairs(fly_farmtasks) do
                    pcall(function() coroutine.close(v) end)
                    fly_farmtasks[i] = nil
                end
                fly_onsurvivorfarm = false
                fly_RemoveSafePlatform()
                if fly_IsThereChar() then
                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                end
                continue
            end

            -- Limpeza profunda ao sair de partidas/iniciar novas para evitar carry-over bugs
            if not getgenv().AutoWinFlyActive or not MasterAutoFarmState or not fly_IsMatchActive() then
                if fly_IsThereChar() and LocalPlayer.Character.HumanoidRootPart.Anchored then
                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                end
                fly_RemoveSafePlatform()
                
                -- Força o encerramento de todas as threads correndo em segundo plano
                for i, v in pairs(fly_farmtasks) do
                    pcall(function() coroutine.close(v) end)
                    fly_farmtasks[i] = nil
                end
                
                fly_onsurvivorfarm = false
                fly_bnhide = false
                fly_Comp = 0 
                fly_SouBeastNessaRodada = false
                
                if getgenv().AutoWinFlyActive and MasterAutoFarmState then
                    if not fly_notifiedLobby then
                        fly_Notify("Lobby", "Waiting for game start...", 5)
                        fly_notifiedLobby = true
                    end
                end
                continue
            end

            if fly_notifiedLobby then
                fly_notifiedLobby = false
            end

            -- Se era Beast mas por algum motivo não é mais durante a partida, reinicia
            if fly_SouBeastNessaRodada and not fly_AmIBeast() then
                fly_SouBeastNessaRodada = false
            end

            fly_TempPlayerStatsModule = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
            fly_Beast = fly_GetBeast()

            if fly_Config.HideBeastNear and fly_IsThereChar() and fly_TempPlayerStatsModule and not fly_TempPlayerStatsModule.IsBeast.Value then
                if (fly_Beast == nil or not fly_IsThereChar(fly_Beast)) then
                    if fly_bnhide then
                        fly_bnhide = false
                        fly_bnhideelapse = 0
                        fly_RemoveSafePlatform()
                        if fly_IsThereChar() then
                            LocalPlayer.Character.HumanoidRootPart.Anchored = false
                            if fly_lpos then
                                LocalPlayer.Character:PivotTo(fly_lpos)
                            end
                        end
                        fly_lpos = nil
                        fly_Notify("Safe", "Resuming activities.", 3)
                    end
                else
                    local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
                    local beastPos = fly_Beast.Character.HumanoidRootPart.Position
                    local currentGroundPos = fly_lpos and fly_lpos.Position or playerPos
                    local distance = (beastPos - currentGroundPos).Magnitude
                    
                    if not fly_isMoving then
                        if not fly_bnhide and distance < fly_Config.HideBeastNearDist then
                            fly_lpos = LocalPlayer.Character:GetPivot() 
                            fly_bnhide = true
                            fly_bnhideelapse = 0
                            
                            pcall(function()
                                if not fly_safePlatform then
                                    fly_safePlatform = Instance.new("Part")
                                    fly_safePlatform.Size = Vector3.new(15, 1, 15)
                                    fly_safePlatform.Anchored = true
                                    fly_safePlatform.CanCollide = true
                                    fly_safePlatform.Transparency = 1
                                    fly_safePlatform.Name = "NexVoidSafePlate"
                                    fly_safePlatform.Parent = workspace
                                end
                                fly_safePlatform.CFrame = fly_lpos * CFrame.new(0, 75, 0)
                                LocalPlayer.Character:PivotTo(fly_safePlatform.CFrame * CFrame.new(0, 3, 0))
                                
                                task.spawn(function()
                                    task.wait()
                                    if fly_IsThereChar() then
                                        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                        LocalPlayer.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                    end
                                end)
                            end)
                            fly_Notify("Danger", "Going up to safety platform.", 3.5)
                        end
                    end

                    if fly_bnhide and fly_lpos and not fly_isMoving then
                        local targetHover = (fly_lpos * CFrame.new(0, 75, 0)).Position
                        if (LocalPlayer.Character.HumanoidRootPart.Position - targetHover).Magnitude > 8 then
                            LocalPlayer.Character:PivotTo(fly_lpos * CFrame.new(0, 75, 0) * CFrame.new(0, 3, 0))
                        end

                        local beastDistanceFromLpos = (beastPos - fly_lpos.Position).Magnitude
                        if beastDistanceFromLpos > (fly_Config.HideBeastNearDist + 15) and fly_TempPlayerStatsModule.Ragdoll.Value == false then
                            fly_RemoveSafePlatform()
                            if fly_IsThereChar() then
                                LocalPlayer.Character.HumanoidRootPart.Anchored = false
                                LocalPlayer.Character:PivotTo(fly_lpos)
                            end
                            fly_bnhide = false
                            fly_bnhideelapse = 0
                            fly_lpos = nil
                            fly_Notify("Clear", "Beast moved away. Returning.", 3)
                        end
                    end
                end
            end

            if fly_bnhide then
                fly_bnhideelapse = fly_bnhideelapse + dt
                fly_noelepse = 0
            else
                fly_noelepse = fly_noelepse + dt
                if fly_noelepse > fly_Config.TriggerUnCampOut then
                    fly_bnhideelapse = 0
                end
            end

            if fly_IsThereChar() and LocalPlayer.Character.HumanoidRootPart.Position.Y < -2000 then
                fly_TPPlayerSpawn()
            end

            local CurrentMap = ReplicatedStorage.CurrentMap.Value
            if CurrentMap then
                local GotComputers = 0
                local children = CurrentMap:GetChildren()
                for i = 1, #children do
                    if children[i].Name == "ComputerTable" then
                        GotComputers = GotComputers + 1
                    end
                end
                if GotComputers ~= fly_Comp then
                    if GotComputers > 0 then
                        task.wait(3)
                        if getgenv().AutoWinFlyActive and not fly_onsurvivorfarm and MasterAutoFarmState then
                            task.spawn(function()
                                while fly_IsInLobby() and fly_IsMatchActive() and getgenv().AutoWinFlyActive and MasterAutoFarmState do
                                    task.wait(0.2)
                                end
                                if getgenv().AutoWinFlyActive and not fly_onsurvivorfarm and not fly_IsInLobby() and MasterAutoFarmState then
                                    if not fly_AmIBeast() then
                                        task.spawn(DoSurvivorFarmFly)
                                    end
                                end
                            end)
                        end
                    else
                        fly_onsurvivorfarm = false
                        fly_Beast = nil
                    end
                    fly_Comp = GotComputers
                end
            end
        end
    end)

    -- ==========================================
    -- LOGICA DE EVASÃO DO TELEPORTE (HideBeastNear)
    -- ==========================================
    task.spawn(function()
        local function IsThereCharLocal()
            local char = LocalPlayer.Character
            return char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0
        end

        while true do
            task.wait(0.1)
            if not MasterAutoFarmState or not getgenv().NexVoidLigado or not IsGameActive.Value then
                if tp_bnhide then
                    tp_bnhide = false
                    if tp_safePlatform then 
                        pcall(function() tp_safePlatform:Destroy() end) 
                        tp_safePlatform = nil 
                    end
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.Anchored = false
                    end
                end
                continue
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local beast = fly_GetBeast() 
            local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
            local isBeast = stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value
            
            if beast and fly_IsThereChar(beast) and not isBeast then
                local beastPos = beast.Character.HumanoidRootPart.Position
                local currentGroundPos = tp_lpos and tp_lpos.Position or hrp.Position
                local distance = (beastPos - currentGroundPos).Magnitude

                if not tp_bnhide and distance < 35 then
                    tp_lpos = hrp.CFrame
                    tp_bnhide = true
                    SendNotification("Danger | Beast is near! Going up to safety platform.", 3.5)
                    
                    pcall(function()
                        if not tp_safePlatform then
                            tp_safePlatform = Instance.new("Part")
                            tp_safePlatform.Size = Vector3.new(15, 1, 15)
                            tp_safePlatform.Anchored = true
                            tp_safePlatform.CanCollide = true
                            tp_safePlatform.Transparency = 1
                            tp_safePlatform.Name = "NexVoidSafePlateTeleport"
                            tp_safePlatform.Parent = workspace
                        end
                        tp_safePlatform.CFrame = tp_lpos * CFrame.new(0, 75, 0)
                        char:PivotTo(tp_safePlatform.CFrame * CFrame.new(0, 3, 0))
                    end)
                end

                if tp_bnhide and tp_lpos then
                    local targetHover = (tp_lpos * CFrame.new(0, 75, 0)).Position
                    if (hrp.Position - targetHover).Magnitude > 8 then
                        char:PivotTo(tp_lpos * CFrame.new(0, 75, 0) * CFrame.new(0, 3, 0))
                    end

                    local beastDistanceFromLpos = (beastPos - tp_lpos.Position).Magnitude
                    local ragdoll = stats and stats:FindFirstChild("Ragdoll") and stats.Ragdoll.Value
                    if beastDistanceFromLpos > 50 and not ragdoll then
                        if tp_safePlatform then 
                            pcall(function() tp_safePlatform:Destroy() end) 
                            tp_safePlatform = nil 
                        end
                        char:PivotTo(tp_lpos)
                        tp_bnhide = false
                        tp_lpos = nil
                        SendNotification("Clear | Beast moved away. Returning.", 3)
                    end
                end
            else
                if tp_bnhide then
                    if tp_safePlatform then 
                        pcall(function() tp_safePlatform:Destroy() end) 
                        tp_safePlatform = nil 
                    end
                    if tp_lpos then char:PivotTo(tp_lpos) end
                    tp_bnhide = false
                    tp_lpos = nil
                    SendNotification("Safe | Resuming activities.", 3)
                end
            end
        end
    end)
end
