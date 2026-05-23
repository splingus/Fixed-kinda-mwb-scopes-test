function SWEP:RefreshAttTable()

end

--- 检查指定槽位能否安装配件
--- 返回 false 表示被排除（不可用），true 表示可用
--- 排除条件：
---   1. 槽位自身的 Exclude 列表匹配了已装备配件的 Category
---   2. 已装备配件的 Excluded 列表匹配了本槽位的 Category（或其子分类）
function SWEP:CanAttach(slotIndex)
    if not self.Attachments or not self.Attachments[slotIndex] then return true end
    local slot = self.Attachments[slotIndex]
    local slotCats = istable(slot.Category) and slot.Category or { slot.Category }

    -- 检查槽位自身的 Exclude 列表
    if slot.Exclude and #slot.Exclude > 0 then
        for _, entry in pairs(self.CurrentAttachments or {}) do
            local attData = BASE_TRM_ATTS[entry.Class]
            if attData and attData.Category then
                for _, excludeCat in ipairs(slot.Exclude) do
                    if attData.Category == excludeCat then
                        return false
                    end
                end
            end
        end
    end

    -- 检查已装备配件的 Excluded 列表
    for _, entry in pairs(self.CurrentAttachments or {}) do
        local attData = BASE_TRM_ATTS[entry.Class]
        if attData and attData.Excluded then
            local excluded = istable(attData.Excluded) and attData.Excluded or { attData.Excluded }
            for _, excludeCat in ipairs(excluded) do
                for _, slotCat in ipairs(slotCats) do
                    if slotCat == excludeCat then
                        return false
                    end
                end
            end
        end
    end

    return true
end

--self:GetViewModel():SetWeaponModel("models/weapons/c_smg1.mdl",self)

function SWEP:PrecacheViewModel()
    self.m_ViewmodelCache = nil
    self.m_SkinCache = nil
    self.m_BodyGroupCache = {}
    self.m_PoseParameter = {}
    self.m_PoseParameter2 = {}

    for _, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        if not BASE_TRM_ATTS[entry.Class] then continue end
        local _att = BASE_TRM_ATTS[entry.Class]
        if _att.ViewModel then
            self.m_ViewmodelCache = _att.ViewModel
        elseif _att.Skin then
            self.m_SkinCache = _att.Skin
        elseif _att.BodyGroup then
            for _model, _submodel in pairs(_att.BodyGroup) do
                self.m_BodyGroupCache[_model] = _submodel
            end
        elseif _att.poseParameter then
            self.m_PoseParameter = _att.poseParameter
        elseif _att.poseParameter2 then
            self.m_PoseParameter2 = _att.poseParameter2
        end
    end
end

function SWEP:PrepareViewModel()
    if (not vm) then
        vm = self:GetViewModel(0)
    end

    if (not IsValid(vm) or not vm) then
        return false
    end

    vm:SetSkin(0)

    for b = 0, vm:GetNumBodyGroups() do
        vm:SetBodygroup(b, 0)
    end

    self:SetSkin(0)

    for b = 0, self:GetNumBodyGroups() do
        self:SetBodygroup(b, 0)
    end
    vm:SetWeaponModel(self.ViewModel, self)

    for _group, _sub in pairs(self.BodyGroups or {}) do
        changeBodyGroup(vm, _group, _sub)
        for _, entry in pairs(self.CurrentAttachments or {}) do
            if IsValid(entry.m_Model) then
                changeBodyGroup(entry.m_Model, _group, _sub)
            end
        end
    end
end

function changeBodyGroup(model, submodel, sub)
    if not IsValid(model) then return end
    local _modelId = model:FindBodygroupByName(submodel)
    if _modelId and _modelId > -1 then
        model:SetBodygroup(_modelId, sub)
    end
    --print("change")
end

function SWEP:ApplyViewModelChange()
    local vm = self:GetViewModel()
    if not IsValid(vm) then return false end
    vm:SetModel(self.m_ViewmodelCache || self.ViewModel)
    vm:SetSkin(self.m_SkinCache || 0)

    for bodygroup, sub in pairs(self.m_BodyGroupCache) do
        changeBodyGroup(vm, bodygroup, sub)
        for _, entry in pairs(self.CurrentAttachments or {}) do
            if IsValid(entry.m_Model) then
                changeBodyGroup(entry.m_Model, bodygroup, sub)
            end
        end
    end
end

