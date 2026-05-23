ATTACHMENT.Name = "att_laser"
ATTACHMENT.Category = nil 
ATTACHMENT.Base = "att_base"
ATTACHMENT.Selectable = true

ATTACHMENT.Laser = {
    Attach = "Laser",
    Color = Color(255,0,0,197),
    Width = 1,
    DotSize = 4,
}

-- 材质缓存（放在配件表上，不是 self）
local lineMat = nil
local dotMat = nil

function ATTACHMENT:GetLineMat()
    if not lineMat then
        lineMat = Material("sprites/physbeam")
    end
    return lineMat
end

function ATTACHMENT:GetDotMat()
    if not dotMat then
        dotMat = CreateMaterial("trmbase_laserdot", "UnLitGeneric", {
            ["$basetexture"] = "sun/overlay",
            ['$additive'] = 1,
            ['$vertexalpha'] = 1,
            ['$vertexcolor'] = 1,
        })
    end
    return dotMat
end

function ATTACHMENT:DoLaserRender(weapon, model, data)
    if not self.Laser then return end

    local attID = model:LookupAttachment(data.Attach)
    if attID <= 0 then return end
    
    local att = model:GetAttachment(attID)
    if not att then return end

    -- 缓存射线结果
    if not self._nextTrace or CurTime() > self._nextTrace then
        self._lastTrace = util.TraceLine({
            start = att.Pos + att.Ang:Forward() * -10,
            endpos = att.Pos + att.Ang:Forward() * 1000,
            filter = {weapon, weapon:GetOwner()},
            mask = MASK_SHOT
        })
        local updateFps = 60
        self._nextTrace = CurTime() + math.min(1 / updateFps ,RealFrameTime() )
    end

    local tr = self._lastTrace
    if not tr then return end

    render.SetMaterial(self:GetLineMat())
    render.DrawBeam(att.Pos, tr.HitPos or tr.endpos, data.Width * math.random(0.5,1), 0, 1, data.Color)

    if tr.Hit then
        render.SetMaterial(self:GetDotMat())
        render.DrawSprite(tr.HitPos, data.DotSize, data.DotSize, data.Color)
    end
end

function ATTACHMENT:Render(weapon, model)
    model:DrawModel()
    self:DoLaserRender(weapon, model, self.Laser)
end