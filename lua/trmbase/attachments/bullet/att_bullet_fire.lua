ATTACHMENT.Base = "att_bullet"
ATTACHMENT.Name = "Fire"
ATTACHMENT.Category = "att_bullet"

function ATTACHMENT:BulletCallback(attacker, tr, dmginfo)
    dmginfo:SetDamageType(DMG_BLAST)
    if tr and tr.Entity and tr.Entity.Ignite then
        tr.Entity:Ignite(5,1)
    end
end

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Recoil.Vertical[2] = weapon.Recoil.Vertical[2] * 1.5
    weapon.Primary.Damage = weapon.Primary.Damage * 0.55
    weapon.Spread.Base = weapon.Spread.Base * 1.5

    weapon.PrintName = weapon.PrintName .. " FireBullets"
end

function ATTACHMENT:DoImpactEffect(tr,type)
    if  not tr or not tr.HitPos then return end
    local effect = EffectData()
    effect:SetOrigin(tr.HitPos)
    effect:SetMagnitude(10)
    effect:SetScale(10)
    effect:SetFlags(0)
    util.Effect("Explosion",effect)

end