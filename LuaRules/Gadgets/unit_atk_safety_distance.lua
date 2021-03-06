function gadget:GetInfo()
  return {
    name      = "Attack Safety distance setter",
    desc      = "Sets attack safety distance for fighter/bomber aircraft",
    author    = "raaar",
    date      = "2015",
    license   = "PD",
    layer     = 3,
    enabled   = true
  }
end


local specialCases = {
	aven_ace = 9999.0
}

local DEFAULT_DISTANCE = 350.0


if (gadgetHandler:IsSyncedCode()) then

	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if (UnitDefs[unitDefID].canFly and  UnitDefs[unitDefID].isStrafingAirUnit and not UnitDefs[unitDefID].hoverAttack) then 
			local dist = DEFAULT_DISTANCE
			local name = UnitDefs[unitDefID].name
			if specialCases[name] then
				dist = specialCases[name]
			end		
			
 			Spring.MoveCtrl.SetAirMoveTypeData(unitID,{attackSafetyDistance=dist})
		end
	end

end