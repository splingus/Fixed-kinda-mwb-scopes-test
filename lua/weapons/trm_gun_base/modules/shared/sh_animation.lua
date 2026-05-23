function SWEP:PlayAnimation(sequenceClass, useInternalDuration )
    if not( IsFirstTimePredicted() and SERVER )then return end
    local vm = self:GetViewModel()
    if self:GetNextAnimationTime() > CurTime() then return end
    
    self:PlayWorldAnimation(sequenceClass)
    --print("Playing animation: Customize")
    if not vm  or not IsValid(vm) or not sequenceClass then
        return 
    end

    
    local animData = self.Animations[sequenceClass]  -- 修复1：用 [] 而不是 .
    if not animData then return end
    
    local seq = animData.sequence  -- 获取动画序列名列表
    if not seq or #seq == 0 then return end
    
    local sequencePlay = seq[math.Round(math.Rand(1, #seq))]  -- 修复2：直接用 #seq 获取长度
    
    self:SetPlayingSequence(sequenceClass)
    
    vm:SendViewModelMatchingSequence(vm:LookupSequence(sequencePlay))

    self:SetGrip1(true)
    self:SetGrip2(true)
    local duration = vm:SequenceDuration(vm:LookupSequence(sequencePlay))
    
    vm:SetCycle(0)


    if animData.events then  -- 修复3：从 animData 取 events
        for _, event in pairs(animData.events) do
            event.Triggered = false
        end
    end
    local speed = (animData.Speed or 1)
    vm:SetPlaybackRate(speed)

    if  useInternalDuration then
        local nexttime = (animData.RealLength or duration )*  (  animData.Length or 1 )  / speed
        self:SetNextAnimationTime( CurTime() + nexttime )
        self:SetNextFireTime(  nexttime )
    end
end

function SWEP:DoAnimationEvents()
    local vm = self:GetViewModel()
    if not vm or not IsValid(vm) then
        return 
    end

    local progress = vm:GetCycle()
    local sequenceClass = self:GetPlayingSequence()
    
    if not sequenceClass or not self.Animations or not self.Animations[sequenceClass] or not self.Animations[sequenceClass].events then 
        return 
    end 
    
    for _, event in pairs(  self.Animations[sequenceClass].events   ) do
        if not event or event.Triggered then 
            continue 
        end

        if progress >= event.time then
            if event.callback  then
                event.callback(self)
            end
            event.Triggered = true
        end
    end
end

function SWEP:PlayWorldAnimation(sequenceClass)
    if not SERVER then return end  -- 只在服务端执行，让所有玩家看到
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    -- 映射表：第一人称动画 → 第三人称动画（ACT）
    local animationTable = {
        -- 攻击类
        ["Fire"] = PLAYER_ATTACK1,
        ["Fire_Last"] = PLAYER_ATTACK1,
        ["Iron_Fire"] = PLAYER_ATTACK1,
        ["Iron_Fire_Last"] = PLAYER_ATTACK1,
        
        -- 换弹类
        ["Reload"] = PLAYER_RELOAD,
        ["Reload_Empty"] = PLAYER_RELOAD,
        ["Reload_Start"] = PLAYER_RELOAD,
        ["Reload_End"] = PLAYER_ATTACK1,
        
        -- 武器操作
        ["Draw"] = PLAYER_DEPLOY,
        ["Holster"] = PLAYER_HOLSTER,
        
        -- 待机
        ["Idle"] = PLAYER_IDLE,
        ["Idle_Empty"] = PLAYER_IDLE,
        ["Iron_Idle"] = PLAYER_IDLE,
        ["Iron_Idle_Empty"] = PLAYER_IDLE,
        
        -- 冲刺
        ["Sprint"] = PLAYER_RUN,
        ["Sprint_Empty"] = PLAYER_RUN,
        ["Sprint_In"] = PLAYER_RUN,
        ["Sprint_Out"] = PLAYER_RUN,
        
        -- 检视
        ["Inspect"] = PLAYER_IDLE,
        ["Inspect_Empty"] = PLAYER_IDLE,
        ["Melee"] = PLAYER_ATTACK1,
        ["Melee_Empty"] = PLAYER_ATTACK1,

    }
    
    
    
    local act = animationTable[sequenceClass]
    if act then
        owner:SetAnimation(act)
    end
end

-- function SWEP:PlayAnimation(sequenceClass, useInternalDuration)
--     -- 只让客户端播放第一人称动画
--     if SERVER then
--         -- 服务端：广播动画，但不播
--         self:CallOnClient("PlayAnimation", sequenceClass, useInternalDuration)
--         self:PlayWorldAnimation(sequenceClass)  -- 第三人称
--         return
--     end

--     -- 客户端：真正播放
--     if not IsFirstTimePredicted() then return end
--     local vm = self:GetViewModel()
--     if self:GetNextAnimationTime() > CurTime() then return end
--     if not IsValid(vm) or not sequenceClass then return end

--     local animData = self.Animations[sequenceClass]
--     if not animData then return end

--     local seq = animData.sequence
--     if not seq or #seq == 0 then return end

--     local sequencePlay = seq[math.Round(math.Rand(1, #seq))]

--     self:SetPlayingSequence(sequenceClass)

--     local seqId = vm:LookupSequence(sequencePlay)
--     if seqId and seqId > 0 then
--         vm:SendViewModelMatchingSequence(seqId)
--         vm:SetCycle(0)

--         local speed = animData.Speed or 1
--         vm:SetPlaybackRate(speed)

--         if animData.events then
--             for _, event in pairs(animData.events) do
--                 event.Triggered = false
--             end
--         end
--     end

--     if useInternalDuration then
--         local duration = self:SequenceDuration(seqId or 1)
--         local nexttime = (animData.Length or 1) * duration / (animData.Speed or 1)
--         self:SetNextAnimationTime(CurTime() + nexttime)
--         self:SetNextFireTime(nexttime)
--     end
-- end