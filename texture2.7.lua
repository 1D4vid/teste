local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
	repeat task.wait() until Players.LocalPlayer
	LocalPlayer = Players.LocalPlayer
end

local viewport
local s, r = pcall(function() return gethui() end)
if s and r then 
    viewport = r 
else
    s, r = pcall(function() return getgenv().gethui() end)
    if s and r then 
        viewport = r 
    else
        s, r = pcall(function() return game:GetService("CoreGui") end)
        if s and r then
            viewport = r
        else
            viewport = LocalPlayer:WaitForChild("PlayerGui")
        end
    end
end

pcall(function()
	if LocalPlayer.PlayerGui:FindFirstChild("NexVoidHub") then LocalPlayer.PlayerGui.NexVoidHub:Destroy() end
	if viewport:FindFirstChild("NexVoidHub") then viewport.NexVoidHub:Destroy() end
end)

local function SendNotification(text, duration)
	pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "NexVoidHub", Text = text, Duration = duration or 3}) end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexVoidHub"
ScreenGui.Parent = viewport
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 10000 
ScreenGui.Enabled = false 

local Theme = {
	FrameColor = Color3.fromRGB(12, 12, 12),
	ContentColor = Color3.fromRGB(20, 20, 20),
	ItemColor = Color3.fromRGB(30, 30, 30),
	ItemStroke = Color3.fromRGB(60, 60, 60),
	SwitchOff = Color3.fromRGB(40, 40, 40), 
	Accent = Color3.fromRGB(240, 240, 240),
    AccentDark = Color3.fromRGB(160, 160, 160),
	Text = Color3.fromRGB(255, 255, 255), 
	TextDark = Color3.fromRGB(150, 150, 150),
	Font = Enum.Font.GothamBold,
	CloseRed = Color3.fromRGB(100, 100, 100)
}

-- Custom Cursor UI Logic
local CurrentCursorSize = 24
local PCCursorActive = false
local MobileCrosshair = Instance.new("ImageLabel")
MobileCrosshair.Name = "MobileCrosshair"
MobileCrosshair.Size = UDim2.new(0, CurrentCursorSize, 0, CurrentCursorSize)
MobileCrosshair.AnchorPoint = Vector2.new(0.5, 0.5)
MobileCrosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
MobileCrosshair.BackgroundTransparency = 1
MobileCrosshair.Visible = false
MobileCrosshair.ZIndex = 99
MobileCrosshair.Parent = ScreenGui 

local PCSoftwareCursor = Instance.new("ImageLabel")
PCSoftwareCursor.Name = "PCCursor"
PCSoftwareCursor.Size = UDim2.new(0, CurrentCursorSize, 0, CurrentCursorSize)
PCSoftwareCursor.AnchorPoint = Vector2.new(0.5, 0.5)
PCSoftwareCursor.BackgroundTransparency = 1
PCSoftwareCursor.Visible = false
PCSoftwareCursor.ZIndex = 10000
PCSoftwareCursor.Parent = ScreenGui

local function UpdateCursorSizes(val) 
    CurrentCursorSize = val
    MobileCrosshair.Size = UDim2.new(0, val, 0, val)
    PCSoftwareCursor.Size = UDim2.new(0, val, 0, val) 
end

local function SetPCCursorActive(val)
    PCCursorActive = val
end

RunService.RenderStepped:Connect(function() 
    if PCCursorActive then 
        UserInputService.MouseIconEnabled = false
        local mousePos = UserInputService:GetMouseLocation()
        PCSoftwareCursor.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y) 
    else 
        if UserInputService.MouseIconEnabled == false and not PCCursorActive then 
            UserInputService.MouseIconEnabled = true 
        end 
    end 
end)

local function ApplyGradient(instance, color1, color2, rotation)
    local gradient = instance:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, color1), ColorSequenceKeypoint.new(1.00, color2)}
    gradient.Rotation = rotation or 45
    gradient.Parent = instance
    return gradient
end

local AnimatedTextGradients = {}
local function ApplyAnimatedTextGradient(instance)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(120, 120, 120)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(170, 170, 170)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(170, 170, 170)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(120, 120, 120))
    }
    gradient.Rotation = 20
    gradient.Parent = instance
    table.insert(AnimatedTextGradients, gradient)
    return gradient
end

RunService.RenderStepped:Connect(function()
    local time = tick() * 0.6 
    local offset = (time % 2) - 1 
    for _, grad in ipairs(AnimatedTextGradients) do
        if grad.Parent then
            grad.Offset = Vector2.new(offset, 0)
        end
    end
end)

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local ConfigFolder = "NexVoidConfigs"
local DefaultTrackerFile = ConfigFolder .. "/default_config.txt"
local UserConfigs = { ToggleKey = "K" }

pcall(function() if makefolder and not isfolder(ConfigFolder) then makefolder(ConfigFolder) end end)

local function GetDefaultConfigName()
    local def = "config_1"
    pcall(function() if isfile and isfile(DefaultTrackerFile) then def = readfile(DefaultTrackerFile) end end)
    return def
end

local CurrentConfigName = GetDefaultConfigName()

local function LoadConfigs(configName)
    local fileToLoad = ConfigFolder .. "/" .. configName .. ".json"
	pcall(function()
		if isfile and isfile(fileToLoad) and readfile then
			local content = readfile(fileToLoad)
            if content then
                local decoded = HttpService:JSONDecode(content)
                if type(decoded) == "table" then
                    for k, v in pairs(decoded) do UserConfigs[k] = v end
                end
            end
		end
	end)
end
LoadConfigs(CurrentConfigName)

local CurrentKey = Enum.KeyCode[UserConfigs.ToggleKey] or Enum.KeyCode.K

local function SaveConfigs(configName)
	UserConfigs.ToggleKey = CurrentKey.Name
	pcall(function()
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
		if writefile then writefile(ConfigFolder .. "/" .. configName .. ".json", HttpService:JSONEncode(UserConfigs)) end
	end)
end

local function SetDefaultConfig(configName)
    pcall(function()
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        if writefile then writefile(DefaultTrackerFile, configName) end
    end)
end

local function ResetAllConfigs()
    pcall(function() if delfolder and isfolder(ConfigFolder) then delfolder(ConfigFolder) end end)
    UserConfigs = { ToggleKey = "K" }
    CurrentKey = Enum.KeyCode.K
end

local Config = {
	MainSize = isMobile and UDim2.new(0, 520, 0, 365) or UDim2.new(0, 600, 0, 420),
	SidebarWidth = isMobile and 130 or 150,
	FooterHeight = 18, 
	BtnHeight = isMobile and 24 or 28, 
	ListPadding = UDim.new(0, 2), 
	FontSize = isMobile and 10 or 12,
	IconSize = isMobile and 13 or 16
}

local ContentConfig = {
	ItemHeightNew = 30,
    ItemHeightOld = 35,
	PlayerCardHeight = 45,
	ItemPadding = UDim.new(0, 4)
}

local function MakeDraggable(triggerObject, frameObject)
    local dragging, dragInput, dragStart, startPos
    
    triggerObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frameObject.Position
        end
    end)
    
    triggerObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frameObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = Config.MainSize
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Theme.FrameColor 
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.ClipsDescendants = true
MainFrame.Visible = false 
MainFrame.Parent = ScreenGui

local FirstPersonFix = Instance.new("TextButton")
FirstPersonFix.Name = "FirstPersonFix"
FirstPersonFix.Size = UDim2.new(1, 0, 1, 0)
FirstPersonFix.BackgroundTransparency = 1
FirstPersonFix.ZIndex = -99
FirstPersonFix.Text = ""
FirstPersonFix.Modal = true
FirstPersonFix.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2
ApplyGradient(MainStroke, Theme.Accent, Color3.fromRGB(20,20,20), -45)

local AnimeBg = Instance.new("ImageLabel")
AnimeBg.Name = "AnimeBackground"
AnimeBg.Size = UDim2.new(1, 0, 1, 0)
AnimeBg.Image = "rbxassetid://77247981769460"
AnimeBg.ScaleType = Enum.ScaleType.Crop
AnimeBg.BackgroundTransparency = 1
AnimeBg.ZIndex = 1
AnimeBg.Parent = MainFrame

local DarkOverlay = Instance.new("Frame")
DarkOverlay.Name = "DarkOverlay"
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.BackgroundColor3 = Color3.new(0,0,0)
DarkOverlay.BackgroundTransparency = 0.65 
DarkOverlay.ZIndex = 2
DarkOverlay.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.new(0,0,0)
TopBar.BackgroundTransparency = 0.5
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 3
TopBar.Parent = MainFrame
MakeDraggable(TopBar, MainFrame)

local TopDiv = Instance.new("Frame")
TopDiv.Size = UDim2.new(1,0,0,1)
TopDiv.Position = UDim2.new(0,0,1,0)
TopDiv.BorderSizePixel=0
TopDiv.Parent = TopBar
ApplyGradient(TopDiv, Color3.new(0,0,0), Theme.Accent, 0) 

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Text = "Nex<font color='rgb(150,150,150)'>Void UI Base</font>"
TitleLabel.RichText = true
TitleLabel.Size = UDim2.new(0, 180, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Theme.Font
TitleLabel.TextSize = isMobile and 14 or 16
TitleLabel.TextColor3 = Theme.Text
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Position = UDim2.new(0, 45, 0, 0)
TitleLabel.ZIndex = 4
TitleLabel.Parent = TopBar

local OpenButton = Instance.new("ImageButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 45, 0, 45)
OpenButton.AnchorPoint = Vector2.new(0, 0)
OpenButton.Position = UDim2.new(0, 15, 0, 60)
OpenButton.BackgroundColor3 = Theme.FrameColor
OpenButton.Image = "rbxassetid://138188957887846"
OpenButton.Visible = false
OpenButton.Active = true
OpenButton.Draggable = true
OpenButton.Parent = ScreenGui
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 4)
local OBS = Instance.new("UIStroke")
OBS.Color = Theme.Accent
OBS.Thickness = 1.5
OBS.Parent = OpenButton
ApplyGradient(OBS, Theme.Accent, Color3.fromRGB(50,50,50), 45)
MakeDraggable(OpenButton, OpenButton)

local function createTopBtn(name, icon, offsetOrder, isImage)
	local Btn
	if isImage then
		Btn = Instance.new("ImageButton")
        Btn.Image = "rbxassetid://" .. icon
        Btn.ScaleType = Enum.ScaleType.Fit
        Btn.ImageTransparency = 1
        local Inner = Instance.new("ImageLabel")
        Inner.Size = UDim2.new(0, 14, 0, 14)
        Inner.Position = UDim2.new(0.5, -7, 0.5, -7)
        Inner.BackgroundTransparency = 1
        Inner.Image = "rbxassetid://" .. icon
        Inner.ImageColor3 = Theme.TextDark
        Inner.ScaleType = Enum.ScaleType.Fit
        Inner.ZIndex = 4
        Inner.Parent = Btn
        Btn.MouseEnter:Connect(function() Inner.ImageColor3 = Theme.Accent end)
        Btn.MouseLeave:Connect(function() Inner.ImageColor3 = Theme.TextDark end)
	else
		Btn = Instance.new("TextButton")
        Btn.Text = icon
        Btn.Font = Enum.Font.GothamBlack
        Btn.TextSize = 14
        Btn.TextColor3 = Theme.TextDark
        if icon == "-" then
            Btn.Text = ""
            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(0, 10, 0, 2)
            Line.Position = UDim2.new(0.5, -5, 0.5, 0)
            Line.BackgroundColor3 = Theme.TextDark
            Line.BorderSizePixel = 0
            Line.ZIndex = 4
            Line.Parent = Btn
            Btn.MouseEnter:Connect(function() Line.BackgroundColor3 = Theme.Accent end)
            Btn.MouseLeave:Connect(function() Line.BackgroundColor3 = Theme.TextDark end)
        elseif name == "Language" then
            Btn.MouseEnter:Connect(function() Btn.TextColor3 = Theme.Accent end)
            Btn.MouseLeave:Connect(function() Btn.TextColor3 = Theme.TextDark end)
        else
            Btn.MouseEnter:Connect(function() Btn.TextColor3 = Theme.CloseRed end)
            Btn.MouseLeave:Connect(function() Btn.TextColor3 = Theme.TextDark end)
        end
	end
	Btn.Name = name
    Btn.Parent = TopBar
    Btn.BackgroundTransparency = 1
    Btn.ZIndex = 4
    Btn.Position = UDim2.new(1, -(35 * offsetOrder), 0, 0)
    Btn.Size = UDim2.new(0, 35, 1, 0)
    return Btn
end

local CloseBtn = createTopBtn("Close", "X", 1, false)
local MinimizeBtn = createTopBtn("Minimize", "-", 2, false)
local InfoBtn = createTopBtn("Info", "5832745500", 3, true)
local LangBtn = createTopBtn("Language", "EN", 4, false)

local SearchContainer = Instance.new("Frame")
SearchContainer.Name = "SearchContainer"
SearchContainer.Size = UDim2.new(0, isMobile and 90 or 110, 0, 24) 
SearchContainer.Position = UDim2.new(1, isMobile and -140 or -155, 0.5, 0)
SearchContainer.AnchorPoint = Vector2.new(1, 0.5)
SearchContainer.BackgroundColor3 = Color3.new(0,0,0)
SearchContainer.BackgroundTransparency = 0.45
SearchContainer.BorderSizePixel = 0
SearchContainer.ClipsDescendants = true
SearchContainer.ZIndex = 4
SearchContainer.Parent = TopBar
Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 4)
local SearchStroke = Instance.new("UIStroke", SearchContainer)
SearchStroke.Color = Color3.fromRGB(40, 40, 40)

