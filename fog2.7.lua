return function(env)
    local Library = env.Library
    local Page = env.Page
    local Lighting = env.Lighting
    local RunService = env.RunService
    local SendNotification = env.SendNotification

    -- [ COLUNA DIREITA: Color Calibrator ] --
    Library:CreateSection(Page, "Color Calibrator", "Right")
    
    local CalibratorState = { enabled = false, fullbright = false, contrast = 0, brightness = 0, saturation = 0, hue = 0, opacity = 1 }
    local origAmbient = Lighting.Ambient
    local origColorShiftBottom = Lighting.ColorShift_Bottom
    local origColorShiftTop = Lighting.ColorShift_Top
    local origGlobalShadows = Lighting.GlobalShadows
    local origFogEnd = Lighting.FogEnd

    Lighting.Changed:Connect(function(prop)
        if not CalibratorState.fullbright then
            if prop == "Ambient" then origAmbient = Lighting.Ambient end
            if prop == "ColorShift_Bottom" then origColorShiftBottom = Lighting.ColorShift_Bottom end
            if prop == "ColorShift_Top" then origColorShiftTop = Lighting.ColorShift_Top end
            if prop == "GlobalShadows" then origGlobalShadows = Lighting.GlobalShadows end
            if prop == "FogEnd" then origFogEnd = Lighting.FogEnd end
        end
    end)

    local EFFECT_NAME = "NexVoid_ColorCalibrator"
    local function getOrCreateEffect()
        local eff = Lighting:FindFirstChild(EFFECT_NAME)
        if not eff then
            pcall(function() eff = Instance.new("ColorCorrectionEffect"); eff.Name = EFFECT_NAME; eff.Parent = Lighting end)
        end
        return eff
    end

    local function ApplyCalibrator()
        local eff = getOrCreateEffect()
        if not eff then return end
        
        if not CalibratorState.enabled then
            eff.Enabled = false
            return
        end

        local op = math.clamp(CalibratorState.opacity, 0, 1)
        eff.Brightness = CalibratorState.brightness * op
        eff.Contrast = CalibratorState.contrast * op
        eff.Saturation = CalibratorState.saturation * op
        
        local hueUnit = (((CalibratorState.hue % 360) + 360) % 360) / 360
        local tintSat = math.clamp(math.abs(CalibratorState.hue) / 180 * 0.5, 0, 1)
        local tintCol = Color3.fromHSV(hueUnit, tintSat, 1)
        eff.TintColor = Color3.new(1 + (tintCol.R - 1)*op, 1 + (tintCol.G - 1)*op, 1 + (tintCol.B - 1)*op)
        eff.Enabled = true
    end

    Library:CreateToggle(Page, "Enable Calibrator", false, function(state)
        CalibratorState.enabled = state
        ApplyCalibrator()
    end)

    local s1 = Library:CreateSlider(Page, "Contrast", -100, 100, 0, function(val)
        CalibratorState.contrast = val / 100
        ApplyCalibrator()
    end)

    local s2 = Library:CreateSlider(Page, "Brightness", -100, 100, 0, function(val)
        CalibratorState.brightness = val / 100
        ApplyCalibrator()
    end)

    local s3 = Library:CreateSlider(Page, "Saturation", -100, 300, 0, function(val)
        CalibratorState.saturation = val / 100
        ApplyCalibrator()
    end)

    local s4 = Library:CreateSlider(Page, "Hue Filter", -180, 180, 0, function(val)
        CalibratorState.hue = val
        ApplyCalibrator()
    end)

    local s5 = Library:CreateSlider(Page, "Filter Opacity", 0, 100, 100, function(val)
        CalibratorState.opacity = val / 100
        ApplyCalibrator()
    end)

    Library:CreateButton(Page, "Reset Calibrator", function()
        if s1 and s1.Set then s1.Set(0) end
        if s2 and s2.Set then s2.Set(0) end
        if s3 and s3.Set then s3.Set(0) end
        if s4 and s4.Set then s4.Set(0) end
        if s5 and s5.Set then s5.Set(100) end
        SendNotification("Color Calibrator Reset!", 2)
    end)

    -- [ COLUNA ESQUERDA: Fog ] --
    Library:CreateSection(Page, "Fog", "Left")
    
    local noFogEnabled = false
    local originalAtmos = setmetatable({}, {__mode = "k"})
    local originalSky = setmetatable({}, {__mode = "k"})
    local noFogAddedConn = nil

    local function arrumarAtmosphere(atm)
        if not noFogEnabled then return end
        if not originalAtmos[atm] then
            originalAtmos[atm] = {
                Color = atm.Color, Glare = atm.Glare, Haze = atm.Haze, Decay = atm.Decay, Density = atm.Density, Offset = atm.Offset
            }
        end
        atm.Color = Color3.fromRGB(0, 0, 0)
        atm.Glare = 0
        atm.Haze = 10
        atm.Decay = Color3.fromRGB(0, 0, 0)
        atm.Density = 0
        atm.Offset = 0
        if not atm:FindFirstChild("NoFogLock") then
            local lock = Instance.new("Folder")
            lock.Name = "NoFogLock"
            lock.Parent = atm
            atm:GetPropertyChangedSignal("Density"):Connect(function()
                if noFogEnabled and atm.Density ~= 0 then
                    atm.Density = 0
                end
            end)
        end
    end

    local function arrumarSky(sky)
        if not noFogEnabled then return end
        if not originalSky[sky] then
            originalSky[sky] = { MoonAngularSize = sky.MoonAngularSize, StarCount = sky.StarCount }
        end
        sky.MoonAngularSize = 10
        sky.StarCount = 0
    end

    Library:CreateToggle(Page, "No fog", false, function(state)
        noFogEnabled = state
        if state then
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then arrumarAtmosphere(atm) end
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if sky then arrumarSky(sky) end
            noFogAddedConn = Lighting.ChildAdded:Connect(function(filho)
                task.defer(function()
                    if filho:IsA("Atmosphere") then
                        arrumarAtmosphere(filho)
                    elseif filho:IsA("Sky") then
                        arrumarSky(filho)
                    end
                end)
            end)
        else
            if noFogAddedConn then noFogAddedConn:Disconnect(); noFogAddedConn = nil end
            for atm, data in pairs(originalAtmos) do
                if atm and atm.Parent then
                    atm.Color = data.Color; atm.Glare = data.Glare; atm.Haze = data.Haze
                    atm.Decay = data.Decay; atm.Density = data.Density; atm.Offset = data.Offset
                end
            end
            for sky, data in pairs(originalSky) do
                if sky and sky.Parent then
                    sky.MoonAngularSize = data.MoonAngularSize; sky.StarCount = data.StarCount
                end
            end
            table.clear(originalAtmos)
            table.clear(originalSky)
        end
    end)

    local BlackFogLoop = nil
    local OriginalAtmosphereData = nil

    Library:CreateToggle(Page, "Black Fog", false, function(state)
        if state then
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then
                OriginalAtmosphereData = {
                    Color = atm.Color, Glare = atm.Glare, Haze = atm.Haze,
                    Decay = atm.Decay, Density = atm.Density, Offset = atm.Offset
                }
            else
                OriginalAtmosphereData = "None"
            end
            BlackFogLoop = task.spawn(function()
                while state do
                    task.wait(1)
                    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
                    if not atmosphere then
                        atmosphere = Instance.new("Atmosphere")
                        atmosphere.Parent = Lighting
                    end
                    if atmosphere.Density ~= 0.75 or atmosphere.Haze ~= 2.46 then
                        atmosphere.Color = Color3.fromRGB(0, 0, 0)
                        atmosphere.Glare = 0
                        atmosphere.Haze = 2.46
                        atmosphere.Decay = Color3.fromRGB(0, 0, 0)
                        atmosphere.Density = 0.75
                        atmosphere.Offset = 0
                    end
                end
            end)
        else
            if BlackFogLoop then task.cancel(BlackFogLoop); BlackFogLoop = nil end
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if OriginalAtmosphereData == "None" then
                if atm then atm:Destroy() end
            elseif OriginalAtmosphereData and type(OriginalAtmosphereData) == "table" then
                if atm then
                    atm.Color = OriginalAtmosphereData.Color; atm.Glare = OriginalAtmosphereData.Glare
                    atm.Haze = OriginalAtmosphereData.Haze; atm.Decay = OriginalAtmosphereData.Decay
                    atm.Density = OriginalAtmosphereData.Density; atm.Offset = OriginalAtmosphereData.Offset
                end
            end
        end
    end)

    local originalExposure = Lighting.ExposureCompensation
    local flashlightLoop = nil
    Library:CreateToggle(Page, "FlashLight", false, function(state)
        if state then
            pcall(function() Lighting.ExposureCompensation = 2.8 end)
            flashlightLoop = task.spawn(function()
                while true do
                    pcall(function() Lighting.ExposureCompensation = 2.8 end)
                    task.wait(1)
                end
            end)
        else
            if flashlightLoop then task.cancel(flashlightLoop); flashlightLoop = nil end
            pcall(function() Lighting.ExposureCompensation = originalExposure end)
        end
    end)

    local FullbrightLoopPro = nil
    Library:CreateToggle(Page, "Enable FullBright", false, function(state)
        CalibratorState.fullbright = state
        if state then
            FullbrightLoopPro = RunService.RenderStepped:Connect(function()
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
                Lighting.ColorShift_Top = Color3.new(1, 1, 1)
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 100000
            end)
        else
            if FullbrightLoopPro then FullbrightLoopPro:Disconnect(); FullbrightLoopPro = nil end
            Lighting.Ambient = origAmbient
            Lighting.ColorShift_Bottom = origColorShiftBottom
            Lighting.ColorShift_Top = origColorShiftTop
            Lighting.GlobalShadows = origGlobalShadows
            Lighting.FogEnd = origFogEnd
        end
    end)

    -- [ COLUNA ESQUERDA: Fog Setting ] --
    Library:CreateSection(Page, "Fog Setting", "Left")

    Library:CreateColorPicker(Page, "Fog Color", Color3.fromRGB(128, 128, 128), function(color)
        pcall(function()
            Lighting.FogColor = color
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then
                atm.Color = color
                atm.Decay = color
            end
        end)
    end)

    Library:CreateSlider(Page, "Fog Power", 0, 100, 50, function(val)
        pcall(function()
            -- Sistema moderno (Atmosphere)
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then
                atm.Density = val / 100
            end
            
            -- Sistema clássico (FogEnd)
            -- 0% de força = Neblina muito distante (100000)
            -- 100% de força = Neblina muito próxima (100)
            local classicFog = 100000 - (val * 999)
            Lighting.FogEnd = math.max(100, classicFog)
        end)
    end)
end
