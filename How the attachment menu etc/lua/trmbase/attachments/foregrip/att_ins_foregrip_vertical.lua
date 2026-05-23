ATTACHMENT.Name = "INS Foregrip"
ATTACHMENT.Category = "att_grip_vert"
ATTACHMENT.Base = "att_base"
ATTACHMENT.Bonemerge = false 
ATTACHMENT.Pos = Vector(-2,0,-0.5)
ATTACHMENT.Scale = 0.5
ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_foregrip_ins.mdl")

ATTACHMENT.poseParameter = {
    "grip_vert_offset",
}

function ATTACHMENT:ChangeWeaponStats(weapon)
    self:ScaleTableValue(   weapon.VisualRecoil.Vertical , 0.5 ) 
end