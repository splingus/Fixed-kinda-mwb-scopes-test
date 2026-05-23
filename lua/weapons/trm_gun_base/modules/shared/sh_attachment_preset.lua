-- =============================================
-- TRMBase 配件自动保存/加载系统
-- 
-- 保存路径: data/trm_weapon_base/preset/save_attachment/{武器类名}/save.json
-- 保存时机: EquipAttachment / UnEquipAttachment
-- 加载时机: 初始化 / Deploy
-- =============================================

local PRESET_ROOT = "trm_weapon_base/preset/save_attachment/"

--- 装上所有定义了 Default 的配件
function SWEP:EquipDefaultAttachments()
    if not SERVER then return end
    if not self.Attachments then return end
    if not self.CurrentAttachments then
        self.CurrentAttachments = {}
    end
    for i, slot in ipairs(self.Attachments) do
        if slot.Default and BASE_TRM_ATTS[slot.Default] then
            local slotKey = tostring(i)
            self.CurrentAttachments[slotKey] = {Class = slot.Default}
        end
    end
    self:ChangeWeaponStats()
end

--- 把当前武器的配件配置保存为 JSON
function SWEP:SaveAttachmentPreset()
    if not SERVER then return end
    local class = self:GetClass()
    if not class or class == "" then return end
    
    -- 改用数组格式
    local data = {}
    if self.Attachments then
        for i = 1, #self.Attachments do
            local slotKey = tostring(i)
            local entry = self.CurrentAttachments and self.CurrentAttachments[slotKey]
            data[i] = entry and entry.Class or "None"  -- 用数字索引
        end
    end
    
    local path = PRESET_ROOT .. class .. "/save.json"
    file.CreateDir(PRESET_ROOT .. class)
    file.Write(path, util.TableToJSON(data))
end

--- 从 JSON 加载配件配置并应用到武器
function SWEP:LoadAttachmentPreset()
    if not SERVER then return end
    local class = self:GetClass()
    if not class or class == "" then return end

    local json = file.Read(PRESET_ROOT .. class .. "/save.json", "DATA")
    if not json or json == "" then return end

    local data = util.JSONToTable(json)
    if not data or not istable(data) then return end

    self.CurrentAttachments = self.CurrentAttachments or {}
    for slotKey in pairs(self.CurrentAttachments) do
        self.CurrentAttachments[slotKey] = nil
    end

    -- 改为 ipairs 迭代数组
    for i, attClass in ipairs(data) do
        local slotKey = tostring(i)
        if self.Attachments and self.Attachments[i] then
            if attClass == "None" then continue end
            if BASE_TRM_ATTS and BASE_TRM_ATTS[attClass] then
                -- ... 其余验证代码不变
                self.CurrentAttachments[slotKey] = {Class = attClass}
            end
        end
    end

    self:SyncAllAttachments()
    self:ChangeWeaponStats()

end
