local AddonName = "MidnightUIButtons"
local Container
local SettingsCategory

-- 1. Default Settings & Static Presets
local function GetDefaultSettings()
    return {
        locked = false, hideBG = false, scale = 1.0, fontSize = 16,
        pos = {"CENTER", 0, 0},
        trayColor = {0, 0, 0, 0.7}, btnColor = {0.1, 0.1, 0.1, 0.9}, textColor = {1, 1, 1, 1},
        isClassic = false
    }
end

local function GetStaticPresets()
    local _, class = UnitClass("player")
    local c = RAID_CLASS_COLORS[class] or {r=0.5, g=0.5, b=0.5}
    return {
        ["Midnight (Default)"] = { trayColor = {0, 0, 0, 0.7}, btnColor = {0.1, 0.1, 0.1, 0.9}, textColor = {1, 1, 1, 1}, isClassic = false },
        ["Classic WoW"]        = { trayColor = {0, 0, 0, 0.4}, btnColor = {1, 1, 1, 1},       textColor = {1, 0.82, 0, 1}, isClassic = true },
        ["Glass"]              = { trayColor = {1, 1, 1, 0.1}, btnColor = {1, 1, 1, 0.05},      textColor = {1, 1, 1, 1}, isClassic = false },
        ["Ghost (Stealth)"]    = { trayColor = {0, 0, 0, 0},   btnColor = {0, 0, 0, 0},         textColor = {0.6, 0.6, 0.6, 0.8}, isClassic = false },
        ["Class Color"]        = { trayColor = {c.r*0.2, c.g*0.2, c.b*0.2, 0.8}, btnColor = {c.r, c.g, c.b, 0.5}, textColor = {1, 1, 1, 1}, isClassic = false },
    }
end

-- 2. Core Logic
local function GetCharKey() return UnitName("player") .. "-" .. GetRealmName() end

local function InitDB()
    MidnightUIButtonsDB = MidnightUIButtonsDB or {}
    MidnightUIButtonsDB.profiles = MidnightUIButtonsDB.profiles or { ["Default"] = GetDefaultSettings() }
    MidnightUIButtonsDB.charToProfile = MidnightUIButtonsDB.charToProfile or {}
    MidnightUIButtonsDB.customStyles = MidnightUIButtonsDB.customStyles or {}
    local charKey = GetCharKey()
    if not MidnightUIButtonsDB.charToProfile[charKey] then MidnightUIButtonsDB.charToProfile[charKey] = "Default" end
end

local function GetCfg()
    local charKey = GetCharKey()
    local profileName = MidnightUIButtonsDB.charToProfile[charKey] or "Default"
    return MidnightUIButtonsDB.profiles[profileName] or MidnightUIButtonsDB.profiles["Default"]
end

-- 3. Appearance Update
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
        if cfg.isClassic then
            btn.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
            btn.bg:SetTexCoord(0, 0.625, 0, 0.6875)
            btn:GetHighlightTexture():SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
            btn:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
            btn.bg:SetVertexColor(1, 1, 1, 1)
        else
            btn.bg:SetTexture(nil)
            btn.bg:SetColorTexture(unpack(cfg.btnColor))
            btn:GetHighlightTexture():SetTexture(nil)
        end
    end
    for i = 1, 3 do StyleButton(_G["MDSecureBtn_"..i]) end
    StyleButton(_G["MDNormalBtn_A"])
end

-- 4. Options UI
local function OpenColorPicker(cfgVar, callback)
    local cfg = GetCfg()
    local r, g, b, a = unpack(cfg[cfgVar])
    local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        local newA = ColorPickerFrame:GetColorAlpha()
        cfg[cfgVar] = {newR, newG, newB, newA}
        callback()
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        swatchFunc = OnColorChanged, opacityFunc = OnColorChanged,
        cancelFunc = function() cfg[cfgVar] = {r, g, b, a}; callback() end,
        hasOpacity = true, opacity = a, r = r, g = g, b = b
    })
end

