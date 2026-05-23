if  SERVER then return end

function SWEP:CustomBob()
    if not CLIENT then 
        return 
    end
    
    local owner = self:GetOwner()
    if not IsValid(owner)  then
        return Vector(0, 0, 0), Angle(0, 0, 0)
    end
    
    local speed = owner:GetVelocity():Length2D()
    if not self.Bob_t then self.Bob_t = 0 end
    
    -- 移动时累积，停止时衰减
    if speed > 10 and owner:OnGround() then
        self.Bob_t = (self.Bob_t or 0) + RealFrameTime() * speed * 0.05
        -- 不限制范围，让 sin 自然循环
    elseif speed < 10 then
        self.Bob_t = (self.Bob_t or 0) * 0.95  -- 停止时归零
    end
    local t = math.sin(self.Bob_t or 0) * (speed / 300)
    local mult = math.min(speed / 300, 1) 
    -- 位置偏移
    local pos = Vector(
        math.sin(self.Bob_t) * -0.9 * mult,      -- 左右
        math.cos(self.Bob_t * 1.5) * 0.5 * mult,  -- 前后
        math.abs(math.sin(self.Bob_t)) * 0.25 * mult  -- 上下
    )
    
    -- 角度偏移
    local ang = Angle(
        math.sin(self.Bob_t * 2) * 1.5 * mult,   -- Pitch
        math.sin(self.Bob_t) * 1 * mult,          -- Yaw
        math.sin(self.Bob_t * 1.5) * 2 * mult   -- Roll
    )
    
    return pos, ang
end

function SWEP:Sway()
    if not (CLIENT and self:GetOwner() and self:GetOwner():IsPlayer()) then 
        return Angle(0,0,0), Vector(0,0,0)
    end
    
    if not IsFirstTimePredicted() and SERVER then
        if not self.m_SwayAngle then
            self.m_SwayAngle = Angle(0,0,0)
            self.m_SwayPos = Vector(0,0,0)
        end
        return self.m_SwayAngle, self.m_SwayPos
    end
    
    local owner = self:GetOwner()
    local angles = owner:EyeAngles()
    local velo = owner:GetVelocity()
    
    if not self.m_LastViewModelAngle then
        self.m_LastViewModelAngle = angles
        self.m_SwayAngle = Angle(0, 0, 0)
        self.m_SwayPos = Vector(0, 0, 0)
        return Angle(0, 0, 0), Vector(0, 0, 0)
    end
    
    local ft = math.min(RealFrameTime(), 0.033)
    
    -- 视角移动摇摆
    local dx = -math.AngleDifference(angles.yaw, self.m_LastViewModelAngle.yaw)
    local dy = math.AngleDifference(angles.pitch, self.m_LastViewModelAngle.pitch) 
    self.m_LastViewModelAngle = angles
    
    local maxSway = 2
    local force = 0.1
    local smooth = 12
    
    self.m_SwayAngle.yaw = math.Clamp(self.m_SwayAngle.yaw - dx * force, -maxSway, maxSway)
    self.m_SwayAngle.pitch = math.Clamp(self.m_SwayAngle.pitch - dy * force, -maxSway, maxSway)
    
    self.m_SwayAngle.yaw = Lerp(ft * smooth, self.m_SwayAngle.yaw, 0)
    self.m_SwayAngle.pitch = Lerp(ft * smooth, self.m_SwayAngle.pitch, 0)
    
    -- ===== 侧向移动滚动 =====
    local sideSpeed = velo:Dot(owner:GetRight())
    local targetRoll = math.Clamp(sideSpeed * 0.22 , -15, 15)
    self.m_SwayAngle.roll = Lerp(ft * 10, self.m_SwayAngle.roll, targetRoll)
    -- ========================
    
    -- 位置派生
    local posSway = Vector(0, 0, 0)
    posSway.x = self.m_SwayAngle.yaw * -1
    posSway.y = math.abs(self.m_SwayAngle.yaw) * -0.5
    posSway.z = -self.m_SwayAngle.pitch * 0.5
    
    self.m_SwayPos = posSway
    
    return self.m_SwayAngle, posSway
