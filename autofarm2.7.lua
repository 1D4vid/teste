return function(env)
    -- Otimização de Performance: Localização de Globais (Upvalues)
    local task_wait = task.wait
    local task_spawn = task.spawn
    local ipairs = ipairs
    local pairs = pairs
    local pcall = pcall
    local Vector3_new = Vector3.new
    local CFrame_new = CFrame.new
    local string_find = string.find
    local string_lower = string.lower
    local table_insert = table.insert
    local table_clear = table.clear
    local math_max = math.max
    local math_floor = math.floor
    local tick = tick

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
    -- CACHE CENTRALIZADO DO MAPA (OTIMIZAÇÃO DE CPU)
    -- ==========================================
    local cachedComputers = {}
    local cachedExitDoors = {}
    local cachedFreezePods = {}

    local function updateMapCache()
        table_clear(cachedComputers)
        table_clear(cachedExitDoors)
        table_clear(cachedFreezePods)
        
        local currentMapVal = ReplicatedStorage:FindFirstChild("CurrentMap") and ReplicatedStorage.CurrentMap.Value
        if currentMapVal then
            for _, obj in ipairs(currentMapVal:GetDescendants()) do
                if obj.Name == "ComputerTable" then
                    table_insert(cachedComputers, obj)
                elseif obj.Name == "ExitDoor" then
                    table_insert(cachedExitDoors, obj)
                elseif obj.Name == "FreezePod" then
                    table_insert(cachedFreezePods, obj)
                end
            end
        end
    end

    ReplicatedStorage.CurrentMap.Changed:Connect(updateMapCache)
    task_spawn(updateMapCache)

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

    -- ==========================================
    -- ELEMENTOS DA INTERFACE (UI)
    -- ==========================================
    Library:CreateSection(Page, "Main Farming (BETA)")

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
            task_spawn(function()
                task_wait()
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
                task_spawn(function()
                    task_wait()
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
                task_spawn(function()
                    task_wait()
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
                task_spawn(DoSurvivorFarmFly)
            else
                SendNotification("Aviso | Aguardando partida iniciar...", 4)
            end
        else
            for i, v in pairs(fly_farmtasks) do
                pcall(function() coroutine.close(v) end)
                fly_farmtasks[i] = nil
            end
            fly_onsurvivorfarm = false
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
                task_spawn(function()
                    task_wait()
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
                task_spawn(function()
                    task_wait()
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

    AntiAfkToggleObj = Library:CreateToggle(Page, "Anti AFK", false, function(state)
        if MasterAutoFarmState and not state then
            task_spawn(function()
                task_wait()
                AntiAfkToggleObj.Set(true)
                SendNotification("Anti AFK cannot be disabled while Auto Farm is active!", 3)
            end)
            return
        end
        _G.AntiAfkEnabled = state
    end)

    local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
    local IsGameActive = ReplicatedStorage:WaitForChild("IsGameActive")

    -- [[ ANTI AFK ]] --
    task_spawn(function()
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
    task_spawn(function()
        local helping = false
        local oldCFrame = nil

        local function getRoot(character)
            if not character then return nil end
            return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        end

        while true do
            task_wait(0.1) -- Otimizado de 0.05 para 0.1
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

            for _, alvo in ipairs(Players:GetPlayers()) do
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
                            task_wait(0.1)
                            if not getgenv().AutoHelpTeleport or not MasterAutoFarmState then break end
                            local atualRoot = getRoot(LocalPlayer.Character)
                            if atualRoot then
                                atualRoot.CFrame = alvoRoot.CFrame * CFrame_new(0, -4.5, 0) * CFrame_new(0, 0, 0) -- Simplificado cálculo angular de CFrame
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

    -- [[ AUTO WIN BEAST - CONSOLIDADO EM 1 ÚNICO LOOP DE ALTA PERFORMANCE ]] --
    do
        local function ObterRaiz(character)
            if not character then return nil end
            return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        end

        local function ObterMapaAtual()
            local currentMapVal = ReplicatedStorage:FindFirstChild("CurrentMap") and ReplicatedStorage.CurrentMap.Value
            if currentMapVal then return currentMapVal end
            if #cachedComputers > 0 and cachedComputers[1].Parent then
                return cachedComputers[1].Parent
            end
            return nil
        end

        local function ObterTuboVazio(mapa)
            if not mapa then return nil end
            for _, obj in ipairs(cachedFreezePods) do
                if obj.Parent == mapa or obj:IsDescendantOf(mapa) then
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

        task_spawn(function()
            while true do
                task_wait(0.1)
                if getgenv().AutoWinBeast and MasterAutoFarmState then
                    pcall(function()
                        if not IsGameActive.Value or not LocalPlayer:FindFirstChild("TempPlayerStatsModule") then return end
                        
                        local MeuPersonagem = LocalPlayer.Character
                        if not MeuPersonagem then return end
                        
                        local MeuEventoMarreta = MeuPersonagem:FindFirstChild("HammerEvent", true)
                        local MinhaRaiz = ObterRaiz(MeuPersonagem)
                        if not MinhaRaiz or not MeuEventoMarreta then return end
                        
                        local AlvoAtual = nil
                        local RaizAlvo = nil
                        local mapa = ObterMapaAtual()
                        
                        for _, alvo in ipairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                                local Stats = alvo:FindFirstChild("TempPlayerStatsModule")
                                if Stats then
                                    local alvoCaido = Stats:FindFirstChild("Ragdoll")
                                    local alvoCapturado = Stats:FindFirstChild("Captured")
                                    local tempRaiz = ObterRaiz(alvo.Character)
                                    
                                    if tempRaiz and alvoCapturado then
                                        -- 1. Encontra o sobrevivente mais próximo para teleportar
                                        if not alvoCapturado.Value and not RaizAlvo then
                                            AlvoAtual = alvo
                                            RaizAlvo = tempRaiz
                                        end
                                        
                                        -- 2. Derruba / Amarra se estiver ao alcance
                                        if not alvoCapturado.Value then
                                            local distancia = (tempRaiz.Position - MinhaRaiz.Position).Magnitude
                                            if distancia <= 12 then
                                                if alvoCaido and not alvoCaido.Value then
                                                    MeuEventoMarreta:FireServer("HammerHit", tempRaiz)
                                                elseif alvoCaido and alvoCaido.Value == true then
                                                    MeuEventoMarreta:FireServer("HammerTieUp", tempRaiz, tempRaiz.Position)
                                                end
                                            end
                                        end
                                        
                                        -- 3. Envia para o Tubo se estiver no chão
                                        if alvoCaido and alvoCaido.Value == true and not alvoCapturado.Value then
                                            local tuboVazio = ObterTuboVazio(mapa)
                                            if tuboVazio then
                                                RemoteEvent:FireServer("Input", "Trigger", true, tuboVazio)
                                                task_wait(0.02)
                                                RemoteEvent:FireServer("Input", "Action", true)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        if RaizAlvo then
                            MeuPersonagem:PivotTo(RaizAlvo.CFrame * CFrame_new(0, 0, 1.5))
                            MinhaRaiz.Velocity = Vector3_new(0, 0, 0)
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
                Alertar("Anti-Cheat Bypass", "Calculating jump... Waiting " .. string_format("%.1f", tempoDeEspera) .. "s", tempoDeEspera)
                hrp.Velocity = Vector3_new(0, 0, 0)
                task_wait(tempoDeEspera)
            end

            hrp.CFrame = destinoCFrame
            hrp.Velocity = Vector3_new(0, 0, 0)
            task_wait(1.2)
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
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local raiz = player.Character:FindFirstChild("HumanoidRootPart")
                    if raiz and (raiz.Position - pcPos).Magnitude <= 6 then 
                        return true 
                    end
                end
            end
            return false
        end

        -- OTIMIZADO: AGORA USA CACHE DE COMPUTADORES EM VEZ DE DAR DESCENDANTADDS/WORKSPACE LOOKUPS
        local function ObterPCParaHackear()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            local pcMaisPerto = nil
            local menorDistancia = math.huge

            for _, obj in ipairs(cachedComputers) do
                if obj.Parent then
                    local tela = obj:FindFirstChild("Screen")
                    local teclado = obj:FindFirstChild("Keyboard") or obj:FindFirstChildWhichIsA("BasePart")
                    local eventoPC = obj:FindFirstChild("Event", true) or obj:FindFirstChildWhichIsA("RemoteEvent", true)
                    
                    if tela and eventoPC and teclado then
                        local corTela = string_lower(tostring(tela.BrickColor))
                        if not string_find(corTela, "green") and not TemGenteNoPC(teclado.Position) then
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
            task_spawn(function()
                repeat task_wait(0.1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                task_wait(1) 
                
                if ChecarSeSouBeast() then
                    getgenv().SouBeastNessaRodada = true
                    getgenv().FarmRodando = false
                    Alertar("System Status", "Beast Mode Detected. Farm Disabled.", 6)
                    return 
                end
                
                Alertar("NexVoid System", "Targets detected. Farm started.", 3)
                
                while getgenv().FarmRodando and getgenv().NexVoidLigado and MasterAutoFarmState do
                    task_wait(0.25) -- Otimizado de 0.2 para 0.25
                    
                    if getgenv().EscapouDaPartida then break end
                    if not PossoAgir() then continue end

                    local mesaPC, tela, eventoPC = ObterPCParaHackear()
                    
                    if mesaPC and tela and eventoPC then
                        local pcCFrame = mesaPC:GetPivot()

                        if pcCFrame then
                            local sucesso = EsperarETeleportar(pcCFrame * CFrame_new(0, 3, -3))
                            
                            if sucesso then
                                while getgenv().FarmRodando and not getgenv().EscapouDaPartida do
                                    if not PossoAgir() then break end
                                    local corAtual = string_lower(tostring(tela.BrickColor))
                                    if string_find(corAtual, "green") then break end
                                    
                                    RemoteEvent:FireServer("Input", "Trigger", true, eventoPC)
                                    RemoteEvent:FireServer("Input", "Action", true)
                                    RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                                    
                                    local char = LocalPlayer.Character
                                    if char and char:FindFirstChild("HumanoidRootPart") then
                                        char.HumanoidRootPart.Velocity = Vector3_new(0, 0, 0)
                                    end
                                    task_wait(0.1) 
                                end
                            end
                        end
                        
                    else
                        for _, porta in ipairs(cachedExitDoors) do
                            if porta.Parent then
                                local painel = porta:FindFirstChild("Light", true) or porta:FindFirstChild("Lock", true) or porta:FindFirstChildWhichIsA("BasePart")
                                local eventoPorta = porta:FindFirstChild("Event", true) or porta:FindFirstChildWhichIsA("RemoteEvent", true)

                                if painel and eventoPorta and not TemGenteNoPC(painel.Position) then
                                    Alertar("Target Locked", "Moving to Exit Door.", 4)
                                    
                                    local cframePorta = painel.CFrame * CFrame_new(0, 0, -3)
                                    local sucesso = EsperarETeleportar(cframePorta)
                                    
                                    if sucesso then
                                        while getgenv().FarmRodando and not getgenv().EscapouDaPartida do
                                            if not PossoAgir() then break end
                                            
                                            local corLuz = string_lower(tostring(painel.BrickColor))
                                            if string_find(corLuz, "green") then break end
                                            
                                            local actionVal = LocalPlayer:FindFirstChild("ActionProgress", true)
                                            if actionVal and actionVal:IsA("NumberValue") then
                                                if actionVal.Value >= 0.99 then break end
                                            end
                                            
                                            RemoteEvent:FireServer("Input", "Trigger", true, eventoPorta)
                                            RemoteEvent:FireServer("Input", "Action", true)
                                            task_wait(0.1)
                                        end
                                        
                                        if getgenv().EscapouDaPartida then break end 
                                        
                                        Alertar("Target Unlocked", "Door opened. Escaping...", 4)
                                        task_wait(3) 
                                        
                                        local char = LocalPlayer.Character
                                        if char and char:FindFirstChild("HumanoidRootPart") then
                                            local hrp = char.HumanoidRootPart
                                            local centroPortaCFrame = porta:GetPivot()
                                            hrp.CFrame = centroPortaCFrame
                                            task_wait(0.5)
                                            
                                            for _, parte in ipairs(porta:GetDescendants()) do
                                                if parte:IsA("BasePart") and parte.Transparency >= 0.8 and not parte.CanCollide then
                                                    hrp.CFrame = parte.CFrame
                                                    task_wait(0.2) 
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

        task_spawn(function()
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
                                    char.HumanoidRootPart.Velocity = Vector3_new(0, 0, 0)
                                end
                            end
                        end
                    end)
                end
                task_wait(1) 
            end
        end)
    end

    -- [[ AUTO SAVE (SILENT) ]] --
    do
        local function GetCurrentMap()
            local map
            local ov = ReplicatedStorage:FindFirstChild("CurrentMap")
            if ov and ov:IsA("ObjectValue") and ov.Value then
                map = ov.Value
            end
            if not map and #cachedComputers > 0 and cachedComputers[1].Parent then
                map = cachedComputers[1].Parent
            end
            return map
        end

        local function CapturedFreezePod(cmap)
            if type(cmap) ~= "table" then return nil end
            for _, obj in ipairs(cmap) do
                if obj.Name == "FreezePod" then
                    local PodTrigger = obj:FindFirstChild("PodTrigger", true)
                    if PodTrigger then
                        local CapturedTorso = PodTrigger:FindFirstChild("CapturedTorso")
                        local Event = PodTrigger:FindFirstChild("Event")
                        
                        if CapturedTorso and Event and CapturedTorso:IsA("ObjectValue") and CapturedTorso.Value then
                            return Event
                        end
                    end
                end
            end
            return nil
        end

        task_spawn(function()
            local map = GetCurrentMap()
            
            while true do
                task_wait(0.1) -- Otimizado de 0.05 para 0.1
                if not getgenv().AutoHelpSilent or not MasterAutoFarmState then continue end
                
                local myStats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                if not myStats then continue end
                
                local myHealth = myStats:FindFirstChild("Health")
                local myRagdoll = myStats:FindFirstChild("Ragdoll")
                local myCaptured = myStats:FindFirstChild("Captured")
                
                if myHealth and myHealth.Value <= 0 then continue end
                if myRagdoll and myRagdoll.Value then continue end
                if myCaptured and myCaptured.Value then continue end
                
                if not map then
                    map = GetCurrentMap()
                    continue
                end
                
                for _, alvo in ipairs(Players:GetPlayers()) do
                    if alvo == LocalPlayer then continue end
                    
                    local alvoStats = alvo:FindFirstChild("TempPlayerStatsModule")
                    local alvoCaptured = alvoStats and alvoStats:FindFirstChild("Captured")
                    
                    if alvoCaptured and alvoCaptured:IsA("BoolValue") and alvoCaptured.Value then
                        local podEvent = CapturedFreezePod(map:GetChildren())
                        
                        if not podEvent then continue end
                        
                        repeat
                            task_wait(0.1)
                            RemoteEvent:FireServer("Input", "Trigger", true, podEvent)
                            RemoteEvent:FireServer("Input", "Action", true)
                            
                        until not (alvoCaptured.Value and getgenv().AutoHelpSilent and MasterAutoFarmState) 
                           or (myRagdoll.Value or myCaptured.Value or myHealth.Value <= 0)
                           
                        break 
                    end
                end
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
                LocalPlayer.Character:PivotTo(lobby.CFrame * CFrame_new(0, 3, 0))
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
            local statusText = string_lower(status.Value)
            if string_find(statusText, "intermission") or string_find(statusText, "game over") or string_find(statusText, "lobby") then
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

        -- OTIMIZADO: LÊ DIRETAMENTE DO CACHE EM VEZ DE GERAR ARRAY ITERATIVO DO MAPA INTEIRO
        local function GetMapObjects()
            return {Computers = cachedComputers, ExitDoors = cachedExitDoors}
        end

        local MapObjects = GetMapObjects()
        local loadAttempts = 0
        while #MapObjects.Computers == 0 and loadAttempts < 10 do
            task_wait(0.5)
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
                
                Root.CFrame = CFrame_new(nextPosition) * Root.CFrame.Rotation
            end

            if fly_IsThereChar() then
                Root.Anchored = false
                Root.CFrame = CFrame_new(Part.Position) * Root.CFrame.Rotation
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
                            task_wait(math_max(0.1, fly_Config.WaitTweenFast - travelTime))
                        end

                        repeat
                            task_wait()
                        until not TaskGood() or fly_bnhide == false or fly_bnhideelapse >= fly_Config.CampHackOut

                        fly_Notify("Objetivo", "Movendo para o computador", 2.5)
                        fly_GoTween(v)

                        if Computer.Screen.BrickColor == BrickColor.new("Dark green") then CurrentComputer = nil; OnComputer = false; return end
                        if not TaskGood() then CurrentComputer = nil; OnComputer = false; return end
                        if v.ActionSign.Value ~= 20 or (ChosenComputer ~= Computer and ChosenComputer ~= nil) then continue end

                        local Tries = 0
                        repeat
                            task_wait()
                            
                            if CurrentComputer ~= Computer and fly_IsTriggerOccupied(v) then
                                fly_Notify("Teclado Ocupado", "Outro jogador pegou esta vaga.", 3)
                                break
                            end

                            if TaskGood() and not fly_bnhide and fly_TempPlayerStatsModule.CurrentAnimation.Value ~= "Typing" then
                                Tries = Tries + 1
                                if fly_IsThereChar() then
                                    LocalPlayer.Character:PivotTo(v.CFrame)
                                end
                                
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, v.Event)
                                task_wait(0.1)
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                task_wait(0.4)
                            elseif TaskGood() and not fly_bnhide then
                                if CurrentComputer ~= Computer then
                                    fly_Notify("Hackeando", "Iniciou o processo", 3)
                                end
                                CurrentComputer = Computer
                                Tries = 0
                                
                                if fly_Config.AntiPCError then
                                    ReplicatedStorage.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                                end
                            end

                            if fly_bnhideelapse >= fly_Config.CampHackOut then
                                ComputerBanList[math_floor(tick() * 1000)] = Computer
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
                                    fly_Notify("Fuga Forçada", "A besta está acampando. Indo para as portas!", 4)
                                else
                                    fly_Notify("Mudando de Alvo", "A besta está acampando neste PC.", 3.5)
                                end
                                return
                            end

                            if Tries >= 15 and TaskGood() and not fly_bnhide then
                                CurrentComputer = nil
                                OnComputer = false
                                fly_Notify("Erro", "Falha ao iniciar hack. Tentando novamente.", 3)
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
                    task_wait(0.25) -- Otimizado
                    
                    if CurrentComputer then
                        ChosenComputer = CurrentComputer
                        continue
                    end

                    ComputersLeft = 0
                    LeastTriggers = 4
                    Closest = math.huge

                    if ChosenComputer and ChosenComputer.Screen.BrickColor == BrickColor.new("Dark green") then
                        fly_Notify("Concluído", "Computador hackeado com sucesso!", 3)
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
            end)()

            repeat
                task_wait(0.5)
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

            fly_Notify("Fuga", "Seguindo para as portas de saída.", 4)

            repeat
                task_wait(0.5)
                for i = 1, #MapObjects.ExitDoors do
                    local v = MapObjects.ExitDoors[i]
                    if not TaskGood() then continue end

                    repeat
                        task_wait(0.5)
                    until not TaskGood() or fly_bnhide == false or fly_bnhideelapse >= fly_Config.CampEscapeOut

                    if v:FindFirstChild("ExitDoorTrigger") then
                        fly_GoTween(v.ExitDoorTrigger)
                        repeat
                            task_wait()
                            if v:FindFirstChild("ExitDoorTrigger") and v.ExitDoorTrigger.ActionSign.Value ~= 0 and not fly_bnhide and fly_IsThereChar() then
                                LocalPlayer.Character:PivotTo(v.ExitDoorTrigger.CFrame * CFrame_new(0, v.ExitDoorTrigger.Size.Y / 2, 0))
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, v.ExitDoorTrigger.Event)
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                task_wait(0.5)
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
                        task_wait(0.5)
                        if v:FindFirstChild("ExitArea") then
                            fly_Notify("Fuga", "Escapando...", 3)
                            fly_GoTween(v.ExitArea)
                        end
                    end
                end
            until not TaskGood()
        end

        local NewFarmTask = coroutine.create(function()
            if PlayerReady() and not fly_onsurvivorfarm then
                fly_onsurvivorfarm = true
                fly_Notify("Auto Farm", "Auto Farm iniciado.", 3)
                Run()
                if not DoNotTeleport then
                    task.wait(1)
                    fly_TPPlayerSpawn()
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
            if fly_AmIBeast() then return end
            while fly_IsInLobby() and fly_IsMatchActive() and getgenv().AutoWinFlyActive and MasterAutoFarmState do
                task.wait(0.2)
            end
            if getgenv().AutoWinFlyActive and not fly_onsurvivorfarm and not fly_IsInLobby() and MasterAutoFarmState then
                fly_Notify("Partida", "Iniciando farm na nova partida.", 3)
                task.spawn(DoSurvivorFarmFly)
            end
        end
    end)

    -- LOOP GERAL DE VERIFICAÇÃO DO VOO (OTIMIZADO)
    task_spawn(function()
        while true do
            local dt = task_wait(0.1)
            
            if not fly_IsThereChar() then
                fly_RemoveSafePlatform()
            end

            if getgenv().AutoWinFlyActive and MasterAutoFarmState and fly_AmIBeast() then
                getgenv().AutoWinFlyActive = false
                if AutoWinFlyToggleObj then AutoWinFlyToggleObj.Set(false) end
                fly_Notify("Pausado", "Você é a BESTA. Script pausado.", 5)
                
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

            if not getgenv().AutoWinFlyActive or not MasterAutoFarmState or not fly_IsMatchActive() then
                if fly_IsThereChar() and LocalPlayer.Character.HumanoidRootPart.Anchored then
                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                end
                fly_RemoveSafePlatform()
                fly_onsurvivorfarm = false
                fly_bnhide = false
                fly_Comp = 0 
                
                if getgenv().AutoWinFlyActive and MasterAutoFarmState then
                    if not fly_notifiedLobby then
                        fly_Notify("Lobby", "Aguardando início do jogo...", 5)
                        fly_notifiedLobby = true
                    end
                end
                continue
            end

            if fly_notifiedLobby then
                fly_notifiedLobby = false
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
                        fly_Notify("Seguro", "Retomando atividades.", 3)
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
                                    fly_safePlatform.Size = Vector3_new(15, 1, 15)
                                    fly_safePlatform.Anchored = true
                                    fly_safePlatform.CanCollide = true
                                    fly_safePlatform.Transparency = 1
                                    fly_safePlatform.Name = "NexVoidSafePlate"
                                    fly_safePlatform.Parent = workspace
                                end
                                fly_safePlatform.CFrame = fly_lpos * CFrame_new(0, 75, 0)
                                LocalPlayer.Character:PivotTo(fly_safePlatform.CFrame * CFrame_new(0, 3, 0))
                                
                                task.spawn(function()
                                    task.wait()
                                    if fly_IsThereChar() then
                                        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                                        LocalPlayer.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
                                    end
                                end)
                            end)
                            fly_Notify("Perigo", "Subindo para plataforma de segurança.", 3.5)
                        end
                    end

                    if fly_bnhide and fly_lpos and not fly_isMoving then
                        local targetHover = (fly_lpos * CFrame_new(0, 75, 0)).Position
                        if (LocalPlayer.Character.HumanoidRootPart.Position - targetHover).Magnitude > 8 then
                            LocalPlayer.Character:PivotTo(fly_lpos * CFrame_new(0, 75, 0) * CFrame_new(0, 3, 0))
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
                            fly_Notify("Livre", "A besta se afastou. Retornando.", 3)
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
                -- Otimizado: lê contagem de computadores diretamente da nossa tabela em cache
                local GotComputers = #cachedComputers
                
                if GotComputers ~= fly_Comp then
                    if GotComputers > 0 then
                        task_wait(3)
                        if getgenv().AutoWinFlyActive and not fly_onsurvivorfarm and MasterAutoFarmState then
                            task_spawn(function()
                                while fly_IsInLobby() and fly_IsMatchActive() and getgenv().AutoWinFlyActive and MasterAutoFarmState do
                                    task.wait(0.2)
                                end
                                if getgenv().AutoWinFlyActive and not fly_onsurvivorfarm and not fly_IsInLobby() and MasterAutoFarmState then
                                    task_spawn(DoSurvivorFarmFly)
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
end
