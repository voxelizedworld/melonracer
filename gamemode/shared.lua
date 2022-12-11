debug = false

GM.Name 	= "Melonracer 1.3"
GM.Author 	= "Robbis_1, Valkyrie"
GM.Email 	= ""
GM.Website 	= ""

-- Constants --
GM.Model = "models/props_junk/watermelon01.mdl" -- The melon model, change for funky effects

GM.RespawnDelay = 2			-- How long you need to wait until you respawn
GM.DefForwardSpeed = 250	-- Forward speed
GM.DefReverseSpeed = 125	-- Backward speed
GM.DefStrafeSpeed = 100		-- Force applied when strafing
GM.NumLaps = 10				-- How many laps until somebody wins?
GM.EnablePowerups = true	-- Should powerups be enabled?
GM.SpawnAtCheckpoint = true	-- If this is true, you will respawn at the latest checkpoint and keep your time, else first checkpoint with reset time
GM.HidePowerupNames = true	-- If this is true, you won't see the powerup names

GM.GameStarted = true
GM.Countdown = 0
GM.Classes = {}

GM.Stats = {}
GM.Stats.BestLap = 0
GM.Stats.BestLapPrint = "--:--:--"
GM.Stats.BestLapName = "N/A"
GM.Stats.FirstPlace = "N/A"
GM.Stats.SecondPlace = "N/A"
GM.Stats.ThirdPlace = "N/A"

GM.Powerups = GM.Powerups or {}
GM.Powerups.Entities = GM.Powerups.Entities or {}

-- MUST contain all names of all powerups below (in correct order)
GM.Powerups.Names = 
	{
		"Bomb", 
		"Haste", 
		"God", 
		"LessTime", 
		"Drug", 
		"TimedBomb", 
		"Slow", 
		"Weak", 
		"MoreTime"
	}

-------------------- POWERUPS --------------------
-- Good --
GM.Powerups.Bomb = {}
GM.Powerups.Bomb.Ammo = 1
GM.Powerups.Bomb.ActivationDelay = 1
GM.Powerups.Bomb.RemovalDelay = 15
GM.Powerups.Bomb.DropKey = IN_ATTACK
GM.Powerups.Bomb.DropDelay = 0.3
GM.Powerups.Bomb.Useful = true
GM.Powerups.Bomb.PrintName = "Bomb"

GM.Powerups.Haste = {}
GM.Powerups.Haste.Duration = 5
GM.Powerups.Haste.Boost = 100
GM.Powerups.Haste.Material = "models/props_combine/tprings_globe"
GM.Powerups.Haste.Useful = true
GM.Powerups.Haste.PrintName = "Haste"

GM.Powerups.God = {}
GM.Powerups.God.Duration = 10
GM.Powerups.God.Color = Color(100, 100, 255, 255)
GM.Powerups.God.Useful = true
GM.Powerups.God.PrintName = "God Mode"

GM.Powerups.LessTime = {}
GM.Powerups.LessTime.TimeMin = 1
GM.Powerups.LessTime.TimeMax = 6
GM.Powerups.LessTime.Useful = true
GM.Powerups.LessTime.PrintName = "Decreased Time (1s - 6s)"

-- Bad --
GM.Powerups.Drug = {}
GM.Powerups.Drug.Duration = 10
GM.Powerups.Drug.Useful = false
GM.Powerups.Drug.PrintName = "Drugs"

GM.Powerups.TimedBomb = {}
GM.Powerups.TimedBomb.Duration = 10
GM.Powerups.TimedBomb.ExplosionRadius = 200
GM.Powerups.TimedBomb.ExplosionDamage = 100
GM.Powerups.TimedBomb.Useful = false
GM.Powerups.TimedBomb.PrintName = "Timed Bomb"

GM.Powerups.Slow = {}
GM.Powerups.Slow.Duration = 10
GM.Powerups.Slow.Slowdown = 200
GM.Powerups.Slow.Useful = false
GM.Powerups.Slow.PrintName = "Slowdown"

GM.Powerups.Weak = {}
GM.Powerups.Weak.Duration = 10
GM.Powerups.Weak.MinDamageRange = 300
GM.Powerups.Weak.MaxDamageRange = 800
GM.Powerups.Weak.Useful = false
GM.Powerups.Weak.PrintName = "Weakness"

GM.Powerups.MoreTime = {}
GM.Powerups.MoreTime.TimeMin = 3
GM.Powerups.MoreTime.TimeMax = 8
GM.Powerups.MoreTime.Useful = false
GM.Powerups.MoreTime.PrintName = "Increased Time (3s - 8s)"
---------------------------------------------------------

-- Our team that everybody uses, so we just need one --
team.SetUp(100, "Melonracers", Color(100, 255, 100, 255))

-- Some debug printing functions --
function dprint(...)
	if (debug) then
		if (SERVER) then
			print("SRV: ", unpack(arg))
		elseif (CLIENT) then
			print("CLI: ", unpack(arg))
		end
	end
end

function dPrintTable(t)
	if (debug) then
		PrintTable(t)
	end
end
