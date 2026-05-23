
function SWEP:ShootEffects(slience)
    
	if SERVER  then return end
	local ejectDelay = self.m_EjectDelay or 0

	local vm = self:GetOwner():ShouldDrawLocalPlayer()
    if not vm then 
 	        self:DoMuzzleEffect()     
           
        
        if self.Effects.Shell.Primary  then
            self:DoShell() 
        end
    end 


end

function SWEP:DoMuzzleEffect()

    if SERVER or self.Primary.Slienced then return end
   
    local effect = EffectData()
    local data = self:GetAttachmentData(self.Effects.Muzzle.attachment)
    local att = data.Ent:GetAttachment(data.id)
    --PrintTable(att )
    local vm = self:GetViewModel()

    effect:SetColor(255,255,255,255) 
    effect:SetOrigin(   att.Pos )
    effect:SetAngles(   att.Ang )
    effect:SetEntity(   data.Ent )   
    effect:SetAttachment(   data.id  )
    effect:SetScale( 5 )
    effect:SetFlags(2 )
 
   --print(effect:GetEntity())

    util.Effect(self.Effects.Muzzle.effect,effect)
    
	-- local dlight = DynamicLight(    self:GetOwner():EntIndex() , true )

	-- dlight.Pos = att.Pos
	-- dlight.r = 255
	-- dlight.g = 0
	-- dlight.b = 0
	-- dlight.brightness = 1500
	-- dlight.decay = 1000
	-- dlight.Size = 1024
	-- dlight.Style = 1
   
end


function SWEP:DoShell()
    if not (CLIENT ) then
        self:CallOnClient("DoShell")     
    return end
    local vm = self:GetViewModel()
    if not IsValid(vm) then return end
    local effect = EffectData()
    local att_shell = self:GetAttachmentData(self.Effects.Shell.attachment)
    local _model = att_shell.Ent:GetAttachment(att_shell.id)

    effect:SetOrigin(_model.Pos + self.Effects.Shell.Pos)
    effect:SetAngles(_model.Ang + self.Effects.Shell.Ang)
    effect:SetScale(self.Effects.Shell.Scale or 1)
    effect:SetEntity(att_shell.Ent)
    effect:SetAttachment(att_shell.id)
    effect:SetFlags(0)
    effect:SetMagnitude(1)
    util.Effect(self.Effects.Shell.effect,effect)
end



