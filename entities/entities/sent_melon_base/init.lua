AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- ENT:Initialize - Initialize stuff --
function ENT:Initialize()
	-- Set our model and physics
	self.Entity:SetModel(GAMEMODE.Model)
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	-- Wake our physics
	local Phys = self.Entity:GetPhysicsObject()
	if (Phys:IsValid()) then
		Phys:Wake()
	end
	
	-- Change the speeds depending on the tickrate (based on 33 tickrate)
	local Tickrate = FrameTime() * 33
	self.ForwardSpeed = math.Round(self.ForwardSpeed * Tickrate)
	self.ReverseSpeed = math.Round(self.ReverseSpeed * Tickrate)
	self.StrafeSpeed = math.Round(self.StrafeSpeed * Tickrate)
	
	-- Leave
	self.RegenTimer = 0
	self.BombAmmo = 0
	self.BombDroppedTimer = 0
	self.HasteTimer = 0
	self.GodTimer = 0
	self.DrugTimer = 0
	self.BombTimer = 0
	self.BombTimerLast = -1
	self.SlowTimer = 0
	self.WeakTimer = 0
	
	self.Entity:SetNetworkedInt("HP", self.HP)
	self.Entity:SetNetworkedInt("MaxHP", self.MaxHP)
end

-- ENT:PhysicsCollide - We hit stuff, do custom damage functions --
function ENT:PhysicsCollide(Data, PhysObj)
	-- Deal damage to func_breakables
	if (Data.HitEntity:GetClass() == "func_breakable") then
		Data.HitEntity:TakeDamage(math.floor(Data.Speed/100))
	end
	
	-- Play sound, depending on speed
	if ((Data.DeltaTime >= 0.8) and (Data.Speed > 100)) or (Data.Speed > 250) then
		self.Entity:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(1, 4)..".wav", 100, 100)
	end
	
	-- Get the max/min damage range
	local MinDamageRange = self.MinDamageRangeOverride or self.MinDamageRange
	local MaxDamageRange = self.MaxDamageRangeOverride or self.MaxDamageRange
	
	-- Hurt the melon
	if (Data.Speed > MinDamageRange) and (not self.GodMode) then
		self:Hurt(Data.Speed / MaxDamageRange)
	end
end

-- ENT:OnTakeDamage - Take bullet, etc damage normally --
function ENT:OnTakeDamage(DmgInfo)
	-- Apply physics
	self.Entity:TakePhysicsDamage(DmgInfo)
	
	-- Make normal explosions and such damage the melons
	self:Hurt(DmgInfo:GetDamage() / 100)
end

-- ENT:Think - Do our controls & powerups here --
function ENT:Think()
	local Owner = self.Entity:GetOwner()
	local MelonPhysObj = self.Entity:GetPhysicsObject()
	local Aim = Owner:EyeAngles()
	Aim.r = 0
	Aim.p = 0

	-- We need to update the player position at the melon or bad thing happens D:
	Owner:SetPos(self.Entity:GetPos())
	
	-- Check which key is pressed and move accordingly
	if (Owner:KeyDown(IN_FORWARD)) then
		if (self.DrugMode) then
			-- Get the right vector
			local Aim = Aim:Right()
			MelonPhysObj:ApplyForceCenter(Aim * self.StrafeSpeed)
		else
			-- Get the forward vector
			local Aim = Aim:Forward()
			MelonPhysObj:ApplyForceCenter(Aim * ((self.ForwardSpeedBoost or self.ForwardSpeed) - (self.ForwardSlowdown or 0)))
		end
	end
	
	if (Owner:KeyDown(IN_BACK)) then
		if (self.DrugMode) then
			-- Get the left vector
			local Aim = Aim:Right() * -1
			MelonPhysObj:ApplyForceCenter(Aim * self.StrafeSpeed)
		else
			-- Get the back vector
			local Aim = Aim:Forward() * -1
			MelonPhysObj:ApplyForceCenter(Aim * self.ReverseSpeed)
		end
	end
	
	if (Owner:KeyDown(IN_MOVELEFT)) then
		if (self.DrugMode) then
			-- Get the back vector
			local Aim = Aim:Forward() * -1
			MelonPhysObj:ApplyForceCenter(Aim * self.ReverseSpeed)
		else
			-- Get the left vector
			local Aim = Aim:Right() * -1
			MelonPhysObj:ApplyForceCenter(Aim * self.StrafeSpeed)
		end
	end
	
	if (Owner:KeyDown(IN_MOVERIGHT)) then
		if (self.DrugMode) then
			-- Get the forward vector
			local Aim = Aim:Forward()
			MelonPhysObj:ApplyForceCenter(Aim * ((self.ForwardSpeedBoost or self.ForwardSpeed) - (self.ForwardSlowdown or 0)))
		else
			-- Get the right vector
			local Aim = Aim:Right()
			MelonPhysObj:ApplyForceCenter(Aim * self.StrafeSpeed)
		end
	end
	
	-- Regenerate some health
	if (self.RegenTimer < CurTime()) then
		self.HP = self.HP + self.HPRegen/10
		
		-- Make sure we don't go over the max HP
		if (self.HP > self.MaxHP) then
			self.HP = self.MaxHP
		end
		
		-- Send over the new HP value to the client
		umsg.Start("sent_melon RecieveHP", self:GetOwner())
			umsg.Entity(self:GetOwner())
			umsg.Float(self.HP)
		umsg.End()
		
		-- Wait 0.1 seconds until next time
		self.RegenTimer = CurTime() + 0.1
	end
	
	-- Do the powerup stuff
	self:DoPowers(Owner)
	
	-- Call the think every frame
	self.Entity:NextThink(CurTime())
	return true
