g_vehicleIdDelorean = 541

function isVehicleTimeMachine(vehicle)
    if not isVehicleDelorean(vehicle) then
        return false
    end
    local variation = getElementData(vehicle, "deloreanVariation")
    if not variation then 
        return false 
    end
    return string.sub(variation, 1, 4) == "bttf"
end

function isVehicleDelorean(vehicle)
    return getElementModel(vehicle) == g_vehicleIdDelorean
end

function getVehicleSpeedMph(vehicle)
    local vX, vY, vZ = getElementVelocity(vehicle)
	local mph = ((vX^2 + vY^2 + vZ^2)^(0.5)) * 111.847
    return mph
end