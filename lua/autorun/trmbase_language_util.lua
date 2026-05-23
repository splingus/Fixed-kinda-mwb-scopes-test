-- trmbase_language_util.lua
if SERVER then
    AddCSLuaFile()
end
if not CLIENT then return end

TRMBase = TRMBase or {}
TRMBase.Language = TRMBase.Language or {}

-- 中文
TRMBase.Language.cn = {
    ["SniperPenetratedRound_ammo"]  ="狙击弹药" ,
    ["Optic"] = "瞄具",
    ["Muzzle"] = "枪口",
    ["Laser"] = "战术配件",
    ["Mag"] = "弹匣" ,
    ["Barrel"] = "枪管" ,
    ["Stock"] = "枪托" ,
    ["Grip"] = "后握把" ,
    ["UnderBarrel"] = "下挂" ,
    ["Misc"] = "杂项" ,

    -- VGUI
    ["TRMBase_Default"] = "默认配件",
    ["TRMBase_None"] = "无",
    ["TRMBase_Customize"] = " - 自定义",
    ["TRMBase_NoSlots"] = "此武器没有配件槽位",
    ["TRMBase_CloseHint"] = "按 Menu_Context 关闭",
    ["TRMBase_SlotExcluded"] = "此槽位被已装备的配件排除",
    ["TRMBase_Excluded"] = "已排除",

    -- 属性面板
    ["TRMBase_Stat_Damage"] = "伤害",
    ["TRMBase_Stat_ClipSize"] = "弹匣容量",
    ["TRMBase_Stat_RPM"] = "射速",
    ["TRMBase_Stat_Spread"] = "散布",
    ["TRMBase_Stat_AimSpeed"] = "开镜时间",
    ["TRMBase_Stat_Recoil"] = "后坐力",

    -- 菜单选项
    ["TRMBase_InfiniteAmmo"] = "无限备弹",
    ["TRMBase_AutoReload"] = "自动换弹",
    ["TRMBase_FireInteruptReload"] = "开火打断换弹",
    ["TRMBase_SprintReload"] = "冲刺换弹",
    ["TRMBase_LoadAttOnPickup"] = "拾取时加载配件（还没做好",
    ["TRMBase_ReplaceNPC"] = "替换 NPC 武器",
    ["TRMBase_ReplaceWeapon"] = "替换生成武器",
    ["TRMBase_ReplaceChance"] = "替换概率",
    ["TRMBase_RandomAttach"] = "随机配件",
    ["TRMBase_MeleeKey"] = "近战",
    ["TRMBase_InspectKey"] = "检视",
    ["TRMBase_CustomizeKey"] = "自定义",
    ["TRMBase_Crosshair"] = "准星",
    ["TRMBase_CrosshairColor"] = "准星颜色",
    ["TRMBase_CrosshairStyle"] = "准星样式",
    ["TRMBase_CrosshairDot"] = "准星中心点",
    ["TRMBase_HideHUDInspect"] = "检视时隐藏 HUD",
}

-- 英文
TRMBase.Language.en = {
    ["Optic"] = "Sight",
    ["Muzzle"] = "Muzzle",
    ["Laser"] = "Tactical",

    -- VGUI
    ["TRMBase_Default"] = "Default",

    ["TRMBase_None"] = "None",
    ["TRMBase_Customize"] = " - Customize",
    ["TRMBase_NoSlots"] = "This weapon has no attachment slots",
    ["TRMBase_CloseHint"] = "Press Menu_Context to close",
    ["TRMBase_SlotExcluded"] = "This slot is excluded by equipped attachments",
    ["TRMBase_Excluded"] = "Excluded",

    -- 属性面板
    ["TRMBase_Stat_Damage"] = "Damage",
    ["TRMBase_Stat_ClipSize"] = "Clip Size",
    ["TRMBase_Stat_RPM"] = "RPM",
    ["TRMBase_Stat_Spread"] = "Spread",
    ["TRMBase_Stat_AimSpeed"] = "Aim Time",
    ["TRMBase_Stat_Recoil"] = "Recoil",

    -- 菜单选项
    ["TRMBase_InfiniteAmmo"] = "Infinite Reserve Ammo",
    ["TRMBase_AutoReload"] = "Auto Reload",
    ["TRMBase_FireInteruptReload"] = "Fire Interrupt Reload",
    ["TRMBase_SprintReload"] = "Sprint Reload",
    ["TRMBase_LoadAttOnPickup"] = "Load Attachments on Pickup(WIP)",
    ["TRMBase_ReplaceNPC"] = "Replace NPC Weapon",
    ["TRMBase_ReplaceWeapon"] = "Replace Spawned Weapon",
    ["TRMBase_ReplaceChance"] = "Replace Chance",
    ["TRMBase_RandomAttach"] = "Random Attachments",
    ["TRMBase_MeleeKey"] = "Melee",
    ["TRMBase_InspectKey"] = "Inspect",
    ["TRMBase_CustomizeKey"] = "Customize",
    ["TRMBase_Crosshair"] = "Crosshair",
    ["TRMBase_CrosshairColor"] = "Crosshair Color",
    ["TRMBase_CrosshairStyle"] = "Crosshair Style",
    ["TRMBase_CrosshairDot"] = "Crosshair Dot",
    ["TRMBase_HideHUDInspect"] = "Hide HUD When Inspect",
}

-- 获取当前语言
function TRMBase.GetLanguage()
    local lang = GetConVar("gmod_language"):GetString()
    lang = string.lower(lang)
    if lang == "zh-cn" or lang == "zh-tw" then
        return TRMBase.Language.cn
    end
    return TRMBase.Language.en
end

for k, v in pairs(TRMBase.GetLanguage()) do
    language.Add(k, v)
end