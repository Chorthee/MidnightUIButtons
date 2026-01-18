local AddonName = "MidnightUIButtons"
local Container
local SettingsCategory -- Store the category object here

-- 1. Default Settings Data
local function GetDefaultSettings()
    return {
        locked = false, 
        hideBG = false, 
        scale = 1.0, 
        fontSize = 16,
        pos = {"CENTER", 0, 0},
        trayColor = {0, 0, 0, 0.7},
        btnColor = {0.1, 0.1, 0.1, 0.9},
        textColor = {1, 1, 1, 1}
    }
end

-- 2. Database & Profile Helpers
local function GetCharKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

local function InitDB()
    MidnightUIButtonsDB = MidnightUIButtonsDB or {}
    MidnightUIButtonsDB.profiles = MidnightUIButtonsDB.profiles or { ["Default"] = GetDefaultSettings() }
    MidnightUIButtonsDB.charToProfile = MidnightUIButtonsDB.charToProfile or {}
    
    local charKey = GetCharKey()
    if not MidnightUIButtonsDB.charToProfile[charKey] then
        MidnightUIButtonsDB.charToProfile[charKey] = "Default"
    end
end

local function GetCfg()
    if not MidnightUIButtonsDB or not MidnightUIButtonsDB.charToProfile then return GetDefaultSettings() end
    local charKey = GetCharKey()
    local profileName = MidnightUIButtonsDB.charToProfile[charKey] or "Default"
    if not MidnightUIButtonsDB.profiles[profileName] then
        MidnightUIButtonsDB.profiles[profileName] = GetDefaultSettings()
    end
    return MidnightUIButtonsDB.profiles[profileName]
end

-- 3. Update Visuals
local function UpdateAppearance()
    if not Container then return end
    local cfg = GetCfg()
    Container:SetScale(cfg.scale)
    Container:ClearAllPoints()
    Container:SetPoint(cfg.pos[1], cfg.pos[2], cfg.pos[3])
    Container.bg:SetAlpha(cfg.hideBG and 0 or 1)
    Container.bg:SetColorTexture(unpack(cfg.trayColor))
    
    local function StyleButton(btn)
        if not btn or not btn.text then return end
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", cfg.fontSize, "OUTLINE")
        btn.text:SetTextColor(unpack(cfg.textColor))
        btn.bg:SetColorTexture(unpack(cfg.btnColor))
    end
    for i = 1, 3 do StyleButton(_G["MDSecureBtn_"..i]) end
    StyleButton(_G["MDNormalBtn_A"])
end

