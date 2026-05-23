ATTACHMENT.Name = "Kobra"
ATTACHMENT.Category = "att_sight"
ATTACHMENT.Base = "att_reticle"
ATTACHMENT.Selectable = true

ATTACHMENT.Angles  = Angle(-90,0,90)

ATTACHMENT.Sight = {
    Pos = Vector(0.00,0, -0.45 ) ,
    Align = "reticle" ,
    Material = Material("models/weapons/tfa_ins2/optics/kobra_dot") ,
    Size = 2.56 , 
    Color = Color(255,0,0),
    HideMaterial = {2} , --Material Index
    Rotate = 90 ,
}

ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_optic_kobra.mdl")

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Aim.Time = weapon.Aim.Time * 1.1
end