if SERVER then return end

-- =============================================
-- 工具函数
-- =============================================
-- =============================================

function SWEP:SendAttachmentToServer(slotKey, attID)
    if not (game.SinglePlayer() or CLIENT) then return end

    net.Start("TRMBase_Attachment")
    net.WriteEntity(self)
    net.WriteString(slotKey)
    net.WriteString(attID)
    net.SendToServer()

    --print("[TRMBase] Send attachment:", slotKey, attID)
end



--- 翻译槽位名称（如果以 # 开头则走语言系统）
local function TranslateSlotName(name)
    if not name then return "Unknown" end
    return language.GetPhrase(name)
end

--- 筛选符合槽位 Category 的配件列表
local function GetAttachmentsForSlot(slot)
    if not slot or not slot.Category then return {} end

    local result = {}
    for attClass, attData in pairs(BASE_TRM_ATTS) do
        if type(attData) ~= "table" then continue end
        if attData.Selectable == false then continue end
        if not attData.Category then continue end

        for _, cat in ipairs(slot.Category) do
            if attData.Category == cat then
                table.insert(result, attClass)
                break
            end
        end
    end

    return result
end

-- =============================================
-- 配件选择面板
-- =============================================

local PANEL = {}

function PANEL:Init()
    self:SetTitle("")
    self:ShowCloseButton(true)
    self:SetDraggable(false)
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)

    self.animationState = 0
    self.m_Slot = self.m_Slot or 1
    self.m_Weapon = nil
    local globalScale = ScreenScale(0.25)

    -- 主内容区域
    self.m_MainPanel = vgui.Create("DPanel", self)
    self.m_MainPanel:SetSize(550 * globalScale, 1000 * globalScale)
    self.m_MainPanel:AlignLeft()
    self.m_MainPanel:AlignTop(200 * globalScale)
    self.m_MainPanel.Paint = function(s, w, h)
        surface.SetDrawColor(30, 30, 30, 50)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    self.m_Container = vgui.Create("DPanel", self.m_MainPanel)
    self.m_Container:Dock(FILL)
    self.m_Container:DockMargin(10, 10, 10, 10)
    self.m_Container.Paint = function() end

    -- 标题
    self.m_TitleLabel = vgui.Create("DLabel", self.m_Container)
    self.m_TitleLabel:Dock(TOP)
    self.m_TitleLabel:SetFont("DermaLarge")
    self.m_TitleLabel:SetTextColor(Color(255, 255, 255))
    self.m_TitleLabel:SetContentAlignment(5)
    self.m_TitleLabel:SetTall(40)

    -- 槽位选择按钮（自定义按钮 + 弹出面板，匹配配件按钮样式）
    self.m_SlotButton = vgui.Create("DButton", self.m_Container)
    self.m_SlotButton:Dock(TOP)
    self.m_SlotButton:SetTall(50)
    self.m_SlotButton:DockMargin(0, 2, 0, 2)
    self.m_SlotButton:SetFont("DermaLarge")
    self.m_SlotButton:SetText("")
    self.m_SlotButton.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255, 200)
        surface.DrawRect(0, 0, w, h)
        local slot = self.m_Weapon and self.m_Weapon.Attachments and self.m_Weapon.Attachments[self.m_Slot]
        local name = slot and (TranslateSlotName(slot.Name) .. "  ▾") or "Select Slot  ▾"
        draw.SimpleText(name, "DermaLarge", w / 2, h / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.m_SlotPopup = nil
    self.m_SlotButton.DoClick = function()
        if IsValid(self.m_SlotPopup) then
            self.m_SlotPopup:Remove()
            self.m_SlotPopup = nil
            return
        end
        -- 创建弹出面板（匹配配件列表风格）
        local popup = vgui.Create("DPanel", self)
        local slotCount = #(self.m_Weapon and self.m_Weapon.Attachments or {})
        local btnH = 50
        local margin = 2
        local totalH = slotCount * (btnH + margin)
        popup:SetSize(self.m_SlotButton:GetWide(), totalH)
        local bx, by = self.m_SlotButton:GetPos()
        popup:SetPos(bx + 550, by + self.m_SlotButton:GetTall() + 2)
        popup.Paint = function(_, w, h)
            surface.SetDrawColor(30, 30, 30, 240)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
        self.m_SlotPopup = popup

        for i, slot in ipairs(self.m_Weapon and self.m_Weapon.Attachments or {}) do
            local name = TranslateSlotName(slot.Name)
            local idx = i
            local btn = vgui.Create("DButton", popup)
            btn:SetText("")
            btn:SetPos(0, (i - 1) * (btnH + margin))
            btn:SetSize(popup:GetWide(), btnH)
            btn.Paint = function(b, w, h)
                if idx == self.m_Slot then
                    surface.SetDrawColor(40, 120, 60, 200)
                elseif b:IsHovered() then
                    surface.SetDrawColor(200, 200, 200, 200)
                else
                    surface.SetDrawColor(50, 50, 50, 200)
                end
                surface.DrawRect(0, 0, w, h)
                draw.SimpleText(name, "DermaLarge", w / 2, h / 2, Color(160, 241, 255), TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function()
                self.m_Slot = idx
                self:RefreshAttList()
                surface.PlaySound("weapons/ar2/ar2_empty.wav")
                if IsValid(self.m_SlotPopup) then
                    self.m_SlotPopup:Remove()
                    self.m_SlotPopup = nil
                end
            end
        end

        -- 点击面板外部自动关闭
        popup.OnMousePressed = function(_, code)
            if code ~= MOUSE_LEFT then return end
            popup:Remove()
            self.m_SlotPopup = nil
        end

        popup.OnRemove = function()
            self.m_SlotPopup = nil
        end
    end

    self.m_SlotButtons = {}

    -- 配件列表滚动区域
    self.m_Scroll = vgui.Create("DScrollPanel", self.m_Container)
    self.m_Scroll:Dock(FILL)
    self.m_Scroll:DockMargin(0, 5, 0, 5)

    self.m_AttList = vgui.Create("DPanel", self.m_Scroll)
    self.m_AttList:Dock(TOP)
    self.m_AttList:SetTall(0)
    self.m_AttList.Paint = function() end

    -- 右侧配件列表面板（透明背景，距主面板 5 像素）
    self.m_AttInfo = vgui.Create("DPanel", self)
    self.m_AttInfo:SetSize(200 * globalScale, 800 * globalScale)
    self.m_AttInfo:AlignLeft(self.m_MainPanel:GetWide() + 5)
    self.m_AttInfo:AlignTop(200 * globalScale)
    self.m_AttInfo.Paint = function() end -- 全透明

    -- 底部提示
    self.m_HintLabel = vgui.Create("DLabel", self.m_Container)
    self.m_HintLabel:Dock(BOTTOM)
    self.m_HintLabel:SetFont("DermaDefault")
    self.m_HintLabel:SetTextColor(Color(180, 180, 180))
    self.m_HintLabel:SetContentAlignment(5)
    self.m_HintLabel:SetTall(25)
    self.m_HintLabel:SetText(language.GetPhrase("#TRMBase_CloseHint"))

    -- -- ESC 关闭（框架 + 所有子控件统一处理）
    -- self.OnKeyCodePressed = function(_, key)
    --     if key == KEY_ESCAPE or key == KEY_E then
    --         self:Close()
    --     end
    -- end
    -- -- 确保 ComboBox 也把 ESC/E 传上来
    -- self.m_SlotCombo.OnKeyCodePressed = function(_, key)
    --     if key == KEY_ESCAPE or key == KEY_E then
    --         self:Close()
    --     else
    --         -- 让 combo 自己处理其他按键
    --     end
    -- end

    -- =============================================
    -- 右侧武器数据面板（Stats）
    -- 如需添加/修改显示的属性，改下面的 stats 列表即可
    -- =============================================
    local menuPanel = self

    self.m_StatsPanel = vgui.Create("DPanel", self)
    self.m_StatsPanel:SetSize(550 * globalScale, 1000 * globalScale)
    self.m_StatsPanel:AlignRight(5)
    self.m_StatsPanel:AlignTop(200)

    self.m_StatsPanel.Paint = function(_, w, h)
        local wep = menuPanel.m_Weapon or LocalPlayer():GetActiveWeapon()
        if not IsValid(wep) then return end

        -- 背景
        surface.SetDrawColor(30, 30, 30, 120)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        -- 武器名
        draw.SimpleText(wep:GetPrintName(), "DermaLarge", 10, 15,
            Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local def = weapons.Get(wep:GetClass())
        if not def then return end
        local sim = table.Copy(def)

        -- 应用默认配件（复制一份处理）
        for slot, att in pairs(wep.Attachments or {}) do
            if not att.Default then continue end
            local attData = BASE_TRM_ATTS[att.Default]
            if attData and attData.ChangeWeaponStats then
                pcall(attData.ChangeWeaponStats, attData, def) -- 用 sim，不污染原始表
            end
        end

        -- 应用已装备配件
        for _, entry in pairs(wep.CurrentAttachments or {}) do
            if not entry or not entry.Class then continue end
            local attData = BASE_TRM_ATTS[entry.Class]
            if attData and attData.ChangeWeaponStats then
                pcall(attData.ChangeWeaponStats, attData, sim)
            end
        end
        local function avg(t, _max)
            if type(t) ~= "table" then return t end -- 如果不是表就当数字用
            if not _max then _max = 100 end
            local total = 0
            local count = 0
            for _, val in pairs(t) do
                if count >= _max then break end
                if type(val) == "table" then
                    -- 如果 val 还是表，递归调用 avg
                    total = total + avg(val)
                else
                    total = total + val
                end
                count = count + 1
            end
            if count == 0 then return 0 end
            return total / count
        end

        local function getRecoil(weapon)
            local _recoil = {
                v = avg(weapon.Recoil.Vertical),
                h = avg(weapon.Recoil.Horizonal),
                s = weapon.Recoil.Shake + weapon.Recoil.KickDown,
            }
            local _ads = avg({ weapon.Recoil.AdsMultiplier, 1 })

            local _total = avg(_recoil) * _ads
            local _table = weapon.VisualRecoil
            local _recoil = {
                v = avg(_table.Vertical),
                h = avg(_table.Horizonal),
                b = avg(_table.Backward),
                r = avg({ -_table.RecoverSpeed, -_table.RecoverDelay }),
            }
            _recoil = avg(_recoil) * avg({ _table.AdsMulitplier, 1 })

            _total = _total + _recoil


            _total = math.Round(_total, 3)
            return _total
        end

        local function getDamage(weapon)
            return weapon.Primary.Damage * weapon.Primary.NumBullets
        end

        local stats                     = { --PrintName , sim , def , sortType
            { language.GetPhrase("#TRMBase_Stat_Damage"),    getDamage(sim),        getDamage(def),        true,   100 },
            { language.GetPhrase("#TRMBase_Stat_ClipSize"),  sim.Primary.ClipSize,  def.Primary.ClipSize,  true,   150 },
            { language.GetPhrase("#TRMBase_Stat_RPM"),       sim.Primary.RPM,       def.Primary.RPM,       true,   1500 },
            { language.GetPhrase("#TRMBase_Stat_Spread"),    sim.Spread.Base,       def.Spread.Base,       false,  0.1 },
            { language.GetPhrase("#TRMBase_Stat_AimSpeed"),  sim.Aim.Time,          def.Aim.Time,          false,  1 },
            { language.GetPhrase("#TRMBase_Stat_Recoil"),    getRecoil(sim),        getRecoil(def),        false,  10 },
        }
        local animationState            = animationState or 0
        local x, y, _w, _h, _padding    = 20, 150, w - 30, 25, 3
        self.animationState             = math.Approach(self.animationState, 1, RealFrameTime() * 1)

        for key, stat in pairs(stats) do
            local _max = stat[5] or stat[3] * 2
            local radio = math.Clamp(stat[2] / _max, 0, 1)
            local ori_radio = math.Clamp(stat[3] / _max, 0, 1)
            local delta = -(stat[3] - stat[2])
            local _reserve = not stat[4]
            local _mainColor = Color(255, 255, 255)
            local _color = _mainColor


            if delta ~= 0 then
                if (delta * (_reserve and -1 or 1)) > 0 then
                    _color = Color(69, 255, 140)
                else
                    _color = Color(255, 103, 103)
                end
                draw.SimpleText((delta > 0 and "+" or "") .. string.format("%.4f", delta), "Trebuchet24", x + 300, y,
                    _color, TEXT_ALIGN_BOTTOM, TEXT_ALIGN_RIGHT)
                local text = "x" .. string.format("%.1f", 100 * stat[2] / stat[3]) .. " %"
                draw.SimpleText(text, "CloseCaption_Normal", w - 100, y - 5, _color, TEXT_ALIGN_BOTTOM, TEXT_ALIGN_RIGHT)
            end

            draw.SimpleText(string.upper(stat[1]) .. "      " .. stat[2], "Trebuchet18", x, y, _mainColor,
                TEXT_ALIGN_BOTTOM, TEXT_ALIGN_LEFT)

            y = y + 20
            --Bar Display
            --条的边框
            surface.SetDrawColor(_mainColor)
            surface.DrawOutlinedRect(x, y, _w, _h, _padding * 0.5)

            local _barLength = (_w - 4 * _padding) * (self.animationState > 0.25 and self.animationState or 0)
            --这里渲染普通条(长度比例为radio)

            --如果delta小于0且顺序
            if _reserve then
                radio = 1 - radio
                ori_radio = 1 - ori_radio
            end
            if radio > ori_radio then
                radio = ori_radio
            end

            surface.SetDrawColor(_mainColor)
            surface.DrawRect(x + 2 * _padding, y + 2 * _padding, _barLength * radio, _h - 4 * _padding)
            --颜色的变化条（）
            local _Delta_Radio = math.abs(delta) / _max
            surface.SetDrawColor(_color)
            surface.DrawRect(x + 2 * _padding + _barLength * radio, y + 2 * _padding, _barLength * _Delta_Radio,
                _h - 4 * _padding)
            --
            y = y + 40
        end
    end -- Paint
end

function PANEL:SetWeapon(weapon)
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

    self.m_Weapon = weapon
    self.m_TitleLabel:SetText(weapon:GetPrintName() .. language.GetPhrase("#TRMBase_Customize"))

    for _, btn in ipairs(self.m_SlotButtons) do
        if IsValid(btn) then btn:Remove() end
    end
    self.m_SlotButtons = {}

    if not weapon.Attachments or #weapon.Attachments == 0 then
        self.m_HintLabel:SetText(language.GetPhrase("#TRMBase_NoSlots"))
        return
    end

    local panel = self

    self.m_Slot = 1
    self:RefreshAttList()
    self:RefreshAttInfo()
end

function PANEL:RefreshAttList()
    self.m_AttList:Clear()

    if not IsValid(self.m_Weapon) then return end

    local slot = self.m_Weapon.Attachments[self.m_Slot]
    if not slot then return end

    local slotKey = tostring(self.m_Slot)
    local currentEntry = self.m_Weapon.CurrentAttachments and self.m_Weapon.CurrentAttachments[slotKey]
    local currentAtt = currentEntry and currentEntry.Class -- nil = 无, string = 配件类名
    local atts = GetAttachmentsForSlot(slot)

    -- 检查此槽位是否被已装备的配件排除
    local slotExcluded = not self.m_Weapon:CanAttach(self.m_Slot)

    -- 第一个按钮永远是"无"（清空槽位）

    -- 如果槽位有 Default 配件，在"无"下面单独显示（之后循环跳过它，避免重复）
    local skipDefault = nil
    if slot.Default and BASE_TRM_ATTS[slot.Default] then
        skipDefault = slot.Default
        local defName = language.GetPhrase(BASE_TRM_ATTS[slot.Default].Name) or skipDefault
        self:AddAttButton(defName .. "[" .. language.GetPhrase("#TRMBase_Default") .. "]", skipDefault,
            currentAtt == skipDefault, slotKey, false)
    else
        self:AddAttButton(language.GetPhrase("#TRMBase_None"), nil, currentAtt == nil or currentAtt == "None", slotKey,
            false)
    end

    for _, attClass in ipairs(atts) do
        local attData = BASE_TRM_ATTS[attClass]
        if not attData then continue end

        -- Default 配件已单独显示，跳过避免重复
        if skipDefault and attClass == skipDefault then continue end

        local name = language.GetPhrase(attData.Name) or attData.Name or attClass
        local isActive = (currentAtt == attClass)
        self:AddAttButton(name, attClass, isActive, slotKey, slotExcluded)
    end

    -- 如果槽位被排除，显示提示
    if slotExcluded then
        self.m_HintLabel:SetText(language.GetPhrase("#TRMBase_SlotExcluded"))
    else
        self.m_HintLabel:SetText(language.GetPhrase("#TRMBase_CloseHint"))
    end

    local totalH = 4  
    for _, child in ipairs(self.m_AttList:GetChildren()) do
        totalH = totalH + child:GetTall() + 5
    end
    if totalH > 0 then totalH = totalH - 4 end
    self.m_AttList:SetTall(math.max(totalH, 1))
    self.m_Scroll:InvalidateLayout()
end

function PANEL:AddAttButton(name, attClass, isActive, slotKey, slotExcluded)
    local btn = vgui.Create("DButton", self.m_AttList)
    btn:SetText("")
    btn:Dock(TOP)
    btn:SetTall(70)
    btn:DockMargin(0, 5, 0, 0)

    local weapon = self.m_Weapon

    btn.Paint = function(self2, w, h)
        if isActive then
            -- 当前选中状态优先，即使槽位被排除也显示绿色
            surface.SetDrawColor(40, 120, 60, 200)
        elseif slotExcluded then
            surface.SetDrawColor(100, 30, 30, 200)
        else
            surface.SetDrawColor(50, 50, 50, 180)
        end
        surface.DrawRect(0, 0, w, h)

        if not slotExcluded and self2:IsHovered() then
            surface.SetDrawColor(255, 255, 255, 30)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
        elseif not slotExcluded then
            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawOutlinedRect(0, 0, w, h, 3)
        end

        local textColor = (isActive or not slotExcluded) and Color(255, 255, 255) or Color(120, 120, 120)
        draw.SimpleText(name, "DermaLarge", 12, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if isActive then
            draw.SimpleText("[Selected]", "Trebuchet24", w - 15, h / 2, Color(100, 255, 100), TEXT_ALIGN_RIGHT,
                TEXT_ALIGN_CENTER)
        elseif slotExcluded then
            draw.SimpleText("[" .. language.GetPhrase("#TRMBase_Excluded") .. "]", "DermaDefault", w - 15, h / 2,
                Color(200, 100, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    btn.DoClick = function()
        if slotExcluded then
            surface.PlaySound("weapons/ar2/ar2_empty.wav")
            return
        end
        local id = attClass or "None"
        if IsValid(weapon) then
            -- 先本地更新 CurrentAttachments，确保按钮立即变绿
            if not weapon.CurrentAttachments then
                weapon.CurrentAttachments = {}
            end
            weapon.CurrentAttachments[slotKey] = (id ~= "None") and { Class = id } or nil
            weapon:SendAttachmentToServer(slotKey, id)
            surface.PlaySound("weapons/ar2/ar2_empty.wav")
            self:RefreshAttList()
            self:RefreshAttInfo()
        end
    end
end

-- 更新右侧配件信息面板
function PANEL:RefreshAttInfo()
    if not IsValid(self.m_AttInfo) then return end
    self.m_AttInfo:Clear()

    local wep = self.m_Weapon
    if not IsValid(wep) or not wep.Attachments then return end

    local y = 5
    local lineH = 50

    for i, slot in ipairs(wep.Attachments) do
        local entry = wep.CurrentAttachments and wep.CurrentAttachments[tostring(i)]
        if not entry or not entry.Class then continue end
        if slot.Default and entry.Class == slot.Default then continue end

        local attData = BASE_TRM_ATTS[entry.Class]
        local name = attData and attData.Name or entry.Class

        local lbl = vgui.Create("DLabel", self.m_AttInfo)
        lbl:SetPos(5, y)
        lbl:Dock(TOP)
        lbl:DockMargin(2, 2, 2, 2)
        lbl:DockPadding(10, 2, 10, 2)
        lbl.Paint = function(self2, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        name = " " .. name
        lbl:SetText(name)
        lbl:SetFont("DermaLarge")
        lbl:SizeToContents()
        lbl:SetTextColor(Color(255, 255, 255, 220))
        y = y + lineH
    end
end

function PANEL:Close()
    gui.EnableScreenClicker(false)
    TRM_AttachMenu_Instance = nil
    self:Remove()
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 90)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("TRM_AttachMenu", PANEL, "DFrame")

-- =============================================
-- concommand 开关
-- =============================================

-- =============================================
-- concommand 开关
-- =============================================

concommand.Add("+trmbase_customize", function(ply)
    if not IsValid(TRM_AttachMenu_Instance) then
        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) or not util.IsTRMBase(weapon) then
            print("[TRMBase] 当前武器不是 TRM Base 武器")
            return
        end

        gui.EnableScreenClicker(true)

        local frame = vgui.Create("TRM_AttachMenu")
        frame:SetWeapon(weapon)

        TRM_AttachMenu_Instance = frame
    else
        TRM_AttachMenu_Instance:Close()
    end
end)


-- =============================================
-- 网络同步
-- =============================================

net.Receive("TRMBase_SyncAttachment", function()
    local wep = net.ReadEntity()
    local slot = net.ReadString()
    local attClass = net.ReadString()

    if not IsValid(wep) then return end

    wep.CurrentAttachments = wep.CurrentAttachments or {}

    if attClass == "None" then
        wep.CurrentAttachments[slot] = nil
    else
        wep.CurrentAttachments[slot] = { Class = attClass }
    end

    -- print("[TRMBase] Synced:", slot, attClass or "None")

    if wep.BuildCustomizedGun then
        wep:BuildCustomizedGun()
    end
    wep.m_NeedsBuild = true

    if IsValid(TRM_AttachMenu_Instance) then
        TRM_AttachMenu_Instance:RefreshAttList()
    end
end)

net.Receive("TRMBase_SyncAllAttachments", function()
    local wep = net.ReadEntity()
    if not IsValid(wep) then return end

    local count = net.ReadUInt(8)
    wep.CurrentAttachments = wep.CurrentAttachments or {}

    for i = 1, count do
        local slot = net.ReadString()
        local attClass = net.ReadString()
        wep.CurrentAttachments[slot] = { Class = attClass }
    end

    -- print("[TRMBase] SyncAllAttachments: received", count, "attachments")

    if wep.BuildCustomizedGun then
        wep:BuildCustomizedGun()
    end
    wep.m_NeedsBuild = true
end)

-- =============================================
-- 调试命令
-- =============================================

concommand.Add("trmbase_test_attach", function(ply, cmd, args)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

    local slotKey = args[1] or ""
    local attID = args[2] or ""

    weapon:SendAttachmentToServer(slotKey, attID)
end)

concommand.Add("trmbase_rebuild_attach", function(ply)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end

    if weapon.CurrentAttachments then
        for _, entry in pairs(weapon.CurrentAttachments) do
            if entry then
                weapon:RemoveAttachmentModel(entry)
            end
        end
    end
    print("[TRMBase] 所有配件模型已强制重建")
end)

concommand.Add("trmbase_show_attach", function(ply, cmd, arg)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end
    print("-----------------------------------")
    print(weapon:GetPrintName())
    print("Can Attach")
    PrintTable(weapon.Attachments)
    print("Equipped:")
    PrintTable(weapon.CurrentAttachments)
end)

concommand.Add("trmbase_debug_slots", function(ply)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then
        print("[TRMBase] 当前武器不是 TRM Base")
        return
    end

    print("========== TRMBase Slot Debug ==========")
    print("Total attachments in BASE_TRM_ATTS: " .. table.Count(BASE_TRM_ATTS or {}))

    print("--- All attachments with Category ---")
    for name, data in pairs(BASE_TRM_ATTS or {}) do
        if type(data) == "table" and data.Category then
            print("  " ..
            name .. " -> Category: " .. tostring(data.Category) .. ", Selectable: " .. tostring(data.Selectable))
        end
    end

    if not weapon.Attachments then
        print("武器没有 Attachments 表!")
        return
    end

    print("--- Weapon Attachments (" .. #weapon.Attachments .. " slots) ---")
    for i, slot in ipairs(weapon.Attachments) do
        if istable(slot) then
            local cats = ""
            if slot.Category then
                for j, cat in ipairs(slot.Category) do
                    cats = cats .. (j > 1 and ", " or "") .. cat
                end
            end
            print("Slot " .. i .. ": Name=" .. tostring(slot.Name) .. ", Category={" .. cats .. "}")

            local matches = GetAttachmentsForSlot(slot)
            if #matches > 0 then
                print("  -> Matches: " .. table.concat(matches, ", "))
            else
                print("  -> NO MATCHES!")
            end
        else
            print("Slot " .. i .. ": NOT A TABLE! type=" .. type(slot))
        end
    end
    print("========================================")
end)
-----------------------------------------
local cvar_hide = CreateClientConVar("trmbase_hidehud_inspect", 1, FCVAR_ARCHIVE)
hook.Add("HUDShouldDraw", "HideWhileCustomizing", function(name)
    if IsValid(TRM_AttachMenu_Instance) then
        return false
    end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if util.IsTRMBase(wep) and IsValid(wep) then
        if wep:IsInspecting() and cvar_hide:GetBool() then
            return false
        end
    end
end)

-- 调试：查看当前 HUD 状态
concommand.Add("trmbase_hud_debug", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    print("=== HUD Debug ===")
    print("IsTRMBase:", util.IsTRMBase(wep))
    print("IsInspecting:", IsValid(wep) and wep:IsInspecting() or false)
    print("MenuOpen:", IsValid(TRM_AttachMenu_Instance))
    print("HideOnInspect:", cvar_hide:GetBool())
    print("GM HideHUD:", ply:GetNW2Int("hidehud", 0))
end)
