ATTACHMENT.Name = "Suppressor Pistol"
ATTACHMENT.Base = "att_suppressor"
ATTACHMENT.Category = "att_muzzle_pistol"
ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_suppressor_pistol.mdl")

function ATTACHMENT:ChangeWeaponStats(weapon)
    BASE_TRM_ATTS[self.Base]:ChangeWeaponStats(weapon)
    weapon.Primary.Damage = weapon.Primary.Damage * 0.95
    weapon.Aim.Time = weapon.Aim.Time * 1.1

end