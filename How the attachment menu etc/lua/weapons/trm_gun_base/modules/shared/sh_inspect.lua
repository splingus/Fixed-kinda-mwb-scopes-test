function SWEP:Task_Inspect(cycle)
    if self:Clip1() == 0 and self.Animations.Inspect_Empty then 
        self:PlayAnimation(self.Animations.Inspect_Empty)
    elseif self.Animations.Inspect then
        self:PlayAnimation(self.Animations.Inspect)
    end
    self:SetCurrentTask("Finished")
end

concommand.Add("trmbase_weaponinspect" ,function(ply )
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") then
        if wep:CanInspect()  then
            wep:SetCurrentTask("Inspect")
        end
    end
end)

function SWEP:Task_Inspect(cycle)
    local animations = self.Animations
    if self:IsEmpty() and animations.Inspect_Empty then
        self:PlayAnimation("Inspect_Empty")
    elseif animations.Inspect then
        self:PlayAnimation("Inspect")
    end
        
    self:SetCurrentTask("Finished")

end

function SWEP:CanInspect()
    local task = self:GetCurrentTask()
    return (task == "Finished" or task == "Rechamber" or  string.find(task  ,"Sprint") )and (self.Animations.Inspect or self.Animations.Inspect_Empty) and not string.find(self:GetPlayingSequence(),"Inspect")
end 

function SWEP:IsInspecting()
    return string.find(self:GetPlayingSequence() , "Inspect")
end