function SWEP:ChangeWeaponStats()
    self:GetOriginStat()
    self:DeepObjectCopy(self.m_OriginalStat, self)

    for _, entry in pairs(self.CurrentAttachments or {}) do
        if entry and entry.Class and BASE_TRM_ATTS[entry.Class].ChangeWeaponStats then
            BASE_TRM_ATTS[entry.Class]:ChangeWeaponStats(self)
        end
    end


    if SERVER then
        if self:Clip1() > self.Primary.ClipSize then
            self:SetClip1(self.Primary.ClipSize)
        end
        if self:Clip2() > self.Secondary.ClipSize then
            self:SetClip2(self.Secondary.ClipSize)
        end
        self:SetSpread(self.Spread.Base)
        self:SetSpreadVertical(self.Spread.Vertical)
        self:SetSpreadHorizonal(self.Spread.Horizontal)
    end
    self:CallOnClient("ChangeWeaponStats")
end

function SWEP:DeepObjectCopy(original, holder)
    for index, value in pairs(original) do
        if index == "ModelBodyGroup" then continue end -- 跳过
        if istable(value) then
            holder[index] = {}
            self:DeepObjectCopy(value, holder[index])
        elseif isvector(value) then
            holder[index] = Vector(value.x, value.y, value.z)
        elseif isangle(value) then
            holder[index] = Angle(value.p, value.y, value.r)
        else
            holder[index] = value
        end
    end
end

function SWEP:GetOriginStat()
    self.m_OriginalStat = weapons.Get(self:GetClass())
end

function SWEP:SpreadInit()
    local val = self.Spread
    if not val then return end
    self:SetSpread(val.Base)
    self:SetSpreadVertical(val.Vertical)
    self:SetSpreadHorizonal(val.Horizontal)
    self:SetRecoilProgress(0)
    self:SetVisualRecoilProgress(0)
end

function SWEP:BulletCallback(attacker, tr, dmginfo)
    local ent = tr.Entity
    if not IsValid(ent) then return end

    -- 只对玩家生效
    if not ent.TakeDamageInfo then return end

    -- 获取击中部位
    local group = tr.HitGroup

    local scale = 1
    if group == HITGROUP_HEAD then
        scale = self.DamageScale.Head or 4
    elseif group == HITGROUP_CHEST or group == HITGROUP_STOMACH then
        scale = self.DamageScale.Body or 1
    elseif group == HITGROUP_LEFTARM or group == HITGROUP_RIGHTARM then
        scale = self.DamageScale.Arms or 0.8
    elseif group == HITGROUP_LEFTLEG or group == HITGROUP_RIGHTLEG then
        scale = self.DamageScale.Legs or 0.6
    end
    if attacker:IsPlayer() then
        dmginfo:ScaleDamage(scale)
    end

    if not self.CurrentAttachments then
        self.CurrentAttachments = {}
    end
    for _, entry in pairs(self.CurrentAttachments) do
        if entry and entry.Class and BASE_TRM_ATTS[entry.Class].BulletCallback then
            BASE_TRM_ATTS[entry.Class]:BulletCallback(attacker, tr, dmginfo)
        end
    end
end

function SWEP:BuildViewModelData()
    if not CLIENT then return end
    local vm = self:GetViewModel(0)
    if not IsValid(vm) then return end

    -- Attachment 数据
    if not self.m_Attachment then
        self.m_Attachment = {}
    end

    -- ViewModel 自身的 Attachments
    local Stat = vm:GetAttachments()
    for _, Modelattachment in pairs(Stat) do
        local data = vm:GetAttachment(Modelattachment.id)
        if data then
            self.m_Attachment[Modelattachment.name] = data
            self.m_Attachment[Modelattachment.name].id = Modelattachment.id
            self.m_Attachment[Modelattachment.name].Ent = vm
        end
    end

    -- 配件模型的 Attachments（只有 Bonemerge 模式的配件才需要）
    for _, entry in pairs(self.CurrentAttachments or {}) do
        local model = entry.m_Model
        if not IsValid(model) then continue end

        local attID = entry.Class
        if not attID then continue end

        local attData = BASE_TRM_ATTS[attID]
        if not attData or not attData.Bonemerge then continue end -- 只处理 Bonemerge 配件

        for _, att in pairs(model:GetAttachments()) do
            local data = model:GetAttachment(att.id)
            if data then
                self.m_Attachment[att.name] = data
                self.m_Attachment[att.name].id = att.id
                self.m_Attachment[att.name].Ent = model
            end
        end
    end

    -- Bone 数据（ViewModel 自身）
    if not self.m_Bone then
        self.m_Bone = {}
    end

    local count = vm:GetBoneCount()
    if count and count > 0 then
        for i = 0, count - 1 do
            local name = vm:GetBoneName(i)
            local matrix = vm:GetBoneMatrix(i)
            if matrix and name then
                self.m_Bone[name] = {
                    Pos = matrix:GetTranslation(),
                    Ang = matrix:GetAngles(),
                    Id = i,
                    Ent = vm,
                }
            end
        end
    end

    -- 配件模型的 Bones（只有 Bonemerge 模式的配件才需要）
    for _, entry in pairs(self.CurrentAttachments or {}) do
        local model = entry.m_Model
        if not IsValid(model) then continue end

        local attID = entry.Class
        if not attID then continue end

        local attData = BASE_TRM_ATTS[attID]
        if not attData or not attData.Bonemerge then continue end

        local boneCount = model:GetBoneCount()
        if not boneCount or boneCount <= 0 then continue end

        for j = 0, boneCount - 1 do
            local name = model:GetBoneName(j)
            local matrix = model:GetBoneMatrix(j)
            if name and matrix then
                if not self.m_Bone[name] then
                    self.m_Bone[name] = {}
                end
                self.m_Bone[name].Pos = matrix:GetTranslation()
                self.m_Bone[name].Ang = matrix:GetAngles()
                self.m_Bone[name].Id = j
                self.m_Bone[name].Ent = model
            end
        end
    end

    if CurTime() - (self.lastdebug or 0) > 10 and GetConVar("developer"):GetInt() == 1 then
        PrintTable(self.m_Bone)
        self.lastdebug = CurTime()
    end
