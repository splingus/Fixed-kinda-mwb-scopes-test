ATTACHMENT.Name = "ANPEQ15 Rainbow"
ATTACHMENT.Category = "att_laser"
ATTACHMENT.Base = "att_laser_apeq01"

local function HSVToRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs(math.fmod(h / 60, 2) - 1))
    local m = v - c
    local r, g, b
    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return (r + m) * 255, (g + m) * 255, (b + m) * 255
end

function ATTACHMENT:Render(weapon, model)
    -- 更新颜色（5fps）
    if not self._nextColorUpdate or CurTime() >= self._nextColorUpdate then
        local hue = math.fmod(CurTime() * 240, 360)
        local r, g, b = HSVToRGB(hue, 1, 1)
        self.Laser.Color = Color(r, g, b, 197)
        self._nextColorUpdate = CurTime() + math.max(1/5,RealFrameTime())
    end

    -- 画模型
    model:DrawModel()

    -- 获取激光附件
    local attID = model:LookupAttachment(self.Laser.Attach or "Laser")
    if attID <= 0 then return end
    
    local att = model:GetAttachment(attID)
    if not att then return end

    -- 射线检测（限制频率）
    local now = CurTime()
    if not self._nextTrace or now >= self._nextTrace then
        self._lastTrace = util.TraceLine({
            start = att.Pos + att.Ang:Forward() * -10,
            endpos = att.Pos + att.Ang:Forward() * 1000,
            filter = {weapon, weapon:GetOwner()},
            mask = MASK_SHOT
        })
        self._nextTrace = now + math.max(1/60,RealFrameTime())  -- 最多 60fps
    end

    local tr = self._lastTrace
    if not tr then return end

    -- 画激光（每帧）
    local lineMat = Material("sprites/physbeam")
    render.SetMaterial(lineMat)
    render.DrawBeam(att.Pos, tr.HitPos or tr.endpos, self.Laser.Width or 2, 0, 1, self.Laser.Color)

    if tr.Hit then
        local dotMat = Material("sprites/glow04_noz")
        render.SetMaterial(dotMat)
        render.DrawSprite(tr.HitPos, self.Laser.DotSize or 4, self.Laser.DotSize or 4, self.Laser.Color)
    end
end