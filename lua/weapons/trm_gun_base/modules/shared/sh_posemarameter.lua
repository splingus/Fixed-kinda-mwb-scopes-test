-- =============================================
-- Pose 参数更新（合并四合一，减少重复 GetViewModel / GetVelocity）
-- =============================================

function SWEP:LookupRangeCache(name)
    if not self.vm_PoseParameterRangeCache then
        self.vm_PoseParameterRangeCache = {}
    end
    if not self.vm_PoseParameterRangeCache[name] then
        local vm = self:GetViewModel()
        local min, max = vm:GetPoseParameterRange(vm:LookupPoseParameter(name))
        self.vm_PoseParameterRangeCache[name] = max
    else
        return self.vm_PoseParameterRangeCache[name]
    end
    return 1
end

function SWEP:UpdatePoseParameters()
    if SERVER then return end


    local vm = self:GetViewModel()
    if not IsValid(vm) then return end

    -- 速度乘相关（只算一次）
    local owner = self:GetOwner()
    local speed = IsValid(owner) and owner:GetVelocity():Length2D() or 0
    local runSpeed = IsValid(owner) and owner:GetRunSpeed() or 1
    local walkSpeed = IsValid(owner) and owner:GetWalkSpeed() or 1
    local dt = engine.TickInterval() * 0.5

    -- Aim Pose
    if self.Sight and self.Sight.PoseParameter then
        self.m_AimPose = Lerp(dt * 20, self.m_AimPose or 0, self:GetAimDelta()) or 0
        for _, Pose in pairs(self.Sight.PoseParameter) do
            vm:SetPoseParameter(Pose, self.m_AimPose)
        end
    end

    -- Sprint Pose
    if self.BasePoseParameter and self.BasePoseParameter.Sprint then
        local sprintVal = self:CanSprint() and speed > walkSpeed and self:GetSprintDelta() or 0
        self.m_SprintPose = Lerp(dt * 10, self.m_SprintPose or 0, sprintVal) or 0
        for _, Pose in pairs(self.BasePoseParameter.Sprint) do
            local max = self:LookupRangeCache(Pose) or 1
            vm:SetPoseParameter(Pose, self.m_SprintPose * max)
        end
    end

    -- Empty Pose
    if self.BasePoseParameter and self.BasePoseParameter.Empty then
        self.m_EmptyPose = Lerp(dt * 10, self.m_EmptyPose or 0, self:IsEmpty() and 1 or 0) or 0
        for _, Pose in pairs(self.BasePoseParameter.Empty) do
            vm:SetPoseParameter(Pose, self.m_EmptyPose)
        end
    end

    -- Walk Pose
    if self.BasePoseParameter and self.BasePoseParameter.Walk then
        local walkVal = self:GetAimDelta() < 0.25 and (speed / walkSpeed) * (1 - self:GetSprintDelta()) or 0
        self.m_WalkPose = Lerp(dt * 10, self.m_WalkPose or 0, walkVal) or 0
        for _, Pose in pairs(self.BasePoseParameter.Walk) do
            vm:SetPoseParameter(Pose, self.m_WalkPose)
        end
    end

    --PrintTable(self.m_PoseParameter)

    if self.m_PoseParameter then
        self.m_grippose = Lerp(dt * 10, self.m_grippose or 0, (self:GetGrip1() and 1 or 0))
        for _, poseName in pairs(self.m_PoseParameter) do
            vm:SetPoseParameter(poseName, self:LookupRangeCache(poseName) * self.m_grippose)
        end
    end

    if self.m_PoseParameter2 then
        self.m_grippose2 = Lerp(dt * 10, self.m_grippose2 or 0, (self:GetGrip2() and 1 or 0))
        for _, poseName in pairs(self.m_PoseParameter2) do
            vm:SetPoseParameter(poseName, self:LookupRangeCache(poseName) * self.m_grippose2)
        end
    end
end
