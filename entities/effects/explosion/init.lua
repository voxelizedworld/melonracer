
function EFFECT:Init(Data)
	local Pos = Data:GetOrigin()
	local Norm = Data:GetNormal()
	local Force
	
	local Emitter = ParticleEmitter(Pos)
	
	if (Emitter) then		
		-- FIRE CORE --
		Force = 1600
		for i = 1, 400 do
			local P = Emitter:Add("effects/fire_cloud1", Pos)
			local Vec = Vector(math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force)) + Norm/4 * Force
			
			P:SetVelocity(Vec)
			P:SetColor( Color(100, 100, 100) )
			P:SetDieTime(math.Rand(0.3, 0.6))
			P:SetStartAlpha(255)
			P:SetEndAlpha(0)
			P:SetStartSize(math.random(30, 50))
			P:SetEndSize(0)
			P:SetRollDelta(math.Rand(-1, 1))
			P:SetAirResistance(math.random(250, 450))
			P:SetGravity(Vector(0, 0, 0))
			P:SetCollide(true)
			P:SetBounce(0)
			
			P:SetStartLength(50)
			P:SetEndLength(100)
		end
		
		-- FIRE --
		Force = 700
		for i = 1, 450 do
			local P = Emitter:Add("effects/fire_cloud2", Pos)
			local Vec = Vector(math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force)) + Norm/2 * Force
			
			P:SetVelocity(Vec)
			P:SetColor( Color(255, 255, 255) )
			P:SetDieTime(math.Rand(0.5, 0.7))
			P:SetStartAlpha(255)
			P:SetEndAlpha(0)
			P:SetStartSize(20)
			P:SetEndSize(math.random(40, 60))
			P:SetRollDelta(math.Rand(-1, 1))
			P:SetAirResistance(math.random(120, 200))
			P:SetGravity(Vector(0, 0, math.random(-80, -10)))
			P:SetCollide(true)
			P:SetBounce(0.1)
		end
		
		-- FIRE EMBERS --
		Force = 500
		for i = 1, 50 do
			local P = Emitter:Add("effects/fire_embers"..math.random(1, 3), Pos)
			local Vec = Vector(math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force)) + Norm/3 * Force
			
			P:SetVelocity(Vec)
			P:SetColor( Color(255, 255, 255) )
			P:SetDieTime(math.Rand(3, 6))
			P:SetStartAlpha(255)
			P:SetEndAlpha(0)
			P:SetStartSize(math.Rand(2, 7))
			P:SetEndSize(0)
			P:SetRollDelta(math.Rand(-10, 10))
			P:SetAirResistance(math.random(40, 80))
			P:SetGravity(Vector(0, 0, math.random(-160, 160)))
			P:SetCollide(true)
			P:SetBounce(0.1)
		end
		
		-- SMOKE CORE --
		Force = 700
		for i = 1, 50 do
			local P = Emitter:Add("particles/smokey", Pos)
			local Vec = Vector(math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force)) + Norm/3 * Force
			local ColRand = math.random(140, 180)
			
			P:SetVelocity(Vec)
			P:SetColor( Color(ColRand, ColRand, ColRand) )
			P:SetDieTime(math.Rand(2, 5))
			P:SetStartAlpha(200)
			P:SetEndAlpha(0)
			P:SetStartSize(80)
			P:SetEndSize(math.random(80, 100))
			P:SetRollDelta(math.Rand(-1, 1))
			P:SetAirResistance(math.random(100, 150))
			P:SetGravity(Vector(0, 0, math.random(10, 80)))
			P:SetCollide(true)
			P:SetBounce(0.1)
			
			P:SetStartLength(100)
			P:SetEndLength(100)
		end
		
		-- SMOKE --
		Force = 300
		for i = 1, 100 do
			local P = Emitter:Add("particles/smokey", Pos)
			local Vec = Vector(math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force)) + Norm/2 * Force
			
			P:SetVelocity(Vec)
			P:SetColor( Color(150, 150, 150) )
			P:SetDieTime(math.Rand(2, 5))
			P:SetStartAlpha(200)
			P:SetEndAlpha(0)
			P:SetStartSize(math.random(10, 20))
			P:SetEndSize(math.random(80, 100))
			P:SetRollDelta(math.Rand(-1, 1))
			P:SetAirResistance(math.random(50, 100))
			P:SetGravity(Vector(0, 0, math.random(30, 80)))
			P:SetCollide(true)
			P:SetBounce(0.1)
		end
		
		-- DIRT --
		Force = 400
		for i = 1, 100 do
			local P = Emitter:Add("particle/rain", Pos)
			local Vec = Vector(math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force)) + Norm * Force
			
			P:SetVelocity(Vec)
			P:SetColor( Color(100, 100, 60) )
			P:SetDieTime(math.Rand(20, 30))
			P:SetStartAlpha(255)
			P:SetEndAlpha(0)
			P:SetStartSize(math.Rand(1, 1.5))
			P:SetEndSize(math.random(0, 1))
			P:SetRollDelta(math.Rand(-5, 5))
			P:SetAirResistance(0)
			P:SetGravity(Vector(0, 0, math.random(-800, -400)))
			P:SetCollide(true)
			P:SetBounce(0.3)
		end
		
		-- DEBRIS --
		--[[Force = 600
		for i = 1, math.random(3, 5) do
			local P = Emitter:Add("particle/rain", Pos)
			local Vec = Vector(math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force), math.cos(math.Rand(-1, 1)) * math.Rand(-Force, Force)) + Norm * Force
			
			P:SetVelocity(Vec)
			P:SetDieTime(math.Rand(2, 4))
			P:SetStartAlpha(0)
			P:SetEndAlpha(0)
			P:SetGravity(Vector(0, 0, math.random(-600, -400)))
			P:SetCollide(true)
			P:SetBounce(0.3)
			
			P:SetThinkFunction(function()
				local Pos = P:GetPos()
				local Emitter = ParticleEmitter(Pos)
				
				if (Emitter) then
					local P = Emitter:Add("particles/smokey", Pos)
					
					P:SetColor(150, 150, 150)
					P:SetDieTime(math.Rand(1, 2))
					P:SetStartAlpha(200)
					P:SetEndAlpha(0)
					P:SetStartSize(math.random(5, 10))
					P:SetEndSize(math.random(20, 40))
					P:SetRollDelta(math.Rand(-1, 1))
					P:SetGravity(Vector(0, 0, math.random(30, 80)))
					P:SetCollide(true)
				end
				
				P:SetNextThink(CurTime() + 1)
			end)
			P:SetNextThink(CurTime() + 1)
			
			P:SetCollideCallback(function()
				P:SetDieTime(math.Rand(1, 2))
			end)
		end]]
		
	end

	Emitter:Finish()

end


function EFFECT:Think()
	return false
end


function EFFECT:Render()
end



