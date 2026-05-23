if not CLIENT then return end

-- 缓存 ConVar 引用（避免每帧 GetConVar 字符串查找）
local cv_debug = CreateClientConVar("trmbase_debug_hud", 0)
local cv_crosshair_enable = CreateClientConVar("trmbase_crosshair_enable", 1)
local cv_crosshair_style = CreateClientConVar("trmbase_crosshair_style", 1)
local cv_crosshair_color_r = CreateClientConVar("trmbase_crosshair_color_r", 255)
local cv_crosshair_color_g = CreateClientConVar("trmbase_crosshair_color_g", 255)
local cv_crosshair_color_b = CreateClientConVar("trmbase_crosshair_color_b", 255)
local cv_crosshair_alpha = CreateClientConVar("trmbase_crosshair_alpha", 200)
local cv_crosshair_dot = CreateClientConVar("trmbase_crosshair_dot", 1)

-- 模块级：避免每帧创建闭包
local HIDE_SEQUENCES = { "Reload", "Inspect", "Melee", "Holster", "Draw" }
local function ShouldHideCrosshair(wep, sequence)
    for _, seq in ipairs(HIDE_SEQUENCES) do
        if string.find(sequence, seq) then
            return true
        end
    end
    return false
end

-- TraceLine 模块变量（已废弃，保留为空避免旧引用出错）
local _lastTraceFrame = 0
local _lastScreenPos = { x = 0, y = 0 }

hook.Add("HUDPaint", "TRMBase_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if wep.Base ~= "trm_gun_base" and wep:GetClass() ~= "trm_gun_base" then return end

    DebugHUD(ply, wep)
    DrawCustomCrosshair(ply, wep)
    DrawDebugHUD(ply, wep)
end)

