module("trm_weapon_base_util",package.seeall)
function util.IsTRMBase(weapon)
    return IsValid(weapon) and (weapon.Base == "trm_gun_base" or weapon:GetClass() == "trm_gun_base")
end

function trm_weapon_base_util.IsDucking(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local height = ply:EyePos().z - ply:GetPos().z
    return height <= 32 or ply:KeyDown(IN_DUCK)
end

CreateConVar("trmbase_load_attachment_on_pickup",1,{FCVAR_ARCHIVE})
if (CLIENT) then
    -- local FullUpdate = {}
    -- --PrintTable(FullUpdate)
    -- function trm_weapon_base_util.DealFullUpdate(ent)
    --     FullUpdate[ent] = true 
    -- end 
    -- hook.Add("PreRender","TrmBase_Model_ReParent",function()
    --     if FullUpdate then
    --         for ent , _ in pairs(FullUpdate) do
    --             if not IsValid(ent) then
    --                 FullUpdate[ent] = nil 
    --                 continue 
    --             end
                
    --             local fullUpdateParent = ent:GetInternalVariable("m_hNetworkMoveParent")
                
    --             if (!IsValid(ent:GetParent()) && IsValid(fullUpdateParent)) then
    --                 ent:SetParent(fullUpdateParent)
    --             end 
    --         end
    --     end
    -- end)
end