local SearchIcon = Instance.new("ImageLabel")
SearchIcon.Size = UDim2.new(0, 12, 0, 12)
SearchIcon.Position = UDim2.new(0, 8, 0.5, -6)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Image = "rbxassetid://104986431790017"
SearchIcon.ImageColor3 = Theme.TextDark
SearchIcon.ZIndex = 5
SearchIcon.Parent = SearchContainer

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -26, 1, 0)
SearchBox.Position = UDim2.new(0, 24, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search..."
SearchBox.TextColor3 = Theme.Text
SearchBox.PlaceholderColor3 = Theme.TextDark
SearchBox.Font = Theme.Font
SearchBox.TextSize = 10
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 5
SearchBox.Parent = SearchContainer

local CenterContainer = Instance.new("Frame")
CenterContainer.Name = "CenterContainer"
CenterContainer.Size = UDim2.new(1, 0, 1, -(40 + Config.FooterHeight))
CenterContainer.Position = UDim2.new(0, 0, 0, 40)
CenterContainer.BackgroundTransparency = 1
CenterContainer.ZIndex = 3
CenterContainer.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, Config.SidebarWidth, 1, 0)
Sidebar.BackgroundColor3 = Color3.new(0,0,0)
Sidebar.BackgroundTransparency = 0.6
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
Sidebar.Parent = CenterContainer

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = Config.ListPadding
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Parent = Sidebar
local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 5)
SidebarPadding.PaddingBottom = UDim.new(0, 5)
SidebarPadding.Parent = Sidebar 

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -Config.SidebarWidth, 1, 0)
ContentArea.Position = UDim2.new(0, Config.SidebarWidth, 0, 0)
ContentArea.BackgroundColor3 = Color3.new(0,0,0)
ContentArea.BackgroundTransparency = 0.7
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 3
ContentArea.Parent = CenterContainer 

local BottomBar = Instance.new("Frame")
BottomBar.Size = UDim2.new(1, 0, 0, Config.FooterHeight)
BottomBar.Position = UDim2.new(0, 0, 1, -Config.FooterHeight)
BottomBar.BackgroundColor3 = Color3.new(0,0,0)
BottomBar.BackgroundTransparency = 0.5
BottomBar.BorderSizePixel = 0
BottomBar.ZIndex = 5
BottomBar.Parent = MainFrame

local DiscordText = Instance.new("TextLabel")
DiscordText.RichText = true
DiscordText.Text = "Discord: <font color='rgb(200,200,200)'>.gg/uxPjBvxPY6</font>"
DiscordText.Size = UDim2.new(1, -10, 1, 0)
DiscordText.Position = UDim2.new(0, 10, 0, 0)
DiscordText.BackgroundTransparency = 1
DiscordText.TextColor3 = Theme.Text
DiscordText.Font = Theme.Font
DiscordText.TextSize = 10
DiscordText.TextXAlignment = Enum.TextXAlignment.Left
DiscordText.ZIndex = 6
DiscordText.Parent = BottomBar

local StatusText = Instance.new("TextLabel")
StatusText.RichText = true
local modeText = isMobile and "Mobile" or "PC"
StatusText.Text = "NexVoid UI Base <font color='rgb(200,200,200)'>" .. modeText .. "</font> | Framework Only."
StatusText.Size = UDim2.new(1, -10, 1, 0)
StatusText.Position = UDim2.new(0, 0, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Theme.Text
StatusText.Font = Theme.Font
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Right
StatusText.ZIndex = 6
StatusText.Parent = BottomBar

local ModalOverlay = Instance.new("Frame")
ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
ModalOverlay.BackgroundColor3 = Color3.new(0,0,0)
ModalOverlay.BackgroundTransparency = 0.5
ModalOverlay.Visible = false
ModalOverlay.ZIndex = 10
ModalOverlay.Parent = MainFrame

local function createModalBox(height)
    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 300, 0, height)
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.Position = UDim2.new(0.5, 0, 0.5, 0)
    Box.BackgroundColor3 = Color3.new(0,0,0)
    Box.BackgroundTransparency = 0.15
    Box.BorderSizePixel = 0
    Box.ZIndex = 11
    Box.Visible = false
    Box.Parent = ModalOverlay
    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = Color3.fromRGB(40, 40, 40)
    BoxStroke.Parent = Box
    local TopLine = Instance.new("Frame")
    TopLine.Size = UDim2.new(1, 0, 0, 2)
    TopLine.BackgroundColor3 = Theme.Accent
    TopLine.BorderSizePixel = 0
    TopLine.ZIndex = 12
    TopLine.Parent = Box
    ApplyGradient(TopLine, Theme.Accent, Theme.AccentDark, 0)
    return Box
end

local ExitBoxContainer = Instance.new("Frame")
ExitBoxContainer.Size = UDim2.new(0, 310, 0, 165)
ExitBoxContainer.AnchorPoint = Vector2.new(0.5, 0.5)
ExitBoxContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
ExitBoxContainer.BackgroundColor3 = Color3.new(0,0,0)
ExitBoxContainer.BackgroundTransparency = 0.15
ExitBoxContainer.BorderSizePixel = 0
ExitBoxContainer.ZIndex = 11
ExitBoxContainer.Visible = false
ExitBoxContainer.Parent = ModalOverlay
Instance.new("UICorner", ExitBoxContainer).CornerRadius = UDim.new(0, 10)
local ExitBoxStroke = Instance.new("UIStroke")
ExitBoxStroke.Color = Color3.fromRGB(40, 40, 40)
ExitBoxStroke.Thickness = 1.5
ExitBoxStroke.Parent = ExitBoxContainer

local ExitTopGlow = Instance.new("Frame")
ExitTopGlow.Size = UDim2.new(1, 0, 0, 4)
ExitTopGlow.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
ExitTopGlow.BorderSizePixel = 0
ExitTopGlow.ZIndex = 12
ExitTopGlow.Parent = ExitBoxContainer
Instance.new("UICorner", ExitTopGlow).CornerRadius = UDim.new(0, 10)
local FixBottomCorners = Instance.new("Frame")
FixBottomCorners.Size = UDim2.new(1, 0, 0, 2)
FixBottomCorners.Position = UDim2.new(0, 0, 1, -2)
FixBottomCorners.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
FixBottomCorners.BorderSizePixel = 0
FixBottomCorners.ZIndex = 12
FixBottomCorners.Parent = ExitTopGlow
ApplyGradient(ExitTopGlow, Color3.fromRGB(255, 80, 80), Color3.fromRGB(150, 20, 20), 0)

local ExitTitleLabel = Instance.new("TextLabel")
ExitTitleLabel.Size = UDim2.new(1, 0, 0, 40)
ExitTitleLabel.Position = UDim2.new(0, 0, 0, 15)
ExitTitleLabel.BackgroundTransparency = 1
ExitTitleLabel.Text = "Exit NexVoid UI Base"
ExitTitleLabel:SetAttribute("OriginalText", "Exit NexVoid UI Base")
ExitTitleLabel.Font = Enum.Font.GothamBlack
ExitTitleLabel.TextSize = 18
ExitTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ExitTitleLabel.ZIndex = 12
ExitTitleLabel.Parent = ExitBoxContainer

local ExitDescLabel = Instance.new("TextLabel")
ExitDescLabel.Size = UDim2.new(1, -40, 0, 40)
ExitDescLabel.Position = UDim2.new(0, 20, 0, 50)
ExitDescLabel.BackgroundTransparency = 1
ExitDescLabel.Text = "Are you sure you want to close the script?"
ExitDescLabel:SetAttribute("OriginalText", "Are you sure you want to close the script?")
ExitDescLabel.Font = Enum.Font.Gotham
ExitDescLabel.TextSize = 12
ExitDescLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ExitDescLabel.TextWrapped = true
ExitDescLabel.ZIndex = 12
ExitDescLabel.Parent = ExitBoxContainer

local CancelExitBtn = Instance.new("TextButton")
CancelExitBtn.Size = UDim2.new(0.42, 0, 0, 36)
CancelExitBtn.Position = UDim2.new(0.06, 0, 0, 110)
CancelExitBtn.BackgroundColor3 = Color3.new(0,0,0)
CancelExitBtn.BackgroundTransparency = 0.45
CancelExitBtn.Text = "Cancel"
CancelExitBtn:SetAttribute("OriginalText", "Cancel")
CancelExitBtn.Font = Enum.Font.GothamBold
CancelExitBtn.TextSize = 13
CancelExitBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CancelExitBtn.ZIndex = 12
CancelExitBtn.Parent = ExitBoxContainer
Instance.new("UICorner", CancelExitBtn).CornerRadius = UDim.new(0, 6)
local CancelStroke = Instance.new("UIStroke")
CancelStroke.Color = Color3.fromRGB(40, 40, 40)
CancelStroke.Thickness = 1
CancelStroke.Parent = CancelExitBtn

local ConfirmExitBtn = Instance.new("TextButton")
ConfirmExitBtn.Size = UDim2.new(0.42, 0, 0, 36)
ConfirmExitBtn.Position = UDim2.new(0.52, 0, 0, 110)
ConfirmExitBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
ConfirmExitBtn.Text = "Yes, Exit"
ConfirmExitBtn:SetAttribute("OriginalText", "Yes, Exit")
ConfirmExitBtn.Font = Enum.Font.GothamBold
ConfirmExitBtn.TextSize = 13
ConfirmExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmExitBtn.ZIndex = 12
ConfirmExitBtn.Parent = ExitBoxContainer
Instance.new("UICorner", ConfirmExitBtn).CornerRadius = UDim.new(0, 6)
local ConfirmStroke = Instance.new("UIStroke")
ConfirmStroke.Color = Color3.fromRGB(100, 20, 20)
ConfirmStroke.Thickness = 1
ConfirmStroke.Parent = ConfirmExitBtn
ApplyGradient(ConfirmExitBtn, Color3.fromRGB(255, 60, 60), Color3.fromRGB(180, 20, 20), 90)

CancelExitBtn.MouseEnter:Connect(function()
    TweenService:Create(CancelExitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
    TweenService:Create(CancelStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 100, 100)}):Play()
end)
CancelExitBtn.MouseLeave:Connect(function()
    TweenService:Create(CancelExitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0,0,0)}):Play()
    TweenService:Create(CancelStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40)}):Play()
end)

ConfirmExitBtn.MouseEnter:Connect(function()
    TweenService:Create(ConfirmExitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}):Play()
end)
ConfirmExitBtn.MouseLeave:Connect(function()
    TweenService:Create(ConfirmExitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 40, 40)}):Play()
end)

CancelExitBtn.MouseButton1Click:Connect(function() 
    TweenService:Create(ExitBoxContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.delay(0.2, function()
        ModalOverlay.Visible = false
        ExitBoxContainer.Visible = false 
    end)
end)
ConfirmExitBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local InfoBox = createModalBox(350)
local InfoTitle = Instance.new("TextLabel")
InfoTitle.Parent = InfoBox
InfoTitle.Text = "UI INFO"
InfoTitle:SetAttribute("OriginalText", "UI INFO")
InfoTitle.Size = UDim2.new(1,0,0,35)
InfoTitle.TextColor3 = Theme.Accent
InfoTitle.BackgroundTransparency = 1
InfoTitle.Font = Theme.Font
InfoTitle.TextSize = 14

local CloseInfoBtn = Instance.new("TextButton")
CloseInfoBtn.Parent = InfoBox
CloseInfoBtn.Text = "Close"
CloseInfoBtn:SetAttribute("OriginalText", "Close")
CloseInfoBtn.Size = UDim2.new(0, 260, 0, 30)
CloseInfoBtn.Position = UDim2.new(0, 20, 1, -40)
CloseInfoBtn.BackgroundColor3 = Color3.new(0,0,0)
CloseInfoBtn.BackgroundTransparency = 0.45
CloseInfoBtn.TextColor3 = Theme.TextDark
Instance.new("UICorner", CloseInfoBtn).CornerRadius = UDim.new(0, 4)
local ciStr = Instance.new("UIStroke", CloseInfoBtn)
ciStr.Color = Color3.fromRGB(40,40,40)

local InfoScroll = Instance.new("ScrollingFrame", InfoBox)
InfoScroll.Size = UDim2.new(1, 0, 1, -85)
InfoScroll.Position = UDim2.new(0, 0, 0, 35)
InfoScroll.BackgroundTransparency = 1
InfoScroll.BorderSizePixel = 0
InfoScroll.ScrollBarThickness = 2
InfoScroll.ScrollBarImageColor3 = Theme.Accent
local InfoLayout = Instance.new("UIListLayout", InfoScroll)
InfoLayout.Padding = UDim.new(0, 10)
InfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

CloseBtn.MouseButton1Click:Connect(function() 
    ModalOverlay.Visible = true
    ExitBoxContainer.Size = UDim2.new(0, 0, 0, 0)
    ExitBoxContainer.Visible = true
    TweenService:Create(ExitBoxContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 310, 0, 165)}):Play()
    InfoBox.Visible = false 
end)

InfoBtn.MouseButton1Click:Connect(function() 
    ModalOverlay.Visible = true
    InfoBox.Visible = true
    ExitBoxContainer.Visible = false 
end)

CloseInfoBtn.MouseButton1Click:Connect(function() 
    ModalOverlay.Visible = false
    InfoBox.Visible = false 
end)

local currentLangIndex = 1
local langs = {"EN", "PT", "ES"}
LangBtn.MouseButton1Click:Connect(function()
    currentLangIndex = currentLangIndex + 1
    if currentLangIndex > #langs then currentLangIndex = 1 end
    LangBtn.Text = langs[currentLangIndex]
    SendNotification("Language Feature is disabled in the UI Base", 2)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local text = SearchBox.Text:lower()
    for _, page in pairs(ContentArea:GetChildren()) do 
        if page:IsA("ScrollingFrame") then
            if not page:GetAttribute("OldStyle") then
                for _, col in pairs(page:GetChildren()) do
                    if col:IsA("Frame") and (col.Name == "LeftCol" or col.Name == "RightCol") then
                        for _, container in pairs(col:GetChildren()) do
                            if container:IsA("Frame") and container.Name:match("^CategoryBox_") then
                                local hasVisibleItem = false
                                for _, item in pairs(container:GetChildren()) do
                                    if item:IsA("Frame") or item:IsA("TextButton") then
                                        if item.Name == "HeaderContainer" then continue end
                                        local lbl = item:FindFirstChildWhichIsA("TextLabel") or (item:IsA("TextButton") and item) or nil
                                        local txt = (lbl and lbl.Text or ""):lower()
                                        if txt:find(text) then 
                                            item.Visible = true 
                                            hasVisibleItem = true
                                        else 
                                            if text ~= "" then item.Visible = false end 
                                        end
                                    end
                                end
                                if text ~= "" and not hasVisibleItem then
                                    container.Visible = false
                                else
                                    container.Visible = true
                                end
                            end
                        end
                    end
                end
            else
                for _, item in pairs(page:GetChildren()) do
                    if item:IsA("Frame") or item:IsA("TextButton") then
                        local lbl = item:FindFirstChildWhichIsA("TextLabel") or (item:IsA("TextButton") and item) or nil
                        local txt = (lbl and lbl.Text or ""):lower()
                        if txt:find(text) then item.Visible = true else if text ~= "" then item.Visible = false end end
                    end
                end
            end
        end 
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == CurrentKey then
		if MainFrame.Visible then 
            MainFrame.Visible = false
            OpenButton.Visible = false 
        else 
            MainFrame.Visible = true
            OpenButton.Visible = false 
        end
	end
end)
MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false
OpenButton.Visible = true end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = true
OpenButton.Visible = false end)

