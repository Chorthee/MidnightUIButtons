local AddonName = "MidnightUIButtons"
local Buttons = {}
local Container

-- 1. Database & Defaults
local function InitDB()
    local defaults = {
        locked = false, 
        hideBG = false, 
        scale = 1.0, 
        fontSize = 16,
        pos = {"CENTER", 0, 0},
        trayColor = {0, 0, 0, 0.7},
        btnColor = {0.1, 0.1, 0.1, 0.9},
        textColor = {1, 1, 1, 1}
    }
    if not MidnightUIButtonsDB then MidnightUIButtonsDB = defaults 
    else
        for k, v in pairs(defaults) do
            if MidnightUIButtonsDB[k] == nil then MidnightUIButtonsDB[k] = v end
        end
    end
end

-- 2. Update Visuals
local function UpdateAppearance()
    if not Container then return end
    Container:SetScale(MidnightUIButtonsDB.scale)
    
    -- Tray Background Visibility
    Container.bg:SetAlpha(MidnightUIButtonsDB.hideBG and 0 or 1)
    Container.bg:SetColorTexture(unpack(MidnightUIButtonsDB.trayColor))
    
    local function StyleButton(btn)
        if not btn or not btn.text then return end
        
        -- Apply Text Settings
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", MidnightUIButtonsDB.fontSize, "OUTLINE")
        btn.text:SetTextColor(unpack(MidnightUIButtonsDB.textColor))
        
        -- Apply Background Color
        btn.bg:SetColorTexture(unpack(MidnightUIButtonsDB.btnColor))
    end

    for i = 1, 3 do StyleButton(_G["MDSecureBtn_"..i]) end
    StyleButton(_G["MDNormalBtn_A"])
end

-- 3. Register Options
local function RegisterOptions()
    local panel = CreateFrame("Frame", "MidnightOptionsPanel", UIParent)
    panel.name = "Midnight UI Buttons"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Midnight UI Buttons")

    local function CreateCheck(name, label, var, yOff)
        local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOff)
        local labelText = _G[cb:GetName().."Text"]
        labelText:SetFontObject("GameFontNormal")
        labelText:SetScale(1.2)
        labelText:SetText(label)
        cb:SetChecked(MidnightUIButtonsDB[var])
        cb:SetScript("OnClick", function(self)
            MidnightUIButtonsDB[var] = self:GetChecked()
            UpdateAppearance()
        end)
    end

    local function CreateSlider(name, label, min, max, step, var, isPercent, yOffset)
        local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20, yOffset)
        s:SetMinMaxValues(min, max)
        s:SetValueStep(step)
        s:SetObeyStepOnDrag(true)
        s:SetValue(MidnightUIButtonsDB[var])
        s:SetWidth(180)
        local text = _G[s:GetName().."Text"]
        text:SetFontObject("GameFontNormal")
        text:SetScale(1.2)
        text:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 8)
        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valText:SetPoint("LEFT", s, "RIGHT", 12, 0)
        
        local function UpdateText(val)
            text:SetText(label)
            valText:SetText(isPercent and string.format("%d%%", math.floor(val * 100 + 0.5)) or math.floor(val + 0.5) .. "pt")
        end
        s:SetScript("OnValueChanged", function(self, value)
            MidnightUIButtonsDB[var] = value
            UpdateText(value)
            UpdateAppearance()
        end)
        UpdateText(MidnightUIButtonsDB[var])
    end

    -- Options Layout
    CreateCheck("MidnightLockCheck", "Lock Tray Position", "locked", -50)
    CreateCheck("MidnightHideBGCheck", "Hide Tray Background", "hideBG", -90)
    
    CreateSlider("MidnightScaleSlider", "Button Scale", 0.5, 2.0, 0.05, "scale", true, -150)
    CreateSlider("MidnightFontSlider", "Font Size", 10, 30, 1, "fontSize", false, -210)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end

-- 4. Main UI Creation
local function CreateButtonUI()
    Container = CreateFrame("Frame", "MidnightUI_MainContainer", UIParent)
    Container:SetSize(136, 36)
    Container:SetPoint(MidnightUIButtonsDB.pos[1], MidnightUIButtonsDB.pos[2], MidnightUIButtonsDB.pos[3])
    Container:SetScale(MidnightUIButtonsDB.scale)
    Container:SetMovable(true)
    Container:EnableMouse(true)
    Container:SetClampedToScreen(true)

    Container.bg = Container:CreateTexture(nil, "BACKGROUND")
    Container.bg:SetAllPoints()
    Container.bg:SetColorTexture(unpack(MidnightUIButtonsDB.trayColor))

    Container:RegisterForDrag("LeftButton")
    Container:SetScript("OnDragStart", function(self)
        if not MidnightUIButtonsDB.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    Container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        MidnightUIButtonsDB.pos = {point, x, y}
    end)

    local function SetupButton(btn, textStr)
        btn:SetSize(30, 30)
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetPoint("CENTER")
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", MidnightUIButtonsDB.fontSize, "OUTLINE")
        btn.text:SetText(textStr)
        btn:SetScript("OnEnter", function(self) self:SetAlpha(0.6) end)
        btn:SetScript("OnLeave", function(self) self:SetAlpha(1.0) end)
    end

    -- Secure Action Buttons (R, E, L)
    local secureData = { { "R", "/reload", 0 }, { "E", "/quit", 1 }, { "L", "/logout", 2 } }
    for i, data in ipairs(secureData) do
        local btn = CreateFrame("Button", "MDSecureBtn_"..i, Container, "SecureActionButtonTemplate")
        btn:SetPoint("LEFT", 3 + (data[3] * 33), 0)
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", data[2])
        SetupButton(btn, data[1])
    end

    -- Normal Button (A)
    local btnA = CreateFrame("Button", "MDNormalBtn_A", Container)
    btnA:SetPoint("LEFT", 3 + (3 * 33), 0)
    SetupButton(btnA, "A")
    btnA:SetScript("OnClick", function() if AddonList:IsShown() then AddonList:Hide() else AddonList:Show() end end)
end

-- 5. Load
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
    if name == AddonName then
        InitDB()
        CreateButtonUI()
        RegisterOptions()
        UpdateAppearance()
    end
end)
