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
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local StarterGui = game:GetService("StarterGui")

    -- Otimizações de performance (Micro-optimizations)
    local Vector3_new = Vector3.new
    local CFrame_new = CFrame.new
    local task_wait = task.wait
    local task_spawn = task.spawn
    local ipairs = ipairs
    local pairs = pairs
    local math_floor = math.floor
    local tick = tick

    local MasterAutoFarmState = false
    local AntiAfkToggleObj
    local AutoWinSurvivorToggleObj
    local AutoWinSurvivorFlyToggleObj
    local AutoWinBeastToggleObj
    local AutoSaveTeleportToggleObj
    local AutoRejoinToggleObj
    local ModAlertToggleObj

    -- Gerenciadores de Conexões Globais
    local RejoinConnection = nil
    local ModAddedConnection = nil

    -- =========================================================================
    -- CONFIGURAÇÕES E ESTADOS INTERNOS DO AUTO FARM FLY (ENGINE)
    -- =========================================================================
    local FlyConfig = {
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

    local fly_AutoFarmEnabled = false
    local fly_onsurvivorfarm = false
    local fly_bnhide = false
    local fly_isMoving = false          
    local fly_bnhideelapse = 0
    local fly_noelepse = 0
    local fly_lpos = nil
    local fly_Beast = nil
    local fly_cachedBeast = nil         
    local fly_safePlatform = nil        
    local fly_farmtasks = {}
    local fly_TempPlayerStatsModule = nil
    local fly_Comp = 0
    local fly_notifiedLobby = false

    local fly_MapConnection = nil
    local fly_BackgroundLoopActive = false

    -- =========================================================================
    -- FUNÇÕES DE SUPORTE DO AUTO FARM FLY
    -- =========================================================================
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
        return char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")
    end

    local function fly_TPPlayerSpawn()
        if fly_IsThereChar() then
            local lobby = workspace:FindFirstChild("LobbySpawnPad")
            if lobby then
                LocalPlayer.Character:PivotTo(lobby.CFrame * CFrame_new(0, 3, 0))
            end
        end
    end

    local function fly_AmIBeast()
        local stats = LocalPlayer:FindFirstChild("TempPlayerStatsModule")
        if stats then
            local isBeastVal = stats:FindFirstChild("IsBeast")
            if isBeastVal and isBeastVal.Value then
                return true
            end
        end
        local char = LocalPlayer.Character
        if char and (char:FindFirstChild("BeastHammer") or char:FindFirstChild("Hammer") or char:FindFirstChild("Weapon")) then
            return true
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
        local isActive = ReplicatedStorage:FindFirstChild("IsGameActive")
        if isActive and not isActive.Value then
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
            return fly_cachedBeast
        end

        for _, v in ipairs(Players:GetPlayers()) do
            local stats = v:FindFirstChild("TempPlayerStatsModule")
            if stats then
                local isBeastVal = stats:FindFirstChild("IsBeast")
                if isBeastVal and isBeastVal.Value then
                    fly_cachedBeast = v
                    return v
                end
            end
            
            local char = v.Character
            if char and (char:FindFirstChild("BeastHammer") or char:FindFirstChild("Hammer") or char:FindFirstChild("Weapon")) then
                fly_cachedBeast = v
                return v
            end
            
            local backpack = v:FindFirstChild("Backpack")
            if backpack and (backpack:FindFirstChild("BeastHammer") or backpack:FindFirstChild("Hammer") or backpack:FindFirstChild("Weapon")) then
                fly_cachedBeast = v
                return v
            end
        end
        fly_cachedBeast = nil
        return nil
    end

    -- =========================================================================
    -- FUNÇÕES DE SUPORTE DO AUTO WIN BEAST ORIGINAL
    -- =========================================================================
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

    -- =========================================================================
    -- LÓGICA PRINCIPAL: SURVIVOR FLY ENGINE
    -- =========================================================================
    local function fly_DoSurvivorFarm()
        local DoNotTeleport = false

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
            return fly_AutoFarmEnabled and not fly_AmIBeast() and fly_IsMatchActive() and PlayerReady()
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
        local GoTween

        GoTween = function(Part)
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
                local speed = FlyConfig.FarmTweenSpeed
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
                local Prioritize = FlyConfig.TriggerPrioritization
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

                        if Distance / FlyConfig.FarmTweenSpeed < FlyConfig.WaitTweenFast then
                            local Time = Distance / FlyConfig.FarmTweenSpeed
                            task_wait(FlyConfig.WaitTweenFast - Time)
                        end

                        repeat
                            task_wait()
                        until not TaskGood() or fly_bnhide == false or fly_bnhideelapse >= FlyConfig.CampHackOut

                        SendNotification("Moving to computer table", 2.5)
                        GoTween(v)

                        if Computer.Screen.BrickColor == BrickColor.new("Dark green") then CurrentComputer = nil; OnComputer = false; return end
                        if not TaskGood() then CurrentComputer = nil; OnComputer = false; return end
                        if v.ActionSign.Value ~= 20 or (ChosenComputer ~= Computer and ChosenComputer ~= nil) then continue end

                        local Tries = 0
                        repeat
                            task_wait()
                            if fly_IsTriggerOccupied(v) then
                                SendNotification("Keyboard Occupied | Another player took this spot.", 3)
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
                                    SendNotification("Hacking | Successfully started hacking", 3)
                                end
                                CurrentComputer = Computer
                                Tries = 0
                                
                                if FlyConfig.AntiPCError then
                                    ReplicatedStorage.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                                end
                            end

                            if fly_bnhideelapse >= FlyConfig.CampHackOut then
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
                                SendNotification("Fleeing | The Beast is camping. Changing computers.", 3.5)
                                return
                            end

                            if Tries >= 15 and TaskGood() and not fly_bnhide then
                                CurrentComputer = nil
                                OnComputer = false
                                SendNotification("Error | Failed to start hacking. Re-trying.", 3)
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
                    task_wait(0.2)
                    
                    if CurrentComputer then
                        ChosenComputer = CurrentComputer
                        continue
                    end

                    ComputersLeft = 0
                    LeastTriggers = 4
                    Closest = math.huge

                    if ChosenComputer and ChosenComputer.Screen.BrickColor == BrickColor.new("Dark green") then
                        SendNotification("Completed | Computer fully hacked!", 3)
                        ChosenComputer = nil
                    end

                    local BeastObj = fly_GetBeast()
                    local currentTime = tick() * 1000

                    for i = 1, #MapObjects.Computers do
                        local v = MapObjects.Computers[i]
                        local UseTrigger = v:FindFirstChild("ComputerTrigger3")
                        local FoundV = nil

                        for i2, v2 in pairs(ComputerBanList) do
                            if UseTrigger and BeastObj and fly_IsThereChar(BeastObj) and v2 == v and currentTime - i2 > 5000 and (UseTrigger.Position - BeastObj.Character.HumanoidRootPart.Position).Magnitude > FlyConfig.HideBeastNearDist + 10 then
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
                if ChosenComputer and not OnComputer then
                    GetComputer(ChosenComputer)
                elseif ComputersLeft < 1 then
                    CancelComputers = true
                end
            until not TaskGood() or CancelComputers

            if not TaskGood() or FlyConfig.ExitCancel then
                return
            end

            SendNotification("Escape | Heading to exit doors.", 4)

            repeat
                task_wait(0.5)
                for i = 1, #MapObjects.ExitDoors do
                    local v = MapObjects.ExitDoors[i]
                    if not TaskGood() then continue end

                    repeat
                        task_wait(0.5)
                    until not TaskGood() or fly_bnhide == false or fly_bnhideelapse >= FlyConfig.CampEscapeOut

                    if v:FindFirstChild("ExitDoorTrigger") then
                        GoTween(v.ExitDoorTrigger)
                        repeat
                            task_wait()
                            if v:FindFirstChild("ExitDoorTrigger") and v.ExitDoorTrigger.ActionSign.Value ~= 0 and not fly_bnhide and fly_IsThereChar() then
                                LocalPlayer.Character:PivotTo(v.ExitDoorTrigger.CFrame * CFrame_new(0, v.ExitDoorTrigger.Size.Y / 2, 0))
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, v.ExitDoorTrigger.Event)
                                ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                task_wait(0.5)
                            end
                        until not TaskGood() or not v:FindFirstChild("ExitDoorTrigger") or fly_bnhideelapse >= FlyConfig.CampEscapeOut

                        if fly_bnhideelapse >= FlyConfig.CampEscapeOut and fly_IsThereChar() then
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
                            SendNotification("Escape | Escaping...", 3)
                            GoTween(v.ExitArea)
                        end
                    end
                end
            until not TaskGood()
        end

        local NewFarmTask = coroutine.create(function()
            if PlayerReady() and not fly_onsurvivorfarm then
                fly_onsurvivorfarm = true
                SendNotification("Auto Farm | NexVoid Farm initiated successfully.", 3)
                Run()
                if not DoNotTeleport then
                    task_wait(1)
                    fly_TPPlayerSpawn()
                end
                fly_onsurvivorfarm = false
            end
        end)
        coroutine.resume(NewFarmTask)
        table.insert(fly_farmtasks, NewFarmTask)
    end

    -- =========================================================================
    -- LOOP DE MONITORAMENTO EM SEGUNDO PLANO (AUTO FARM FLY / TELEPORT)
    -- =========================================================================
    local function fly_StartBackgroundLoop()
        if fly_BackgroundLoopActive then return end
        fly_BackgroundLoopActive = true
        
        task_spawn(function()
            while fly_AutoFarmEnabled or getgenv().NexVoidLigado do
                local dt = task_wait(0.1)
                
                if not fly_IsThereChar() then
                    fly_RemoveSafePlatform()
                end

                -- Se for a Besta, apenas pausa o Survivor Farm sem desativar a toggle
                if (fly_AutoFarmEnabled or getgenv().NexVoidLigado) and fly_AmIBeast() then
                    for i, v in pairs(fly_farmtasks) do
                        pcall(function()
                            coroutine.close(v)
                        end)
                        fly_farmtasks[i] = nil
                    end
                    fly_onsurvivorfarm = false
                    fly_RemoveSafePlatform()
                    if fly_IsThereChar() then
                        LocalPlayer.Character.HumanoidRootPart.Anchored = false
                    end
                    
                    pcall(function()
                        if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("SimpleAutoFarmGUI") then
                            LocalPlayer.PlayerGui.SimpleAutoFarmGUI.MainFrame.StatusLabel.Text = "Status: Paused (Beast Round)"
                        end
                    end)
                    continue 
                end

                if not (fly_AutoFarmEnabled or getgenv().NexVoidLigado) or not fly_IsMatchActive() then
                    if fly_IsThereChar() and LocalPlayer.Character.HumanoidRootPart.Anchored then
                        LocalPlayer.Character.HumanoidRootPart.Anchored = false
                    end
                    fly_RemoveSafePlatform()
                    fly_onsurvivorfarm = false
                    fly_bnhide = false
                    fly_Comp = 0 
                    
                    if fly_AutoFarmEnabled or getgenv().NexVoidLigado then
                        if not fly_notifiedLobby then
                            SendNotification("Lobby State | Waiting for the game match to start...", 5)
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

                -- Proteção com Plataforma Estática (Fly e Teleport)
                if FlyConfig.HideBeastNear and fly_IsThereChar() and fly_TempPlayerStatsModule and not fly_TempPlayerStatsModule.IsBeast.Value then
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
                            SendNotification("Beast Gone | Resuming.", 3)
                        end
                    else
                        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
                        local beastPos = fly_Beast.Character.HumanoidRootPart.Position
                        local currentGroundPos = fly_lpos and fly_lpos.Position or playerPos
                        local distance = (beastPos - currentGroundPos).Magnitude
                        
                        local isMoving = fly_AutoFarmEnabled and fly_isMoving
                        
                        if not isMoving then
                            if not fly_bnhide and distance < FlyConfig.HideBeastNearDist then
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
                                        if fly_IsThereChar() then
                                            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                                            LocalPlayer.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
                                        end
                                    end)
                                end)
                                SendNotification("Beast Warning | Standing on safe platform.", 3.5)
                            end
                        end

                        if fly_bnhide and fly_lpos and not isMoving then
                            local targetHover = (fly_lpos * CFrame_new(0, 75, 0)).Position
                            if (LocalPlayer.Character.HumanoidRootPart.Position - targetHover).Magnitude > 8 then
                                LocalPlayer.Character:PivotTo(fly_lpos * CFrame_new(0, 75, 0) * CFrame_new(0, 3, 0))
                            end

                            local beastDistanceFromLpos = (beastPos - fly_lpos.Position).Magnitude
                            if beastDistanceFromLpos > (FlyConfig.HideBeastNearDist + 15) and fly_TempPlayerStatsModule.Ragdoll.Value == false then
                                fly_RemoveSafePlatform()
                                if fly_IsThereChar() then
                                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                                    LocalPlayer.Character:PivotTo(fly_lpos)
                                end
                                fly_bnhide = false
                                fly_bnhideelapse = 0
                                fly_lpos = nil
                                SendNotification("Beast Away | Returning to ground.", 3)
                            end
                        end
                    end
                end

                if fly_bnhide then
                    fly_bnhideelapse = fly_bnhideelapse + dt
                    fly_noelepse = 0
                else
                    fly_noelepse = fly_noelepse + dt
                    if fly_noelepse > FlyConfig.TriggerUnCampOut then
                        fly_bnhideelapse = 0
                    end
                end

                if fly_IsThereChar() and LocalPlayer.Character.HumanoidRootPart.Position.Y < -2000 then
                    fly_TPPlayerSpawn()
                end

                -- Retomada Survivor automática quando as condições permitirem
                if fly_AutoFarmEnabled and not fly_onsurvivorfarm and not fly_AmIBeast() and fly_IsMatchActive() then
                    task_spawn(fly_DoSurvivorFarm)
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
                            task_wait(3)
                            if fly_AutoFarmEnabled and not fly_onsurvivorfarm and not fly_AmIBeast() then
                                task_spawn(fly_DoSurvivorFarm)
                            end
                        else
                            fly_onsurvivorfarm = false
                            fly_Beast = nil
                        end
                        fly_Comp = GotComputers
                    end
                end
            end
            fly_BackgroundLoopActive = false
        end)
    end


    -- =========================================================================
    -- ELEMENTOS DA INTERFACE (TABS / TOGGLES)
    -- =========================================================================
    Library:CreateSection(Page, "Main Farming (BETA)")

    -- Enable Auto Farm
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
        if state then
            if not MasterAutoFarmState then
                task.spawn(function()
                    task.wait()
                    AutoWinSurvivorToggleObj.Set(false)
                    SendNotification("Enable 'Enable Auto Farm' first!", 3)
                end)
                return
            end
            if AutoWinSurvivorFlyToggleObj then AutoWinSurvivorFlyToggleObj.Set(false) end
            
            -- Ativa o loop de segurança em background para monitorar a Besta no modo Teleport
            fly_StartBackgroundLoop()
        else
            getgenv().FarmRodando = false
        end

        getgenv().NexVoidLigado = state
        if not state then
            getgenv().FarmRodando = false
        end
    end)

    -- Auto Win Survivor (Fly)
    AutoWinSurvivorFlyToggleObj = Library:CreateToggle(Page, "Auto win survivor (fly)", false, function(state)
        if state then
            if not MasterAutoFarmState then
                task.spawn(function()
                    task.wait()
                    AutoWinSurvivorFlyToggleObj.Set(false)
                    SendNotification("Enable 'Enable Auto Farm' first!", 3)
                end)
                return
            end
            if AutoWinSurvivorToggleObj then AutoWinSurvivorToggleObj.Set(false) end
        end

        fly_AutoFarmEnabled = state

        if state then
            fly_StartBackgroundLoop()
            
            if not fly_MapConnection then
                fly_MapConnection = ReplicatedStorage.CurrentMap.Changed:Connect(function(newMap)
                    if newMap and fly_AutoFarmEnabled and not fly_onsurvivorfarm then
                        if fly_AmIBeast() then return end
                        SendNotification("Match | Starting in 3 seconds.", 4)
                        task_wait(3)
                        task_spawn(fly_DoSurvivorFarm)
                    end
                end)
            end

            if fly_IsMatchActive() and not fly_AmIBeast() then
                task_spawn(fly_DoSurvivorFarm)
            else
                SendNotification("NexVoid | Waiting for the match to start...", 4)
            end
        else
            if fly_MapConnection then
                fly_MapConnection:Disconnect()
                fly_MapConnection = nil
            end

            for i, v in pairs(fly_farmtasks) do
                pcall(function()
                    coroutine.close(v)
                end)
                fly_farmtasks[i] = nil
            end

            fly_onsurvivorfarm = false
            fly_RemoveSafePlatform()
            if fly_IsThereChar() then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
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
                                    
                                end until not (alvoCaptured.Value and getgenv().AutoHelpTeleport) 
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


    -- =========================================================================
    -- SEÇÃO: FARM SETTINGS
    -- =========================================================================
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
                        task.wait(3)
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
                    warn("[AVISO DE SEGURANÇA] Moderator detectado no servidor: " .. player.Name)
                    SendNotification("[PERIGO] Moderador detectado: " .. player.Name, 10)
                end
            end
        end

        if state then
            SendNotification("Moderator Alert/Kick Ativado", 3)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(checkPlayer, player)
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

    -- Fly Speed Slider (Posicionado no final da categoria)
    Library:CreateSlider(Page, "Fly Farm Speed", 16, 30, 22, function(val)
        FlyConfig.FarmTweenSpeed = val
    end)


    -- =========================================================================
    -- DETECTORES DO AUTO FARM TELEPORT CLASSIC E OUTROS LOOPS DE SUPORTE
    -- =========================================================================
    local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
    local IsGameActive = ReplicatedStorage:WaitForChild("IsGameActive")

    -- [[ ANTI AFK LOOP ]] --
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

    -- [[ AUTO-EQUIP DA MARRETA EM SEGUNDO PLANO ]] --
    task.spawn(function()
        while true do
            task.wait(0.5) -- Loop leve executado a cada 0.5 segundos
            if getgenv().AutoWinBeast and IsGameActive.Value then
                pcall(function()
                    local char = LocalPlayer.Character
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if char and backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                            -- Localiza qualquer marreta ou ferramenta com o evento de ataque
                            if tool:IsA("Tool") and (tool.Name:match("Hammer") or tool.Name:match("Mallet") or tool:FindFirstChild("HammerEvent")) then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if hum then
                                    hum:EquipTool(tool)
                                end
                                break
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- [[ AUTO WIN BEAST - CHASE LOOP ORIGINAL ]] --
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
                    
                    if RaizAlvo and LocalPlayer.Character then
                        LocalPlayer.Character:PivotTo(RaizAlvo.CFrame * CFrame.new(0, 0, 1.5))
                        MinhaRaiz.Velocity = Vector3.zero 
                    end
                end)
            end
        end
    end)

    -- [[ AUTO WIN BEAST - ATTACK LOOP ORIGINAL ]] --
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
                            local alvoCaptured = Stats:FindFirstChild("Captured")
                            local RaizAlvo = ObterRaiz(alvo.Character)
                            
                            if RaizAlvo and alvoCaptured and not alvoCaptured.Value then
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

    -- [[ AUTO WIN BEAST - FREEZEPOD LOOP ORIGINAL ]] --
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
                            local alvoCaptured = Stats:FindFirstChild("Captured")
                            
                            if alvoCaido and alvoCaido.Value == true and alvoCaptured and alvoCaptured.Value == false then
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

    -- [[ AUTO WIN SURVIVOR (TELEPORT CLASSIC) ]] --
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
            if fly_bnhide then return false end -- Pausa as ações se estiver escondido da Beast
            
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

    -- [[ AUTO SAVE (SILENT) BACKEND ]] --
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
