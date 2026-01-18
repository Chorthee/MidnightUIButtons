local AddonName = "MidnightUIButtons"
local Buttons = {}
local Container

-- 1. Database & Defaults
local function GetDefaults()
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

local function InitDB()
    local defaults = GetDefaults()
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
    Container:ClearAllPoints()
    Container:SetPoint(MidnightUIButtonsDB.pos[1], MidnightUIButtonsDB.pos[2], MidnightUIButtonsDB.pos[3])
    
    Container.bg:SetAlpha(MidnightUIButtonsDB.hideBG and 0 or 1)
    Container.bg:SetColorTexture(unpack(MidnightUIButtonsDB.trayColor))
    
    local function StyleButton(btn)
        if not btn or not btn.text then return end
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", MidnightUIButtonsDB.fontSize, "OUTLINE")
        btn.text:SetTextColor(unpack(MidnightUIButtonsDB.textColor))
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
        _G[cb:GetName().."Text"]:SetText(label)
        cb:SetChecked(MidnightUIButtonsDB[var])
        cb:SetScript("OnClick", function(self)
            MidnightUIButtonsDB[var] = self:GetChecked()
            UpdateAppearance()
        end)
        return cb
    end

    local function CreateSlider(name, label, min, max, step, var, isPercent, yOffset)
        local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20, yOffset)
        s:SetMinMaxValues(min, max)
        s:SetValueStep(step)
        s:SetValue(MidnightUIButtonsDB[var])
        s:SetWidth(180)
        local text = _G[s:GetName().."Text"]
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
        return s
    end

    -- Color Picker Creation
    local function CreateColorPicker(label, var, yOffset)
        local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOPLEFT", 20, yOffset)
        t:SetText(label)

        local btn = CreateFrame("Button", nil, panel)
        btn:SetSize(24, 24)
        btn:SetPoint("LEFT", t, "RIGHT", 10, 0)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetSize(22, 22)
        btn.bg:SetPoint("CENTER")
        btn.bg:SetColorTexture(unpack(MidnightUIButtonsDB[var]))
        
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetColorTexture(0.5, 0.5, 0.5, 1)

        btn:SetScript("OnClick", function()
            local r, g, b, a = unpack(MidnightUIButtonsDB[var])
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    MidnightUIButtonsDB[var] = {nr, ng, nb, 1}
                    btn.bg:SetColorTexture(nr, ng, nb, 1)
                    UpdateAppearance()
                end,
                cancelFunc = function()
                    MidnightUIButtonsDB[var] = {r, g, b, a}
                    btn.bg:SetColorTexture(r, g, b, a)
                    UpdateAppearance()
                end,
                r = r, g = g, b = b, opacity = 1, hasOpacity = false
            })
        end)
        return btn
    end

    -- Setup Options UI
    local lockCb = CreateCheck("MidnightLockCheck", "Lock Tray Position", "locked", -50)
    local hideCb = CreateCheck("MidnightHideBGCheck", "Hide Tray Background", "hideBG", -90)
    local scaleSld = CreateSlider("MidnightScaleSlider", "Button Scale", 0.5, 2.0, 0.05, "scale", true, -150)
    local fontSld = CreateSlider("MidnightFontSlider", "Font Size", 10, 30, 1, "fontSize", false, -210)
    local colorBtn = CreateColorPicker("Font Color:", "textColor", -255)

    -- THE RESET BUTTON
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("TOPLEFT", 16, -310)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        MidnightUIButtonsDB = GetDefaults()
        -- Update the UI controls to reflect the reset
        lockCb:SetChecked(MidnightUIButtonsDB.locked)
        hideCb:SetChecked(MidnightUIButtonsDB.hideBG)
        scaleSld:SetValue(MidnightUIButtonsDB.scale)
        fontSld:SetValue(MidnightUIButtonsDB.fontSize)
        colorBtn.bg:SetColorTexture(unpack(MidnightUIButtonsDB.textColor))
        UpdateAppearance()
    end)

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

    local secureData = { { "R", "/reload", 0 }, { "E", "/quit", 1 }, { "L", "/logout", 2 } }
    for i, data in ipairs(secureData) do
        local btn = CreateFrame("Button", "MDSecureBtn_"..i, Container, "SecureActionButtonTemplate")
        btn:SetPoint("LEFT", 3 + (data[3] * 33), 0)
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", data[2])
        SetupButton(btn, data[1])
    end

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
