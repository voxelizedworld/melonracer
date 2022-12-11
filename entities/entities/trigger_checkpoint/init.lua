ENT.Base = "base_brush"
ENT.Type = "brush"

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	self.CheckpointNum = self.CheckpointNum or 1
end

/*---------------------------------------------------------
   Name: StartTouch
---------------------------------------------------------*/
function ENT:StartTouch(Ent)
	-- Debug
	dprint(tostring(self.Entity) .. ":StartTouch(" .. tostring(Ent) .. ")")
	
	local Owner = Ent:GetOwner()
	if (IsValid(Owner) and Owner:IsConnected()) then
		-- Make sure we have a calid checkpoint
		if (not self.Entity.CheckpointNum) then
			-- There is no valid checkpoint number
			error("Entity "..tostring(Ent).." doesn't have a valid checkpoint number!")
			
			-- Stop here
			return
		end
		
		local OK = Owner:CheckCheckpoint(self.Entity.CheckpointNum)
		if (OK) then
			-- We're going the right way, update the checkpoint
			Owner:SetCheckpoint(self.Entity.CheckpointNum)
		end
	end
end

/*---------------------------------------------------------
   Name: EndTouch
---------------------------------------------------------*/
function ENT:EndTouch(Ent)
end

/*---------------------------------------------------------
   Name: Touch
---------------------------------------------------------*/
function ENT:Touch(Ent)
end

/*---------------------------------------------------------
   Name: PassesTriggerFilters
   Desc: Return true if this object should trigger us
---------------------------------------------------------*/
function ENT:PassesTriggerFilters(Ent)
	return true
end

/*---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us
---------------------------------------------------------*/
function ENT:KeyValue(Key, Value)
	if (string.lower(Key) == "checkpoint") then
		self.CheckpointNum = tonumber(Value)
	end
end

/*---------------------------------------------------------
   Name: Think
   Desc: Entity's think function. 
---------------------------------------------------------*/
function ENT:Think()
end

/*---------------------------------------------------------
   Name: OnRemove
   Desc: Called just before entity is deleted
---------------------------------------------------------*/
function ENT:OnRemove()
end
