include("shared.lua")

local TextureCorner = surface.GetTextureID("gui/corner16")
local TextureLap = surface.GetTextureID("melonracer/lap")
local TextureMelonracer = surface.GetTextureID("melonracer/melongui")
local BellSound = "hl1/fvox/bell.wav"
//Fonts
function surface_CreateFontLegacy(font_name, size, weight, antialiasing, additive, new_font_name, drop_shadow, outlined, blur)
	
	local fd = {}
	
	fd.font = font_name
	fd.size = size
	fd.weight = weight
	fd.antialias = antialiasing
	fd.additive = additive
	
	surface.CreateFont(new_font_name, fd)
	
end

function ScaleToWideScreen(size)
	return math.min(math.max( ScreenScale(size / 2.62467192), math.min(size, 14) ), size);
end

surface_CreateFontLegacy("coolvetica", 32, 500, true, false, "ScoreboardHead");
surface_CreateFontLegacy("coolvetica", 42, 500, true, false, "ScoreboardSub");
surface_CreateFontLegacy("coolvetica", 22, 500, true, false, "ScoreboardSubtitle");
surface_CreateFontLegacy("Default", 16, 800, true, false, "ScoreboardText");
surface_CreateFontLegacy( "coolvetica", 32, 500, true, false, "ScoreboardHeader" )
surface_CreateFontLegacy( "coolvetica", 22, 500, true, false, "ScoreboardSubtitle" )
surface_CreateFontLegacy( "coolvetica", 19, 500, true, false, "ScoreboardPlayerName" )
surface_CreateFontLegacy( "coolvetica", 22, 500, true, false, "ScoreboardPlayerNameBig" )

-- Get the screen scale
local S = SScale(1)

-- InitPostEntity - Setup the player variable & stuff --
function GM:InitPostEntity()
	-- Set our player globally :3
	local Ply = LocalPlayer()
	if Ply then	
		Ply.ZoomDist = 100
		Ply.BestLap = 0
	end
	
	self:ResetVars()	
	self.BaseClass:InitPostEntity()
end

-- ResetVars - Reset the player variables for a new round --
function GM:ResetVars()
	local Ply = LocalPlayer()
	if Ply then	
		Ply.Respawning = 0
		Ply.WayTimer = 0
		Ply.Laps = 0
		Ply.LapTime = 0
		Ply.LastLap = 0
		Ply.Checkpoint = 0
	end
end

-- PlayBellSound - Play the 'bell' sound --
function GM:PlayBellSound(Times, Delay)
	Times = Times or 1
	Delay = Delay or 1
	
	-- Play the sound x amount of times
	for i = 0, Times - 1 do
		//timer.Simple(i*Delay, function() surface.PlaySound(BellSound) end)
	end
end

-- HUDShouldDraw - Remove old HL2 health/armor hud --
function GM:HUDShouldDraw(Name)
	if (Name == "CHudHealth") or (Name == "CHudBattery") then
		return false
	end
	
	return true
end

-- SpawnMenuEnabled - Disable spawnmenu --
function GM:SpawnMenuEnabled()
	return false	
end

-- SpawnMenuOpen - Disable spawnmenu --
function GM:SpawnMenuOpen()
	return false
end

-- ContextMenuOpen - Disable contextmenu --
function GM:ContextMenuOpen()
	return false
end

-- PopulateToolMenu - Don't populate the stool menu --
function GM:PopulateToolMenu()
	return false
end

-- PlayerBindPress - Disable things as flashlight --
function GM:PlayerBindPress(Ply, Bind, Pressed)
	if (string.find(Bind, "impulse 100")) then return true end
end 

-- CalcView - Set the chase distance --
function GM:CalcView(Ply, Position, Angles, FOV)
	if (Ply:KeyDown(IN_SPEED)) then
		-- Zoom out
		Ply.ZoomDist = math.min(250, Ply.ZoomDist + 200*FrameTime())
	elseif (Ply:KeyDown(IN_DUCK)) then
		-- Zoom in
		Ply.ZoomDist = math.max(0, Ply.ZoomDist - 200*FrameTime())
	end
	
	Ply.ZoomDist = Ply.ZoomDist || 100
	Ply.BestLap = Ply.BestLap || 0
	
	-- Prevent camera from noclipping with world
	local Melon = Ply:GetNetworkedEntity("Melon")
	if (Melon:IsValid()) then
		local Trace = util.QuickTrace(Melon:GetPos(), Ply:GetAimVector() * -Ply.ZoomDist, {Melon, Ply})
		
		local View = {}
		View.origin = Trace.HitPos + (Trace.HitNormal * 2)
		View.angles = Angles
		
		-- We're not actually here..
		Ply.FakePos = View.origin
		
		return View
	end
