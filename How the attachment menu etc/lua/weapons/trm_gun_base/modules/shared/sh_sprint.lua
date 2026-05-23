local cvar_sprint_reload = CreateConVar("trmbase_allow_sprintreload", 0, {FCVAR_ARCHIVE})

function SWEP:CanSprint()
    local vm = self:GetViewModel(0)
    if not IsValid(vm) then return false end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
    local seq = self:GetPlayingSequence() or ""
    local task = self:GetCurrentTask() or ""
    
    -- 动画是否播放完毕
    local animFinished = self:GetNextAnimationTime() <= CurTime()
    
    -- 如果动画没播完，有些动作不能冲刺
    if not animFinished then
        -- 换弹动画未完成时，根据 cvar 决定
        if string.find(seq, "Reload") or string.find(task, "Reload") then
            return cvar_sprint_reload:GetBool()
        end
        
        -- 这些动画未完成时绝对不能冲刺
        local forbidAnims = {"Deploy", "Holster", "Inspect", "Melee", "Draw"}
        for _, v in ipairs(forbidAnims) do
            if string.find(seq, v) or string.find(task, v) then
                return false
            end
        end
    end
    
    -- 动画播完后，额外检查一些状态（防止残留）
    local blacklist = {"Deploy","Rechamber", "Holster", "Reload", "Inspect", "Melee", "Draw"}
    for _, v in ipairs(blacklist) do
        if string.find(task, v) or string.find(seq, v) then
            return false
        end
    end
    
    return true
end

function SWEP:Task_SprintIn(cycle)
    self:SetNextAnimationTime(0)
    if self:IsEmpty() and self.Animations.SprintIn_Empty then
        self:PlayAnimation("SprintIn_Empty"  )
    elseif self.Animations.SprintIn then
        self:PlayAnimation("SprintIn"  )
    end
    
    self:SetCurrentTask("Sprint")
end

function SWEP:Task_Sprint(cycle) 
    
    if self.Animations.Sprint_Empty and self:IsEmpty() then
        self:PlayAnimation("Sprint_Empty",true)
    elseif self.Animations.Sprint then
        self:PlayAnimation("Sprint",true)
    elseif self:IsEmpty() and self.Animations.Idle_Empty then 
        self:PlayAnimation("Idle_Empty" ,true)
    else
        self:PlayAnimation("Idle" ,true)
    end
    
    if self:GetOwner():KeyDown(IN_SPEED) == false or not self:GetOwner():OnGround() then
        self:SetCurrentTask("SprintOut")
    end
    

end



function SWEP:Task_SprintOut(cycle)
    self:SetNextAnimationTime(0)
    self:SetNextFireTime(0.0)
    if self:IsEmpty() and self.Animations.SprintOut_Empty then
        self:PlayAnimation("SprintOut_Empty" )
    elseif self.Animations.SprintOut then
        self:PlayAnimation("SprintOut")
    else
        self:Task_Idle()
    end
    self:SetCurrentTask("Finished")
    
end

function SWEP:Sprint()
    local currentTask = self:GetCurrentTask()
    local speed =   self:GetOwner():GetVelocity():Length2D()
    local runSpeed = self:GetOwner():GetRunSpeed()
    local radio = speed / runSpeed
    local sequence = self:GetPlayingSequence()
    -- 已经在冲刺相关状态中，不要干扰
    if currentTask == "SprintIn" or currentTask == "Sprint" or currentTask == "SprintOut"  then
        return
    end
    
    if self:GetOwner():KeyDown(IN_SPEED) and self:CanSprint() and radio > 0.8 and self:GetOwner():OnGround() then 
        self:SetCurrentTask("SprintIn")
    end
end
