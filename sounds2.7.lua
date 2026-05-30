return function(env)
    -- Importando as variáveis enviadas pelo script principal
    local Library = env.Library
    local Page = env.Page
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local Workspace = env.Workspace
    local TweenService = env.TweenService
    local Theme = env.Theme
    local UserConfigs = env.UserConfigs
    local GetParentTarget = env.GetParentTarget
    local UserInputService = game:GetService("UserInputService")
    local SoundService = game:GetService("SoundService")

    -- Variaveis de Lógica e Backup do Antigo Script
    local LegitSettings = {MuteSteps = false, MuteJumps = false, MuteHack = false}
    local CurrentSoundIDs = {Running = 0, Jumping = 0, Landing = 0}
    local OriginalSoundBackups = setmetatable({}, {__mode = "k"})

    -- Carregando estados salvos do Bloco de Volumes (Inicia desligado por padrão)
    local VolumesEnabled = UserConfigs["Vol_Enabled"]
    if VolumesEnabled == nil then VolumesEnabled = false end

    local FootstepsVolMultiplier = UserConfigs["Vol_FootstepsMultiplier"] or 1
    local JumpVolMultiplier = UserConfigs["Vol_JumpMultiplier"] or 1
    local FallVolMultiplier = UserConfigs["Vol_FallMultiplier"] or 1

    -- Carregando estado do Silenciador da Beast (Mute Beast Sounds)
    local BeastMuteEnabled = UserConfigs["Legit_BeastMute"]
    if BeastMuteEnabled == nil then BeastMuteEnabled = false end

    -- Instância de som de alta fidelidade para as músicas customizadas
    local MusicSound = Instance.new("Sound")
    MusicSound.Name = "NexVoid_CustomMusic"
    MusicSound.Looped = true
    MusicSound.Volume = 0.5
    MusicSound.Parent = SoundService

    -- Lista de faixas pré-selecionadas solicitadas
    local SongsList = {
        {Name = "six seven", ID = "139780631670217"},
        {Name = "low cortisol", ID = "110919391228823"},
        {Name = "His Love", ID = "140684861805080"},
        {Name = "7 years of trying", ID = "90964788762820"},
        {Name = "7 years", ID = "115598617339786"},
        {Name = "Never Alone", ID = "86404842974521"},
        {Name = "ballerina cappucina", ID = "140675348569592"},
        {Name = "its you", ID = "139010646759693"},
        {Name = "funk brazil", ID = "131443412031360"},
        {Name = "na na na", ID = "94884255368589"}
    }

    -- Armas conhecidas da Beast no Flee the Facility
    local BEAST_WEAPONS = {
        ["Hammer"] = true,
        ["Gemstone Hammer"] = true,
        ["Iron Hammer"] = true,
        ["Mallet"] = true
    }

    -- Sons de aviso gerados localmente pela engine do jogo
    local TARGET_WARNING_SOUNDS = {
        ["action"] = true,
        ["warning"] = true,
        ["heartbeat"] = true,
        ["terror"] = true
    }

    -- Função auxiliar de Gradiente idêntica à do Hub Principal
    local function ApplyGradient(instance, color1, color2, rotation)
        local gradient = instance:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, color1), ColorSequenceKeypoint.new(1.00, color2)}
        gradient.Rotation = rotation or 45
        gradient.Parent = instance
        return gradient
    end

    local function formatID(id)
        if type(id) == "number" and id > 0 then return "rbxassetid://" .. id
        elseif type(id) == "string" and id ~= "" and id ~= "0" then
            if not id:find("rbxassetid://") then return "rbxassetid://" .. id else return id end
        end
        return nil
    end

    local function replaceSounds(character)
        task.spawn(function()
            local rootPart = character:WaitForChild("HumanoidRootPart", 10)
            if not rootPart then return end
            task.wait(0.5)
            if not OriginalSoundBackups[character] then
                OriginalSoundBackups[character] = {}
                for name, _ in pairs(CurrentSoundIDs) do
                    local existingSound = rootPart:FindFirstChild(name)
                    if existingSound and existingSound:IsA("Sound") then OriginalSoundBackups[character][name] = existingSound.SoundId end
                end
            end
            for soundName, soundId in pairs(CurrentSoundIDs) do
                local sound = rootPart:FindFirstChild(soundName)
                if soundId == 0 or soundId == "0" then
                    if sound and OriginalSoundBackups[character] and OriginalSoundBackups[character][soundName] then
                        sound.SoundId = OriginalSoundBackups[character][soundName]
                    end
                else
                    local validId = formatID(soundId)
                    if validId then
                        if sound and sound:IsA("Sound") then sound.SoundId = validId
                        else
                            local newSound = Instance.new("Sound")
                            newSound.Name = soundName
                            newSound.Parent = rootPart
                            newSound.SoundId = validId
                        end
                    end
                end
            end
        end)
    end

    local function RefreshAllSounds() 
        for _, player in ipairs(Players:GetPlayers()) do 
            if player.Character then replaceSounds(player.Character) end 
        end 
    end
    
    local function setupPlayerSoundEvents(player)
        if player.Character then replaceSounds(player.Character) end
        player.CharacterAdded:Connect(function(newCharacter) replaceSounds(newCharacter) end)
    end
    for _, player in ipairs(Players:GetPlayers()) do setupPlayerSoundEvents(player) end
    Players.PlayerAdded:Connect(setupPlayerSoundEvents)

    -- Sincronização original de Mute local
    local function ProcessCharacter(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if not root then return end
        local function MuteLogic(soundObj, typeName)
            if not soundObj then return end
            local targetVol = 0.5
            if typeName == "Running" then targetVol = 0.65 end
            if char == LocalPlayer.Character then
                if typeName == "Running" and LegitSettings.MuteSteps then targetVol = 0 end
                if (typeName == "Jumping" or typeName == "Landing") and LegitSettings.MuteJumps then targetVol = 0 end
            end
            soundObj.Volume = targetVol
            soundObj:GetPropertyChangedSignal("Volume"):Connect(function()
                if char == LocalPlayer.Character then
                    if typeName == "Running" and LegitSettings.MuteSteps then soundObj.Volume = 0 
                    elseif (typeName == "Jumping" or typeName == "Landing") and LegitSettings.MuteJumps then soundObj.Volume = 0 end
                end
            end)
        end
        task.spawn(function()
            local s1 = root:WaitForChild("Running", 5)
            if s1 then MuteLogic(s1, "Running") end
            local s2 = root:WaitForChild("Jumping", 5)
            if s2 then MuteLogic(s2, "Jumping") end
            local s3 = root:WaitForChild("Landing", 5)
            if s3 then MuteLogic(s3, "Landing") end
        end)
    end
    Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(ProcessCharacter) end)
    for _, p in pairs(Players:GetPlayers()) do 
        if p.Character then ProcessCharacter(p.Character) end
        p.CharacterAdded:Connect(ProcessCharacter) 
    end

    local hackSignals = {}
    local hackConnection = nil
    
    local HACK_KEYWORDS = {"keyboard", "typing", "type", "hack", "key"}
    local function isHackSound(sound) 
        local name = sound.Name:lower()
        for _, keyword in ipairs(HACK_KEYWORDS) do 
            if name:find(keyword) then return true end 
        end
        return false 
    end
    
    local function isFromComputer(sound) 
        local parent = sound.Parent
        while parent do 
            if parent.Name == "ComputerTable" then return true end
            parent = parent.Parent 
        end
        return false 
    end
    
    local function muteHack(sound) 
        sound.Volume = 0
        local sig = sound:GetPropertyChangedSignal("Volume"):Connect(function() sound.Volume = 0 end)
        table.insert(hackSignals, {Signal = sig, Object = sound}) 
    end
    
    local noHitSoundEnabled = false
    local noHitSoundSignals = {}
    local HIT_KEYWORDS = {"hit", "smack", "damage", "crack", "bone", "bash", "punch", "impact"}
    
    local function isHitSoundTarget(soundName)
        soundName = soundName:lower()
        for _, keyword in ipairs(HIT_KEYWORDS) do
            if soundName:match(keyword) then return true end
        end
        return false
    end
    
    local function muteIfHitSound(obj)
        if obj:IsA("Sound") and isHitSoundTarget(obj.Name) then
            obj.Volume = 0
            local sig = obj:GetPropertyChangedSignal("Volume"):Connect(function()
                if obj.Volume > 0 then obj.Volume = 0 end
            end)
            table.insert(noHitSoundSignals, {Signal = sig, Object = obj})
        end
    end
    
    local noHitSoundAddedConn = nil

    -- Tabelas fracas e caches rápidos de alta performance para os Sliders de Volume
    local ActiveSounds = setmetatable({}, {__mode = "k"})
    local SoundCategories = setmetatable({}, {__mode = "k"})
    local originalVolumeBackup = setmetatable({}, {__mode = "k"})

    -- Referências de volume estático para evitar o bug de travamento em volume 0
    local BaseVolumes = {
        Footsteps = 0.65,
        Jump = 0.5,
        Fall = 0.5
    }

    local function getSoundCategory(sound)
        local name = sound.Name:lower()
        if TARGET_WARNING_SOUNDS[name] then
            return "BeastWarning"
        elseif name:find("running") or name:find("walk") or name:find("step") then
            return "Footsteps"
        elseif name:find("jumping") or name:find("jump") then
            return "Jump"
        elseif name:find("landing") or name:find("fall") or name:find("land") then
            return "Fall"
        end
        return nil
    end

    local function registerSound(obj)
        if obj:IsA("Sound") then
            ActiveSounds[obj] = true
            if not originalVolumeBackup[obj] then
                originalVolumeBackup[obj] = obj.Volume
            end
            if not SoundCategories[obj] then
                SoundCategories[obj] = getSoundCategory(obj)
            end
        end
    end
    
    -- Varredura e escuta estendidas ao SoundService para interceptar a música de aviso/perseguição
    for _, obj in ipairs(Workspace:GetDescendants()) do registerSound(obj) end
    for _, obj in ipairs(SoundService:GetDescendants()) do registerSound(obj) end
    Workspace.DescendantAdded:Connect(registerSound)
    SoundService.DescendantAdded:Connect(registerSound)

    -- Identifica de forma segura se o jogador é a Beast
    local function checkIsBeast(player)
        if player.Team and player.Team.Name == "Beast" then
            return true
        end
        
        local character = player.Character
        if character then
            for weapon in pairs(BEAST_WEAPONS) do
                if character:FindFirstChild(weapon) then
                    return true
                end
            end
        end
        
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for weapon in pairs(BEAST_WEAPONS) do
                if backpack:FindFirstChild(weapon) then
                    return true
                end
            end
        end
        
        return false
    end

    local BeastCharacter = nil
    local function updateBeastCharacter()
        for _, player in ipairs(Players:GetPlayers()) do
            if checkIsBeast(player) then
                BeastCharacter = player.Character
                return
            end
        end
        BeastCharacter = nil
    end

    -- Sincronizador de volumes otimizado de altíssimo desempenho (Consumo ~0% de CPU)
    task.spawn(function()
        while task.wait(0.3) do
            local enabled = VolumesEnabled
            local stepMult = FootstepsVolMultiplier
            local jumpMult = JumpVolMultiplier
            local fallMult = FallVolMultiplier
            local muteSteps = LegitSettings.MuteSteps
            local muteJumps = LegitSettings.MuteJumps
            local muteBeast = BeastMuteEnabled
            local localChar = LocalPlayer.Character
            
            -- Pré-calcula a Beast ativa uma única vez por ciclo
            updateBeastCharacter()

            for sound in pairs(ActiveSounds) do
                local category = SoundCategories[sound]
                if category then
                    local origVol = originalVolumeBackup[sound] or 0.5
                    local multiplier = 1

                    if category == "BeastWarning" then
                        -- Se for som de aviso/batimento da Beast e a toggle estiver ligada
                        if muteBeast then
                            multiplier = 0
                        else
                            multiplier = 1
                        end
                    else
                        -- Caso contrário, processa o slider de volume geral
                        if enabled then
                            if category == "Footsteps" then
                                multiplier = stepMult
                            elseif category == "Jump" then
                                multiplier = jumpMult
                            elseif category == "Fall" then
                                multiplier = fallMult
                            end
                        end

                        -- Verifica se o som pertence ao LocalPlayer para aplicar o silenciador legítimo
                        if localChar and sound:IsDescendantOf(localChar) then
                            if category == "Footsteps" and muteSteps then
                                multiplier = 0
                            elseif (category == "Jump" or category == "Fall") and muteJumps then
                                multiplier = 0
                            end
                        end

                        -- Silenciador global de barulhos físicos vindos do personagem da Beast
                        if muteBeast and BeastCharacter and sound:IsDescendantOf(BeastCharacter) then
                            multiplier = 0
                        end
                    end

                    local targetVol = origVol * multiplier
                    if sound.Volume ~= targetVol then
                        pcall(function() sound.Volume = targetVol end)
                    end
                end
            end
        end
    end)

    -- =========================================================================
    -- LAYOUT HÍBRIDO (Top 2-Column, Bottom Full-Width)
    -- =========================================================================
    
    -- Container das configurações com ajuste automático de tamanho para evitar gaps
    local SettingsContainer = Instance.new("Frame")
    SettingsContainer.Size = UDim2.new(1, -2, 0, 0)
    SettingsContainer.AutomaticSize = Enum.AutomaticSize.Y
    SettingsContainer.BackgroundTransparency = 1
    SettingsContainer.ZIndex = 10
    SettingsContainer.Parent = Page

    local sLayout = Instance.new("UIListLayout", SettingsContainer)
    sLayout.FillDirection = Enum.FillDirection.Horizontal
    sLayout.Padding = UDim.new(0, 12)
    sLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Volume Settings no Lado Esquerdo (LayoutOrder = 1)
    local VolumeBlock = Instance.new("Frame")
    VolumeBlock.Size = UDim2.new(0.5, -6, 0, 0)
    VolumeBlock.AutomaticSize = Enum.AutomaticSize.Y
    VolumeBlock.BackgroundColor3 = Color3.new(0, 0, 0)
    VolumeBlock.BackgroundTransparency = 0.45
    VolumeBlock.BorderSizePixel = 0
    VolumeBlock.LayoutOrder = 1
    VolumeBlock.ZIndex = 11
    VolumeBlock.Parent = SettingsContainer
    Instance.new("UICorner", VolumeBlock).CornerRadius = UDim.new(0, 6)
    local vStroke = Instance.new("UIStroke", VolumeBlock)
    vStroke.Color = Color3.fromRGB(40, 40, 40)
    vStroke.Thickness = 1

    local vLayout = Instance.new("UIListLayout", VolumeBlock)
    vLayout.SortOrder = Enum.SortOrder.LayoutOrder
    vLayout.Padding = UDim.new(0, 4)
    local vPadding = Instance.new("UIPadding", VolumeBlock)
    vPadding.PaddingTop = UDim.new(0, 8)
    vPadding.PaddingBottom = UDim.new(0, 8)
    vPadding.PaddingLeft = UDim.new(0, 10)
    vPadding.PaddingRight = UDim.new(0, 10)

    -- Mute Settings no Lado Direito (LayoutOrder = 2)
    local MuteBlock = Instance.new("Frame")
    MuteBlock.Size = UDim2.new(0.5, -6, 0, 0)
    MuteBlock.AutomaticSize = Enum.AutomaticSize.Y
    MuteBlock.BackgroundColor3 = Color3.new(0, 0, 0)
    MuteBlock.BackgroundTransparency = 0.45
    MuteBlock.BorderSizePixel = 0
    MuteBlock.LayoutOrder = 2
    MuteBlock.ZIndex = 11
    MuteBlock.Parent = SettingsContainer
    Instance.new("UICorner", MuteBlock).CornerRadius = UDim.new(0, 6)
    local mStroke = Instance.new("UIStroke", MuteBlock)
    mStroke.Color = Color3.fromRGB(40, 40, 40)
    mStroke.Thickness = 1

    local mLayout = Instance.new("UIListLayout", MuteBlock)
    mLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mLayout.Padding = UDim.new(0, 4)
    local mPadding = Instance.new("UIPadding", MuteBlock)
    mPadding.PaddingTop = UDim.new(0, 8)
    mPadding.PaddingBottom = UDim.new(0, 8)
    mPadding.PaddingLeft = UDim.new(0, 10)
    mPadding.PaddingRight = UDim.new(0, 10)

    -- Componentes Compactos da UI com Réplica de Fidelidade 100% ao Hub Original
    local function CreateCompactToggle(parent, text, defaultVal, callback)
        local Tgl = Instance.new("TextButton")
        Tgl.Size = UDim2.new(1, 0, 0, 30)
        Tgl.BackgroundTransparency = 1
        Tgl.Text = ""
        Tgl.ZIndex = parent.ZIndex + 1
        Tgl.Parent = parent

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.Position = UDim2.new(0, 5, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Theme.Font
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextScaled = true 
        local tConst = Instance.new("UITextSizeConstraint", Label)
        tConst.MinTextSize = 7
        tConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
        Label.ZIndex = Tgl.ZIndex + 1
        Label.Parent = Tgl
        
        local Bg = Instance.new("Frame")
        Bg.Size = UDim2.new(0, 30, 0, 14)
        Bg.Position = UDim2.new(1, -30, 0.5, -7)
        Bg.BackgroundColor3 = Theme.SwitchOff
        Bg.ZIndex = Tgl.ZIndex + 1
        Bg.Parent = Tgl
        Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)
        local BgGrad = ApplyGradient(Bg, Theme.SwitchOff, Theme.SwitchOff, 90)
        
        local Cir = Instance.new("Frame")
        Cir.Size = UDim2.new(0, 12, 0, 12)
        Cir.Position = UDim2.new(0, 1, 0.5, -6)
        Cir.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        Cir.ZIndex = Tgl.ZIndex + 2
        Cir.Parent = Bg
        Instance.new("UICorner", Cir).CornerRadius = UDim.new(1, 0)
        
        local state = defaultVal
        
        local function updateVisuals()
            local onPos = UDim2.new(1, -13, 0.5, -6)
            local offPos = UDim2.new(0, 1, 0.5, -6)
            
            if state then
                TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
                BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.AccentDark)}
                TweenService:Create(Cir, TweenInfo.new(0.2), {Position = onPos, BackgroundColor3 = Color3.new(0,0,0)}):Play()
                TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
            else
                TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SwitchOff}):Play()
                BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.SwitchOff), ColorSequenceKeypoint.new(1, Theme.SwitchOff)}
                TweenService:Create(Cir, TweenInfo.new(0.2), {Position = offPos, BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
                TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
            end
        end
        
        Tgl.MouseButton1Click:Connect(function()
            state = not state
            updateVisuals()
            callback(state)
        end)
        
        updateVisuals()
        return {Set = function(val) state = val; updateVisuals(); callback(val) end}
    end

    local function CreateCompactSlider(parent, text, min, max, defaultVal, callback)
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, 0, 0, 35)
        Frame.BackgroundTransparency = 1
        Frame.ZIndex = parent.ZIndex + 1
        Frame.Parent = parent

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -45, 0, 20)
        Label.Position = UDim2.new(0, 5, 0, 2)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.Font = Theme.Font
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextScaled = true 
        local lConst = Instance.new("UITextSizeConstraint", Label)
        lConst.MinTextSize = 7
        lConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
        Label.ZIndex = Frame.ZIndex + 1
        Label.Parent = Frame
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Size = UDim2.new(0, 40, 0, 20)
        ValueLabel.Position = UDim2.new(1, -5, 0, 2)
        ValueLabel.AnchorPoint = Vector2.new(1, 0)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = tostring(defaultVal)
        ValueLabel.Font = Theme.Font
        ValueLabel.TextSize = 11
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.TextColor3 = Theme.Text
        ValueLabel.ZIndex = Frame.ZIndex + 1
        ValueLabel.Parent = Frame
        
        local SliderBar = Instance.new("Frame")
        SliderBar.Size = UDim2.new(1, -10, 0, 8)
        SliderBar.Position = UDim2.new(0, 5, 0, 25)
        SliderBar.BackgroundColor3 = Theme.SwitchOff
        SliderBar.BorderSizePixel = 0
        SliderBar.Parent = Frame
        Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
        
        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0)
        Fill.BackgroundColor3 = Theme.Accent
        Fill.BorderSizePixel = 0
        Fill.Parent = SliderBar
        Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
        ApplyGradient(Fill, Theme.Accent, Theme.AccentDark, 0)
        
        local Trigger = Instance.new("TextButton")
        Trigger.Size = UDim2.new(1, 0, 1, 0)
        Trigger.BackgroundTransparency = 1
        Trigger.Text = ""
        Trigger.Parent = SliderBar
        
        local currentVal = defaultVal
        local dragging = false
        
        local function update(input)
            local pos = UDim2.new(math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1), 0, 1, 0)
            Fill.Size = pos
            local val = math.floor(min + ((max - min) * pos.X.Scale))
            ValueLabel.Text = tostring(val)
            currentVal = val
            callback(val)
        end
        
        Trigger.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
        
        local function setVal(v)
            currentVal = math.clamp(v, min, max)
            local ratio = (currentVal - min) / (max - min)
            TweenService:Create(Fill, TweenInfo.new(0.2), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
            ValueLabel.Text = tostring(currentVal)
            callback(currentVal)
        end
        
        return {Set = setVal}
    end

    local function CreateCompactButton(parent, text, callback)
        local BtnFrame = Instance.new("TextButton")
        BtnFrame.Size = UDim2.new(1, 0, 0, 30)
        BtnFrame.BackgroundTransparency = 1
        BtnFrame.Text = ""
        BtnFrame.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -10, 1, 0)
        Label.Position = UDim2.new(0, 5, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label:SetAttribute("OriginalText", text) 
        Label.Font = Theme.Font
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextScaled = true 
        local tConst = Instance.new("UITextSizeConstraint", Label)
        tConst.MinTextSize = 7
        tConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
        Label.Parent = BtnFrame

        BtnFrame.MouseEnter:Connect(function() TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.Accent}):Play() end)
        BtnFrame.MouseLeave:Connect(function() TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play() end)
        BtnFrame.MouseButton1Click:Connect(callback)
        return BtnFrame
    end

    -- Criando e Populando o Header Volume Settings (Esquerda)
    local VolHeader = Instance.new("Frame")
    VolHeader.Name = "HeaderContainer"
    VolHeader.Size = UDim2.new(1, 0, 0, 20)
    VolHeader.BackgroundTransparency = 1
    VolHeader.Parent = VolumeBlock
    
    local VolTitle = Instance.new("TextLabel")
    VolTitle.Size = UDim2.new(1, 0, 1, 0)
    VolTitle.BackgroundTransparency = 1
    VolTitle.Text = "Volume Settings"
    VolTitle.Font = Theme.Font
    VolTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    VolTitle.TextSize = 12
    VolTitle.TextXAlignment = Enum.TextXAlignment.Left
    VolTitle.Parent = VolHeader

    CreateCompactToggle(VolumeBlock, "Enable Volume Modifier", VolumesEnabled, function(state)
        VolumesEnabled = state
        UserConfigs["Vol_Enabled"] = state
    end)
    
    local FootstepsSlider = CreateCompactSlider(VolumeBlock, "FootSteps Volume", 0, 10, FootstepsVolMultiplier, function(val)
        FootstepsVolMultiplier = val
        UserConfigs["Vol_FootstepsMultiplier"] = val
    end)
    
    local JumpSlider = CreateCompactSlider(VolumeBlock, "Jump Volume", 0, 10, JumpVolMultiplier, function(val)
        JumpVolMultiplier = val
        UserConfigs["Vol_JumpMultiplier"] = val
    end)
    
    local FallSlider = CreateCompactSlider(VolumeBlock, "Fall Volume", 0, 10, FallVolMultiplier, function(val)
        FallVolMultiplier = val
        UserConfigs["Vol_FallMultiplier"] = val
    end)

    CreateCompactButton(VolumeBlock, "Reset Volumes", function()
        FootstepsSlider.Set(1)
        JumpSlider.Set(1)
        FallSlider.Set(1)
    end)

    -- Criando e Populando o Header Mute Settings (Direita)
    local MuteHeader = Instance.new("Frame")
    MuteHeader.Name = "HeaderContainer"
    MuteHeader.Size = UDim2.new(1, 0, 0, 20)
    MuteHeader.BackgroundTransparency = 1
    MuteHeader.Parent = MuteBlock
    
    local MuteTitle = Instance.new("TextLabel")
    MuteTitle.Size = UDim2.new(1, 0, 1, 0)
    MuteTitle.BackgroundTransparency = 1
    MuteTitle.Text = "Mute Settings"
    MuteTitle.Font = Theme.Font
    MuteTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MuteTitle.TextSize = 12
    MuteTitle.TextXAlignment = Enum.TextXAlignment.Left
    MuteTitle.Parent = MuteHeader

    CreateCompactToggle(MuteBlock, "Remove Your Steps", false, function(state) 
        LegitSettings.MuteSteps = state
        if LocalPlayer.Character then ProcessCharacter(LocalPlayer.Character) end 
    end)
    CreateCompactToggle(MuteBlock, "Remove Your Jumps", false, function(state) 
        LegitSettings.MuteJumps = state
        if LocalPlayer.Character then ProcessCharacter(LocalPlayer.Character) end 
    end)
    CreateCompactToggle(MuteBlock, "Remove Pc Hack Sounds", false, function(state) 
        if state then 
            for _, obj in ipairs(Workspace:GetDescendants()) do 
                if obj:IsA("Sound") and isHackSound(obj) and isFromComputer(obj) then muteHack(obj) end 
            end
            hackConnection = Workspace.DescendantAdded:Connect(function(obj) 
                if obj:IsA("Sound") then 
                    if isHackSound(obj) and isFromComputer(obj) then muteHack(obj) end 
                end 
            end) 
        else 
            if hackConnection then hackConnection:Disconnect() hackConnection = nil end
            for _, data in ipairs(hackSignals) do 
                if data.Signal then data.Signal:Disconnect() end
                if data.Object then data.Object.Volume = 0.5 end 
            end
            hackSignals = {} 
        end 
    end)
    CreateCompactToggle(MuteBlock, "No hit sound", false, function(state)
        noHitSoundEnabled = state
        if state then
            local function monitorCharacter(character)
                for _, child in ipairs(character:GetDescendants()) do muteIfHitSound(child) end
                character.DescendantAdded:Connect(function(child)
                    task.defer(function() if child and child.Parent and noHitSoundEnabled then muteIfHitSound(child) end end)
                end)
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then monitorCharacter(player.Character) end
                player.CharacterAdded:Connect(function(c) if noHitSoundEnabled then monitorCharacter(c) end end)
            end
            for _, sound in ipairs(game:GetService("SoundService"):GetDescendants()) do muteIfHitSound(sound) end
            noHitSoundAddedConn = game:GetService("SoundService").DescendantAdded:Connect(function(child)
                task.defer(function() if child and child.Parent and noHitSoundEnabled then muteIfHitSound(child) end end)
            end)
        else
            if noHitSoundAddedConn then noHitSoundAddedConn:Disconnect() noHitSoundAddedConn = nil end
            for _, data in ipairs(noHitSoundSignals) do 
                if data.Signal then data.Signal:Disconnect() end
                if data.Object then data.Object.Volume = 0.5 end
            end
            noHitSoundSignals = {}
        end
    end)
    
    -- Seletor Corrigido para Mute Beast Sounds
    CreateCompactToggle(MuteBlock, "Mute Beast Sounds", BeastMuteEnabled, function(state)
        BeastMuteEnabled = state
        UserConfigs["Legit_BeastMute"] = state
    end)

    -- =========================================================================
    -- MUSIC PLAYER (Design Elegante, Compacto com Dropdown Flutuante)
    -- =========================================================================
    local MusicBlock = Instance.new("Frame")
    MusicBlock.Size = UDim2.new(1, -2, 0, 95) -- Tamanho de segurança de 95px contra colisões
    MusicBlock.BackgroundColor3 = Color3.new(0, 0, 0)
    MusicBlock.BackgroundTransparency = 0.45
    MusicBlock.BorderSizePixel = 0
    MusicBlock.ClipsDescendants = false -- Permite o dropdown flutuar sem problemas
    MusicBlock.ZIndex = 100 -- ZIndex prioritário
    MusicBlock.Parent = Page
    
    local muStroke = Instance.new("UIStroke", MusicBlock)
    muStroke.Color = Color3.fromRGB(40, 40, 40)
    muStroke.Thickness = 1

    local muPadding = Instance.new("UIPadding", MusicBlock)
    muPadding.PaddingTop = UDim.new(0, 10)
    muPadding.PaddingBottom = UDim.new(0, 10)
    muPadding.PaddingLeft = UDim.new(0, 12)
    muPadding.PaddingRight = UDim.new(0, 12)

    local MusicTitle = Instance.new("TextLabel")
    MusicTitle.Size = UDim2.new(0.4, 0, 0, 16)
    MusicTitle.BackgroundTransparency = 1
    MusicTitle.Text = "Music Player"
    MusicTitle.Font = Theme.Font
    MusicTitle.TextColor3 = Theme.Text
    MusicTitle.TextSize = 12
    MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
    MusicTitle.ZIndex = 101
    MusicTitle.Parent = MusicBlock

    -- Entrada Customizada de ID (Fundo preto transparente integrado)
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.32, -6, 0, 28)
    textBox.Position = UDim2.new(0, 0, 0, 42)
    textBox.PlaceholderText = "Insert ID..."
    textBox.Text = ""
    textBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Fundo preto
    textBox.BackgroundTransparency = 0.45 -- Transparente
    textBox.TextColor3 = Theme.Text
    textBox.PlaceholderColor3 = Theme.TextDark
    textBox.Font = Theme.Font
    textBox.TextSize = 10
    textBox.ClearTextOnFocus = true
    textBox.ZIndex = 101
    textBox.Parent = MusicBlock
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)
    local tbStroke = Instance.new("UIStroke", textBox)
    tbStroke.Color = Color3.fromRGB(40, 40, 40)

    -- Botão Seletor de Faixas (Pre-seleções) (Fundo preto transparente integrado)
    local songDropdown = Instance.new("TextButton")
    songDropdown.Size = UDim2.new(0.32, -6, 0, 28)
    songDropdown.Position = UDim2.new(0.32, 6, 0, 42)
    songDropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Fundo preto
    songDropdown.BackgroundTransparency = 0.45 -- Transparente
    songDropdown.Text = "Select Song"
    songDropdown.Font = Theme.Font
    songDropdown.TextSize = 10
    songDropdown.TextColor3 = Theme.TextDark
    songDropdown.ZIndex = 102
    songDropdown.Parent = MusicBlock
    Instance.new("UICorner", songDropdown).CornerRadius = UDim.new(0, 4)
    local sdStroke = Instance.new("UIStroke", songDropdown)
    sdStroke.Color = Color3.fromRGB(40, 40, 40)
    
    local sdArrow = Instance.new("TextLabel")
    sdArrow.Size = UDim2.new(0, 16, 1, 0)
    sdArrow.Position = UDim2.new(1, -18, 0, 0)
    sdArrow.BackgroundTransparency = 1
    sdArrow.Text = "▼"
    sdArrow.Font = Enum.Font.Gotham
    sdArrow.TextColor3 = Theme.TextDark
    sdArrow.TextSize = 8
    sdArrow.ZIndex = 103
    sdArrow.Parent = songDropdown

    -- Container Flutuante do Menu de Músicas com Opacidade Total e Fundo Preto Transparente
    local SongMenu = Instance.new("Frame")
    SongMenu.Size = UDim2.new(1, 0, 0, 134)
    SongMenu.Position = UDim2.new(0, 0, 1, 4)
    SongMenu.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Preto
    SongMenu.BackgroundTransparency = 0.15 -- Transparente/Translúcido elegante
    SongMenu.BorderSizePixel = 0
    SongMenu.Visible = false
    SongMenu.ZIndex = 200
    SongMenu.Parent = songDropdown
    Instance.new("UICorner", SongMenu).CornerRadius = UDim.new(0, 4)
    local smStroke = Instance.new("UIStroke", SongMenu)
    smStroke.Color = Color3.fromRGB(40, 40, 40)
    
    local smScroll = Instance.new("ScrollingFrame", SongMenu)
    smScroll.Size = UDim2.new(1, -4, 1, -4)
    smScroll.Position = UDim2.new(0, 2, 0, 2)
    smScroll.BackgroundTransparency = 1
    smScroll.BorderSizePixel = 0
    smScroll.ScrollBarThickness = 2
    smScroll.ScrollBarImageColor3 = Theme.Accent
    smScroll.CanvasSize = UDim2.new(0, 0, 0, #SongsList * 22)
    smScroll.ZIndex = 201
    
    local smLayout = Instance.new("UIListLayout", smScroll)
    smLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, song in ipairs(SongsList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = song.Name
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 9
        btn.TextColor3 = Theme.TextDark
        btn.ZIndex = 202
        btn.Parent = smScroll
        
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -10, 0, 1)
        sep.Position = UDim2.new(0, 5, 1, -1)
        sep.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        sep.BorderSizePixel = 0
        sep.ZIndex = 203
        sep.Parent = btn
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6, BackgroundColor3 = Color3.fromRGB(255, 255, 255), TextColor3 = Theme.Text}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 1, TextColor3 = Theme.TextDark}):Play()
        end)
        
        btn.MouseButton1Click:Connect(function()
            textBox.Text = song.ID
            songDropdown.Text = song.Name
            SongMenu.Visible = false
            sdArrow.Text = "▼"
        end)
    end

    songDropdown.MouseButton1Click:Connect(function()
        SongMenu.Visible = not SongMenu.Visible
        sdArrow.Text = SongMenu.Visible and "▲" or "▼"
    end)

    -- Sincroniza o seletor quando o ID é colado manualmente
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local currentText = textBox.Text
        local found = false
        for _, s in ipairs(SongsList) do
            if s.ID == currentText then
                songDropdown.Text = s.Name
                found = true
                break
            end
        end
        if not found then
            songDropdown.Text = "Select Song"
        end
    end)

    -- Botão Play/Stop de Canto Inferior Direito sem colisão de Y
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0.34, -12, 0, 28)
    playBtn.Position = UDim2.new(0.66, 12, 0, 42)
    playBtn.BackgroundColor3 = Color3.new(0, 0, 0)
    playBtn.BackgroundTransparency = 0.45
    playBtn.Text = "Play"
    playBtn.Font = Theme.Font
    playBtn.TextSize = 10
    playBtn.TextColor3 = Theme.TextDark
    playBtn.ZIndex = 101
    playBtn.Parent = MusicBlock
    Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 4)
    local pbStroke = Instance.new("UIStroke", playBtn)
    pbStroke.Color = Color3.fromRGB(40, 40, 40)

    playBtn.MouseEnter:Connect(function()
        TweenService:Create(pbStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
        TweenService:Create(playBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
    end)
    playBtn.MouseLeave:Connect(function()
        if playBtn.Text ~= "Stop" then
            TweenService:Create(pbStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
            TweenService:Create(playBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
        end
    end)

    local isPlaying = false
    playBtn.MouseButton1Click:Connect(function()
        if isPlaying then
            MusicSound:Stop()
            isPlaying = false
            playBtn.Text = "Play"
            TweenService:Create(pbStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
            TweenService:Create(playBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
        else
            local text = textBox.Text
            local cleanId = text:match("%d+")
            if cleanId then
                MusicSound:Stop()
                MusicSound.SoundId = "rbxassetid://" .. cleanId
                MusicSound:Play()
                isPlaying = true
                playBtn.Text = "Stop"
                TweenService:Create(pbStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
                TweenService:Create(playBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
            else
                textBox.Text = ""
                textBox.PlaceholderText = "Invalid ID!"
            end
        end
    end)

    -- Slider de Volume da Música (Y = -4 para espaçamento de folga)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0.4, 0, 0, 35)
    sliderFrame.Position = UDim2.new(0.6, 0, 0, -4)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.ZIndex = 101
    sliderFrame.Parent = MusicBlock

    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, -35, 0, 14)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Music Vol"
    sliderLabel.Font = Theme.Font
    sliderLabel.TextColor3 = Theme.TextDark
    sliderLabel.TextSize = 10
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.ZIndex = 102
    sliderLabel.Parent = sliderFrame

    local sliderVal = Instance.new("TextLabel")
    sliderVal.Size = UDim2.new(0, 30, 0, 14)
    sliderVal.Position = UDim2.new(1, -30, 0, 0)
    sliderVal.BackgroundTransparency = 1
    sliderVal.Text = "50%"
    sliderVal.Font = Theme.Font
    sliderVal.TextColor3 = Theme.Text
    sliderVal.TextSize = 10
    sliderVal.TextXAlignment = Enum.TextXAlignment.Right
    sliderVal.ZIndex = 102
    sliderVal.Parent = sliderFrame

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, 0, 0, 5)
    sliderBar.Position = UDim2.new(0, 0, 0, 20)
    sliderBar.BackgroundColor3 = Theme.SwitchOff
    sliderBar.BorderSizePixel = 0
    sliderBar.ZIndex = 102
    sliderBar.Parent = sliderFrame
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0.5, 0, 1, 0) -- default 50%
    sliderFill.BackgroundColor3 = Theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 103
    sliderFill.Parent = sliderBar
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    ApplyGradient(sliderFill, Theme.Accent, Theme.AccentDark, 0)

    local sliderTrigger = Instance.new("TextButton")
    sliderTrigger.Size = UDim2.new(1, 0, 1, 0)
    sliderTrigger.BackgroundTransparency = 1
    sliderTrigger.Text = ""
    sliderTrigger.ZIndex = 104
    sliderTrigger.Parent = sliderBar

    local mDragging = false
    local function updateMusicVol(input)
        local ratio = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
        local pct = math.floor(ratio * 100)
        sliderVal.Text = pct .. "%"
        MusicSound.Volume = ratio
    end

    sliderTrigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mDragging = true
            updateMusicVol(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if mDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateMusicVol(input)
        end
    end)

    -- =========================================================================
    -- DESIGN CLÁSSICO DO SOUND CARD (Largura Inteira Original Restaurado)
    -- =========================================================================
    Library:CreateSection(Page, "Custom Sound Packs")

    local WalkButtons = {}
    local JumpButtons = {}
    local FallButtons = {}

    local savedWalk = UserConfigs["CustomSound_Walk"] or "0"
    local savedJump = UserConfigs["CustomSound_Jump"] or "0"
    local savedFall = UserConfigs["CustomSound_Fall"] or "0"

    CurrentSoundIDs.Running = savedWalk
    CurrentSoundIDs.Jumping = savedJump
    CurrentSoundIDs.Landing = savedFall

    local function updateButtonVisuals(categoryDict, activeId)
        for id, data in pairs(categoryDict) do
            if id == activeId then
                TweenService:Create(data.Btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0, TextColor3 = Color3.new(0,0,0)}):Play()
                TweenService:Create(data.Stroke, TweenInfo.new(0.3), {Color = Theme.Accent, Transparency = 0}):Play()
            else
                TweenService:Create(data.Btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.45, TextColor3 = Color3.fromRGB(150,150,150)}):Play()
                TweenService:Create(data.Stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(40, 40, 40), Transparency = 0}):Play()
            end
        end
    end

    local function CreateSoundCard(Parent, TitleText, Actions)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, -2, 0, 65)
        Card.Position = UDim2.new(0, 1, 0, 0)
        Card.BackgroundColor3 = Color3.new(0, 0, 0)
        Card.BackgroundTransparency = 0.45 
        Card.BorderSizePixel = 0
        Card.ZIndex = 1 -- Definido como baixo para não competir com a lista de música
        Card.Parent = Parent
        
        local cardStroke = Instance.new("UIStroke", Card)
        cardStroke.Color = Color3.fromRGB(40, 40, 40)
        cardStroke.Thickness = 1

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -20, 0, 20)
        Title.Position = UDim2.new(0, 10, 0, 5)
        Title.BackgroundTransparency = 1
        Title.Text = TitleText
        Title:SetAttribute("OriginalText", TitleText)
        Title.TextColor3 = Theme.Text
        Title.Font = Theme.Font
        Title.TextSize = 12
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Card

        local BtnContainer = Instance.new("Frame")
        BtnContainer.Size = UDim2.new(1, -20, 0, 26)
        BtnContainer.Position = UDim2.new(0, 10, 0, 30)
        BtnContainer.BackgroundTransparency = 1
        BtnContainer.Parent = Card

        local layout = Instance.new("UIListLayout", BtnContainer)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        local btnWidth = (1 / #Actions)
        for _, act in ipairs(Actions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(btnWidth, -((#Actions-1)*8 / #Actions), 1, 0)
            btn.BackgroundColor3 = Color3.new(0, 0, 0)
            btn.BackgroundTransparency = 0.45
            btn.Text = act.Name
            btn:SetAttribute("OriginalText", act.Name)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            btn.Parent = BtnContainer
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            local btnStroke = Instance.new("UIStroke", btn)
            btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            btnStroke.Color = Color3.fromRGB(40, 40, 40)
            btnStroke.Thickness = 1

            local actTypeLower = string.lower(act.Type)
            if actTypeLower == "walk" then WalkButtons[act.ID] = {Btn = btn, Stroke = btnStroke}
            elseif actTypeLower == "jump" then JumpButtons[act.ID] = {Btn = btn, Stroke = btnStroke}
            elseif actTypeLower == "fall" then FallButtons[act.ID] = {Btn = btn, Stroke = btnStroke} end

            btn.MouseEnter:Connect(function()
                local activeId = (actTypeLower == "walk" and CurrentSoundIDs.Running) or (actTypeLower == "jump" and CurrentSoundIDs.Jumping) or CurrentSoundIDs.Landing
                if activeId ~= act.ID then
                    TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
                end
            end)
            btn.MouseLeave:Connect(function()
                local activeId = (actTypeLower == "walk" and CurrentSoundIDs.Running) or (actTypeLower == "jump" and CurrentSoundIDs.Jumping) or CurrentSoundIDs.Landing
                if activeId ~= act.ID then
                    TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
                end
            end)

            btn.MouseButton1Click:Connect(function()
                if actTypeLower == "walk" then
                    CurrentSoundIDs.Running = act.ID
                    UserConfigs["CustomSound_Walk"] = act.ID
                    updateButtonVisuals(WalkButtons, act.ID)
                elseif actTypeLower == "jump" then
                    CurrentSoundIDs.Jumping = act.ID
                    UserConfigs["CustomSound_Jump"] = act.ID
                    updateButtonVisuals(JumpButtons, act.ID)
                elseif actTypeLower == "fall" then
                    CurrentSoundIDs.Landing = act.ID
                    UserConfigs["CustomSound_Fall"] = act.ID
                    updateButtonVisuals(FallButtons, act.ID)
                end
                RefreshAllSounds()
            end)
        end
    end

    local ResetBtnFrame = Instance.new("TextButton")
    ResetBtnFrame.Size = UDim2.new(1, -2, 0, 30)
    ResetBtnFrame.Position = UDim2.new(0, 1, 0, 0)
    ResetBtnFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    ResetBtnFrame.BackgroundTransparency = 0.45
    ResetBtnFrame.Text = "Default Sounds (Reset All)"
    ResetBtnFrame.TextColor3 = Color3.fromRGB(150, 150, 150) -- Cor cinza padrão legível
    ResetBtnFrame.Font = Enum.Font.GothamBold
    ResetBtnFrame.TextSize = 11
    ResetBtnFrame.ZIndex = 1 -- Baixo ZIndex de segurança
    ResetBtnFrame.Parent = Page
    Instance.new("UICorner", ResetBtnFrame).CornerRadius = UDim.new(0, 6)
    
    local rbsStr = Instance.new("UIStroke", ResetBtnFrame)
    rbsStr.Color = Color3.fromRGB(40, 40, 40)
    rbsStr.Thickness = 1

    -- Efeitos de hover extremamente legíveis e destacados
    ResetBtnFrame.MouseEnter:Connect(function() 
        TweenService:Create(ResetBtnFrame, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play()
        TweenService:Create(rbsStr, TweenInfo.new(0.2), {Color = Color3.fromRGB(220, 80, 80)}):Play() 
    end)
    ResetBtnFrame.MouseLeave:Connect(function() 
        TweenService:Create(ResetBtnFrame, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        TweenService:Create(rbsStr, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play() 
    end)
    
    ResetBtnFrame.MouseButton1Click:Connect(function()
        CurrentSoundIDs.Running = "0"
        CurrentSoundIDs.Jumping = "0"
        CurrentSoundIDs.Landing = "0"
        UserConfigs["CustomSound_Walk"] = "0"
        UserConfigs["CustomSound_Jump"] = "0"
        UserConfigs["CustomSound_Fall"] = "0"
        updateButtonVisuals(WalkButtons, "0")
        updateButtonVisuals(JumpButtons, "0")
        updateButtonVisuals(FallButtons, "0")
        RefreshAllSounds()
    end)

    -- Inserindo a categoria de som "NorthDxv1Ces" com os botões normalizados (Walk, Jump, Fall)
    CreateSoundCard(Page, "NorthDxv1Ces", {
        {Name = "Walk", ID = "119933956036500", Type = "Walk"},
        {Name = "Jump", ID = "87683560682449", Type = "Jump"},
        {Name = "Fall", ID = "73586375325988", Type = "Fall"}
    })

    CreateSoundCard(Page, "michawell", {
        {Name = "Walk", ID = "116140177933689", Type = "Walk"},
        {Name = "Jump", ID = "70420181848348", Type = "Jump"}
    })

    CreateSoundCard(Page, "DraxynSoulx", {
        {Name = "Walk", ID = "130152479167305", Type = "Walk"},
        {Name = "Jump", ID = "122238807601932", Type = "Jump"},
        {Name = "Fall", ID = "71782790555091", Type = "Fall"}
    })

    CreateSoundCard(Page, "Luana_Mitxu", {
        {Name = "Walk", ID = "107070338913559", Type = "Walk"},
        {Name = "Jump", ID = "133939057526098", Type = "Jump"}
    })

    CreateSoundCard(Page, "Facility Gamer", {
        {Name = "Walk", ID = "131592620665625", Type = "Walk"},
        {Name = "Jump", ID = "89459688918065", Type = "Jump"}
    })

    CreateSoundCard(Page, "NoobTwoPoint", {
        {Name = "Walk", ID = "110709356093026", Type = "Walk"},
        {Name = "Jump", ID = "124276657634407", Type = "Jump"}
    })

    CreateSoundCard(Page, "Tio Morcego", {
        {Name = "Walk", ID = "97458293386939", Type = "Walk"},
        {Name = "Jump", ID = "72503238596964", Type = "Jump"},
        {Name = "Fall", ID = "83702883984130", Type = "Fall"}
    })

    CreateSoundCard(Page, "FKPS", {
        {Name = "Walk", ID = "97733831736820", Type = "Walk"},
        {Name = "Jump", ID = "86031664547378", Type = "Jump"},
        {Name = "Fall", ID = "78180192109919", Type = "Fall"}
    })

    CreateSoundCard(Page, "Normal", {
        {Name = "Walk", ID = "79392671800290", Type = "Walk"},
        {Name = "Jump", ID = "80853972291847", Type = "Jump"},
        {Name = "Fall", ID = "88947883822456", Type = "Fall"}
    })

    CreateSoundCard(Page, "Extra Jumps (Part 1)", {
        {Name = "Pew", ID = "136299701781122", Type = "Jump"},
        {Name = "Sharingan", ID = "118102230060662", Type = "Jump"},
        {Name = "Albino", ID = "129415490412106", Type = "Jump"}
    })

    CreateSoundCard(Page, "Extra Jumps (Part 2)", {
        {Name = "1Rxdrigo", ID = "80276851298640", Type = "Jump"},
        {Name = "Three Jumps", ID = "126925004664723", Type = "Jump"},
        {Name = "Yusei Jump", ID = "119519595212440", Type = "Jump"}
    })

    updateButtonVisuals(WalkButtons, savedWalk)
    updateButtonVisuals(JumpButtons, savedJump)
    updateButtonVisuals(FallButtons, savedFall)
end
