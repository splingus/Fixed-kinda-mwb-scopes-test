ATTACHMENT.Name = "att_suppressor_base"
ATTACHMENT.Base = "att_base"
ATTACHMENT.Selectable = true

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Primary.Slienced = true
    
end