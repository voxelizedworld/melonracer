AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- ENT:Initialize - Initialize stuff --
function ENT:Initialize()
	-- How many degrees/second is should rotate
	self.RotateSpeed = 45
	
	-- Set our model and physics
	self.Entity:SetModel("models/combine_helicopter/helicopter_bomb01.mdl")
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetNotSolid(true)
	
	-- Make it call triggers
	self.Entity:SetTrigger(true)
	
	-- Wake our physics
	local Phys = self.Entity:GetPhysicsObject()
	if (Phys:IsValid()) then
		Phys:EnableGravity(false)
		Phys:Wake()
	end
	
	-- Motioncontroller for the spinning part
	self.Entity:StartMotionController()
	
	-- Our initial position
	self.Pos = self.Entity:GetPos() + Vector(0, 0, 16)
	
	-- Leave
	self.Time = CurTime()
end

-- ENT:PassesTriggerFilters - Allow only melons to run triggers --
function ENT:PassesTriggerFilters(Ent)
	return string.find(Ent:GetClass(), "sent_melon")
end

-- ENT:StartTouch - Called when a melon touched this entity --
function ENT:StartTouch(Ent)
	-- Only melons are allowed
	if not (string.find(Ent:GetClass(), "sent_melon")) then return end
	
	-- Do the powerup stuff
	self:DoPowers(Ent)
	
	-- Remove one powerup from the base entity
	self.Entity.BaseEntity.NumPowerups = self.Entity.BaseEntity.NumPowerups - 1
	
	-- Remove it from the global table
	for k,v in pairs(GAMEMODE.Powerups.Entities) do
		if (v == self.Entity) then
			table.remove(GAMEMODE.Powerups.Entities, k)
			break
		end
	end
	
	-- Remove the powerup 
	self.Entity:Remove()
	
	-- Debug
	dprint(tostring(self)..":StartTouch("..tostring(Ent)..")")
end

-- ENT:PhysicsSimulate - This is where the entity rotate --
function ENT:PhysicsSimulate(PhysObj, DeltaTime)
	local Motion = {}
	local Angles = self.Entity:GetAngles()
	Angles.y = math.NormalizeAngle(Angles.y + self.RotateSpeed)
	
	-- Leave this shit
	Motion.secondstoarrive	= 1
	Motion.pos				= self.Pos + Vector(0, 0, math.cos((CurTime() - self.Time) * 2) * 4)
	Motion.maxangular		= 3600
	Motion.maxangulardamp	= 10000
	Motion.maxspeed			= 100000
	Motion.maxspeeddamp		= 1000
	Motion.dampfactor		= 1
	Motion.teleportdistance	= 100
	Motion.angle			= Angles
	Motion.deltatime		= DeltaTime
	
	-- Move it
	PhysObj:ComputeShadowControl(Motion)
	
	-- Keep the physobj awake
	PhysObj:Wake()
end

-- ENT:SetType - Sets which type of powerup this is --
function ENT:SetType(Type)
	self.PowerupType = Type
	
	self.Entity:SetNetworkedString("PowerupType", Type)
end

-- ENT:DoPowers - This is the function that do the actual powerup code, there is also code in sent_melon_base --
function ENT:DoPowers(Ent)
	-- Bomb --
	if (self.PowerupType == "Bomb") then
		Ent:GetOwner():PrintMessage(4, "Use left mouse button to spawn bombs")
		Ent.BombAmmo = GAMEMODE.Powerups.Bomb.Ammo
		
	-- Haste --
	elseif (self.PowerupType == "Haste") then
		Ent.HasteTimer = CurTime() + GAMEMODE.Powerups.Haste.Duration
		
	-- God --
	elseif (self.PowerupType == "God") then
		Ent.GodTimer = CurTime() + GAMEMODE.Powerups.God.Duration
		
	-- Less Time --
	elseif (self.PowerupType == "LessTime") then
		local Ply = Ent:GetOwner()
		local NewTime = math.min(Ply.LapStart + math.Rand(GAMEMODE.Powerups.LessTime.TimeMin, GAMEMODE.Powerups.LessTime.TimeMax), CurTime())
		Ply.LapStart = NewTime
		
		-- Client too
		umsg.Start("Melonracer SetLapStart", Ply)
			umsg.Float(NewTime)
		umsg.End()
		
	-- Drug --
	elseif (self.PowerupType == "Drug") then
		Ent.DrugTimer = CurTime() + GAMEMODE.Powerups.Drug.Duration
	
	-- Timed Bomb --
	elseif (self.PowerupType == "TimedBomb") then
		util.PrecacheSound("weapons/c4/c4_beep1.wav")
		Ent.BombTimer = CurTime() + GAMEMODE.Powerups.TimedBomb.Duration
		
	-- Slow --
	elseif (self.PowerupType == "Slow") then
		Ent.SlowTimer = CurTime() + GAMEMODE.Powerups.Slow.Duration
		
	-- Weakness --
	elseif (self.PowerupType == "Weak") then
		Ent.WeakTimer = CurTime() + GAMEMODE.Powerups.Weak.Duration
		
	-- More Time --
	elseif (self.PowerupType == "MoreTime") then
		local Ply = Ent:GetOwner()
		local NewTime = math.min(Ply.LapStart - math.Rand(GAMEMODE.Powerups.MoreTime.TimeMin, GAMEMODE.Powerups.MoreTime.TimeMax), CurTime())
		Ply.LapStart = NewTime
		
		-- Client too
		umsg.Start("Melonracer SetLapStart", Ply)
			umsg.Float(NewTime)
		umsg.End()
	end
end
