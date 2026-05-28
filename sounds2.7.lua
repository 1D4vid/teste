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

    -- Variaveis de Lógica e Controle
    local LegitSettings = {MuteSteps = false, MuteJumps = false, MuteHack = false}
    
    -- Configurações de Volume (Toggle Master desativada por padrão)
    local VolumesEnabled = UserConfigs["EnableSoundSettings"]
    if VolumesEnabled == nil then VolumesEnabled = false end

    local FootstepsVolMultiplier = UserConfigs["FootstepsVol"] or 1
    local JumpVolMultiplier = UserConfigs["JumpVol"] or 1
    local FallVolMultiplier = UserConfigs["FallVol"] or 1

    -- Tabelas fracas e caches para otimização de performance
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

    -- Laço de sincronização de volumes otimizado em segundo plano (Prevenção de Lag)
    task.spawn(function()
        while task.wait(0.3) do
            local enabled = VolumesEnabled
            local stepMult = FootstepsVolMultiplier
            local jumpMult = JumpVolMultiplier
            local fallMult = FallVolMultiplier
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

                    -- Aplica silenciador local do usuário
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

    -- =========================================================================
    -- SECTION: MUTE SETTINGS (Coluna Esquerda)
    -- =========================================================================
    Library:CreateSection(Page, "Mute Settings", "Left")
    
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

    -- =========================================================================
    -- SECTION: VOLUME CUSTOMIZATION (Coluna Direita)
    -- =========================================================================
    Library:CreateSection(Page, "Volume Customization", "Right")
    
    local MasterToggle = Library:CreateToggle(Page, "Enable Volume Modifier", VolumesEnabled, function(state)
        VolumesEnabled = state
        UserConfigs["EnableSoundSettings"] = state
    end)
    
    local FootstepsSlider = Library:CreateSlider(Page, "FootSteps Volume", 0, 10, FootstepsVolMultiplier, function(val)
        FootstepsVolMultiplier = val
        UserConfigs["FootstepsVol"] = val
    end)
    
    local JumpSlider = Library:CreateSlider(Page, "Jump Volume", 0, 10, JumpVolMultiplier, function(val)
        JumpVolMultiplier = val
        UserConfigs["JumpVol"] = val
    end)
    
    local FallSlider = Library:CreateSlider(Page, "Fall Volume", 0, 10, FallVolMultiplier, function(val)
        FallVolMultiplier = val
        UserConfigs["FallVol"] = val
    end)

    Library:CreateButton(Page, "Reset Volumes", function()
        FootstepsSlider.Set(1)
        JumpSlider.Set(1)
        FallSlider.Set(1)
    end)
end
