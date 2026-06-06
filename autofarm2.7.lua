return function(env)
    local Library = env.Library
    local Page = env.Page
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local Workspace = env.Workspace
    local ReplicatedStorage = env.ReplicatedStorage
    local SendNotification = env.SendNotification

    -- Serviços adicionais necessários
    local GuiService = game:GetService("GuiService")
    local TeleportService = game:GetService("TeleportService")
    local RunService = game:GetService("RunService")

    -- Localização de funções para ganho de performance (Micro-optimizations)
    local Vector3_new = Vector3.new
    local CFrame_new = CFrame.new
    local task_wait = task.wait
    local task_spawn = task.spawn
    local ipairs = ipairs
    local pairs = pairs
    local math_floor = math.floor
    local tick = tick

    -- Configurações internas do Auto Farm (NexVoid Fly)
    local Config = {
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

    local MasterAutoFarmState = false
    local AntiAfkToggleObj
    local AutoWinSurvivorToggleObj
    local AutoWinSurvivorFlyToggleObj
    local AutoWinBeastToggleObj
    local AutoSaveTeleportToggleObj
    local AutoRejoinToggleObj
    local ModAlertToggleObj

    -- Gerenciadores de Conexões Globais para evitar loops/eventos duplicados
    local RejoinConnection = nil
    local ModAddedConnection = nil
    local IsGameActiveConnection = nil

    -- Estados Isolados do Auto Win Survivor (Fly) - Prefixo fly_
    local fly_AutoFarmEnabled = false
    local fly_onsurvivorfarm = false
    local fly_bnhide = false
    local fly_isMoving = false          
    local fly_bnhideelapse = 0
    local fly_noelepse = 0
    local fly_lpos = nil
    local fly_clpos = false
    local fly_Beast = nil
    local fly_cachedBeast = nil         
    local fly_safePlatform = nil        
    local fly_farmtasks = {}
    local fly_Comp = 0
    local fly_SessionId = 0
    local lastRoleIsBeast = false

    local notifiedLobby = false
    local TempPlayerStatsModule = nil

    -- Função de Notificações
    local function Notify(title, text, duration)
        SendNotification(title .. " | " .. text, duration or 3)
    end

    -- Limpeza física da plataforma aérea de Sobrevivente
    local function RemoveSafePlatform()
        if fly_safePlatform then
            pcall(function()
                fly_safePlatform:Destroy()
            end)
            fly_safePlatform = nil
        end
    end

    -- Funções de Apoio de Carregamento
    local function IsThereChar(APlr)
        local plr = APlr or LocalPlayer
        local char = plr.Character
        return char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")
    end

    -- Limpa de forma absoluta toda e qualquer tarefa (Besta e Survivor) apenas UMA VEZ por transição
    local function GlobalReset()
        fly_SessionId = fly_SessionId + 1 -- Aborta imediatamente qualquer execução de tween ou hacking pendente
        print("[SESSION RESET] Session ID incremented to:", fly_SessionId)

        fly_onsurvivorfarm = false
        fly_bnhide = false
        fly_isMoving = false
        fly_bnhideelapse = 0
        fly_noelepse = 0
        fly_lpos = nil
        fly_clpos = false
        fly_Beast = nil
        fly_cachedBeast = nil
        fly_Comp = 0
        RemoveSafePlatform()
        
        -- Encerra todas as threads antigas de Sobrevivente ativas
        for i, v in pairs(fly_farmtasks) do
            pcall(function()
                coroutine.close(v)
            end)
            fly_farmtasks[i] = nil
        end
        
        -- Desliga o script externo de Besta de forma limpa
        getgenv().AutoWinBeast = false
        getgenv().FarmRodando = false
        getgenv().NexVoidLigado = false
        
        -- Força a liberação da física e ancoragem do personagem
        pcall(function()
            if IsThereChar() then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                hrp.Anchored = false
                hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
            end
        end)
    end

    -- Verifica se o personagem está no Lobby
    local function IsInLobby()
        local lobby = workspace:FindFirstChild("LobbySpawnPad")
        if not lobby then
            return false 
        end
        
        if not IsThereChar() then
            return true
        end
        
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return true
        end
        
        return (hrp.Position - lobby.Position).Magnitude < 150
    end

    -- Verifica se o jogador local é a Besta
    local function AmIBeast()
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

    -- Reduzido o raio para 2.0 studs para evitar conflitos quando dois jogadores usam o mesmo PC
    local function IsTriggerOccupied(trigger)
        local triggerPos = trigger.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsThereChar(p) then
                if (p.Character.HumanoidRootPart.Position - triggerPos).Magnitude < 2.0 then
                    return true
                end
            end
        end
        return false
    end

    -- Detecção de Partida Ativa
    local function IsMatchActive()
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

    -- Detecção de Conclusão do Computador
    local function IsComputerCompleted(computer)
        if not computer then return true end
        
        local t1 = computer:FindFirstChild("ComputerTrigger1")
        local t2 = computer:FindFirstChild("ComputerTrigger2")
        local t3 = computer:FindFirstChild("ComputerTrigger3")
        if not t1 and not t2 and not t3 then
            return true
        end
        
        local screen = computer:FindFirstChild("Screen")
        if screen then
            local color = screen.BrickColor
            if color == BrickColor.new("Dark green") or color == BrickColor.new("Lime green") or color == BrickColor.new("Bright green") then
                return true
            end
            
            local billboard = screen:FindFirstChildOfClass("BillboardGui") or computer:FindFirstChildOfClass("BillboardGui")
            if billboard then
                local textLabel = billboard:FindFirstChildOfClass("TextLabel")
                if textLabel and string.find(string.upper(textLabel.Text), "COMPLETED") then
                    return true
                end
            end
        end
        
        return false
    end

    local function TPPlayerSpawn()
        if IsThereChar() then
            local lobby = workspace:FindFirstChild("LobbySpawnPad")
            if lobby then
                LocalPlayer.Character:PivotTo(lobby.CFrame * CFrame_new(0, 3, 0))
            end
        end
    end

    -- Detecção Otimizada da Besta para Sobreviventes (Correção: Exclusão rígida do LocalPlayer)
    local function GetBeast()
        if fly_cachedBeast then
            if fly_cachedBeast == LocalPlayer or fly_cachedBeast.Parent ~= Players or not IsThereChar(fly_cachedBeast) then
                fly_cachedBeast = nil
            else
                local stats = fly_cachedBeast:FindFirstChild("TempPlayerStatsModule")
                local isBeastVal = stats and stats:FindFirstChild("IsBeast")
                local hasHammer = fly_cachedBeast.Character and (fly_cachedBeast.Character:FindFirstChild("BeastHammer") or fly_cachedBeast.Character:FindFirstChild("Hammer"))
                
                local stillBeast = (isBeastVal and isBeastVal.Value == true) or (hasHammer and hasHammer:IsA("Tool"))
                if not stillBeast then
                    fly_cachedBeast = nil
                end
            end
        end

        if not fly_cachedBeast then
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= LocalPlayer then
                    local stats = v:FindFirstChild("TempPlayerStatsModule")
                    local isBeastVal = stats and stats:FindFirstChild("IsBeast")
                    local hasHammer = v.Character and (v.Character:FindFirstChild("BeastHammer") or v.Character:FindFirstChild("Hammer"))
                    
                    if (isBeastVal and isBeastVal.Value == true) or (hasHammer and hasHammer:IsA("Tool")) then
                        fly_cachedBeast = v
                        break
                    end
                end
            end
        end
        return fly_cachedBeast
    end

    -- LÓGICA DE AUTO WIN SOBREVIVENTE (FLY)
    local function DoSurvivorFarm()
        if fly_onsurvivorfarm then return end
        fly_onsurvivorfarm = true

        local currentSession = fly_SessionId
        print("[FLY START] Session:", currentSession, "Traceback:\n", debug.traceback())

        local DoNotTeleport = false
        local forceEscape = false

        -- Estados de controle local isolados por escopo (farm_)
        local farm_OnComputer = false
        local farm_ChosenComputer = nil
        local farm_ComputerBanList = {}
        local farm_CurrentComputer = nil

        local function PlayerReady()
            if TempPlayerStatsModule then
                local ragdoll = TempPlayerStatsModule:FindFirstChild("Ragdoll")
                if ragdoll and ragdoll.Value then
                    DoNotTeleport = true
                    return false
                end
                local health = TempPlayerStatsModule:FindFirstChild("Health")
                if (health and health.Value <= 0) or TempPlayerStatsModule.IsBeast.Value then
                    return false
                end
            end
            return IsThereChar()
        end

        local function TaskGood()
            return fly_AutoFarmEnabled and not AmIBeast() and IsMatchActive() and PlayerReady() and fly_SessionId == currentSession
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
            task_wait(0.5)
            MapObjects = GetMapObjects()
            loadAttempts = loadAttempts + 1
        end

        local GoTween

        GoTween = function(Part, session)
            if not IsThereChar() or fly_SessionId ~= session then return end
            fly_isMoving = true 
            local Root = LocalPlayer.Character.HumanoidRootPart
            
            Root.Anchored = true
            
            while IsThereChar() and TaskGood() and fly_SessionId == session do
                local currentPos = Root.Position
                local targetPos = Part.Position
                local distanceVector = targetPos - currentPos
                local distance = distanceVector.Magnitude
                
                if distance < 1.5 then
                    break
                end
                
                local dt = RunService.Heartbeat:Wait()
                local speed = Config.FarmTweenSpeed
                local step = speed * dt
                
                if step > distance then
                    step = distance
                end
                
                local direction = distanceVector.Unit
                local nextPosition = currentPos + (direction * step)
                
                Root.CFrame = CFrame_new(nextPosition) * Root.CFrame.Rotation
            end

            if IsThereChar() and fly_SessionId == session then
                Root.Anchored = false
                Root.CFrame = CFrame_new(Part.Position) * Root.CFrame.Rotation
                Root.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                Root.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
            end
            fly_isMoving = false
        end

        local function GetComputer(Computer)
            if TaskGood() and not IsComputerCompleted(Computer) and not farm_OnComputer and fly_SessionId == currentSession then
                farm_OnComputer = true
                local Prioritize = Config.TriggerPrioritization
                local Triggers = {}

                if Prioritize == 1 then
                    Triggers = { Computer:FindFirstChild("ComputerTrigger1"), Computer:FindFirstChild("ComputerTrigger2"), Computer:FindFirstChild("ComputerTrigger3") }
                elseif Prioritize == 2 then
                    Triggers = { Computer:FindFirstChild("ComputerTrigger2"), Computer:FindFirstChild("ComputerTrigger3"), Computer:FindFirstChild("ComputerTrigger1") }
                else
                    Triggers = { Computer:FindFirstChild("ComputerTrigger3"), Computer:FindFirstChild("ComputerTrigger1"), Computer:FindFirstChild("ComputerTrigger2") }
                end

                for i = 1, #Triggers do
                    if forceEscape or fly_SessionId ~= currentSession then break end
                    local v = Triggers[i]
                    if v and TaskGood() and v.ActionSign.Value == 20 and not IsTriggerOccupied(v) and not IsComputerCompleted(Computer) and farm_ChosenComputer == Computer and fly_SessionId == currentSession then
                        local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude

                        if Distance / Config.FarmTweenSpeed < Config.WaitTweenFast then
                            local Time = Distance / Config.FarmTweenSpeed
                            task_wait(Config.WaitTweenFast - Time)
                        end

                        repeat
                            task_wait()
                        until not TaskGood() or forceEscape or fly_bnhide == false or fly_bnhideelapse >= Config.CampHackOut or fly_SessionId ~= currentSession

                        if fly_SessionId ~= currentSession then return end

                        Notify("Objective", "Moving to computer table", 2.5)
                        GoTween(v, currentSession)

                        if IsComputerCompleted(Computer) then farm_CurrentComputer = nil; farm_OnComputer = false; return end
                        if not TaskGood() or forceEscape or fly_SessionId ~= currentSession then farm_CurrentComputer = nil; farm_OnComputer = false; return end
                        if v.ActionSign.Value ~= 20 or (farm_ChosenComputer ~= Computer and farm_ChosenComputer ~= nil) then continue end

                        local Tries = 0
                        repeat
                            task_wait()
                            if forceEscape or fly_SessionId ~= currentSession then break end
                            
                            if farm_CurrentComputer ~= Computer and IsTriggerOccupied(v) then
                                Notify("Keyboard Occupied", "Another player took this spot.", 3)
                                break
                            end

                            if TaskGood() and not fly_bnhide and TempPlayerStatsModule.CurrentAnimation.Value ~= "Typing" and fly_SessionId == currentSession then
                                Tries = Tries + 1
                                if IsThereChar() then
                                    LocalPlayer.Character:PivotTo(v.CFrame)
                                end
                                
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, v.Event)
                                task_wait(0.1)
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                task_wait(0.4)
                            elseif TaskGood() and not fly_bnhide and fly_SessionId == currentSession then
                                if farm_CurrentComputer ~= Computer then
                                    Notify("Hacking", "Successfully started hacking", 3)
                                end
                                farm_CurrentComputer = Computer
                                Tries = 0
                                
                                if Config.AntiPCError then
                                    ReplicatedStorage.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                                end
                            end

                            -- Acampamento detectado no PC
                            if fly_bnhideelapse >= Config.CampHackOut and fly_SessionId == currentSession then
                                farm_ComputerBanList[math_floor(tick() * 1000)] = Computer
                                RemoveSafePlatform()
                                fly_bnhide = false
                                farm_OnComputer = false
                                farm_CurrentComputer = nil
                                fly_bnhideelapse = 0
                                fly_lpos = nil 
                                if IsThereChar() then
                                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                                end

                                local reqLeftVal = ReplicatedStorage:FindFirstChild("ComputersLeft")
                                if reqLeftVal and reqLeftVal.Value <= 0 then
                                    forceEscape = true
                                    Notify("Fleeing Extra PC", "Heading to exit doors!", 4)
                                else
                                    Notify("Fleeing", "The Beast is camping. Changing computers.", 3.5)
                                end
                                return
                            end

                            if Tries >= 15 and TaskGood() and not fly_bnhide and fly_SessionId == currentSession then
                                farm_CurrentComputer = nil
                                farm_OnComputer = false
                                Notify("Error", "Failed to start hacking.", 3)
                                return
                            end
                        until not TaskGood() or forceEscape or IsComputerCompleted(Computer) or (farm_ChosenComputer ~= Computer and farm_ChosenComputer ~= nil) or fly_SessionId ~= currentSession
                    end
                end
                farm_CurrentComputer = nil
                farm_OnComputer = false
            end
        end

        local function Run()
            local CancelComputers = false
            local LeastTriggers = 4
            local Closest = math.huge
            local ComputersLeft = 0

            coroutine.wrap(function()
                while TaskGood() and fly_SessionId == currentSession do
                    task_wait(0.2)
                    
                    if farm_CurrentComputer then
                        farm_ChosenComputer = farm_CurrentComputer
                        continue
                    end

                    ComputersLeft = 0
                    LeastTriggers = 4
                    Closest = math.huge

                    if farm_ChosenComputer and IsComputerCompleted(farm_ChosenComputer) then
                        Notify("Completed", "Computer fully hacked!", 3)
                        farm_ChosenComputer = nil
                    end

                    local BeastObj = GetBeast()
                    local currentTime = tick() * 1000

                    for i = 1, #MapObjects.Computers do
                        local v = MapObjects.Computers[i]
                        local UseTrigger = v:FindFirstChild("ComputerTrigger3")
                        local FoundV = nil

                        for i2, v2 in pairs(farm_ComputerBanList) do
                            if UseTrigger and BeastObj and IsThereChar(BeastObj) and v2 == v and currentTime - i2 > 5000 and (UseTrigger.Position - BeastObj.Character.HumanoidRootPart.Position).Magnitude > Config.HideBeastNearDist + 10 then
                                farm_ComputerBanList[i2] = nil
                            elseif v2 == v then
                                FoundV = v2
                            end
                        end

                        if not IsComputerCompleted(v) then
                            ComputersLeft = ComputersLeft + 1
                        end

                        if not IsComputerCompleted(v) and not FoundV and IsThereChar() then
                            local Triggers = { v:FindFirstChild("ComputerTrigger3"), v:FindFirstChild("ComputerTrigger2"), v:FindFirstChild("ComputerTrigger1") }
                            local Distance = Triggers[1] and (Triggers[1].Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or math.huge
                            local AmtTriggers = 3

                            for i3 = 1, #Triggers do
                                local v2 = Triggers[i3]
                                if v2 and v2.ActionSign.Value ~= 20 then
                                    AmtTriggers = AmtTriggers - 1
                                elseif not v2 then
                                    AmtTriggers = AmtTriggers - 1
                                end
                            end

                            if v == farm_CurrentComputer and AmtTriggers >= 1 then
                                AmtTriggers = AmtTriggers + 1
                            elseif AmtTriggers < 1 then
                                AmtTriggers = -1
                            end

                            if (AmtTriggers >= 1 and AmtTriggers <= LeastTriggers) then
                                if AmtTriggers == LeastTriggers and Distance > Closest then
                                    continue
                                end
                                farm_ChosenComputer = v
                                LeastTriggers = AmtTriggers
                                Closest = Distance
                            end
                        end
                    end
                end
            end)()

            repeat
                task_wait(0.5)
                if fly_SessionId ~= currentSession then return end
                
                local reqLeftVal = ReplicatedStorage:FindFirstChild("ComputersLeft")
                local requiredDone = reqLeftVal and reqLeftVal.Value <= 0

                if requiredDone and farm_ChosenComputer then
                    local BeastObj = GetBeast()
                    if BeastObj and IsThereChar(BeastObj) then
                        local trigger = farm_ChosenComputer:FindFirstChild("ComputerTrigger3")
                        if trigger then
                            local distanceToBeast = (BeastObj.Character.HumanoidRootPart.Position - trigger.Position).Magnitude
                            if distanceToBeast < (Config.HideBeastNearDist + 10) then
                                forceEscape = true
                                Notify("Fleeing Extra PC", "Beast is near the extra PC. Escaping directly!", 4)
                            end
                        end
                    end
                end

                local isFinished = (ComputersLeft < 1) or forceEscape

                if isFinished then
                    CancelComputers = true
                    RemoveSafePlatform()
                    fly_bnhide = false
                    fly_lpos = nil
                    if IsThereChar() then
                        LocalPlayer.Character.HumanoidRootPart.Anchored = false
                    end
                elseif farm_ChosenComputer and not farm_OnComputer then
                    GetComputer(farm_ChosenComputer)
                end
            until not TaskGood() or CancelComputers or fly_SessionId ~= currentSession

            if not TaskGood() or Config.ExitCancel or fly_SessionId ~= currentSession then
                return
            end

            Notify("Escape", "Heading to exit doors.", 4)

            repeat
                task_wait(0.5)
                if fly_SessionId ~= currentSession then return end
                for i = 1, #MapObjects.ExitDoors do
                    local v = MapObjects.ExitDoors[i]
                    if not TaskGood() or fly_SessionId ~= currentSession then continue end

                    repeat
                        task_wait(0.5)
                    until not TaskGood() or fly_bnhide == false or fly_bnhideelapse >= Config.CampEscapeOut or fly_SessionId ~= currentSession

                    if fly_SessionId ~= currentSession then return end

                    if v:FindFirstChild("ExitDoorTrigger") then
                        GoTween(v.ExitDoorTrigger, currentSession)
                        repeat
                            task_wait()
                            if fly_SessionId ~= currentSession then return end
                            if v:FindFirstChild("ExitDoorTrigger") and v.ExitDoorTrigger.ActionSign.Value ~= 0 and not fly_bnhide and IsThereChar() then
                                LocalPlayer.Character:PivotTo(v.ExitDoorTrigger.CFrame * CFrame_new(0, v.ExitDoorTrigger.Size.Y / 2, 0))
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, v.ExitDoorTrigger.Event)
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                task_wait(0.5)
                            end
                        until not TaskGood() or not v:FindFirstChild("ExitDoorTrigger") or fly_bnhideelapse >= Config.CampEscapeOut or fly_SessionId ~= currentSession

                        if fly_bnhideelapse >= Config.CampEscapeOut and IsThereChar() and fly_SessionId == currentSession then
                            RemoveSafePlatform()
                            LocalPlayer.Character.HumanoidRootPart.Anchored = false
                            fly_bnhide = false
                            fly_bnhideelapse = 0
                            fly_lpos = nil
                            continue
                        end
                    end

                    if TaskGood() and fly_SessionId == currentSession then
                        task_wait(0.5)
                        if v:FindFirstChild("ExitArea") then
                            Notify("Escape", "Escaping...", 3)
                            GoTween(v.ExitArea, currentSession)
                        end
                    end
                end
            until not TaskGood() or fly_SessionId ~= currentSession
        end

        local NewFarmTask = coroutine.create(function()
            if PlayerReady() and fly_SessionId == currentSession then
                Notify("Auto Farm", "NexVoid Farm initiated successfully.", 3)
                Run()
                if not DoNotTeleport and fly_SessionId == currentSession then
                    task_wait(1)
                    TPPlayerSpawn()
                end
                fly_onsurvivorfarm = false
            end
        end)
        coroutine.resume(NewFarmTask)
        table.insert(fly_farmtasks, NewFarmTask)
    end

    -- ==========================================
    -- SEÇÃO: MAIN FARMING (BETA)
    -- ==========================================
    Library:CreateSection(Page, "Main Farming (BETA111)")

    Library:CreateToggle(Page, "Enable Auto Farm", false, function(state)
        MasterAutoFarmState = state
        if state then
            if AntiAfkToggleObj then AntiAfkToggleObj.Set(true) end
        else
            if AutoWinSurvivorToggleObj then AutoWinSurvivorToggleObj.Set(false) end
            if AutoWinSurvivorFlyToggleObj then AutoWinSurvivorFlyToggleObj.Set(false) end
            if AutoWinBeastToggleObj then AutoWinBeastToggleObj.Set(false) end
        end
    end)

    -- Auto Win Survivor (Teleport)
    AutoWinSurvivorToggleObj = Library:CreateToggle(Page, "Auto Win Survivor (Teleport)", false, function(state)
        if state and not MasterAutoFarmState then
            task.spawn(function()
                task.wait()
                AutoWinSurvivorToggleObj.Set(false)
                SendNotification("Enable 'Enable Auto Farm' first!", 3)
            end)
            return
        end

        if state then
            if AutoWinSurvivorFlyToggleObj then AutoWinSurvivorFlyToggleObj.Set(false) end
        end

        getgenv().NexVoidLigado = state
        if not state then
            getgenv().FarmRodando = false
        end
    end)

    -- Auto Win Survivor (Fly)
    AutoWinSurvivorFlyToggleObj = Library:CreateToggle(Page, "Auto win survivor (fly)", false, function(state)
        if state and not MasterAutoFarmState then
            task.spawn(function()
                task.wait()
                AutoWinSurvivorFlyToggleObj.Set(false)
                SendNotification("Enable 'Enable Auto Farm' first!", 3)
            end)
            return
        end

        if state then
            if AutoWinSurvivorToggleObj then AutoWinSurvivorToggleObj.Set(false) end
        end

        fly_AutoFarmEnabled = state

        if state then
            if AmIBeast() then
                Notify("NexVoid Active", "Suspended while you are the BEAST.", 3.5)
            else
                Notify("NexVoid Active", "NexVoid Survivor Auto Farm enabled.", 3.5)
                if IsMatchActive() then
                    if not IsInLobby() then
                        task_spawn(DoSurvivorFarm)
                    end
                else
                    Notify("NexVoid", "Waiting for the match to start...", 4)
                end
            end
        else
            Notify("NexVoid Inactive", "NexVoid Auto Farm has been disabled.", 3)
            GlobalReset()
        end
    end)

    -- Auto Win Beast
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

    -- Auto Save (Silent)
    Library:CreateToggle(Page, "Auto Save (Silent)", false, function(state)
        getgenv().AutoHelpSilent = state
        if state then
            SendNotification("Auto Save (Silent) | Players in pod will be saved magically.", 5)
        end
    end)

    -- Auto Save (Teleport)
    AutoSaveTeleportToggleObj = Library:CreateToggle(Page, "Auto Save (Teleport)", false, function(state)
        getgenv().AutoHelpTeleport = state
        if state then
            SendNotification("Auto Help (Teleport) | Ativado", 3)
            
            task.spawn(function()
                local helping = false
                local oldCFrame = nil

                local function getRoot(character)
                    if not character then return nil end
                    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                end

                while getgenv().AutoHelpTeleport do
                    task.wait(0.05)

                    local meChar = LocalPlayer.Character
                    local meRoot = getRoot(meChar)
                    local myStats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
                    
                    if not meChar or not meRoot or not myStats then continue end

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
                                    local atualRoot = getRoot(LocalPlayer.Character)
                                    if atualRoot then
                                        atualRoot.CFrame = alvoRoot.CFrame * CFrame.new(0, -4.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                                    end
                                    RemoteEvent:FireServer("Input", "Action", true)
                                    
                                until not (alvoCaptured.Value and getgenv().AutoHelpTeleport) 
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
        end
    end)


    -- ==========================================
    -- SEÇÃO: FARM SETTINGS
    -- ==========================================
    Library:CreateSection(Page, "Farm Settings")

    -- Anti AFK
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

    -- Auto Rejoin (Disconnection)
    AutoRejoinToggleObj = Library:CreateToggle(Page, "Auto Rejoin (Disconnection)", false, function(state)
        getgenv().AutoRejoinEnabled = state
        if state then
            SendNotification("Auto Rejoin Ativado", 3)
            if not RejoinConnection then
                RejoinConnection = GuiService.ErrorMessageChanged:Connect(function(errorMessage)
                    if getgenv().AutoRejoinEnabled and errorMessage and errorMessage ~= "" then
                        print("[AutoRejoin] Erro detectado: " .. errorMessage .. ". Tentando reconectar...")
                        task_wait(3) 
                        pcall(function()
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end)
                    end
                end)
            end
        else
            if RejoinConnection then
                RejoinConnection:Disconnect()
                RejoinConnection = nil
            end
        end
    end)

    -- Moderator Alert/Kick
    ModAlertToggleObj = Library:CreateToggle(Page, "Moderator Alert/Kick", false, function(state)
        getgenv().ModAlertKickEnabled = state
        
        local GAME_GROUP_ID = 3195655 
        local MINIMUM_MOD_RANK = 200  
        local MOD_ACTION = "KICK"     

        local function checkPlayer(player)
            if player == LocalPlayer then return end
            local isMod = false

            if GAME_GROUP_ID > 0 then
                pcall(function()
                    local rank = player:GetRankInGroup(GAME_GROUP_ID)
                    if rank >= MINIMUM_MOD_RANK then
                        isMod = true
                    end
                end)
            end

            if isMod and getgenv().ModAlertKickEnabled then
                if MOD_ACTION == "KICK" then
                    LocalPlayer:Kick("[Segurança] Um moderador (" .. player.Name .. ") entrou no servidor. Você foi desconectado para evitar punições.")
                elseif MOD_ACTION == "ALERT" then
                    warn("[AVISO DE SEGURANÇA] Moderador detectado no servidor: " .. player.Name)
                    SendNotification("[PERIGO] Moderador detectado: " .. player.Name, 10)
                end
            end
        end

        if state then
            SendNotification("Moderator Alert/Kick Ativado", 3)
            for _, player in ipairs(Players:GetPlayers()) do
                task_spawn(checkPlayer, player)
            end
            if not ModAddedConnection then
                ModAddedConnection = Players.PlayerAdded:Connect(function(player)
                    checkPlayer(player)
                end)
            end
        else
            if ModAddedConnection then
                ModAddedConnection:Disconnect()
                ModAddedConnection = nil
            end
        end
    end)

    -- ==========================================
    -- SCRIPTS DO AUTO FARM E UTILS
    -- ==========================================
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

        task_spawn(function()
            while true do
                task_wait(0.1) 
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

        task_spawn(function()
            while true do
                task_wait(0.1)
                if getgenv().AutoWinBeast then
                    pcall(function()
                        if not IsGameActive.Value or not LocalPlayer:FindFirstChild("TempPlayerStatsModule") then return end

                        local MeuPersonagem = LocalPlayer.Character
                        local MeuEventoMarreta = MeuPersonagem and MeuPersonagem:FindFirstChild("HammerEvent", true)
                        local MinhaRaiz = ObterRaiz(MeuPersonagem)
                        
                        if not MeuEventoMarreta or not MinhaRaiz then return end
                        
                        for _, alvo in pairs(Players:GetPlayers()) do
                            if alvo ~= LocalPlayer and alvo.Character then
                               _ = alvo:FindFirstChild("TempPlayerStatsModule")
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

        task_spawn(function()
            while true do
                task_wait(0.1)
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
                                        task_wait(0.05)
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

    -- GERENCIADOR DE TRANSIÇÃO E ESTADOS DE PARTIDA (Survivor Fly)
    ReplicatedStorage.CurrentMap.Changed:Connect(function(newMap)
        print("[MAP CHANGED]", newMap)
        GlobalReset() -- Limpa e sincroniza todo o estado da rodada de forma instantânea
    end)

    if IsGameActive then
        IsGameActiveConnection = IsGameActive.Changed:Connect(function(active)
            print("[ROUND STATE CHANGED] Active:", active)
            if not active then
                print("[ROUND ENDED]")
            end
            GlobalReset()
        end)
    end

    -- Loop de Monitoramento em Segundo Plano Único
    task_spawn(function()
        while true do
            local dt = task_wait(0.1)
            
            if not IsThereChar() then
                RemoveSafePlatform()
            end

            -- Detecta a mudança dinâmica de papel (Beast <-> Survivor) entre rodadas e limpa o ambiente
            local currentIsBeast = AmIBeast()
            if currentIsBeast ~= lastRoleIsBeast then
                print("[ROLE CHANGED] Old Beast state:", lastRoleIsBeast, "New Beast state:", currentIsBeast)
                lastRoleIsBeast = currentIsBeast
                GlobalReset()
            end

            if not fly_AutoFarmEnabled or not IsMatchActive() then
                if fly_onsurvivorfarm or fly_bnhide then
                    GlobalReset()
                end

                if fly_AutoFarmEnabled then
                    if not notifiedLobby then
                        Notify("Lobby State", "Waiting for the game match to start...", 5)
                        notifiedLobby = true
                    end
                end
                continue
            end

            if notifiedLobby then
                notifiedLobby = false
            end

            TempPlayerStatsModule = LocalPlayer:FindFirstChild("TempPlayerStatsModule")

            if fly_AutoFarmEnabled and AmIBeast() then
                if fly_onsurvivorfarm or fly_bnhide then
                    GlobalReset()
                end
                continue
            end

            if fly_AutoFarmEnabled and not AmIBeast() then
                -- Inicialização segura e única do farm de sobrevivente fora do lobby
                if not IsInLobby() and not fly_onsurvivorfarm then
                    task_spawn(DoSurvivorFarm)
                end

                fly_Beast = GetBeast()

                -- Lógica de Proteção Estática contra Besta
                if Config.HideBeastNear and IsThereChar() and TempPlayerStatsModule and not TempPlayerStatsModule.IsBeast.Value then
                    if (fly_Beast == nil or not IsThereChar(fly_Beast)) then
                        if fly_bnhide then
                            fly_bnhide = false
                            fly_bnhideelapse = 0
                            RemoveSafePlatform()
                            if IsThereChar() then
                                LocalPlayer.Character.HumanoidRootPart.Anchored = false
                                if fly_lpos then
                                    LocalPlayer.Character:PivotTo(fly_lpos)
                                end
                            end
                            fly_lpos = nil
                            Notify("Beast Gone", "Resuming.", 3)
                        end
                    else
                        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
                        local beastPos = fly_Beast.Character.HumanoidRootPart.Position
                        local currentGroundPos = fly_lpos and fly_lpos.Position or playerPos
                        local distance = (beastPos - currentGroundPos).Magnitude
                        
                        if not fly_isMoving then
                            if not fly_bnhide and distance < Config.HideBeastNearDist then
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
                                    
                                    task_spawn(function()
                                        task_wait()
                                        if IsThereChar() then
                                            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                                            LocalPlayer.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
                                        end
                                    end)
                                end)
                                Notify("Beast Warning", "Standing on safe platform.", 3.5)
                            end
                        end

                        if fly_bnhide and fly_lpos and not fly_isMoving then
                            local targetHover = (fly_lpos * CFrame_new(0, 75, 0)).Position
                            if (LocalPlayer.Character.HumanoidRootPart.Position - targetHover).Magnitude > 8 then
                                LocalPlayer.Character:PivotTo(fly_lpos * CFrame_new(0, 75, 0) * CFrame_new(0, 3, 0))
                            end

                            local beastDistanceFromLpos = (beastPos - fly_lpos.Position).Magnitude
                            if beastDistanceFromLpos > (Config.HideBeastNearDist + 15) and TempPlayerStatsModule.Ragdoll.Value == false then
                                RemoveSafePlatform()
                                if IsThereChar() then
                                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                                    LocalPlayer.Character:PivotTo(fly_lpos)
                                end
                                fly_bnhide = false
                                fly_bnhideelapse = 0
                                fly_lpos = nil
                                Notify("Beast Away", "Returning to ground.", 3)
                            end
                        end
                    end
                end

                if fly_bnhide then
                    fly_bnhideelapse = fly_bnhideelapse + dt
                    fly_noelepse = 0
                else
                    fly_noelepse = fly_noelepse + dt
                    if fly_noelepse > Config.TriggerUnCampOut then
                        fly_bnhideelapse = 0
                    end
                end

                if IsThereChar() and LocalPlayer.Character.HumanoidRootPart.Position.Y < -2000 then
                    TPPlayerSpawn()
                end

                -- Monitora contagem de computadores
                local CurrentMap = ReplicatedStorage.CurrentMap.Value
                if CurrentMap then
                    local GotComputers = 0
                    local children = CurrentMap:GetChildren()
                    for i = 1, #children do
                        local child = children[i]
                        if child.Name == "ComputerTable" and not IsComputerCompleted(child) then
                            GotComputers = GotComputers + 1
                        end
                    end
                    if GotComputers ~= fly_Comp then
                        if GotComputers == 0 then
                            fly_onsurvivorfarm = false
                            fly_Beast = nil
                        end
                        fly_Comp = GotComputers
                    end
                end
            end
        end
    end)

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
                                    menorDistancia = distance
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
end