end
function SWEP:GetClientAimDelta()
    if not CLIENT then
        return self:GetAimDelta()
    end
    
    local target = self:GetAimDelta() or 0
    local smoothSpeed = 25  -- 平滑速度，越大越快
    
    self.m_SmoothAimDelta = self.m_SmoothAimDelta or 0
    self.m_SmoothAimDelta = Lerp(FrameTime() * smoothSpeed, self.m_SmoothAimDelta, target)
    
    -- 接近时直接归位避免残留
    if math.abs(self.m_SmoothAimDelta - target) < 0.01 then
        self.m_SmoothAimDelta = target
    end
    
    return self.m_SmoothAimDelta
end

function SWEP:GetClientVisualRecoil()
    if SERVER then return end
    local source = self:GetVisualRecoil()
    if not self.m_Client_VisualRecoil then
        self.m_Client_VisualRecoil = source
    end
    self.m_Client_VisualRecoil = LerpAngle( RealFrameTime() * 50 , self.m_Client_VisualRecoil , source )

    return self.m_Client_VisualRecoil
end

function SWEP:GetDucking()
    local owner = self:GetOwner()
    self.m_DuckDelta = self.m_DuckDelta or 0
    if IsValid(owner) then
        local target = ( trm_weapon_base_util.IsDucking(owner) and owner:OnGround() ) and 1 or 0
        self.m_DuckDelta = Lerp(RealFrameTime() * 2, self.m_DuckDelta, target)
    else
        self.m_DuckDelta = 0
    end
    return self.m_DuckDelta
end





function SWEP:TranslateFOV(fov)
    local aimDelta = self:GetAimDelta() or 0
    local normalFOV = GetConVar("fov_desired"):GetInt() 
    local aimFOV = normalFOV / self.Aim.Scale  -- 建议 55-65 之间
    -- if self:IsReloading() then aimFOV = normalFOV  end
    -- 使用平滑曲线，让过渡更自然
    local easedDelta = math.pow(aimDelta,2)  
    local FOV = Lerp(easedDelta, normalFOV, aimFOV)
    self.m_MouseSensitivity = Lerp(easedDelta, 1, 1 /self.Aim.Scale )
    return FOV
end


local cvar_camera = CreateClientConVar("trmbase_camera_animation_scale",1.0)

function SWEP:CalcView(ply, pos, angles, fov)
    local vm = self:GetViewModel(0)
    if not IsValid(vm) then return pos, angles, fov end
    
    -- 不需要相机跟随的动画
    local ignoreAnims = {"Fire", "Idle","Sprint"}
    local currentSeq = self.m_CurrentSequence or self:GetPlayingSequence() or ""
    
    for _, anim in ipairs(ignoreAnims) do
        if string.find(currentSeq, anim) then
            return pos, angles, fov
        end
    end
    
    local attachmentID = vm:LookupAttachment(self.CameraAttachment)
    if not attachmentID or attachmentID <= 0 then
        
        return pos, angles, fov end
    
    local attachment = vm:GetAttachment(attachmentID)
    if not attachment then return pos, angles, fov end
    if self.CameraOffset then
        angles:Add(self.CameraOffset)
    end

    local localAng = vm:WorldToLocalAngles(attachment.Ang)  
    local mul = cvar_camera:GetFloat() 
    if self.CameraReserve == true then 
        localAng:Mul(-1) 
    end
    localAng:Mul(mul)
    angles:Add(localAng)

    return pos, angles, fov
end

local CachePos = Vector(0,0,0)
local CacheAngle =  Angle(0,0,0)

local AimOffset , AimOffsetAngle