function DebugHUD(ply, wep)
    if cv_debug:GetInt() == 0 then return end
    draw.SimpleText("Current Task: " .. (wep.GetCurrentTask and wep:GetCurrentTask() or "None"), "Default", ScrW() / 2,
        ScrH() * 0.74, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local aimdelta = wep:GetAimDelta()
    draw.SimpleText("Aim Delta: " .. (aimdelta and math.Round(aimdelta, 2) or "None"), "Default", ScrW() / 2,
        ScrH() * 0.76, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local sequence = wep.m_CurrentSequence or wep:GetPlayingSequence() or "None"
    draw.SimpleText("Sequence: " .. (sequence and sequence or "None"), "Default", ScrW() / 2, ScrH() * 0.78,
        Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local text = wep:CanPrimaryAttack() and "1" or "0"
    draw.SimpleText("Can: " .. (text and text or "None"), "Default", ScrW() / 2, ScrH() * 0.68, Color(255, 255, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local text = wep:GetOwner():GetViewModel(0):GetCycle()
    text = math.Round(text, 2)
    draw.SimpleText("Cycle: " .. (text and text or "None"), "Default", ScrW() / 2, ScrH() * 0.65, Color(255, 255, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.RoundedBox(0, ScrW() / 2, ScrH() / 2 * 1.5, 500, 20, Color(0, 0, 0, 255))
    draw.RoundedBox(0, ScrW() / 2, ScrH() / 2 * 1.5, 500 * text, 20, Color(255, 255, 255, 255))
    local text = CurTime() - wep:GetNextPrimaryFire() >= 0 and "true" or "false"
    draw.SimpleText("Next: " .. (text and text or "None"), "Default", ScrW() / 2, ScrH() * 0.25, Color(255, 255, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local text = ply:GetViewModel(0):SequenceDuration()
    text = math.Round(text, 2)
    draw.SimpleText("SeqDur: " .. (text and text or "None"), "Default", ScrW() / 2, ScrH() * 0.22, Color(255, 255, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local vRecoil = wep.m_VRecoil or Angle(0, 0, 0)
    local back = wep:GetVisualRecoilBackward()
    draw.SimpleText(string.format("Visual Recoil: P=%.2f Y=%.2f", vRecoil.pitch, vRecoil.yaw), "Default", ScrW() / 2,
        ScrH() * 0.80, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.format("Visual Recoil Backward: %.2f", back), "Default", ScrW() / 2, ScrH() * 0.82,
        Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function DrawCustomCrosshair(ply, wep)
    if cv_crosshair_enable:GetInt() == 0 then return end
    local style = cv_crosshair_style:GetInt()
    local r = cv_crosshair_color_r:GetInt()
    local g = cv_crosshair_color_g:GetInt()
    local b = cv_crosshair_color_b:GetInt()
    local alpha = cv_crosshair_alpha:GetInt()

    local aimpos = ply:GetShootPos()
    local visualRecoil = wep:GetClientVisualRecoil() or wep.m_VRecoil or Angle(0, 0, 0)
    local recoil = ply:GetViewPunchAngles()

    local aimDir = ply:GetAimVector():Angle()
    aimDir.pitch = aimDir.pitch + visualRecoil.pitch * 1 + recoil.pitch * 1
    aimDir.yaw = aimDir.yaw + visualRecoil.yaw * 1 + recoil.yaw * 1
    local aimDirVec = aimDir:Forward()

    -- TraceLine 每 2 帧做一次（物理查询开销大，准星不需要每帧重新追踪）
    local frame = FrameNumber()
    if frame ~= _lastTraceFrame and (frame % 5) == 0 then 
        _lastTraceFrame = frame
        local tr = util.TraceLine({
            start = aimpos,
            endpos = aimpos + aimDirVec * 1000,
            filter = ply,
            mask = MASK_SHOT
        })
        _lastScreenPos = tr.HitPos:ToScreen()
    end
    local screenPos = _lastScreenPos or { x = ScrW() / 2, y = ScrH() / 2 }

    local x = math.Clamp(screenPos.x, 0, ScrW())
    local y = math.Clamp(screenPos.y, 0, ScrH())

    local spread = (wep:GetCurrentSpread() or 0) * 700
    local spreadH = wep:GetSpreadHorizonal() or 0.5
    local spreadV = wep:GetSpreadVertical() or 0.5
    local spreadSizeX = spread * math.tan(spreadH)
    local spreadSizeY = spread * math.tan(spreadV)
    local sequence = wep.m_CurrentSequence or wep:GetPlayingSequence()

    -- ADS 时隐藏准星（只对 DrawCrossHairIS=true 的武器显示，或开启调试时强制显示）
    if not ply:ShouldDrawLocalPlayer() and wep.DrawCrossHairIS ~= true and wep:GetAimDelta() > 0.5 and cv_debug:GetInt() == 0 then
        alpha = 0
    end

    if (wep:GetSprintDelta() > 0.5 and wep:CanSprint()) or ShouldHideCrosshair(wep, sequence) then
        alpha = 0
    end

    surface.SetDrawColor(r, g, b, alpha)

    local width = 2.5
    local length = 16
    if wep.Primary.NumBullets > 1 then
        local temp = width
        width = length
        length = temp
    end

    if style == 1 then
        local gapX = math.max(spreadSizeX, 4)
        local gapY = math.max(spreadSizeY, 4)
        if wep.Primary.Automatic or wep.Primary.NumBullets > 1 then
            surface.DrawRect(x - width / 2, y - gapY - length, width, length)
        end

        surface.DrawRect(x - width / 2, y + gapY, width, length)

        surface.DrawRect(x - gapX - length, y - width * 0.5, length, width)

        surface.DrawRect(x + gapX, y - width * 0.5, length, width)

        if cv_crosshair_dot:GetInt() == 1 then
            surface.DrawRect(x - 1, y - 1, 2, 2)
        end
    elseif style == 2 then
        surface.DrawRect(x - 2.5, y - 2.5, 5, 5)
        surface.SetDrawColor(r, g, b, alpha / 2)
        local spreadAvg = (spreadSizeX + spreadSizeY) / 2
        surface.DrawCircle(x, y, spreadAvg + 5, r, g, b, alpha)
    elseif style == 3 then
        local size = 10
        local gap = 4
        surface.DrawRect(x - 1, y - gap - size, 2, size)
        surface.DrawRect(x - 1, y + gap, 2, size)
        surface.DrawRect(x - gap - size, y - 1, size, 2)
        surface.DrawRect(x + gap, y - 1, size, 2)
        surface.DrawOutlinedRect(x - 3, y - 3, 6, 6)
    end
end

concommand.Add("trmbase_wep_updateIcon", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") and wep.UpdateSelectIcon then
        wep:UpdateSelectIcon()
    end
end)

function DrawDebugHUD(ply, wep)
end