end

-- HUDPaint - All our HUD stuff is found in here --
local BorderSize = 8
function GM:HUDPaint()
	local Ply = LocalPlayer()
	if !(Ply && Ply:Alive()) then
		return
	end
	
	local ScrW = surface.ScreenWidth()
	local ScrH = surface.ScreenHeight()
	local CurTime = CurTime()
	
	Ply.Respawning = Ply.Respawning || 0
	-- Calculate time untill respawn
	local RespawnTime = Ply.Respawning - CurTime
	if (GAMEMODE.GameStarted) then
		-- Set the laptime
		Ply.LapTime = CurTime - (Ply.LapStart or CurTime)
		
		if (GAMEMODE.Countdown > CurTime) then
			-- Show the "GO!" text
			draw.SimpleTextOutlined("GO!", "ScoreboardHead", ScrW*0.5, ScrH*0.5, Color(0, 255, 0, 255), 1, 1, 1, Color(0, 0, 0, 255))
		end
	else
		-- Get how much time we got left
		local Countdown = GAMEMODE.Countdown - CurTime
		
		if (Countdown <= 0) then
			-- Countdown reached 0, start the game
			GAMEMODE.GameStarted = true
			GAMEMODE.Countdown = CurTime + 2
		else
			-- The the time left in M:S format
			local Time = string.FormattedTime(Countdown)
			
			-- We don't want 20 decimals
			Time.s = math.floor(Time.s)
			Time.ms = math.floor(Time.ms)
			
			-- Add a 0 if there is none
			if (Time.ms < 10) then
				Time.ms = "0" .. Time.ms
			end
			
			-- Draw it
			draw.SimpleTextOutlined(Time.s .. ":" .. Time.ms, "ScoreboardHead", ScrW*0.5 - 20, ScrH*0.5, Color(Countdown*85, 255 - Countdown*85, 0, 255), 0, 1, 1, Color(0, 0, 0, 255))
		end
	end
	
	---- Left HUD ----
	-- Get the size of the bestlap name, so we can adjust the size of the panel accordingly
	surface.SetFont("ScoreboardText")
	local NameW, NameH = math.max(60, surface.GetTextSize(self.Stats.BestLapName))
	
	-- The panels
	draw.RoundedBox(BorderSize, 10, 10, 210 + NameW, 265, Color(255, 255, 255, 150))
	draw.RoundedBox(BorderSize, 15, 15, 200 + NameW, 255, Color(0, 0, 0, 150))
	
	-- The melonracer logo
	surface.SetTexture(TextureMelonracer)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRect(25, 20, 256, 64) 
	
	-- All stats
	draw.SimpleTextOutlined("1.  " .. self.Stats.FirstPlace, "ScoreboardText", 25, 80, Color(255, 255, 100, 255), 0, 0, 1, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined("2.  " .. self.Stats.SecondPlace, "ScoreboardText", 25, 95, Color(255, 255, 177, 255), 0, 0, 1, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined("3.  " .. self.Stats.ThirdPlace, "ScoreboardText", 25, 110, Color(255, 255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
	
	draw.SimpleText("Best Lap:", "ScoreboardText", 25, 150, Color(255, 255, 255, 150), 0, 0)
	draw.SimpleText("Best Lap By:", "ScoreboardText", 25, 165, Color(255, 255, 255, 150), 0, 0)
	draw.SimpleTextOutlined(self.Stats.BestLapPrint, "ScoreboardText", 205, 150, Color(255, 255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined(self.Stats.BestLapName, "ScoreboardText", 205, 165, Color(255, 255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
	
	draw.SimpleText("Your Best Lap:", "ScoreboardText", 25, 190, Color(255, 255, 255, 150), 0, 0)
	draw.SimpleText("Your Last Lap:", "ScoreboardText", 25, 205, Color(255, 255, 255, 150), 0, 0)
	draw.SimpleText("Your Current Lap:", "ScoreboardText", 25, 220, Color(255, 255, 255, 150), 0, 0)
	draw.SimpleTextOutlined(string.ToMinutesSecondsMilliseconds(Ply.BestLap), "ScoreboardText", 205, 190, Color(255, 255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined(string.ToMinutesSecondsMilliseconds(Ply.LastLap), "ScoreboardText", 205, 205, Color(255, 255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined(string.ToMinutesSecondsMilliseconds(Ply.LapTime), "ScoreboardText", 205, 220, Color(255, 255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
	
	draw.SimpleText("Laps:", "ScoreboardText", 25, 245, Color(255, 255, 255, 150), 0, 0)
	draw.SimpleTextOutlined(Ply.Laps || 0 .. "/" .. self.NumLaps, "ScoreboardText", 205, 245, Color(255, 255, 255, 255), 0, 0, 1, Color(0, 0, 0, 255))
	
	
	-- Health panel --
	local Melon = Ply:GetNetworkedEntity("Melon")
	if (Melon:IsValid()) then
		local HP, MaxHP = Melon:GetNetworkedInt("HP") or 1, Melon:GetNetworkedInt("MaxHP") or 1
		local Ratio = (HP / MaxHP)
		
		-- Make sure we don't go negative
		if (Ratio > 0) then
			draw.RoundedBox(8, 15, ScrH - 55, ScrW - 40, 30, Color(0, 0, 0, 150))
			draw.RoundedBox(6, 20, ScrH - 50, Ratio * (ScrW - 50), 20, Color(math.abs(Ratio*255 - 255), Ratio*255, 0, 100))
		end
	end
	
	-- Respawn timer --
	if (RespawnTime > 0) then
		local Seconds = math.floor(RespawnTime*10)/10
		
		if (Seconds % 1 == 0) then
			-- There's no decimal, add it
			Seconds = Seconds .. ".0"
		end
		
		-- Show respawn text
		draw.SimpleTextOutlined("Respawning in: " .. Seconds .. " second(s)...", "ScoreboardText", ScrW*0.5, ScrH*0.5, Color(255, 255, 255, 255), 1, 1, 1, Color(0, 0, 0, 255))
		draw.SimpleTextOutlined("Press left mouse button to go to the last checkpoint spawn", "ScoreboardText", ScrW*0.5, ScrH*0.5 + 15, Color(255, 255, 255, 255), 1, 1, 1, Color(0, 0, 0, 255))
	end
	
	---- Names ----
	-- Player names --
	for k,v in pairs(player.GetAll()) do
		local Melon = v:GetNetworkedEntity("Melon")
		
		-- Make sure our melon is valid before we do anything
		if (Melon:IsValid()) then
			-- Make a traceline
			local Trace = {}
			Trace.start = Ply.FakePos
			Trace.endpos = Melon:GetPos()
			Trace.filter = Ply
			Trace.mask = MASK_SOLID
			Trace = util.TraceLine(Trace) 
			
			if (Trace.HitNonWorld) and (string.find(Trace.Entity:GetClass(), "sent_melon")) then
				local Pos = Melon:GetPos() + Vector(0, 0, 10)
				local PosScr = Pos:ToScreen()
				
				-- Draw their names above their melons
				draw.SimpleTextOutlined(v:Name(), "Default", PosScr.x, PosScr.y, Color(200, 255, 200, 255), 1, 1, 1, Color(0, 0, 0, 255))
			end
		end
	end
	
	-- Powerups --
	if not (self.HidePowerupNames) then
		for k,v in pairs(ents.FindByClass("sent_powerup")) do
			if (IsValid(v)) then
				-- Make a traceline
				local Trace = {}
				Trace.start = Ply.FakePos
				Trace.endpos = v:GetPos()
				Trace.filter = {Ply, Ply:GetNetworkedEntity("Melon")}
				Trace.mask = MASK_SOLID
				Trace = util.TraceLine(Trace) 
				
				if not (Trace.Hit) then
					-- Get our powerup type
					local PowerupType = v:GetNetworkedString("PowerupType", nil)
					
					-- Make sure it's valid
					if (PowerupType) then
						-- Get positions and alpha
						local Pos = v:GetPos() + Vector(0, 0, 20)
						local PosScr = Pos:ToScreen()
						local A = math.max(2000 - (Ply.FakePos - v:GetPos()):Length(), 0) / 2000
						
						-- Draw text in different colors depending on if it's useful or not
						if (self.Powerups[PowerupType]) then
							if (self.Powerups[PowerupType].Useful) then
								draw.SimpleTextOutlined(self.Powerups[PowerupType].PrintName, "Default", PosScr.x, PosScr.y, Color(100, 100, 255, 255*A), 1, 1, 0.5, Color(0, 100, 0, 255*A))
							else
								draw.SimpleTextOutlined(self.Powerups[PowerupType].PrintName, "Default", PosScr.x, PosScr.y, Color(255, 100, 100, 255*A), 1, 1, 0.5, Color(0, 0, 100, 255*A))
							end
						end
					end
				end
			end
		end
	end
	
	-- Which way you are going --
	if (Ply.Way) and (Ply.WayTimer > CurTime) then
		local Text
		local Col
		
		if (Ply.Way == 1) then
			-- Player just went through a checkpoint
			Text = "Checkpoint " .. Ply.Checkpoint .. "!"
			Col = Color(255, 255, 255, 255)
			
		elseif (Ply.Way == 2) then
			-- Player just made a lap
			local Left = math.max(Ply.WayTimer - CurTime - 1, 0)
			surface.SetTexture(TextureLap)
			surface.SetDrawColor(255, 255, 255, math.min(Left * 200, 200))
			surface.DrawTexturedRect(ScrW*0.5 - Left*100*S, ScrH*0.5 - Left*50*S - 100*S, Left*200*S, Left*100*S)
			
		elseif (Ply.Way == 3) then
			-- Player is going the wrong way
			Text = "You're going the wrong way!"
			Col = Color(255, 100, 100, 255)
			
			Ply.WayTimer = Ply.WayTimer + 1
		end
		
		if (Text) then
			-- Draw what we set above
			draw.SimpleTextOutlined(Text, "ScoreboardSub", ScrW*0.5, ScrH - 75, Col, 1, 1, 1, Color(0, 0, 0, 255))
		end
	end
end

/*********************************/
--[[ USERMESSAGES ONLY BELOW ]]--
/*********************************/
-- Usermessage 'Melonracer Countdown' --
local function Umsg(UM)
	GAMEMODE.Countdown = CurTime() + 3
	GAMEMODE.GameStarted = false
	GAMEMODE:ResetVars()
end
usermessage.Hook("Melonracer Countdown", Umsg)

-- Usermessage 'Melonracer RespawnMelon' --
local function Umsg(UM)
	local Ply = LocalPlayer()
	if !(Ply) then
		return
	end
	Ply.Respawning = CurTime() + UM:ReadFloat()
end
usermessage.Hook("Melonracer RespawnMelon", Umsg)

-- Usermessage 'Melonracer RightWay' --
local function Umsg(UM)
	local Ply = LocalPlayer()
	if !(Ply) then
		return
	end
	
	Ply.Way = UM:ReadChar()
	Ply.WayTimer = CurTime() + 3
	
	if (Ply.Way == 1) then
		-- It's a checkpoint, get the current checkpoint number
		Ply.Checkpoint = UM:ReadShort()
	elseif (Ply.Way == 2) then
		-- It's a lap, we sent the current lap too, get it
		Ply.Laps = UM:ReadShort()
	end
end
usermessage.Hook("Melonracer RightWay", Umsg)

-- Usermessage 'Melonracer SetLapStart' --
local function Umsg(UM)
	local Ply = LocalPlayer() -- This is needed at some places because global doesn't exst yet
	Ply.LapStart = UM:ReadFloat()
end
usermessage.Hook("Melonracer SetLapStart", Umsg)

-- Usermessage 'Melonracer SetBestLap' --
local function Umsg(UM)
	local Ply = UM:ReadEntity()
	Ply.BestLap = UM:ReadFloat()
end
usermessage.Hook("Melonracer SetBestLap", Umsg)

-- Usermessage 'Melonracer SetLastLap' --
local function Umsg(UM)
	local Ply = LocalPlayer()
	if !(Ply) then
		return
	end
	Ply.LastLap = UM:ReadFloat()
end
usermessage.Hook("Melonracer SetLastLap", Umsg)

-- Usermessage 'Melonracer SetServerBestLap' --
local function Umsg(UM)
	GAMEMODE.Stats.BestLap = UM:ReadFloat()
	GAMEMODE.Stats.BestLapPrint = string.ToMinutesSecondsMilliseconds(GAMEMODE.Stats.BestLap)
	GAMEMODE.Stats.BestLapName = UM:ReadString()
end
usermessage.Hook("Melonracer SetServerBestLap", Umsg)

-- Usermessage 'Melonracer SetLeader' --
local function Umsg(UM)
	local Pos = UM:ReadChar()
	local Name = UM:ReadString()
	local Name2 = UM:ReadString()
	local Name3 = UM:ReadString()
	
	if (Pos == 1) then
		GAMEMODE.Stats.FirstPlace = Name
	elseif (Pos == 2) then
		GAMEMODE.Stats.SecondPlace = Name
	elseif (Pos == 3) then
		GAMEMODE.Stats.ThirdPlace = Name
	else
		GAMEMODE.Stats.FirstPlace = Name
		GAMEMODE.Stats.SecondPlace = Name2
		GAMEMODE.Stats.ThirdPlace = Name3
	end
end
usermessage.Hook("Melonracer SetLeader", Umsg)

-- Usermessage 'Melonracer ResetVars' --
local function Umsg(UM)
	GAMEMODE:ResetVars()
end
usermessage.Hook("Melonracer ResetVars", Umsg)

surface.CreateFont( "ScoreboardDefault",
{
	font		= "Helvetica",
	size		= 22,
	weight		= 800
})

surface.CreateFont( "ScoreboardDefaultTitle",
{
	font		= "Helvetica",
	size		= 32,
	weight		= 800
})


--
-- This defines a new panel type for the player row. The player row is given a player
-- and then from that point on it pretty much looks after itself. It updates player info
-- in the think function, and removes itself when the player leaves the server.
--
local PLAYER_LINE = 
{
	Init = function( self )

		self.AvatarButton = self:Add( "DButton" )
		self.AvatarButton:Dock( LEFT )
		self.AvatarButton:SetSize( 32, 32 )
		self.AvatarButton.DoClick = function() self.Player:ShowProfile() end

		self.Avatar		= vgui.Create( "AvatarImage", self.AvatarButton )
		self.Avatar:SetSize( 32, 32 )
		self.Avatar:SetMouseInputEnabled( false )		

		self.Name		= self:Add( "DLabel" )
		self.Name:Dock( FILL )
		self.Name:SetFont( "ScoreboardDefault" )
		self.Name:DockMargin( 8, 0, 0, 0 )
		self.Name:SetTextColor( Color( 54, 54, 54, 255 ) )
		self.Mute		= self:Add( "DImageButton" )
		self.Mute:SetSize( 32, 32 )
		self.Mute:Dock( RIGHT )

		self.Ping		= self:Add( "DLabel" )
		self.Ping:Dock( RIGHT )
		self.Ping:SetWidth( 50 )
		self.Ping:SetFont( "ScoreboardDefault" )
		self.Ping:SetContentAlignment( 5 )
		self.Ping:SetTextColor( Color( 54, 54, 54, 255 ) )
		self:Dock( TOP )
		self:DockPadding( 3, 3, 3, 3 )
		self:SetHeight( 32 + 3*2 )
		self:DockMargin( 2, 0, 2, 2 )

	end,

	Setup = function( self, pl )

		self.Player = pl

		self.Avatar:SetPlayer( pl )
		self.Name:SetText( pl:Nick() )

		self:Think( self )

		--local friend = self.Player:GetFriendStatus()
		--MsgN( pl, " Friend: ", friend )

	end,

	Think = function( self )

		if ( !IsValid( self.Player ) ) then
			self:Remove()
			return
		end	

		if ( self.NumPing == nil || self.NumPing != self.Player:Ping() ) then
			self.NumPing	=	self.Player:Ping()
			self.Ping:SetText( self.NumPing )
		end

		--
		-- Change the icon of the mute button based on state
		--
		if ( self.Muted == nil || self.Muted != self.Player:IsMuted() ) then

			self.Muted = self.Player:IsMuted()
			if ( self.Muted ) then
				self.Mute:SetImage( "icon32/muted.png" )
			else
				self.Mute:SetImage( "icon32/unmuted.png" )
			end

			self.Mute.DoClick = function() self.Player:SetMuted( !self.Muted ) end

		end

		--
		-- Connecting players go at the very bottom
		--
		if ( self.Player:Team() == TEAM_CONNECTING ) then
			self:SetZPos( 2000 )
		end

		--
		-- This is what sorts the list. The panels are docked in the z order, 
		-- so if we set the z order according to kills they'll be ordered that way!
		-- Careful though, it's a signed short internally, so needs to range between -32,768k and +32,767
		--
	//	self:SetZPos( (self.NumKills * -50) + self.NumDeaths )

	end,

	Paint = function( self, w, h )

		if ( !IsValid( self.Player ) ) then
			return
		end

		--
		-- We draw our background a different colour based on the status of the player
		--

		if ( self.Player:Team() == TEAM_CONNECTING ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 200, 200, 200, 200 ) )
			return
		end

		if  ( !self.Player:Alive() ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 200, 200, 255 ) )
			return
		end

		if ( self.Player:IsAdmin() ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 255, 230, 255 ) )
			return
		end

		draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 230, 230, 255 ) )

	end,
}

--
-- Convert it from a normal table into a Panel Table based on DPanel
--
PLAYER_LINE = vgui.RegisterTable( PLAYER_LINE, "DPanel" );

--
-- Here we define a new panel table for the scoreboard. It basically consists 
-- of a header and a scrollpanel - into which the player lines are placed.
--
local SCORE_BOARD = 
{
	Init = function( self )

		self.Header = self:Add( "Panel" )
		self.Header:Dock( TOP )
		self.Header:SetHeight( 100 )

		self.Name = self.Header:Add( "DLabel" )
		self.Name:SetFont( "ScoreboardDefaultTitle" )
		self.Name:SetTextColor( Color( 255, 255, 255, 255 ) )
		self.Name:Dock( TOP )
		self.Name:SetHeight( 40 )
		self.Name:SetContentAlignment( 5 )
		self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

		self.NumPlayers = self.Header:Add( "DLabel" )
		self.NumPlayers:SetFont( "ScoreboardDefault" )
		self.NumPlayers:SetTextColor( Color( 255, 255, 255, 255 ) )
		self.NumPlayers:SetPos( 0, 100 - 30 )
		self.NumPlayers:SetSize( 300, 30 )
		self.NumPlayers:SetContentAlignment( 4 )

		self.Scores = self:Add( "DScrollPanel" )
		self.Scores:Dock( FILL )

	end,

	PerformLayout = function( self )

		self:SetSize( 700, ScrH() - 200 )
		self:SetPos( ScrW() / 2 - 350, 100 )

	end,

	Paint = function( self, w, h )

		draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 200 ) )

	end,

	Think = function( self, w, h )

		self.NumPlayers:SetText("MelonRacer 1.3")
		self.Name:SetText(GetHostName())

		--
		-- Loop through each player, and if one doesn't have a score entry - create it.
		--
		local plyrs = player.GetAll()
		for id, pl in pairs( plyrs ) do

			if ( IsValid( pl.ScoreEntry ) ) then continue end

			pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
			pl.ScoreEntry:Setup( pl )

			self.Scores:AddItem( pl.ScoreEntry )

		end		

	end,
}

SCORE_BOARD = vgui.RegisterTable( SCORE_BOARD, "EditablePanel" );

--[[---------------------------------------------------------
   Name: gamemode:ScoreboardShow( )
   Desc: Sets the scoreboard to visible
-----------------------------------------------------------]]
function GM:ScoreboardShow()

	if ( !IsValid( g_Scoreboard ) ) then
		g_Scoreboard = vgui.CreateFromTable( SCORE_BOARD )
	end

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Show()
		g_Scoreboard:MakePopup()
	end

end

--[[---------------------------------------------------------
   Name: gamemode:ScoreboardHide( )
   Desc: Hides the scoreboard
-----------------------------------------------------------]]
function GM:ScoreboardHide()

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Hide()
	end

end


--[[---------------------------------------------------------
   Name: gamemode:HUDDrawScoreBoard( )
   Desc: If you prefer to draw your scoreboard the stupid way (without vgui)
-----------------------------------------------------------]]
function GM:HUDDrawScoreBoard()

end