function SWEP:CalcViewModelView(vm ,pos , angles , poss , angless )
    if not CLIENT then return end

    -- 冻结 VM 调试（直接读 ConVar，不依赖 m_VMFrozen 同步）
    if GetConVar("trmbase_freeze_vm"):GetInt() ~= 0 then
        if not self.m_VMFreezeAng then self.m_VMFreezeAng = angles end
        if not self.m_VMFreezePos then self.m_VMFreezePos = pos end
        return self.m_VMFreezePos, self.m_VMFreezeAng
    else
        self.m_VMFreezeAng = nil
        self.m_VMFreezePos = nil
    end


    local aimdelta = self:GetClientAimDelta()
    --Idle Offset
    if not self.m_IdleDelta then self.m_IdleDelta = 1 end
    self.m_IdleDelta = Lerp(    RealFrameTime() * 10 , self.m_IdleDelta or 0 , self:IsInspecting() and 0 or 1 ) * (1 -aimdelta)
    CachePos = (self.VMOffset.Idle.Pos.x*angles:Right() + self.VMOffset.Idle.Pos.y*angles:Forward() - self.VMOffset.Idle.Pos.z*angles:Up()) * self.m_IdleDelta
    CacheAngle = self.VMOffset.Idle.Ang  *  self.m_IdleDelta 

    pos:Add(CachePos)
    angles:Add(CacheAngle)
    --Sway 
    CacheAngle , CachePos  = self:Sway()
    local  Pos = -Vector( angles:Right() * CachePos.x , angles:Forward() * CachePos.y , angles:Up() * CachePos.z   )  * Lerp(aimdelta ,1 , 0.2 )
    pos:Add(Pos)
    angles:Add(CacheAngle* Lerp(aimdelta ,1 , 0.5 ))
    --Bob
    local BobPos , BobAngle = self:CustomBob()
    local ApplyBobPos = Vector( angles:Right() * BobPos.x , angles:Forward() * BobPos.y , angles:Up() * BobPos.z   ) * ( 1 - aimdelta  )
    BobAngle:Mul(1 - aimdelta * 0.8 )
    pos:Add(ApplyBobPos)
    angles:Add(BobAngle)
    --Duck Pose
    local DuckDelta = (1 - aimdelta) * self:GetDucking()
    local DuckPos = (angles:Right() * self.VMOffset.Crouch.Pos.x +  
                 angles:Forward() * self.VMOffset.Crouch.Pos.y + 
                 angles:Up() * self.VMOffset.Crouch.Pos.z) * DuckDelta    
    local DuckAngle = self.VMOffset.Crouch.Ang * DuckDelta
    pos:Add(DuckPos)
    angles:Add(DuckAngle)
    --Sprint Pose

    local sprintDelta = self:GetSprintDelta() * (self:CanSprint() and 1 or 0)
    local sprintPos = (angles:Right() * self.VMOffset.Sprint.Pos.x +  
    angles:Forward() * self.VMOffset.Sprint.Pos.y + 
    angles:Up() * self.VMOffset.Sprint.Pos.z) * sprintDelta    
    local sprintAngle = self.VMOffset.Sprint.Ang * sprintDelta

    pos:Add(sprintPos)
    angles:Add(sprintAngle)
    -- Aim Pose（基础偏移用 VM 朝向）
    AimOffset = self.Sight.Pos and Vector(self.Sight.Pos) or Vector(0,0,0)
    AimOffsetAngle = self.Sight.Ang and Angle(self.Sight.Ang) or Angle(0,0,0)
    local applyAimPos = (angles:Right() * AimOffset.x + angles:Forward() * AimOffset.y +  angles:Up() * AimOffset.z) * aimdelta
    pos:Add(applyAimPos)
    angles:Add(AimOffsetAngle * aimdelta)

    -- 配件瞄具偏移（用骨骼自身 axis 变换，与 GenerateAimOffset 的 WorldToLocal 坐标空间一致）
    if self.GetSight and self:GetSight() then
        local sight = self:GetSight()
        local boneAng = sight.AimBoneAng or angles
        local sightPos = (angles:Right() * sight.AimPos.x + angles:Forward() * sight.AimPos.y + angles:Up() * sight.AimPos.z) * aimdelta
        pos:Add(sightPos)
        local applyAng = sight.AimAng * aimdelta
        angles:Add(applyAng)
    end



    --Visual Recoil（只有玩家持有时才应用）
    if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
        -- 后坐力后退（position）
        self.m_VRecoilBack = Lerp(  RealFrameTime() * 20 , self.m_VRecoilBack or 0 ,  self:GetVisualRecoilBackward() or self.m_VRecoilBack) 
        pos:Add(Vector(  -self.m_VRecoilBack * angles:Forward()  , -self.m_VRecoilBack * angles:Right()  , -self.m_VRecoilBack * angles:Up()  )  )

        -- 后坐力角度偏移（pitch/yaw 让 viewmodel 上跳）
        local visAng = self:GetClientVisualRecoil()
       

        angles:RotateAroundAxis(    angles:Right() , -visAng.p * 0.63 )
        angles:RotateAroundAxis(    angles:Up() , visAng.y * 0.68 )
        --angles:RotateAroundAxis(    angles:Forward() , visAng.y * -3 )


        --angles:Add(self.m_VisualRecoilAngle)
    end 


    return pos , angles
