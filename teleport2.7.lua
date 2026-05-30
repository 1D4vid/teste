return function(env)
    -- Importando apenas o que é necessário para renderizar o aviso
    local Page = env.Page
    local Theme = env.Theme

    -- Limpa os componentes anteriores para liberar a tela inteira
    for _, child in ipairs(Page:GetChildren()) do
        if not child:IsA("Attribute") then
            child:Destroy()
        end
    end

    -- Container para alinhar tudo ao centro da tela
    local MaintenanceContainer = Instance.new("Frame")
    MaintenanceContainer.Name = "MaintenanceContainer"
    MaintenanceContainer.Size = UDim2.new(1, 0, 1, 0)
    MaintenanceContainer.BackgroundTransparency = 1
    MaintenanceContainer.Parent = Page

    local CenterLayout = Instance.new("UIListLayout")
    CenterLayout.FillDirection = Enum.FillDirection.Vertical
    CenterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    CenterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    CenterLayout.Padding = UDim.new(0, 15)
    CenterLayout.Parent = MaintenanceContainer

    -- Card centralizado
    local Card = Instance.new("Frame")
    Card.Name = "Card"
    Card.Size = UDim2.new(0.9, 0, 0, 220)
    Card.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    Card.BackgroundTransparency = 0.15
    Card.Parent = MaintenanceContainer

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card

    -- Borda que se adapta à cor principal do seu tema (Theme.Accent)
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.Accent or Color3.fromRGB(235, 94, 85)
    CardStroke.Thickness = 1.5
    CardStroke.Transparency = 0.4
    CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    CardStroke.Parent = Card

    local CardLayout = Instance.new("UIListLayout")
    CardLayout.FillDirection = Enum.FillDirection.Vertical
    CardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    CardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    CardLayout.Padding = UDim.new(0, 12)
    CardLayout.Parent = Card

    local CardPadding = Instance.new("UIPadding")
    CardPadding.PaddingLeft = UDim.new(0, 25)
    CardPadding.PaddingRight = UDim.new(0, 25)
    CardPadding.Parent = Card

    -- 1. Ícone temático (representando teleporte / coordenadas)
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(1, 0, 0, 35)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🌀"
    Icon.TextSize = 34
    Icon.Font = Theme.Font or Enum.Font.GothamBold
    Icon.Parent = Card

    -- 2. Título amigável
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundTransparency = 1
    Title.Text = "Aba de Teleportes em manutenção"
    Title.TextColor3 = Theme.TextLight or Color3.fromRGB(255, 255, 255)
    Title.Font = Theme.Font or Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = Card

    -- 3. Mensagem natural
    local Body = Instance.new("TextLabel")
    Body.Size = UDim2.new(1, 0, 0, 75)
    Body.BackgroundTransparency = 1
    Body.Text = "reescrevendo o sistema de teleportes do zero.\n\naguarde!"
    Body.TextColor3 = Theme.TextDark or Color3.fromRGB(180, 180, 180)
    Body.Font = Theme.Font or Enum.Font.GothamMedium
    Body.TextSize = 11
    Body.TextWrapped = true
    Body.Parent = Card

    -- 4. Status Badge
    local StatusBadge = Instance.new("Frame")
    StatusBadge.Size = UDim2.new(0, 150, 0, 22)
    StatusBadge.BackgroundColor3 = Theme.Accent or Color3.fromRGB(235, 94, 85)
    StatusBadge.BackgroundTransparency = 0.85
    StatusBadge.Parent = Card

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 6)
    BadgeCorner.Parent = StatusBadge

    local BadgeStroke = Instance.new("UIStroke")
    BadgeStroke.Color = Theme.Accent or Color3.fromRGB(235, 94, 85)
    BadgeStroke.Thickness = 1
    BadgeStroke.Transparency = 0.6
    BadgeStroke.Parent = StatusBadge

    local BadgeText = Instance.new("TextLabel")
    BadgeText.Size = UDim2.new(1, 0, 1, 0)
    BadgeText.BackgroundTransparency = 1
    BadgeText.Text = "Buscando bypass seguro..."
    BadgeText.TextColor3 = Theme.Accent or Color3.fromRGB(255, 255, 255)
    BadgeText.Font = Theme.Font or Enum.Font.GothamBold
    BadgeText.TextSize = 9
    BadgeText.Parent = StatusBadge
end
