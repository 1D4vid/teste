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

    -- Variaveis de Lógica e Backup do Antigo Script
    local LegitSettings = {MuteSteps = false, MuteJumps = false, MuteHack = false}
    local CurrentSoundIDs = {Running = 0, Jumping = 0, Landing = 0}
    local OriginalSoundBackups = setmetatable({}, {__mode = "k"})

    -- Carregando estados e valores salvos
    local VolumesEnabled = UserConfigs["EnableSoundSettings"]
    if VolumesEnabled == nil then VolumesEnabled = false end

    local FootstepsVolMultiplier = UserConfigs["FootstepsVol"] or 1
    local JumpVolMultiplier = UserConfigs["JumpVol"] or 1
    local FallVolMultiplier = UserConfigs["FallVol"] or 1

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

    -- Tabelas fracas para mapeamento rápido de categorias e preservação de memória
    local ActiveSounds = setmetatable({}, {__mode = "k"})
    local SoundCategories = setmetatable({}, {__mode = "k"})
    local originalVolumeBackup = setmetatable({}, {__mode = "k"})

    local function getSoundCategory(sound)
        local name = sound.Name:lower()
        if name:find("running") or name:find("walk") or name:find("step") then
            return "Footsteps"
        elseif name:find("jumping") or name:find("jump") then
            return "Jump"
        elseif name:find("landing") or name:find("fall") or name:find("land") then
            return "Fall"
        end
        return nil
    end

    -- Processa a categorização uma única vez por objeto de áudio
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
    
    for _, obj in ipairs(Workspace:GetDescendants()) do registerSound(obj) end
    Workspace.DescendantAdded:Connect(registerSound)

    -- Laço de sincronização de alto desempenho
    task.spawn(function()
        while task.wait(0.3) do
            -- Cache local de referências de tabelas para otimizar o processamento interno
            local enabled = VolumesEnabled
            local stepMult = FootstepsVolMultiplier
            local jumpMult = JumpVolMultiplier
            local fallMult = FallVolMultiplier
            local muteSteps = LegitSettings.MuteSteps
            local muteJumps = LegitSettings.MuteJumps

            for sound in pairs(ActiveSounds) do
                local category = SoundCategories[sound]
                if category then
                    local origVol = originalVolumeBackup[sound] or 0.5
                    local multiplier = 1

                    if enabled then
                        if category == "Footsteps" then
                            multiplier = stepMult
                        elseif category == "Jump" then
                            multiplier = jumpMult
                        elseif category == "Fall" then
                            multiplier = fallMult
                        end
                    end

                    -- Silenciador legit
                    if category == "Footsteps" and muteSteps then
                        multiplier = 0
                    elseif (category == "Jump" or category == "Fall") and muteJumps then
                        multiplier = 0
                    end

                    local targetVol = origVol * multiplier
                    -- Alterar propriedade apenas se houver diferença real (Evita stutters na Engine)
                    if sound.Volume ~= targetVol then
                        pcall(function() sound.Volume = targetVol end)
                    end
                end
            end
        end
    end)

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

    -- ==========================================
    -- Interface Visual (Bloco Unificado)
    -- ==========================================
    Library:CreateSection(Page, "Mute Sounds")
    Library:CreateToggle(Page, "Remove Your Steps", false, function(state) 
        LegitSettings.MuteSteps = state
    end)
    Library:CreateToggle(Page, "Remove Your Jumps", false, function(state) 
        LegitSettings.MuteJumps = state
    end)
    Library:CreateToggle(Page, "Remove Pc Hack Sounds", false, function(state) 
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
    Library:CreateToggle(Page, "No hit sound", false, function(state)
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
    
    -- Bloco Unificado de Volumes
    Library:CreateSection(Page, "Volume Settings")
    
    local VolumeBlock = Instance.new("Frame")
    VolumeBlock.Size = UDim2.new(1, -2, 0, 205)
    VolumeBlock.BackgroundColor3 = Color3.new(0, 0, 0)
    VolumeBlock.BackgroundTransparency = 0.45
    VolumeBlock.BorderSizePixel = 0
    VolumeBlock.Parent = Page
    Instance.new("UICorner", VolumeBlock).CornerRadius = UDim.new(0, 6)
    
    local vStroke = Instance.new("UIStroke", VolumeBlock)
    vStroke.Color = Color3.fromRGB(40, 40, 40)
    vStroke.Thickness = 1
    
    local listLayout = Instance.new("UIListLayout", VolumeBlock)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    
    local padding = Instance.new("UIPadding", VolumeBlock)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)

    -- Toggle Customizada (Fiel ao tema original)
    local function CreateCompactToggle(parent, text, defaultVal, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 24)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Theme.Font
        label.TextColor3 = Theme.Text
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local bg = Instance.new("TextButton")
        bg.Size = UDim2.new(0, 30, 0, 14)
        bg.Position = UDim2.new(1, -30, 0.5, -7)
        bg.BackgroundColor3 = Theme.SwitchOff
        bg.Text = ""
        bg.Parent = frame
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
        
        local bgGrad = Instance.new("UIGradient")
        bgGrad.Rotation = 90
        bgGrad.Parent = bg
        
        local cir = Instance.new("Frame")
        cir.Size = UDim2.new(0, 12, 0, 12)
        cir.Position = UDim2.new(0, 1, 0.5, -6)
        cir.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        cir.Parent = bg
        Instance.new("UICorner", cir).CornerRadius = UDim.new(1, 0)
        
        local state = defaultVal
        
        local function updateVisuals()
            if state then
                TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
                bgGrad.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Theme.Accent),
                    ColorSequenceKeypoint.new(1, Theme.AccentDark)
                }
                TweenService:Create(cir, TweenInfo.new(0.2), {Position = UDim2.new(1, -13, 0.5, -6), BackgroundColor3 = Color3.new(0,0,0)}):Play()
            else
                TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SwitchOff}):Play()
                bgGrad.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Theme.SwitchOff),
                    ColorSequenceKeypoint.new(1, Theme.SwitchOff)
                }
                TweenService:Create(cir, TweenInfo.new(0.2), {Position = UDim2.new(0, 1, 0.5, -6), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
            end
        end
        
        bg.MouseButton1Click:Connect(function()
            state = not state
            updateVisuals()
            callback(state)
        end)
        
        updateVisuals()
        return {Set = function(val) state = val; updateVisuals(); callback(val) end}
    end

    -- Slider Customizado (Fiel ao tema original com gradientes)
    local function CreateCompactSlider(parent, text, min, max, defaultVal, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 0, 14)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Theme.Font
        label.TextColor3 = Theme.TextDark
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0, 40, 0, 14)
        valLabel.Position = UDim2.new(1, -40, 0, 0)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = tostring(defaultVal)
        valLabel.Font = Theme.Font
        valLabel.TextColor3 = Theme.Text
        valLabel.TextSize = 11
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.Parent = frame
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 5)
        bar.Position = UDim2.new(0, 0, 0, 20)
        bar.BackgroundColor3 = Theme.SwitchOff
        bar.BorderSizePixel = 0
        bar.Parent = frame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        
        local fillGrad = Instance.new("UIGradient")
        fillGrad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentDark)
        }
        fillGrad.Parent = fill
        
        local trigger = Instance.new("TextButton")
        trigger.Size = UDim2.new(1, 0, 1, 0)
        trigger.BackgroundTransparency = 1
        trigger.Text = ""
        trigger.Parent = bar
        
        local currentVal = defaultVal
        local dragging = false
        
        local function update(input)
            local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            local val = math.floor(min + ((max - min) * ratio))
            valLabel.Text = tostring(val)
            currentVal = val
            callback(val)
        end
        
        trigger.InputBegan:Connect(function(input)
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
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            valLabel.Text = tostring(currentVal)
            callback(currentVal)
        end
        
        return {Set = setVal}
    end

    local function CreateCompactButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = Color3.new(0, 0, 0)
        btn.BackgroundTransparency = 0.45
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = Theme.TextDark
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = Color3.fromRGB(40, 40, 40)
        stroke.Thickness = 1
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
        end)
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Ativador Master do Bloco (Volume Modifier)
    local MasterToggle = CreateCompactToggle(VolumeBlock, "Enable Volume Modifier", VolumesEnabled, function(state)
        VolumesEnabled = state
        UserConfigs["EnableSoundSettings"] = state
    end)

    -- Sliders Individuais com Escala Correta
    local FootstepsSlider = CreateCompactSlider(VolumeBlock, "FootSteps Volume", 0, 10, FootstepsVolMultiplier, function(val)
        FootstepsVolMultiplier = val
        UserConfigs["FootstepsVol"] = val
    end)
    
    local JumpSlider = CreateCompactSlider(VolumeBlock, "Jump Volume", 0, 10, JumpVolMultiplier, function(val)
        JumpVolMultiplier = val
        UserConfigs["JumpVol"] = val
    end)
    
    local FallSlider = CreateCompactSlider(VolumeBlock, "Fall Volume", 0, 10, FallVolMultiplier, function(val)
        FallVolMultiplier = val
        UserConfigs["FallVol"] = val
    end)

    -- Botão de Reset
    CreateCompactButton(VolumeBlock, "Reset Volumes", function()
        FootstepsSlider.Set(1)
        JumpSlider.Set(1)
        FallSlider.Set(1)
    end)
    
    -- Seção Custom Sound Packs
    Library:CreateSection(Page, "Custom Sound Packs")
    local targetParentSounds = GetParentTarget(Page)
    
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
        Card.Parent = Parent
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        
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

            if act.Type == "Walk" then WalkButtons[act.ID] = {Btn = btn, Stroke = btnStroke}
            elseif act.Type == "Jump" then JumpButtons[act.ID] = {Btn = btn, Stroke = btnStroke}
            elseif act.Type == "Fall" then FallButtons[act.ID] = {Btn = btn, Stroke = btnStroke} end

            btn.MouseEnter:Connect(function()
                local activeId = (act.Type == "Walk" and CurrentSoundIDs.Running) or (act.Type == "Jump" and CurrentSoundIDs.Jumping) or CurrentSoundIDs.Landing
                if activeId ~= act.ID then
                    TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
                end
            end)
            btn.MouseLeave:Connect(function()
                local activeId = (act.Type == "Walk" and CurrentSoundIDs.Running) or (act.Type == "Jump" and CurrentSoundIDs.Jumping) or CurrentSoundIDs.Landing
                if activeId ~= act.ID then
                    TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
                end
            end)

            btn.MouseButton1Click:Connect(function()
                if act.Type == "Walk" then
                    CurrentSoundIDs.Running = act.ID
                    UserConfigs["CustomSound_Walk"] = act.ID
                    updateButtonVisuals(WalkButtons, act.ID)
                elseif act.Type == "Jump" then
                    CurrentSoundIDs.Jumping = act.ID
                    UserConfigs["CustomSound_Jump"] = act.ID
                    updateButtonVisuals(JumpButtons, act.ID)
                elseif act.Type == "Fall" then
                    CurrentSoundIDs.Landing = act.ID
                    UserConfigs["CustomSound_Fall"] = act.ID
                    updateButtonVisuals(FallButtons, act.ID)
                end
                RefreshAllSounds()
            end)
        end
    end

    -- Criando o botão Reset Sounds integrado ao layout
    Library:CreateButton(Page, "Reset Sounds", function()
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

    CreateSoundCard(targetParentSounds, "michawell", {
        {Name = "Walk", ID = "116140177933689", Type = "Walk"},
        {Name = "Jump", ID = "70420181848348", Type = "Jump"}
    })

    CreateSoundCard(targetParentSounds, "DraxynSoulx", {
        {Name = "Walk", ID = "130152479167305", Type = "Walk"},
        {Name = "Jump", ID = "122238807601932", Type = "Jump"},
        {Name = "Fall", ID = "71782790555091", Type = "Fall"}
    })

    CreateSoundCard(targetParentSounds, "Luana_Mitxu", {
        {Name = "Walk", ID = "107070338913559", Type = "Walk"},
        {Name = "Jump", ID = "133939057526098", Type = "Jump"}
    })

    CreateSoundCard(targetParentSounds, "Facility Gamer", {
        {Name = "Walk", ID = "131592620665625", Type = "Walk"},
        {Name = "Jump", ID = "89459688918065", Type = "Jump"}
    })

    CreateSoundCard(targetParentSounds, "NoobTwoPoint", {
        {Name = "Walk", ID = "110709356093026", Type = "Walk"},
        {Name = "Jump", ID = "124276657634407", Type = "Jump"}
    })

    CreateSoundCard(targetParentSounds, "Tio Morcego", {
        {Name = "Walk", ID = "97458293386939", Type = "Walk"},
        {Name = "Jump", ID = "72503238596964", Type = "Jump"},
        {Name = "Fall", ID = "83702883984130", Type = "Fall"}
    })

    CreateSoundCard(targetParentSounds, "FKPS", {
        {Name = "Walk", ID = "97733831736820", Type = "Walk"},
        {Name = "Jump", ID = "86031664547378", Type = "Jump"},
        {Name = "Fall", ID = "78180192109919", Type = "Fall"}
    })

    CreateSoundCard(targetParentSounds, "Normal", {
        {Name = "Walk", ID = "79392671800290", Type = "Walk"},
        {Name = "Jump", ID = "80853972291847", Type = "Jump"},
        {Name = "Fall", ID = "88947883822456", Type = "Fall"}
    })

    CreateSoundCard(targetParentSounds, "Extra Jumps (Part 1)", {
        {Name = "Pew", ID = "136299701781122", Type = "Jump"},
        {Name = "Sharingan", ID = "118102230060662", Type = "Jump"},
        {Name = "Albino", ID = "129415490412106", Type = "Jump"}
    })

    CreateSoundCard(targetParentSounds, "Extra Jumps (Part 2)", {
        {Name = "1Rxdrigo", ID = "80276851298640", Type = "Jump"},
        {Name = "Three Jumps", ID = "126925004664723", Type = "Jump"},
        {Name = "Yusei Jump", ID = "119519595212440", Type = "Jump"}
    })

    updateButtonVisuals(WalkButtons, savedWalk)
    updateButtonVisuals(JumpButtons, savedJump)
    updateButtonVisuals(FallButtons, savedFall)
end
