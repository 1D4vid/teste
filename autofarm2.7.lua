return function(env)
    local Library = env.Library
    local Page = env.Page
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local Workspace = env.Workspace
    local ReplicatedStorage = env.ReplicatedStorage
    local SendNotification = env.SendNotification

    local MasterAutoFarmState = false
    local AntiAfkToggleObj
    local AutoWinTeleportToggleObj
    local AutoWinFlyToggleObj
    local AutoWinBeastToggleObj
    local AutoSaveTeleportToggleObj

    Library:CreateSection(Page, "Main Farming (BETA)")

    Library:CreateToggle(Page, "Enable Auto Farm", false, function(state)
        MasterAutoFarmState = state
        if state then
            if AntiAfkToggleObj then AntiAfkToggleObj.Set(true) end
        else
            if AutoWinTeleportToggleObj then AutoWinTeleportToggleObj.Set(false) end
            if AutoWinFlyToggleObj then AutoWinFlyToggleObj.Set(false) end
            if AutoWinBeastToggleObj then AutoWinBeastToggleObj.Set(false) end
            if AutoSaveTeleportToggleObj then AutoSaveTeleportToggleObj.Set(false) end
        end
    end)

    AutoWinTeleportToggleObj = Library:CreateToggle(Page, "Auto Win (Teleport)", false, function(state)
        if state and not MasterAutoFarmState then
            task.spawn(function()
                task.wait()
                AutoWinTeleportToggleObj.Set(false)
                SendNotification("Enable 'Enable Auto Farm' first!", 3)
            end)
            return
        end
        getgenv().NexVoidLigado = state
        if not state then
            getgenv().FarmRodando = false
        end
    end)

    AutoWinFlyToggleObj = Library:CreateToggle(Page, "Auto Win (Fly)", false, function(state)
        if state and not MasterAutoFarmState then
            task.spawn(function()
                task.wait()
                AutoWinFlyToggleObj.Set(false)
                SendNotification("Enable 'Enable Auto Farm' first!", 3)
            end)
            return
        end
        -- Vazio por enquanto
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

    Library:CreateToggle(Page, "Auto Save (Silent)", false, function(state)
        getgenv().AutoHelpSilent = state
        if state then
            SendNotification("Auto Save (Silent) | Players in pod will be saved magically.", 5)
        end
    end)

    AutoSaveTeleportToggleObj = Library:CreateToggle(Page, "Auto Save (Teleport)", false, function(state)
        if state and not MasterAutoFarmState then
            task.spawn(function()
                task.wait()
                AutoSaveTeleportToggleObj.Set(false)
                SendNotification("Enable 'Enable Auto Farm' first!", 3)
            end)
            return
        end
        -- Vazio por enquanto
    end)

    Library:CreateSection(Page, "Farm Settings")

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

    -- SCRIPTS DO AUTO FARM E UTILS
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
                if getgenv().AutoWinBeast then
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
                            MinhaRaiz.Velocity = Vector3.zero 
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while true do
                task.wait(0.1)
                if getgenv().AutoWinBeast then
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
                if getgenv().AutoWinBeast then
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
                hrp.Velocity = Vector3.new(0,0,0)
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
                
                while getgenv().FarmRodando and getgenv().NexVoidLigado do
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
                if getgenv().NexVoidLigado then
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
                                    char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                                end
                            end
                        end
                    end)
                end
                task.wait(1) 
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
            if not map then
                local comp = workspace:FindFirstChild("ComputerTable", true)
                if comp and comp.Parent then map = comp.Parent end
            end
            if not map then
                local pod = workspace:FindFirstChild("FreezePod", true)
                if pod and pod.Parent then map = pod.Parent end
            end
            return map
        end

        local function CapturedFreezePod(cmap)
            if type(cmap) ~= "table" then return nil end
            for _, obj in pairs(cmap) do
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

        task.spawn(function()
            local map = GetCurrentMap()
            
            while true do
                task.wait(0.05)
                if not getgenv().AutoHelpSilent then continue end
                
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
                
                for _, alvo in pairs(Players:GetPlayers()) do
                    if alvo == LocalPlayer then continue end
                    
                    local alvoStats = alvo:FindFirstChild("TempPlayerStatsModule")
                    local alvoCaptured = alvoStats and alvoStats:FindFirstChild("Captured")
                    
                    if alvoCaptured and alvoCaptured:IsA("BoolValue") and alvoCaptured.Value then
                        local podEvent = CapturedFreezePod(map:GetChildren())
                        
                        if not podEvent then continue end
                        
                        repeat
                            task.wait(0.05)
                            RemoteEvent:FireServer("Input", "Trigger", true, podEvent)
                            RemoteEvent:FireServer("Input", "Action", true)
                            
                        until not (alvoCaptured.Value and getgenv().AutoHelpSilent) 
                           or (myRagdoll.Value or myCaptured.Value or myHealth.Value <= 0)
                           
                        break 
                    end
                end
            end
        end)
    end
end
