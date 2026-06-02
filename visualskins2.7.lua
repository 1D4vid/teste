return function(env)
    -- Importando as variáveis do script principal
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local RunService = env.RunService
    local TweenService = env.TweenService
    local Theme = env.Theme
    local SendNotification = env.SendNotification
    local ModalOverlay = env.ModalOverlay
    local ApplyGradient = env.ApplyGradient

    local AssetService = game:GetService("AssetService")
    local MarketplaceService = game:GetService("MarketplaceService")
    local HttpService = game:GetService("HttpService")
    local selectedModalId = nil
    local currentModalAction = nil
    getgenv().FixLoop = nil

    -- IDs de Época para prevenção absoluta de Race Conditions
    local headlessEpoch = 0
    local korbloxEpoch = 0
    local skeletonEpoch = 0
    local zombieEpoch = 0
    local scepterEpoch = 0
    local arrowEpoch = 0

    -- Controle de Estado Exclusivo do Bundle Changer
    local currentActiveBundleId = nil
    local bundleEpoch = 0
    local bundleToggleControls = {}
    local bundleConn = nil
    local characterBackups = setmetatable({}, {__mode = "k"})

    -- Controle de Estado Ativo do Accessories Changer (Reaplicação Automática)
    local activeAccessoriesStates = {
        Headless = false,
        Korblox = false,
        SkeletonLeg = false,
        ZombieLeg = false,
        RoyalScepter = false,
        MysteriousArrow = false
    }

    -- Proteção de Respawn de Skin
    local activeSkinUserId = nil

    -- Funções Core de Auxílio
    local function loadAsset(id)
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(id))[1]
        end)
        if success and result then return result end
        return nil
    end

    local function SmartWeld(char, accessory)
        local handle = accessory:FindFirstChild("Handle")
        if not handle then return end
        handle.Anchored = false
        handle.CanCollide = false
        handle.Massless = true
        accessory.Parent = char
        local accAtt = handle:FindFirstChildWhichIsA("Attachment")
        local charAtt, targetPart = nil, nil
        if accAtt then
            if char:FindFirstChild("Head") and char.Head:FindFirstChild(accAtt.Name) then 
                charAtt = char.Head[accAtt.Name]
                targetPart = char.Head
            elseif char:FindFirstChild("Torso") and char.Torso:FindFirstChild(accAtt.Name) then 
                charAtt = char.Torso[accAtt.Name]
                targetPart = char.Torso 
            elseif char:FindFirstChild("Right Arm") and char["Right Arm"]:FindFirstChild(accAtt.Name) then
                charAtt = char["Right Arm"][accAtt.Name]
                targetPart = char["Right Arm"]
            end
        end
        local weld = Instance.new("Weld")
        weld.Part1 = handle
        if charAtt and targetPart then 
            weld.Part0 = targetPart
            weld.C0 = charAtt.CFrame
            weld.C1 = accAtt.CFrame
        else 
            targetPart = char:FindFirstChild("Right Arm")
            if targetPart then 
                weld.Part0 = targetPart
                weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end 
        end
        if weld.Part0 then weld.Parent = handle end
    end

    -- Equipamento de Acessórios por ID
    local function EquipAccessoryByID(id)
        local char = LocalPlayer.Character
        if not char then return end
        
        local asset = loadAsset(id)
        if not asset then
            SendNotification("Failed to load item ID: " .. tostring(id), 3)
            return
        end
        
        local function handleEquip(obj)
            if obj:IsA("Accessory") or obj:IsA("Hat") then
                SmartWeld(char, obj)
                SendNotification("Accessory Equipped!", 3)
            elseif obj:IsA("Tool") then
                obj.Parent = char
                SendNotification("Tool Equipped!", 3)
            elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") then
                local existing = char:FindFirstChildOfClass(obj.ClassName)
                if existing then existing:Destroy() end
                obj.Parent = char
                SendNotification("Clothing Equipped!", 3)
            elseif obj:IsA("Model") then
                local hasEquipped = false
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("Accessory") or child:IsA("Hat") or child:IsA("Tool") or child:IsA("Shirt") or child:IsA("Pants") then
                        handleEquip(child)
                        hasEquipped = true
                    end
                end
                if not hasEquipped then
                    obj.Parent = char
                    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        primary.Anchored = false
                        primary.CanCollide = false
                        local weld = Instance.new("Weld")
                        weld.Part0 = char:FindFirstChild("Head") or char.PrimaryPart
                        weld.Part1 = primary
                        weld.C0 = CFrame.new(0, 0, 0)
                        weld.Parent = primary
                    end
                    SendNotification("Model Attached!", 3)
                end
            else
                obj.Parent = char
            end
        end
        handleEquip(asset)
    end

    local function StartFixLoop(char, colorTable, originalHeadTextureId)
        if getgenv().FixLoop then getgenv().FixLoop:Disconnect() end
        getgenv().FixLoop = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent then 
                if getgenv().FixLoop then getgenv().FixLoop:Disconnect() end 
                return 
            end
            for partName, color in pairs(colorTable) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    if part.Color ~= color then 
                        part.Color = color
                        part.Material = Enum.Material.SmoothPlastic 
                    end
                    local mesh = part:FindFirstChildOfClass("SpecialMesh")
                    if mesh then
                        if partName == "Head" then
                            if originalHeadTextureId and originalHeadTextureId ~= "" then 
                                if mesh.TextureId ~= originalHeadTextureId then mesh.TextureId = originalHeadTextureId end
                                mesh.VertexColor = Vector3.new(1, 1, 1) 
                            else 
                                if mesh.TextureId ~= "" then mesh.TextureId = "" end 
                            end
                        else 
                            if mesh.TextureId ~= "" then mesh.TextureId = "" end
                            mesh.VertexColor = Vector3.new(1,1,1) 
                        end
                    end
                    for _, child in pairs(part:GetChildren()) do 
                        if child:IsA("Decal") and child.Name ~= "face" then child:Destroy() 
                        elseif child:IsA("Texture") then child:Destroy() end 
                    end
                end
            end
        end)
    end

    -- Sistema de Backup e Restauração local de Personagem (Substitui o LoadCharacter instável)
    local function BackupCharacterAppearance(char)
        if not char then return end
        if characterBackups[char] then return end
        
        local backup = {
            meshes = {},
            clothes = {},
            accessories = {},
            bodyColors = nil,
            faceTexture = nil,
            headMesh = nil
        }
        
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("CharacterMesh") then
                table.insert(backup.meshes, child:Clone())
            elseif child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
                table.insert(backup.clothes, child:Clone())
            elseif child:IsA("Accessory") or child:IsA("Hat") then
                table.insert(backup.accessories, child:Clone())
            elseif child:IsA("BodyColors") then
                backup.bodyColors = child:Clone()
            end
        end
        
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
            if face then
                backup.faceTexture = face.Texture
            end
            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                backup.headMesh = mesh:Clone()
            end
        end
        
        characterBackups[char] = backup
    end

    local function RestoreCharacterAppearance(char)
        if not char then return end
        local backup = characterBackups[char]
        if not backup then return end
        
        if getgenv().FixLoop then getgenv().FixLoop:Disconnect() getgenv().FixLoop = nil end
        
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("CharacterMesh") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("Accessory") or child:IsA("Hat") or child:IsA("BodyColors") then
                child:Destroy()
            end
        end
        
        for _, mesh in ipairs(backup.meshes) do
            mesh:Clone().Parent = char
        end
        
        for _, cloth in ipairs(backup.clothes) do
            cloth:Clone().Parent = char
        end
        
        for _, acc in ipairs(backup.accessories) do
            local clone = acc:Clone()
            clone.Parent = char
        end
        
        if backup.bodyColors then
            backup.bodyColors:Clone().Parent = char
        end
        
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
            if not face then
                face = Instance.new("Decal", head)
                face.Name = "face"
            end
            face.Texture = backup.faceTexture or "rbxasset://textures/face.png"
            
            local currentMesh = head:FindFirstChildOfClass("SpecialMesh")
            if currentMesh then currentMesh:Destroy() end
            if backup.headMesh then
                backup.headMesh:Clone().Parent = head
            else
                local defaultMesh = Instance.new("SpecialMesh", head)
                defaultMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
            end
        end
    end

    -- Sincronização dos Toggles que estiverem ligados após a troca de Skin ou Bundle
    local function ReapplyActiveAccessories(char)
        if not char then return end
        task.spawn(function()
            task.wait(0.5)
            if activeAccessoriesStates.Headless then
                ApplyHeadless(char, headlessEpoch)
            end
            if activeAccessoriesStates.Korblox then
                ApplyKorblox(char, korbloxEpoch)
            end
            if activeAccessoriesStates.SkeletonLeg then
                ApplySkeletonLeg(char, skeletonEpoch)
            end
            if activeAccessoriesStates.ZombieLeg then
                ApplyZombieLeg(char, zombieEpoch)
            end
            if activeAccessoriesStates.RoyalScepter then
                ApplyScepter(char, scepterEpoch)
            end
            if activeAccessoriesStates.MysteriousArrow then
                ApplyArrow(char, arrowEpoch)
            end
        end)
    end

    local function TransformarSkin(userId)
        local char = LocalPlayer.Character
        if not char then return end
        
        activeSkinUserId = userId
        currentActiveBundleId = nil -- Desativa bundles pre-definidos ao aplicar skin
        
        local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
        if not s or not desc then 
            SendNotification("Não foi possível carregar a skin.", 3)
            return 
        end
        
        local realColors = { ["Head"] = desc.HeadColor,["Torso"] = desc.TorsoColor,["Left Arm"] = desc.LeftArmColor,["Right Arm"] = desc.RightArmColor,["Left Leg"] = desc.LeftLegColor,["Right Leg"] = desc.RightLegColor }
        local dummy = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
        dummy.Name = "AssetSource"
        dummy.Parent = workspace
        dummy:SetPrimaryPartCFrame(CFrame.new(0, -500, 0))
        task.wait(1.0)
        
        local targetHeadTexture = ""
        local dummyMesh = dummy.Head:FindFirstChildOfClass("SpecialMesh")
        if dummyMesh then targetHeadTexture = dummyMesh.TextureId end
        
        for _, v in pairs(char:GetChildren()) do 
            if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then 
                v:Destroy() 
            end 
        end
        if char:FindFirstChild("Head") and char.Head:FindFirstChild("face") then char.Head.face:Destroy() end
        
        local myMesh = char.Head:FindFirstChildOfClass("SpecialMesh")
        if not myMesh then myMesh = Instance.new("SpecialMesh", char.Head) end
        
        if dummyMesh then 
            myMesh.MeshType = dummyMesh.MeshType
            myMesh.MeshId = dummyMesh.MeshId
            myMesh.Scale = dummyMesh.Scale
            myMesh.TextureId = targetHeadTexture
        else
            myMesh.MeshType = Enum.MeshType.Head
            myMesh.MeshId = ""
            myMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
            myMesh.TextureId = ""
        end
        myMesh.VertexColor = Vector3.new(1,1,1) 
        
        for _, item in pairs(dummy:GetChildren()) do if item:IsA("CharacterMesh") then item:Clone().Parent = char end end
        for _, item in pairs(dummy:GetChildren()) do 
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then 
                item:Clone().Parent = char 
            end 
        end

        local faceDecal = Instance.new("Decal")
        faceDecal.Name = "face"
        local dummyFace = dummy.Head:FindFirstChild("face")
        
        if dummyFace then
            faceDecal.Texture = dummyFace.Texture
        elseif desc.Face and desc.Face > 0 then
            faceDecal.Texture = "rbxassetid://" .. desc.Face
        else
            faceDecal.Texture = "rbxasset://textures/face.png"
        end
        faceDecal.Parent = char.Head
        
        local newBC = Instance.new("BodyColors")
        newBC.HeadColor3 = desc.HeadColor
        newBC.TorsoColor3 = desc.TorsoColor
        newBC.LeftArmColor3 = desc.LeftArmColor
        newBC.RightArmColor3 = desc.RightArmColor
        newBC.LeftLegColor3 = desc.LeftLegColor
        newBC.RightLegColor3 = desc.RightLegColor
        newBC.Parent = char
        
        StartFixLoop(char, realColors, targetHeadTexture)
        
        for _, item in pairs(dummy:GetChildren()) do 
            if item:IsA("Accessory") then 
                local clone = item:Clone()
                SmartWeld(char, clone) 
            end 
        end
        dummy:Destroy()
        
        ReapplyActiveAccessories(char) -- Readequação das modificações do Accessories Changer
        
        SendNotification("Skin Applied Successfully!", 3)
    end

    local function ApplyBundleSafe(bundleId, epoch)
        local char = LocalPlayer.Character
        if not char then return end
        
        activeSkinUserId = nil -- Desativa skins persistentes ao aplicar bundle
        BackupCharacterAppearance(char)
        
        local success, bundleDetails = pcall(function() return AssetService:GetBundleDetailsAsync(bundleId) end)
        if epoch ~= bundleEpoch then return end
        if not success or not bundleDetails or not bundleDetails.Items then return end

        local targetDesc = nil
        for _, item in ipairs(bundleDetails.Items) do
            if item.Type == "UserOutfit" then
                local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
                if s and desc then targetDesc = desc break end
            end
        end
        if epoch ~= bundleEpoch then return end

        if not targetDesc then return end
        
        local realColors = { 
            ["Head"] = targetDesc.HeadColor, 
            ["Torso"] = targetDesc.TorsoColor,
            ["Left Arm"] = targetDesc.LeftArmColor,
            ["Right Arm"] = targetDesc.RightArmColor,
            ["Left Leg"] = targetDesc.LeftLegColor,
            ["Right Leg"] = targetDesc.RightLegColor 
        }
        
        local dummy = Players:CreateHumanoidModelFromDescription(targetDesc, Enum.HumanoidRigType.R6)
        if epoch ~= bundleEpoch then dummy:Destroy() return end
        
        dummy.Name = "AssetSource"
        dummy.Parent = workspace
        dummy:SetPrimaryPartCFrame(CFrame.new(0, -500, 0))
        task.wait(1.0)
        if epoch ~= bundleEpoch then dummy:Destroy() return end
        
        local targetHeadTexture = ""
        if dummy.Head:FindFirstChildOfClass("SpecialMesh") then 
            targetHeadTexture = dummy.Head:FindFirstChildOfClass("SpecialMesh").TextureId 
        end
        
        for _, v in pairs(char:GetChildren()) do 
            if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then 
                v:Destroy() 
            end 
        end
        if char:FindFirstChild("Head") and char.Head:FindFirstChild("face") then char.Head.face:Destroy() end
        
        local dummyMesh = dummy.Head:FindFirstChildOfClass("SpecialMesh")
        local myMesh = char.Head:FindFirstChildOfClass("SpecialMesh")
        if dummyMesh then 
            if not myMesh then myMesh = Instance.new("SpecialMesh", char.Head) end
            myMesh.MeshType = Enum.MeshType.FileMesh
            myMesh.MeshId = dummyMesh.MeshId
            myMesh.Scale = dummyMesh.Scale
            myMesh.TextureId = targetHeadTexture
            myMesh.VertexColor = Vector3.new(1,1,1) 
        end
        
        for _, item in pairs(dummy:GetChildren()) do 
            if item:IsA("CharacterMesh") then item:Clone().Parent = char end 
        end
        for _, item in pairs(dummy:GetChildren()) do 
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then 
                item:Clone().Parent = char 
            elseif item.Name == "Head" and item:FindFirstChild("face") then 
                item.face:Clone().Parent = char:FindFirstChild("Head") 
            end 
        end
        
        local newBC = Instance.new("BodyColors")
        newBC.HeadColor3 = targetDesc.HeadColor
        newBC.TorsoColor3 = targetDesc.TorsoColor
        newBC.LeftArmColor3 = targetDesc.LeftArmColor
        newBC.RightArmColor3 = targetDesc.RightArmColor
        newBC.LeftLegColor3 = targetDesc.LeftLegColor
        newBC.RightLegColor3 = targetDesc.RightLegColor
        newBC.Parent = char
        
        StartFixLoop(char, realColors, targetHeadTexture)
        
        for _, item in pairs(dummy:GetChildren()) do 
            if item:IsA("Accessory") then 
                local clone = item:Clone()
                SmartWeld(char, clone) 
            end 
        end
        dummy:Destroy()
        
        ReapplyActiveAccessories(char) -- Readequação das modificações do Accessories Changer
        
        SendNotification("Bundle Applied Successfully!", 3)
    end

    -- SISTEMA DE APLICAÇÃO PREVENIDO DE RACE CONDITIONS
    local cachedHeadlessMesh = nil
    local headlessConn = nil
    local headlessBackups = {}

    local function ApplyHeadless(char, epoch)
        if not char or not cachedHeadlessMesh then return end
        task.wait(0.5)
        if epoch ~= headlessEpoch then return end -- Aborta se mudou de estado
        local head = char:FindFirstChild("Head")
        if head then
            if not headlessBackups[char] then
                headlessBackups[char] = {
                    mesh = head:FindFirstChildOfClass("SpecialMesh") and head:FindFirstChildOfClass("SpecialMesh"):Clone(),
                    face = (head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")) and (head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")):Clone()
                }
            end
            
            local currentMesh = head:FindFirstChildOfClass("SpecialMesh")
            if currentMesh then currentMesh:Destroy() end
            local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
            if face then face:Destroy() end
            
            cachedHeadlessMesh:Clone().Parent = head
        end
    end

    local function RestoreHeadless(char)
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local backup = headlessBackups[char]
        if backup then
            local currentMesh = head:FindFirstChildOfClass("SpecialMesh")
            if currentMesh then currentMesh:Destroy() end
            if backup.mesh then backup.mesh:Clone().Parent = head end
            
            local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
            if face then face:Destroy() end
            if backup.face then backup.face:Clone().Parent = head end
        end
    end

    local cachedKorbloxLeg = nil
    local korbloxConn = nil
    local korbloxBackups = {}

    local function ApplyKorblox(char, epoch)
        if not char or not cachedKorbloxLeg then return end
        task.wait(0.5)
        if epoch ~= korbloxEpoch then return end -- Aborta se mudou de estado
        if not korbloxBackups[char] then
            korbloxBackups[char] = {}
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    table.insert(korbloxBackups[char], v:Clone())
                end
            end
        end
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                v:Destroy()
            end
        end
        cachedKorbloxLeg:Clone().Parent = char
    end

    local function RestoreKorblox(char)
        if not char then return end
        local backup = korbloxBackups[char]
        if backup then
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    v:Destroy()
                end
            end
            for _, v in ipairs(backup) do
                v:Clone().Parent = char
            end
        end
    end

    local cachedSkeletonLeg = nil
    local skeletonConn = nil
    local skeletonBackups = {}

    local function ApplySkeletonLeg(char, epoch)
        if not char or not cachedSkeletonLeg then return end
        task.wait(0.5)
        if epoch ~= skeletonEpoch then return end -- Aborta se mudou de estado
        if not skeletonBackups[char] then
            skeletonBackups[char] = {}
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    table.insert(skeletonBackups[char], v:Clone())
                end
            end
        end
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                v:Destroy()
            end
        end
        cachedSkeletonLeg:Clone().Parent = char
    end

    local function RestoreSkeletonLeg(char)
        if not char then return end
        local backup = skeletonBackups[char]
        if backup then
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    v:Destroy()
                end
            end
            for _, v in ipairs(backup) do
                v:Clone().Parent = char
            end
        end
    end

    local cachedZombieLeg = nil
    local zombieConn = nil
    local zombieBackups = {}

    local function ApplyZombieLeg(char, epoch)
        if not char or not cachedZombieLeg then return end
        task.wait(0.5)
        if epoch ~= zombieEpoch then return end -- Aborta se mudou de estado
        if not zombieBackups[char] then
            zombieBackups[char] = {}
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    table.insert(zombieBackups[char], v:Clone())
                end
            end
        end
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                v:Destroy()
            end
        end
        cachedZombieLeg:Clone().Parent = char
    end

    local function RestoreZombieLeg(char)
        if not char then return end
        local backup = zombieBackups[char]
        if backup then
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    v:Destroy()
                end
            end
            for _, v in ipairs(backup) do
                v:Clone().Parent = char
            end
        end
    end

    local function ApplyScepter(char, epoch)
        if not char then return end
        task.wait(0.5)
        if epoch ~= scepterEpoch then return end
        local obj = loadAsset(123021068422074)
        if epoch ~= scepterEpoch then 
            if obj then obj:Destroy() end
            return 
        end
        if obj then
            obj.Name = "RoyalScepterAccessory"
            SmartWeld(char, obj)
        end
    end

    local arrowAccessory = nil
    local arrowConn = nil

    local function ApplyArrow(char, epoch)
        if not char then return end
        task.wait(0.5)
        if epoch ~= arrowEpoch then return end
        local obj = loadAsset(100766397788633)
        if epoch ~= arrowEpoch then 
            if obj then obj:Destroy() end
            return 
        end
        if obj then
            obj.Name = "MysteriousArrowAccessory"
            SmartWeld(char, obj)
        end
    end

    -- Criação do Modal de Confirmação
    local PreviewBox = Instance.new("Frame")
    PreviewBox.Size = UDim2.new(0, 260, 0, 130)
    PreviewBox.AnchorPoint = Vector2.new(0.5, 0.5)
    PreviewBox.Position = UDim2.new(0.5, 0, 0.5, 0)
    PreviewBox.BackgroundColor3 = Color3.new(0,0,0)
    PreviewBox.BackgroundTransparency = 0.15
    PreviewBox.BorderSizePixel = 0
    PreviewBox.ZIndex = 11
    PreviewBox.Visible = false
    PreviewBox.Parent = ModalOverlay

    local PBStroke = Instance.new("UIStroke")
    PBStroke.Color = Color3.fromRGB(40, 40, 40)
    PBStroke.Parent = PreviewBox
    
    local PBTopLine = Instance.new("Frame")
    PBTopLine.Size = UDim2.new(1, 0, 0, 2)
    PBTopLine.BackgroundColor3 = Theme.Accent
    PBTopLine.BorderSizePixel = 0
    PBTopLine.ZIndex = 12
    PBTopLine.Parent = PreviewBox
    ApplyGradient(PBTopLine, Theme.Accent, Theme.AccentDark, 0)

    local PTitle = Instance.new("TextLabel")
    PTitle.Parent = PreviewBox
    PTitle.Text = "FOUND"
    PTitle.Font = Theme.Font
    PTitle.TextSize = 14
    PTitle.TextColor3 = Theme.Accent
    PTitle.Size = UDim2.new(1, 0, 0, 35)
    PTitle.BackgroundTransparency = 1
    PTitle.ZIndex = 12

    local PImage = Instance.new("ImageLabel")
    PImage.Size = UDim2.new(0, 46, 0, 46)
    PImage.Position = UDim2.new(0, 20, 0, 35)
    PImage.BackgroundColor3 = Theme.SwitchOff
    PImage.ZIndex = 12
    PImage.Parent = PreviewBox
    Instance.new("UICorner", PImage).CornerRadius = UDim.new(0, 6)

    local PName = Instance.new("TextLabel")
    PName.Text = "Name"
    PName.Size = UDim2.new(1, -80, 0, 46)
    PName.Position = UDim2.new(0, 75, 0, 35)
    PName.BackgroundTransparency = 1
    PName.TextColor3 = Theme.Text
    PName.Font = Enum.Font.Gotham
    PName.TextSize = 13
    PName.TextXAlignment = Enum.TextXAlignment.Left
    PName.ZIndex = 12
    PName.Parent = PreviewBox

    local PApplyBtn = Instance.new("TextButton")
    PApplyBtn.Text = "Apply"
    PApplyBtn.Size = UDim2.new(0, 100, 0, 28)
    PApplyBtn.Position = UDim2.new(0, 20, 0, 90)
    PApplyBtn.BackgroundColor3 = Theme.Accent
    PApplyBtn.TextColor3 = Color3.new(0,0,0)
    PApplyBtn.Font = Theme.Font
    PApplyBtn.TextSize = 12
    PApplyBtn.ZIndex = 12
    PApplyBtn.Parent = PreviewBox
    Instance.new("UICorner", PApplyBtn).CornerRadius = UDim.new(0, 4)
    ApplyGradient(PApplyBtn, Theme.Accent, Theme.AccentDark, 90)

    local PCancelBtn = Instance.new("TextButton")
    PCancelBtn.Text = "Cancel"
    PCancelBtn.Size = UDim2.new(0, 100, 0, 28)
    PCancelBtn.Position = UDim2.new(1, -120, 0, 90)
    PCancelBtn.BackgroundColor3 = Color3.new(0, 0, 0)
    PCancelBtn.BackgroundTransparency = 0.45
    PCancelBtn.TextColor3 = Theme.TextDark
    PCancelBtn.Font = Theme.Font
    PCancelBtn.TextSize = 12
    PCancelBtn.ZIndex = 12
    PCancelBtn.Parent = PreviewBox
    Instance.new("UICorner", PCancelBtn).CornerRadius = UDim.new(0, 4)
    local pcbStr = Instance.new("UIStroke", PCancelBtn)
    pcbStr.Color = Color3.fromRGB(40,40,40)

    PCancelBtn.MouseButton1Click:Connect(function() 
        ModalOverlay.Visible = false
        PreviewBox.Visible = false
        selectedModalId = nil 
        currentModalAction = nil
    end)
    
    PApplyBtn.MouseButton1Click:Connect(function() 
        if selectedModalId then
            if currentModalAction == "Skin" then
                TransformarSkin(selectedModalId)
            elseif currentModalAction == "Bundle" then
                if currentActiveBundleId then
                    local prevControl = bundleToggleControls[currentActiveBundleId]
                    if prevControl then prevControl.SetVisual(false) end
                end
                currentActiveBundleId = nil
                
                bundleEpoch = bundleEpoch + 1
                local currentEpoch = bundleEpoch
                
                task.spawn(function()
                    ApplyBundleSafe(selectedModalId, currentEpoch)
                    if currentEpoch ~= bundleEpoch then return end
                    if bundleConn then bundleConn:Disconnect() end
                    bundleConn = LocalPlayer.CharacterAdded:Connect(function(char)
                        ApplyBundleSafe(selectedModalId, currentEpoch)
                    end)
                end)
            elseif currentModalAction == "Accessory" then
                EquipAccessoryByID(selectedModalId)
            end
            ModalOverlay.Visible = false
            PreviewBox.Visible = false
        end
    end)

    -- Função Auxiliar para Criar Toggles no estilo de Cartões de Presets do Bundle Changer (Grid Sincronizado)
    local function CreateGridToggle(parent, text, iconId, defaultState, callback)
        local state = defaultState or false

        local Btn = Instance.new("TextButton")
        Btn.BackgroundColor3 = Color3.new(0, 0, 0)
        Btn.BackgroundTransparency = 0.45
        Btn.Text = ""
        Btn.Parent = parent
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

        local BStroke = Instance.new("UIStroke")
        BStroke.Color = Color3.fromRGB(40, 40, 40)
        BStroke.Thickness = 1
        BStroke.Parent = Btn

        local Icon = Instance.new("ImageLabel")
        Icon.Size = UDim2.new(0, 28, 0, 28)
        Icon.Position = UDim2.new(0, 7, 0.5, -14)
        Icon.BackgroundColor3 = Theme.SwitchOff
        Icon.BackgroundTransparency = 0.5
        Icon.Image = iconId
        Icon.Parent = Btn
        Instance.new("UICorner", Icon).CornerRadius = UDim.new(0, 6)

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -40, 1, 0)
        NameLabel.Position = UDim2.new(0, 36, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = text
        NameLabel.Font = Theme.Font
        NameLabel.TextScaled = true
        local nsConst = Instance.new("UITextSizeConstraint", NameLabel)
        nsConst.MinTextSize = 7
        nsConst.MaxTextSize = 11
        NameLabel.TextColor3 = Theme.TextDark
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Btn

        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0, 6, 0, 6)
        Indicator.Position = UDim2.new(1, -12, 0, 6)
        Indicator.BackgroundColor3 = Theme.Accent
        Indicator.Visible = false
        Indicator.Parent = Btn
        Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
        ApplyGradient(Indicator, Theme.Accent, Theme.AccentDark, 90)

        local function Upd(fireCallback)
            if state then
                TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
                TweenService:Create(NameLabel, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
                Indicator.Visible = true
            else
                TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
                TweenService:Create(NameLabel, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
                Indicator.Visible = false
            end
            if fireCallback then pcall(callback, state) end
        end

        Btn.MouseEnter:Connect(function()
            if not state then
                TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(80, 80, 80)}):Play()
            end
        end)
        Btn.MouseLeave:Connect(function()
            if not state then
                TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
            end
        end)

        Btn.MouseButton1Click:Connect(function()
            state = not state
            Upd(true)
        end)

        Upd(false)
        if state then task.spawn(function() pcall(callback, state) end) end

        return {
            Set = function(val)
                state = val
                Upd(true)
            end
        }
    end

    -- Função Auxiliar para Criar os Presets de Bundle como Toggles Exclusivos (Estilo Radio Button)
    local function SetupBundleToggle(btn, bndl)
        local state = false
        local bId = bndl.Id

        local Indicator = Instance.new("Frame")
        Indicator.Name = "Indicator"
        Indicator.Size = UDim2.new(0, 6, 0, 6)
        Indicator.Position = UDim2.new(1, -12, 0, 6)
        Indicator.BackgroundColor3 = Theme.Accent
        Indicator.Visible = false
        Indicator.Parent = btn
        Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
        ApplyGradient(Indicator, Theme.Accent, Theme.AccentDark, 90)

        local function UpdVisuals(isActive)
            state = isActive
            local BStroke = btn:FindFirstChildOfClass("UIStroke")
            local NameLabel = btn:FindFirstChildWhichIsA("TextLabel")
            if BStroke and NameLabel then
                if isActive then
                    TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
                    TweenService:Create(NameLabel, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
                    Indicator.Visible = true
                else
                    TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
                    TweenService:Create(NameLabel, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
                    Indicator.Visible = false
                end
            end
        end

        local function Action(isActive)
            bundleEpoch = bundleEpoch + 1
            local currentEpoch = bundleEpoch

            if isActive then
                if currentActiveBundleId and currentActiveBundleId ~= bId then
                    local prevControl = bundleToggleControls[currentActiveBundleId]
                    if prevControl then
                        prevControl.SetVisual(false)
                    end
                end
                currentActiveBundleId = bId

                task.spawn(function()
                    ApplyBundleSafe(bId, currentEpoch)
                    if currentEpoch ~= bundleEpoch then return end

                    if bundleConn then bundleConn:Disconnect() end
                    bundleConn = LocalPlayer.CharacterAdded:Connect(function(char)
                        ApplyBundleSafe(bId, currentEpoch)
                    end)
                end)
            else
                if currentActiveBundleId == bId then
                    currentActiveBundleId = nil
                    if bundleConn then bundleConn:Disconnect() bundleConn = nil end
                    if getgenv().FixLoop then getgenv().FixLoop:Disconnect() getgenv().FixLoop = nil end
                    if LocalPlayer.Character then
                        RestoreCharacterAppearance(LocalPlayer.Character)
                    end
                end
            end
        end

        btn.MouseButton1Click:Connect(function()
            state = not state
            UpdVisuals(state)
            Action(state)
        end)

        btn.MouseEnter:Connect(function()
            if not state then
                local BStroke = btn:FindFirstChildOfClass("UIStroke")
                if BStroke then TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(80, 80, 80)}):Play() end
            end
        end)
        btn.MouseLeave:Connect(function()
            if not state then
                local BStroke = btn:FindFirstChildOfClass("UIStroke")
                if BStroke then TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play() end
            end
        end)

        bundleToggleControls[bId] = {
            SetVisual = function(val)
                state = val
                UpdVisuals(val)
            end,
            Action = Action
        }
    end

    -- =======================================================
    -- [1] COLUNA SPLIT (BUNDLE CHANGER + ACCESSORIES CHANGER) - TOPO
    -- =======================================================
    local ColumnsContainer = Instance.new("Frame")
    ColumnsContainer.Name = "ColumnsContainer"
    ColumnsContainer.Size = UDim2.new(1, 0, 0, 0)
    ColumnsContainer.AutomaticSize = Enum.AutomaticSize.Y
    ColumnsContainer.BackgroundTransparency = 1
    ColumnsContainer.LayoutOrder = 1
    ColumnsContainer.Parent = Page

    local CCLayout = Instance.new("UIListLayout")
    CCLayout.FillDirection = Enum.FillDirection.Horizontal
    CCLayout.Padding = UDim.new(0, 12)
    CCLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CCLayout.Parent = ColumnsContainer

    local LeftCol = Instance.new("Frame")
    LeftCol.Name = "LeftCol"
    LeftCol.Size = UDim2.new(0.5, -6, 0, 0)
    LeftCol.AutomaticSize = Enum.AutomaticSize.Y
    LeftCol.BackgroundTransparency = 1
    LeftCol.Parent = ColumnsContainer
    local LL = Instance.new("UIListLayout")
    LL.Padding = UDim.new(0, 10)
    LL.SortOrder = Enum.SortOrder.LayoutOrder
    LL.Parent = LeftCol

    local RightCol = Instance.new("Frame")
    RightCol.Name = "RightCol"
    RightCol.Size = UDim2.new(0.5, -6, 0, 0)
    RightCol.AutomaticSize = Enum.AutomaticSize.Y
    RightCol.BackgroundTransparency = 1
    RightCol.Parent = ColumnsContainer
    local RL = Instance.new("UIListLayout")
    RL.Padding = UDim.new(0, 10)
    RL.SortOrder = Enum.SortOrder.LayoutOrder
    RL.Parent = RightCol

    -- [COLUNA ESQUERDA] - BUNDLE CHANGER
    local BundleChangerSection = Instance.new("Frame")
    BundleChangerSection.Name = "CategoryBox_BundleChanger"
    BundleChangerSection.Size = UDim2.new(1, 0, 0, 0)
    BundleChangerSection.AutomaticSize = Enum.AutomaticSize.Y
    BundleChangerSection.BackgroundColor3 = Color3.new(0, 0, 0)
    BundleChangerSection.BackgroundTransparency = 0.45
    BundleChangerSection.BorderSizePixel = 0
    BundleChangerSection.Parent = LeftCol

    Instance.new("UICorner", BundleChangerSection).CornerRadius = UDim.new(0, 6)
    local BCStroke = Instance.new("UIStroke")
    BCStroke.Color = Color3.fromRGB(40, 40, 40)
    BCStroke.Thickness = 1
    BCStroke.Parent = BundleChangerSection

    local BCLayout = Instance.new("UIListLayout")
    BCLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BCLayout.Padding = UDim.new(0, 8)
    BCLayout.Parent = BundleChangerSection

    local BCPadding = Instance.new("UIPadding")
    BCPadding.PaddingTop = UDim.new(0, 8)
    BCPadding.PaddingBottom = UDim.new(0, 8)
    BCPadding.PaddingLeft = UDim.new(0, 10)
    BCPadding.PaddingRight = UDim.new(0, 10)
    BCPadding.Parent = BundleChangerSection

    local BCHeader = Instance.new("Frame")
    BCHeader.Name = "HeaderContainer"
    BCHeader.Size = UDim2.new(1, 0, 0, 20)
    BCHeader.BackgroundTransparency = 1
    BCHeader.Parent = BundleChangerSection

    local BCLabel = Instance.new("TextLabel")
    BCLabel.Size = UDim2.new(1, 0, 1, 0)
    BCLabel.BackgroundTransparency = 1
    BCLabel.Text = "Bundle Changer"
    BCLabel:SetAttribute("OriginalText", "Bundle Changer")
    BCLabel.Font = Theme.Font
    BCLabel.TextSize = 12
    BCLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    BCLabel.TextXAlignment = Enum.TextXAlignment.Left
    BCLabel.Parent = BCHeader

    -- Input Box do Bundle Changer
    local BundleInputContainer = Instance.new("Frame")
    BundleInputContainer.Size = UDim2.new(1, 0, 0, 35)
    BundleInputContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    BundleInputContainer.BackgroundTransparency = 0.45
    BundleInputContainer.Parent = BundleChangerSection
    Instance.new("UICorner", BundleInputContainer).CornerRadius = UDim.new(0, 6)
    local bicStr = Instance.new("UIStroke", BundleInputContainer)
    bicStr.Color = Color3.fromRGB(40,40,40)
    bicStr.Thickness = 1

    local BundleInputBox = Instance.new("TextBox")
    BundleInputBox.Size = UDim2.new(1, -40, 1, 0)
    BundleInputBox.Position = UDim2.new(0, 10, 0, 0)
    BundleInputBox.BackgroundTransparency = 1
    BundleInputBox.Text = ""
    BundleInputBox.PlaceholderText = "Bundle ID (Ex: 201)..."
    BundleInputBox.TextColor3 = Theme.Text
    BundleInputBox.PlaceholderColor3 = Theme.TextDark
    BundleInputBox.Font = Theme.Font
    BundleInputBox.TextSize = 13
    BundleInputBox.TextXAlignment = Enum.TextXAlignment.Left
    BundleInputBox.Parent = BundleInputContainer

    local BundleSearchBtnIcon = Instance.new("ImageButton")
    BundleSearchBtnIcon.Size = UDim2.new(0, 20, 0, 20)
    BundleSearchBtnIcon.Position = UDim2.new(1, -28, 0.5, -10)
    BundleSearchBtnIcon.BackgroundTransparency = 1
    BundleSearchBtnIcon.Image = "rbxassetid://104986431790017"
    BundleSearchBtnIcon.ImageColor3 = Theme.Accent
    BundleSearchBtnIcon.ScaleType = Enum.ScaleType.Fit
    BundleSearchBtnIcon.Parent = BundleInputContainer

    -- Presets do Bundle Changer
    local BundlePresetsContainer = Instance.new("Frame")
    BundlePresetsContainer.Size = UDim2.new(1, 0, 0, 0)
    BundlePresetsContainer.BackgroundTransparency = 1
    BundlePresetsContainer.AutomaticSize = Enum.AutomaticSize.Y
    BundlePresetsContainer.Parent = BundleChangerSection

    local GridBundle = Instance.new("UIGridLayout")
    GridBundle.CellSize = UDim2.new(0.5, -4, 0, 42) 
    GridBundle.CellPadding = UDim2.new(0, 8, 0, 8)
    GridBundle.SortOrder = Enum.SortOrder.LayoutOrder
    GridBundle.Parent = BundlePresetsContainer

    local BundlePresets = {
        {Name = "Headless", Id = 201},
        {Name = "Korblox", Id = 192},
        {Name = "Skeleton", Id = 295},
        {Name = "Ice General", Id = 194},
        {Name = "Gnomo", Id = 652},
        {Name = "Dr. Fia Tyfoid", Id = 512}
    }

    for _, bndl in pairs(BundlePresets) do
        local Btn = Instance.new("TextButton")
        Btn.BackgroundColor3 = Color3.new(0, 0, 0)
        Btn.BackgroundTransparency = 0.45
        Btn.Text = ""
        Btn.Parent = BundlePresetsContainer
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

        local BStroke = Instance.new("UIStroke")
        BStroke.Color = Color3.fromRGB(40, 40, 40)
        BStroke.Thickness = 1
        BStroke.Parent = Btn

        local BundleIcon = Instance.new("ImageLabel")
        BundleIcon.Size = UDim2.new(0, 28, 0, 28)
        BundleIcon.Position = UDim2.new(0, 7, 0.5, -14)
        BundleIcon.BackgroundColor3 = Theme.SwitchOff
        BundleIcon.BackgroundTransparency = 0.5
        BundleIcon.Image = "rbxthumb://type=BundleThumbnail&id=" .. bndl.Id .. "&w=150&h=150"
        BundleIcon.Parent = Btn
        Instance.new("UICorner", BundleIcon).CornerRadius = UDim.new(0, 6)

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -40, 1, 0)
        NameLabel.Position = UDim2.new(0, 36, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = bndl.Name
        NameLabel.Font = Theme.Font
        NameLabel.TextScaled = true
        local nsConst = Instance.new("UITextSizeConstraint", NameLabel)
        nsConst.MinTextSize = 7
        nsConst.MaxTextSize = 11
        NameLabel.TextColor3 = Theme.TextDark
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Btn

        SetupBundleToggle(Btn, bndl)
    end

    BundleInputBox.FocusLost:Connect(function(enter) if enter then PerformBundleSearch() end end)
    SearchBtnIcon.MouseButton1Click:Connect(function() PerformBundleSearch() end)


    -- [COLUNA DIREITA] - ACCESSORIES CHANGER
    local ExclusiveSection = Instance.new("Frame")
    ExclusiveSection.Name = "CategoryBox_AccessoriesChanger"
    ExclusiveSection.Size = UDim2.new(1, 0, 0, 0)
    ExclusiveSection.AutomaticSize = Enum.AutomaticSize.Y
    ExclusiveSection.BackgroundColor3 = Color3.new(0, 0, 0)
    ExclusiveSection.BackgroundTransparency = 0.45
    ExclusiveSection.BorderSizePixel = 0
    ExclusiveSection.Parent = RightCol

    Instance.new("UICorner", ExclusiveSection).CornerRadius = UDim.new(0, 6)

    local ESStroke = Instance.new("UIStroke")
    ESStroke.Color = Color3.fromRGB(40, 40, 40)
    ESStroke.Thickness = 1
    ESStroke.Parent = ExclusiveSection

    local ESLayout = Instance.new("UIListLayout")
    ESLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ESLayout.Padding = UDim.new(0, 8)
    ESLayout.Parent = ExclusiveSection

    local ESPadding = Instance.new("UIPadding")
    ESPadding.PaddingTop = UDim.new(0, 8)
    ESPadding.PaddingBottom = UDim.new(0, 8)
    ESPadding.PaddingLeft = UDim.new(0, 10)
    ESPadding.PaddingRight = UDim.new(0, 10)
    ESPadding.Parent = ExclusiveSection

    local ESHeader = Instance.new("Frame")
    ESHeader.Name = "HeaderContainer"
    ESHeader.Size = UDim2.new(1, 0, 0, 20)
    ESHeader.BackgroundTransparency = 1
    ESHeader.Parent = ExclusiveSection

    local ESLabel = Instance.new("TextLabel")
    ESLabel.Size = UDim2.new(1, 0, 1, 0)
    ESLabel.BackgroundTransparency = 1
    ESLabel.Text = "Accessories Changer"
    ESLabel:SetAttribute("OriginalText", "Accessories Changer")
    ESLabel.Font = Theme.Font
    ESLabel.TextSize = 12
    ESLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ESLabel.TextXAlignment = Enum.TextXAlignment.Left
    ESLabel.Parent = ESHeader
    
    -- Barra de Pesquisa de IDs Customizados (100% Sincronizada)
    local CustomAssetInputContainer = Instance.new("Frame")
    CustomAssetInputContainer.Name = "CustomAssetInputContainer"
    CustomAssetInputContainer.Size = UDim2.new(1, 0, 0, 35)
    CustomAssetInputContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    CustomAssetInputContainer.BackgroundTransparency = 0.45
    CustomAssetInputContainer.Parent = ExclusiveSection
    Instance.new("UICorner", CustomAssetInputContainer).CornerRadius = UDim.new(0, 6)
    local caiStr = Instance.new("UIStroke", CustomAssetInputContainer)
    caiStr.Color = Color3.fromRGB(40,40,40)
    caiStr.Thickness = 1

    local CustomAssetInputBox = Instance.new("TextBox")
    CustomAssetInputBox.Size = UDim2.new(1, -40, 1, 0)
    CustomAssetInputBox.Position = UDim2.new(0, 10, 0, 0)
    CustomAssetInputBox.BackgroundTransparency = 1
    CustomAssetInputBox.Text = ""
    CustomAssetInputBox.PlaceholderText = "Asset/Accessory ID..."
    CustomAssetInputBox.TextColor3 = Theme.Text
    CustomAssetInputBox.PlaceholderColor3 = Theme.TextDark
    CustomAssetInputBox.Font = Theme.Font
    CustomAssetInputBox.TextSize = 13
    CustomAssetInputBox.TextXAlignment = Enum.TextXAlignment.Left
    CustomAssetInputBox.Parent = CustomAssetInputContainer

    local CustomAssetSearchBtnIcon = Instance.new("ImageButton")
    CustomAssetSearchBtnIcon.Size = UDim2.new(0, 20, 0, 20)
    CustomAssetSearchBtnIcon.Position = UDim2.new(1, -28, 0.5, -10)
    CustomAssetSearchBtnIcon.BackgroundTransparency = 1
    CustomAssetSearchBtnIcon.Image = "rbxassetid://104986431790017"
    CustomAssetSearchBtnIcon.ImageColor3 = Theme.Accent
    CustomAssetSearchBtnIcon.ScaleType = Enum.ScaleType.Fit
    CustomAssetSearchBtnIcon.Parent = CustomAssetInputContainer

    local function ProcessCustomAsset()
        local inputId = tonumber(CustomAssetInputBox.Text)
        if inputId then
            task.spawn(function()
                local name = "Catalog Item"
                local success, info = pcall(function()
                    return MarketplaceService:GetProductInfo(inputId)
                end)
                if success and info then
                    name = info.Name
                end
                
                selectedModalId = inputId
                currentModalAction = "Accessory"
                PTitle.Text = "EQUIP ITEM"
                PName.Text = name
                PApplyBtn.Text = "Equip"
                PImage.Image = "rbxthumb://type=Asset&id=" .. inputId .. "&w=150&h=150"
                ModalOverlay.Visible = true
                PreviewBox.Visible = true
            end)
        else
            SendNotification("Por favor, insira um ID válido.", 3)
        end
    end

    CustomAssetInputBox.FocusLost:Connect(function(enter) if enter then ProcessCustomAsset() end end)
    CustomAssetSearchBtnIcon.MouseButton1Click:Connect(ProcessCustomAsset)

    -- Container do Grid de Toggles
    local TogglesGridContainer = Instance.new("Frame")
    TogglesGridContainer.Name = "TogglesGridContainer"
    TogglesGridContainer.Size = UDim2.new(1, 0, 0, 0)
    TogglesGridContainer.BackgroundTransparency = 1
    TogglesGridContainer.AutomaticSize = Enum.AutomaticSize.Y
    TogglesGridContainer.Parent = ExclusiveSection

    local GridTgl = Instance.new("UIGridLayout")
    GridTgl.CellSize = UDim2.new(0.5, -4, 0, 42)
    GridTgl.CellPadding = UDim2.new(0, 8, 0, 8)
    GridTgl.SortOrder = Enum.SortOrder.LayoutOrder
    GridTgl.Parent = TogglesGridContainer

    -- Botões de Toggles Seguros de Race Conditions (Epoch-Safe)
    CreateGridToggle(TogglesGridContainer, "Headless", "rbxthumb://type=BundleThumbnail&id=201&w=150&h=150", false, function(state)
        headlessEpoch = headlessEpoch + 1
        local currentEpoch = headlessEpoch
        activeAccessoriesStates.Headless = state
        
        if state then
            task.spawn(function()
                if not cachedHeadlessMesh then
                    local success, bundleDetails = pcall(function() return AssetService:GetBundleDetailsAsync(201) end)
                    if currentEpoch ~= headlessEpoch then return end
                    if success and bundleDetails then
                        local targetDesc = nil
                        for _, item in ipairs(bundleDetails.Items) do
                            if item.Type == "UserOutfit" then
                                local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
                                if s and desc then targetDesc = desc break end
                            end
                        end
                        if targetDesc then
                            local dummy = Players:CreateHumanoidModelFromDescription(targetDesc, Enum.HumanoidRigType.R6)
                            local dummyHead = dummy:FindFirstChild("Head")
                            if dummyHead then
                                local mesh = dummyHead:FindFirstChildOfClass("SpecialMesh")
                                if mesh then cachedHeadlessMesh = mesh:Clone() end
                            end
                            dummy:Destroy()
                        end
                    end
                end
                
                if currentEpoch ~= headlessEpoch then return end

                if cachedHeadlessMesh then
                    if LocalPlayer.Character then ApplyHeadless(LocalPlayer.Character, currentEpoch) end
                    if headlessConn then headlessConn:Disconnect() end
                    headlessConn = LocalPlayer.CharacterAdded:Connect(function(char) ApplyHeadless(char, currentEpoch) end)
                else
                    SendNotification("Failed to load Headless", 3)
                end
            end)
        else
            if headlessConn then headlessConn:Disconnect() headlessConn = nil end
            if LocalPlayer.Character then RestoreHeadless(LocalPlayer.Character) end
        end
    end)
    
    CreateGridToggle(TogglesGridContainer, "Korblox", "rbxassetid://93791173513996", false, function(state)
        korbloxEpoch = korbloxEpoch + 1
        local currentEpoch = korbloxEpoch
        activeAccessoriesStates.Korblox = state
        
        if state then
            task.spawn(function()
                if not cachedKorbloxLeg then
                    local success, bundleDetails = pcall(function() return AssetService:GetBundleDetailsAsync(192) end)
                    if currentEpoch ~= korbloxEpoch then return end
                    if success and bundleDetails then
                        local targetDesc = nil
                        for _, item in ipairs(bundleDetails.Items) do
                            if item.Type == "UserOutfit" then
                                local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
                                if s and desc then targetDesc = desc break end
                            end
                        end
                        if targetDesc then
                            local dummy = Players:CreateHumanoidModelFromDescription(targetDesc, Enum.HumanoidRigType.R6)
                            for _, item in pairs(dummy:GetChildren()) do
                                if item:IsA("CharacterMesh") and item.BodyPart == Enum.BodyPart.RightLeg then
                                    cachedKorbloxLeg = item:Clone()
                                    break
                                end
                            end
                            dummy:Destroy()
                        end
                    end
                end
                
                if currentEpoch ~= korbloxEpoch then return end

                if cachedKorbloxLeg then
                    if LocalPlayer.Character then ApplyKorblox(LocalPlayer.Character, currentEpoch) end
                    if korbloxConn then korbloxConn:Disconnect() end
                    korbloxConn = LocalPlayer.CharacterAdded:Connect(function(char) ApplyKorblox(char, currentEpoch) end)
                else
                    SendNotification("Failed to load Korblox", 3)
                end
            end)
        else
            if korbloxConn then korbloxConn:Disconnect() korbloxConn = nil end
            if LocalPlayer.Character then RestoreKorblox(LocalPlayer.Character) end
        end
    end)

    CreateGridToggle(TogglesGridContainer, "Skeleton Leg", "rbxassetid://118599491782541", false, function(state)
        skeletonEpoch = skeletonEpoch + 1
        local currentEpoch = skeletonEpoch
        activeAccessoriesStates.SkeletonLeg = state
        
        if state then
            task.spawn(function()
                if not cachedSkeletonLeg then
                    local success, bundleDetails = pcall(function() return AssetService:GetBundleDetailsAsync(295) end)
                    if currentEpoch ~= skeletonEpoch then return end
                    if success and bundleDetails then
                        local targetDesc = nil
                        for _, item in ipairs(bundleDetails.Items) do
                            if item.Type == "UserOutfit" then
                                local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
                                if s and desc then targetDesc = desc break end
                            end
                        end
                        if targetDesc then
                            local dummy = Players:CreateHumanoidModelFromDescription(targetDesc, Enum.HumanoidRigType.R6)
                            for _, item in pairs(dummy:GetChildren()) do
                                if item:IsA("CharacterMesh") and item.BodyPart == Enum.BodyPart.RightLeg then
                                    cachedSkeletonLeg = item:Clone()
                                    break
                                end
                            end
                            dummy:Destroy()
                        end
                    end
                end
                
                if currentEpoch ~= skeletonEpoch then return end

                if cachedSkeletonLeg then
                    if LocalPlayer.Character then ApplySkeletonLeg(LocalPlayer.Character, currentEpoch) end
                    if skeletonConn then skeletonConn:Disconnect() end
                    skeletonConn = LocalPlayer.CharacterAdded:Connect(function(char) ApplySkeletonLeg(char, currentEpoch) end)
                else
                    SendNotification("Failed to load Skeleton Leg", 3)
                end
            end)
        else
            if skeletonConn then skeletonConn:Disconnect() skeletonConn = nil end
            if LocalPlayer.Character then RestoreSkeletonLeg(LocalPlayer.Character) end
        end
    end)

    CreateGridToggle(TogglesGridContainer, "Zombie Leg", "rbxassetid://137720329950856", false, function(state)
        zombieEpoch = zombieEpoch + 1
        local currentEpoch = zombieEpoch
        activeAccessoriesStates.ZombieLeg = state
        
        if state then
            task.spawn(function()
                if not cachedZombieLeg then
                    local success, bundleDetails = pcall(function() return AssetService:GetBundleDetailsAsync(291) end)
                    if currentEpoch ~= zombieEpoch then return end
                    if success and bundleDetails then
                        local targetDesc = nil
                        for _, item in ipairs(bundleDetails.Items) do
                            if item.Type == "UserOutfit" then
                                local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
                                if s and desc then targetDesc = desc break end
                            end
                        end
                        if targetDesc then
                            local dummy = Players:CreateHumanoidModelFromDescription(targetDesc, Enum.HumanoidRigType.R6)
                            for _, item in pairs(dummy:GetChildren()) do
                                if item:IsA("CharacterMesh") and item.BodyPart == Enum.BodyPart.RightLeg then
                                    cachedZombieLeg = item:Clone()
                                    break
                                end
                            end
                            dummy:Destroy()
                        end
                    end
                end
                
                if currentEpoch ~= zombieEpoch then return end

                if cachedZombieLeg then
                    if LocalPlayer.Character then ApplyZombieLeg(LocalPlayer.Character, currentEpoch) end
                    if zombieConn then zombieConn:Disconnect() end
                    zombieConn = LocalPlayer.CharacterAdded:Connect(function(char) ApplyZombieLeg(char, currentEpoch) end)
                else
                    SendNotification("Failed to load Zombie Leg", 3)
                end
            end)
        else
            if zombieConn then zombieConn:Disconnect() zombieConn = nil end
            if LocalPlayer.Character then RestoreZombieLeg(LocalPlayer.Character) end
        end
    end)

    CreateGridToggle(TogglesGridContainer, "Royal Scepter", "rbxthumb://type=Asset&id=123021068422074&w=150&h=150", false, function(state)
        scepterEpoch = scepterEpoch + 1
        local currentEpoch = scepterEpoch
        activeAccessoriesStates.RoyalScepter = state
        
        if state then
            task.spawn(function()
                task.wait(0.5)
                if currentEpoch ~= scepterEpoch then return end

                local obj = loadAsset(123021068422074)
                if currentEpoch ~= scepterEpoch then 
                    if obj then obj:Destroy() end
                    return 
                end

                if obj then
                    obj.Name = "RoyalScepterAccessory"
                    if scepterAccessory then scepterAccessory:Destroy() end
                    scepterAccessory = obj
                    SmartWeld(LocalPlayer.Character, obj)
                end

                if scepterConn then scepterConn:Disconnect() end
                scepterConn = LocalPlayer.CharacterAdded:Connect(function(char) ApplyScepter(char, currentEpoch) end)
            end)
        else
            if scepterConn then scepterConn:Disconnect() scepterConn = nil end
            if scepterAccessory then scepterAccessory:Destroy() scepterAccessory = nil end
            if LocalPlayer.Character then
                local existing = LocalPlayer.Character:FindFirstChild("RoyalScepterAccessory")
                if existing then existing:Destroy() end
            end
        end
    end)

    CreateGridToggle(TogglesGridContainer, "Mysterious Arrow", "rbxthumb://type=Asset&id=100766397788633&w=150&h=150", false, function(state)
        arrowEpoch = arrowEpoch + 1
        local currentEpoch = arrowEpoch
        activeAccessoriesStates.MysteriousArrow = state
        
        if state then
            task.spawn(function()
                task.wait(0.5)
                if currentEpoch ~= arrowEpoch then return end

                local obj = loadAsset(100766397788633)
                if currentEpoch ~= arrowEpoch then 
                    if obj then obj:Destroy() end
                    return 
                end

                if obj then
                    obj.Name = "MysteriousArrowAccessory"
                    if arrowAccessory then arrowAccessory:Destroy() end
                    arrowAccessory = obj
                    SmartWeld(LocalPlayer.Character, obj)
                end

                if arrowConn then arrowConn:Disconnect() end
                arrowConn = LocalPlayer.CharacterAdded:Connect(function(char) ApplyArrow(char, currentEpoch) end)
            end)
        else
            if arrowConn then arrowConn:Disconnect() arrowConn = nil end
            if arrowAccessory then arrowAccessory:Destroy() arrowAccessory = nil end
            if LocalPlayer.Character then
                local existing = LocalPlayer.Character:FindFirstChild("MysteriousArrowAccessory")
                if existing then existing:Destroy() end
            end
        end
    end)


    -- =======================================================
    -- [ESPAÇADOR] - ENTRE O TOPO E O SKIN CHANGER
    -- =======================================================
    local LayoutSpacer = Instance.new("Frame")
    LayoutSpacer.Name = "LayoutSpacer"
    LayoutSpacer.Size = UDim2.new(1, 0, 0, 10)
    LayoutSpacer.BackgroundTransparency = 1
    LayoutSpacer.LayoutOrder = 2
    LayoutSpacer.Parent = Page


    -- =======================================================
    -- [2] SKIN CHANGER (LARGURA TOTAL, COM CONFIGURAÇÃO DE 3 COLUNAS)
    -- =======================================================
    local before = #Page:GetChildren()
    Library:CreateSection(Page, "Skin Changer")
    
    -- Ajuste do cabeçalho original para ficar na ordem correta
    local pageChildren = Page:GetChildren()
    local lastSectionHeader = pageChildren[#pageChildren]
    if lastSectionHeader and lastSectionHeader:IsA("Frame") then
        lastSectionHeader.LayoutOrder = 3
    end

    -- Input Box do Skin Changer
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -2, 0, 35)
    InputContainer.Position = UDim2.new(0, 1, 0, 0)
    InputContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    InputContainer.BackgroundTransparency = 0.45
    InputContainer.LayoutOrder = 4
    InputContainer.Parent = Page
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 6)
    local icStr = Instance.new("UIStroke", InputContainer)
    icStr.Color = Color3.fromRGB(40,40,40)

    local UserInputBox = Instance.new("TextBox")
    UserInputBox.Size = UDim2.new(1, -40, 1, 0)
    UserInputBox.Position = UDim2.new(0, 10, 0, 0)
    UserInputBox.BackgroundTransparency = 1
    UserInputBox.Text = ""
    UserInputBox.PlaceholderText = "Username..."
    UserInputBox.TextColor3 = Theme.Text
    UserInputBox.PlaceholderColor3 = Theme.TextDark
    UserInputBox.Font = Theme.Font
    UserInputBox.TextSize = 13
    UserInputBox.TextXAlignment = Enum.TextXAlignment.Left
    UserInputBox.Parent = InputContainer

    local SearchBtnIcon = Instance.new("ImageButton")
    SearchBtnIcon.Size = UDim2.new(0, 20, 0, 20)
    SearchBtnIcon.Position = UDim2.new(1, -28, 0.5, -10)
    SearchBtnIcon.BackgroundTransparency = 1
    SearchBtnIcon.Image = "rbxassetid://104986431790017"
    SearchBtnIcon.ImageColor3 = Theme.Accent
    SearchBtnIcon.ScaleType = Enum.ScaleType.Fit
    SearchBtnIcon.Parent = InputContainer

    -- Presets do Skin Changer (Redesenhados para exibir 3 colunas em vez de 2)
    local PresetsContainer = Instance.new("Frame")
    PresetsContainer.Size = UDim2.new(1, 0, 0, 0)
    PresetsContainer.BackgroundTransparency = 1
    PresetsContainer.AutomaticSize = Enum.AutomaticSize.Y
    PresetsContainer.LayoutOrder = 5
    PresetsContainer.Parent = Page

    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0.333, -6, 0, 42) -- Grade de 3 Colunas
    Grid.CellPadding = UDim2.new(0, 8, 0, 8)
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.Parent = PresetsContainer

    local DummyNames = {
        "y4am1n380", "eduttk7", "Victoria234h", "1Pexssz", "Vaultzinx",
        "fleepkkj", "znerx3ys", "TryNotToRageew", "DenzelDxvices", "DraxynSoulx", "Gaie_VR", "totallyvelez", "steik00s", "Guime_blox", "sennapy", "Mwaiconn", "Dexterzxxp", "Jpzinux", "Udies11br", "akatexs", "phzin_it1", "hq_slyin", "Dv_223", "Dimeyuri", "JaoEverCry", "Baydiina", "Meshew", "SniperFq",
        "sukyaik", "nathanserafas12", "guhtorrez", "sthefany12091", "011coded", 
        "Marionete533", "akatexs", "j_oqoo", "lauriinhakplayer", "tio_morcego", "l_qke", "pqsteljxde", "brokensfr", "TotallyFerr", "ZxvqZayan", "cw_223"
    }

    local function PerformSearch(forcedText)
        local text = forcedText or UserInputBox.Text
        if text and text ~= "" then
            UserInputBox.Text = text
            local s, id = pcall(function() return Players:GetUserIdFromNameAsync(text) end)
            if s and id then
                selectedModalId = id
                currentModalAction = "Skin"
                PTitle.Text = "SKIN FOUND"
                PName.Text = text
                PApplyBtn.Text = "Apply Skin"
                local thumb, isReady = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                if isReady then
                    PImage.Image = thumb
                    ModalOverlay.Visible = true
                    PreviewBox.Visible = true
                end
            else
                SendNotification("User not found!", 2)
            end
        end
    end

    UserInputBox.FocusLost:Connect(function(enter) if enter then PerformSearch() end end)
    SearchBtnIcon.MouseButton1Click:Connect(function() PerformSearch() end)

    for _, name in pairs(DummyNames) do
        local Btn = Instance.new("TextButton")
        Btn.BackgroundColor3 = Color3.new(0, 0, 0)
        Btn.BackgroundTransparency = 0.45
        Btn.Text = ""
        Btn.Parent = PresetsContainer
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

        local BStroke = Instance.new("UIStroke")
        BStroke.Color = Color3.fromRGB(40, 40, 40)
        BStroke.Thickness = 1
        BStroke.Parent = Btn

        local AvatarIcon = Instance.new("ImageLabel")
        AvatarIcon.Size = UDim2.new(0, 28, 0, 28)
        AvatarIcon.Position = UDim2.new(0, 7, 0.5, -14)
        AvatarIcon.BackgroundColor3 = Theme.SwitchOff
        AvatarIcon.BackgroundTransparency = 0.5
        AvatarIcon.Parent = Btn
        Instance.new("UICorner", AvatarIcon).CornerRadius = UDim.new(0, 6)

        -- Nome de Exibição (Display Name) como principal (Bold e Marcado)
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -40, 0.45, 0)
        NameLabel.Position = UDim2.new(0, 36, 0.05, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = name -- Começa com o username como fallback
        NameLabel.Font = Theme.Font
        NameLabel.TextScaled = true
        local nsConst = Instance.new("UITextSizeConstraint", NameLabel)
        nsConst.MinTextSize = 7
        nsConst.MaxTextSize = 11
        NameLabel.TextColor3 = Theme.Text
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Btn

        -- Username original (@Username) embaixo de forma secundária (Dim e Normal)
        local UserLabel = Instance.new("TextLabel")
        UserLabel.Size = UDim2.new(1, -40, 0.35, 0)
        UserLabel.Position = UDim2.new(0, 36, 0.5, 0)
        UserLabel.BackgroundTransparency = 1
        UserLabel.Text = "@" .. name
        UserLabel.Font = Enum.Font.Gotham
        UserLabel.TextScaled = true
        local usConst = Instance.new("UITextSizeConstraint", UserLabel)
        usConst.MinTextSize = 6
        usConst.MaxTextSize = 9
        UserLabel.TextColor3 = Theme.TextDark
        UserLabel.TextXAlignment = Enum.TextXAlignment.Left
        UserLabel.Parent = Btn

        Btn.MouseEnter:Connect(function() TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play() end)
        Btn.MouseLeave:Connect(function() TweenService:Create(BStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play() end)

        -- Carrega dados e imagens de forma assíncrona para desempenho ideal (sem lag ao abrir a aba)
        task.spawn(function()
            local s, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
            if s and id then
                local thumb = "rbxthumb://type=AvatarHeadShot&id=" .. id .. "&w=150&h=150"
                AvatarIcon.Image = thumb
                
                local dispName, userName = name, "@" .. name
                local pInServer = Players:FindFirstChild(name)
                if pInServer then
                    dispName, userName = pInServer.DisplayName, "@" .. pInServer.Name
                else
                    local s2, result = pcall(function()
                        return game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(id))
                    end)
                    if s2 and result then
                        local decoded = HttpService:JSONDecode(result)
                        if decoded and decoded.displayName and decoded.name then
                            dispName = decoded.displayName
                            userName = "@" .. decoded.name
                        end
                    end
                end
                
                NameLabel.Text = dispName
                UserLabel.Text = userName
            end
        end)
        
        Btn.MouseButton1Click:Connect(function() PerformSearch(name) end)
    end

    -- Listener Global para Reaplicar a Skin caso o jogador resete ou morra
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        if activeSkinUserId then
            TransformarSkin(activeSkinUserId)
        end
    end)
end
