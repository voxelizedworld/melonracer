/*---------- FUNCTION TABLE ------------
	-- Stuff in brackets [ ] are optional --
	Ply:SpawnMelon([Position])
	Ply:HasMelon()
	Ply:SetMelon(Entity)
	Ply:BreakMelon()
	Ply:RespawnMelon([Delay])
	Ply:IsRespawning()
	Ply:SetCheckpoint(Number)
	Ply:CheckCheckpoint(NewNumber)
	Ply:UpdateLapTimes()
------------------------------------------------*/


local Meta = FindMetaTable("Player")

/*******************************************
********************************************/
function Meta:SpawnMelon(Pos)
	-- Make sure we have a valid/connected player
	if not (IsValid(self)) then return end
	
	--self:Freeze(false) 
	
	-- Break the old melon if we had one
	self:BreakMelon()
	
	-- Create our new one
	local Melon = ents.Create("sent_melon_normal")
	Melon:SetPos(Pos or self.CheckpointPos or self:GetPos())
	Melon:SetOwner(self)
	Melon:Spawn()
	Melon:Activate()
	Melon:SetColor(Color(255, 255, 255, 0))
	
	-- If it's a checkpoint, set the eyeangles too
	self:SetEyeAngles(self.CheckpointAng or Angle(0, 0, 0))
	
	-- Make the player follow the melon
	--self:Spectate(OBS_MODE_CHASE)
	self:SpectateEntity(Melon)
	
	-- Disable the crosshair, it's in the way
	self:CrosshairDisable()
		
	-- Debug
	dprint(tostring(self)..":SpawnMelon() == "..tostring(Melon))
	
	-- Make it our melon
	self:SetMelon(Melon)
	
	if (not GAMEMODE.SpawnAtCheckpoint) then
		-- Reset the lap time
		self.LapStart = CurTime()
		
		umsg.Start("Melonracer SetLapStart", self)
			umsg.Float(self.LapStart)
		umsg.End()
		
		-- Reset the checkpoint
		self.Checkpoint = 0
	end
	
	-- Reset the wrong way vars
	self.CheckpointWrongWay = false
	self.CheckpointWrongWayNum = 0
	
	self:SetColor(Color(255, 255, 255, 0))
	self:SetMoveType( MOVETYPE_OBSERVER )
	self:Spectate(OBS_MODE_CHASE);
	return Melon
end

/*******************************************
********************************************/
function Meta:HasMelon()
	return IsValid(self.Melon)
end

/*******************************************
********************************************/
function Meta:SetMelon(Ent)
	-- Set our new melon
	self.Melon = Ent
	self:SetNetworkedEntity("Melon", Ent)
	
	-- Debug
	dprint(tostring(self)..":SetMelon("..tostring(Ent)..")")
end

/*******************************************
********************************************/
function Meta:BreakMelon()
	-- Make sure we have a melon
	if (self:HasMelon()) then
		-- Break the melon
		self.Melon:Break()
		self.Melon = nil
		--self:Freeze(true) 
		
		-- Debug
		dprint(tostring(self)..":BreakMelon()")
	end
end

/*******************************************
********************************************/
function Meta:RespawnMelon(Delay)
	if (not self.Respawning) then
		Delay = Delay or GAMEMODE.RespawnDelay
		
		-- Break the melon if it exists already
		self:BreakMelon()
		
		-- Wait 'Delay' number of seconds untill we spawn it
		timer.Simple(Delay, function()
			self:SpawnMelon()
			self.Respawning = false
		end)
		
		-- Tell the client too
		umsg.Start("Melonracer RespawnMelon", self)
			umsg.Float(Delay)
		umsg.End()
		
		umsg.Start("Melonracer RightWay", self)
			umsg.Char(0)
		umsg.End()
		
		self.Respawning = true
		self.CheckpointWrongWay = false
		
		dprint(tostring(self)..":RespawnMelon("..Delay..")")
	end
end

/*******************************************
********************************************/
function Meta:IsRespawning()
	return self.Respawning
end

/*******************************************
********************************************/
function Meta:SetCheckpoint(Num)
	-- Set our current checkpoint
	self.Checkpoint = Num or 0
	
	-- Trace down and set the position at ground level
	local Melon = self.Melon or self -- If the melon shouldn't exist for ??? reason, use the player
	local Pos = Melon:GetPos()
	local Trace = util.QuickTrace(Pos, Pos - Vector(0, 0, 4096), {Melon, self})
	
	if (GAMEMODE.SpawnAtCheckpoint) or (Num == 1) then
		-- Set our checkpoint position
		if (Trace.Hit) then
			self.CheckpointPos = Trace.HitPos + Vector(0, 0, 9.5)
		else
			self.CheckpointPos = Pos
		end
		
		-- Save our angles
		self.CheckpointAng = self:EyeAngles()
	end
	
	dprint(tostring(self)..":SetCheckpoint("..Num..")")
