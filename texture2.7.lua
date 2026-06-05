return function(env)
    -- Importando as variáveis enviadas pelo script principal
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local RunService = env.RunService
    local TweenService = env.TweenService
    local UserInputService = env.UserInputService
    local Theme = env.Theme
    local UserConfigs = env.UserConfigs
    local GetParentTarget = env.GetParentTarget
    local isMobile = env.isMobile
    local ContentConfig = env.ContentConfig
    local UpdateCursorSizes = env.UpdateCursorSizes
    local SetPCCursorActive = env.SetPCCursorActive
    local MobileCrosshair = env.MobileCrosshair
    local PCSoftwareCursor = env.PCSoftwareCursor
    local Lighting = game:GetService("Lighting")
    local Mouse = LocalPlayer:GetMouse()

    local formatID = function(id)
        if type(id) == "number" and id > 0 then return "rbxassetid://" .. id
        elseif type(id) == "string" and id ~= "" and id ~= "0" then
            if not id:find("rbxassetid://") then return "rbxassetid://" .. id else return id end
        end
        return nil
    end

    -- Processador de altíssima performance baseado em Orçamento de Tempo (Frame Budget de 1.5ms)
    local function batchProcess(items, processFunc, onComplete)
        local total = #items
        local index = 1
        
        local function run()
            local startTime = os.clock()
            while index <= total do
                local item = items[index]
                if item then
                    processFunc(item)
                end
                index = index + 1
                
                -- Se a execução deste frame passar de 1.5ms, pausa para o próximo frame
                if os.clock() - startTime >= 0.0015 then
                    task.wait()
                    startTime = os.clock() -- Reseta o cronômetro para o novo frame
                end
            end
            if onComplete then onComplete() end
        end
        task.spawn(run)
    end

    local function createGridContainer(parentTarget)
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -2, 0, 0)
        bg.Position = UDim2.new(0, 1, 0, 0)
        bg.AutomaticSize = Enum.AutomaticSize.Y
        bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BackgroundTransparency = 0.45
        bg.Parent = parentTarget
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
        local str = Instance.new("UIStroke", bg)
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1

        local wrapper = Instance.new("Frame")
        wrapper.Size = UDim2.new(1, 0, 0, 0)
        wrapper.AutomaticSize = Enum.AutomaticSize.Y
        wrapper.BackgroundTransparency = 1
        wrapper.Parent = bg
        
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 36, 0, 36)
        grid.CellPadding = UDim2.new(0, 8, 0, 8)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        grid.Parent = wrapper
        
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.Parent = wrapper

        return wrapper
    end

    -- Controle dinâmico de visibilidade do cursor do mouse padrão
    local cursorLoopConn = nil
    local function updateMouseVisibility()
        local savedPC = UserConfigs["TexturesPage_Crosshair_PC"]
        if savedPC and savedPC ~= "RESET" and not isMobile then
            UserInputService.MouseIconEnabled = false
            Mouse.Icon = "rbxassetid://0" -- Força textura vazia/invisível para anular o cursor padrão
        else
            if Mouse.Icon == "rbxassetid://0" then
                Mouse.Icon = ""
                UserInputService.MouseIconEnabled = true
            end
        end
    end

    if cursorLoopConn then cursorLoopConn:Disconnect() end
    cursorLoopConn = RunService.RenderStepped:Connect(updateMouseVisibility)

    -- ==========================================
    -- SISTEMA UNIFICADO DE RENDERIZAÇÃO DO MAPA
    -- ==========================================
    local cachedParts = {}
    local cachedLights = {}
    
    local originalMapStates = setmetatable({}, {__mode = "k"})
    local originalLightStates = setmetatable({}, {__mode = "k"})
    local mcTexturesCache = setmetatable({}, {__mode = "k"}) -- Cache local das texturas 3D do Minecraft

    local wbEnabled = false
    local snowEnabled = false
    local mcEnabled = false
    local removeShadowsEnabled = false

    local IgnoreNames = { ComputerTable = true, ExitDoor = true }
    local mcFaces = {"Front", "Back", "Bottom", "Top", "Right", "Left"}
    
    local mcMaterials = {
        [Enum.Material.Wood] = "3258599312", 
        [Enum.Material.WoodPlanks] = "8676581022", 
        [Enum.Material.Brick] = "8558400252", 
        [Enum.Material.Cobblestone] = "5003953441",
        [Enum.Material.Concrete] = "7341687607", 
        [Enum.Material.DiamondPlate] = "6849247561", 
        [Enum.Material.Fabric] = "118776397", 
        [Enum.Material.Granite] = "4722586771",
        [Enum.Material.Grass] = "4722588177", 
        [Enum.Material.Ice] = "3823766459", 
        [Enum.Material.Marble] = "62967586", 
        [Enum.Material.Metal] = "62967586", 
        [Enum.Material.Sand] = "152572215"
    }

    local function isPlayerPart(part)
        local parent = part.Parent
        if not parent then return false end
        if parent:IsA("Model") and Players:GetPlayerFromCharacter(parent) then
            return true
        end
        local grand = parent.Parent
        if grand and grand:IsA("Model") and Players:GetPlayerFromCharacter(grand) then
            return true
        end
        return false
    end

    local function refreshPartVisual(part)
        if not part or not part.Parent then return end

        local bkp = originalMapStates[part]
        if not bkp then
            bkp = {
                Material = part.Material,
                Color = part.Color,
                CastShadow = part.CastShadow
            }
            originalMapStates[part] = bkp
        end

        local targetMaterial = bkp.Material
        local targetColor = bkp.Color
        local targetShadow = bkp.CastShadow

        if removeShadowsEnabled then
            targetShadow = false
        end

        local mcApplied = false

        if snowEnabled then
            if part.Anchored and not IgnoreNames[part.Name] then
                targetMaterial = Enum.Material.Snow
                targetColor = Color3.fromRGB(255, 255, 255)
            end
        elseif wbEnabled then
            targetMaterial = Enum.Material.Brick
            targetColor = Color3.fromRGB(255, 255, 255)
        elseif mcEnabled then
            local textureId = mcMaterials[bkp.Material]
            if textureId then
                targetMaterial = Enum.Material.SmoothPlastic
                mcApplied = true
                
                local texGroup = mcTexturesCache[part]
                if not texGroup then
                    texGroup = {}
                    for i = 1, 6 do
                        local face = mcFaces[i]
                        local tex = Instance.new("Texture")
                        tex.Name = "McTexture_" .. face
                        tex.ZIndex = 2147483647
                        tex.Face = Enum.NormalId[face]
                        tex.StudsPerTileU = 4
                        tex.StudsPerTileV = 4
                        tex.Parent = part
                        texGroup[i] = tex
                    end
                    mcTexturesCache[part] = texGroup
                end
                
                local fullTexId = "rbxassetid://" .. textureId
                local partColor = bkp.Color
                local partTrans = part.Transparency
                for i = 1, 6 do
                    local tex = texGroup[i]
                    if tex and tex.Parent then
                        if tex.Texture ~= fullTexId then tex.Texture = fullTexId end
                        if tex.Color3 ~= partColor then tex.Color3 = partColor end
                        if tex.Transparency ~= partTrans then tex.Transparency = partTrans end
                    end
                end
            end
        end

        if not mcApplied then
            local texGroup = mcTexturesCache[part]
            if texGroup then
                for i = 1, 6 do
                    local tex = texGroup[i]
                    if tex then pcall(function() tex:Destroy() end) end
                end
                mcTexturesCache[part] = nil
            end
        end

        pcall(function()
            if part.Material ~= targetMaterial then part.Material = targetMaterial end
            if part.Color ~= targetColor then part.Color = targetColor end
            if part.CastShadow ~= targetShadow then part.CastShadow = targetShadow end
        end)
    end

    local function refreshLightVisual(light)
        if not light or not light.Parent then return end
        local bkp = originalLightStates[light]
        if not bkp then
            bkp = { Shadows = light.Shadows }
            originalLightStates[light] = bkp
        end

        local targetShadow = bkp.Shadows
        if removeShadowsEnabled then
            targetShadow = false
        end

        pcall(function()
            if light.Shadows ~= targetShadow then light.Shadows = targetShadow end
        end)
    end

    task.spawn(function()
        local desc = Workspace:GetDescendants()
        local startTime = os.clock()
        for i = 1, #desc do
            local v = desc[i]
            local class = v.ClassName
            
            if class == "Part" or class == "MeshPart" or class == "WedgePart" or class == "CornerWedgePart" then
                if not isPlayerPart(v) then
                    table.insert(cachedParts, v)
                end
            elseif class == "PointLight" or class == "SpotLight" or class == "SurfaceLight" then
                table.insert(cachedLights, v)
            end
            
            if os.clock() - startTime >= 0.0015 then
                task.wait()
                startTime = os.clock()
            end
        end

        Workspace.DescendantAdded:Connect(function(child)
            task.defer(function()
                local class = child.ClassName
                if class == "Part" or class == "MeshPart" or class == "WedgePart" or class == "CornerWedgePart" then
                    if not isPlayerPart(child) then
                        table.insert(cachedParts, child)
                        refreshPartVisual(child)
                    end
                elseif class == "PointLight" or class == "SpotLight" or class == "SurfaceLight" then
                    table.insert(cachedLights, child)
                    refreshLightVisual(child)
                end
            end)
        end)
    end)


    -- ==========================================
    -- MAP TEXTURES (Coluna Esquerda)
    -- ==========================================
    Library:CreateSection(Page, "Map Textures", "Left")

    Library:CreateToggle(Page, "White Bricks", false, function(state)
        wbEnabled = state
        batchProcess(cachedParts, refreshPartVisual)
    end)

    Library:CreateToggle(Page, "Snow Textures", false, function(state)
        snowEnabled = state
        batchProcess(cachedParts, refreshPartVisual)
    end)

    Library:CreateToggle(Page, "Remove Textures", false, function(state) 
        if not getgenv().NexOptimization then
            getgenv().NexOptimization = loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/fps%20booster%20e%20remove%20textures.lua"))()
        end
        getgenv().NexOptimization.ToggleTextures(state)
    end)

    Library:CreateToggle(Page, "Minecraft Texture", false, function(state)
        mcEnabled = state
        batchProcess(cachedParts, refreshPartVisual)
    end)


    -- ==========================================
    -- FPS SETTINGS (Coluna Direita - Topo)
    -- ==========================================
    Library:CreateSection(Page, "FPS Settings", "Right")
    
    Library:CreateToggle(Page, "FpsBooster", false, function(state) 
        if not getgenv().NexOptimization then
            getgenv().NexOptimization = loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/fps%20booster%20e%20remove%20textures.lua"))()
        end
        getgenv().NexOptimization.ToggleFPSBooster(state)
    end)

    -- [ TOGGLE REESCRITO DE ALTA PERFORMANCE E COMPATIBILIDADE REDUNDANTE DE SPAWNS ]
    local grayOutfitsEnabled = false
    local grayCharacterConns = {}
    local characterBackups = setmetatable({}, {__mode = "k"})

    local function applyGreyCharacter(char)
        if not char or not char.Parent then return end
        if characterBackups[char] then return end -- Evita dupla aplicação
        
        local backup = {
            Parts = {},
            Accessories = {},
            Clothes = {},
            Connections = {}
        }
        
        local function processItem(i)
            if not i or not i.Parent then return end
            
            if (i:IsA("BasePart") or i:IsA("MeshPart")) and i.Name ~= "HumanoidRootPart" then
                local isAcc = i:FindFirstAncestorOfClass("Accessory")
                if isAcc then
                    -- Processamento de Handle de acessório
                    if i.Name == "Handle" and not backup.Accessories[i] then
                        local handleBackup = {
                            Color = i.Color,
                            Material = i.Material,
                            TextureID = nil,
                            MeshInstance = nil
                        }
                        i.Color = Color3.fromRGB(150, 150, 150)
                        i.Material = Enum.Material.SmoothPlastic
                        
                        if i:IsA("MeshPart") then
                            handleBackup.TextureID = i.TextureID
                            i.TextureID = ""
                        else
                            local mesh = i:FindFirstChildWhichIsA("SpecialMesh") or i:FindFirstChildWhichIsA("Mesh")
                            if mesh then
                                handleBackup.TextureID = mesh.TextureId
                                handleBackup.MeshInstance = mesh
                                mesh.TextureId = ""
                            end
                        end
                        backup.Accessories[i] = handleBackup
                    end
                else
                    -- Processamento de parte do corpo
                    if not backup.Parts[i] then
                        backup.Parts[i] = {
                            Color = i.Color,
                            Material = i.Material
                        }
                        i.Color = Color3.fromRGB(150, 150, 150)
                        i.Material = Enum.Material.SmoothPlastic
                    end
                end
            elseif i:IsA("Pants") or i:IsA("Shirt") or i:IsA("ShirtGraphic") or i.Name == "Shirt Graphic" then
                if not backup.Clothes[i] then
                    backup.Clothes[i] = i.Parent
                    task.defer(function() i.Parent = nil end) -- Esconde de forma limpa e reversível
                end
            elseif i:IsA("SpecialMesh") or i:IsA("Mesh") then
                -- Lida com meshes de acessórios que carregam depois
                local p = i.Parent
                if p and p.Name == "Handle" and backup.Accessories[p] then
                    local hBkp = backup.Accessories[p]
                    if not hBkp.MeshInstance then
                        hBkp.TextureID = i.TextureId
                        hBkp.MeshInstance = i
                        i.TextureId = ""
                    end
                end
            end
        end

        -- Processa o que já está carregado
        for _, i in ipairs(char:GetDescendants()) do
            processItem(i)
        end

        -- Conecta ouvinte dinâmico para carregar itens atrasados em tempo de execução
        local conn = char.DescendantAdded:Connect(function(desc)
            task.wait() -- Dá tempo para as propriedades do Roblox inicializarem no client
            if grayOutfitsEnabled then
                processItem(desc)
            end
        end)
        table.insert(backup.Connections, conn)
        
        characterBackups[char] = backup
    end

    local function restoreCharacter(char)
        local backup = characterBackups[char]
        if not backup then return end
        
        -- Desconecta ouvinte de inserção dinâmica
        for _, conn in ipairs(backup.Connections) do
            conn:Disconnect()
        end
        
        -- Restaura partes do corpo
        for part, data in pairs(backup.Parts) do
            if part and part.Parent then
                part.Color = data.Color
                part.Material = data.Material
            end
        end
        
        -- Restaura acessórios
        for handle, data in pairs(backup.Accessories) do
            if handle and handle.Parent then
                handle.Color = data.Color
                handle.Material = data.Material
                if handle:IsA("MeshPart") then
                    handle.TextureID = data.TextureID
                elseif data.MeshInstance then
                    data.MeshInstance.TextureId = data.TextureID
                end
            end
        end
        
        -- Restaura roupas
        for clothing, originalParent in pairs(backup.Clothes) do
            if clothing then
                clothing.Parent = char
            end
        end
        
        characterBackups[char] = nil
    end

    -- Gerenciador inteligente de ciclo de vida de Spawns de personagens
    local function handleCharacterLoading(char)
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if player then
            -- Redundância de segurança: aguarda o carregamento de roupas nativo do Roblox antes de processar
            if not player:HasAppearanceLoaded() then
                local loaded = false
                local appearanceConn
                appearanceConn = player.CharacterAppearanceLoaded:Connect(function()
                    loaded = true
                    if appearanceConn then appearanceConn:Disconnect() end
                end)
                
                local start = os.clock()
                while not loaded and os.clock() - start < 5 do -- Timeout máximo de 5 segundos para não travar loops
                    task.wait(0.1)
                end
                if appearanceConn then appearanceConn:Disconnect() end
            end
        end
        task.wait(0.1) -- Delay de sincronização do Roblox
        if grayOutfitsEnabled then
            applyGreyCharacter(char)
        end
    end

    Library:CreateToggle(Page, "Gray Characters", false, function(state)
        grayOutfitsEnabled = state
        if state then
            -- Aplica imediatamente nos players que já estão logados
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    task.spawn(handleCharacterLoading, player.Character)
                end
                local conn = player.CharacterAdded:Connect(function(char)
                    task.spawn(handleCharacterLoading, char)
                end)
                table.insert(grayCharacterConns, conn)
            end
            
            -- Ouvinte global de novos players que entrarem na sala
            local conn2 = Players.PlayerAdded:Connect(function(player)
                local conn = player.CharacterAdded:Connect(function(char)
                    task.spawn(handleCharacterLoading, char)
                end)
                table.insert(grayCharacterConns, conn)
            end)
            table.insert(grayCharacterConns, conn2)
        else
            -- Desconecta todos os rastreadores de spawn
            for _, conn in ipairs(grayCharacterConns) do
                conn:Disconnect()
            end
            table.clear(grayCharacterConns)
            
            -- Restaura a coloração e as roupas originais de todos os personagens
            for char, _ in pairs(characterBackups) do
                restoreCharacter(char)
            end
            table.clear(characterBackups)
        end
    end)

    local shadowChangedConn = nil

    Library:CreateToggle(Page, "Remove Shadows", false, function(state)
        removeShadowsEnabled = state
        
        if state then
            pcall(function() Lighting.GlobalShadows = false end)
            shadowChangedConn = Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
                if Lighting.GlobalShadows and removeShadowsEnabled then
                    pcall(function() Lighting.GlobalShadows = false end)
                end
            end)
        else
            if shadowChangedConn then shadowChangedConn:Disconnect() shadowChangedConn = nil end
            pcall(function() Lighting.GlobalShadows = true end)
        end

        batchProcess(cachedParts, refreshPartVisual, function()
            batchProcess(cachedLights, refreshLightVisual)
        end)
    end)

    local removeParticlesEnabled = false
    local particlesDescConnW = nil
    local particlesDescConnL = nil
    local particleBkp = setmetatable({}, {__mode = "k"})

    local function applyParticleRemoval(objeto)
        if not removeParticlesEnabled then return end
        
        local isParticle = objeto:IsA("ParticleEmitter") or 
                           objeto:IsA("Sparkles") or 
                           objeto:IsA("Fire") or 
                           objeto:IsA("Smoke") or 
                           objeto:IsA("Trail") or 
                           objeto:IsA("Beam") or 
                           objeto:IsA("PostEffect")
        
        if isParticle then
            if not particleBkp[objeto] then
                local connection
                connection = objeto:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if removeParticlesEnabled and objeto.Enabled == true then
                        pcall(function() objeto.Enabled = false end)
                    end
                end)
                
                particleBkp[objeto] = {
                    Enabled = objeto.Enabled,
                    Conn = connection
                }
            end
            pcall(function() objeto.Enabled = false end)
        elseif objeto:IsA("Explosion") then
            pcall(function() objeto:Destroy() end)
        end
    end

    Library:CreateToggle(Page, "Remove Particles", false, function(state)
        removeParticlesEnabled = state
        
        if state then
            local descW = Workspace:GetDescendants()
            local descL = Lighting:GetDescendants()
            
            batchProcess(descW, applyParticleRemoval, function()
                if removeParticlesEnabled then
                    batchProcess(descL, applyParticleRemoval)
                end
            end)

            particlesDescConnW = Workspace.DescendantAdded:Connect(function(child)
                if removeParticlesEnabled then task.defer(applyParticleRemoval, child) end
            end)
            particlesDescConnL = Lighting.DescendantAdded:Connect(function(child)
                if removeParticlesEnabled then task.defer(applyParticleRemoval, child) end
            end)
        else
            if particlesDescConnW then particlesDescConnW:Disconnect() particlesDescConnW = nil end
            if particlesDescConnL then particlesDescConnL:Disconnect() particlesDescConnL = nil end

            local currentBkp = particleBkp
            particleBkp = setmetatable({}, {__mode = "k"})
            local toRevert = {}
            for obj, data in pairs(currentBkp) do
                table.insert(toRevert, {obj = obj, data = data})
            end

            batchProcess(toRevert, function(item)
                local obj = item.obj
                local data = item.data
                
                if data.Conn then
                    pcall(function() data.Conn:Disconnect() end)
                end
                
                if obj and obj.Parent then
                    pcall(function()
                        if data.Enabled ~= nil then obj.Enabled = data.Enabled end
                    end)
                end
            end)
        end
    end)


    -- ==========================================================
    -- DOUBLE JUMP EFFECTS P1 & P2 (Alinhados na Esquerda - Left)
    -- ==========================================================
    Library:CreateSection(Page, "Double Jump Effects (P1)", "Left")
    local targetParentDJ1 = GetParentTarget(Page)
    
    Library:CreateSection(Page, "Double Jump (P2)", "Left")
    local targetParentDJ2 = GetParentTarget(Page)

    -- ==========================================================
    -- CROSSHAIRS P1 & P2 (Alinhados na Direita - Right)
    -- ==========================================================
    Library:CreateSection(Page, "Crosshairs (P1)", "Right")
    Library:CreateSlider(Page, "Cursor Size", 10, 100, 24, UpdateCursorSizes)
    local targetParentCur1 = GetParentTarget(Page)
    
    Library:CreateSection(Page, "Crosshairs (P2)", "Right")
    local targetParentCur2 = GetParentTarget(Page)

    -- ==========================================
    -- POPULATE DOUBLE JUMP EFFECTS
    -- ==========================================
    local currentDoubleJumpConns = {}
    local originalTextures = setmetatable({}, {__mode = "k"})
    local OriginalSparkleColors = setmetatable({}, {__mode = "k"})
    
    local function EnableDoubleJumpEffect(texturaID)
        UserConfigs["TexturesPage_DoubleJump"] = texturaID
        for _, c in ipairs(currentDoubleJumpConns) do c:Disconnect() end
        table.clear(currentDoubleJumpConns)
        
        local function aplicarTextura(obj)
            if texturaID == "Default" then
                obj:SetAttribute("CurrentTexture", nil)
                if obj.ClassName == "ParticleEmitter" then
                    if originalTextures[obj] then obj.Texture = originalTextures[obj] end
                elseif obj.ClassName == "Sparkles" then
                    local oldClone = obj.Parent:FindFirstChild("CustomSparkleClone_" .. obj.Name)
                    if oldClone then oldClone:Destroy() end
                    if OriginalSparkleColors[obj] then pcall(function() obj.SparkleColor = OriginalSparkleColors[obj] end)
                    else pcall(function() obj.SparkleColor = Color3.new(1, 1, 1) end) end
                end
                return
            end

            if obj:GetAttribute("CurrentTexture") == texturaID then return end
            obj:SetAttribute("CurrentTexture", texturaID)
            
            local classe = obj.ClassName
            if classe == "ParticleEmitter" then
                local sucesso, texturaAtual = pcall(function() return obj.Texture end)
                if sucesso and texturaAtual and string.find(string.lower(texturaAtual), "sparkles_main") then
                    if not originalTextures[obj] then originalTextures[obj] = obj.Texture end
                    obj.Texture = texturaID
                end
            elseif classe == "Sparkles" then
                if not OriginalSparkleColors[obj] then OriginalSparkleColors[obj] = obj.SparkleColor end
                pcall(function() obj.SparkleColor = Color3.new(0, 0, 0) end)
                
                local oldClone = obj.Parent:FindFirstChild("CustomSparkleClone_" .. obj.Name)
                if oldClone then oldClone:Destroy() end
                
                local clone = Instance.new("ParticleEmitter")
                clone.Name = "CustomSparkleClone_" .. obj.Name
                clone.Texture = texturaID
                clone.Rate = 20
                clone.Speed = NumberRange.new(2, 4)
                clone.Lifetime = NumberRange.new(1.5, 2)
                clone.Rotation = NumberRange.new(0, 360)
                clone.RotSpeed = NumberRange.new(-50, 50)
                clone.LightEmission = 0.8
                clone.ZOffset = 1
                clone.Brightness = 2
                clone.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0)})
                clone.Parent = obj.Parent
                clone.Enabled = obj.Enabled
                
                local conexao = obj:GetPropertyChangedSignal("Enabled"):Connect(function() 
                    if clone then clone.Enabled = obj.Enabled end
                end)
                local destConn = obj.Destroying:Connect(function()
                    if conexao then conexao:Disconnect() end
                    if clone then clone:Destroy() end
                end)
                
                table.insert(currentDoubleJumpConns, conexao)
                table.insert(currentDoubleJumpConns, destConn)
            end
        end

        -- Varredura ultrarrápida focada em players atuais
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then
                        aplicarTextura(obj)
                    end
                end
            end
        end

        -- Varredura fracionada em segundo plano no Workspace
        task.spawn(function()
            local desc = Workspace:GetDescendants()
            local total = #desc
            local index = 1
            local chunkSize = 150

            while index <= total do
                for i = 1, chunkSize do
                    if index > total then break end
                    local obj = desc[index]
                    if obj and (obj:IsA("ParticleEmitter") or obj:IsA("Sparkles")) then
                        aplicarTextura(obj)
                    end
                    index = index + 1
                end
                task.wait()
            end
        end)

        -- Escuta em tempo real para novos elementos adicionados dinamicamente
        if texturaID ~= "Default" then
            table.insert(currentDoubleJumpConns, Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then
                    task.defer(function() aplicarTextura(obj) end)
                end
            end))

            for _, plr in ipairs(Players:GetPlayers()) do
                table.insert(currentDoubleJumpConns, plr.CharacterAdded:Connect(function(char)
                    table.insert(currentDoubleJumpConns, char.DescendantAdded:Connect(function(obj)
                        if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then
                            task.defer(function() aplicarTextura(obj) end)
                        end
                    end))
                end))
            end

            table.insert(currentDoubleJumpConns, Players.PlayerAdded:Connect(function(plr)
                table.insert(currentDoubleJumpConns, plr.CharacterAdded:Connect(function(char)
                    table.insert(currentDoubleJumpConns, char.DescendantAdded:Connect(function(obj)
                        if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then
                            task.defer(function() aplicarTextura(obj) end)
                        end
                    end))
                end))
            end))
        end
    end

    local CustomInputContainer = Instance.new("Frame")
    CustomInputContainer.Size = UDim2.new(1, -2, 0, ContentConfig.ItemHeightNew)
    CustomInputContainer.Position = UDim2.new(0, 1, 0, 0)
    CustomInputContainer.BackgroundTransparency = 1
    CustomInputContainer.Parent = targetParentDJ1

    local CustomInputBox = Instance.new("TextBox")
    CustomInputBox.Size = UDim2.new(1, -65, 1, 0)
    CustomInputBox.Position = UDim2.new(0, 5, 0, 0)
    CustomInputBox.BackgroundTransparency = 1
    CustomInputBox.Text = ""
    local savedDJ = UserConfigs["TexturesPage_DoubleJump"]
    if savedDJ and savedDJ ~= "Default" then CustomInputBox.Text = savedDJ:gsub("rbxassetid://", "") end
    CustomInputBox.PlaceholderText = "Texture ID..."
    CustomInputBox.TextColor3 = Theme.TextDark
    CustomInputBox.PlaceholderColor3 = Theme.TextDark
    CustomInputBox.Font = Theme.Font
    CustomInputBox.TextSize = 10
    CustomInputBox.TextXAlignment = Enum.TextXAlignment.Left
    CustomInputBox.ClearTextOnFocus = false
    CustomInputBox.Parent = CustomInputContainer

    local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Size = UDim2.new(0, 55, 0, 20)
    ApplyBtn.Position = UDim2.new(1, -60, 0.5, -10)
    ApplyBtn.BackgroundColor3 = Color3.new(0,0,0)
    ApplyBtn.BackgroundTransparency = 0.45
    ApplyBtn.Text = "Apply"
    ApplyBtn.Font = Enum.Font.GothamBold
    ApplyBtn.TextSize = 10
    ApplyBtn.TextColor3 = Theme.TextDark
    ApplyBtn.Parent = CustomInputContainer
    Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)
    local abStr = Instance.new("UIStroke", ApplyBtn)
    abStr.Color = Color3.fromRGB(40,40,40)

    ApplyBtn.MouseButton1Click:Connect(function()
        local val = CustomInputBox.Text
        if val and val ~= "" then
            local formatted = formatID(val)
            if formatted then
                UserConfigs["TexturesPage_DoubleJump"] = formatted
                EnableDoubleJumpEffect(formatted)
            end
        end
    end)

    local effectIDs = {
        "81110491136307", "117864251880006", "120181545812734", "74056211768119", 
        "116419901031627", "92247449256845", "113423466689563", "90279999098357", 
        "94123299347751", "105065705443269", "122902019815288", "138617722401997", 
        "75192344666220", "139646605021296", "133105930199997", "96482830256985", 
        "107964624563909", "122185636007520", "130200330618832", "84159990264787",
        "87265760472097", "125925535971201", "99196076742919", "80555494674270", 
        "77364460442867", "84014330993791", "80081088131892", "70463296258416",
        "84683340454265", "110707827597886", "94615398600162", "136555497393349", 
        "115660311620643", "87528090276578", "91090339346537", "104273334466284", 
        "125877054664162", "99696281853254", "115091366896134", "118044368508403"
    }

    local GridWrapperDJ1 = createGridContainer(targetParentDJ1)
    local GridWrapperDJ2 = createGridContainer(targetParentDJ2)

    local defaultBtn = Instance.new("TextButton")
    defaultBtn.Text = "Default"
    defaultBtn.Font = Enum.Font.GothamBold
    defaultBtn.TextSize = 9
    defaultBtn.TextColor3 = Theme.TextDark
    defaultBtn.BackgroundColor3 = Color3.new(0,0,0)
    defaultBtn.BackgroundTransparency = 0.45
    defaultBtn.Parent = GridWrapperDJ1
    Instance.new("UICorner", defaultBtn).CornerRadius = UDim.new(0, 4)
    local dbStr = Instance.new("UIStroke", defaultBtn)
    dbStr.Color = Color3.fromRGB(40,40,40)
    
    defaultBtn.MouseEnter:Connect(function() TweenService:Create(dbStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.Accent}):Play() end)
    defaultBtn.MouseLeave:Connect(function() TweenService:Create(dbStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.TextDark}):Play() end)
    defaultBtn.MouseButton1Click:Connect(function() UserConfigs["TexturesPage_DoubleJump"] = "Default" EnableDoubleJumpEffect("Default") end)

    for i, id in ipairs(effectIDs) do
        local targetGrid = (i <= 19) and GridWrapperDJ1 or GridWrapperDJ2
        local btn = Instance.new("ImageButton")
        btn.BackgroundColor3 = Color3.new(0,0,0)
        btn.BackgroundTransparency = 0.45
        btn.Image = "rbxassetid://" .. id
        btn.ScaleType = Enum.ScaleType.Crop 
        btn.Parent = targetGrid
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local ebStr = Instance.new("UIStroke", btn)
        ebStr.Color = Color3.fromRGB(40,40,40)

        btn.MouseEnter:Connect(function() TweenService:Create(ebStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(ebStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() end)
        btn.MouseButton1Click:Connect(function() 
            UserConfigs["TexturesPage_DoubleJump"] = "rbxassetid://" .. id
            EnableDoubleJumpEffect("rbxassetid://" .. id)
        end)
    end

    -- [ MOBILE JUMP BUTTON ]
    if isMobile then
        Library:CreateSection(Page, "Mobile Button Jump", "Right")
        local targetParentMJ = GetParentTarget(Page)

        local mobileJumpConns = {}
        local function EnableMobileButtonJump(texturaID)
            UserConfigs["TexturesPage_MobileJump"] = texturaID
            if not isMobile then return end
            
            for _, c in ipairs(mobileJumpConns) do c:Disconnect() end
            table.clear(mobileJumpConns)

            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local function applyCustomButton(touchGui)
                local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame") or touchGui:WaitForChild("TouchControlFrame", 2)
                if not touchControlFrame then return end
                local jumpButton = touchControlFrame:FindFirstChild("JumpButton") or touchControlFrame:WaitForChild("JumpButton", 2)
                if not jumpButton then return end

                if texturaID == "Default" then
                    jumpButton.ImageTransparency = 0
                    local existingIcon = jumpButton:FindFirstChild("CustomJumpIcon")
                    if existingIcon then existingIcon:Destroy() end
                    return
                end
                
                jumpButton.ImageTransparency = 1 
                local existingIcon = jumpButton:FindFirstChild("CustomJumpIcon")
                if existingIcon then existingIcon:Destroy() end
                
                local customIcon = Instance.new("ImageLabel")
                customIcon.Name = "CustomJumpIcon"
                customIcon.Size = UDim2.new(1, 0, 1, 0)
                customIcon.Position = UDim2.new(0, 0, 0, 0)
                customIcon.BackgroundTransparency = 1
                customIcon.Image = texturaID
                customIcon.ZIndex = jumpButton.ZIndex + 50
                customIcon.Parent = jumpButton
                
                local c1 = jumpButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        customIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
                    end
                end)
                local c2 = jumpButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        customIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end)
                table.insert(mobileJumpConns, c1)
                table.insert(mobileJumpConns, c2)
            end

            if playerGui:FindFirstChild("TouchGui") then task.spawn(applyCustomButton, playerGui.TouchGui) end
            if texturaID ~= "Default" then
                table.insert(mobileJumpConns, playerGui.ChildAdded:Connect(function(child)
                    if child.Name == "TouchGui" then task.spawn(applyCustomButton, child) end
                end))
            end
        end

        local MJInputContainer = Instance.new("Frame")
        MJInputContainer.Size = UDim2.new(1, -2, 0, ContentConfig.ItemHeightNew)
        MJInputContainer.Position = UDim2.new(0, 1, 0, 0)
        MJInputContainer.BackgroundTransparency = 1
        MJInputContainer.Parent = targetParentMJ

        local MJumpTextBox = Instance.new("TextBox")
        MJumpTextBox.Size = UDim2.new(1, -65, 1, 0)
        MJumpTextBox.Position = UDim2.new(0, 5, 0, 0)
        MJumpTextBox.BackgroundTransparency = 1
        MJumpTextBox.Text = ""
        local savedMJ = UserConfigs["TexturesPage_MobileJump"]
        if savedMJ and savedMJ ~= "Default" then MJumpTextBox.Text = savedMJ:gsub("rbxassetid://", "") end
        MJumpTextBox.PlaceholderText = "Texture ID..."
        MJumpTextBox.TextColor3 = Theme.TextDark
        MJumpTextBox.PlaceholderColor3 = Theme.TextDark
        MJumpTextBox.Font = Theme.Font
        MJumpTextBox.TextSize = 10
        MJumpTextBox.TextXAlignment = Enum.TextXAlignment.Left
        MJumpTextBox.ClearTextOnFocus = false
        MJumpTextBox.Parent = MJInputContainer

        local MJumpApplyBtn = Instance.new("TextButton")
        MJumpApplyBtn.Size = UDim2.new(0, 55, 0, 20)
        MJumpApplyBtn.Position = UDim2.new(1, -60, 0.5, -10)
        MJumpApplyBtn.BackgroundColor3 = Color3.new(0,0,0)
        MJumpApplyBtn.BackgroundTransparency = 0.45
        MJumpApplyBtn.Text = "Apply"
        MJumpApplyBtn.Font = Enum.Font.GothamBold
        MJumpApplyBtn.TextSize = 10
        MJumpApplyBtn.TextColor3 = Theme.TextDark
        MJumpApplyBtn.Parent = MJInputContainer
        Instance.new("UICorner", MJumpApplyBtn).CornerRadius = UDim.new(0, 4)
        local mbStr = Instance.new("UIStroke", MJumpApplyBtn)
        mbStr.Color = Color3.fromRGB(40,40,40)

        MJumpApplyBtn.MouseButton1Click:Connect(function()
            local val = MJumpTextBox.Text
            if val and val ~= "" then
                local formatted = formatID(val)
                if formatted then
                    UserConfigs["TexturesPage_MobileJump"] = formatted
                    EnableMobileButtonJump(formatted)
                end
            end
        end)

        local MJGridWrapper = createGridContainer(targetParentMJ)

        local mDefaultBtn = Instance.new("TextButton")
        mDefaultBtn.Text = "Default"
        mDefaultBtn.Font = Enum.Font.GothamBold
        mDefaultBtn.TextSize = 9
        mDefaultBtn.TextColor3 = Theme.TextDark
        mDefaultBtn.BackgroundColor3 = Color3.new(0,0,0)
        mDefaultBtn.BackgroundTransparency = 0.45
        mDefaultBtn.Parent = MJGridWrapper
        Instance.new("UICorner", mDefaultBtn).CornerRadius = UDim.new(0, 4)
        local mDStr = Instance.new("UIStroke", mDefaultBtn)
        mDStr.Color = Color3.fromRGB(40,40,40)
        
        mDefaultBtn.MouseEnter:Connect(function() TweenService:Create(mDStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() TweenService:Create(mDefaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.Accent}):Play() end)
        mDefaultBtn.MouseLeave:Connect(function() TweenService:Create(mDStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.TextDark}):Play() end)
        mDefaultBtn.MouseButton1Click:Connect(function() UserConfigs["TexturesPage_MobileJump"] = "Default" EnableMobileButtonJump("Default") end)

        local mJumpIDs = {
            "126321670529682", "77430663366893", "115979689020396", "101678026501268", 
            "100604012502918", "107988778180975", "106355869384286", "119823685069603"
        }

        for _, id in ipairs(mJumpIDs) do
            local btn = Instance.new("ImageButton")
            btn.BackgroundColor3 = Color3.new(0,0,0)
            btn.BackgroundTransparency = 0.45
            btn.Image = "rbxassetid://" .. id
            btn.ScaleType = Enum.ScaleType.Crop 
            btn.Parent = MJGridWrapper
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            local str = Instance.new("UIStroke", btn)
            str.Color = Color3.fromRGB(40,40,40)
            
            btn.MouseEnter:Connect(function() TweenService:Create(str, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() end)
            btn.MouseLeave:Connect(function() TweenService:Create(str, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() end)
            btn.MouseButton1Click:Connect(function() 
                UserConfigs["TexturesPage_MobileJump"] = "rbxassetid://" .. id
                EnableMobileButtonJump("rbxassetid://" .. id)
            end)
        end
    end

    -- ==========================================
    -- POPULATE CROSSHAIRS
    -- ==========================================
    local CursorList = {
        {Name = "Default", ID = "RESET"},
        {Name = "Use Cursor", ID = "15368174199"}, {Name = "Use Cursor", ID = "12701650945"},
        {Name = "Use Cursor", ID = "128514706094926"}, {Name = "Use Cursor", ID = "119350232226515"},
        {Name = "Use Cursor", ID = "5060823578"}, {Name = "Use Cursor", ID = "9896571799"},
        {Name = "Use Cursor", ID = "139654963330788"}, {Name = "Use Cursor", ID = "13441649168"},
        {Name = "Use Cursor", ID = "88005681147215"}, {Name = "Use Cursor", ID = "72902755839437"},
        {Name = "Use Cursor", ID = "128926155948846"}, {Name = "Use Cursor", ID = "95348763251820"},
        {Name = "Use Cursor", ID = "138513473967293"}, {Name = "Use Cursor", ID = "82043397777881"},
        {Name = "Use Cursor", ID = "84583215296063"}, {Name = "Use Cursor", ID = "120058675182639"},
        {Name = "Use Cursor", ID = "130210380679877"}, {Name = "Use Cursor", ID = "74264514489577"},
        {Name = "Use Cursor", ID = "115877213393063"}, {Name = "Use Cursor", ID = "133579119074302"},
        {Name = "Use Cursor", ID = "137970082797101"}, {Name = "Use Cursor", ID = "116865736993390"},
        {Name = "Use Cursor", ID = "70613337612134"}, {Name = "Use Cursor", ID = "75670552980458"}, 
        {Name = "Use Cursor", ID = "100822311002882"}, {Name = "Use Cursor", ID = "135331308026486"},
        {Name = "Use Cursor", ID = "91090339346537"}, {Name = "Use Cursor", ID = "99626703938913"},
        {Name = "Use Cursor", ID = "112195317343485"}, {Name = "Use Cursor", ID = "89746976355403"},
        {Name = "Use Cursor", ID = "132191954497107"}, {Name = "Use Cursor", ID = "93050147531878"},
        {Name = "Use Cursor", ID = "88343941218179"}, {Name = "Use Cursor", ID = "81277812126144"},
        {Name = "Use Cursor", ID = "131422226977434"}, {Name = "Use Cursor", ID = "116499481211766"}
    }

    local function CreateCursorSystem(isMob)
        local CInputContainer = Instance.new("Frame")
        CInputContainer.Size = UDim2.new(1, -2, 0, ContentConfig.ItemHeightNew)
        CInputContainer.Position = UDim2.new(0, 1, 0, 0)
        CInputContainer.BackgroundTransparency = 1
        CInputContainer.Parent = targetParentCur1
        
        local TextBox = Instance.new("TextBox")
        TextBox.Size = UDim2.new(1, -65, 1, 0)
        TextBox.Position = UDim2.new(0, 5, 0, 0)
        TextBox.BackgroundTransparency = 1
        TextBox.Text = ""
        local flagKey = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
        local savedCross = UserConfigs[flagKey]
        if savedCross and savedCross ~= "RESET" then TextBox.Text = savedCross:gsub("rbxassetid://", "") end
        TextBox.PlaceholderText = "Texture ID..."
        TextBox.TextColor3 = Theme.TextDark
        TextBox.PlaceholderColor3 = Theme.TextDark
        TextBox.Font = Theme.Font
        TextBox.TextSize = 10
        TextBox.TextXAlignment = Enum.TextXAlignment.Left
        TextBox.ClearTextOnFocus = false
        TextBox.Parent = CInputContainer
        
        local ApplyBtn = Instance.new("TextButton")
        ApplyBtn.Size = UDim2.new(0, 55, 0, 20)
        ApplyBtn.Position = UDim2.new(1, -60, 0.5, -10)
        ApplyBtn.BackgroundColor3 = Color3.new(0,0,0)
        ApplyBtn.BackgroundTransparency = 0.45
        ApplyBtn.Text = "Apply"
        ApplyBtn.Font = Enum.Font.GothamBold
        ApplyBtn.TextSize = 10
        ApplyBtn.TextColor3 = Theme.TextDark
        ApplyBtn.Parent = CInputContainer
        Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)
        local apStr = Instance.new("UIStroke", ApplyBtn)
        apStr.Color = Color3.fromRGB(40,40,40)
        
        ApplyBtn.MouseButton1Click:Connect(function() 
            local id = TextBox.Text
            if id ~= "" then 
                local fullID = formatID(id)
                local flag = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
                UserConfigs[flag] = fullID
                if isMob then 
                    MobileCrosshair.Image = fullID
                    MobileCrosshair.Visible = true 
                else 
                    PCSoftwareCursor.Image = fullID
                    SetPCCursorActive(true)
                    PCSoftwareCursor.Visible = true 
                    updateMouseVisibility()
                end 
            end 
        end)

        local GridWrapperCur1 = createGridContainer(targetParentCur1)
        local GridWrapperCur2 = createGridContainer(targetParentCur2)
        
        for i, item in ipairs(CursorList) do
            local targetGrid = (i <= 18) and GridWrapperCur1 or GridWrapperCur2

            if item.ID == "RESET" then
                local defaultBtn = Instance.new("TextButton")
                defaultBtn.Text = "Default"
                defaultBtn.Font = Enum.Font.GothamBold
                defaultBtn.TextSize = 9
                defaultBtn.TextColor3 = Theme.TextDark
                defaultBtn.BackgroundColor3 = Color3.new(0,0,0)
                defaultBtn.BackgroundTransparency = 0.45
                defaultBtn.Parent = targetGrid
                Instance.new("UICorner", defaultBtn).CornerRadius = UDim.new(0, 4)
                local dStr = Instance.new("UIStroke", defaultBtn)
                dStr.Color = Color3.fromRGB(40,40,40)
                
                defaultBtn.MouseEnter:Connect(function() TweenService:Create(dStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.Accent}):Play() end)
                defaultBtn.MouseLeave:Connect(function() TweenService:Create(dStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() TweenService:Create(defaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.TextDark}):Play() end)
                
                defaultBtn.MouseButton1Click:Connect(function() 
                    local flag = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
                    UserConfigs[flag] = "RESET"
                    if isMob then 
                        MobileCrosshair.Visible = false 
                    else 
                        SetPCCursorActive(false)
                        PCSoftwareCursor.Visible = false
                        UserInputService.MouseIconEnabled = true 
                        Mouse.Icon = ""
                    end 
                end)
            else
                local btn = Instance.new("ImageButton")
                btn.BackgroundColor3 = Color3.new(0,0,0)
                btn.BackgroundTransparency = 0.45
                btn.Image = "rbxassetid://" .. item.ID
                btn.ScaleType = Enum.ScaleType.Crop 
                btn.Parent = targetGrid
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                local imgStr = Instance.new("UIStroke", btn)
                imgStr.Color = Color3.fromRGB(40,40,40)
                
                btn.MouseEnter:Connect(function() imgStr.Color = Theme.Accent end)
                btn.MouseLeave:Connect(function() imgStr.Color = Color3.fromRGB(40,40,40) end)
                
                btn.MouseButton1Click:Connect(function() 
                    local fullID = "rbxassetid://" .. item.ID
                    local flag = "TexturesPage_Crosshair_" .. (isMob and "Mobile" or "PC")
                    UserConfigs[flag] = fullID
                    if isMob then 
                        MobileCrosshair.Image = fullID
                        MobileCrosshair.Visible = true 
                    else 
                        PCSoftwareCursor.Image = fullID
                        SetPCCursorActive(true)
                        PCSoftwareCursor.Visible = true 
                        updateMouseVisibility()
                    end 
                end)
            end
        end
    end

    local usePCCursor = UserInputService.MouseEnabled
    if usePCCursor then CreateCursorSystem(false) else CreateCursorSystem(true) end

    -- INICIALIZADOR DE SALVOS
    if UserConfigs["TexturesPage_DoubleJump"] then task.spawn(function() EnableDoubleJumpEffect(UserConfigs["TexturesPage_DoubleJump"]) end) end
    if isMobile and UserConfigs["TexturesPage_MobileJump"] then task.spawn(function() EnableMobileButtonJump(UserConfigs["TexturesPage_MobileJump"]) end) end

    task.spawn(function()
        if usePCCursor then
            local saved = UserConfigs["TexturesPage_Crosshair_PC"]
            if saved and saved ~= "RESET" then
                PCSoftwareCursor.Image = saved
                SetPCCursorActive(true)
                PCSoftwareCursor.Visible = true 
                updateMouseVisibility()
            end
        else
            local saved = UserConfigs["TexturesPage_Crosshair_Mobile"]
            if saved and saved ~= "RESET" then
                MobileCrosshair.Image = saved
                MobileCrosshair.Visible = true 
            end
        end
    end)
end
