ATTACHMENT.Name = "att_base"
ATTACHMENT.Category = nil 
ATTACHMENT.Selectable = true  --暂时填true用来调试

ATTACHMENT.Description = nil 

-- 渲染相关字段
ATTACHMENT.Model = nil      -- 模型路径
ATTACHMENT.Visible = true   -- 第三人称配件模型是否显示
ATTACHMENT.Bonemerge = nil  -- true(默认) = EF_BONEMERGE跟随动画, false = FollowBone+偏移
ATTACHMENT.Bone = nil       -- 要绑定的骨骼名（默认用槽位的 Bone）

ATTACHMENT.Pos = Vector(0,0,0)
ATTACHMENT.Angles = Angle(0,0,0)

function ATTACHMENT:ChangeWeaponStats(weapon)
    
end

function ATTACHMENT:Render( weapon ,model )
    model:DrawModel()
end

function ATTACHMENT:PostProcess(weapon)
    
end

function ATTACHMENT:ScaleTableValue(tableData, mul)
    if not tableData then return end
    for key, val in pairs(tableData) do
        if istable(val) then
            self:ScaleTableValue(val, mul)
        else
            tableData[key] = val * mul  -- ✅ 直接修改原表的值
        end
    end
end



function ATTACHMENT:Remove(weapon,model)
    model:Remove()
end
--
