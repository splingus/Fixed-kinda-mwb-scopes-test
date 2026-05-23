ATTACHMENT.Name = "Eotech 552"
ATTACHMENT.Category = "att_sight"
ATTACHMENT.Base = "att_reticle"
ATTACHMENT.Selectable = true

ATTACHMENT.Angles  = Angle(-90,0,90)

ATTACHMENT.Sight = {
    Pos = Vector(0.00,0, -0.95 ) ,
    Align = "reticle" ,
    Material = Material("models/weapons/tfa_ins2/optics/eotech_reticule") ,
    Size = 5.12 , 
    Color = Color(255,0,0),
    HideMaterial = {2} , --Material Index
}

ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_optic_eotech.mdl")

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Aim.Time = weapon.Aim.Time * 1.1
end