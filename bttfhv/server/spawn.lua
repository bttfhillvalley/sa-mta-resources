addEvent("spawnVehicle", true)
function handleSpawnVehicleEvent(delorean)
	--outputDebugString(string.format("spawnVehicle event triggered, %i", delorean))
    local posX, posY, posZ = getElementPosition(client)
	local rotX, rotY, rotZ = getElementRotation(client)
	local vehicle = createVehicle(delorean, posX, posY, posZ, rotX, rotY, rotZ)
	if not vehicle then
		outputDebugString("createVehicle failed")
		return
	end
	createBlipAttachedTo(vehicle, 0, 2, 192, 192, 192, 255, -1, 99999.0, getRootElement())
	setElementDimension(vehicle, getElementDimension(client))
	warpPedIntoVehicle(client, vehicle)
	setVehicleColor(vehicle, 14, 13, 0, 0)
	setElementData(vehicle, "deloreanVariation", "stock")
	triggerClientEvent("vehicleSpawned", source, vehicle)
end
addEventHandler("spawnVehicle", getRootElement(), handleSpawnVehicleEvent)
