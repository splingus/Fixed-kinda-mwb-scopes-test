ATTACHMENT.Name = "P320 Laser"
ATTACHMENT.Model = Model("models/weapons/upgrades/a_laser_p320.mdl")
ATTACHMENT.Category = "att_laser_pistol"
ATTACHMENT.Base = "att_laser"
ATTACHMENT.Angles = Angle(-0,0,0)
ATTACHMENT.Pos = Vector(3.5,0,-0.5)
ATTACHMENT.Laser = {
    Attach = "Laser" ,
    Color = Color(149,239,255) , 
    Width = 1 , 
    DotSize = 2 ,
}

function ATTACHMENT:ChangeWeaponStats(stat )
    stat.Spread.Base = stat.Spread.Base * 0.75 
end