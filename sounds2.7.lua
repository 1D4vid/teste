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

    -- =========================================================================
    -- CONVERSÃO DINÂMICA PARA O DESIGN MODERNO (LeftCol / RightCol)
    -- =========================================================================
    if Page:GetAttribute("OldStyle") == true then
        Page:SetAttribute("OldStyle", false)
        
        local oldLayout = Page:FindFirstChildOfClass("UIListLayout")
        if oldLayout then oldLayout:Destroy() end
        local oldPadding = Page:FindFirstChildOfClass("UIPadding")
        if oldPadding then oldPadding:Destroy() end

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.FillDirection = Enum.FillDirection.Horizontal
        PageLayout.Padding = UDim.new(0, 12) 
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        local PP = Instance.new("UIPadding")
        PP.PaddingBottom = UDim.new(0, 10)
        PP.Parent = Page

        local LeftCol = Instance.new("Frame")
        LeftCol.Name = "LeftCol"
        LeftCol.Size = UDim2.new(0.5, -6, 0, 0)
        LeftCol.AutomaticSize = Enum.AutomaticSize.Y
        LeftCol.BackgroundTransparency = 1
        LeftCol.Parent = Page
        local LL = Instance.new("UIListLayout")
        LL.Padding = UDim.new(0, 10)
        LL.SortOrder = Enum.SortOrder.LayoutOrder
        LL.Parent = LeftCol

        local RightCol = Instance.new("Frame")
        RightCol.Name = "RightCol"
        RightCol.Size = UDim2.new(0.5, -6, 0, 0)
        RightCol.AutomaticSize = Enum.AutomaticSize.Y
        RightCol.BackgroundTransparency = 1
        RightCol.Parent = Page
        local RL = Instance.new("UIListLayout")
        RL.Padding = UDim.new(0, 10)
        RL.SortOrder = Enum.SortOrder.LayoutOrder
        RL.Parent = RightCol

        local SectionCount = Instance.new("IntValue")
        SectionCount.Name = "SectionCount"
        SectionCount.Value = 0
        SectionCount.Parent = Page
    end

    -- Variaveis de Lógica e Backup do Antigo Script
    local LegitSettings = {MuteSteps = false, MuteJumps = false, MuteHack = false}
    local CurrentSoundIDs = {Running = 0, Jumping = 0, Landing = 0}
    local OriginalSoundBackups = setmetatable({}, {__mode = "k"})

    -- Carregando estados salvos do Bloco de Volumes (Inicia desligado por padrão)
    local VolumesEnabled = UserConfigs["SoundPage_Enable Volume Modifier"]
    if VolumesEnabled == nil then VolumesEnabled = false end

    local FootstepsVolMultiplier = UserConfigs["SoundPage_FootSteps Volume"] or 1
    local JumpVolMultiplier = UserConfigs["SoundPage_Jump Volume"] or 1
    local FallVolMultiplier = UserConfigs["SoundPage_Fall Volume"] or 1

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

    -- Sincronização e monitoramento de volumes
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

    -- Tabelas fracas para mapeamento rápido de categorias de volume
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
            local enabled = UserConfigs["SoundPage_Enable Volume Modifier"]
            local stepMult = UserConfigs["SoundPage_FootSteps Volume"] or 1
            local jumpMult = UserConfigs["SoundPage_Jump Volume"] or 1
            local fallMult = UserConfigs["SoundPage_Fall Volume"] or 1
            local muteSteps = LegitSettings.MuteSteps
            local muteJumps = LegitSettings.MuteJumps
            local localChar = LocalPlayer.Character

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

                    if localChar and sound:IsDescendantOf(localChar) then
                        if category == "Footsteps" and muteSteps then
                            multiplier = 0
                        elseif (category == "Jump" or category == "Fall") and muteJumps then
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
    -- COLUNA ESQUERDA (Left Column)
    -- =========================================================================
    Library:CreateSection(Page, "Mute Settings", "Left")
    
    Library:CreateToggle(Page, "Remove Your Steps", false, function(state) 
        LegitSettings.MuteSteps = state
        if LocalPlayer.Character then ProcessCharacter(LocalPlayer.Character) end 
    end)
    
    Library:CreateToggle(Page, "Remove Your Jumps", false, function(state) 
        LegitSettings.MuteJumps = state
        if LocalPlayer.Character then ProcessCharacter(LocalPlayer.Character) end 
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

    -- =========================================================================
    -- COLUNA DIREITA (Right Column)
    -- =========================================================================
    Library:CreateSection(Page, "Volume Settings", "Right")
    
    Library:CreateToggle(Page, "Enable Volume Modifier", false, function(state)
        VolumesEnabled = state
    end)
    
    local FootstepsSlider = Library:CreateSlider(Page, "FootSteps Volume", 0, 10, 1, function(val)
        FootstepsVolMultiplier = val
    end)
    
    local JumpSlider = Library:CreateSlider(Page, "Jump Volume", 0, 10, 1, function(val)
        JumpVolMultiplier = val
    end)
    
    local FallSlider = Library:CreateSlider(Page, "Fall Volume", 0, 10, 1, function(val)
        FallVolMultiplier = val
    end)

    Library:CreateButton(Page, "Reset Volumes", function()
        FootstepsSlider.Set(1)
        JumpSlider.Set(1)
        FallSlider.Set(1)
    end)

    -- =========================================================================
    -- GERENCIADOR DE SOUND CARDS (Design Unificado)
    -- =========================================================================
    local WalkButtons = {}
    local JumpButtons = {}
    local FallButtons = {}

    local function CreateSoundCard(ParentPage, TitleText, Actions)
        local parent = GetParentTarget(ParentPage)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 48)
        Card.BackgroundTransparency = 1
        Card.Parent = parent

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 16)
        Title.BackgroundTransparency = 1
        Title.Text = TitleText
        Title:SetAttribute("OriginalText", TitleText)
        Title.TextColor3 = Theme.TextDark
        Title.Font = Theme.Font
        Title.TextSize = 10
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Card

        local BtnContainer = Instance.new("Frame")
        BtnContainer.Size = UDim2.new(1, 0, 0, 24)
        BtnContainer.Position = UDim2.new(0, 0, 0, 18)
        BtnContainer.BackgroundTransparency = 1
        BtnContainer.Parent = Card

        local layout = Instance.new("UIListLayout", BtnContainer)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        local btnWidth = (1 / #Actions)
        for _, act in ipairs(Actions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(btnWidth, -((#Actions-1)*6 / #Actions), 1, 0)
            btn.BackgroundColor3 = Color3.new(0, 0, 0)
            btn.BackgroundTransparency = 0.45
            btn.Text = act.Name
            btn:SetAttribute("OriginalText", act.Name)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            btn.Parent = BtnContainer
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

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

    -- =========================================================================
    -- SOUND PACKS: COLUNA ESQUERDA (Left Column)
    -- =========================================================================
    Library:CreateSection(Page, "Sound Packs (Part 1)", "Left")

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

    -- =========================================================================
    -- SOUND PACKS: COLUNA DIREITA (Right Column)
    -- =========================================================================
    Library:CreateSection(Page, "Sound Packs (Part 2)", "Right")

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

    -- =========================================================================
    -- EXTRA SOUND PACKS (Right Column)
    -- =========================================================================
    Library:CreateSection(Page, "Extra Sound Packs", "Right")

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

    updateButtonVisuals(WalkButtons, savedWalk)
    updateButtonVisuals(JumpButtons, savedJump)
    updateButtonVisuals(FallButtons, savedFall)
end
