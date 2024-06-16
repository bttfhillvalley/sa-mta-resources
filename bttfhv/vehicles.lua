------------------------------
--	Script wide used variables
------------------------------

-- define a list of vehicles that are prohibited to be spawned by this script
g_prohibitedVehicles = {
	425, -- Hunter
	432, -- Rhino
	441, -- RC Bandit
	464, -- RC Baron
	465, -- RC Raider
	501, -- RC Goblin
	520, -- Hydra
	564, -- RC Tiger
	594, -- RC Cam (flower pot)
}

-- We don't want the player to be able to spawn new vehicles continously.
-- They should rather wait half a minute between every vehicle spawn.
-- This variable holds a list of timestampts when each player last spawned a vehicle.
g_lastCarSpawn = {}

-- We want to despawn cars 15 minutes after they have been left.
-- In order to track how much time has passed since a player had been driving a vehicle
-- create a list that contains a timer for each car. Once the timer experies the car will
-- be despawned. If a car is entered again, its timer will be aborted.
g_vehicleDespawnTimer = {}

------------------------------
--	Functionality
------------------------------

function createVehicleForPlayer(thePlayer, vehicleModel)
	-- if our list of timestamps doesn't contain one for this player initialize it with 0
	if not g_lastCarSpawn[thePlayer] then
		g_lastCarSpawn[thePlayer] = 0
	end

	-- abort if the player is already driving, they aren't outside or are dead
	if getPedOccupiedVehicle(thePlayer) or getElementInterior(thePlayer) ~= 0 or isPedDead(thePlayer) then
		return
	end
	
	-- calculate the time that has passed since they last spawned a vehicle.
	-- if it's less than 30 seconds, tell them howe long they still have to wait.
	local spawnCooldown = (getTickCount() - g_lastCarSpawn[thePlayer]) / 1000
	if not (spawnCooldown >= 30) then
		outputChatBox(string.format("You have to wait an other %2i seconds before you can spawn a new vehicle.", 30 - spawnCooldown), thePlayer, 255, 0, 0)
		return
	end

	-- if they didn't pass a vehicle ID as argument to the command, show them the selection UI
	if vehicleModel == nil then
		triggerClientEvent(thePlayer, "showVehicleSpawnGui", thePlayer)
		return
	end

	-- if they passed the string "delorean" as argument replace that with its id
	-- otherwise get the stock vehicle's id from its name
	if (vehicleModel == "delorean") then
		vehicleModel = g_deloreanModels["bttf2"]
	else
		-- see if we can find the vehicle by the name given by the player
		local testVehicleModel = getVehicleModelFromName(vehicleModel)
		if testVehicleModel then
			vehicleModel = testVehicleModel
		end
	end

	-- verify we got a correct vehicle id
	vehicleModel = tonumber(vehicleModel)
	if not vehicleModel then
		outputChatBox("You either need to specify a vehicle name or its ID.", thePlayer)
		return
	end

	-- check if the vehicle is prohibited
	if table.contains(g_prohibitedVehicles, vehicleModel) then
		outputChatBox("You're not allowed to spawn a " .. getVehicleNameFromModel(vehicleModel) .. ".", thePlayer)
		return
	end

	-- spawn the vehicle in the player's current position with their orientation, attach a map blip to it and seat them into it
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

	-- depending on the vehicle type, turn off the engine. The player can manually start the ignition with I
	local vehicleType = getVehicleType(vehicle)
	if (vehicleType == "Automobile") or (vehicleType == "Bike") or (vehicleType == "Monster Truck") or (vehicleType == "Quad") then
		setVehicleEngineState(vehicle, false)
	end

	-- on time machines preset their variables for the time travel code
	if (vehicleModel == g_deloreanModels["bttf2"] or vehicleModel == g_deloreanModels["bttf2flying"]) then
		timeTravel(vehicle, 10000)
		setElementData(vehicle, "tcstate", false)
		setElementData(vehicle, "destinationTime", 3, true)
		setVehicleColor(vehicle, 13, 24, 0, 0)
	end

	-- remember when they last spawned a vehicle for the cooldown
	g_lastCarSpawn[thePlayer] = getTickCount()
end

-- when the player enters the command /car, spawn the respective vehicle for them
function handleCarCommand(thePlayer, command, argument)
    createVehicleForPlayer(thePlayer, argument)
end
addCommandHandler("car", handleCarCommand)

-- when the client selected a vehicle from the ui, spawn it for them
addEvent("spawnVehicle", true)
function handleSpawnVehicleEvent(argument)
    createVehicleForPlayer(client, argument)    
