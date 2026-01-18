local AddonName = "MidnightUIButtons"
local Buttons = {}
local Container

-- 1. Database & Defaults
local function InitDB()
    local defaults = {
        locked = false, scale = 1.0, fontSize = 16,
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
    Container.bg:SetColorTexture(unpack(MidnightUIButtonsDB.trayColor))
    
    for i = 1, 3 do
        local btn = _G["MDSecureBtn_"..i]
        if btn then
            btn.bg:SetColorTexture(unpack(MidnightUIButtonsDB.btnColor))
            btn.text:SetFont("Fonts\\FRIZQT__.TTF", MidnightUIButtonsDB.fontSize, "OUTLINE")
            btn.text:SetTextColor(unpack(MidnightUIButtonsDB.textColor))
        end
    end

    local btnA = _G["MDNormalBtn_A"]
    if btnA then
        btnA.bg:SetColorTexture(unpack(MidnightUIButtonsDB.btnColor))
        btnA.text:SetFont("Fonts\\FRIZQT__.TTF", MidnightUIButtonsDB.fontSize, "OUTLINE")
        btnA.text:SetTextColor(unpack(MidnightUIButtonsDB.textColor))
    end
end

-- 3. Register Options (Refined Sizing)
local function RegisterOptions()
    local panel = CreateFrame("Frame", "MidnightOptionsPanel", UIParent)
    panel.name = "Midnight UI Buttons"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Midnight UI Buttons")

    -- Checkbox Helper
    local function CreateCheck(name, label, var)
        local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, -50)
        local labelText = _G[cb:GetName().."Text"]
        labelText:SetFontObject("GameFontNormal")
        labelText:SetScale(1.2) -- Manually scaled for perfect sizing
        labelText:SetText(label)
        cb:SetChecked(MidnightUIButtonsDB[var])
        cb:SetScript("OnClick", function(self)
            MidnightUIButtonsDB[var] = self:GetChecked()
            UpdateAppearance()
        end)
    end

    -- Slider Helper
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
        text:SetScale(1.2) -- Manually scaled
        text:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 8)
        
        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valText:SetPoint("LEFT", s, "RIGHT", 12, 0)
        
        local function UpdateText(val)
            text:SetText(label)
            if isPercent then
                valText:SetText(string.format("%d%%", math.floor(val * 100 + 0.5)))
            else
                valText:SetText(string.format("%dpt", math.floor(val + 0.5)))
            end
        end
        
        s:SetScript("OnValueChanged", function(self, value)
            MidnightUIButtonsDB[var] = value
            UpdateText(value)
            UpdateAppearance()
        end)
        
        UpdateText(MidnightUIButtonsDB[var])
        return s
    end

    CreateCheck("MidnightLockCheck", "Lock Tray Position", "locked")
    
    -- Compact spacing for a cleaner look
    CreateSlider("MidnightScaleSlider", "Button Scale", 0.5, 2.0, 0.05, "scale", true, -110)
    CreateSlider("MidnightFontSlider", "Font Size", 10, 30, 1, "fontSize", false, -170)

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
    Container:SetFrameStrata("HIGH")
    Container:EnableMouse(true)
    Container:SetMovable(true)
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

    local secureData = { { "R", "/reload", 0 }, { "E", "/quit", 1 }, { "L", "/logout", 2 } }
    for i, data in ipairs(secureData) do
        local btn = CreateFrame("Button", "MDSecureBtn_"..i, Container, "SecureActionButtonTemplate")
        btn:SetSize(30, 30)
        btn:SetPoint("LEFT", 3 + (data[3] * 33), 0)
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", data[2])
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(unpack(MidnightUIButtonsDB.btnColor))
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetPoint("CENTER")
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", MidnightUIButtonsDB.fontSize, "OUTLINE")
        btn.text:SetText(data[1])
        btn:SetScript("OnEnter", function(self) self.bg:SetAlpha(0.5) end)
        btn:SetScript("OnLeave", function(self) self.bg:SetAlpha(1.0) end)
    end

    local btnA = CreateFrame("Button", "MDNormalBtn_A", Container)
    btnA:SetSize(30, 30)
    btnA:SetPoint("LEFT", 3 + (3 * 33), 0)
    btnA.bg = btnA:CreateTexture(nil, "BACKGROUND")
    btnA.bg:SetAllPoints()
    btnA.bg:SetColorTexture(unpack(MidnightUIButtonsDB.btnColor))
    btnA.text = btnA:CreateFontString(nil, "OVERLAY")
    btnA.text:SetPoint("CENTER")
    btnA.text:SetFont("Fonts\\FRIZQT__.TTF", MidnightUIButtonsDB.fontSize, "OUTLINE")
    btnA.text:SetText("A")
    btnA:SetScript("OnClick", function() if AddonList:IsShown() then AddonList:Hide() else AddonList:Show() end end)
    btnA:SetScript("OnEnter", function(self) btnA.bg:SetAlpha(0.5) end)
    btnA:SetScript("OnLeave", function(self) btnA.bg:SetAlpha(1.0) end)
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