end



function SWEP:ShouldDrawViewModel()
    local owner = self:GetOwner()
    if owner:InVehicle() then return false end

    
    return true
end






function SWEP:ViewModelDrawn(vm)
    if not IsValid(vm) then return end

    if self ~= (IsValid(LocalPlayer()) and LocalPlayer():GetActiveWeapon()) then return end
    vm:InvalidateBoneCache()
    vm:SetupBones()

    -- -- 检测配件模型是否缺失（换关后 ClientsideModel 被销毁需要重建）
    -- if not self.m_NeedsBuild then
    --     for _, entry in pairs(self.CurrentAttachments or {}) do
    --         if entry.Class and BASE_TRM_ATTS[entry.Class].Model and not IsValid(entry.m_Model) then
    --             self.m_NeedsBuild = true
    --             break
    --         end
    --     end
    -- end

    if self.m_NeedsBuild and self.BuildCustomizedGun then
       -- print(CurTime())
        self:BuildCustomizedGun()
        self.m_NeedsBuild = false
    end

    if not self.m_LastBuild then
        self.m_LastBuild = CurTime()
    elseif CurTime() - self.m_LastBuild > 120 then
        self.m_LastBuild = CurTime()
        self.m_NeedsBuild = true
    end
    
    -- 逐个调用配件的 Render
    for slot, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        local data = BASE_TRM_ATTS[entry.Class]
        local model = entry.m_Model
        if data.Render and IsValid(model) then
            data:Render(self,model)
        end
    end 

    
end

function SWEP:PostDrawViewModel()

end

function SWEP:PreDrawViewModel()
    
end




concommand.Add("trm_clear_test_model", function(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    if wep.test and IsValid(wep.test.m_model) then
        wep.test.m_model:Remove()
        wep.test.m_model = nil
        print("测试模型已清除")
    else
        print("没有找到测试模型")
    end
end)

-- 调试 ConVar
CreateClientConVar("trmbase_freeze_vm", 0)

-- =============================================
-- 调试：冻结 viewmodel 位置/角度
-- =============================================

concommand.Add("trmbase_freeze_vm", function(ply, cmd, args)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not util.IsTRMBase(wep) then
        print("[TRMBase] 当前武器不是 TRM Base 武器")
        return
    end

    local cv = GetConVar("trmbase_freeze_vm")
    local newVal = cv:GetInt() == 0 and 1 or 0
    cv:SetInt(newVal)

    if newVal == 1 then
        local vm = wep:GetViewModel(0)
        if IsValid(vm) then
            wep.m_VMFreezePos = vm:GetPos()
            wep.m_VMFreezeAng = vm:GetAngles()
        end
        print("[TRMBase] Viewmodel 已冻结")
        print("  位置:", tostring(wep.m_VMFreezePos))
        print("  角度:", tostring(wep.m_VMFreezeAng))
        print("  再次执行 trmbase_freeze_vm 解冻")
    else
        wep.m_VMFreezePos = nil
        wep.m_VMFreezeAng = nil
        print("[TRMBase] Viewmodel 已解冻")
    end
end)