end

/*******************************************
********************************************/
function Meta:CheckCheckpoint(NewNum)
	local OK = false
	
	-- Debug
	dprint(tostring(self)..":CheckCheckpoint("..NewNum..")")
	
	if (NewNum == 1) and (self.Checkpoint == GAMEMODE.NumCheckpoints) then
		-- Lap
		OK = true
		
		-- Add 1 onto our current lap
		self.Laps = self.Laps + 1
		
		-- Add 1 point
		self:AddFrags(1)
		
		-- Update the lap times
		self:UpdateLapTimes()
		
		-- Check if it was the last lap
		if (self.Laps >= GAMEMODE.NumLaps) then
			-- We've reached the maximum laps, tell everybody who won
			for k,v in pairs(player.GetAll()) do
				v:ChatPrint(self:Name() .. " won this round! A new one is starting in 5 seconds...")
			end
			
			-- Start a new match
			GAMEMODE.GameStarted = false
			GAMEMODE:NewMatch(5)
		else
			umsg.Start("Melonracer RightWay", self)
				umsg.Char(2)
				umsg.Short(self.Laps)
			umsg.End()
		end
		
		dprint("	Lap " .. self.Laps .. "!")
	elseif (self.Checkpoint == 0) and (NewNum == 1) then
		-- Spawn checkpoint
		OK = true
		
		dprint("	Spawn checkpoint! - " .. NewNum)
	elseif (self.Checkpoint + 1 == NewNum) and (not self.CheckpointWrongWay) then
		-- Checkpoint
		OK = true
		
		dprint("	Checkpoint! - " .. NewNum)
		
		umsg.Start("Melonracer RightWay", self)
			umsg.Char(1)
			umsg.Short(self.Checkpoint)
		umsg.End()
	elseif (self.Checkpoint == NewNum) then
		-- Right way!
		self.CheckpointWrongWay = false
		
		-- Same checkpoint
		umsg.Start("Melonracer RightWay", self)
			umsg.Char(0)
		umsg.End()
		
		dprint("	Same checkpoint... " .. NewNum)
	elseif (self.CheckpointWrongWayNum == NewNum) then
		-- Set new wrong checkpoint
		self.CheckpointWrongWayNum = NewNum + 1
		
		-- We don't want to set it to a checkpoint that doesn't exist...
		if (self.CheckpointWrongWayNum > GAMEMODE.NumCheckpoints) then
			self.CheckpointWrongWayNum = 1
		end
		
		-- He was going wrong way, not anymore
		umsg.Start("Melonracer RightWay", self)
			umsg.Char(0)
		umsg.End()
		
		dprint("	Right way... " .. NewNum)
	else
		-- Wrong way
		umsg.Start("Melonracer RightWay", self)
			umsg.Char(3)
		umsg.End()
		
		-- He's going the wrong way...
		self.CheckpointWrongWay = true
		self.CheckpointWrongWayNum = NewNum
		
		dprint("	Wrong way!")
	end
	
	return OK	
end

/*******************************************
********************************************/
function Meta:UpdateLapTimes()
	-- Update last lap
	self.LastLap = self.LapTime
	umsg.Start("Melonracer SetLastLap", self)
		umsg.Float(self.LastLap)
	umsg.End()
	
	-- Check personal best
	if (self.BestLap == 0) or (self.BestLap > self.LapTime) then
		self.BestLap = self.LapTime
		
		umsg.Start("Melonracer SetBestLap", self)
			umsg.Float(self.BestLap)
		umsg.End()
	end
	
	-- Check server best
	if ((GAMEMODE.Stats.BestLap > self.LapTime) or (GAMEMODE.Stats.BestLap == 0)) and (self.LapTime != 0) then
		-- Set the new best lap
		GAMEMODE.Stats.BestLap = self.LapTime
		GAMEMODE.Stats.BestLapName = self:Name()
		
		-- Get all players
		local Filter = RecipientFilter()
		Filter:AddAllPlayers()
		
		-- Update it for the clients
		umsg.Start("Melonracer SetServerBestLap", Filter)
			umsg.Float(GAMEMODE.Stats.BestLap)
			umsg.String(GAMEMODE.Stats.BestLapName)
		umsg.End()
	end
	
	-- Update the leaderlist
	GAMEMODE:UpdateTopThree()
	
	-- Set the lap start
	self.LapStart = CurTime()
	umsg.Start("Melonracer SetLapStart", self)
		umsg.Float(self.LapStart)
	umsg.End()
end
