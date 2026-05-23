ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_optic"
ATTACHMENT.Description = "The Base for Magnified Optics"
ATTACHMENT.Selectable = false

local fallbackReticle = Material("models/weapons/tfa_ins2/optics/aimpoint_reticule")

local function GetScopeConfig(att)
    att.Scope = att.Scope or {}
    att.Sight = att.Sight or {}
    return att.Scope
end

local function GetScopeAlign(att)
    local scope = GetScopeConfig(att)
    return scope.Align or (att.Sight and att.Sight.Align) or "scope_origin"
end

local function GetScopeRT(att, wep)
    local scope = GetScopeConfig(att)
    local size = scope.RTSize or 1024
    local name = "trm_scope_rt_" .. wep:EntIndex() .. "_" .. tostring(att.Name or "optic")

    if not att._ScopeRT or att._ScopeRTSize ~= size then
        att._ScopeRT = GetRenderTarget(name, size, size)
        att._ScopeRTSize = size
        att._ScopeMaterial = CreateMaterial(name .. "_mat", "UnlitGeneric", {
            ["$basetexture"] = att._ScopeRT:GetName(),
            ["$translucent"] = "1",
            ["$vertexalpha"] = "1",
            ["$vertexcolor"] = "1",
            ["$nocull"] = "1",
            ["$ignorez"] = "1"
        })
    end

    return att._ScopeRT, att._ScopeMaterial
end

local function GetAimAlpha(att, wep)
    local scope = GetScopeConfig(att)
    local aimDelta = wep.GetAimDelta and wep:GetAimDelta() or 1
    local drawAt = scope.DrawAt or 0.35
    if aimDelta <= drawAt then return 0 end
    return math.Clamp((aimDelta - drawAt) / (1 - drawAt), 0, 1)
end

local function DrawTexturedCircle(x, y, radius, segments, textureRotate)
    local verts = {}
    segments = segments or 96
    textureRotate = math.rad(textureRotate or 0)
    local rotCos = math.cos(textureRotate)
    local rotSin = math.sin(textureRotate)

    table.insert(verts, { x = x, y = y, u = 0.5, v = 0.5 })
    for i = 0, segments do
        local r = math.rad((i / segments) * 360)
        local cx = math.cos(r)
        local cy = math.sin(r)
        local u = cx * rotCos - cy * rotSin
        local v = cx * rotSin + cy * rotCos

        table.insert(verts, {
            x = x + cx * radius,
            y = y + cy * radius,
            u = 0.5 + u * 0.5,
            v = 0.5 + v * 0.5
        })
    end

    surface.DrawPoly(verts)
end

local function DrawReticle2D(att, scope, x, y, radius, alpha)
    local ret = att.Sight or {}
    local retMat = ret.Material or scope.ReticleMaterial or fallbackReticle
    local retColor = ret.Color or Color(255, 255, 255)
    local lineColor = scope.ReticleLineColor or Color(20, 20, 20, 235)
    local retSize = scope.ReticleSize or ret.ReticleSize or math.min(radius * 1.45, ret.Size or radius * 1.25)

    if scope.UseMaterialReticle == true and retMat then
        surface.SetMaterial(retMat)
        surface.SetDrawColor(retColor.r, retColor.g, retColor.b, (retColor.a or 255) * alpha)
        surface.DrawTexturedRectRotated(x, y, retSize, retSize, ret.Rotate or scope.ReticleRotate or 0)
    end

    local gap = radius * 0.035
    local fineLen = radius * 0.2
    local postStart = radius * 0.55
    local postLen = radius * 0.18
    local thick = math.max(1, math.floor(radius * 0.004))
    local postThick = math.max(2, math.floor(radius * 0.012))

    surface.SetDrawColor(lineColor.r, lineColor.g, lineColor.b, (lineColor.a or 235) * alpha)
    surface.DrawRect(x - thick * 0.5, y - gap - fineLen, thick, fineLen)
    surface.DrawRect(x - thick * 0.5, y + gap, thick, fineLen)
    surface.DrawRect(x - gap - fineLen, y - thick * 0.5, fineLen, thick)
    surface.DrawRect(x + gap, y - thick * 0.5, fineLen, thick)
    surface.DrawRect(x - thick * 0.5, y - thick * 0.5, thick, thick)

    surface.DrawRect(x - postStart - postLen, y - postThick * 0.5, postLen, postThick)
    surface.DrawRect(x + postStart, y - postThick * 0.5, postLen, postThick)
    surface.DrawRect(x - postThick * 0.5, y + postStart, postThick, postLen)
