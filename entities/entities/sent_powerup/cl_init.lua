include('shared.lua')

local Outline = Material("models/props_combine/portalball001_sheet")

-- ENT:Initialize - Nothing? --
function ENT:Initialize()

end

-- ENT:Draw - Draw the model --
function ENT:Draw()
	-- Draw the normal model
	self.Entity:SetModelScale( 0.8, 1 )
	self.Entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self.Entity:SetColor( Color(100, 30, 255, 128) )
	self.Entity:DrawModel()
	
	-- Draw the outlining
	self.Entity:SetModelScale( 0.825, 1 )

	self.Entity:DrawModel()
	-- Draw the outlining again
	self.Entity:SetModelScale( 0.85, 1 )
	self.Entity:DrawModel()

	-- Put it back to normal
	self.Entity:SetModelScale( 0.8, 1 )
end

