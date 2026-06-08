return function(env)
    local Library = env.Library
    local Page = env.Page
    local Workspace = env.Workspace
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local RunService = env.RunService
    local CoreGui = env.CoreGui
    local Theme = env.Theme
    local UserConfigs = env.UserConfigs
    local SendNotification = env.SendNotification
    local isMobile = env.isMobile

    local HideLeavesConnection = nil
    local hiddenParts = setmetatable({}, {__mode = "k"}) 
    local currentFont = "Default"
    local originalFonts = setmetatable({}, {__mode = "k"})
    
    local originalName = LocalPlayer.Name
    local originalDisplayName = LocalPlayer.DisplayName
    local originalLevel = "1"
    local spoofName = LocalPlayer.Name
    local spoofLevel = 100
    local spoofIconId = "rbxassetid://1188562340"
    
    local spoofedOthers = {}
    local othersOriginalData = {}
    local spoofOthersEnabled = false
    
    local targetOrigName = "Select Player"
    local targetFakeName = "Fake Name"
    local targetFakeLevel = 100
    local targetFakeIcon = ""

    local spoofVisualsEnabled = false
    local spoofVisualsLoop
    local meusIcones = {
        VIP = "rbxassetid://1188562340",
        QA = "rbxassetid://105177418407648",
        CON = "rbxassetid://76898592264692",
        Mod = "rbxassetid://105155010224102",
        Dev = "rbxassetid://18940006678",
        Manager = "rbxassetid://131476591459702",
        MrWindy = "rbxassetid://18937953345",
        Nenhum = ""
    }
    local originalTexts = setmetatable({}, {__mode = "k"})
    
    local function patchElement(e)
        if not e or not e:IsA("GuiObject") then return end
        if not (e:IsA("TextLabel") or e:IsA("TextButton") or e:IsA("TextBox")) then return end
        local ok, txt = pcall(function() return e.Text end)
        if not ok or not txt or txt == "" then return end
        
        local changed = false
        local newTxt = txt
        
        if spoofVisualsEnabled then
            if newTxt:find(originalName, 1, true) then
                newTxt = newTxt:gsub(originalName, spoofName)
                changed = true
            end
            if originalDisplayName and newTxt:find(originalDisplayName, 1, true) then
                newTxt = newTxt:gsub(originalDisplayName, spoofName)
                changed = true
            end
        end
        
        if spoofOthersEnabled then
            for origNameKey, fakeData in pairs(spoofedOthers) do
                local fakeName = fakeData.spoofName
                if newTxt:find(origNameKey, 1, true) then
                    newTxt = newTxt:gsub(origNameKey, fakeName)
                    changed = true
                end
                local backup = othersOriginalData[origNameKey]
                local origDisp = backup and backup.DisplayName
                if origDisp and newTxt:find(origDisp, 1, true) then
                    newTxt = newTxt:gsub(origDisp, fakeName)
                    changed = true
                end
            end
        end
        
        if changed then
            if not originalTexts[e] then originalTexts[e] = txt end
            pcall(function() e.Text = newTxt end)
        else
            if originalTexts[e] and txt ~= originalTexts[e] then
                local orig = originalTexts[e]
                local shouldBeSpoofed = false
                
                if spoofVisualsEnabled and (orig:find(originalName, 1, true) or (originalDisplayName and orig:find(originalDisplayName, 1, true))) then
                    shouldBeSpoofed = true
                end
                
                if spoofOthersEnabled and not shouldBeSpoofed then
                    for origNameKey, _ in pairs(spoofedOthers) do
                        local backup = othersOriginalData[origNameKey]
                        local origDisp = backup and backup.DisplayName
                        if orig:find(origNameKey, 1, true) or (origDisp and orig:find(origDisp, 1, true)) then
                            shouldBeSpoofed = true
                            break
                        end
                    end
                end
                
                if not shouldBeSpoofed then
                    pcall(function() e.Text = orig end)
                end
            end
        end
    end
    
    local function trackElement(e)
        if not e then return end
        if e:IsA("TextLabel") or e:IsA("TextButton") or e:IsA("TextBox") then
            patchElement(e)
            pcall(function() e:GetPropertyChangedSignal("Text"):Connect(function() patchElement(e) end) end)
        end
    end
    local trackersInitialized = false

    local function updateTrackers()
        if not trackersInitialized then
            trackersInitialized = true
            pcall(function()
                for _, gui in ipairs(CoreGui:GetDescendants()) do trackElement(gui) end
                CoreGui.DescendantAdded:Connect(trackElement)
                local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
                if playerGui then
                    for _, gui in ipairs(playerGui:GetDescendants()) do trackElement(gui) end
                    playerGui.DescendantAdded:Connect(trackElement)
                end
            end)
        end
        for e, origTxt in pairs(originalTexts) do
            if e and e.Parent then 
                pcall(function() e.Text = origTxt end)
                patchElement(e)
            end
        end
    end

    spoofVisualsLoop = RunService.Heartbeat:Connect(function()
        if not spoofVisualsEnabled and not spoofOthersEnabled then return end
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local namesFrame = playerGui and playerGui:FindFirstChild("PlayerNamesFrame", true)

            if spoofOthersEnabled then
                for origNameKey, data in pairs(spoofedOthers) do
                    local player = Players:FindFirstChild(origNameKey)
                    if player and player.Character then
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum then 
                            pcall(function() hum.DisplayName = data.spoofName end) 
                        end
                    end
                    
                    if namesFrame then
                        local playerFrame = namesFrame:FindFirstChild(origNameKey .. "PlayerFrame")
                        if playerFrame then
                            local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                            local nameLabel  = playerFrame:FindFirstChild("NameLabel")
                            local iconLabel  = playerFrame:FindFirstChild("IconLabel")
                            
                            if levelLabel then levelLabel.Text = tostring(data.spoofLevel) end
                            if nameLabel then nameLabel.Text = data.spoofName end
                            if iconLabel then 
                                iconLabel.ImageTransparency = 1
                                local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                                if not fakeIcon then
                                    fakeIcon = Instance.new("ImageLabel")
                                    fakeIcon.Name = "IconeFakeCorrigido"
                                    fakeIcon.BackgroundTransparency = 1
                                    fakeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                                    fakeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
                                    fakeIcon.ZIndex = iconLabel.ZIndex + 1
                                    fakeIcon.Parent = iconLabel
                                end
                                fakeIcon.Image = data.spoofIcon
                                fakeIcon.Visible = true
                                fakeIcon.ScaleType = Enum.ScaleType.Fit
                                
                                if data.spoofIcon == meusIcones.QA or data.spoofIcon == meusIcones.CON then
                                    fakeIcon.Size = UDim2.new(1.35, 0, 1.35, 0) 
                                else
                                    fakeIcon.Size = UDim2.new(1.0, 0, 1.0, 0)
                                end
                            end
                        end
                    end
                end
            end
            
            if spoofVisualsEnabled then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum.DisplayName = spoofName end) end
                    local head = char:FindFirstChild("Head")
                    if head then
                        for _, gui in ipairs(head:GetChildren()) do
                            if gui:IsA("BillboardGui") then
                                for _, d in ipairs(gui:GetDescendants()) do trackElement(d) end
                            end
                        end
                    end
                end
                
                if not namesFrame then return end
                local playerFrame = namesFrame:FindFirstChild(LocalPlayer.Name .. "PlayerFrame")
                if not playerFrame then return end
                local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                local nameLabel  = playerFrame:FindFirstChild("NameLabel")
                local iconLabel  = playerFrame:FindFirstChild("IconLabel")
                if levelLabel and originalLevel == "1" and levelLabel.Text ~= tostring(spoofLevel) then
                    originalLevel = levelLabel.Text
                end
                if levelLabel then levelLabel.Text = tostring(spoofLevel) end
                if nameLabel then nameLabel.Text = spoofName end
                if iconLabel then 
                    iconLabel.ImageTransparency = 1
                    local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                    if not fakeIcon then
                        fakeIcon = Instance.new("ImageLabel")
                        fakeIcon.Name = "IconeFakeCorrigido"
                        fakeIcon.BackgroundTransparency = 1
                        fakeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                        fakeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
                        fakeIcon.ZIndex = iconLabel.ZIndex + 1
                        fakeIcon.Parent = iconLabel
                    end
                    fakeIcon.Image = spoofIconId
                    fakeIcon.Visible = true
                    fakeIcon.ScaleType = Enum.ScaleType.Fit
                    if spoofIconId == meusIcones.QA or spoofIconId == meusIcones.CON then
                        fakeIcon.Size = UDim2.new(1.35, 0, 1.35, 0) 
                    else
                        fakeIcon.Size = UDim2.new(1.0, 0, 1.0, 0)
                    end
                end
                playerFrame.LayoutOrder = -spoofLevel
            end
        end)
    end)

    local function restoreOtherPlayer(realName)
        if not realName then return end
        spoofedOthers[realName] = nil
        
        local backup = othersOriginalData[realName]
        local player = Players:FindFirstChild(realName)
        if player and player.Character and backup then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then 
                pcall(function() hum.DisplayName = backup.DisplayName end) 
            end
        end
        
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local namesFrame = playerGui and playerGui:FindFirstChild("PlayerNamesFrame", true)
        if namesFrame then
            local playerFrame = namesFrame:FindFirstChild(realName .. "PlayerFrame")
            if playerFrame then
                local iconLabel = playerFrame:FindFirstChild("IconLabel")
                local nameLabel = playerFrame:FindFirstChild("NameLabel")
                local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                
                if iconLabel then
                    iconLabel.ImageTransparency = 0
                    local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                    if fakeIcon then fakeIcon.Visible = false end
                end
                
                if nameLabel and backup then
                    nameLabel.Text = backup.Name
                end
                if levelLabel and backup then
                    levelLabel.Text = backup.Level
                end
            end
        end
        updateTrackers()
    end

    local stretchConnection = nil
    local grayConns = {}
    local grayBackups = setmetatable({}, {__mode = "k"})

    local function makeGray(char)
        if not char then return end
        if not grayBackups[char] then
            grayBackups[char] = { parts = setmetatable({}, {__mode="k"}), meshes = setmetatable({}, {__mode="k"}), clothes = {} }
        end
        local backup = grayBackups[char]
        
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:FindFirstAncestorWhichIsA("Tool") then continue end
            if obj:IsA("BasePart") then
                if not backup.parts[obj] then
                    backup.parts[obj] = { Color = obj.Color, Material = obj.Material }
                end
                obj.Color = Color3.fromRGB(150, 150, 150)
                obj.Material = Enum.Material.SmoothPlastic
                if obj:IsA("MeshPart") then
                    if not backup.meshes[obj] then backup.meshes[obj] = obj.TextureID end
                    obj.TextureID = ""
                end
            elseif obj:IsA("SpecialMesh") then
                if not backup.meshes[obj] then backup.meshes[obj] = obj.TextureId end
                obj.TextureId = ""
            elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") or (obj:IsA("Decal") and obj.Name ~= "face") then
                table.insert(backup.clothes, {obj = obj, parent = obj.Parent})
                obj.Parent = nil
            end
        end
    end
    
    local function restoreGray(char)
        local backup = grayBackups[char]
        if not backup then return end
        
        for part, data in pairs(backup.parts) do
            if part and part.Parent then
                part.Color = data.Color
                part.Material = data.Material
            end
        end
        for mesh, tex in pairs(backup.meshes) do
            if mesh and mesh.Parent then
                if mesh:IsA("MeshPart") then mesh.TextureID = tex
                elseif mesh:IsA("SpecialMesh") then mesh.TextureId = tex end
            end
        end
        for _, clothData in ipairs(backup.clothes) do
            if clothData.obj then clothData.obj.Parent = clothData.parent end
        end
        grayBackups[char] = nil
    end

    Library:CreateSection(Page, "Camera & UI", "Left")
    local FovVal = 70
    Library:CreateSlider(Page, "Fov Changer", 70, 120, 70, function(v) 
        FovVal = v 
    end)
    RunService.RenderStepped:Connect(function() 
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = FovVal end
    end)
    
    local fontOptions = {"Default"}
    for _, font in ipairs(Enum.Font:GetEnumItems()) do
        if font.Name ~= "Unknown" and font.Name ~= "Legacy" then table.insert(fontOptions, font.Name) end
    end
    Library:CreateDropdown(Page, "Font Changer", fontOptions, "Default", function(val) 
        currentFont = val
        local function applyFont(obj)
            if not originalFonts[obj] then originalFonts[obj] = obj.FontFace end
            if currentFont == "Default" then
                pcall(function() obj.FontFace = originalFonts[obj] end)
            else
                local selectedFont = Enum.Font[currentFont]
                if selectedFont then
                    pcall(function() obj.FontFace = Font.fromEnum(selectedFont) end)
                end
            end
        end
        for _, obj in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then applyFont(obj) end
        end
        LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d) 
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then task.defer(applyFont, d) end 
        end)
    end)
    
    Library:CreateToggle(Page, "stretch screen", false, function(state) 
        if state then 
            getgenv().Resolution = {[".gg/scripters"] = 0.65}
            local Cam = workspace.CurrentCamera
            stretchConnection = game:GetService("RunService").RenderStepped:Connect(function() 
                Cam.CFrame = Cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1) 
            end) 
        else 
            if stretchConnection then 
                stretchConnection:Disconnect()
                stretchConnection = nil 
            end
            getgenv().Resolution = {[".gg/scripters"] = 1} 
        end 
    end)

    Library:CreateSection(Page, "Spoof Actions", "Left")
    Library:CreateButton(Page, "Apply To Selected Player", function()
        if targetOrigName ~= "Select Player" and targetFakeName ~= "" then
            local p = Players:FindFirstChild(targetOrigName)
            if p then
                if not othersOriginalData[p.Name] then
                    local origName = p.DisplayName
                    local origLevel = "1"
                    
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    local namesFrame = playerGui and playerGui:FindFirstChild("PlayerNamesFrame", true)
                    if namesFrame then
                        local playerFrame = namesFrame:FindFirstChild(p.Name .. "PlayerFrame")
                        if playerFrame then
                            local nLabel = playerFrame:FindFirstChild("NameLabel")
                            local lLabel = playerFrame:FindFirstChild("LevelLabel")
                            if nLabel then origName = nLabel.Text end
                            if lLabel then origLevel = lLabel.Text end
                        end
                    end
                    othersOriginalData[p.Name] = { Name = origName, Level = origLevel, DisplayName = p.DisplayName }
                end
                
                spoofedOthers[p.Name] = {
                    spoofName = targetFakeName, 
                    spoofLevel = targetFakeLevel, 
                    spoofIcon = targetFakeIcon
                }
                
                SendNotification("Applied fake data to " .. p.Name, 3)
                
                if spoofOthersEnabled then
                    updateTrackers()
                end
            end
        else
            SendNotification("Select a valid player first!", 3)
        end
    end)
    
    Library:CreateButton(Page, "Reset Selected Player", function()
        if targetOrigName ~= "Select Player" then
            restoreOtherPlayer(targetOrigName)
            SendNotification("Restored " .. targetOrigName, 3)
        end
    end)
    
    Library:CreateButton(Page, "Clear All Spoofed Players", function()
        local keys = {}
        for name, _ in pairs(spoofedOthers) do table.insert(keys, name) end
        for _, name in ipairs(keys) do
            restoreOtherPlayer(name)
        end
        table.clear(spoofedOthers)
        SendNotification("All spoofed players restored.", 3)
    end)

    Library:CreateSection(Page, "Visual Environment", "Left")
    Library:CreateToggle(Page, "Hide Leaves (Only Homestead)", false, function(state) 
        if state then
            local function isGreen(part)
                local c = part.Color
                return (c.G > c.R * 1.1) and (c.G > c.B * 1.1)
            end
            local function cleanPart(part)
                if not part:IsA("BasePart") then return end
                if part.Transparency == 1 then return end
                if part.Name == "HumanoidRootPart" then return end
                if not part.CanCollide then
                    local mat = part.Material
                    local name = part.Name:lower()
                    if name:find("leaf") or name:find("bush") or name:find("grass") or name:find("tree") or mat == Enum.Material.Grass or mat == Enum.Material.LeafyGrass or isGreen(part) then
                        if not (part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")) then
                             if not hiddenParts[part] then
                                hiddenParts[part] = part.Transparency 
                                part.Transparency = 1
                            end
                        end
                    end
                end
            end
            for _, v in pairs(workspace:GetDescendants()) do cleanPart(v) end
            HideLeavesConnection = workspace.DescendantAdded:Connect(cleanPart)
        else
            if HideLeavesConnection then HideLeavesConnection:Disconnect() end
            for part, originalTrans in pairs(hiddenParts) do
                if part and part.Parent then part.Transparency = originalTrans end
            end
            table.clear(hiddenParts)
        end
    end)

    Library:CreateToggle(Page, "Gray characters", false, function(state) 
        if state then
            local function setupCharacter(character)
                local player = Players:GetPlayerFromCharacter(character)
                if player and not player:HasAppearanceLoaded() then
                    player.CharacterAppearanceLoaded:Wait()
                end
                task.wait(0.1)
                if not character or not character.Parent then return end
                makeGray(character)
                
                local c1 = character.DescendantAdded:Connect(function(obj)
                    task.wait()
                    if obj and obj.Parent then
                        if obj:FindFirstAncestorWhichIsA("Tool") then return end
                        if obj:IsA("BasePart") then
                            if not grayBackups[character].parts[obj] then
                                grayBackups[character].parts[obj] = { Color = obj.Color, Material = obj.Material }
                            end
                            obj.Color = Color3.fromRGB(150, 150, 150)
                            obj.Material = Enum.Material.SmoothPlastic
                            if obj:IsA("MeshPart") then
                                if not grayBackups[character].meshes[obj] then
                                    grayBackups[character].meshes[obj] = obj.TextureID
                                end
                                obj.TextureID = ""
                            end
                        elseif obj:IsA("SpecialMesh") then
                            if not grayBackups[character].meshes[obj] then
                                grayBackups[character].meshes[obj] = obj.TextureId
                            end
                            obj.TextureId = ""
                        elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") or (obj:IsA("Decal") and obj.Name ~= "face") then
                            table.insert(grayBackups[character].clothes, {obj = obj, parent = obj.Parent})
                            obj.Parent = nil
                        end
                    end
                end)
                table.insert(grayConns, c1)
            end

            local function onPlayerAdded(player)
                if player == LocalPlayer then return end
                if player.Character then task.spawn(setupCharacter, player.Character) end
                local c2 = player.CharacterAdded:Connect(setupCharacter)
                table.insert(grayConns, c2)
            end

            for _, player in ipairs(Players:GetPlayers()) do
                onPlayerAdded(player)
            end
            local c3 = Players.PlayerAdded:Connect(onPlayerAdded)
            table.insert(grayConns, c3)
        else
            for _, c in ipairs(grayConns) do if c then c:Disconnect() end end
            table.clear(grayConns)
            
            for char, _ in pairs(grayBackups) do
                restoreGray(char)
            end
        end
    end)

    if not getgenv().NexFloorbang then
        getgenv().NexFloorbang = loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/floorbang.lua"))()
    end
    Library:CreateToggle(Page, "Floorbang", false, function(state)
        getgenv().NexFloorbang.Toggle(state)
    end)

    local WallhopFolder = nil
    local WallhopConn = nil

    local function applyWallhopESP(part)
        if part.ClassName == "Part" or part.ClassName == "TrussPart" then
            if part.ClassName == "Part" and part.Shape ~= Enum.PartType.Block then return end
            if part.Transparency > 0.8 or not part.CanCollide then return end
            if part:FindFirstChildWhichIsA("DataModelMesh") then return end
            if part.Size.Y <= 2 then return end

            local ancestorModel = part:FindFirstAncestorOfClass("Model")
            if ancestorModel and ancestorModel:FindFirstChildOfClass("Humanoid") then return end

            if WallhopFolder and not part:FindFirstChild("WallhopSelectionBox") then
                local box = Instance.new("SelectionBox")
                box.Name = "WallhopSelectionBox"
                box.Adornee = part
                box.Color3 = Color3.fromRGB(255, 255, 255)
                box.LineThickness = 0.03
                box.SurfaceTransparency = 1
                box.Parent = WallhopFolder
            end
        end
    end

    Library:CreateToggle(Page, "Wallhop Lines", false, function(state)
        if state then
            if not WallhopFolder then
                WallhopFolder = Instance.new("Folder")
                WallhopFolder.Name = "WallhopESPFolder"
                local s = pcall(function() WallhopFolder.Parent = CoreGui end)
                if not s then WallhopFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
            end

            for _, part in ipairs(Workspace:GetDescendants()) do
                applyWallhopESP(part)
            end

            WallhopConn = Workspace.DescendantAdded:Connect(function(part)
                task.defer(function()
                    if WallhopFolder then applyWallhopESP(part) end
                end)
            end)
        else
            if WallhopConn then WallhopConn:Disconnect() WallhopConn = nil end
            if WallhopFolder then WallhopFolder:Destroy() WallhopFolder = nil end
        end
    end)

    Library:CreateSection(Page, "Spoof Settings", "Right")
    Library:CreateToggle(Page, "Enable Others Spoofing", false, function(state)
        spoofOthersEnabled = state
        if state then
            updateTrackers()
        else
            for origNameKey, _ in pairs(spoofedOthers) do
                local backup = othersOriginalData[origNameKey]
                local p = Players:FindFirstChild(origNameKey)
                if p and p.Character and backup then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum.DisplayName = backup.DisplayName end) end
                end
                
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local namesFrame = playerGui and playerGui:FindFirstChild("PlayerNamesFrame", true)
                if namesFrame then
                    local playerFrame = namesFrame:FindFirstChild(origNameKey .. "PlayerFrame")
                    if playerFrame then
                        local iconLabel = playerFrame:FindFirstChild("IconLabel")
                        local nameLabel = playerFrame:FindFirstChild("NameLabel")
                        local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                        
                        if iconLabel then
                            iconLabel.ImageTransparency = 0
                            local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                            if fakeIcon then fakeIcon.Visible = false end
                        end
                        if nameLabel and backup then nameLabel.Text = backup.Name end
                        if levelLabel and backup then levelLabel.Text = backup.Level end
                    end
                end
            end
            updateTrackers()
        end
    end)

    Library:CreatePlayerDropdown(Page, "Target Player", "Select Player", function(val) 
        targetOrigName = val 
    end)

    Library:CreateInput(Page, "Target Fake Name", "Fake Name", function(val) 
        targetFakeName = val 
    end)
    
    Library:CreateInput(Page, "Target Fake Level", "100", function(val) 
        targetFakeLevel = tonumber(val) or 100 
    end)
    
    Library:CreateDropdown(Page, "Target Fake Icon", {"VIP", "QA", "CON", "Mod", "Dev", "Manager", "MrWindy", "Nenhum"}, "VIP", function(val) 
        targetFakeIcon = meusIcones[val] or "" 
    end)

    Library:CreateSection(Page, "Visual Name/Level", "Right")
    Library:CreateToggle(Page, "Enable Visuals", false, function(state) 
        spoofVisualsEnabled = state
        if state then
            updateTrackers()
        else
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum.DisplayName = originalDisplayName end) end
                end
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if not playerGui then return end
                local namesFrame = playerGui:FindFirstChild("PlayerNamesFrame", true)
                if namesFrame then
                    local playerFrame = namesFrame:FindFirstChild(LocalPlayer.Name .. "PlayerFrame")
                    if playerFrame then
                        local levelLabel = playerFrame:FindFirstChild("LevelLabel")
                        local nameLabel  = playerFrame:FindFirstChild("NameLabel")
                        local iconLabel  = playerFrame:FindFirstChild("IconLabel")
                        if levelLabel then levelLabel.Text = tostring(originalLevel) end
                        if nameLabel then nameLabel.Text = originalDisplayName end
                        if iconLabel then 
                            iconLabel.ImageTransparency = 0
                            local fakeIcon = iconLabel:FindFirstChild("IconeFakeCorrigido")
                            if fakeIcon then fakeIcon.Visible = false end
                        end
                        playerFrame.LayoutOrder = -tonumber(originalLevel)
                    end
                end
            end)
            updateTrackers()
        end
    end)
    Library:CreateInput(Page, "Fake Name", LocalPlayer.Name, function(val) 
        spoofName = val 
        if spoofVisualsEnabled then updateTrackers() end
    end)
    Library:CreateInput(Page, "Fake Level", "67", function(val) 
        spoofLevel = tonumber(val) or 100 
    end)
    Library:CreateDropdown(Page, "Select Icon", {"VIP", "QA", "CON", "Mod", "Dev", "Manager", "MrWindy", "Nenhum"}, "VIP", function(val) 
        spoofIconId = meusIcones[val] or "" 
    end)
end
