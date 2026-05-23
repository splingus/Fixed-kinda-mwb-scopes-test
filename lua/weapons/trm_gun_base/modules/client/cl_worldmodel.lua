if not CLIENT then return end

-- =============================================
-- 世界模型渲染 — SetRenderOrigin/Angles 方式
-- Offset = { Pos = Vector, Ang = Angle }
--   基于玩家右手骨骼 + SetRenderOrigin
-- =============================================

--- 应用世界模型变换
-- function SWEP:RenderOverride()
--     local bone = self:LookupBone(self.WorldModelOffsets.Bone)

--     if (bone != nil && bone > 0) then
--         if (IsValid(self:GetOwner())) then
--             self:ManipulateBoneAngles(bone, self.WorldModelOffsets.Angles)
--             self:ManipulateBonePosition(bone, self.WorldModelOffsets.Pos)
--         else
--             self:ManipulateBoneAngles(bone, Angle(0,0,0))
--             self:ManipulateBonePosition(bone, Vector(0,0,0))
--         end
--     end
--     self:DrawModel()
--     self:SetupBones()

-- end

-- =============================================
-- DrawWorldModel — 每帧由引擎调用  
-- =============================================
function SWEP:DrawWorldModel(flags)

    if self.m_NeedsBuild and self.BuildCustomizedGun then
        -- print(CurTime())
        self:BuildCustomizedGun()
        self.m_NeedsBuild = false
    end

    -- 先计算骨骼变换，再画模型
    local bone = self:LookupBone(self.WorldModelOffsets.Bone)
    if bone and bone > 0 and IsValid(self:GetOwner()) then
        self:ManipulateBoneAngles(bone, self.WorldModelOffsets.Angles)
        self:ManipulateBonePosition(bone, self.WorldModelOffsets.Pos)
    end
    
    self:DrawModel(flags)
    if self.CurrentAttachments then
        for _, entry in pairs(self.CurrentAttachments) do
            if IsValid(entry.m_TpModel) then
                entry.m_TpModel:DrawModel()
            end
        end
    end

end

function SWEP:DrawWorldModelTranslucent(flags)
    self:DrawWorldModel(flags)
end

-- =============================================
-- 清理 TP 配件模型（武器移除时子实体不会自动移除）
-- =============================================
function SWEP:OnRemove()
    if self.CurrentAttachments then
        for _, entry in pairs(self.CurrentAttachments) do
            if entry then
                self:RemoveAttachmentModel(entry, true)
            end
        end
    end
end
