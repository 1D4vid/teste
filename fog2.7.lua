return function(env)
    local Library = env.Library
    local Page = env.Page
    local Lighting = env.Lighting
    local RunService = env.RunService
    local SendNotification = env.SendNotification

    -- Cache de valores constantes para poupar memória
    local COLOR_WHITE = Color3.new(1, 1, 1)
    local COLOR_BLACK = Color3.new(0, 0, 0)
    local COLOR_GRAY = Color3.fromRGB(128, 128, 128)

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
    local cachedEffect = nil

    local function getOrCreateEffect()
        if cachedEffect and cachedEffect.Parent == Lighting then
            return cachedEffect
        end
        local eff = Lighting:FindFirstChild(EFFECT_NAME)
        if not eff then
            pcall(function() 
                eff = Instance.new("ColorCorrectionEffect")
                eff.Name = EFFECT_NAME
                eff.Parent = Lighting 
            end)
        end
        cachedEffect = eff
        return eff
    end

    local function ApplyCalibrator()
        local eff = getOrCreateEffect()
        if not eff then return end
        
        local isEnabled = CalibratorState.enabled
        if eff.Enabled ~= isEnabled then
            eff.Enabled = isEnabled
        end
        if not isEnabled then return end

        local op = math.clamp(CalibratorState.opacity, 0, 1)
        local targetBrightness = CalibratorState.brightness * op
        local targetContrast = CalibratorState.contrast * op
        local targetSaturation = CalibratorState.saturation * op

        if eff.Brightness ~= targetBrightness then eff.Brightness = targetBrightness end
        if eff.Contrast ~= targetContrast then eff.Contrast = targetContrast end
        if eff.Saturation ~= targetSaturation then eff.Saturation = targetSaturation end
        
        local hueUnit = (((CalibratorState.hue % 360) + 360) % 360) / 360
        local tintSat = math.clamp(math.abs(CalibratorState.hue) / 180 * 0.5, 0, 1)
        local tintCol = Color3.fromHSV(hueUnit, tintSat, 1)
        local targetTintColor = Color3.new(1 + (tintCol.R - 1)*op, 1 + (tintCol.G - 1)*op, 1 + (tintCol.B - 1)*op)
        
        if eff.TintColor ~= targetTintColor then
            eff.TintColor = targetTintColor
        end
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
        if atm.Color ~= COLOR_BLACK then atm.Color = COLOR_BLACK end
        if atm.Glare ~= 0 then atm.Glare = 0 end
        if atm.Haze ~= 10 then atm.Haze = 10 end
        if atm.Decay ~= COLOR_BLACK then atm.Decay = COLOR_BLACK end
        if atm.Density ~= 0 then atm.Density = 0 end
        if atm.Offset ~= 0 then atm.Offset = 0 end
        
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
        if sky.MoonAngularSize ~= 10 then sky.MoonAngularSize = 10 end
        if sky.StarCount ~= 0 then sky.StarCount = 0 end
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
                    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
                    if not atmosphere then
                        atmosphere = Instance.new("Atmosphere")
                        atmosphere.Parent = Lighting
                    end
                    -- Apenas reescreve propriedades se forem alteradas por outros scripts
                    if atmosphere.Color ~= COLOR_BLACK then atmosphere.Color = COLOR_BLACK end
                    if atmosphere.Glare ~= 0 then atmosphere.Glare = 0 end
                    if atmosphere.Haze ~= 2.46 then atmosphere.Haze = 2.46 end
                    if atmosphere.Decay ~= COLOR_BLACK then atmosphere.Decay = COLOR_BLACK end
                    if atmosphere.Density ~= 0.75 then atmosphere.Density = 0.75 end
                    if atmosphere.Offset ~= 0 then atmosphere.Offset = 0 end
                    task.wait(1)
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
            if Lighting.ExposureCompensation ~= 2.8 then
                pcall(function() Lighting.ExposureCompensation = 2.8 end)
            end
            flashlightLoop = task.spawn(function()
                while true do
                    -- Verifica antes de gravar para poupar processamento
                    if Lighting.ExposureCompensation ~= 2.8 then
                        pcall(function() Lighting.ExposureCompensation = 2.8 end)
                    end
                    task.wait(1.5)
                end
            end)
        else
            if flashlightLoop then task.cancel(flashlightLoop); flashlightLoop = nil end
            pcall(function() Lighting.ExposureCompensation = originalExposure end)
        end
    end)

    local FullbrightConn = nil
    local function enforceFullbright()
        if Lighting.Ambient ~= COLOR_WHITE then Lighting.Ambient = COLOR_WHITE end
        if Lighting.ColorShift_Bottom ~= COLOR_WHITE then Lighting.ColorShift_Bottom = COLOR_WHITE end
        if Lighting.ColorShift_Top ~= COLOR_WHITE then Lighting.ColorShift_Top = COLOR_WHITE end
        if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
        if Lighting.FogEnd ~= 100000 then Lighting.FogEnd = 100000 end
    end

    Library:CreateToggle(Page, "Enable FullBright", false, function(state)
        CalibratorState.fullbright = state
        if state then
            enforceFullbright()
            -- Event-driven: Só executa se algo mudar o Lighting (0% de uso de CPU quando parado)
            FullbrightConn = Lighting.Changed:Connect(function()
                if CalibratorState.fullbright then
                    enforceFullbright()
                end
            end)
        else
            if FullbrightConn then FullbrightConn:Disconnect(); FullbrightConn = nil end
            Lighting.Ambient = origAmbient
            Lighting.ColorShift_Bottom = origColorShiftBottom
            Lighting.ColorShift_Top = origColorShiftTop
            Lighting.GlobalShadows = origGlobalShadows
            Lighting.FogEnd = origFogEnd
        end
    end)

    -- [ COLUNA ESQUERDA: Fog Setting ] --
    Library:CreateSection(Page, "Fog Setting", "Left")

    local CustomFogState = {
        enabled = false,
        color = COLOR_GRAY,
        power = 50
    }
    local OriginalCustomFogData = nil
    local CustomFogLoop = nil

    local function ApplyCustomFog()
        if not CustomFogState.enabled then return end
        pcall(function()
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            local targetDensity = CustomFogState.power / 100
            local targetColor = CustomFogState.color
            
            if atm then
                if atm.Color ~= targetColor then atm.Color = targetColor end
                if atm.Decay ~= targetColor then atm.Decay = targetColor end
                if atm.Glare ~= 0 then atm.Glare = 0 end
                if atm.Haze ~= 2.46 then atm.Haze = 2.46 end
                if atm.Density ~= targetDensity then atm.Density = targetDensity end
                if atm.Offset ~= 0 then atm.Offset = 0 end
            end
            
            if Lighting.FogColor ~= targetColor then Lighting.FogColor = targetColor end
            local classicFog = math.max(100, 100000 - (CustomFogState.power * 999))
            if Lighting.FogEnd ~= classicFog then Lighting.FogEnd = classicFog end
        end)
    end

    Library:CreateToggle(Page, "Enable Custom Fog", false, function(state)
        CustomFogState.enabled = state
        if state then
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then
                OriginalCustomFogData = {
                    Color = atm.Color, Glare = atm.Glare, Haze = atm.Haze,
                    Decay = atm.Decay, Density = atm.Density, Offset = atm.Offset,
                    FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd
                }
            else
                OriginalCustomFogData = {
                    FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
                    None = true
                }
            end

            CustomFogLoop = task.spawn(function()
                while CustomFogState.enabled do
                    pcall(function()
                        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
                        if not atmosphere then
                            atmosphere = Instance.new("Atmosphere")
                            atmosphere.Parent = Lighting
                        end
                        
                        local targetDensity = CustomFogState.power / 100
                        local targetColor = CustomFogState.color
                        
                        if atmosphere.Color ~= targetColor then atmosphere.Color = targetColor end
                        if atmosphere.Decay ~= targetColor then atmosphere.Decay = targetColor end
                        if atmosphere.Glare ~= 0 then atmosphere.Glare = 0 end
                        if atmosphere.Haze ~= 2.46 then atmosphere.Haze = 2.46 end
                        if atmosphere.Density ~= targetDensity then atmosphere.Density = targetDensity end
                        if atmosphere.Offset ~= 0 then atmosphere.Offset = 0 end
                        
                        if Lighting.FogColor ~= targetColor then Lighting.FogColor = targetColor end
                        local classicFog = math.max(100, 100000 - (CustomFogState.power * 999))
                        if Lighting.FogEnd ~= classicFog then Lighting.FogEnd = classicFog end
                    end)
                    task.wait(1)
                end
            end)
        else
            if CustomFogLoop then task.cancel(CustomFogLoop); CustomFogLoop = nil end
            if OriginalCustomFogData then
                pcall(function()
                    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                    if OriginalCustomFogData.None then
                        if atm then atm:Destroy() end
                    elseif atm then
                        atm.Color = OriginalCustomFogData.Color
                        atm.Glare = OriginalCustomFogData.Glare
                        atm.Haze = OriginalCustomFogData.Haze
                        atm.Decay = OriginalCustomFogData.Decay
                        atm.Density = OriginalCustomFogData.Density
                        atm.Offset = OriginalCustomFogData.Offset
                    end
                    Lighting.FogColor = OriginalCustomFogData.FogColor
                    Lighting.FogEnd = OriginalCustomFogData.FogEnd
                end)
            end
        end
    end)

    Library:CreateColorPicker(Page, "Fog Color", COLOR_GRAY, function(color)
        CustomFogState.color = color
        ApplyCustomFog()
    end)

    Library:CreateSlider(Page, "Fog Power", 0, 100, 50, function(val)
        CustomFogState.power = val
        ApplyCustomFog()
    end)
end
