function SWEP:CanMelee()
    local seq = self:GetPlayingSequence()

    if  CurTime() > self:GetNextPrimaryFire() and self.Melee.Enabled then
        return true
    end


    if not  string.find(seq,"Melee") and self.Melee.Enabled  then
        return true
    end
    return false 
end

function SWEP:Task_Melee()
    self:SetNextAnimationTime(0)
    local animations = self.Animations
    if self:IsEmpty() and animations.Melee_Empty then
        self:PlayAnimation("Melee_Empty",true)
    elseif animations.Melee then
        self:PlayAnimation("Melee",true)
    end
    self:SetCurrentTask("Finished")
end

concommand.Add("trmbase_melee",function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") then
        if wep:CanMelee() then
            wep:SetCurrentTask("Melee")
        end
    end
end)

function SWEP:DealMeleeDamage()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local startPos = owner:GetShootPos()
    local forward = owner:GetAimVector()
    local range = self.Melee.Range or 200
    local damage = self.Melee.Damage or 40
    local radius = self.Melee.Radius or 32  -- 增大判定半径
    
    local endPos = startPos + forward * range
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        filter = owner,
        mins = Vector(-10, -5, -0),
        maxs = Vector(10, 5, 5),
       -- mask = MASK_SHOT_HULL,
    })
    
    
    local dmginfo = DamageInfo()
        dmginfo:SetDamage(damage)
        dmginfo:SetAttacker(owner)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageForce(forward * (self.Melee.Force or 10))
        dmginfo:SetDamageType(DMG_CLUB)
    
    if not tr.Hit then return end
    self:MeleeDoor(tr)
    local ent = tr.Entity
    if not (game.SinglePlayer() and CLIENT ) then
        self:EmitSound(self.Melee.Sound)
    end
    if CLIENT then return end

    if IsValid(ent) and ent.TakeDamageInfo then
        ent:TakeDamageInfo(dmginfo)
        --self:ImpactEffects(tr,type)
    end

    local phys

	if ent:IsRagdoll() then
		phys = ent:GetPhysicsObjectNum(tr.PhysicsBone or 0)
	else
		phys = ent:GetPhysicsObject()
	end

	if IsValid(phys) then
		if ent:IsPlayer() or ent:IsNPC() then
			ent:SetVelocity(owner:GetAimVector() * damage * 0.5)
			phys:SetVelocity(phys:GetVelocity() + forward * damage * 0.5)
		else
			phys:ApplyForceOffset(forward * damage * 0.5, tr.HitPos)
		end
	end
end
 
function SWEP:MeleeDoor(tr)
    if CLIENT or not IsValid(tr.Entity) then return end
    local ent =tr.Entity
    if not (ent:GetClass() == "prop_door_rotating" or  ent:GetClass() == "func_door_rotating" ) then return end
    ent:EmitSound("ambient/materials/door_hit1.wav", 100, math.random(80, 120))
    ent:SetKeyValue("Speed", "500")
    ent:SetKeyValue("Open Direction", "Both directions")
    --ent:SetKeyValue("opendir", "0")
    ent:Fire("openawayfrom", self:GetOwner():EntIndex(), 0)

    timer.Simple(0.3, function()
			if IsValid(ent) then
				ent:SetKeyValue("Speed", "100")
			end
	end)

end