end

local function DrawScopeEdge(x, y, radius, alpha)
    surface.SetDrawColor(0, 0, 0, 255 * alpha)
    for i = 0, 10 do
        surface.DrawCircle(x, y, radius + i, 0, 0, 0, 255 * alpha)
    end

    surface.SetDrawColor(255, 255, 255, 32 * alpha)
    surface.DrawCircle(x, y, radius - 5, 255, 255, 255, 32 * alpha)
    surface.DrawCircle(x, y, radius - 11, 255, 255, 255, 18 * alpha)

    surface.SetDrawColor(0, 0, 0, 70 * alpha)
    surface.DrawCircle(x, y, radius * 0.74, 0, 0, 0, 70 * alpha)
end

local function RenderScopeView(att, wep)
    local owner = wep:GetOwner()
    if not IsValid(owner) then return end

    local scope = GetScopeConfig(att)
    local rt = GetScopeRT(att, wep)
    if not rt then return end
    local rtSize = scope.RTSize or 1024

    local baseFOV = owner:GetFOV()
    if baseFOV <= 0 then baseFOV = GetConVar("fov_desired"):GetInt() end

    local mag = scope.Magnification or scope.Zoom or att.Magnification or 4
    local fov = scope.FOV or math.Clamp(baseFOV / mag, 5, 45)
    local eyeAng = owner:EyeAngles()
    local ang = Angle(eyeAng.p, eyeAng.y, eyeAng.r)

    if wep.GetVisualRecoil then
        ang = ang + wep:GetVisualRecoil()
    end

    if scope.CameraAngle then
        ang = ang + scope.CameraAngle
    end

    render.PushRenderTarget(rt)
        render.Clear(0, 0, 0, 255, true, true)
        render.RenderView({
            x = 0,
            y = 0,
            w = rtSize,
            h = rtSize,
            aspect = 1,
            origin = owner:EyePos() + ang:Forward() * (scope.CameraForward or 1),
            angles = ang,
            fov = fov,
            drawviewmodel = false,
            drawhud = false,
            dopostprocess = false,
            znear = scope.ZNear or 4,
            zfar = scope.ZFar
        })
    render.PopRenderTarget()
end

local function GetParallaxOffset(scope, scopeAtt, owner, worldSize)
    local strength = scope.Parallax or 0.12
    if strength <= 0 or not IsValid(owner) then return 0, 0 end

    local eyeDir = (owner:EyePos() - scopeAtt.Pos):GetNormalized()
    local maxOffset = worldSize * (scope.ParallaxMax or 0.18)
    local x = math.Clamp(eyeDir:Dot(scopeAtt.Ang:Right()) * worldSize * strength, -maxOffset, maxOffset)
    local y = math.Clamp(eyeDir:Dot(scopeAtt.Ang:Up()) * worldSize * strength, -maxOffset, maxOffset)
    return x, y
end

