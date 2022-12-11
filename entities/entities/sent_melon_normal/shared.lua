ENT.Type 			= "anim"
ENT.Base 			= "sent_melon_base"


-- Our speeds, no need to define them, we're using the base speed here
-- ENT.ForwardSpeed = 0
-- ENT.ReverseSpeed = 0
-- ENT.StrafeSpeed = 0

-- Under min will be no damage, else it's min/max damage
-- This is the speed the melon needs to take damage
ENT.MinDamageRange = 400
ENT.MaxDamageRange = 900

ENT.HP = 1.5 -- How much damage the melon can take
ENT.MaxHP = ENT.HP -- Leave
ENT.HPRegen = 0.1 -- HP/second it regenerates