end
addEventHandler("spawnVehicle", root, handleSpawnVehicleEvent)

-- when a DeLorean explodes, remove their attached components
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

	-- despawn the vehilce 60 seconds after the explosion
	setTimer(despawnVehicle, 60000, 1, source)
end
addEventHandler("onVehicleExplode", getRootElement(), removeHoverWheelsAndBlipOnVehicle)

-- to despawn the vehicle first remove the map blip attached to it
function despawnVehicle(theVehicle)
	-- is arg1 an mta element?
	if not isElement(theVehicle) then
		return
	end

	-- is someone still sitting in the vehicle?
	if getVehicleOccupant(theVehicle, 0) or getVehicleOccupant(theVehicle, 1) then
		return
	end
	
	-- look for a map blip attached to the vehicle and destroy it
	local attachedElements = getAttachedElements(theVehicle)
	if attachedElements then
		for ElementKey, ElementValue in ipairs(attachedElements) do
			if (getElementType(ElementValue) == "blip") then
				destroyElement(ElementValue)
			end
		end
	end

	-- now destroy the vehicle
	destroyElement(theVehicle)
end

-- start a 15 minutes timer when a vehicle is being left
function setVehicleDespawnTimer(thePlayer, seat, jacker)
	g_vehicleDespawnTimer[source] = setTimer(despawnVehicle, 15 * 60 * 1000, 1, source)
end
addEventHandler("onVehicleExit", getRootElement(), setVehicleDespawnTimer)

-- start a 15 minutes timer when a player leaves the game while driving a vehicle
function setVehicleDespawnTimerOnPlayerQuit(quitType, reason, responsibleElement)
	local vehicle = getPedOccupiedVehicle(source)
	if not vehicle then
		return
	end

	-- check if there's any other passengers in any seat of the vehicle
	for i = 0, getVehicleMaxPassengers(vehicle) do
		local occupant getVehicleOccupant(vehicle, i)
		if occupant then
			if (occupant ~= source) then
				-- don't despawn the vehicle
				return 
			end
		end
	end
	
	-- start the despawn timer
	g_vehicleDespawnTimer[vehicle] = setTimer(despawnVehicle, 15 * 60 * 1000, 1, vehicle)
end
addEventHandler("onPlayerQuit", getRootElement(), setVehicleDespawnTimerOnPlayerQuit)

-- stop the vehicle despawn timer if a player enters it
function killVehicleDespawnTimer(thePlayer, seat, jacked)
	if isTimer(g_vehicleDespawnTimer[source]) then
		killTimer(g_vehicleDespawnTimer[source])
	end
end
addEventHandler("onVehicleEnter", getRootElement(), killVehicleDespawnTimer)

-- bind a button to toggle the engine's state
addEvent("onVehicleEngineStateToggle", true)
function toggleEngine(keyPresser, key, keyState)
	-- if the player is not in the driver's seat of a car or they're remote controlling the car
	-- they're not supposed to be able to toggle its engine state
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if not playerCar or getPedOccupiedVehicleSeat(keyPresser) ~= 0 or exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		return 
	end

	-- ensure the player is driving a ground vehicle
	local vehicleType = getVehicleType(playerCar)
	if vehicleType ~= "Automobile" and vehicleType ~= "Bike" and vehicleType ~= "Monster Truck" and vehicleType ~= "Quad" then
		return
	end
	
	-- invert the current engine state of the vehicle
	local engineState = not getVehicleEngineState(playerCar)
	setVehicleEngineState(playerCar, engineState)
	
	-- inform other scripts on the server and client of the engine state change so they i.e. can play sound effects
	triggerEvent("onVehicleEngineStateToggle", playerCar, engineState, keyPresser)
	triggerClientEvent(getRootElement(), "onVehicleEngineStateToggle", playerCar, engineState, keyPresser)
end

-- bind a button to toggle the vehicle's lights
function toggleLights(keyPresser, key, keyState)
	-- if the player is not in the driver's seat of a car or they're remote controlling the car
	-- they're not supposed to be able to toggle its lights
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if not playerCar or getPedOccupiedVehicleSeat(keyPresser) ~= 0 or exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		return
	end

	-- the lights can have three states:
	--   0 = default
	--   1 = force off
	--   2 = force on
	-- toggle through all of these
	local lights = getVehicleOverrideLights(playerCar) + 1
	if (lights > 2) then
		lights = 0
	end
	setVehicleOverrideLights(playerCar, lights)
end