local function DrawScope3D(att, wep, scopeAtt)
    local scope = GetScopeConfig(att)
    if scope.Use3D == false then return end
    if scope.ScreenOverlay == true and scope.Draw3DWithOverlay ~= true then return end

    local owner = wep:GetOwner()
    local alpha = GetAimAlpha(att, wep)
    if alpha <= 0 then return end

    local rt, rtMat = GetScopeRT(att, wep)
    if not rt or not rtMat then return end

    local forward = scopeAtt.Ang:Forward()
    local right = scopeAtt.Ang:Right()
    local up = scopeAtt.Ang:Up()
    local normal = forward:GetNegated()
    local lensSize = scope.LensSize or scope.WorldSize or 2.25
    local lensPos = scopeAtt.Pos + forward * (scope.LensOffset or -0.08)
    local roll = -(scopeAtt.Ang.r or 0) + (scope.LensRotate or 180)

    render.SetMaterial(rtMat)
    render.DrawQuadEasy(lensPos, normal, lensSize, lensSize, Color(255, 255, 255, 255 * alpha), roll)

    local ret = att.Sight or {}
    local retMat = ret.Material or scope.ReticleMaterial or fallbackReticle
    if retMat or scope.UseMaterialReticle3D == false then
        local px, py = GetParallaxOffset(scope, scopeAtt, owner, lensSize)
        local retSize = scope.ReticleWorldSize or lensSize * (scope.ReticleScale or 0.82)
        local retColor = ret.Color or Color(255, 255, 255)
        local retPos = lensPos + forward * (scope.ReticleDepth or -0.16) + right * px + up * py

        if scope.UseMaterialReticle3D ~= false and retMat then
            render.SetMaterial(retMat)
            render.DrawQuadEasy(retPos, normal, retSize, retSize,
                Color(retColor.r, retColor.g, retColor.b, (retColor.a or 255) * alpha),
                roll + (ret.Rotate or scope.ReticleRotate or 0))
        end

        local lineColor = scope.ReticleLineColor or Color(20, 20, 20, 235)
        local gap = retSize * 0.04
        local len = retSize * 0.2
        render.DrawLine(retPos + up * gap, retPos + up * (gap + len), lineColor, false)
        render.DrawLine(retPos - up * gap, retPos - up * (gap + len), lineColor, false)
        render.DrawLine(retPos + right * gap, retPos + right * (gap + len), lineColor, false)
        render.DrawLine(retPos - right * gap, retPos - right * (gap + len), lineColor, false)
    end
end

local function DrawScopeOverlay(att, wep, screen)
    local scope = GetScopeConfig(att)
    if scope.ScreenOverlay == false then return end

    local rt, rtMat = GetScopeRT(att, wep)
    if not rt or not rtMat then return end

    local alpha = GetAimAlpha(att, wep)
    if alpha <= 0 then return end

    local screenSize = scope.ScreenSize or scope.Size or att.Sight.Size or 420
    if scope.ScreenScale then
        screenSize = math.min(ScrW(), ScrH()) * scope.ScreenScale
    end

    local radius = screenSize * 0.5
    local x = (scope.CenterOverlay ~= false) and (ScrW() * 0.5) or screen.x
    local y = (scope.CenterOverlay ~= false) and (ScrH() * 0.5) or screen.y

    x = x + (scope.ScreenOffset and scope.ScreenOffset.x or 0)
    y = y + (scope.ScreenOffset and scope.ScreenOffset.y or 0)

    cam.Start2D()
        surface.SetDrawColor(0, 0, 0, (scope.BackdropAlpha or 170) * alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())

        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 255 * alpha)
        DrawTexturedCircle(x, y, radius + 34, scope.Segments or 144, 0)
        surface.SetDrawColor(8, 8, 8, 245 * alpha)
        DrawTexturedCircle(x, y, radius + 17, scope.Segments or 144, 0)

        surface.SetMaterial(rtMat)
        surface.SetDrawColor(255, 255, 255, 255 * alpha)
        DrawTexturedCircle(x, y, radius, scope.Segments or 128, scope.TextureRotate or scope.ScreenRotate or 0)

        DrawReticle2D(att, scope, x, y, radius, alpha)

        DrawScopeEdge(x, y, radius, alpha)
    cam.End2D()
end

function ATTACHMENT:Render(wep, model)
    if not IsValid(model) then return end
    if not wep:IsCarriedByLocalPlayer() then
        model:DrawModel()
        return
    end
    self:RenderScope(wep, model)
end

function ATTACHMENT:RenderScope(wep, model)
    local alignID = model:LookupAttachment(GetScopeAlign(self))
    if alignID <= 0 then
        model:DrawModel()
        return
    end

    local scopeAtt = model:GetAttachment(alignID)
    if not scopeAtt then return end
    local alpha = GetAimAlpha(self, wep)

    local scope = GetScopeConfig(self)
    if alpha <= 0 or scope.HideModelInScope ~= true then
        model:DrawModel()
    end

    if alpha <= 0 then return end

    RenderScopeView(self, wep)
    DrawScope3D(self, wep, scopeAtt)

    local screen = scopeAtt.Pos:ToScreen()
    if scope.CenterOverlay ~= false or (screen and screen.visible) then
        DrawScopeOverlay(self, wep, screen)
    end
end
