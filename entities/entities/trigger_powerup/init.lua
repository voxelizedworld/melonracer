ENT.Base = "base_brush"
ENT.Type = "brush"

-- ENT:Initialize - Set default values for the keyvalues & other stuff --
function ENT:Initialize()
	-- Keyvalues
	self.Delay = self.Delay or 60
	self.Max = self.Max or 1
	
	-- Setups
	self.Timer = 0
	self.NumPowerups = 0
end

-- ENT:KeyValue - A custom keyvalue is added --
function ENT:KeyValue(Key, Value)
	Key = string.lower(Key)
	
	-- Set our keyvalues
	if (Key == "powerups") and (Value != "") then
		self.Powerups = string.Explode(";", Value)
	elseif (Key == "delay") and (tonumber(Value)) then
		self.Delay = tonumber(Value)
	elseif (Key == "max") and (tonumber(Value)) then
		self.Max = tonumber(Value)
	end
end

-- ENT:Think - Make it spawn the powerups --
function ENT:Think()
	-- Make sure it's enabled
	if not (GAMEMODE.EnablePowerups) then 
		-- Oh noes, it's not enabled, remove this useless entity
		self.Entity:Remove()
		return
	end
	
	local RealTime = RealTime()
	if (self.NumPowerups < self.Max) then
		if (self.Timer < RealTime) then
			-- Get our random position
			local Pos = self:GetRandomPosition()
			
			-- Debug
			dprint(tostring(self)..":GetRandomPosition() -> "..tostring(Pos))
			
			if (Pos) then
				local Type
				if (self.Powerups) then
					Type = self.Powerups[math.random(1, #self.Powerups)]
				else
					Type = GAMEMODE.Powerups.Names[math.random(1, #GAMEMODE.Powerups.Names)]
				end
				
				-- Spawn our powerup at the pos
				local Powerup = ents.Create("sent_powerup")
				Powerup:SetPos(Pos)
				Powerup:SetType(Type)
				Powerup:Spawn()
				Powerup.BaseEntity = self.Entity
				
				-- Add it to the number of powerups
				self.NumPowerups = self.NumPowerups + 1
				
				-- Add it to the global table
				table.insert(GAMEMODE.Powerups.Entities, Powerup)
				
				-- Debug
				dprint("\t".."Spawned powerup "..tostring(Powerup).." type '"..Type.."'")
			end
			
			-- Reset the timer
			self.Timer = RealTime + self.Delay
		end
	else
		-- We do nothing... Keep on resetting the timer untill somebody pick up a powerup
		self.Timer = RealTime + self.Delay
	end

end

-- ENT:GetRandomPosition - Get a valid spawning position  --
function ENT:GetRandomPosition()
	local RandomPos
	local Min, Max = self.Entity:WorldSpaceAABB()
	local NoPos = true
	local Fraction = (Max.z - Min.z) / 1000
	
	-- Loop untill we get a valid position out of 1000
	for i=1, 1000 do
		-- Get a random pos
		RandomPos = Vector(math.Rand(Min.x, Max.x), math.Rand(Min.y, Max.y), Max.z - Fraction * i)
		
		-- Make sure it's valid
		if (util.IsInWorld(RandomPos)) then
			NoPos = false
			break
		end
	end
	
	if (NoPos) then
		-- We found no valid position
		error(tostring(self.Entity)..": Could not find valid spawnpoint for powerup!\n- Removing entity...", 0)
		
		-- Remove this entity
		self.Entity:Remove()
	else
		-- Valid position, trace down to the ground
		local Trace = {}
		Trace.start = RandomPos
		Trace.endpos = RandomPos - Vector(0, 0, Max.z - Min.z)
		Trace.filter = self.Entity
		Trace.mask = MASK_WATERWORLD
		Trace = util.TraceLine(Trace)
		
		return Trace.HitPos
	end
end
