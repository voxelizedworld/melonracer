AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("meta_player.lua")
include("shared.lua")

function GM:PlayerInitalSpawn(ply)
	 ply:SetColor(Color(255, 255, 255, 0))
end
-- NewMatch - Starts a completely new match --
function GM:NewMatch(Wait)
	Wait = Wait or 0.1
	self.GameStarted = false
	
	-- Remove all powerups
	self:RemoveAllPowerups()
	
	for k,v in pairs(player.GetAll()) do
		-- Reslset the variables for all players
		self:ResetVars(v)
		
		-- Break their melons
		v:BreakMelon()
	end
	
	timer.Simple(Wait, function()
		for k,v in pairs(player.GetAll()) do
			-- Spawn their melons
			self:PlayerSpawn(v)
			
			-- Tell the client that we're restarting
			umsg.Start("Melonracer Countdown", self)
				-- Nothing really
			umsg.End()
			
			-- Play the sound on the client
			v:SendLua("GAMEMODE:PlayBellSound(3)")
			timer.Simple(3, function()
				v:SendLua("GAMEMODE:PlayBellSound(3, 0.15)")
			end)
		end
		
		timer.Simple(3, function() 
			for k,v in pairs(player.GetAll()) do
				-- Get the melons moving
				if (v:HasMelon()) then
					local PhysObj = v.Melon:GetPhysicsObject()
					PhysObj:EnableMotion(true)
					PhysObj:Wake()
				end
				
				-- Reset the lap times
				v:UpdateLapTimes()
			end
			
			-- We have now officially started
			self.GameStarted = true 
		end)
	end)
end

-- ResetVars - Reset the player variables for a new round --
function GM:ResetVars(Ply)
	if (IsValid(Ply)) then
		Ply.Checkpoint = 0
		Ply.CheckpointPos = nil
		Ply.CheckpointAng = nil
		Ply.CheckpointWrongWay = false
		Ply.CheckpointWrongWayNum = 0
		Ply.Laps = 0
		Ply.LapTime = 0
		Ply.LastLap = 0
		Ply.LapStart = 0
		
		Ply:SetDeaths(0)
		Ply:SetFrags(0)
		
		umsg.Start("Melonracer ResetVars", Ply) umsg.End()
	end
end

-- RemoveAllPowerups - Guess what it does :O --
function GM:RemoveAllPowerups()
	for k,v in pairs(self.Powerups.Entities) do
		if (IsValid(v)) then
			v:Remove()
		end
	end
	
	-- Clear the entities table
	self.Powerups.Entities = {}
	
	-- We need to reset the powerup spawner's
	for k,v in pairs(ents.FindByClass("trigger_powerup")) do
		v.Timer = 0
		v.NumPowerups = 0
	end
	
	-- Remove all the bombs spawned too
	for k,v in pairs(ents.FindByClass("sent_bomb")) do
		if (IsValid(v)) then
			v:Remove()
		end
	end
end

-- UpdateTopThree - Updates the top 3 list --
function GM:UpdateTopThree()
	local List = {}
	
	for i = 1, #player.GetAll() do
		local Highest = 0
		local Ply
		
		for k,v in pairs(player.GetAll()) do
			if (not table.HasValue(List, v)) and (v.Laps != 0) and ((Highest == 0) or (Highest < v.Laps)) then
				Highest = v.Laps
				Ply = v
			end
		end
		
		-- Insert the player to the list
		table.insert(List, Ply)
	end
	
	-- Set our leaders
	if (List[1]) then
		self.Stats.FirstPlace = List[1]:Name()
	else
		self.Stats.FirstPlace = "N/A"
	end
	if (List[2]) then
		self.Stats.SecondPlace = List[2]:Name()
	else
		self.Stats.SecondPlace = "N/A"
	end
	if (List[3]) then
		self.Stats.ThirdPlace = List[3]:Name()
	else
		self.Stats.ThirdPlace = "N/A"
	end
	
	-- Send them to the clients
	local Filter = RecipientFilter()
	Filter:AddAllPlayers()
	
	umsg.Start("Melonracer SetLeader", Filter)
		umsg.Char(4)
		umsg.String(self.Stats.FirstPlace)
		umsg.String(self.Stats.SecondPlace)
		umsg.String(self.Stats.ThirdPlace)
	umsg.End()
end

-- InitPostEntity - Count our checkpoints --
function GM:InitPostEntity()
	local Num = #ents.FindByClass("trigger_checkpoint")
	self.NumCheckpoints = Num
	
	dprint("****************************************")
	dprint("*** Number of checkpoints in map = " .. Num .. " ***")
	dprint("****************************************")
	
	-- Tell server we're in debugmode...
	if (SERVER) and (debug) then
		MsgN("**********************")
		MsgN("* Debugging enabled! *")
		MsgN("**********************")
	end
end

