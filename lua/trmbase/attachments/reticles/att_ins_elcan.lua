ATTACHMENT.Name = "Elcan 4x"
ATTACHMENT.Category = "att_sight"
ATTACHMENT.Base = "att_optic"
ATTACHMENT.Selectable = true
ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_optic_elcan.mdl")

ATTACHMENT.Angles = Angle(-90, 0, 90)

ATTACHMENT.Sight = {
    Pos = Vector(0, -1.8, -1.8),
    Align = "scope_origin",
    Material = Material("models/weapons/tfa_ins2/optics/elcan_reticule"),
    Size = 360,
    Color = Color(255, 255, 255)
}

ATTACHMENT.Scope = {
    Align = "scope_origin",
    Magnification = 4,
    FOV = 18,
    RTSize = 1024,
    ScreenScale = 0.62,
    CenterOverlay = true,
    HideModelInScope = true,
    ReticleSize = 230,
    LensSize = 2.1,
    ReticleWorldSize = 1.45,
    ReticleDepth = -0.18,
    ReticleLineColor = Color(0, 0, 0, 245),
    Parallax = 0.08,
    ParallaxMax = 0.12,
    BackdropAlpha = 245,
    ScreenOverlay = true,
    Use3D = false,
    UseMaterialReticle = false,
    UseMaterialReticle3D = false,
    TextureRotate = 0,
    DrawAt = 0.35,
    ZNear = 4
}

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Aim.Time = weapon.Aim.Time * 1.25
    weapon.Aim.Scale = math.max(weapon.Aim.Scale or 1, 1.15)
end
