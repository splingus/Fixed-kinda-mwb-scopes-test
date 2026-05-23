ATTACHMENT.Name = "INS Foregrip Sec 2"
ATTACHMENT.Category = "att_grip_vert"
ATTACHMENT.Base = "att_base"
ATTACHMENT.Bonemerge = false 
ATTACHMENT.Pos = Vector(-2,0,-0.0)
ATTACHMENT.Scale = 0.5
ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_foregrip_sec2.mdl")

ATTACHMENT.poseParameter = {
    "grip_vert_offset",
}

function ATTACHMENT:ChangeWeaponStats(weapon)
    self:ScaleTableValue(   weapon.VisualRecoil.Vertical , 0.8 ) 
    weapon.Aim.Time = weapon.Aim.Time * 0.8
end