ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_magazine"
--ATTACHMENT.Category = "att_bullet"
ATTACHMENT.Description = "The Base for Weapon"

--for gameplay mag
ATTACHMENT.BulletList = {}

--for animation mag (offhand) from mwb
ATTACHMENT.ReserveBulletList = {}

ATTACHMENT.PoseParameter = "bullets_offset" --the spring

local small = Vector()
local normal = Vector(1, 1, 1)




function ATTACHMENT:Render(weapon,model)
    BASE_TRM_ATTS[self.Base]:Render(weapon,model)

    if (!weapon:IsCarriedByLocalPlayer()) then
        return
    end

    if (!weapon:IsReloading()) then
        -- model._clip = weapon:Clip1()
        -- model._ammo = weapon:Ammo1()
        --不知道这个干嘛的
        self:SetMagFollowerPoseParam(weapon, model ,weapon:GetMaxClip1() - weapon:Clip1())
    end

    
end

function ATTACHMENT:SetMagFollowerPoseParam(weapon, model ,val)
    local ppid = model:LookupPoseParameter(self.PoseParameter)
    local min, max = model:GetPoseParameterRange(ppid)
    min = min || 0
    max = max || 1
    
    model:SetPoseParameter(self.PoseParameter, math.Clamp(val, min, max))

    

end