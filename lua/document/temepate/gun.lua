SWEP.Base = "trm_gun_base"

SWEP.Category = "TriggerBase Weapon"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "武器名称"
SWEP.Author = "作者名"
SWEP.Purpose = ""
SWEP.DrawCrosshair = false
SWEP.DrawCrossHairIS = false

-- 模型
SWEP.ViewModel = "models/weapons/xxx.mdl"
SWEP.UseHands = true
SWEP.ViewModelFOV = 70
SWEP.WorldModel = "models/weapons/xxx.mdl"

-- 基础属性
SWEP.RenderGroup = RENDERGROUP_OPAQUE
SWEP.RenderMode = RENDERMODE_NORMAL
SWEP.BobScale = 0
SWEP.SwayScale = 0
SWEP.IconHeightRadio = 1.5
SWEP.Slot = 2
SWEP.m_WeaponDeploySpeed = 1

-- 弹药
SWEP.Primary.ClipSize = 30
SWEP.Primary.Chamber = 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Ammo = "ar2"
SWEP.Primary.SpecialAmmo = -1
SWEP.Primary.RPM = 700
SWEP.Primary.Automatic = true
SWEP.Primary.Damage = 34
SWEP.Primary.Force = 1
SWEP.Primary.NumBullets = 1

-- 音效
SWEP.Primary.Sound = Sound("武器.开火")
SWEP.Primary.SliencedSound = Sound("武器.消音开火")
SWEP.Primary.Slienced = false

-- 换弹类型
SWEP.ReloadType = "Magzine"

-- 视角偏移
SWEP.VMOffset = {
    Idle = { Pos = Vector(0, 2, 1), Ang = Angle(0, 0, 0) },
    Sprint = { Pos = Vector(0, 0, 0), Ang = Angle(0, 0, 0) },
    Crouch = { Pos = Vector(-2, 0, 3), Ang = Angle(0, 0, -15) }
}

-- 特效
SWEP.Effects = {
    Muzzle = { effect = "MuzzleEffect", attachment = "muzzle" },
    Shell = {
        attachment = "shell",
        effect = "RifleShellEject",
        Pos = Vector(0, 0, 0),
        Ang = Angle(20, 0, 0),
        Magnitude = 10,
        Primary = true,
    }
}

SWEP.HoldType = "ar2"

-- 世界模型偏移
SWEP.Offset = { Pos = Vector(1, 0, 0), Ang = Angle(0, 0, 180) }

-- 瞄准配置
SWEP.Sight = {
    Origin = "muzzle",
    Align = nil,         -- 瞄准参考附件点，替换为你的 viewmodel 上的 ironsight 附件名
    Angles = Angle(0, 0, -90),
    Pos = Vector(-3.07, -1, 0.1),
    Type = "Attachment"
}

-- 后坐力
SWEP.Recoil = {
    Vertical = {2, 2},
    Horizonal = {-0.3, 0.3},
    AdsMultiplier = 0.1,
    KickDown = 1,
    Shake = 0.8,
}

-- 视觉后坐力
SWEP.VisualRecoil = {
    Vertical = {1, 1},
    Horizonal = {-0.1, 0.1},
    Backward = {0.1, 0.1, 1},
    RecoverSpeed = 0.1,
    RecoverDelay = 0.1,
    AdsMultiplier = 1,
}

-- 散布
SWEP.Spread = {
    Base = 0.009,
    Vertical = 1.0,
    Horizontal = 1.0,
    Max = 0.2,
    Increase = 0.01,
    Recover = 0.3,
    Delay = 0.1,
}

-- 瞄准
SWEP.Aim = {
    Spread = 0.005,
    SpreadFollowPrimary = false,
    Scale = 1.3,
    Time = 0.4,
}

SWEP.MoveSpeed = { Walk = 0.95, Run = 1, Aim = 0.8 }
SWEP.CameraAttachment = "Camera"
SWEP.AltSwitch = false

-- 动画
SWEP.Animations = {
    ["Draw"] = { sequence = {"base_draw"} },
    ["Draw_First"] = { sequence = {"base_ready"} },
    ["Holster"] = { sequence = {"base_holster"} },
    ["Idle"] = { sequence = {"base_idle"} },
    ["Idle_Empty"] = { sequence = {"empty_idle"} },
    ["Iron_Idle"] = { sequence = {"base_idle"} },
    ["Sprint"] = { sequence = {"base_sprint"}, Speed = 1.1 },
    ["Sprint_Empty"] = { sequence = {"empty_sprint"}, Speed = 1.1 },
    ["Fire"] = { sequence = {"base_fire"} },
    ["Fire_Last"] = { sequence = {"base_fire_last"} },
    ["Iron_Fire"] = { sequence = {"iron_fire"} },
    ["Iron_Fire_Last"] = { sequence = {"iron_fire_last"} },
    ["Reload"] = { sequence = {"base_reload"}, Speed = 1.2, Length = 1, events = { { time = 0.5, callback = function(self) self:MagzineLoaded() end } } },
    ["Reload_Empty"] = { sequence = {"base_reloadempty"}, Speed = 1.2, Length = 1, events = { { time = 0.5, callback = function(self) self:MagzineLoaded() end } } },
}

-- 配件槽位
SWEP.Attachments = {
    {
        Name = "Muzzle",
        Category = {"att_muzzle"},
        Pos = Vector(0, 0, 0),
        Ang = Angle(0, 0, 0),
        Bone = "A_Muzzle",
    },
}