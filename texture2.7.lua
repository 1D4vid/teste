local function LoadTexturesPage(pageObj)
    local s, code = pcall(function() return game:HttpGet("SUA_URL_DO_RAW_AQUI/textures2.7.lua") end)
    if s and code then
        loadstring(code)()({
            Library = Library,
            Page = pageObj,
            Workspace = Workspace,
            Players = Players,
            LocalPlayer = LocalPlayer,
            RunService = RunService,
            TweenService = TweenService,
            UserInputService = UserInputService,
            Theme = Theme,
            UserConfigs = UserConfigs,
            GetParentTarget = GetParentTarget,
            MobileCrosshair = MobileCrosshair,
            PCSoftwareCursor = PCSoftwareCursor,
            SetPCCursorActive = SetPCCursorActive,
            UpdateCursorSizes = UpdateCursorSizes
        })
    else
        warn("Failed to load Textures Page")
    end
end