local function RegisterOptions()
    local panel = CreateFrame("Frame", "MidnightOptionsPanel", UIParent)
    panel.name = "Midnight UI Buttons"
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("Midnight UI Buttons (v1.2.18)")

    local visualTab = CreateFrame("Frame", nil, panel); visualTab:SetAllPoints()
    local profileTab = CreateFrame("Frame", nil, panel); profileTab:SetAllPoints()

    local tabs = {}
    local function ShowTab(tabID)
        visualTab:SetShown(tabID == 1); profileTab:SetShown(tabID == 2)
        for id, btn in ipairs(tabs) do
            btn.text:SetTextColor(id == tabID and 1 or 0.6, id == tabID and 0.82 or 0.6, id == tabID and 0 or 0.6)
        end
    end

    local function CreateTabBtn(id, text, xOff)
        local btn = CreateFrame("Button", nil, panel, "BackdropTemplate")
        btn:SetSize(120, 25); btn:SetPoint("TOPLEFT", 16 + xOff, -45)
        btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        btn:SetBackdropColor(0,0,0,0.5); btn:SetBackdropBorderColor(0.5,0.5,0.5,0.5)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); btn.text:SetPoint("CENTER"); btn.text:SetText(text)
        btn:SetScript("OnClick", function() ShowTab(id) end)
        tabs[id] = btn; return btn
    end

    CreateTabBtn(1, "Visual Settings", 0); CreateTabBtn(2, "Profiles", 125); ShowTab(1)

    --- VISUAL SETTINGS ---
    local styleLabel = visualTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    styleLabel:SetPoint("TOPLEFT", 16, -95); styleLabel:SetText("Style Presets:"); styleLabel:SetTextColor(1, 0.82, 0)
    local styleDrop = CreateFrame("Frame", "MidnightStyleDropdown", visualTab, "UIDropDownMenuTemplate")
    styleDrop:SetPoint("LEFT", styleLabel, "RIGHT", -10, -2); UIDropDownMenu_SetWidth(styleDrop, 140)
    
    local function InitStyleDrop()
        UIDropDownMenu_Initialize(styleDrop, function()
            local static = GetStaticPresets()
            for name, data in pairs(static) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name; info.func = function()
                    local cfg = GetCfg()
                    cfg.trayColor, cfg.btnColor, cfg.textColor, cfg.isClassic = data.trayColor, data.btnColor, data.textColor, data.isClassic
                    UpdateAppearance(); UIDropDownMenu_SetText(styleDrop, name)
                end
                UIDropDownMenu_AddButton(info)
            end
            if next(MidnightUIButtonsDB.customStyles) then
                UIDropDownMenu_AddSeparator()
                for name, data in pairs(MidnightUIButtonsDB.customStyles) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = name; info.func = function()
                        local cfg = GetCfg()
                        cfg.trayColor, cfg.btnColor, cfg.textColor, cfg.isClassic = data.trayColor, data.btnColor, data.textColor, data.isClassic
                        UpdateAppearance(); UIDropDownMenu_SetText(styleDrop, name)
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end
        end)
    end
    InitStyleDrop()

    local function CreateCheck(label, var, yOff)
        local cb = CreateFrame("CheckButton", nil, visualTab, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOff); local l = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("LEFT", cb, "RIGHT", 8, 0); l:SetText(label); l:SetTextColor(1, 0.82, 0)
        cb:SetChecked(GetCfg()[var]); cb:SetScript("OnClick", function(self) GetCfg()[var] = self:GetChecked(); UpdateAppearance() end)
    end
    CreateCheck("Lock Tray Position", "locked", -135); CreateCheck("Hide Tray Background", "hideBG", -175)

    local function CreateSlider(label, min, max, step, var, isPercent, yOff)
        local s = CreateFrame("Slider", "MDSlider_"..var, visualTab, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 25, yOff); s:SetMinMaxValues(min, max); s:SetValueStep(step); s:SetValue(GetCfg()[var]); s:SetWidth(180)
        _G[s:GetName().."Text"]:SetText(label); _G[s:GetName().."Text"]:SetTextColor(1, 1, 1)
        local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        val:SetPoint("LEFT", s, "RIGHT", 15, 0)
        s:SetScript("OnValueChanged", function(_, v) GetCfg()[var] = v; UpdateAppearance(); val:SetText(isPercent and math.floor(v*100).."%" or math.floor(v).."pt") end)
        val:SetText(isPercent and math.floor(GetCfg()[var]*100).."%" or math.floor(GetCfg()[var]).."pt")
    end
    CreateSlider("Button Scale", 0.5, 2.0, 0.05, "scale", true, -230); CreateSlider("Font Size", 10, 30, 1, "fontSize", false, -290)

    local function CreateColorRow(label, var, yOff)
        local btn = CreateFrame("Button", nil, visualTab, "UIPanelButtonTemplate")
        btn:SetSize(140, 24); btn:SetPoint("TOPLEFT", 20, yOff); btn:SetText(label)
        btn:SetScript("OnClick", function() OpenColorPicker(var, UpdateAppearance) end)
        local swatch = visualTab:CreateTexture(nil, "OVERLAY")
        swatch:SetSize(18, 18); swatch:SetPoint("LEFT", btn, "RIGHT", 10, 0); swatch:SetColorTexture(1, 1, 1, 1)
        local inner = visualTab:CreateTexture(nil, "OVERLAY")
        inner:SetSize(14, 14); inner:SetPoint("CENTER", swatch)
        btn:SetScript("OnUpdate", function() local c = GetCfg()[var]; inner:SetColorTexture(c[1], c[2], c[3], c[4]) end)
        local rst = CreateFrame("Button", nil, visualTab, "UIPanelButtonTemplate")
        rst:SetSize(60, 24); rst:SetPoint("LEFT", swatch, "RIGHT", 10, 0); rst:SetText("Reset")
        rst:SetScript("OnClick", function() GetCfg()[var] = GetDefaultSettings()[var]; UpdateAppearance() end)
    end
    CreateColorRow("Tray Color", "trayColor", -340); CreateColorRow("Button Color", "btnColor", -370); CreateColorRow("Text Color", "textColor", -400)

    -- CLEANED UP CUSTOM STYLE SECTION
    local saveLabel = visualTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    saveLabel:SetPoint("TOPLEFT", 20, -445); saveLabel:SetText("Save Custom Style:"); saveLabel:SetTextColor(1, 0.82, 0)
    local custEdit = CreateFrame("EditBox", nil, visualTab, "InputBoxTemplate")
    custEdit:SetSize(160, 25); custEdit:SetPoint("TOPLEFT", 155, -442); custEdit:SetAutoFocus(false)
    local saveBtn = CreateFrame("Button", nil, visualTab, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 24); saveBtn:SetPoint("LEFT", custEdit, "RIGHT", 10, 0); saveBtn:SetText("Add Style")
    saveBtn:SetScript("OnClick", function()
        local name = custEdit:GetText()
        if name ~= "" then
            local cfg = GetCfg()
            MidnightUIButtonsDB.customStyles[name] = { trayColor = cfg.trayColor, btnColor = cfg.btnColor, textColor = cfg.textColor, isClassic = cfg.isClassic }
            custEdit:SetText(""); InitStyleDrop()
        end
    end)

    local delLabel = visualTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delLabel:SetPoint("TOPLEFT", 20, -485); delLabel:SetText("Delete Custom Style:"); delLabel:SetTextColor(1, 0.82, 0)
    local delStyleDrop = CreateFrame("Frame", "MidnightDelStyleDrop", visualTab, "UIDropDownMenuTemplate")
    delStyleDrop:SetPoint("TOPLEFT", 145, -482); UIDropDownMenu_SetWidth(delStyleDrop, 140); UIDropDownMenu_SetText(delStyleDrop, "Select...")
    
    local delStyleBtn = CreateFrame("Button", nil, visualTab, "UIPanelButtonTemplate")
    delStyleBtn:SetSize(100, 24); delStyleBtn:SetPoint("LEFT", delStyleDrop, "RIGHT", -5, 2); delStyleBtn:SetText("Delete")
    
    UIDropDownMenu_Initialize(delStyleDrop, function()
        for name in pairs(MidnightUIButtonsDB.customStyles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name; info.func = function() UIDropDownMenu_SetText(delStyleDrop, name) end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    delStyleBtn:SetScript("OnClick", function()
        local name = UIDropDownMenu_GetText(delStyleDrop)
        if name and name ~= "Select..." then
            MidnightUIButtonsDB.customStyles[name] = nil
            UIDropDownMenu_SetText(delStyleDrop, "Select...")
            InitStyleDrop()
        end
    end)

    --- PROFILES (BETA 5 LAYOUT) ---
    local function CreateProfileLabel(text, yOff)
        local l = profileTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("TOPLEFT", 20, yOff); l:SetText(text); l:SetTextColor(1, 0.82, 0); return l
    end
    CreateProfileLabel("Active Profile:", -100)
    local activeDrop = CreateFrame("Frame", "MidnightActiveDrop", profileTab, "UIDropDownMenuTemplate")
    activeDrop:SetPoint("TOPLEFT", 130, -95); UIDropDownMenu_SetWidth(activeDrop, 180)
    local function RefreshActiveText() UIDropDownMenu_SetText(activeDrop, MidnightUIButtonsDB.charToProfile[GetCharKey()]) end
    UIDropDownMenu_Initialize(activeDrop, function()
        for name in pairs(MidnightUIButtonsDB.profiles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name; info.func = function() MidnightUIButtonsDB.charToProfile[GetCharKey()] = name; RefreshActiveText(); UpdateAppearance() end
            UIDropDownMenu_AddButton(info)
        end
    end)
    CreateProfileLabel("Delete Profile:", -150)
    local delDrop = CreateFrame("Frame", "MidnightDelDrop", profileTab, "UIDropDownMenuTemplate")
    delDrop:SetPoint("TOPLEFT", 130, -145); UIDropDownMenu_SetWidth(delDrop, 180); UIDropDownMenu_SetText(delDrop, "Select...")
    local delBtn = CreateFrame("Button", nil, profileTab, "UIPanelButtonTemplate")
    delBtn:SetSize(100, 24); delBtn:SetPoint("LEFT", delDrop, "RIGHT", -5, 2); delBtn:SetText("Delete")
    UIDropDownMenu_Initialize(delDrop, function()
        for name in pairs(MidnightUIButtonsDB.profiles) do
            if name ~= "Default" then
                local info = UIDropDownMenu_CreateInfo()
                info.text = name; info.func = function() UIDropDownMenu_SetText(delDrop, name) end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    delBtn:SetScript("OnClick", function()
        local name = UIDropDownMenu_GetText(delDrop)
        if name and name ~= "Select..." and name ~= "Default" then
            MidnightUIButtonsDB.profiles[name] = nil
            if MidnightUIButtonsDB.charToProfile[GetCharKey()] == name then MidnightUIButtonsDB.charToProfile[GetCharKey()] = "Default" end
            UIDropDownMenu_SetText(delDrop, "Select..."); RefreshActiveText(); UpdateAppearance()
        end
    end)
    CreateProfileLabel("New Profile Name:", -200)
    local newEdit = CreateFrame("EditBox", nil, profileTab, "InputBoxTemplate")
    newEdit:SetSize(190, 30); newEdit:SetPoint("TOPLEFT", 160, -195); newEdit:SetAutoFocus(false)
    local addBtn = CreateFrame("Button", nil, profileTab, "UIPanelButtonTemplate")
    addBtn:SetSize(120, 24); addBtn:SetPoint("LEFT", newEdit, "RIGHT", 10, 0); addBtn:SetText("Add Profile")
    addBtn:SetScript("OnClick", function()
        local name = newEdit:GetText()
        if name ~= "" and not MidnightUIButtonsDB.profiles[name] then
            MidnightUIButtonsDB.profiles[name] = GetDefaultSettings()
            MidnightUIButtonsDB.charToProfile[GetCharKey()] = name; newEdit:SetText(""); RefreshActiveText(); UpdateAppearance()
        end
    end)
    local resetProfileBtn = CreateFrame("Button", nil, profileTab, "UIPanelButtonTemplate")
    resetProfileBtn:SetSize(180, 24); resetProfileBtn:SetPoint("TOPLEFT", 20, -260); resetProfileBtn:SetText("Reset Current Profile")
    resetProfileBtn:SetScript("OnClick", function()
        local current = MidnightUIButtonsDB.charToProfile[GetCharKey()]
        MidnightUIButtonsDB.profiles[current] = GetDefaultSettings()
        UpdateAppearance()
    end)
    RefreshActiveText()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        SettingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(SettingsCategory)
    else InterfaceOptions_AddCategory(panel) end
end

-- 5. Main UI & Load
local function CreateButtonUI()
    local cfg = GetCfg()
    Container = CreateFrame("Frame", "MidnightUI_MainContainer", UIParent)
    Container:SetSize(136, 36); Container:SetMovable(true); Container:EnableMouse(true); Container:SetClampedToScreen(true)
    Container.bg = Container:CreateTexture(nil, "BACKGROUND"); Container.bg:SetAllPoints()
    Container:RegisterForDrag("LeftButton")
    Container:SetScript("OnDragStart", function(self) if not GetCfg().locked and not InCombatLockdown() then self:StartMoving() end end)
    Container:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local p, _, _, x, y = self:GetPoint(); GetCfg().pos = {p, x, y} end)
    local function SetupButton(btn, textStr, xOff)
        btn:SetSize(30, 30); btn:SetPoint("LEFT", 3 + xOff, 0)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND"); btn.bg:SetAllPoints()
        local h = btn:CreateTexture(nil, "HIGHLIGHT"); h:SetAllPoints(); btn:SetHighlightTexture(h)
        btn.text = btn:CreateFontString(nil, "OVERLAY"); btn.text:SetPoint("CENTER")
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", cfg.fontSize or 16, "OUTLINE"); btn.text:SetText(textStr)
    end
    local secureData = { { "R", "/reload", 0 }, { "E", "/quit", 33 }, { "L", "/logout", 66 } }
    for i, d in ipairs(secureData) do
        local b = CreateFrame("Button", "MDSecureBtn_"..i, Container, "SecureActionButtonTemplate")
        b:RegisterForClicks("AnyUp", "AnyDown"); b:SetAttribute("type", "macro"); b:SetAttribute("macrotext", d[2]); SetupButton(b, d[1], d[3])
    end
    local btnA = CreateFrame("Button", "MDNormalBtn_A", Container)
    btnA:RegisterForClicks("AnyUp"); SetupButton(btnA, "A", 99)
    btnA:SetScript("OnClick", function() if AddonList:IsShown() then AddonList:Hide() else AddonList:Show() end end)
end

local f = CreateFrame("Frame"); f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name) if name == AddonName then InitDB(); CreateButtonUI(); RegisterOptions(); UpdateAppearance() end end)
