return function(env)
    -- Importando apenas as variáveis necessárias para a interface
    local Library = env.Library
    local Page = env.Page
    local Theme = env.Theme
    local GetParentTarget = env.GetParentTarget

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

    -- =========================================================================
    -- MENSAGEM DE MANUTENÇÃO (Coluna Esquerda)
    -- =========================================================================
    Library:CreateSection(Page, "Aviso / Warning", "Left")

    local parent = GetParentTarget(Page)
    if parent then
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 120)
        Card.BackgroundTransparency = 1
        Card.Parent = parent

        local Msg = Instance.new("TextLabel")
        Msg.Size = UDim2.new(1, 0, 1, 0)
        Msg.BackgroundTransparency = 1
        Msg.Text = " CATEGORIA EM MANUTENÇÃO\n\nEsta seção está temporariamente desativada para ajustes técnicos e melhorias no desempenho.\n\ne eu odeio escola."
        Msg.TextColor3 = Theme.Accent or Color3.fromRGB(235, 94, 85)
        Msg.Font = Theme.Font or Enum.Font.GothamBold
        Msg.TextSize = 12
        Msg.TextWrapped = true
        Msg.TextXAlignment = Enum.TextXAlignment.Center
        Msg.TextYAlignment = Enum.TextYAlignment.Center
        Msg.Parent = Card
    end
end