-- 4. Popups
StaticPopupDialogs["MIDNIGHT_RELOAD_CONFIRM"] = {
    text = "This action requires a UI Reload. Do you want to continue?",
    button1 = "Yes", button2 = "No",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["MIDNIGHT_DELETE_CONFIRM"] = {
    text = "Are you sure you want to permanently delete the profile: |cffff0000%s|r?",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function(self, data)
        if data and MidnightUIButtonsDB.profiles[data] then
            MidnightUIButtonsDB.profiles[data] = nil
            ReloadUI()
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- 5. Tab Logic & Options
local function RegisterOptions()
    local panel = CreateFrame("Frame", "MidnightOptionsPanel", UIParent)
    panel.name = "Midnight UI Buttons"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Midnight UI Buttons (v1.1.38)")

    local visualTab = CreateFrame("Frame", nil, panel)
    visualTab:SetAllPoints()
    local profileTab = CreateFrame("Frame", nil, panel)
    profileTab:SetAllPoints()

    local tabs = {}
    local function ShowTab(tabID)
        visualTab:SetShown(tabID == 1)
        profileTab:SetShown(tabID == 2)
        for id, btn in ipairs(tabs) do
            if id == tabID then
                btn:SetBackdropColor(0.2, 0.2, 0.2, 1)
                btn.text:SetTextColor(1, 0.82, 0)
            else
                btn:SetBackdropColor(0, 0, 0, 0.5)
                btn.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end

    local function CreateTabBtn(id, text, xOff)
        local btn = CreateFrame("Button", nil, panel, "BackdropTemplate")
        btn:SetSize(120, 25); btn:SetPoint("TOPLEFT", 16 + xOff, -45)
        btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", tile = true, tileSize = 16, edgeSize = 1})
        btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER"); btn.text:SetText(text)
        btn:SetScript("OnClick", function() ShowTab(id) end)
        tabs[id] = btn
        return btn
    end

    CreateTabBtn(1, "Visual Settings", 0); CreateTabBtn(2, "Profiles", 125); ShowTab(1)

    --- VISUAL TAB ---
    local function CreateCheck(label, var, yOff)
        local cb = CreateFrame("CheckButton", nil, visualTab, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOff)
        if cb.Text then cb.Text:SetText("") end
        local customLabel = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        customLabel:SetPoint("LEFT", cb, "RIGHT", 8, 0); customLabel:SetScale(1.2); customLabel:SetText(label)
        cb:SetChecked(GetCfg()[var])
        cb:SetScript("OnClick", function(self) GetCfg()[var] = self:GetChecked(); UpdateAppearance() end)
    end

    local function CreateSlider(label, min, max, step, var, isPercent, yOffset)
        local sliderName = "MidnightSlider_"..var
        local s = CreateFrame("Slider", sliderName, visualTab, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20, yOffset)
        s:SetMinMaxValues(min, max); s:SetValueStep(step); s:SetValue(GetCfg()[var]); s:SetWidth(180)
        local text = _G[sliderName.."Text"]
        if text then text:SetScale(1.2); text:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 10); text:SetText(label) end
        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valText:SetPoint("LEFT", s, "RIGHT", 15, 0); valText:SetScale(1.2)
        s:SetScript("OnValueChanged", function(_, value)
            GetCfg()[var] = value
            valText:SetText(isPercent and string.format("%d%%", math.floor(value * 100 + 0.5)) or math.floor(value + 0.5) .. "pt")
            UpdateAppearance()
        end)
        valText:SetText(isPercent and string.format("%d%%", math.floor(GetCfg()[var] * 100 + 0.5)) or math.floor(GetCfg()[var] + 0.5) .. "pt")
    end

    CreateCheck("Lock Tray Position", "locked", -100)
    CreateCheck("Hide Tray Background", "hideBG", -140)
    CreateSlider("Button Scale", 0.5, 2.0, 0.05, "scale", true, -210)
    CreateSlider("Font Size", 10, 30, 1, "fontSize", false, -280)

    --- PROFILE TAB ---
    local pY = -100
    local selectLabel = profileTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectLabel:SetPoint("TOPLEFT", 16, pY); selectLabel:SetScale(1.2); selectLabel:SetText("Active Profile:")

    local dropdown = CreateFrame("Frame", "MidnightSelectDropdown", profileTab, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", selectLabel, "RIGHT", -10, -3)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_Initialize(dropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        local current = MidnightUIButtonsDB.charToProfile[GetCharKey()]
        for name in pairs(MidnightUIButtonsDB.profiles) do
            info.text = name; info.value = name; info.checked = (name == current)
            info.func = function(self) MidnightUIButtonsDB.charToProfile[GetCharKey()] = self.value; StaticPopup_Show("MIDNIGHT_RELOAD_CONFIRM") end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(dropdown, MidnightUIButtonsDB.charToProfile[GetCharKey()])

    local deleteLabel = profileTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deleteLabel:SetPoint("TOPLEFT", 16, pY - 50); deleteLabel:SetScale(1.2); deleteLabel:SetText("Delete Profile:")

    local delDropdown = CreateFrame("Frame", "MidnightDeleteDropdown", profileTab, "UIDropDownMenuTemplate")
    delDropdown:SetPoint("LEFT", deleteLabel, "RIGHT", -10, -3)
    UIDropDownMenu_SetWidth(delDropdown, 150)
    local targetToDelete = nil
    UIDropDownMenu_Initialize(delDropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        local current = MidnightUIButtonsDB.charToProfile[GetCharKey()]
        for name in pairs(MidnightUIButtonsDB.profiles) do
            if name ~= "Default" and name ~= current then
                info.text = name; info.value = name; info.func = function(self) targetToDelete = self.value; UIDropDownMenu_SetText(delDropdown, self.value) end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    UIDropDownMenu_SetText(delDropdown, "Select...")

    local delBtn = CreateFrame("Button", nil, profileTab, "UIPanelButtonTemplate")
    delBtn:SetSize(80, 22); delBtn:SetPoint("LEFT", delDropdown, "RIGHT", -10, 3); delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function() if targetToDelete then StaticPopup_Show("MIDNIGHT_DELETE_CONFIRM", targetToDelete, nil, targetToDelete) end end)

    local createLabel = profileTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    createLabel:SetPoint("TOPLEFT", 16, pY - 100); createLabel:SetScale(1.2); createLabel:SetText("New Profile Name:")

    local editBox = CreateFrame("EditBox", nil, profileTab, "InputBoxTemplate")
    editBox:SetSize(150, 20); editBox:SetPoint("LEFT", createLabel, "RIGHT", 15, 0); editBox:SetAutoFocus(false)

    local addBtn = CreateFrame("Button", nil, profileTab, "UIPanelButtonTemplate")
    addBtn:SetSize(100, 22); addBtn:SetPoint("LEFT", editBox, "RIGHT", 10, 0); addBtn:SetText("Add Profile")
    addBtn:SetScript("OnClick", function()
        local name = editBox:GetText()
        if name and name ~= "" and not MidnightUIButtonsDB.profiles[name] then
            MidnightUIButtonsDB.profiles[name] = GetDefaultSettings()
            MidnightUIButtonsDB.charToProfile[GetCharKey()] = name
            StaticPopup_Show("MIDNIGHT_RELOAD_CONFIRM")
        end
    end)

    local resetBtn = CreateFrame("Button", nil, profileTab, "UIPanelButtonTemplate")
    resetBtn:SetSize(160, 25); resetBtn:SetPoint("TOPLEFT", 16, pY - 180); resetBtn:SetText("Reset Current Profile")
    resetBtn:SetScript("OnClick", function() StaticPopup_Show("MIDNIGHT_RELOAD_CONFIRM") end)

    -- API Registration
    if Settings and Settings.RegisterCanvasLayoutCategory then
        SettingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(SettingsCategory)
    else
        InterfaceOptions_AddCategory(panel)
    end

    -- Slash Commands
    SLASH_MIDNIGHT1 = "/midnight"; SLASH_MIDNIGHT2 = "/mb"
    SlashCmdList["MIDNIGHT"] = function()
        if Settings and Settings.OpenToCategory then
            -- Use the ID of the category object we registered
            Settings.OpenToCategory(SettingsCategory:GetID())
        else
            InterfaceOptionsFrame_OpenToCategory(panel)
        end
    end
end

-- 6. Main UI & Load
local function CreateButtonUI()
    local cfg = GetCfg()
    Container = CreateFrame("Frame", "MidnightUI_MainContainer", UIParent)
    Container:SetSize(136, 36)
    Container:SetMovable(true); Container:EnableMouse(true); Container:SetClampedToScreen(true)
    Container.bg = Container:CreateTexture(nil, "BACKGROUND")
    Container.bg:SetAllPoints()
    Container:RegisterForDrag("LeftButton")
    Container:SetScript("OnDragStart", function(self) if not GetCfg().locked and not InCombatLockdown() then self:StartMoving() end end)
    Container:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local p, _, _, x, y = self:GetPoint(); GetCfg().pos = {p, x, y} end)

    local function SetupButton(btn, textStr)
        btn:SetSize(30, 30); btn:RegisterForClicks("AnyUp", "AnyDown")
        btn.bg = btn:CreateTexture(nil, "BACKGROUND"); btn.bg:SetAllPoints()
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetPoint("CENTER")
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", cfg.fontSize or 16, "OUTLINE")
        btn.text:SetTextColor(unpack(cfg.textColor))
        btn.text:SetText(textStr)
        btn:SetScript("OnEnter", function(self) self:SetAlpha(0.6) end)
        btn:SetScript("OnLeave", function(self) self:SetAlpha(1.0) end)
    end

    local secureData = { { "R", "/reload", 0 }, { "E", "/quit", 1 }, { "L", "/logout", 2 } }
    for i, data in ipairs(secureData) do
        local btn = CreateFrame("Button", "MDSecureBtn_"..i, Container, "SecureActionButtonTemplate")
        btn:SetPoint("LEFT", 3 + (data[3] * 33), 0)
        btn:SetAttribute("type", "macro"); btn:SetAttribute("macrotext", data[2])
        SetupButton(btn, data[1])
    end

    local btnA = CreateFrame("Button", "MDNormalBtn_A", Container)
    btnA:SetPoint("LEFT", 3 + (3 * 33), 0)
    SetupButton(btnA, "A")
    btnA:SetScript("OnClick", function() if AddonList:IsShown() then AddonList:Hide() else AddonList:Show() end end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
    if name == AddonName then
        InitDB(); CreateButtonUI(); RegisterOptions(); UpdateAppearance()
    end
end)