-- PlayerSpawn - Respawn the melon --
function GM:PlayerSpawn(Ply)
	-- Hide the players model
	Ply:DrawWorldModel(false)
	
	if (not Ply:HasMelon()) then
		-- Trace down and set the position at ground level
		local SpawnPoint = self:PlayerSelectSpawn(Ply)
		local MelonPos = SpawnPoint:GetPos()
		MelonPos.z = MelonPos.z + 7.75 -- So the melon doesn't spawn in ground
		
		-- Spawn the melon at our new pos
		local Melon = Ply:SpawnMelon(MelonPos)
		
		if (not self.GameStarted) then
			Melon:GetPhysicsObject():EnableMotion(false)
		end
	end
end

-- PlayerInitialSpawn - Setup stuff --
function GM:PlayerInitialSpawn(Ply)
	-- Our melon team
	Ply:SetTeam(100)
	
	-- Set up the variables to be used
	self:ResetVars(Ply)
	Ply.BestLap = 0
	
	-- We need to send over the server best
	umsg.Start("Melonracer SetServerBestLap", Ply)
		umsg.Float(GAMEMODE.Stats.BestLap)
		umsg.String(GAMEMODE.Stats.BestLapName)
	umsg.End()
	
	umsg.Start("Melonracer SetLeader", Ply)
		umsg.Char(4)
		umsg.String(self.Stats.FirstPlace)
		umsg.String(self.Stats.SecondPlace)
		umsg.String(self.Stats.ThirdPlace)
	umsg.End()
	
	if (#player.GetAll() <= 2) then
		timer.Simple(1, function()
			-- Tell the players
			for k,v in pairs(player.GetAll()) do
				v:ChatPrint("Match starting in 5 seconds!")
			end
			
			-- Start a new match
			self:NewMatch(5)
		end)
	end
end

-- PlayerDisconnected - Break the melon, update top 3 --
function GM:PlayerDisconnected(Ply)
	-- Break it
	Ply:BreakMelon()
	
	-- Update top 3
	self:UpdateTopThree()
end

-- DoPlayerDeath - Respawn melon, this shouldn't happen --
function GM:DoPlayerDeath(Ply, Attacker, DmgInfo)
	Ply:RespawnMelon()
end

-- PlayerDeathThink - Do nothing --
function GM:PlayerDeathThink(Ply)
end

-- CanPlayerSuicide - Prevent them from suicide --
function GM:CanPlayerSuicide(Ply)
	-- Show then what they can do instead
	Ply:ChatPrint("Type '-respawn' in chat or press 'reload button (R)' to break the melon and respawn.")
	
	return false
end

-- PlayerLoadout - Give the player no weapons --
function GM:PlayerLoadout(Ply)
	Ply:StripWeapons()
	
	return false
end

-- PlayerSay - Allow them to suicide with a command --
function GM:PlayerSay(Ply, Text, Public)
	-- Check if we've typed "-respawn"
	if (string.find(Text, "^-respawn")) and (string.len(Text) == 8) then
		-- Respawn the melon
		Ply:RespawnMelon()
		
		-- Add one to deaths
		Ply:AddDeaths(1)
	end
	
	return Text
end

-- PropBreak - Add 1 to deaths --
function GM:PropBreak(Attacker, Prop)
	for k,v in pairs(player.GetAll()) do
		if (v.Melon == Prop) then
			-- His melon broke, add 1 to deaths
			v:AddDeaths(1)
			
			break
		end
	end
end

-- Think - Do the controls --
function GM:Think()
	if (self.GameStarted) and (FrameTime() != 0) then
		for k,v in pairs(player.GetAll()) do
			-- Set the laptime
			v.LapTime = CurTime() - v.LapStart
			
			if (v:HasMelon()) then
				if (v:KeyDown(IN_RELOAD)) and (self.GameStarted) then
					-- Reload was pressed, killing melon
					v:RespawnMelon()
					v:AddDeaths(1)
				end
				
			else
				-- Respawn the melon
				v:RespawnMelon()
				
				if (v:KeyPressed(IN_ATTACK)) then
					-- Attack pressed, move to the melon spawn position
					if (v.CheckpointPos) then
						--v:Spectate(OBS_MODE_FIXED)
						v:SetPos(v.CheckpointPos + Vector(0, 0, 64))
						v:SetEyeAngles(v.CheckpointAng)
					end
				end
			end
		end
	end
end

//Downloads
if (SERVER) then
	resource.AddFile( "materials/melonracer/lap.vmt" )
	resource.AddFile( "materials/melonracer/lap.vtf" )
	resource.AddFile( "materials/melonracer/melon.vmt" )
	resource.AddFile( "materials/melonracer/melon.vtf" )
	resource.AddFile( "materials/melonracer/melongui.vmt" )
	resource.AddFile( "materials/melonracer/melongui.vtf" )
	resource.AddFile( "materials/melonracer/title.vmt" )
	resource.AddFile( "materials/melonracer/title.vtf" )
end