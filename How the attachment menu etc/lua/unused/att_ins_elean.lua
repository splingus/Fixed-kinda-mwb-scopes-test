ATTACHMENT.Name = "Elean"
ATTACHMENT.Category = "att_sight"
ATTACHMENT.Base = "att_optic"
ATTACHMENT.Selectable = true
ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_optic_elcan.mdl")

ATTACHMENT.Angles  = Angle(-90,0,90)

ATTACHMENT.Sight = {
    Pos = Vector(0,0,  -1.8 ) ,
    Align = "scope_origin" ,
    Material = Material("models/weapons/tfa_ins2/optics/eotech_reticule") ,
    Size = 512 , 
    Color = Color(255,0,0)
}

ATTACHMENT.Scope = {
    Align = "scope_origin" ,
    Pos  = Vector(0,0,0) ,
    Ang = Angle(0,0,0),
    Size = 256 ,
    
}


function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Aim.Time = weapon.Aim.Time * 1.25
end