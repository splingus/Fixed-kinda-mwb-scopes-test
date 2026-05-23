-- =============================================
-- TRMBase NPC/武器替换系统
-- 自动匹配弹药类型，支持随机选择
-- 开关:
--   trmbase_replace_npc (0/1)
--   trmbase_replace_weapon (0/1) - 替换生成的世界武器
-- =============================================

CreateConVar("trmbase_replace_npc", "0", FCVAR_ARCHIVE)
CreateConVar("trmbase_replace_weapon", "0", FCVAR_ARCHIVE)
CreateConVar("trmbase_replace_chance", "100", FCVAR_ARCHIVE)
CreateConVar("trmbase_random_attachments", "0", FCVAR_ARCHIVE)

local refresh = FrameTime() * 5

if CLIENT and not SERVER then return end

local SpecialAmmoMap = {
    ["XBowBolt"] = "SniperPenetratedRound",
}

-- 查找所有使用指定弹药类型的 TRM 武器（返回列表，支持随机）
local function FindAllTRMByAmmo(ammoType)
    if not ammoType then return {} end
    if SpecialAmmoMap[ammoType] then
        ammoType = SpecialAmmoMap[ammoType]
    end
    local lower = string.lower(ammoType)
    local results = {}
    for _, wep in pairs(weapons.GetList()) do
        if type(wep) ~= "table" then continue end
        if wep.Base ~= "trm_gun_base" then continue end
        local wa = wep.Primary and wep.Primary.Ammo
        if wa and string.lower(wa) == lower then
            table.insert(results, wep.ClassName)
        end
    end
    return results
end

local function PickRandom(list)
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

-- 检查替换概率（0-100）
local function RollChance()
    local cv = GetConVar("trmbase_replace_chance")
    local chance = cv and cv:GetInt() or 100
    return math.random(0, 99) < chance
end
local function RandomizeAttachments(ent)
    if not IsValid(ent) then return end
    if not ent.Attachments or #ent.Attachments == 0 then return end
    if not ent.EquipAttachment then return end

    local cv = GetConVar("trmbase_random_attachments")
    if not cv or not cv:GetBool() then return end

    for i, slot in ipairs(ent.Attachments) do
        if not slot.Category then continue end

        -- 找到该槽位可用的配件
        local available = {}
        for attClass, attData in pairs(BASE_TRM_ATTS) do
            if type(attData) ~= "table" then continue end
            if not attData.Category then continue end
            for _, cat in ipairs(istable(slot.Category) and slot.Category or { slot.Category }) do
                if attData.Category == cat and (attData.Selectable or true) then
                    table.insert(available, attClass)
                    break
                end
            end
        end

        if #available == 0 then continue end

        -- 每个槽 60% 概率装一个随机配件（不装默认）
        if math.random() < 0.5 then
            local chosen = available[math.random(#available)]
            if chosen ~= slot.Default then
                ent:EquipAttachment(tostring(i), chosen)
                --print("[TRMBase] Random attach slot " .. i .. ": " .. chosen)
            end
        end
    end
end

-- ===== NPC 武器替换 =====
local function DoNPCReplace(npc)
    if not IsValid(npc) or not npc:IsNPC() then return end
    local cv = GetConVar("trmbase_replace_npc")
    if not cv or not cv:GetBool() then return end
    if not RollChance() then return end

    local wep = npc:GetActiveWeapon()
    if not IsValid(wep) or wep.Base == "trm_gun_base" then return end
    -- 读弹药类型
    local ammoType = game.GetAmmoName(wep:GetPrimaryAmmoType())
    if not ammoType or ammoType == "" then
        local ammoMap = {
            npc_combine_s = "ar2",
            npc_combine = "ar2",
            npc_metropolice = "pistol",
            npc_rebel = "pistol",
            npc_citizen = "pistol",
        }
        ammoType = ammoMap[npc:GetClass()]
        if not ammoType then
            return
        end
    end

    local candidates = FindAllTRMByAmmo(ammoType)
    if #candidates == 0 then return end
    local newClass = PickRandom(candidates)

    print("[TRMBase] NPC " ..
    npc:GetClass() .. ": " .. wep:GetClass() .. " → " .. newClass .. " (random from " .. #candidates .. ")")
    if IsValid(wep) then wep:Remove() end
    npc:Give(newClass)
    timer.Simple(refresh, function()
        local wep = npc:GetActiveWeapon()
        if not IsValid(wep) then return end
        RandomizeAttachments(npc:GetActiveWeapon())
    end)
end

-- 随机装上配件

-- 是否由玩家生成的实体？通过 Source 和 SpawnFlags 判断
-- 世界/脚本生成的武器没有玩家创建者
local function IsPlayerSpawned(ent)
    -- SpawnFlags & 64 = SF_FORCE_PLAYER_DROPPED, 或检查创建者
    local owner = ent:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then return true end
    -- 如果已经 player-dropped，说明曾经被玩家持有过
    if ent.PlayerDropped then return true end
    return false
end

-- ===== 世界武器替换 =====
local function DoWeaponReplace(ent)
    if not IsValid(ent) then return end
    if not ent:IsWeapon() then return end
    if ent.Base == "trm_gun_base" then return end
    if IsValid(ent:GetOwner()) then return end
    if not RollChance() then return end

    local ammoType = game.GetAmmoName(ent:GetPrimaryAmmoType())
    if not ammoType or ammoType == "" then return end

    local candidates = FindAllTRMByAmmo(ammoType)
    if #candidates == 0 then return end
    local newClass = PickRandom(candidates)

    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local velocity = ent:GetVelocity()
    local isPlayerGen = IsPlayerSpawned(ent)

    print("[TRMBase] World weapon: " ..
    ent:GetClass() .. " → " .. newClass .. (isPlayerGen and " (player)" or " (world)"))

    ent:Remove()
    local newEnt = ents.Create(newClass)
    if IsValid(newEnt) then
        newEnt:SetPos(pos)
        newEnt:SetAngles(ang)
        newEnt:SetVelocity(velocity)
        newEnt:Spawn()

        -- 不是玩家生成的武器 → 随机装点配件
        if not isPlayerGen then
            timer.Simple(refresh, function()
                RandomizeAttachments(newEnt)
            end)
        end
    end
end

-- ===== 钩子 =====
hook.Add("OnEntityCreated", "TRMBase_Replace", function(ent)
    if not IsValid(ent) then return end
    -- 读档时跳过替换（save/restore 期间武器由存档系统管理）

    timer.Simple(refresh, function()
        if ent:IsNPC() then
            DoNPCReplace(ent)
        elseif ent:IsWeapon() then
            local cv = GetConVar("trmbase_replace_weapon")
            if cv and cv:GetBool() then
                DoWeaponReplace(ent)
            end
        end
    end)
end)

hook.Add("PlayerDroppedWeapon", "TRMBASE_ReplaceDrop", function(owner, ent)
    timer.Simple(refresh, function()
        local cv = GetConVar("trmbase_replace_weapon")
        if cv and cv:GetBool() then
            DoWeaponReplace(ent)
        end
    end)
end)