end

-- ENT:Hurt - A simple function that handles the damage --
function ENT:Hurt(Dmg)
	-- Set HP
	self.HP = self.HP - Dmg
	
	-- Set it on the client
	umsg.Start("sent_melon RecieveHP", self:GetOwner())
		umsg.Entity(self:GetOwner())
		umsg.Float(self.HP)
	umsg.End()
	
	-- We're dead - break it
	if (self.HP <= 0) then
		self:Break()
	end
end

-- ENT:Break - Break the melon and spawn chunks --
function ENT:Break()
	for i = 1, 3 do
		-- There is 3 different chunks
		local Part = "a"
		if (i == 2) then
			Part = "b"
		elseif (i == 3) then
			Part = "c"
		end
		
		-- Create it
		local Chunk = ents.Create("prop_physics")
		Chunk:SetModel("models/props_junk/watermelon01_chunk01"..Part..".mdl")
		Chunk:SetPos(self.Entity:GetPos())
		Chunk:Spawn()
		Chunk:Activate()
		
		-- Make them fly forwards
		Chunk:GetPhysicsObject():ApplyForceCenter(self.Entity:GetVelocity() * 3)
		
		-- Remove after 10 - 15 seconds
		timer.Simple(math.Rand(10, 15), function() if (IsValid(Chunk)) then Chunk:Remove() end end)
	end
	
	-- Remove the melon
	self.Entity:Remove()
end

-- ENT:DoPowers - This is the function that do the actual powerup stuff, there is also code in sent_powerup --
function ENT:DoPowers(Owner)
	-- Bomb --
	if (self.BombAmmo > 0) then
		if (Owner:KeyDown(GAMEMODE.Powerups.Bomb.DropKey)) and (self.BombDroppedTimer < UnPredictedCurTime()) then
			-- Create a bomb
			local Bomb = ents.Create("sent_bomb")
			Bomb:SetPos(self.Entity:GetPos())
			Bomb:SetAngles(self.Entity:GetAngles())
			Bomb:Spawn()
			
			-- Decrease the bomb ammo
			self.BombAmmo = self.BombAmmo - 1
			
			-- Set the drop delay
			self.BombDroppedTimer = UnPredictedCurTime() + GAMEMODE.Powerups.Bomb.DropDelay
		end
	end
	
	-- Haste --
	if (self.HasteTimer > CurTime()) then
		if (not self.ForwardSpeedBoost) then
			self.Entity:SetMaterial(GAMEMODE.Powerups.Haste.Material)
			self.ForwardSpeedBoost = self.ForwardSpeed + GAMEMODE.Powerups.Haste.Boost
		end
	elseif (self.ForwardSpeedBoost) then
		self.Entity:SetMaterial("")
		self.ForwardSpeedBoost = nil
	end
	
	-- God --
	if (self.GodTimer > CurTime()) then
		if (not self.GodMode) then
			self.Entity:SetRenderMode(1);
			self.Entity:SetColor( Color(GAMEMODE.Powerups.God.Color.r, GAMEMODE.Powerups.God.Color.g, GAMEMODE.Powerups.God.Color.b, GAMEMODE.Powerups.God.Color.a) )
			self.GodMode = true
		end
	elseif (self.GodMode) then
		self.Entity:SetColor( Color(255, 255, 255, 255) )
		self.GodMode = nil
	end
	
	-- Drug --
	if (self.DrugTimer > CurTime()) then
		if (not self.DrugMode) then
			self.Entity:SetColor( Color(255, 0, 0, 255) )
			self.DrugMode = true
		end
	elseif (self.DrugMode) then
		self.Entity:SetColor( Color(255, 255, 255, 255) )
		self.DrugMode = nil
	end
	
	-- Timed Bomb --
	if (self.BombTimer > CurTime()) then
		local BombTimer = math.ceil(CurTime() - self.BombTimer)
		
		if (self.BombTimerLast != BombTimer) then
			umsg.Start("sent_melon BombTimer", RecipientFilter():AddAllPlayers())
				umsg.Entity(Owner)
				umsg.Entity(self)
				umsg.Char(BombTimer)
			umsg.End()
			
			self.Entity:EmitSound("weapons/c4/c4_beep1.wav")
			
			self.BombTimerLast = BombTimer
		end
	elseif (self.BombTimerLast >= 0) then
		-- Explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(self.Entity:GetPos())
		util.Effect("Explosion", Effect)
		
		-- Throw around the other players
		local Phys = ents.Create("env_physexplosion")
		Phys:SetPos(self.Entity:GetPos())
		Phys:SetKeyValue("spawnflags", 1 + 16)
		Phys:SetKeyValue("magnitude", 100)
		Phys:Spawn()
		Phys:Fire("explode", "", 0)
		Phys:Fire("kill", "", 0.1)
		
		-- Break our melon
		self:Break()
	end
	
	-- Slow --
	if (self.SlowTimer > CurTime()) then
		if (not self.ForwardSlowdown) then
			self.ForwardSlowdown = GAMEMODE.Powerups.Slow.Slowdown
		end
	elseif (self.ForwardSlowdown) then
		self.ForwardSlowdown = nil
	end
	
	-- Weak --
	if (self.WeakTimer > CurTime()) then
		if (not self.WeakMode) then
			self.MinDamageRangeOverride = GAMEMODE.Powerups.Weak.MinDamageRange
			self.MaxDamageRangeOverride = GAMEMODE.Powerups.Weak.MaxDamageRange
		end
	elseif (self.WeakMode) then
		self.MinDamageRangeOverride = nil
		self.MaxDamageRangeOverride = nil
		self.WeakMode = nil
	end
	
end
