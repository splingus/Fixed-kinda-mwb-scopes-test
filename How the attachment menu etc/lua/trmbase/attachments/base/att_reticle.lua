-- att_sight.lua（瞄具配件通用基类）
ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_sight"
ATTACHMENT.Description = "The Base for Sight Attachments"

-- 默认配置，子类可以覆盖
ATTACHMENT.Sight = {}
ATTACHMENT.Scope = {}

function ATTACHMENT:Render(weapon, model)
    BASE_TRM_ATTS[self.Base]:Render(weapon,model)
    -- 先渲染模型本身
    --model:DrawModel()
    
    -- 如果有分划板配置，渲染红点/分划板
    if self.Sight and self.Sight.Material then
        self:RenderReticle(weapon, model)
    end
    
    
end

-- 渲染红点/分划板（使用 Stencil 遮罩）
function ATTACHMENT:RenderReticle(weapon, model)
    local ret = self.Sight
    if not ret or not ret.Material then return end
    
    -- 获取红点显示位置（附件点）
    local attID = model:LookupAttachment(ret.Align or "reticle")
    if attID <= 0 then return end
    
    local att = model:GetAttachment(attID)
    if not att then return end
    
    -- 开始 Stencil 遮罩
    render.ClearStencil()
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(0)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilEnable(true)
    render.SetStencilReferenceValue(TRM_BASE_REF + 1)
    
    -- 写入遮罩区域
    model:DrawModel()
    render.SetStencilCompareFunction(STENCIL_LESSEQUAL)
    
    -- 渲染红点
    local size = ret.Size or 5.12
    local color = ret.Color or Color(255, 0, 0, 255)
    render.SetMaterial(ret.Material)
    
    local offset = att.Ang:Forward() * 100
    if ret.Offset then
        offset = offset + att.Ang:Right() * ret.Offset.x
        offset = offset + att.Ang:Up() * ret.Offset.y
    end
    local roll = -att.Ang.r + 180
    if ret.Rotate then
        roll = roll + ret.Rotate
    end
    render.DrawQuadEasy(att.Pos + offset, att.Ang:Forward():GetNegated(), size, size, color, roll)
    render.ClearStencil()
    render.SetStencilEnable(false)
end