local Library = {}
Library.CurrentSections = {}
local tabs = {}

local function createSidebarButton(iconId, name, lazyLoadFunc, isOldStyle)
	local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
	Page.Size = UDim2.new(1, -20, 1, -10)
    Page.Position = UDim2.new(0, 10, 0, 5)
	Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.ScrollBarImageTransparency = 0 
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.Visible = false
    Page.Parent = ContentArea
    
    Page:SetAttribute("OldStyle", isOldStyle == true)
    
    if not isOldStyle then
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
    else
        local PL = Instance.new("UIListLayout")
        PL.Padding = ContentConfig.ItemPadding
        PL.SortOrder = Enum.SortOrder.LayoutOrder
        PL.Parent = Page
        local PP = Instance.new("UIPadding")
        PP.PaddingBottom = UDim.new(0, 10)
        PP.Parent = Page
    end
	
	local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, Config.BtnHeight)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = ""
    TabButton.Parent = Sidebar
	local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 3, 0.7, 0)
    Indicator.Position = UDim2.new(0, 0, 0.15, 0)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BackgroundTransparency = 1
    Indicator.BorderSizePixel = 0
    Indicator.Parent = TabButton
    ApplyGradient(Indicator, Theme.Accent, Theme.AccentDark, 90)
	
	local Icon = Instance.new("ImageLabel")
    Icon.Image = "rbxassetid://" .. iconId
    Icon.Size = UDim2.new(0, Config.IconSize, 0, Config.IconSize)
    Icon.Position = UDim2.new(0, 12, 0.5, -(Config.IconSize/2))
    Icon.BackgroundTransparency = 1
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Icon.ImageTransparency = 0.2 
    Icon.Parent = TabButton
	local Label = Instance.new("TextLabel")
    Label.Text = name
    Label:SetAttribute("OriginalText", name) 
    Label.Size = UDim2.new(0, 100, 1, 0)
    Label.Position = UDim2.new(0, 34, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Theme.Font
    Label.TextSize = Config.FontSize
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextTransparency = 0.2 
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TabButton
	
	ApplyAnimatedTextGradient(Label)

	TabButton.MouseButton1Click:Connect(function()
		for _, tab in pairs(tabs) do 
			tab.Page.Visible = false
			tab.Indicator.BackgroundTransparency = 1
			tab.Label.TextTransparency = 0.2
			tab.Icon.ImageTransparency = 0.2
		end
		Page.Visible = true
		Indicator.BackgroundTransparency = 0
		Label.TextTransparency = 0
		Icon.ImageTransparency = 0
	end)
	
	table.insert(tabs, {Page = Page, Indicator = Indicator, Label = Label, Icon = Icon})
	
	if lazyLoadFunc then
		task.spawn(function()
			local s, e = pcall(function() lazyLoadFunc(Page) end)
			if not s then warn("UI Framework Load Error for " .. name .. ": ", e) end
		end)
	end

	return Page
end

local function GetParentTarget(Page)
    if Page:GetAttribute("OldStyle") then
        return Page
    end
    if Library.CurrentSections[Page] then
        return Library.CurrentSections[Page]
    else
        return Page:FindFirstChild("LeftCol") or Page 
    end
end

-- ==========================================
-- CRIAÇÃO DOS ELEMENTOS 
-- ==========================================

function Library:CreateSection(Page, Text, ForceSide)
    local isOld = Page:GetAttribute("OldStyle")
    
    if isOld then
        local Section = Instance.new("Frame")
        Section.Size = UDim2.new(1, -2, 0, 25)
        Section.Position = UDim2.new(0, 1, 0, 0)
        Section.BackgroundTransparency = 1
        Section.Parent = Page
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = Text
        Label:SetAttribute("OriginalText", Text) 
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 13
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Section
        
        ApplyAnimatedTextGradient(Label)
        
        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(1, -(Label.TextBounds.X + 16), 0, 1)
        Line.Position = UDim2.new(0, Label.TextBounds.X + 8, 0.5, 0)
        Line.BackgroundColor3 = Theme.ItemStroke
        Line.BorderSizePixel = 0
        Line.Parent = Section
        ApplyGradient(Line, Theme.Accent, Color3.new(0,0,0), 0)

        Label:GetPropertyChangedSignal("TextBounds"):Connect(function()
            Line.Size = UDim2.new(1, -(Label.TextBounds.X + 16), 0, 1)
            Line.Position = UDim2.new(0, Label.TextBounds.X + 8, 0.5, 0)
        end)
    else
        local targetCol
        if ForceSide == "Left" then
            targetCol = Page.LeftCol
        elseif ForceSide == "Right" then
            targetCol = Page.RightCol
        else
            Page.SectionCount.Value = Page.SectionCount.Value + 1
            targetCol = (Page.SectionCount.Value % 2 == 1) and Page.LeftCol or Page.RightCol
        end

        local SectionBox = Instance.new("Frame")
        SectionBox.Name = "CategoryBox_" .. Text
        SectionBox.Size = UDim2.new(1, -2, 0, 0)
        SectionBox.Position = UDim2.new(0, 1, 0, 0)
        SectionBox.AutomaticSize = Enum.AutomaticSize.Y
        SectionBox.BackgroundColor3 = Color3.new(0, 0, 0) 
        SectionBox.BackgroundTransparency = 0.45 
        SectionBox.BorderSizePixel = 0
        SectionBox.Parent = targetCol
        
        Instance.new("UICorner", SectionBox).CornerRadius = UDim.new(0, 6)
        
        local str = Instance.new("UIStroke")
        str.Color = Color3.fromRGB(40, 40, 40) 
        str.Thickness = 1
        str.Parent = SectionBox
        
        local SectionLayout = Instance.new("UIListLayout")
        SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        SectionLayout.Padding = ContentConfig.ItemPadding
        SectionLayout.Parent = SectionBox
        
        local SectionPadding = Instance.new("UIPadding")
        SectionPadding.PaddingTop = UDim.new(0, 8)
        SectionPadding.PaddingBottom = UDim.new(0, 8)
        SectionPadding.PaddingLeft = UDim.new(0, 10)
        SectionPadding.PaddingRight = UDim.new(0, 10)
        SectionPadding.Parent = SectionBox

        local HeaderContainer = Instance.new("Frame")
        HeaderContainer.Name = "HeaderContainer"
        HeaderContainer.Size = UDim2.new(1, 0, 0, 20)
        HeaderContainer.BackgroundTransparency = 1
        HeaderContainer.Parent = SectionBox
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = Text
        Label:SetAttribute("OriginalText", Text) 
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 12
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = HeaderContainer
        
        Library.CurrentSections[Page] = SectionBox
    end
end

function Library:CreateButton(Page, Text, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or ContentConfig.ItemHeightNew
    
	local BtnFrame = Instance.new("TextButton")
    BtnFrame.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    BtnFrame.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    BtnFrame.Text = ""
    BtnFrame.Parent = targetParent
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local tConst = Instance.new("UITextSizeConstraint", Label)
    tConst.MinTextSize = 7
    Label.Parent = BtnFrame
    
    local str
    if isOld then
        BtnFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        BtnFrame.BackgroundTransparency = 0.45
        Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 6)
        str = Instance.new("UIStroke")
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        str.Parent = BtnFrame
        Label.Position = UDim2.new(0, 10, 0, 0)
        tConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
    else
        BtnFrame.BackgroundTransparency = 1 
        tConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
    end

	BtnFrame.MouseButton1Click:Connect(function() 
        pcall(Callback) 
    end)
    
    if not isOld then
        BtnFrame.MouseEnter:Connect(function() TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.Accent}):Play() end)
        BtnFrame.MouseLeave:Connect(function() TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play() end)
    end
end

function Library:CreateToggle(Page, Text, Default, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or ContentConfig.ItemHeightNew
    
	local Flag = Page.Name .. "_" .. Text
	local State = UserConfigs[Flag]
	if State == nil then State = Default or false end
	UserConfigs[Flag] = State

	local Tgl = Instance.new("TextButton")
    Tgl.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    Tgl.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Tgl.Text = ""
    Tgl.Parent = targetParent

	local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local tConst = Instance.new("UITextSizeConstraint", Label)
    tConst.MinTextSize = 7
    Label.Parent = Tgl
    
    local str
    if isOld then
        Tgl.BackgroundColor3 = Color3.new(0, 0, 0)
        Tgl.BackgroundTransparency = 0.45
        Instance.new("UICorner", Tgl).CornerRadius = UDim.new(0, 6)
        str = Instance.new("UIStroke")
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        str.Parent = Tgl
        Label.Position = UDim2.new(0, 12, 0, 0)
        tConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
    else
        Tgl.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 5, 0, 0)
        tConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
    end

    local bgWidth, bgHeight, cirSize = 30, 14, 12
    if isOld then bgWidth, bgHeight, cirSize = 34, 18, 14 end

	local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(0, bgWidth, 0, bgHeight)
    Bg.Position = isOld and UDim2.new(1, -46, 0.5, -9) or UDim2.new(1, -30, 0.5, -7)
    Bg.BackgroundColor3 = Theme.SwitchOff
    Bg.Parent = Tgl
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)
    local BgGrad = ApplyGradient(Bg, Theme.SwitchOff, Theme.SwitchOff, 90)
    
	local Cir = Instance.new("Frame")
    Cir.Size = UDim2.new(0, cirSize, 0, cirSize)
    Cir.Position = isOld and UDim2.new(0, 2, 0.5, -7) or UDim2.new(0, 1, 0.5, -6)
    Cir.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Cir.Parent = Bg
    Instance.new("UICorner", Cir).CornerRadius = UDim.new(1, 0)
	
    local function Upd(fireCallback)
        local onPos = isOld and UDim2.new(1, -16, 0.5, -7) or UDim2.new(1, -13, 0.5, -6)
        local offPos = isOld and UDim2.new(0, 2, 0.5, -7) or UDim2.new(0, 1, 0.5, -6)
        
		if State then 
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
            BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.AccentDark)}
            TweenService:Create(Cir, TweenInfo.new(0.2), {Position = onPos, BackgroundColor3 = Color3.new(0,0,0)}):Play()
            if not isOld then TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play() end
		else 
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SwitchOff}):Play()
            BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.SwitchOff), ColorSequenceKeypoint.new(1, Theme.SwitchOff)}
            TweenService:Create(Cir, TweenInfo.new(0.2), {Position = offPos, BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play() 
            if not isOld then TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play() end
        end
		if fireCallback then pcall(Callback, State) end
	end
	
	Tgl.MouseButton1Click:Connect(function() 
        State = not State
        UserConfigs[Flag] = State
        Upd(true) 
    end)
    
    if State then task.spawn(function() pcall(Callback, State) end) end
	Upd(false) 
    
    local function Set(val)
        State = val
        UserConfigs[Flag] = State
        Upd(true)
    end
    return {Set = Set}
end

function Library:CreateToggleKeybind(Page, Text, DefaultState, DefaultKey, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or ContentConfig.ItemHeightNew
    
    local FlagState = Page.Name .. "_" .. Text .. "_State"
    local FlagKey = Page.Name .. "_" .. Text .. "_Key"
    
    local State = UserConfigs[FlagState]
    if State == nil then State = DefaultState or false end
    UserConfigs[FlagState] = State
    
    local Key = UserConfigs[FlagKey]
    if Key == nil then Key = DefaultKey or "None" end
    UserConfigs[FlagKey] = Key

    local Tgl = Instance.new("TextButton")
    Tgl.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    Tgl.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Tgl.Text = ""
    Tgl.Parent = targetParent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -110, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local tConst = Instance.new("UITextSizeConstraint", Label)
    tConst.MinTextSize = 7
    Label.Parent = Tgl
    
    local str
    if isOld then
        Tgl.BackgroundColor3 = Color3.new(0, 0, 0)
        Tgl.BackgroundTransparency = 0.45
        Instance.new("UICorner", Tgl).CornerRadius = UDim.new(0, 6)
        str = Instance.new("UIStroke")
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        str.Parent = Tgl
        Label.Position = UDim2.new(0, 12, 0, 0)
        tConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
    else
        Tgl.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 5, 0, 0)
        tConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
    end

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Size = isOld and UDim2.new(0, 45, 0, 20) or UDim2.new(0, 32, 0, 16)
    KeyBtn.Position = isOld and UDim2.new(1, -100, 0.5, -10) or UDim2.new(1, -66, 0.5, -8)
    KeyBtn.BackgroundColor3 = Color3.new(0,0,0)
    KeyBtn.BackgroundTransparency = 0.45
    KeyBtn.Text = (Key == "None" and (isOld and "Set Key" or "Key") or Key)
    KeyBtn.TextColor3 = Theme.TextDark
    KeyBtn.Font = Enum.Font.Gotham
    KeyBtn.TextSize = 10
    KeyBtn.Parent = Tgl
    Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 4)
    local kbStr = Instance.new("UIStroke", KeyBtn)
    kbStr.Color = Color3.fromRGB(40, 40, 40)

    local ResetBtn = Instance.new("TextButton")
    ResetBtn.Size = isOld and UDim2.new(0, 40, 0, 20) or UDim2.new(0, 26, 0, 16)
    ResetBtn.Position = isOld and UDim2.new(1, -148, 0.5, -10) or UDim2.new(1, -96, 0.5, -8)
    ResetBtn.BackgroundColor3 = Color3.new(0,0,0)
    ResetBtn.BackgroundTransparency = 0.45
    ResetBtn.Text = isOld and "Reset" or "Del"
    ResetBtn.TextColor3 = Theme.CloseRed
    ResetBtn.Font = Enum.Font.Gotham
    ResetBtn.TextSize = 10
    ResetBtn.Parent = Tgl
    Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 4)
    local rbStr = Instance.new("UIStroke", ResetBtn)
    rbStr.Color = Color3.fromRGB(40, 40, 40)

    local bgWidth, bgHeight, cirSize = 30, 14, 12
    if isOld then bgWidth, bgHeight, cirSize = 34, 18, 14 end

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(0, bgWidth, 0, bgHeight)
    Bg.Position = isOld and UDim2.new(1, -46, 0.5, -9) or UDim2.new(1, -30, 0.5, -7)
    Bg.BackgroundColor3 = Theme.SwitchOff
    Bg.Parent = Tgl
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)
    local BgGrad = ApplyGradient(Bg, Theme.SwitchOff, Theme.SwitchOff, 90)
    
	local Cir = Instance.new("Frame")
    Cir.Size = UDim2.new(0, cirSize, 0, cirSize)
    Cir.Position = isOld and UDim2.new(0, 2, 0.5, -7) or UDim2.new(0, 1, 0.5, -6)
    Cir.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Cir.Parent = Bg
    Instance.new("UICorner", Cir).CornerRadius = UDim.new(1, 0)

    local function Upd(fireCallback)
        local onPos = isOld and UDim2.new(1, -16, 0.5, -7) or UDim2.new(1, -13, 0.5, -6)
        local offPos = isOld and UDim2.new(0, 2, 0.5, -7) or UDim2.new(0, 1, 0.5, -6)
        
        if State then 
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
            BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.AccentDark)}
            TweenService:Create(Cir, TweenInfo.new(0.2), {Position = onPos, BackgroundColor3 = Color3.new(0,0,0)}):Play()
            if not isOld then TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play() end
        else 
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SwitchOff}):Play()
            BgGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.SwitchOff), ColorSequenceKeypoint.new(1, Theme.SwitchOff)}
            TweenService:Create(Cir, TweenInfo.new(0.2), {Position = offPos, BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play() 
            if not isOld then TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play() end
        end
        if fireCallback then pcall(Callback, State) end
    end

    Tgl.MouseButton1Click:Connect(function()
        State = not State
        UserConfigs[FlagState] = State
        Upd(true)
    end)
    
    ResetBtn.MouseButton1Click:Connect(function()
        UserConfigs[FlagKey] = "None"
        KeyBtn.Text = isOld and "Set Key" or "Key"
    end)
    
    KeyBtn.MouseButton1Click:Connect(function()
        KeyBtn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                    UserConfigs[FlagKey] = "None"
                    KeyBtn.Text = isOld and "Set Key" or "Key"
                else
                    UserConfigs[FlagKey] = input.KeyCode.Name
                    KeyBtn.Text = input.KeyCode.Name
                end
                if conn then conn:Disconnect() end
            end
        end)
    end)
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp then
            local currentKey = UserConfigs[FlagKey]
            if currentKey and currentKey ~= "None" and input.KeyCode.Name == currentKey then
                State = not State
                UserConfigs[FlagState] = State
                Upd(true)
            end
        end
    end)

    if State then task.spawn(function() pcall(Callback, State) end) end
    Upd(false)
    
    local function Set(val)
        State = val
        UserConfigs[FlagState] = State
        Upd(true)
    end
    return {Set = Set}
