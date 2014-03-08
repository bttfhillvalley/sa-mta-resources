prohibitedVehicles = {425, 432, 520, 441, 464, 594, 501, 465, 564,}
lastCarSpawn = {}
function createVehicleForPlayer(thePlayer, vehicleModel)
	if not lastCarSpawn[thePlayer] then
		lastCarSpawn[thePlayer] = 0
	end
	if not getPedOccupiedVehicle(thePlayer) and (getElementInterior(thePlayer) == 0) and not isPedDead(thePlayer) then
		local spawnCooldown = (getTickCount() - lastCarSpawn[thePlayer]) / 1000
		if not (spawnCooldown >= 30) then
		    outputChatBox(string.format("You have to wait an other %2i seconds before you can spawn a new vehicle.", 30 - spawnCooldown), thePlayer, 255, 0, 0)
		    return
		end
		if vehicleModel == nil then
			triggerClientEvent(thePlayer, "showVehicleSpawnGui", thePlayer)
			return
		end
		if (vehicleModel == "delorean") then
			vehicleModel = DeLoreanModels["bttf2"]
		else
			local testVehicleModel = getVehicleModelFromName(vehicleModel)
			if testVehicleModel then
				vehicleModel = testVehicleModel
			end
		end
		vehicleModel = tonumber(vehicleModel)
		if not vehicleModel then
			outputChatBox("You either need to specify a vehicle name or its ID.", thePlayer)
			return
		end
		if table.contains(prohibitedVehicles, vehicleModel) then
		    outputChatBox("You're not allowed to spawn a " .. getVehicleNameFromModel(vehicleModel) .. ".", thePlayer)
		    return
	    end
		local posX, posY, posZ = getElementPosition(thePlayer)
		local rotX, rotY, rotZ = getElementRotation(thePlayer)
		local vehicle = createVehicle(vehicleModel, posX, posY, posZ, rotX, rotY, rotZ)
		if not vehicle then
		    outputChatBox("Failed to create vehicle.", thePlayer)
		    return
	    end
		createBlipAttachedTo(vehicle, 0, 2, 192, 192, 192, 255, -1, 99999.0, getRootElement())
		setElementDimension(vehicle, getElementDimension(thePlayer))
		warpPedIntoVehicle(thePlayer, vehicle)
		local vehicleType = getVehicleType(vehicle)
		if (vehicleType == "Automobile") or (vehicleType == "Bike") or (vehicleType == "Monster Truck") or (vehicleType == "Quad") then
			setVehicleEngineState(vehicle, false)
		end
		if (vehicleModel == DeLoreanModels["bttf2"] or vehicleModel == DeLoreanModels["bttf2flying"]) then
			timeTravel(vehicle, 10000)
			setElementData(vehicle, "tcstate", false)
			setElementData(vehicle, "destinationTime", 3, true)
			setVehicleColor(vehicle, 13, 24, 0, 0)
		end
		lastCarSpawn[thePlayer] = getTickCount()
	end
end

function handleCarCommand(thePlayer, command, argument)
    createVehicleForPlayer(thePlayer, argument)
end
addCommandHandler("car", handleCarCommand)

addEvent("spawnVehicle", true)
function handleSpawnVehicleEvent(argument)
    createVehicleForPlayer(client, argument)    
end
addEventHandler("spawnVehicle", root, handleSpawnVehicleEvent)

function removeHoverWheelsAndBlipOnVehicle()
	local attachedElements = getAttachedElements(source)
	if attachedElements then
		for ElementKey, ElementValue in ipairs(attachedElements) do
			if (getElementModel(ElementValue) == 3890) then -- d_strut_l
				destroyElement(ElementValue)
			elseif (getElementModel(ElementValue) == 3891) then -- d_strut_r
				destroyElement(ElementValue)
			elseif (getElementModel(ElementValue) == 3892) then -- d_wheel_l
				destroyElement(ElementValue)
			elseif (getElementModel(ElementValue) == 3893) then -- d_wheel_r
				destroyElement(ElementValue)
			elseif (getElementModel(ElementValue) == 3894) then -- d_coil_lit
				destroyElement(ElementValue)
			elseif (getElementModel(ElementValue) == 3895) then -- d_green
				destroyElement(ElementValue)
			elseif (getElementModel(ElementValue) == 3896) then -- d_wheel_g
				destroyElement(ElementValue)
			elseif (getElementType(ElementValue) == "blip") then
				destroyElement(ElementValue)
			end
		end
	end
	setTimer(despawnVehicle, 60000, 1, source)
end
addEventHandler("onVehicleExplode", getRootElement(), removeHoverWheelsAndBlipOnVehicle)

function despawnVehicle(theVehicle)
	if isElement(theVehicle) then
		if not getVehicleOccupant(theVehicle, 0) and not getVehicleOccupant(theVehicle, 1) then
			local attachedElements = getAttachedElements(theVehicle)
			if attachedElements then
				for ElementKey, ElementValue in ipairs(attachedElements) do
					if (getElementType(ElementValue) == "blip") then
						destroyElement(ElementValue)
					end
				end
			end
			destroyElement(theVehicle)
		end
	end
end

vehicleDespawnTimer = {}
function setVehicleDespawnTimer(thePlayer, seat, jacker)
	vehicleDespawnTimer[source] = setTimer(despawnVehicle, 15 * 60 * 1000, 1, source)
end
addEventHandler("onVehicleExit", getRootElement(), setVehicleDespawnTimer)

function setVehicleDespawnTimerOnPlayerQuit(quitType, reason, responsibleElement)
	local vehicle = getPedOccupiedVehicle(source)
	if vehicle then
		for i = 0, getVehicleMaxPassengers(vehicle) do
			local occupant getVehicleOccupant(vehicle, i)
			if occupant then
				if (occupant ~= source) then
					return -- don't despawn it
				end
			end
		end
		vehicleDespawnTimer[vehicle] = setTimer(despawnVehicle, 15 * 60 * 1000, 1, vehicle)
	end
end
addEventHandler("onPlayerQuit", getRootElement(), setVehicleDespawnTimerOnPlayerQuit)

function killVehicleDespawnTimer(thePlayer, seat, jacked)
	if isTimer(vehicleDespawnTimer[source]) then
		killTimer(vehicleDespawnTimer[source])
	end
end
addEventHandler("onVehicleEnter", getRootElement(), killVehicleDespawnTimer)

addEvent("onVehicleEngineStateToggle", true)
function toggleEngine(keyPresser, key, keyState)
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if playerCar and (getPedOccupiedVehicleSeat(keyPresser) == 0) and not exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		local vehicleType = getVehicleType(playerCar)
		if (vehicleType == "Automobile") or (vehicleType == "Bike") or (vehicleType == "Monster Truck") or (vehicleType == "Quad") then
			local engineState = getVehicleEngineState(playerCar)
			if engineState then
				engineState = false
			else
				engineState = true
			end
			triggerEvent("onVehicleEngineStateToggle", playerCar, engineState, keyPresser)
			triggerClientEvent(getRootElement(), "onVehicleEngineStateToggle", playerCar, engineState, keyPresser)
			setVehicleEngineState(playerCar, engineState)
		end
	end
end

function toggleLights(keyPresser, key, keyState)
	local playerCar = getPedOccupiedVehicle(keyPresser)
	local vehicleModel = getElementModel(playerCar)
	if playerCar and (getPedOccupiedVehicleSeat(keyPresser) == 0) and not exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		local lights = getVehicleOverrideLights(playerCar) + 1
		if (lights > 2) then
			lights = 0
		end
		setVehicleOverrideLights(playerCar, lights)
	end
end