function widget:GetInfo()
	return {
		name	= "Settings",
		desc	= "Overrides some Spring settings: grass, camera and maxParticles",
		author	= "raaar",
		date	= "2015-07-20",
		license	= "PD",
		layer	= 5,
		enabled	= true
	}
end

function widget:Initialize()
	-- disable grass
	Spring.SetConfigInt("GrassDetail",0)
	
	-- set camera to "ta" mode
	local camState = Spring.GetCameraState()
	camState.name = 'ta'
	camState.mode = Spring.GetCameraNames()['ta']
	Spring.SetCameraState(camState, 0)
	
	-- set max particles to 20000
	Spring.SetConfigInt("MaxParticles",20000)
end