end

function Library:CreateSlider(Page, Text, Min, Max, Default, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or (ContentConfig.ItemHeightNew + 5)
    
	local Flag = Page.Name .. "_" .. Text
	local currentVal = UserConfigs[Flag]
	if currentVal == nil then currentVal = Default end
	currentVal = math.clamp(currentVal, Min, Max)
	UserConfigs[Flag] = currentVal

	local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    Frame.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Frame.Parent = targetParent

	local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local lConst = Instance.new("UITextSizeConstraint", Label)
    lConst.MinTextSize = 7
    Label.Parent = Frame
    
	local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 40, 0, 20)
    ValueLabel.AnchorPoint = Vector2.new(1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(currentVal)
    ValueLabel.Font = Theme.Font
    ValueLabel.TextSize = 11
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Frame
    
    if isOld then
        Frame.BackgroundColor3 = Color3.new(0, 0, 0)
        Frame.BackgroundTransparency = 0.45
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
        local str = Instance.new("UIStroke", Frame)
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        
        Label.Size = UDim2.new(1, -45, 0, 20)
        Label.Position = UDim2.new(0, 10, 0, 2)
        lConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
        ValueLabel.Position = UDim2.new(1, -10, 0, 2)
        ValueLabel.TextColor3 = Theme.TextDark
    else
        Frame.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -45, 0, 20)
        Label.Position = UDim2.new(0, 5, 0, 2)
        lConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
        ValueLabel.Position = UDim2.new(1, -5, 0, 2)
        ValueLabel.TextColor3 = Theme.Text
    end

	local SliderBar = Instance.new("Frame")
    SliderBar.Size = isOld and UDim2.new(1, -20, 0, 8) or UDim2.new(1, -10, 0, 8)
    SliderBar.Position = isOld and UDim2.new(0, 10, 0, 25) or UDim2.new(0, 5, 0, 25)
    SliderBar.BackgroundColor3 = Theme.SwitchOff
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = Frame
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
    
	local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((currentVal - Min) / (Max - Min), 0, 1, 0)
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
	
	task.spawn(function() pcall(Callback, currentVal) end)

	local dragging = false
	local function Update(input)
		local pos = UDim2.new(math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1), 0, 1, 0)
        Fill.Size = pos
		local value = math.floor(Min + ((Max - Min) * pos.X.Scale))
		ValueLabel.Text = tostring(value)
		UserConfigs[Flag] = value
		pcall(Callback, value)
	end
	Trigger.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true
    Update(input) end end)
	UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            if dragging then dragging = false end
        end 
    end)
	UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Update(input) end end)

    local function Set(val)
        currentVal = math.clamp(val, Min, Max)
        local pos = (currentVal - Min) / (Max - Min)
        TweenService:Create(Fill, TweenInfo.new(0.2), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
        ValueLabel.Text = tostring(currentVal)
        UserConfigs[Flag] = currentVal
        pcall(Callback, currentVal)
    end
    return { Set = Set }
end

function Library:CreateInput(Page, Text, Default, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or ContentConfig.ItemHeightNew
    
	local Flag = Page.Name .. "_" .. Text
	local currentVal = UserConfigs[Flag]
	if currentVal == nil then currentVal = Default end
	UserConfigs[Flag] = currentVal

	local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    Container.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Container.Parent = targetParent

	local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local lConst = Instance.new("UITextSizeConstraint", Label)
    lConst.MinTextSize = 7
    Label.Parent = Container

	local Box = Instance.new("TextBox")
    Box.BackgroundColor3 = Theme.SwitchOff
    Box.Text = tostring(currentVal)
    Box.TextColor3 = Theme.Text
    Box.Font = Theme.Font
    Box.TextSize = 12
    Box.TextScaled = false
    Box.ClipsDescendants = true
    Box.Parent = Container
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    
    if isOld then
        Container.BackgroundColor3 = Color3.new(0, 0, 0)
        Container.BackgroundTransparency = 0.45
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
        local str = Instance.new("UIStroke", Container)
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        
        Label.Size = UDim2.new(1, -90, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        lConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
        Box.Size = UDim2.new(0, 70, 0, 26)
        Box.Position = UDim2.new(1, -80, 0.5, -13)
    else
        Container.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -75, 1, 0)
        Label.Position = UDim2.new(0, 5, 0, 0)
        lConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
        Box.Size = UDim2.new(0, 60, 0, 24)
        Box.Position = UDim2.new(1, -65, 0.5, -12)
    end
	
	task.spawn(function() pcall(Callback, currentVal) end)

	Box.FocusLost:Connect(function() 
		local num = tonumber(Box.Text)
		local finalVal = num or (Box.Text ~= "" and Box.Text or currentVal)
		Box.Text = tostring(finalVal)
		UserConfigs[Flag] = finalVal
		pcall(Callback, finalVal)
	end)
end

function Library:CreateDropdown(Page, Text, Options, Default, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or ContentConfig.ItemHeightNew
    
    local Flag = Page.Name .. "_" .. Text
    local currentVal = UserConfigs[Flag] or Default or Options[1]
    UserConfigs[Flag] = currentVal

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    Container.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Container.ClipsDescendants = true
    Container.Parent = targetParent

    local TopBtn = Instance.new("TextButton")
    TopBtn.Size = UDim2.new(1, 0, 0, height)
    TopBtn.BackgroundTransparency = 1
    TopBtn.Text = ""
    TopBtn.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = Text .. ": " .. tostring(currentVal)
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local lConst = Instance.new("UITextSizeConstraint", Label)
    lConst.MinTextSize = 7
    Label.Parent = TopBtn
    
    local str
    if isOld then
        Container.BackgroundColor3 = Color3.new(0, 0, 0)
        Container.BackgroundTransparency = 0.45
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
        str = Instance.new("UIStroke", Container)
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.Position = UDim2.new(0, 15, 0, 0)
        lConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
    else
        Container.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -25, 1, 0)
        Label.Position = UDim2.new(0, 5, 0, 0)
        lConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
    end

    if not isOld then
        TopBtn.MouseEnter:Connect(function() TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.Accent}):Play() end)
        TopBtn.MouseLeave:Connect(function() TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play() end)
    end

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 20, 0, 20)
    Icon.Position = isOld and UDim2.new(1, -30, 0.5, -10) or UDim2.new(1, -20, 0.5, -10)
    Icon.BackgroundTransparency = 1
    Icon.Text = "▼"
    Icon.TextColor3 = Theme.TextDark
    Icon.Font = Enum.Font.Gotham
    Icon.TextSize = 12
    Icon.Parent = TopBtn

    local MenuBg = Instance.new("Frame")
    MenuBg.Size = UDim2.new(1, 0, 1, -height)
    MenuBg.Position = UDim2.new(0, 0, 0, height)
    MenuBg.BackgroundColor3 = Color3.new(0, 0, 0)
    MenuBg.BackgroundTransparency = 0.45
    MenuBg.BorderSizePixel = 0
    MenuBg.Parent = Container

    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(0, 2, 1, 0)
    AccentLine.Position = UDim2.new(1, -2, 0, 0)
    AccentLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    AccentLine.BorderSizePixel = 0
    AccentLine.ZIndex = 5
    AccentLine.Parent = MenuBg

    local OptionList = Instance.new("ScrollingFrame")
    OptionList.Size = UDim2.new(1, -4, 1, 0)
    OptionList.Position = UDim2.new(0, 0, 0, 0)
    OptionList.BackgroundTransparency = 1
    OptionList.BorderSizePixel = 0
    OptionList.ScrollBarThickness = 2
    OptionList.ScrollBarImageColor3 = Theme.Accent
    OptionList.CanvasSize = UDim2.new(0, 0, 0, 0)
    OptionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    OptionList.Parent = MenuBg

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = OptionList

    local isOpen = false

    TopBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local optHeight = isOld and 30 or 26
            local maxHeight = isOld and 180 or 160
            TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, isOld and -2 or 0, 0, math.min(height + (#Options * optHeight), maxHeight))}):Play()
            Icon.Text = "▲"
            TweenService:Create(Icon, TweenInfo.new(0.3), {TextColor3 = Theme.Accent}):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, isOld and -2 or 0, 0, height)}):Play()
            Icon.Text = "▼"
            TweenService:Create(Icon, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark}):Play()
        end
    end)

    local function AddOption(optName)
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, isOld and 30 or 26)
        optBtn.BackgroundColor3 = Color3.new(0, 0, 0)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = tostring(optName)
        optBtn.TextColor3 = (currentVal == optName) and Theme.Text or Theme.TextDark
        optBtn.Font = (currentVal == optName) and Enum.Font.GothamBold or Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.TextXAlignment = Enum.TextXAlignment.Center
        optBtn.Parent = OptionList

        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -20, 0, 1)
        sep.Position = UDim2.new(0, 10, 1, -1)
        sep.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        sep.BorderSizePixel = 0
        sep.Parent = optBtn

        optBtn.MouseEnter:Connect(function()
            if currentVal ~= optName then 
                TweenService:Create(optBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
            end
        end)
        optBtn.MouseLeave:Connect(function()
            if currentVal ~= optName then 
                TweenService:Create(optBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
            end
        end)

        optBtn.MouseButton1Click:Connect(function()
            currentVal = optName
            UserConfigs[Flag] = currentVal
            
            local originalLabel = Label:GetAttribute("OriginalText")
            if originalLabel then
                local currentText = Label.Text
                local translatedPrefix = string.split(currentText, ": ")[1]
                Label.Text = translatedPrefix .. ": " .. tostring(currentVal)
            else
                Label.Text = Text .. ": " .. tostring(currentVal)
            end
            
            isOpen = false
            TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, isOld and -2 or 0, 0, height)}):Play()
            Icon.Text = "▼"
            TweenService:Create(Icon, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark}):Play()
            
            for _, child in pairs(OptionList:GetChildren()) do
                if child:IsA("TextButton") then 
                    child.TextColor3 = Theme.TextDark
                    child.Font = Enum.Font.Gotham
                end
            end
            optBtn.TextColor3 = Theme.Text
            optBtn.Font = Enum.Font.GothamBold
            
            pcall(Callback, currentVal)
        end)
    end

    for _, opt in ipairs(Options) do AddOption(opt) end
    task.spawn(function() pcall(Callback, currentVal) end)
end

