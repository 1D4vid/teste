return function(env)
    local Library = env.Library
    local Page = env.Page
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local Workspace = env.Workspace
    local TweenService = env.TweenService
    local Theme = env.Theme
    local UserConfigs = env.UserConfigs
    local GetParentTarget = env.GetParentTarget
    local SoundService = game:GetService("SoundService")

    local LegitSettings = {MuteSteps = false, MuteJumps = false, MuteHack = false, MuteBeastSounds = false}
    local CurrentSoundIDs = {Running = 0, Jumping = 0, Landing = 0}
    local OriginalSoundBackups = setmetatable({}, {__mode = "k"})

    local VolumesEnabled = UserConfigs["Vol_Enabled"]
    if VolumesEnabled == nil then VolumesEnabled = false end

    local FootstepsVolMultiplier = UserConfigs["Vol_FootstepsMultiplier"] or 1
    local JumpVolMultiplier = UserConfigs["Vol_JumpMultiplier"] or 1
    local FallVolMultiplier = UserConfigs["Vol_FallMultiplier"] or 1

    local MuteBeastSoundsEnabled = UserConfigs["Legit_MuteBeastSounds"]
    if MuteBeastSoundsEnabled == nil then MuteBeastSoundsEnabled = false end
    LegitSettings.MuteBeastSounds = MuteBeastSoundsEnabled

    local CustomMusicID = ""
    local MusicSound = Instance.new("Sound")
    MusicSound.Name = "NexVoid_CustomMusic"
    MusicSound.Looped = true
    MusicSound.Volume = 0.5
    MusicSound.Parent = SoundService

    local SongsList = {
        ["six seven"] = "139780631670217",
        ["low cortisol"] = "110919391228823",
        ["His Love"] = "140684861805080",
        ["7 years of trying"] = "90964788762820",
        ["7 years"] = "115598617339786",
        ["Never Alone"] = "86404842974521",
        ["ballerina cappucina"] = "140675348569592",
        ["its you"] = "139010646759693",
        ["funk brazil"] = "131443412031360",
        ["na na na"] = "94884255368589"
    }

    local songNames = {"None", "six seven", "low cortisol", "His Love", "7 years of trying", "7 years", "Never Alone", "ballerina cappucina", "its you", "funk brazil", "na na na"}

    local BEAST_WEAPONS = {
        ["Hammer"] = true,
        ["Gemstone Hammer"] = true,
        ["Iron Hammer"] = true,
        ["Mallet"] = true
    }

    local TARGET_WARNING_SOUNDS = {
        ["action"] = true,
        ["warning"] = true,
        ["heartbeat"] = true,
        ["terror"] = true
    }

    local function checkIsBeast(player)
        if player.Team and player.Team.Name == "Beast" then
            return true
        end
        local character = player.Character
        if character then
            for weapon in pairs(BEAST_WEAPONS) do
                if character:FindFirstChild(weapon) then return true end
            end
        end
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for weapon in pairs(BEAST_WEAPONS) do
                if backpack:FindFirstChild(weapon) then return true end
            end
        end
        return false
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
    local originalVolumeBackup = {}
    
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

    local ActiveSounds = setmetatable({}, {__mode = "k"})
    local SoundCategories = setmetatable({}, {__mode = "k"})

    local BaseVolumes = {
        Footsteps = 0.65,
        Jump = 0.5,
        Fall = 0.5
    }

    local function getSoundCategory(sound)
        local name = sound.Name:lower()
        if TARGET_WARNING_SOUNDS[name] then
            return "BeastWarning"
        end

        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and sound:IsDescendantOf(char) then
                if checkIsBeast(player) then
                    return "BeastSound"
                else
                    if name:find("running") or name:find("walk") or name:find("step") then
                        return "Footsteps"
                    elseif name:find("jumping") or name:find("jump") then
                        return "Jump"
                    elseif name:find("landing") or name:find("fall") or name:find("land") then
                        return "Fall"
                    end
                end
            end
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

    local lastCacheClear = os.clock()
    task.spawn(function()
        while task.wait(0.3) do
            if os.clock() - lastCacheClear > 4 then
                lastCacheClear = os.clock()
                table.clear(SoundCategories)
                for s in pairs(ActiveSounds) do
                    SoundCategories[s] = getSoundCategory(s)
                end
            end

            local enabled = VolumesEnabled
            local stepMult = FootstepsVolMultiplier
            local jumpMult = JumpVolMultiplier
            local fallMult = FallVolMultiplier
            local muteSteps = LegitSettings.MuteSteps
            local muteJumps = LegitSettings.MuteJumps
            local muteBeast = LegitSettings.MuteBeastSounds
            local localChar = LocalPlayer.Character
            local localIsBeast = checkIsBeast(LocalPlayer)

            for sound in pairs(ActiveSounds) do
                local category = SoundCategories[sound]
                if category then
                    local origVol = originalVolumeBackup[sound] or 0.5
                    local multiplier = 1

                    if category == "BeastWarning" then
                        if localIsBeast or muteBeast then
                            multiplier = 0
                        else
                            multiplier = 1
                        end
                    elseif category == "BeastSound" then
                        if muteBeast then
                            multiplier = 0
                        else
                            multiplier = 1
                        end
                    else
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
                    end

                    local targetVol = BaseVolumes[category] or 0.5
                    targetVol = targetVol * multiplier
                    if sound.Volume ~= targetVol then
                        pcall(function() sound.Volume = targetVol end)
                    end
                end
            end
        end
    end)

    Library:CreateSection(Page, "Mute Sounds")

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

    Library:CreateToggle(Page, "Mute Beast Sounds", LegitSettings.MuteBeastSounds, function(state)
        LegitSettings.MuteBeastSounds = state
        UserConfigs["Legit_MuteBeastSounds"] = state
    end)

    Library:CreateSection(Page, "Volume Settings")

    local VolToggle = Library:CreateToggle(Page, "Enable Volume Modifier", VolumesEnabled, function(state)
        VolumesEnabled = state
        UserConfigs["Vol_Enabled"] = state
    end)

    local FootstepsSlider = Library:CreateSlider(Page, "FootSteps Volume", 0, 10, FootstepsVolMultiplier, function(val)
        FootstepsVolMultiplier = val
        UserConfigs["Vol_FootstepsMultiplier"] = val
    end)

    local JumpSlider = Library:CreateSlider(Page, "Jump Volume", 0, 10, JumpVolMultiplier, function(val)
        JumpVolMultiplier = val
        UserConfigs["Vol_JumpMultiplier"] = val
    end)

    local FallSlider = Library:CreateSlider(Page, "Fall Volume", 0, 10, FallVolMultiplier, function(val)
        FallVolMultiplier = val
        UserConfigs["Vol_FallMultiplier"] = val
    end)

    Library:CreateButton(Page, "Reset Volumes", function()
        VolToggle.Set(false)
        FootstepsSlider.Set(1)
        JumpSlider.Set(1)
        FallSlider.Set(1)
    end)

    Library:CreateSection(Page, "Music Player")

    Library:CreateDropdown(Page, "Select Song", songNames, "None", function(selectedName)
        if selectedName == "None" then
            MusicSound:Stop()
        else
            local id = SongsList[selectedName]
            if id then
                MusicSound:Stop()
                MusicSound.SoundId = "rbxassetid://" .. id
                MusicSound:Play()
            end
        end
    end)

    Library:CreateInput(Page, "Custom ID", "", function(val)
        CustomMusicID = val
    end)

    Library:CreateButton(Page, "Play Custom ID", function()
        local cleanId = CustomMusicID:match("%d+")
        if cleanId then
            MusicSound:Stop()
            MusicSound.SoundId = "rbxassetid://" .. cleanId
            MusicSound:Play()
        end
    end)

    Library:CreateButton(Page, "Stop Music", function()
        MusicSound:Stop()
    end)

    Library:CreateSlider(Page, "Music Volume", 0, 100, 50, function(val)
        MusicSound.Volume = val / 100
    end)

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
    ResetBtnFrame.TextColor3 = Color3.fromRGB(150, 150, 150)
    ResetBtnFrame.Font = Enum.Font.GothamBold
    ResetBtnFrame.TextSize = 11
    ResetBtnFrame.Parent = targetParentSounds
    Instance.new("UICorner", ResetBtnFrame).CornerRadius = UDim.new(0, 6)
    
    local rbsStr = Instance.new("UIStroke", ResetBtnFrame)
    rbsStr.Color = Color3.fromRGB(40, 40, 40)
    rbsStr.Thickness = 1

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

    CreateSoundCard(targetParentSounds, "NorthDxv1Ces", {
        {Name = "Walk", ID = "119933956036500", Type = "Walk"},
        {Name = "Jump", ID = "87683560682449", Type = "Jump"},
        {Name = "Fall", ID = "73586375325988", Type = "Fall"}
    })

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
