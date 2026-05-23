function SWEP:Walk()
    --if not trm_weapon_base_util.IsPlayerHolding(wep) then return end

    local vm = self:GetViewModel(self)
    local owner = self:GetOwner()
    local vel = owner:GetVelocity():Length()
    local jumpPose = owner:OnGround() and 1 or 0

    self.m_WalkDeltaLerp = Lerp(5*FrameTime(),self.m_WalkDeltaLerp, 1 ) 
    self.m_WalkPose = Lerp(4*FrameTime(),self.m_WalkPose,vel/ owner:GetWalkSpeed() * jumpPose) 
    -- for _ ,pose in pairs(self.BasePoseParameters.walk) do
    -- vm:SetPoseParameter(pose ,self.m_WalkDeltaLerp * self.m_WalkPose)
        
    -- end
end   

function SWEP:GetLuaWalkBob()
    local owner = self:GetOwner()  
    if !owner:IsPlayer() or owner == NULL then return end
    local val = owner:GetVelocity():Length()
    if not self.WalkBob then
    end
    if val == 0 then
        self.WalkBob = 0
        self.WalkStoppedTime  = CurTime()
        return 
    end
        self.WalkBob = math.sin(CurTime() - self.WalkStoppedTime or 0 )
        local bob = Angle( self.WalkBob * val * self.m_WalkPose , 0 , math.abs(self.WalkBob * val * self.m_WalkPose)  )
    
    return bob
end