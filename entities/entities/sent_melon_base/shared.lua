ENT.Type 			= "anim"
ENT.Base 			= "base_anim"


-- Our speeds
ENT.ForwardSpeed = GAMEMODE.DefForwardSpeed
ENT.ReverseSpeed = GAMEMODE.DefReverseSpeed
ENT.StrafeSpeed = GAMEMODE.DefStrafeSpeed

-- Under min will be no damage, else it's min/max damage
-- This is the speed the melon needs to take damage
ENT.MinDamageRange = 400
ENT.MaxDamageRange = 900

ENT.HP = 1.5 -- How much damage the melon can take
ENT.MaxHP = ENT.HP -- Leave
ENT.HPRegen = 0.1 -- HP/second it regenerates