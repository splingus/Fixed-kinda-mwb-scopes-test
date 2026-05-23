function SWEP:Task_Rechamber(cycle)
    if self:GetOwner():KeyDown(IN_ATTACK) then return end
    if self.Animations.Rechamber and not self:IsEmpty() then
        self:PlayAnimation("Rechamber",true) 
    end
    self:SetCurrentTask("Finished")
end

function SWEP:ResetChamberRound(amount)
    if not amount then
        amount = self.Primary.ChamberSize
    end
    
    self:SetChamberAmmo(math.min(amount,self:Clip1()))
end

function SWEP:CanRechamber()
    local seq = self.m_CurrentSequence or self:GetPlayingSequence()
    local task = self:GetCurrentTask()
    if (string.find(seq,"Idle") or string.find(task,"Sprint")or string.find(seq,"Sprint") )and not self:IsEmpty() then return true end

    return false 
end