SWEP.Tasks = {}



function SWEP:TaskThink()
    local vm = self:GetViewModel()
    if not IsValid(vm) or (CLIENT and game.SinglePlayer()) and not IsFirstTimePredicted() then
        return
    end

    local task = self:GetCurrentTask()
    local cycle = vm:GetCycle()

    -- 任务映射表
    local taskMap = {
        Deploy = "Task_Deploy",
        Holster = "Task_Holster",
        Inspect = "Task_Inspect",
        Customize = "Task_Customize",
        PrimaryFire = "Task_PrimaryFire",
        SprintIn = "Task_SprintIn",
        Sprint = "Task_Sprint",
        SprintOut = "Task_SprintOut",
        AdsIn = "Task_AdsIn",
        AdsOut = "Task_AdsOut",
        Melee = "Task_Melee",
        Rechamber = "Task_Rechamber",
        Reload = "Task_Reload",
        ReloadLoop = "Task_ReloadLoop",
        ReloadEnd = "Task_ReloadEnd",
    }

    local funcName = taskMap[task]
    if funcName and self[funcName] then
        self[funcName](self, cycle)
    elseif task == "Finished" and cycle >= 0.98 then
        self:Task_Idle()
    end
end

function SWEP:Task_Idle()
    local animations = self.Animations
    self:SetNextAnimationTime(0)
    if self:IsEmpty() and animations.Idle_Empty then
        self:PlayAnimation("Idle_Empty")
    else
        self:PlayAnimation("Idle")
    end
end

concommand.Add("trmbase_debug_task", function(ply, cmd, args)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") then
        wep:SetCurrentTask(args[1] or "Idle")
    end
end)