function Library:CreatePlayerDropdown(Page, Text, Default, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or ContentConfig.ItemHeightNew
    
    local Flag = Page.Name .. "_" .. Text
    local currentVal = UserConfigs[Flag] or Default or "Select Player"
    UserConfigs[Flag] = currentVal

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    Container.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Container.ClipsDescendants = true
    Container.Parent = targetParent

    local TopBtn = Instance.new("TextButton")
    TopBtn.Size = UDim2.new(1, 0, 0, height)
    TopBtn.BackgroundTransparency = 1
    TopBtn.Text = ""
    TopBtn.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = Text .. ": " .. tostring(currentVal)
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local lConst = Instance.new("UITextSizeConstraint", Label)
    lConst.MinTextSize = 7
    Label.Parent = TopBtn
    
    local str
    if isOld then
        Container.BackgroundColor3 = Color3.new(0, 0, 0)
        Container.BackgroundTransparency = 0.45
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
        str = Instance.new("UIStroke", Container)
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.Position = UDim2.new(0, 15, 0, 0)
        lConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
    else
        Container.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.Position = UDim2.new(0, 5, 0, 0)
        lConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
    end

    if not isOld then
        TopBtn.MouseEnter:Connect(function() TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Theme.Accent}):Play() end)
        TopBtn.MouseLeave:Connect(function() TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark}):Play() end)
    end

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 20, 0, 20)
    Icon.Position = isOld and UDim2.new(1, -30, 0.5, -10) or UDim2.new(1, -25, 0.5, -10)
    Icon.BackgroundTransparency = 1
    Icon.Text = "▼"
    Icon.TextColor3 = Theme.TextDark
    Icon.Font = Enum.Font.Gotham
    Icon.TextSize = 12
    Icon.Parent = TopBtn

    local MenuBg = Instance.new("Frame")
    MenuBg.Size = UDim2.new(1, 0, 1, -height)
    MenuBg.Position = UDim2.new(0, 0, 0, height)
    MenuBg.BackgroundColor3 = Color3.new(0, 0, 0)
    MenuBg.BackgroundTransparency = 0.45
    MenuBg.BorderSizePixel = 0
    MenuBg.Parent = Container

    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(0, 2, 1, 0)
    AccentLine.Position = UDim2.new(1, -2, 0, 0)
    AccentLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    AccentLine.BorderSizePixel = 0
    AccentLine.ZIndex = 5
    AccentLine.Parent = MenuBg

    local OptionList = Instance.new("ScrollingFrame")
    OptionList.Size = UDim2.new(1, -4, 1, 0)
    OptionList.Position = UDim2.new(0, 0, 0, 0)
    OptionList.BackgroundTransparency = 1
    OptionList.BorderSizePixel = 0
    OptionList.ScrollBarThickness = 2
    OptionList.ScrollBarImageColor3 = Theme.Accent
    OptionList.CanvasSize = UDim2.new(0, 0, 0, 0)
    OptionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    OptionList.Parent = MenuBg

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = OptionList

    local isOpen = false

    local function AddOption(optName)
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, isOld and 30 or 26)
        optBtn.BackgroundColor3 = Color3.new(0, 0, 0)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = tostring(optName)
        optBtn.TextColor3 = (currentVal == optName) and Theme.Text or Theme.TextDark
        optBtn.Font = (currentVal == optName) and Enum.Font.GothamBold or Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.TextXAlignment = Enum.TextXAlignment.Center
        optBtn.Parent = OptionList

        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -20, 0, 1)
        sep.Position = UDim2.new(0, 10, 1, -1)
        sep.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        sep.BorderSizePixel = 0
        sep.Parent = optBtn

        optBtn.MouseEnter:Connect(function()
            if currentVal ~= optName then 
                TweenService:Create(optBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
            end
        end)
        optBtn.MouseLeave:Connect(function()
            if currentVal ~= optName then 
                TweenService:Create(optBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark}):Play()
            end
        end)

        optBtn.MouseButton1Click:Connect(function()
            currentVal = optName
            UserConfigs[Flag] = currentVal
            
            local originalLabel = Label:GetAttribute("OriginalText")
            if originalLabel then
                local currentText = Label.Text
                local translatedPrefix = string.split(currentText, ": ")[1]
                Label.Text = translatedPrefix .. ": " .. tostring(currentVal)
            else
                Label.Text = Text .. ": " .. tostring(currentVal)
            end
            
            isOpen = false
            TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, isOld and -2 or 0, 0, height)}):Play()
            Icon.Text = "▼"
            TweenService:Create(Icon, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark}):Play()
            
            pcall(Callback, currentVal)
        end)
    end

    TopBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            for _, child in ipairs(OptionList:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            
            local playersList = Players:GetPlayers()
            local playerCount = 0
            for _, p in ipairs(playersList) do
                if p ~= LocalPlayer then
                    AddOption(p.Name)
                    playerCount = playerCount + 1
                end
            end

            local optHeight = isOld and 30 or 26
            local maxHeight = isOld and 180 or 160
            local targetHeight = math.min(height + (playerCount * optHeight), maxHeight)
            if targetHeight == height then targetHeight = height + optHeight end 
            
            TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, isOld and -2 or 0, 0, targetHeight)}):Play()
            Icon.Text = "▲"
            TweenService:Create(Icon, TweenInfo.new(0.3), {TextColor3 = Theme.Accent}):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, isOld and -2 or 0, 0, height)}):Play()
            Icon.Text = "▼"
            TweenService:Create(Icon, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark}):Play()
        end
    end)

    task.spawn(function() pcall(Callback, currentVal) end)
end

