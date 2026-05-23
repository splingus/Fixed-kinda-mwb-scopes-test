if not CLIENT then return end

function SWEP:Tracer(tr)
    local effect = EffectData()
    local effectName = "AR2Tracer"
    local vm = self:GetViewModel()
    effect:SetOrigin(tr.HitPos)
    effect:SetEntity(vm or self)
    effect:SetScale(500)
    effect:SetStart(self:GetTracerOrigin())

    util.Effect(effectName, effect)
end
