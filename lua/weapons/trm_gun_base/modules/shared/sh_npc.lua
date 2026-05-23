
function SWEP:CanBePickedUpByNPCs()
    return true
end
function SWEP:GetNPCBulletSpread()
    return 4    
end

function SWEP:GetNPCBurstSettings()
    return 1 , 5 , (60 /self.Primary.RPM)
end

function SWEP:GetNPCRestTimes()
    return 0.3 , 0.6
end

function SWEP:NPCShoot_Primary(pos , dir)
    if CurTime() > self:GetNextPrimaryFire() then
            self:FirePrimaryBullet() 
            self:SetNextFireTime( 60 / self.Primary.RPM ) 
    end
end  