function Library:CreateColorPicker(Page, Text, DefaultColor, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
    local height = isOld and ContentConfig.ItemHeightOld or ContentConfig.ItemHeightNew
    
    local Flag = Page.Name .. "_" .. Text
    local currentVal = UserConfigs[Flag]
    if currentVal then
        if type(currentVal) == "string" then
            currentVal = Color3.fromHex(currentVal)
        end
    else
        currentVal = DefaultColor
    end
    UserConfigs[Flag] = currentVal:ToHex()

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
    Container.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Container.ClipsDescendants = true
    Container.Parent = targetParent

    local TopBtn = Instance.new("TextButton")
    TopBtn.Size = UDim2.new(1, 0, 0, height)
    TopBtn.BackgroundTransparency = 1
    TopBtn.Text = ""
    TopBtn.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label:SetAttribute("OriginalText", Text) 
    Label.Font = Theme.Font
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextScaled = true 
    local lConst = Instance.new("UITextSizeConstraint", Label)
    lConst.MinTextSize = 7
    Label.Parent = TopBtn
    
    local str
    if isOld then
        Container.BackgroundColor3 = Color3.new(0, 0, 0)
        Container.BackgroundTransparency = 0.45
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
        str = Instance.new("UIStroke", Container)
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
        
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        lConst.MaxTextSize = 12
        Label.TextColor3 = Theme.Text
    else
        Container.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.Position = UDim2.new(0, 5, 0, 0)
        lConst.MaxTextSize = 11
        Label.TextColor3 = Theme.TextDark
    end

    if not isOld then
        TopBtn.MouseEnter:Connect(function() TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Theme.Accent}):Play() end)
        TopBtn.MouseLeave:Connect(function() TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Theme.TextDark}):Play() end)
    end

    local DisplayColor = Instance.new("Frame")
    DisplayColor.Size = isOld and UDim2.new(0, 24, 0, 24) or UDim2.new(0, 24, 0, 20)
    DisplayColor.Position = isOld and UDim2.new(1, -34, 0.5, -12) or UDim2.new(1, -29, 0.5, -10)
    DisplayColor.BackgroundColor3 = currentVal
    DisplayColor.Parent = TopBtn
    Instance.new("UICorner", DisplayColor).CornerRadius = UDim.new(0, 4)

    local PickerArea = Instance.new("Frame")
    PickerArea.Size = UDim2.new(1, 0, 0, 110)
    PickerArea.Position = UDim2.new(0, 0, 0, height)
    PickerArea.BackgroundTransparency = 1
    PickerArea.Parent = Container

    local SVMap = Instance.new("ImageButton")
    SVMap.Size = isOld and UDim2.new(0, 150, 0, 90) or UDim2.new(0, 140, 0, 90)
    SVMap.Position = UDim2.new(0, 10, 0, 10)
    SVMap.AutoButtonColor = false
    SVMap.Parent = PickerArea
    local svImage = Instance.new("ImageLabel")
    svImage.Size = UDim2.new(1,0,1,0)
    svImage.BackgroundTransparency = 1
    svImage.Image = "rbxassetid://4155801252"
    svImage.Parent = SVMap
    local SVCursor = Instance.new("Frame")
    SVCursor.Size = UDim2.new(0, 6, 0, 6)
    SVCursor.BackgroundColor3 = Color3.new(1,1,1)
    SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    SVCursor.Parent = SVMap
    Instance.new("UICorner", SVCursor).CornerRadius = UDim.new(1,0)

    local HueBar = Instance.new("ImageButton")
    HueBar.Size = UDim2.new(0, 20, 0, 90)
    HueBar.Position = isOld and UDim2.new(0, 170, 0, 10) or UDim2.new(0, 160, 0, 10)
    HueBar.AutoButtonColor = false
    HueBar.BackgroundColor3 = Color3.new(1, 1, 1) 
    HueBar.Parent = PickerArea
    local HueGrad = Instance.new("UIGradient")
    HueGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0))
    }
    HueGrad.Rotation = 90
    HueGrad.Parent = HueBar
    local HueCursor = Instance.new("Frame")
    HueCursor.Size = UDim2.new(1, 0, 0, 2)
    HueCursor.BackgroundColor3 = Color3.new(1,1,1)
    HueCursor.AnchorPoint = Vector2.new(0, 0.5)
    HueCursor.Parent = HueBar

    local h, s, v = currentVal:ToHSV()
    local isSVDra, isHueDrag = false, false

    local function UpdateColor()
        local c = Color3.fromHSV(h, s, v)
        currentVal = c
        DisplayColor.BackgroundColor3 = c
        SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        UserConfigs[Flag] = c:ToHex()
        pcall(Callback, c)
    end

    local function UpdateCursors()
        HueCursor.Position = UDim2.new(0, 0, math.clamp(1 - h, 0, 1), 0)
        SVCursor.Position = UDim2.new(math.clamp(s, 0, 1), 0, math.clamp(1 - v, 0, 1), 0)
        UpdateColor()
    end
    UpdateCursors()

    local function handleSVDra(input)
        local rx = math.clamp((input.Position.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
        local ry = math.clamp((input.Position.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
        s = rx
        v = 1 - ry
        UpdateCursors()
    end

    local function handleHueDrag(input)
        local ry = math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
        h = 1 - ry
        UpdateCursors()
    end

    SVMap.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSVDra = true
            if Page and Page:IsA("ScrollingFrame") then Page.ScrollingEnabled = false end
            handleSVDra(input)
        end
    end)

    HueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isHueDrag = true
            if Page and Page:IsA("ScrollingFrame") then Page.ScrollingEnabled = false end
            handleHueDrag(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSVDra = false
            isHueDrag = false
            if Page and Page:IsA("ScrollingFrame") then Page.ScrollingEnabled = true end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if isSVDra then
                handleSVDra(input)
            elseif isHueDrag then
                handleHueDrag(input)
            end
        end
    end)

    local isOpen = false
    TopBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            Container.Size = UDim2.new(1, isOld and -2 or 0, 0, height + 110)
        else
            Container.Size = UDim2.new(1, isOld and -2 or 0, 0, height)
        end
    end)

    task.spawn(function() pcall(Callback, currentVal) end)
end

function Library:CreatePlayerCard(Page, Player, Callback)
    local isOld = Page:GetAttribute("OldStyle")
    local targetParent = GetParentTarget(Page)
	local Card = Instance.new("Frame")
    Card.Name = "PlayerCard" 
    Card.Size = UDim2.new(1, isOld and -2 or 0, 0, isOld and 50 or ContentConfig.PlayerCardHeight)
    Card.Position = UDim2.new(0, isOld and 1 or 0, 0, 0)
    Card.Parent = targetParent
    
    if isOld then
        Card.BackgroundColor3 = Color3.new(0, 0, 0)
        Card.BackgroundTransparency = 0.45
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        local str = Instance.new("UIStroke", Card)
        str.Color = Color3.fromRGB(40, 40, 40)
        str.Thickness = 1
    else
        Card.BackgroundTransparency = 1
    end
    
	local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.new(0, 30, 0, 30)
    Avatar.Position = UDim2.new(0, 5, 0.5, -15)
    Avatar.BackgroundColor3 = Color3.new(0, 0, 0)
    Avatar.BackgroundTransparency = 0.45
    Avatar.Parent = Card
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 6)
	task.spawn(function() 
        local content, isReady = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        if isReady then Avatar.Image = content end 
    end)
    
	local Display = Instance.new("TextLabel")
    Display.Text = Player.DisplayName
    Display.Size = UDim2.new(1, isOld and -130 or -100, 0, 18)
    Display.Position = UDim2.new(0, isOld and 54 or 40, 0, 5)
    Display.BackgroundTransparency = 1
    Display.Font = Theme.Font
    Display.TextScaled = true 
    local dConst = Instance.new("UITextSizeConstraint", Display)
    dConst.MinTextSize = 7
    dConst.MaxTextSize = isOld and 13 or 12
    Display.TextColor3 = Theme.Text
    Display.TextXAlignment = Enum.TextXAlignment.Left
    Display.Parent = Card
    
	local User = Instance.new("TextLabel")
    User.Text = "@" .. Player.Name
    User.Size = UDim2.new(1, isOld and -130 or -100, 0, 14)
    User.Position = UDim2.new(0, isOld and 54 or 40, 0, isOld and 26 or 21)
    User.BackgroundTransparency = 1
    User.Font = Enum.Font.Gotham
    User.TextScaled = true 
    local uConst = Instance.new("UITextSizeConstraint", User)
    uConst.MinTextSize = 7
    uConst.MaxTextSize = isOld and 11 or 10
    User.TextColor3 = Theme.TextDark
    User.TextXAlignment = Enum.TextXAlignment.Left
    User.Parent = Card
    
	local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(0, isOld and 75 or 45, 0, isOld and 26 or 24)
    ActionBtn.Position = UDim2.new(1, isOld and -83 or -50, 0.5, isOld and -13 or -12)
    ActionBtn.BackgroundColor3 = Theme.Accent
    ActionBtn.Text = isOld and "Teleport" or "TP"
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.TextSize = isOld and 11 or 10
    ActionBtn.TextColor3 = Color3.new(0,0,0)
    ActionBtn.Parent = Card
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 6)
    ApplyGradient(ActionBtn, Theme.Accent, Theme.AccentDark, 90)
    ActionBtn.MouseButton1Click:Connect(function() 
        TweenService:Create(ActionBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        task.wait(0.1)
        TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
        pcall(Callback) 
    end)
end

-- ==========================================
-- TELEPORT PAGE
-- ==========================================
local function LoadTeleportPage(pageObj)
    local s, code = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/1D4vid/teste/refs/heads/main/teleport2.7.lua") end)
    if s and code then
        loadstring(code)()({
            Library = Library,
            Page = pageObj,
            Workspace = Workspace,
            Players = Players,
            LocalPlayer = LocalPlayer,
            ScreenGui = ScreenGui,
            SendNotification = SendNotification,
            UserInputService = UserInputService
        })
    else
        warn("Failed to load Teleport Page")
    end
end

-- ==========================================
-- FOG PAGE
-- ==========================================
local function LoadFogPage(pageObj)
    local s, code = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/1D4vid/teste/refs/heads/main/fog2.7.lua") end)
    if s and code then
        loadstring(code)()({
            Library = Library,
            Page = pageObj,
            Lighting = Lighting,
            RunService = RunService,
            SendNotification = SendNotification
        })
    else
        warn("Failed to load Fog Page")
    end
end

-- ==========================================
-- TEXTURES PAGE (PORTADO DA UI ANTIGA)
-- ==========================================
local function LoadTexturesPage(Page)
    local formatID = function(id)
        if type(id) == "number" and id > 0 then return "rbxassetid://" .. id
        elseif type(id) == "string" and id ~= "" and id ~= "0" then
            if not id:find("rbxassetid://") then return "rbxassetid://" .. id else return id end
        end
        return nil
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

    Library:CreateSection(Page, "Map Textures", "Left")

    -- [ WHITE BRICKS ]
    local wbEnabled = false
    local wbDescConn
    local wbBkp = setmetatable({}, {__mode = "k"})
    
    local function applyWhiteBrick(part)
        if not wbEnabled then return end
        if not part:IsA("BasePart") or part:IsA("Terrain") then return end
        
        local parentModel = part:FindFirstAncestorOfClass("Model")
        if parentModel and parentModel:FindFirstChildOfClass("Humanoid") then return end

        if not wbBkp[part] then 
            wbBkp[part] = {M = part.Material, C = part.Color} 
        end
        
        pcall(function()
            part.Material = Enum.Material.Brick
            part.Color = Color3.fromRGB(255, 255, 255)
        end)
    end

    Library:CreateToggle(Page, "White Bricks", false, function(state)
        wbEnabled = state
        if state then
            task.spawn(function()
                local desc = Workspace:GetDescendants()
                local t = os.clock()
                for i = 1, #desc do
                    if not wbEnabled then break end
                    applyWhiteBrick(desc[i])
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
            wbDescConn = Workspace.DescendantAdded:Connect(function(child)
                if wbEnabled then task.defer(function() applyWhiteBrick(child) end) end
            end)
        else
            if wbDescConn then wbDescConn:Disconnect() wbDescConn = nil end
            local currentBkp = wbBkp
            wbBkp = setmetatable({}, {__mode = "k"})
            local toRevert = {}
            for p, d in pairs(currentBkp) do table.insert(toRevert, {part = p, mat = d.M, col = d.C}) end
            task.spawn(function()
                local t = os.clock()
                for i = 1, #toRevert do
                    local item = toRevert[i]
                    local p = item.part
                    if p and p.Parent then
                        pcall(function() p.Material = item.mat; p.Color = item.col end)
                    end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
        end
    end)

    -- [ SNOW TEXTURES ]
    local snowEnabled = false
    local snowDescConn
    local snowBkp = setmetatable({}, {__mode = "k"})
    local IgnoreNames = { ComputerTable = true, ExitDoor = true }
    
    local function applySnowTexture(part)
        if not snowEnabled then return end
        if not part:IsA("BasePart") or part:IsA("Terrain") then return end
        if not part.Anchored or IgnoreNames[part.Name] then return end

        if not snowBkp[part] then snowBkp[part] = {M = part.Material, C = part.Color} end
        
        pcall(function()
            part.Material = Enum.Material.Snow
            part.Color = Color3.fromRGB(255, 255, 255)
        end)
    end

    Library:CreateToggle(Page, "Snow Textures", false, function(state)
        snowEnabled = state
        if state then
            task.spawn(function()
                local desc = Workspace:GetDescendants()
                local t = os.clock()
                for i = 1, #desc do
                    if not snowEnabled then break end
                    applySnowTexture(desc[i])
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
            snowDescConn = Workspace.DescendantAdded:Connect(function(child)
                if snowEnabled then task.defer(function() applySnowTexture(child) end) end
            end)
        else
            if snowDescConn then snowDescConn:Disconnect() snowDescConn = nil end
            local currentBkp = snowBkp
            snowBkp = setmetatable({}, {__mode = "k"})
            local toRevert = {}
            for p, d in pairs(currentBkp) do table.insert(toRevert, {part = p, mat = d.M, col = d.C}) end
            task.spawn(function()
                local t = os.clock()
                for i = 1, #toRevert do
                    local item = toRevert[i]
                    local p = item.part
                    if p and p.Parent then
                        pcall(function() p.Material = item.mat; p.Color = item.col end)
                    end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
        end
    end)

    Library:CreateToggle(Page, "Remove Textures", false, function(state) 
        if not getgenv().NexOptimization then
            getgenv().NexOptimization = loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/fps%20booster%20e%20remove%20textures.lua"))()
        end
        getgenv().NexOptimization.ToggleTextures(state)
    end)
    
    Library:CreateToggle(Page, "FpsBooster", false, function(state) 
        if not getgenv().NexOptimization then
            getgenv().NexOptimization = loadstring(game:HttpGet("https://raw.githubusercontent.com/1D4vid/FTFNexVoid/refs/heads/main/fps%20booster%20e%20remove%20textures.lua"))()
        end
        getgenv().NexOptimization.ToggleFPSBooster(state)
    end)

    -- [ ULTRA HD GRAPHICS ]
    local ultraHDConns = {}
    local createdMaterials = {}
    Library:CreateToggle(Page, "Ultra HD Graphics", false, function(state) 
        local MaterialService = game:GetService("MaterialService")
        local StarterGui = game:GetService("StarterGui")
        local Cam = Workspace.CurrentCamera
        
        if state then
            local function createMaterial(name, baseMaterial, colorMap, normalMap, roughnessMap)
                local Mat = Instance.new("MaterialVariant")
                Mat.Name = name .. "_TextureOnly"
                Mat.BaseMaterial = baseMaterial
                Mat.ColorMap = colorMap
                Mat.NormalMap = normalMap
                Mat.RoughnessMap = roughnessMap
                Mat.Parent = MaterialService
                pcall(function() MaterialService:SetBaseMaterialOverride(baseMaterial, Mat) end)
                table.insert(createdMaterials, {Variant = Mat, Base = baseMaterial})
            end
            createMaterial("Concrete", Enum.Material.Concrete, "rbxassetid://6223521473", "rbxassetid://6223521257", "rbxassetid://6223521360")
            createMaterial("Brick", Enum.Material.Brick, "rbxassetid://6396996328", "rbxassetid://6396996024", "rbxassetid://6396996160")
            createMaterial("Wood", Enum.Material.Wood, "rbxassetid://924320031", "rbxassetid://924320256", "rbxassetid://924305001")
            createMaterial("WoodPlanks", Enum.Material.WoodPlanks, "rbxassetid://924320031", "rbxassetid://924320256", "rbxassetid://924305001")
            pcall(function() MaterialService.Use2022Materials = true end)

            local spectateIndex = 1
            local allPlayers = {}
            local function updatePlayerList()
                allPlayers = {}
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
                        table.insert(allPlayers, plr)
                    end
                end
            end
            local function spectatePlayer(direction)
                updatePlayerList()
                if #allPlayers == 0 then return end
                spectateIndex = spectateIndex + direction
                if spectateIndex > #allPlayers then spectateIndex = 1 end
                if spectateIndex < 1 then spectateIndex = #allPlayers end
                local target = allPlayers[spectateIndex]
                if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                    Cam.CameraType = Enum.CameraType.Custom
                    Cam.CameraSubject = target.Character.Humanoid
                    pcall(function() StarterGui:SetCore("SendNotification", {Title = "Spectating", Text = target.Name, Duration = 1}) end)
                end
            end
            local function stopSpectating()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Cam.CameraType = Enum.CameraType.Custom
                    Cam.CameraSubject = LocalPlayer.Character.Humanoid
                    pcall(function() StarterGui:SetCore("SendNotification", {Title = "Reset", Text = "Camera no Jogador", Duration = 2}) end)
                end
            end
            table.insert(ultraHDConns, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.Right then spectatePlayer(1)
                elseif input.KeyCode == Enum.KeyCode.Left then spectatePlayer(-1)
                elseif input.KeyCode == Enum.KeyCode.Backspace then stopSpectating() end
            end))
        else
            for _, m in ipairs(createdMaterials) do
                pcall(function() MaterialService:SetBaseMaterialOverride(m.Base, "") end)
                if m.Variant then m.Variant:Destroy() end
            end
            table.clear(createdMaterials)
            pcall(function() MaterialService.Use2022Materials = false end)
            for _, c in ipairs(ultraHDConns) do c:Disconnect() end
            table.clear(ultraHDConns)
            if Cam.CameraSubject and Cam.CameraSubject:IsA("Humanoid") and Cam.CameraSubject.Parent ~= LocalPlayer.Character then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Cam.CameraType = Enum.CameraType.Custom
                    Cam.CameraSubject = LocalPlayer.Character.Humanoid
                end
            end
        end
    end)

    -- [ MINECRAFT TEXTURE ]
    local mcOriginalMaterials = setmetatable({}, {__mode = "k"})
    local mcDescendantConn
    local mcLoopConn
    local mcFila = {}
    local mcEnabled = false
    local mcFaces = {"Front", "Back", "Bottom", "Top", "Right", "Left"}
    local mcMaterials = {
        Wood = "3258599312", WoodPlanks = "8676581022", Brick = "8558400252", Cobblestone = "5003953441",
        Concrete = "7341687607", DiamondPlate = "6849247561", Fabric = "118776397", Granite = "4722586771",
        Grass = "4722588177", Ice = "3823766459", Marble = "62967586", Metal = "62967586", Sand = "152572215"
    }

    local function processMCPart(part)
        if not mcEnabled then return end
        if part:IsA("BasePart") and part.Transparency < 1 then
            if part:FindFirstChild("McTexture_Front") then return end
            local textureId = mcMaterials[part.Material.Name]
            if textureId then
                mcOriginalMaterials[part] = part.Material
                for _, face in ipairs(mcFaces) do
                    local newTex = Instance.new("Texture")
                    newTex.Name = "McTexture_" .. face
                    newTex.ZIndex = 2147483647
                    newTex.Texture = "rbxassetid://" .. textureId
                    newTex.Face = Enum.NormalId[face]
                    newTex.StudsPerTileU = 4
                    newTex.StudsPerTileV = 4
                    newTex.Color3 = part.Color
                    newTex.Transparency = part.Transparency
                    newTex.Parent = part
                end
                part.Material = Enum.Material.SmoothPlastic
            end
        end
    end

    Library:CreateToggle(Page, "Minecraft Texture", false, function(state)
        mcEnabled = state
        if state then
            task.spawn(function()
                local desc = Workspace:GetDescendants()
                local t = os.clock()
                for i = 1, #desc do
                    if not mcEnabled then break end
                    processMCPart(desc[i])
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
            mcDescendantConn = Workspace.DescendantAdded:Connect(function(newObj)
                if mcEnabled then table.insert(mcFila, newObj) end
            end)
            mcLoopConn = RunService.Heartbeat:Connect(function()
                if not mcEnabled then return end
                local t = os.clock()
                while #mcFila > 0 do
                    if os.clock() - t > 0.005 then break end 
                    local obj = table.remove(mcFila) 
                    processMCPart(obj)
                end
            end)
        else
            if mcDescendantConn then mcDescendantConn:Disconnect() end
            if mcLoopConn then mcLoopConn:Disconnect() end
            table.clear(mcFila)
            
            local currentBkp = mcOriginalMaterials
            mcOriginalMaterials = setmetatable({}, {__mode = "k"})
            local toRevert = {}
            for part, origMat in pairs(currentBkp) do table.insert(toRevert, {part = part, mat = origMat}) end
            
            task.spawn(function()
                local t = os.clock()
                for i = 1, #toRevert do
                    local p = toRevert[i].part
                    if p and p.Parent then
                        pcall(function()
                            for _, face in ipairs(mcFaces) do
                                local tex = p:FindFirstChild("McTexture_" .. face)
                                if tex then tex:Destroy() end
                            end
                            p.Material = toRevert[i].mat
                        end)
                    end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
            end)
        end
    end)

    -- [ DOUBLE JUMP EFFECTS ]
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

        task.spawn(function()
            local pastasSeguras = {Workspace, game:GetService("ReplicatedStorage"), Players}
            local t = os.clock()
            for _, pasta in ipairs(pastasSeguras) do
                local desc = pasta:GetDescendants()
                for i = 1, #desc do
                    local obj = desc[i]
                    if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then aplicarTextura(obj) end
                    if os.clock() - t > 0.01 then task.wait() t = os.clock() end
                end
                if texturaID ~= "Default" then
                    table.insert(currentDoubleJumpConns, pasta.DescendantAdded:Connect(function(obj)
                        if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") then task.defer(function() aplicarTextura(obj) end) end
                    end))
                end
            end
        end)
    end

    -- DIVISÃO DO DOUBLE JUMP EM PARTE 1 E 2
    Library:CreateSection(Page, "Double Jump Effects (P1)", "Right")
    local targetParentDJ1 = GetParentTarget(Page)
    
    Library:CreateSection(Page, "Double Jump (P2)", "Left")
    local targetParentDJ2 = GetParentTarget(Page)

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
        mDefaultBtn.MouseLeave:Connect(function() TweenService:Create(mDStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() TweenService:Create(mDefaultBtn, TweenInfo.new(0.2), {TextColor3=Theme.TextDark}):Play() end)
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

    -- DIVISÃO DO CROSSHAIR EM PARTE 1 E 2
    Library:CreateSection(Page, "Crosshairs (P1)", "Left")
    Library:CreateSlider(Page, "Cursor Size", 10, 100, 24, UpdateCursorSizes)
    local targetParentCur1 = GetParentTarget(Page)
    
    Library:CreateSection(Page, "Crosshairs (P2)", "Right")
    local targetParentCur2 = GetParentTarget(Page)

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
                
                btn.MouseEnter:Connect(function() TweenService:Create(imgStr, TweenInfo.new(0.2), {Color=Theme.Accent}):Play() end)
                btn.MouseLeave:Connect(function() TweenService:Create(imgStr, TweenInfo.new(0.2), {Color=Color3.fromRGB(40,40,40)}):Play() end)
                
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

-- ==========================================
-- PAGE LOADERS PLACEHOLDERS 
-- ==========================================

local function LoadProgressPage(Page)
    Library:CreateSection(Page, "Action Timers")
    Library:CreateToggle(Page, "Computer Progress", false, function(state) end)
    Library:CreateToggle(Page, "Door Progress", false, function(state) end)
    Library:CreateToggle(Page, "ExitDoor Progress", false, function(state) end)
    Library:CreateToggle(Page, "GetUp Timer", false, function(state) end)
    
    Library:CreateSection(Page, "Beast Indicators")
    Library:CreateToggle(Page, "Beast Power Timer", false, function(state) end)
    Library:CreateToggle(Page, "Beast Power Timer V2", false, function(state) end)
    Library:CreateToggle(Page, "Beast Spawn Timer", false, function(state) end)
    Library:CreateToggle(Page, "WalkSpeed Detector", false, function(state) end)
end

local function LoadVisualSkinsPage(Page)
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
    PCancelBtn.BackgroundColor3 = Color3.new(0,0,0)
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
    end)
    PApplyBtn.MouseButton1Click:Connect(function() 
        SendNotification("Skin UI Base Applied!", 2)
        ModalOverlay.Visible = false
        PreviewBox.Visible = false
    end)

    Library:CreateSection(Page, "Exclusive Bundles")
    Library:CreateToggle(Page, "Headless", false, function(state) end)
    Library:CreateToggle(Page, "Korblox", false, function(state) end)

    local SpacerEx = Instance.new("Frame")
    SpacerEx.Size = UDim2.new(1, 0, 0, 5)
    SpacerEx.BackgroundTransparency = 1
    SpacerEx.Parent = Page

    Library:CreateSection(Page, "Skin Changer")
    
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -2, 0, 35)
    InputContainer.Position = UDim2.new(0, 1, 0, 0)
    InputContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    InputContainer.BackgroundTransparency = 0.45
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

    SearchBtnIcon.MouseButton1Click:Connect(function()
        if UserInputBox.Text ~= "" then
            PTitle.Text = "SKIN FOUND"
            PName.Text = UserInputBox.Text
            PApplyBtn.Text = "Apply Skin"
            ModalOverlay.Visible = true
            PreviewBox.Visible = true
        end
    end)

    Library:CreateSection(Page, "Bundle Changer")
    Library:CreateInput(Page, "Bundle ID...", "", function(val) end)
end

local function LoadAutoFarmPage(Page)
    Library:CreateSection(Page, "Main Farming")
    Library:CreateToggle(Page, "Enable Auto Farm", false, function(state) end)
    Library:CreateToggle(Page, "Auto Win Survivor", false, function(state) end)
    Library:CreateToggle(Page, "Auto Win Beast", false, function(state) end)

    Library:CreateSection(Page, "Farm Settings")
    Library:CreateToggle(Page, "Auto Save (Silent)", false, function(state) end)
    Library:CreateToggle(Page, "Anti AFK", false, function(state) end)
end

local function LoadSoundsPage(Page)
    Library:CreateSection(Page, "Mute Sounds")
    Library:CreateToggle(Page, "Remove Your Steps", false, function(state) end)
    Library:CreateToggle(Page, "Remove Your Jumps", false, function(state) end)
    Library:CreateToggle(Page, "Remove Pc Hack Sounds", false, function(state) end)
    Library:CreateToggle(Page, "No hit sound", false, function(state) end)
    
    Library:CreateSection(Page, "General")
    Library:CreateSlider(Page, "Volume Boost", 0, 10, 1, function(val) end)
    
    Library:CreateSection(Page, "Custom Sound Packs")
    local targetParentSounds = GetParentTarget(Page)
    local ResetBtnFrame = Instance.new("TextButton")
    ResetBtnFrame.Size = UDim2.new(1, -2, 0, 30)
    ResetBtnFrame.Position = UDim2.new(0, 1, 0, 0)
    ResetBtnFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    ResetBtnFrame.BackgroundTransparency = 0.45
    ResetBtnFrame.Text = "Default Sounds (Reset All)"
    ResetBtnFrame.TextColor3 = Theme.CloseRed
    ResetBtnFrame.Font = Enum.Font.GothamBold
    ResetBtnFrame.TextSize = 11
    ResetBtnFrame.Parent = targetParentSounds
    Instance.new("UICorner", ResetBtnFrame).CornerRadius = UDim.new(0, 6)
    local rbsStr = Instance.new("UIStroke", ResetBtnFrame)
    rbsStr.Color = Color3.fromRGB(40,40,40)
end

local function LoadAdvancedPage(Page)
    Library:CreateSection(Page, "Survivor")
    Library:CreateToggle(Page, "Auto Save (Teleport)", false, function(state) end)
    Library:CreateToggle(Page, "Beast Untie Player", false, function(state) end)
    Library:CreateToggle(Page, "Anti Ragdoll", false, function(state) end)
    Library:CreateToggle(Page, "Slow Beast", false, function(state) end)
    Library:CreateToggle(Page, "Slow Runner Beast", false, function(state) end)
    Library:CreateToggle(Page, "Slow Beast Aura", false, function(state) end)
    Library:CreateSlider(Page, "Slow Beast Aura Range", 5, 30, 15, function(val) end)
    Library:CreateToggle(Page, "Touch Fling", false, function(state) end)
    Library:CreateToggle(Page, "No Hack Fail", false, function(state) end)

    Library:CreateSection(Page, "Beast")
    Library:CreateToggle(Page, "Beast Camera Mode", false, function(state) end)
    Library:CreateToggle(Page, "Auto Tie", false, function(state) end)
    Library:CreateSlider(Page, "Auto Tie Range", 5, 30, 15, function(val) end)
    Library:CreateToggle(Page, "Hit Aura", false, function(state) end)
    Library:CreateSlider(Page, "Hit Aura Range", 5, 15, 10, function(val) end)
    Library:CreateToggle(Page, "Hitbox Extender", false, function(state) end)
    Library:CreateInput(Page, "Hitbox Size", 2, function(val) end)
    Library:CreateToggle(Page, "Show Hitbox", false, function(state) end)
    Library:CreateToggle(Page, "No Jump Delay", false, function(state) end)

    Library:CreateSection(Page, "Players")
    Library:CreateToggle(Page, "Fast Double Jump", false, function(state) end)
    Library:CreateToggleKeybind(Page, "Walkspeed", false, "None", function(state) end)
    Library:CreateSlider(Page, "Speed Value", 16, 200, 16, function(val) end)
    Library:CreateToggleKeybind(Page, "Jump Power", false, "None", function(state) end)
    Library:CreateSlider(Page, "Jump Power Val", 50, 300, 120, function(val) end)
    Library:CreateToggleKeybind(Page, "Fly", false, "None", function(state) end)
    Library:CreateSlider(Page, "Fly Speed", 10, 200, 50, function(val) end)
    Library:CreateToggleKeybind(Page, "Noclip", false, "None", function(state) end)
    Library:CreateToggle(Page, "ShiftLock", false, function(state) end)
    Library:CreateToggle(Page, "Inf Jump", false, function(state) end)
end

-- ==========================================
-- SIDEBAR BUTTONS
-- ==========================================

local HighlightPage = createSidebarButton("14502433595", "Highlight") 
local VisualPage = createSidebarButton("76176408662599", "Visual") 
local ProgressPage = createSidebarButton("6761866149", "Progress", LoadProgressPage)
local TexturesPage = createSidebarButton("12623720992", "Textures", LoadTexturesPage)
local AutoFarmPage = createSidebarButton("12403104094", "Auto Farm", LoadAutoFarmPage) 
local FogPage = createSidebarButton("111246090084265", "Fog", LoadFogPage)
local SoundsPage = createSidebarButton("13288142767", "Sound", LoadSoundsPage, true)
local AdvancedPage = createSidebarButton("16717281575", "Advanced", LoadAdvancedPage)

-- ESTAS USAM O ESTILO ANTIGO (MANTIDOS SE FOR O CASO)
local VisualSkinsPage = createSidebarButton("11656483170", "Visual Skins", LoadVisualSkinsPage, true) 
local TeleportPage = createSidebarButton("12689978575", "Teleport", LoadTeleportPage) 
local SettingsPage = createSidebarButton("11293977610", "Settings", nil, true)

-- ==========================================
-- POPULATE HIGHLIGHT & VISUAL TABS
-- ==========================================
Library:CreateSection(HighlightPage, "ESP Features")
Library:CreateToggle(HighlightPage, "Esp Players", false, function(state) end)
Library:CreateToggle(HighlightPage, "Esp outline", false, function(state) end)
Library:CreateToggle(HighlightPage, "Beast Highlight", false, function(state) end)
Library:CreateToggle(HighlightPage, "Esp Tracer Line", false, function(state) end)
Library:CreateDropdown(HighlightPage, "Tracer Origin", {"Inferior", "Topo", "Torso"}, "Torso", function(val) end)
Library:CreateToggle(HighlightPage, "Esp Computers", false, function(state) end)
Library:CreateToggle(HighlightPage, "Esp Doors", false, function(state) end)
Library:CreateToggle(HighlightPage, "Esp Freezepods", false, function(state) end)

Library:CreateSection(HighlightPage, "Global Settings")
Library:CreateToggle(HighlightPage, "Only Esp Beast", false, function(state) end)
Library:CreateToggle(HighlightPage, "Hide ESP Names", false, function(state) end)

Library:CreateSection(HighlightPage, "Tracer Control", "Left")
Library:CreateSlider(HighlightPage, "Tracer Thickness", 1, 5, 1, function(val) end)

Library:CreateSection(HighlightPage, "Color Customization", "Left")
Library:CreateColorPicker(HighlightPage, "Beast highlight Color", Color3.fromRGB(0, 255, 255), function(color) end)
Library:CreateColorPicker(HighlightPage, "Survivor Fill Color", Color3.fromRGB(0, 255, 0), function(color) end)
Library:CreateColorPicker(HighlightPage, "Beast Fill Color", Color3.fromRGB(255, 0, 0), function(color) end)
Library:CreateColorPicker(HighlightPage, "Freezepod Fill Color", Color3.fromRGB(0, 255, 255), function(color) end)

Library:CreateSection(HighlightPage, "Outline Customization", "Right")
Library:CreateColorPicker(HighlightPage, "Survivor Outline", Color3.fromRGB(0, 0, 0), function(color) end)
Library:CreateColorPicker(HighlightPage, "Beast Outline", Color3.fromRGB(0, 0, 0), function(color) end)
Library:CreateColorPicker(HighlightPage, "Computer Outline", Color3.fromRGB(0, 0, 0), function(color) end)
Library:CreateColorPicker(HighlightPage, "Freezepod Outline", Color3.fromRGB(0, 0, 0), function(color) end)
Library:CreateColorPicker(HighlightPage, "Door Outline", Color3.fromRGB(0, 0, 0), function(color) end)


Library:CreateSection(VisualPage, "Camera & UI")
Library:CreateSlider(VisualPage, "Fov Changer", 70, 120, 70, function(v) end)
Library:CreateDropdown(VisualPage, "Font Changer", {"Default"}, "Default", function(val) end)
Library:CreateToggle(VisualPage, "stretch screen", false, function(state) end)

-- Dividindo Spoof em duas caixas
Library:CreateSection(VisualPage, "Spoof Settings")
Library:CreateToggle(VisualPage, "Enable Others Spoofing", false, function(state) end)
Library:CreatePlayerDropdown(VisualPage, "Target Player", "Select Player", function(val) end)
Library:CreateInput(VisualPage, "Target Fake Name", "Fake Name", function(val) end)
Library:CreateInput(VisualPage, "Target Fake Level", "100", function(val) end)
Library:CreateDropdown(VisualPage, "Target Fake Icon", {"VIP", "QA", "CON", "Mod", "Dev", "Manager", "MrWindy", "Nenhum"}, "VIP", function(val) end)

Library:CreateSection(VisualPage, "Spoof Actions")
Library:CreateButton(VisualPage, "Apply To Selected Player", function() end)
Library:CreateButton(VisualPage, "Reset Selected Player", function() end)
Library:CreateButton(VisualPage, "Clear All Spoofed Players", function() end)

Library:CreateSection(VisualPage, "Visual Name/Level")
Library:CreateToggle(VisualPage, "Enable Visuals", false, function(state) end)
Library:CreateInput(VisualPage, "Fake Name", LocalPlayer.Name, function(val) end)
Library:CreateInput(VisualPage, "Fake Level", "67", function(val) end)
Library:CreateDropdown(VisualPage, "Select Icon", {"VIP", "QA", "CON", "Mod", "Dev", "Manager", "MrWindy", "Nenhum"}, "VIP", function(val) end)

Library:CreateSection(VisualPage, "Visual Environment")
Library:CreateToggle(VisualPage, "Hide Leaves (Only Homestead)", false, function(state) end)
Library:CreateToggle(VisualPage, "Gray characters", false, function(state) end)
Library:CreateToggle(VisualPage, "Floorbang", false, function(state) end)
Library:CreateToggle(VisualPage, "Wallhop Lines", false, function(state) end)

-- ==========================================
-- ABA DE SETTINGS
-- ==========================================
Library:CreateSection(SettingsPage, "Menu Configuration")

local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(1, -2, 0, 40)
KeyFrame.Position = UDim2.new(0, 1, 0, 0)
KeyFrame.BackgroundColor3 = Color3.new(0, 0, 0)
KeyFrame.BackgroundTransparency = 0.45
KeyFrame.Parent = SettingsPage
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 6)
local strKey = Instance.new("UIStroke")
strKey.Color = Color3.fromRGB(40, 40, 40)
strKey.Thickness = 1
strKey.Parent = KeyFrame

local KeyLabelPage = Instance.new("TextLabel")
KeyLabelPage.Text = "Menu Keybind:"
KeyLabelPage.Font = Theme.Font
KeyLabelPage.TextSize = 12
KeyLabelPage.TextColor3 = Theme.Text
KeyLabelPage.Size = UDim2.new(0, 100, 1, 0)
KeyLabelPage.Position = UDim2.new(0, 10, 0, 0)
KeyLabelPage.BackgroundTransparency = 1
KeyLabelPage.TextXAlignment = Enum.TextXAlignment.Left
KeyLabelPage.Parent = KeyFrame

local KeyBtnPage = Instance.new("TextButton")
KeyBtnPage.Parent = KeyFrame
KeyBtnPage.Text = CurrentKey.Name
KeyBtnPage.Size = UDim2.new(0, 60, 0, 22)
KeyBtnPage.Position = UDim2.new(1, -70, 0.5, -11)
KeyBtnPage.BackgroundColor3 = Color3.new(0, 0, 0)
KeyBtnPage.BackgroundTransparency = 0.45
KeyBtnPage.TextColor3 = Theme.Accent
Instance.new("UICorner", KeyBtnPage).CornerRadius = UDim.new(0, 4)
local kbStr = Instance.new("UIStroke", KeyBtnPage)
kbStr.Color = Color3.fromRGB(40, 40, 40)

KeyBtnPage.MouseButton1Click:Connect(function() 
    KeyBtnPage.Text = "..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            CurrentKey = input.KeyCode
            UserConfigs.ToggleKey = CurrentKey.Name
            KeyBtnPage.Text = CurrentKey.Name
            if conn then conn:Disconnect() end
        end
    end)
end)

Library:CreateSection(SettingsPage, "Configuration Management")

local CfgNameTitle = Instance.new("TextLabel")
CfgNameTitle.Text = "Config Name:"
CfgNameTitle.Font = Enum.Font.GothamBold
CfgNameTitle.TextSize = 12
CfgNameTitle.TextColor3 = Theme.Text
CfgNameTitle.Size = UDim2.new(1, -10, 0, 20)
CfgNameTitle.BackgroundTransparency = 1
CfgNameTitle.TextXAlignment = Enum.TextXAlignment.Left
CfgNameTitle.Parent = SettingsPage

local CfgInputBg = Instance.new("Frame")
CfgInputBg.Size = UDim2.new(1, -2, 0, 30)
CfgInputBg.Position = UDim2.new(0, 1, 0, 0)
CfgInputBg.BackgroundColor3 = Color3.new(0, 0, 0)
CfgInputBg.BackgroundTransparency = 0.45
CfgInputBg.BorderSizePixel = 0
CfgInputBg.Parent = SettingsPage
Instance.new("UICorner", CfgInputBg).CornerRadius = UDim.new(0, 4)
local ciStr = Instance.new("UIStroke", CfgInputBg)
ciStr.Color = Color3.fromRGB(40, 40, 40)

local CfgInputBox = Instance.new("TextBox")
CfgInputBox.Size = UDim2.new(1, -20, 1, 0)
CfgInputBox.Position = UDim2.new(0, 10, 0, 0)
CfgInputBox.BackgroundTransparency = 1
CfgInputBox.Text = CurrentConfigName
CfgInputBox.PlaceholderText = "Type config name..."
CfgInputBox.TextColor3 = Theme.Text
CfgInputBox.Font = Enum.Font.Gotham
CfgInputBox.TextSize = 12
CfgInputBox.TextXAlignment = Enum.TextXAlignment.Left
CfgInputBox.ClearTextOnFocus = false
CfgInputBox.Parent = CfgInputBg

local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(1, 0, 0, 60)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = SettingsPage

local SaveFileBtn = Instance.new("TextButton")
SaveFileBtn.Size = UDim2.new(0.32, 0, 0, 30)
SaveFileBtn.Position = UDim2.new(0, 0, 0, 0)
SaveFileBtn.BackgroundColor3 = Color3.new(0, 0, 0)
SaveFileBtn.BackgroundTransparency = 0.45
SaveFileBtn.Text = "Save Config"
SaveFileBtn.Font = Enum.Font.GothamBold
SaveFileBtn.TextSize = 11
SaveFileBtn.TextColor3 = Theme.Text
SaveFileBtn.Parent = BtnContainer
Instance.new("UICorner", SaveFileBtn).CornerRadius = UDim.new(0, 4)
local sfStr = Instance.new("UIStroke", SaveFileBtn)
sfStr.Color = Color3.fromRGB(40, 40, 40)

local LoadFileBtn = Instance.new("TextButton")
LoadFileBtn.Size = UDim2.new(0.32, 0, 0, 30)
LoadFileBtn.Position = UDim2.new(0.34, 0, 0, 0)
LoadFileBtn.BackgroundColor3 = Color3.new(0, 0, 0)
LoadFileBtn.BackgroundTransparency = 0.45
LoadFileBtn.Text = "Load Config"
LoadFileBtn.Font = Enum.Font.GothamBold
LoadFileBtn.TextSize = 11
LoadFileBtn.TextColor3 = Theme.Text
LoadFileBtn.Parent = BtnContainer
Instance.new("UICorner", LoadFileBtn).CornerRadius = UDim.new(0, 4)
local lfStr = Instance.new("UIStroke", LoadFileBtn)
lfStr.Color = Color3.fromRGB(40, 40, 40)

local DefaultFileBtn = Instance.new("TextButton")
DefaultFileBtn.Size = UDim2.new(0.32, 0, 0, 30)
DefaultFileBtn.Position = UDim2.new(0.68, 0, 0, 0)
DefaultFileBtn.BackgroundColor3 = Color3.new(0, 0, 0)
DefaultFileBtn.BackgroundTransparency = 0.45
DefaultFileBtn.Text = "Set as Default"
DefaultFileBtn.Font = Enum.Font.GothamBold
DefaultFileBtn.TextSize = 11
DefaultFileBtn.TextColor3 = Theme.Text
DefaultFileBtn.Parent = BtnContainer
Instance.new("UICorner", DefaultFileBtn).CornerRadius = UDim.new(0, 4)
local dfStr = Instance.new("UIStroke", DefaultFileBtn)
dfStr.Color = Color3.fromRGB(40, 40, 40)

local ResetAllBtn = Instance.new("TextButton")
ResetAllBtn.Size = UDim2.new(1, -2, 0, 25)
ResetAllBtn.Position = UDim2.new(0, 1, 0, 35)
ResetAllBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
ResetAllBtn.BackgroundTransparency = 0.2
ResetAllBtn.Text = "Reset to Default"
ResetAllBtn.Font = Enum.Font.GothamBold
ResetAllBtn.TextSize = 11
ResetAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetAllBtn.Parent = BtnContainer
Instance.new("UICorner", ResetAllBtn).CornerRadius = UDim.new(0, 4)
local raStr = Instance.new("UIStroke", ResetAllBtn)
raStr.Color = Color3.fromRGB(60, 20, 20)

local AvailableTitle = Instance.new("TextLabel")
AvailableTitle.Text = "Available Configs:"
AvailableTitle.Font = Enum.Font.GothamBold
AvailableTitle.TextSize = 12
AvailableTitle.TextColor3 = Theme.Text
AvailableTitle.Size = UDim2.new(1, -10, 0, 30)
AvailableTitle.BackgroundTransparency = 1
AvailableTitle.TextXAlignment = Enum.TextXAlignment.Left
AvailableTitle.Parent = SettingsPage

local ConfigListFrame = Instance.new("ScrollingFrame")
ConfigListFrame.Size = UDim2.new(1, -2, 0, 100)
ConfigListFrame.Position = UDim2.new(0, 1, 0, 0)
ConfigListFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ConfigListFrame.BackgroundTransparency = 0.45
ConfigListFrame.BorderSizePixel = 0
ConfigListFrame.ScrollBarThickness = 2
ConfigListFrame.ScrollBarImageColor3 = Theme.Accent
ConfigListFrame.Parent = SettingsPage
Instance.new("UICorner", ConfigListFrame).CornerRadius = UDim.new(0, 4)
local cfStr = Instance.new("UIStroke", ConfigListFrame)
cfStr.Color = Color3.fromRGB(40, 40, 40)

local CfgListLayout = Instance.new("UIListLayout")
CfgListLayout.Padding = UDim.new(0, 5)
CfgListLayout.SortOrder = Enum.SortOrder.LayoutOrder
CfgListLayout.Parent = ConfigListFrame

local CfgListPad = Instance.new("UIPadding")
CfgListPad.PaddingTop = UDim.new(0, 5)
CfgListPad.PaddingLeft = UDim.new(0, 10)
CfgListPad.PaddingBottom = UDim.new(0, 5)
CfgListPad.Parent = ConfigListFrame

local function RefreshConfigList()
    for _, child in ipairs(ConfigListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local defName = GetDefaultConfigName()
    
    pcall(function()
        if listfiles and isfolder(ConfigFolder) then
            local files = listfiles(ConfigFolder)
            for _, path in ipairs(files) do
                if path:match("%.json$") then
                    local justName = path:match("([^/\\]+)%.json$")
                    if justName then
                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(1, -10, 0, 20)
                        btn.BackgroundTransparency = 1
                        btn.Font = Enum.Font.GothamBold
                        btn.TextSize = 12
                        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                        btn.TextXAlignment = Enum.TextXAlignment.Left
                        
                        if justName == defName then
                            btn.Text = justName .. " (default config)"
                        else
                            btn.Text = justName
                        end
                        
                        btn.Parent = ConfigListFrame
                        
                        btn.MouseButton1Click:Connect(function()
                            CfgInputBox.Text = justName
                        end)
                        btn.MouseEnter:Connect(function() btn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
                        btn.MouseLeave:Connect(function() btn.TextColor3 = Color3.fromRGB(200, 200, 200) end)
                    end
                end
            end
        end
    end)
    
    local items = 0
    for _, c in ipairs(ConfigListFrame:GetChildren()) do if c:IsA("TextButton") then items = items + 1 end end
    ConfigListFrame.CanvasSize = UDim2.new(0, 0, 0, items * 25)
end
RefreshConfigList()

SaveFileBtn.MouseButton1Click:Connect(function()
    local name = CfgInputBox.Text
    if name == "" then name = "config_1" end
    SaveConfigs(name)
    RefreshConfigList()
    SendNotification("Config '" .. name .. "' Saved!", 3)
end)

LoadFileBtn.MouseButton1Click:Connect(function()
    local name = CfgInputBox.Text
    if name == "" then return end
    LoadConfigs(name)
    SendNotification("Loaded! Re-execute script to apply.", 4)
end)

DefaultFileBtn.MouseButton1Click:Connect(function()
    local name = CfgInputBox.Text
    if name == "" then return end
    SetDefaultConfig(name)
    RefreshConfigList()
    SendNotification("Set '" .. name .. "' as default config.", 3)
end)

ResetAllBtn.MouseButton1Click:Connect(function()
    ResetAllConfigs()
    RefreshConfigList()
    CfgInputBox.Text = "config_1"
    SendNotification("All Configs Wiped! Please re-execute script.", 4)
end)

Library:CreateButton(SettingsPage, "Server Rejoin", function()
    SendNotification("Server Rejoin triggered (Framework only)", 2)
end)

Library:CreateButton(SettingsPage, "Random Servers", function()
    SendNotification("Server Hop triggered (Framework only)", 2)
end)

-- ==========================================
-- MODAL DE INFO (Cards) Restaurado
-- ==========================================
local function createInfoCard(titleText, items)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -15, 0, 40 + (#items * 25))
    Card.BackgroundColor3 = Color3.new(0, 0, 0)
    Card.BackgroundTransparency = 0.45
    Card.BorderSizePixel = 0
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

    local Stroke = Instance.new("UIStroke", Card)
    Stroke.Color = Color3.fromRGB(40, 40, 40)
    Stroke.Thickness = 1
    
    local TitleLabel = Instance.new("TextLabel", Card)
    TitleLabel.Size = UDim2.new(1, -30, 0, 30)
    TitleLabel.Position = UDim2.new(0, 20, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = titleText
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.TextSize = 12
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local AccentBar = Instance.new("Frame", Card)
    AccentBar.Size = UDim2.new(0, 3, 0, 14)
    AccentBar.Position = UDim2.new(0, 10, 0, 8)
    AccentBar.BackgroundColor3 = Theme.Accent
    AccentBar.BorderSizePixel = 0
    Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)
    
    local Sep = Instance.new("Frame", Card)
    Sep.Size = UDim2.new(1, -20, 0, 1)
    Sep.Position = UDim2.new(0, 10, 0, 30)
    Sep.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep.BorderSizePixel = 0

    local dynamicLabels = {}

    for i, field in ipairs(items) do
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -20, 0, 20)
        Label.Position = UDim2.new(0, 15, 0, 35 + ((i - 1) * 25))
        Label.BackgroundTransparency = 1
        Label.RichText = true
        Label.Text = field.Default
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 12
        Label.TextColor3 = Theme.Text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Card

        if field.Id then
            dynamicLabels[field.Id] = Label
        end
    end
    return Card, dynamicLabels
end

local creditsCard, _ = createInfoCard("CREDITS", {
    {Default = "<b>UI Framework Extracted</b>"},
    {Default = "<b>Ready for custom scripts!</b>"}
})
creditsCard.Parent = InfoScroll

local playerCard, playerLabels = createInfoCard("PLAYER INFO", {
    {Id = "FPS", Default = "<b>FPS:</b> <font color='rgb(150,150,150)'>...</font>"},
    {Id = "Ping", Default = "<b>Ping:</b> <font color='rgb(150,150,150)'>... ms</font>"},
    {Id = "Exec", Default = "<b>Executor:</b> <font color='rgb(150,150,150)'>" .. (identifyexecutor and identifyexecutor() or "Unknown") .. "</font>"}
})
playerCard.Parent = InfoScroll

local serverCard, serverLabels = createInfoCard("SERVER INFO", {
    {Id = "Region", Default = "<b>Region:</b> <font color='rgb(150,150,150)'>Fetching...</font>"},
    {Id = "Players", Default = "<b>Players:</b> <font color='rgb(150,150,150)'>...</font>"},
    {Id = "Max", Default = "<b>Max Players:</b> <font color='rgb(150,150,150)'>" .. tostring(Players.MaxPlayers) .. "</font>"}
})
serverCard.Parent = InfoScroll

-- Atualização Dinâmica da Rolagem
InfoLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    InfoScroll.CanvasSize = UDim2.new(0, 0, 0, InfoLayout.AbsoluteContentSize.Y + 20)
end)

local frames = 0
local lastUpdate = tick()

task.spawn(function()
    local s, r = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("http://ip-api.com/json/"))
    end)
    local reg = "Unknown"
    if s and r and r.countryCode then
        reg = r.countryCode
    end
    if serverLabels["Region"] then
        serverLabels["Region"].Text = "<b>Region:</b> <font color='rgb(150,150,150)'>" .. reg .. "</font>"
    end
end)

RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local currentTick = tick()
    if currentTick - lastUpdate >= 1 then
        local fps = frames
        frames = 0
        lastUpdate = currentTick
        
        if playerLabels["FPS"] then
            playerLabels["FPS"].Text = "<b>FPS:</b> <font color='rgb(150,150,150)'>" .. tostring(fps) .. "</font>"
        end
        
        local pingVal = 0
        pcall(function()
            pingVal = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if playerLabels["Ping"] then
            playerLabels["Ping"].Text = "<b>Ping:</b> <font color='rgb(150,150,150)'>" .. tostring(pingVal) .. " ms</font>"
        end

        if serverLabels["Players"] then
            serverLabels["Players"].Text = "<b>Players:</b> <font color='rgb(150,150,150)'>" .. tostring(#Players:GetPlayers()) .. "</font>"
        end
    end
end)

if tabs[1] then 
	tabs[1].Page.Visible = true
	tabs[1].Indicator.BackgroundTransparency = 0
	tabs[1].Label.TextTransparency = 0
	tabs[1].Icon.ImageTransparency = 0
end

ScreenGui.Enabled = true
MainFrame.Visible = true
OpenButton.Visible = false
