return function(env)
    local Library = env.Library
    local Page = env.Page

    Library:CreateSection(Page, "Teleport", "Left")

    Library:CreateLabel(Page, "Under Maintenance")
    Library:CreateLabel(Page, "This module is currently being rewritten.")
    Library:CreateLabel(Page, "Several systems are being optimized")
    Library:CreateLabel(Page, "to improve stability and performance.")
    Library:CreateLabel(Page, "")
    Library:CreateLabel(Page, "Expected to return in a future update.")
end