end

function SWEP:GetAttachmentData(name)
    return self.m_Attachment[name]
end

function SWEP:GetBoneData(name)
    return self.m_Bone[name]
end

---CustomizeSystem
function SWEP:OnAttachmentChanged()
    self:ChangeWeaponStats()
    self:BuildCustomizedGun()
    self:SaveAttachmentPreset()
end

-- 统一移除配件模型，调用 attData:Remove 扩展钩子
function SWEP:RemoveAttachmentModel(entry, isTp)
    local model = isTp and entry.m_TpModel or entry.m_Model
    if not IsValid(model) then return end
    local attData = entry.Class and BASE_TRM_ATTS[entry.Class]
    if attData and attData.Remove then
        attData:Remove(self, model)
    else
        model:Remove()
    end
    if isTp then
        entry.m_TpModel = nil
    else
        entry.m_Model = nil
    end
end

function SWEP:EquipAttachment(slot, attClass)
    -- 检查此槽位是否被排除（防止绕过 VGUI 直接发 net 消息）
    local slotIndex = tonumber(slot)
    if slotIndex and not self:CanAttach(slotIndex) then
        print("[TRMBase] Slot", slot, "is excluded, cannot equip", attClass)
        return
    end

    local attData = BASE_TRM_ATTS[attClass]
    if attData then
        self.CurrentAttachments[slot] = { Class = attClass }

        -- 装完后检查其他槽是否因此被排除，如有则自动卸掉

        local removedSlots = {}
        for i = 1, #(self.Attachments or {}) do
            local key = tostring(i)
            if key ~= slot and self.CurrentAttachments[key] and self.CurrentAttachments[key].Class and not self:CanAttach(i) then
                self:RemoveAttachmentModel(self.CurrentAttachments[key])
                removedSlots[#removedSlots + 1] = key
                self.CurrentAttachments[key] = nil
            end
        end

        -- 发送主配件的同步消息
        net.Start("TRMBase_SyncAttachment")
        net.WriteEntity(self)
        net.WriteString(slot)
        net.WriteString(attClass)
        net.SendPVS(self:GetPos())

        -- 同时发送被自动卸载的槽位同步（告诉客户端这些槽已清空）
        for _, removedKey in ipairs(removedSlots) do
            net.Start("TRMBase_SyncAttachment")
            net.WriteEntity(self)
            net.WriteString(removedKey)
            net.WriteString("None")
            net.SendPVS(self:GetPos())
        end
    end


    self:OnAttachmentChanged()

    --print("Equipped:", slot, attClass)
end

function SWEP:UnEquipAttachment(slot)
    local slotIndex = tonumber(slot)

    -- 清理模型
    local entry = self.CurrentAttachments[slot]
    if entry and IsValid(entry.m_Model) then
        BASE_TRM_ATTS[entry.Class]:Remove(self, m_Model)
    end

    self.CurrentAttachments[slot] = nil

    -- 注：不再自动装默认配件，让用户从列表中自行选择"无"或默认配件

    -- 发一次同步
    net.Start("TRMBase_SyncAttachment")
    net.WriteEntity(self)
    net.WriteString(slot)
    net.WriteString("None")
    net.SendPVS(self:GetPos())

    self:OnAttachmentChanged()
    self:SaveAttachmentPreset()

    -- 恢复被排他配件清空的槽位默认配件（跳过刚卸掉的槽位本身）
    timer.Simple(FrameTime() * 5, function()
        if SERVER then
            for i, slotData in ipairs(self.Attachments or {}) do
                local key = tostring(i)
                if key ~= slot and not self.CurrentAttachments[key] and slotData.Default and self:CanAttach(i) then
                    self:EquipAttachment(key, slotData.Default)
                    PrintTable(self.CurrentAttachments[key])
                end
            end
        end
    end)


    --print("Unequipped:", slot, self.CurrentAttachments[slot] or "None")
end

function SWEP:BuildCustomizedGun()
    if SERVER then
        self:CallOnClient("BuildCustomizedGun")
        return
    end

    local vm = self:GetViewModel()
    local hasVM = IsValid(vm)

    self.m_Sight = nil
    --print("call rebuild!")
    local currentSlotKeys = {}

    for slotKey, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        currentSlotKeys[slotKey] = true

        local attData = BASE_TRM_ATTS[entry.Class]
        if not attData then continue end

        -- ========== 第一人称模型（挂 ViewModel） ==========
        -- 只在 vm 有效时创建/更新
        if hasVM then
            if not IsValid(entry.m_Model) and attData.Model then
                local model = ClientsideModel(attData.Model, RENDERGROUP_OPAQUE)
                model:SetNoDraw(true)
                model:SetNotSolid(true)
                model:SetMoveType(MOVETYPE_NONE)
                model:SetOwner(vm)
                entry.m_Model = model
            end
        end

        -- ========== 第三人称模型（挂武器实体，引擎自动渲染） ==========
        if attData.Bonemerge == true and attData.Model then
            if not IsValid(entry.m_TpModel) then
                local tpModel = ClientsideModel(attData.Model, RENDERGROUP_OPAQUE)
                tpModel:SetNotSolid(true)
                tpModel:SetMoveType(MOVETYPE_NONE)
                tpModel:SetNoDraw(true)
                tpModel:SetParent(self)
                tpModel:AddEffects(EF_BONEMERGE)
                tpModel:AddEffects(EF_BONEMERGE_FASTCULL)
                entry.m_TpModel = tpModel
            end
        elseif IsValid(entry.m_TpModel) then
            self:RemoveAttachmentModel(entry, true)
        end
    end

    -- 清除已卸载配件的模型
    for slotKey, entry in pairs(self.CurrentAttachments or {}) do
        if not currentSlotKeys[slotKey] and entry then
            self:RemoveAttachmentModel(entry)
            self:RemoveAttachmentModel(entry, true)
        end
    end

    -- VM 相关操作只在 vm 有效时执行
    if hasVM and self:GetOwner() and self:GetOwner():GetActiveWeapon() == self then
        -- 确保骨骼数据已刷新
        vm:InvalidateBoneCache()
        vm:SetupBones()

        self:PrecacheViewModel()
        self:PrepareViewModel()
        self:ApplyViewModelChange()
        self:BuildViewModelData()
        self:ApplyAttachmentModels()
        self:GenerateAimOffset()
    end

    -- TP 模型偏移始终需要计算（挂在武器实体上，不依赖 vm）
    for slotKey, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        local tpModel = entry.m_TpModel
        if not IsValid(tpModel) then continue end

        local slotData = self.Attachments and self.Attachments[tonumber(slotKey)]
        local attData = BASE_TRM_ATTS[entry.Class]

        local tpPos = slotData and Vector(slotData.Pos) or Vector(0, 0, 0)
        local tpAng = slotData and Angle(slotData.Ang) or Angle(0, 0, 0)
        if attData and attData.Pos and isvector(attData.Pos) then tpPos:Add(attData.Pos) end
        if attData and attData.Angles and isangle(attData.Angles) then tpAng:Add(attData.Angles) end

        tpModel:SetLocalPos(tpPos)
        tpModel:SetLocalAngles(tpAng)
    end
end

function SWEP:ApplyAttachmentModels()
    if SERVER then return end
    local vm = self:GetViewModel()
    if not IsValid(vm) then return end

    for slot, entry in pairs(self.CurrentAttachments) do
        if not entry or not entry.Class then continue end
        local AttachmentData = BASE_TRM_ATTS[entry.Class]
        local WeaponData = self.Attachments and self.Attachments[tonumber(slot)]
        if not AttachmentData.Model then continue end
        local model = entry.m_Model
        if not IsValid(model) then continue end
        local parent = vm

        if AttachmentData.Bonemerge then
            model:SetParent(parent)
            model:AddEffects(EF_BONEMERGE)
            model:AddEffects(EF_BONEMERGE_FASTCULL)
            model:SetLocalPos(Vector(0, 0, 0))
            model:SetLocalAngles(Angle(0, 0, 0))
        else
            if not WeaponData.Bone then continue end
            local bone = self:GetBoneData(WeaponData.Bone)
            if not bone then continue end
            parent = bone.Ent
            model:FollowBone(parent, bone.Id)

            -- 先清零（确保不继承上次的结果）
            model:SetLocalPos(Vector(0, 0, 0))
            model:SetLocalAngles(Angle(0, 0, 0))

            -- 组合偏移：槽位偏移 + 配件自身偏移
            local finalPos = WeaponData.Pos and Vector(WeaponData.Pos) or Vector(0, 0, 0)
            local finalAng = WeaponData.Ang and Angle(WeaponData.Ang) or Angle(0, 0, 0)
            if AttachmentData.Pos and isvector(AttachmentData.Pos) then finalPos:Add(AttachmentData.Pos) end
            if AttachmentData.Angles and isangle(AttachmentData.Angles) then finalAng:Add(AttachmentData.Angles) end

            model:SetLocalPos(finalPos)
            model:SetLocalAngles(finalAng)
            if AttachmentData.Scale then
                model:SetModelScale(AttachmentData.Scale)
            end
        end
    end
end

function SWEP:GetSight()
    return self.m_Sight or false
end

function SWEP:GenerateAimOffset()
    if SERVER then return end
    for slot, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        local AttachmentData = BASE_TRM_ATTS[entry.Class]
        if not AttachmentData or AttachmentData.Model == nil then continue end

        if AttachmentData.Sight != nil then
            local vm = self:GetViewModel()
            if not IsValid(vm) then continue end

            vm:InvalidateBoneCache()
            vm:SetupBones()

            local align = self.Attachments[tonumber(slot)]
            if not align or not align.Bone then continue end

            local AlignAttachment = self:GetBoneData(align.Bone)

            if AlignAttachment then
                local model = entry.m_Model

                if not IsValid(model) then continue end

                model:InvalidateBoneCache()
                model:SetupBones()

                local parent = model:GetParent()
                if IsValid(parent) then
                    parent:InvalidateBoneCache()
                    parent:SetupBones()
                end

                local Data = AlignAttachment
                local sightData = model:GetAttachment(model:LookupAttachment(AttachmentData.Sight.Align or "reticle"))
                if not sightData then continue end

                local localPos, localAng = WorldToLocal(sightData.Pos, Data.Ang, Data.Pos, Data.Ang)
                localPos.x = 0
                if AttachmentData.Sight.Pos then
                    localPos:Add(AttachmentData.Sight.Pos)
                end
                if align.SightPos then
                    localPos:Add(align.SightPos)
                end
                model.AimPos = Vector(localPos.x, localPos.y, localPos.z)
                model.AimAng = align.SightAng or Angle(0, 0, 0)
                if not self.m_Sight then
                    self.m_Sight = {
                        AimPos = model.AimPos,
                        AimAng = model.AimAng,
                        AimBoneAng = Angle(Data.Ang),
                    }
                end

                entry.m_Model = model
                model = nil
            end
        end
    end
end

--- 服务端：把全部配件同步给客户端（Deploy 时调用）
function SWEP:SyncAllAttachments()
    if not SERVER then return end

    -- 地面武器没有 owner 也能同步（用于第三人称模型）
    net.Start("TRMBase_SyncAllAttachments")
    net.WriteEntity(self)
    local count = 0
    for _ in pairs(self.CurrentAttachments or {}) do
        count = count + 1
    end
    net.WriteUInt(count, 8)
    for slot, entry in pairs(self.CurrentAttachments or {}) do
        if not entry.Class then continue end
        net.WriteString(slot)
        net.WriteString(entry.Class)
    end
    net.Broadcast()
end

net.Receive("TRMBase_Attachment", function()
    local weapon = net.ReadEntity()
    local slot = net.ReadString()
    local attClass = net.ReadString()
    if attClass == "None" then
        weapon:UnEquipAttachment(slot)
    else
        weapon:EquipAttachment(slot, attClass)
    end
end)





------------------------------------------------------
