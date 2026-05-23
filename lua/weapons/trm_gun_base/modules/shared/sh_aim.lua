function SWEP:CanAim()
    local seq = self.m_CurrentSequence or self:GetPlayingSequence()
    if self:GetSprintDelta() > 0.8 or ( self.IronsightReload == false and self:IsReloading() )or string.find(seq,"Melee") or string.find(seq,"Holster")or string.find(seq,"Draw") then return false end  
    return true 
end



function SWEP:AimIn()
    self.m_AimDelta = math.Approach(self.m_AimDelta,1,FrameTime()/self.m_AimTime) 
    if not self.m_Aiming then
        if not self:IsReloading() then
            self:PlayAnimation("Ads_In")
        end
        self:SetNextAnimationTime(0)

        self.m_Aiming = true
    end
    local seq = self.m_CurrentSequence or self:GetPlayingSequence()
    if seq == "Idle" and self.Animations.Iron_Idle then
        self:PlayAnimation("Iron_Idle")
    elseif seq == "Idle_Empty" and self.Animations.Iron_Idle_Empty then
        self:PlayAnimation("Iron_Idle_Empty")
    end
    
end

function SWEP:AimOut()
    self.m_AimDelta = math.Approach(self.m_AimDelta,0,FrameTime()/self.Aim.Time) 
    if  self.m_Aiming then
        if not self:IsReloading() then
            self:PlayAnimation("Ads_Out")
        end
        self:SetNextAnimationTime(0)

        self.m_Aiming = false 
    end

    local seq = self.m_CurrentSequence or self:GetPlayingSequence()
    if seq == "Iron_Idle" and self.Animations.Idle then
        self:PlayAnimation("Idle")
    elseif seq == "Iron_Idle_Empty" and self.Animations.Idle_Empty then
        self:PlayAnimation("Idle_Empty")
    end
    
end



function SWEP:AimLogic()
    
    if self:GetOwner():KeyDown(IN_ATTACK2) && self:CanAim() then
            self:AimIn()
    else
            self:AimOut()
    end      
    

    if SERVER then
        self:SetAimDelta(self.m_AimDelta)
    end

    return true
end

function SWEP:AimThink()

    if SERVER and IsFirstTimePredicted() then
        self:AimLogic()
    end
    

    
end





function SWEP:AdjustMouseSensitivity()
    
    return self.m_MouseSensitivity or 1
end


