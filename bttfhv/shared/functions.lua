g_vehicleIdDelorean = 541

function isVehicleTimeMachine(vehicle)
    return getElementModel(vehicle) == g_vehicleIdDelorean
end

function getVehicleSpeedMph(vehicle)
    local vX, vY, vZ = getElementVelocity(vehicle)
	local mph = ((vX^2 + vY^2 + vZ^2)^(0.5)) * 111.847
    return mph
end