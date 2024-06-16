------------------------------
-- Script wide used variables
------------------------------

-- configure which stock SA models the two DeLorean variants replace
g_deloreanModels = {
	bttf2 = 541,
	bttf2flying = 488,
}

-- create a list to store a timer for each car
-- the timer will run the time travel code every 100ms
g_timeTravelTimers = {}

-- create a list to remember when each player last time travelled
-- in order to put a 10s cooldown on time travelling
g_lastTimeTravel = {}

-- create a list to remember which cars were boosted from the rear vents
g_boostedCars = {}

-- creata a list to remember which vehicles are currently hover converting
g_isVehicleHoverConversionActive = {}

-- remember the last few number buttons each player pressed for the time circuit input
g_keyBuffer = {}

-- remember the last DeLorean that each player drove
g_lastDeloreanDriven = {}

------------------------------
--	Functionality
------------------------------

-- allows the server to call any function on the client (rather than just trigger events)
-- see https://wiki.multitheftauto.com/wiki/CallClientFunction
function callClientFunction(client, funcname, ...)
	local arg = { ... }
	if (arg[1]) then
		for key, value in next, arg do
			if (type(value) == "number") then arg[key] = tostring(value) end
		end
	end
	-- If the clientside event handler is not in the same resource, replace 'resourceRoot' with the appropriate element
	triggerClientEvent(client, "onServerCallsClientFunction", resourceRoot, funcname, unpack(arg or {}))
end

-- helper function to check whether a table contains an element
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

-- convert the dimension number into a text to display on the scoreboard
-- this will be attached to the player element so that it can easily be 
-- accessed from another resource
function getEraText(dimension)
	local eras = {
		"SEP 02 1885 08:00",
		"NOV 12 1955 22:04",
		"OCT 26 1985 01:24",
		"OCT 21 2015 16:29",
	}
	
	-- prevent array out of bounds error
	if (dimension > -1) and (dimension + 1 <= #eras) then
		return eras[dimension + 1]
	end

	-- the era is invalid, so just return ERR
	return "ERR"
end

-- check if 10 seconds have passed since the vehicle occupant last time travelled
function isVehicleOccupantInSeatReadyForTimetravel(vehicle, seat)
	-- check if somebody is sitting in this seat that has a cooldown active
	local occupant = getVehicleOccupant(vehicle, seat)
	if not occupant or not g_lastTimeTravel[occupant] then
		-- either there is no player in this seat or they haven't timetravelled at all yet
		return true
	end

	-- have 10 seconds passed since they last time travelled?
	return getTickCount() - g_lastTimeTravel[occupant] > 10000
end

-- main time travel logic
function timeTravel(playerCar, cooldown)
	-- is the playerCar a valid MTA element?
	if not isElement(playerCar) then
		return
	end

	-- get the car's speed in game units and calculate an mph value
	-- use pythagorean theorem to get actual velocity taking all directions into account and multiply to get miles per hour
	local speedX, speedY, speedZ = getElementVelocity(playerCar)
	local mph = ((speedX^2 + speedY^2 + speedZ^2)^(0.5)) * 111.847

	-- have 10 seconds passed since the time machine last time travelled and are the passengers in both seats also ready for time travel?
	if (cooldown >= 10000) and getElementData(playerCar, "tcstate") and isVehicleOccupantInSeatReadyForTimetravel(playerCar, 0) and isVehicleOccupantInSeatReadyForTimetravel(playerCar, 1) then
		-- above 80 mph add glowing coils to the car
		if (mph >= 80) then
			-- check if we already have glowing coils attached
			local d_coil_lit
			local attachedElements = getAttachedElements(playerCar)
			for elementKey, elementValue in ipairs(attachedElements) do
				if isElement(elementValue) then
					if (getElementModel(elementValue) == 3894) then -- d_coil_lit
						d_coil_lit = elementValue
					end
				end
			end

			-- if we don't, create and attached them
			if not isElement(d_coil_lit) then
				local posX, posY, posZ = getElementPosition(playerCar)
				local d_coil_lit = createObject(3894, posX, posY, posZ)
				if isElement(d_coil_lit) then
					setElementDimension(d_coil_lit, getElementDimension(playerCar))
					attachElements(d_coil_lit, playerCar, 0.0, 0.0, 0.0)

					-- trigger that the coils started glowing on the client so that it can play a sound effect
					triggerClientEvent(getRootElement(), "onClientCoilsStart", d_coil_lit)
				end
			end
		else 
			-- below 80 mph remove the glowing coils
			local attachedElements = getAttachedElements(playerCar)
			for elementKey, elementValue in ipairs(attachedElements) do
				if isElement(elementValue) then
					if (getElementModel(elementValue) == 3894) then -- d_coil_lit
						-- signal the client to stop the sound effect
						triggerClientEvent(getRootElement(), "onClientCoilsStop", elementValue)
						destroyElement(elementValue)
					end
				end
			end
		end
		-- above 82 mph add sparks at the wheels
		if (mph >= 82) then
			-- do sparks already exist?
			local sparks
			local attachedElements = getAttachedElements(playerCar)
			for elementKey, elementValue in ipairs(attachedElements) do
				if isElement(elementValue) then
					if (getElementModel(elementValue) == 3900) then -- particle_prt_spark
						sparks = elementValue
					end
				end
			end

			-- add the sparks if they don't
			if not isElement(sparks) then
				createSparks(playerCar)
			end
		else
			-- below 82 mph remove the spark and fire effects on the wheels
			local attachedElements = getAttachedElements(playerCar)
			for elementKey, elementValue in ipairs(attachedElements) do
				if isElement(elementValue) then
					if(getElementModel(elementValue) == 3900) --[[ particle_prt_spark ]] or
						(getElementModel(elementValue) == 3899) --[[ particle_fire ]] then
						destroyElement(elementValue)
					end
				end
			end
		end
		-- above 88 mph travel the car to the destination time if its MrFusion fuel chamber is full
		if (mph >= 88) and getElementData(playerCar, "fueled") then
			-- set the last time departed as the one we're still in
			setElementData(playerCar, "lastTime", getElementDimension(playerCar) + 1, true)
			
			-- set that the car needs to cool down before travelling again
			setElementData(playerCar, "cooleddown", false, true)

			-- use the fuel in MrFusion's fuel chamber
			setElementData(playerCar, "fueled", false, true)

			-- get the destination time from the time circuits
			local dimension = getElementData(playerCar, "destinationTime") - 1

			-- go through all passengers in the car, play the sound effect, update their dimension, etc.
			for i = 0, getVehicleMaxPassengers(playerCar), 1 do
				local passenger = getVehicleOccupant(playerCar, i) -- not using an array here, we are safe to overwrite the variable since we don't need it these commands
				if passenger then
					-- if the player is remote controlling the car he is in himself or not remote controlling at all
					if (isElement(exports["RcMode"]:getPlayerRcDummy(passenger)) and (getPedOccupiedVehicle(passenger) == getPedOccupiedVehicle(exports["RcMode"]:getPlayerRcDummy(passenger)))) or not exports["RcMode"]:isPlayerInRcMode(passenger) then
						-- play the time travel sound flash the screen white and set the new dimension on the player
						callClientFunction(passenger, "playSound", "sounds/time_travel-instant.mp3")
						fadeCamera(passenger, false, .1, 255, 255, 255)
						setElementDimension(passenger, dimension)

						-- attach text for present time to the player element for outputting on the scoreboard
						setElementData(passenger, "PRESENT TIME", getEraText(dimension))

						-- fade the camera back to normal after a few milliseconds
						setTimer(fadeCamera, 125, 1, passenger, true, .1)

						-- remember when we last time travelled
						g_lastTimeTravel[passenger] = getTickCount()

						-- trigger the animation on the client to indicate MrFusion's fuel chamber is empty
						triggerClientEvent(passenger, "plutoniumEmpty", passenger, playerCar)
					else
						-- exit rc mode
						exports["RcMode"]:exitRcMode(passenger)
					end
				end
			end

			-- play the effects for a leaving and entering time machine on the clients
			local posX, posY, posZ = getElementPosition(playerCar)
			triggerClientEvent(getRootElement(), "onClientTimemachineLeaves", playerCar, posX, posY, posZ, getElementDimension(playerCar))
			triggerClientEvent(getRootElement(), "onClientTimemachineEnters", playerCar, posX, posY, posZ, dimension)

			-- move the car and it's attachments to the correct dimension
			setElementDimension(playerCar, dimension)
			local attachedElements = getAttachedElements(playerCar)
			if attachedElements then
				for elementKey, elementValue in ipairs(attachedElements) do
					if isElement(elementValue) then
						if (getElementType(elementValue) == "object") then
							if(getElementModel(elementValue) == 3890) --[[ d_strut_l ]] or 
								(getElementModel(elementValue) == 3891) --[[ d_strut_r ]] or 
								(getElementModel(elementValue) == 3892) --[[ d_wheel_l ]] or 
								(getElementModel(elementValue) == 3893) --[[ d_wheel_r ]] or
								(getElementModel(elementValue) == 3900) --[[ particle_prt_spark ]] or
								(getElementModel(elementValue) == 3899) --[[ particle_fire ]] then
								setElementDimension(elementValue, dimension)
							elseif (getElementModel(elementValue) == 3894) then -- d_coil_lit
								triggerClientEvent(getRootElement(), "onClientCoilsStop", elementValue)
								setElementDimension(elementValue, dimension)
							end
						end
					end
				end
			end

			-- set a timer to play the vent steam release animation on the car
			setTimer(createVentSteam, 6000, 1, playerCar)
			cooldown = 0
		else
			setElementData(playerCar, "cooleddown", true, true)
			cooldown = 10000
		end
	else
		-- as per Mike's request, leave the coil glow intact for three seconds after a timetravel
		-- if 2.5 seconds hae passed or the car's speed drops below 80 mph remove the lit coils
		if (cooldown >= 2500) or (mph < 80) then
			local attachedElements = getAttachedElements(playerCar)
			for elementKey, elementValue in ipairs(attachedElements) do
				if isElement(elementValue) then
					if (getElementType(elementValue) == "object") then
						if (getElementModel(elementValue) == 3894) then -- d_coil_lit
							destroyElement(elementValue)
						end
					end
				end
			end
		end
		-- if (mph < 80) then
			-- remove the wheel effects immediately
			local attachedElements = getAttachedElements(playerCar)
			for elementKey, elementValue in ipairs(attachedElements) do
				if isElement(elementValue) then
					if(getElementModel(elementValue) == 3900) --[[ particle_prt_spark ]] or
						(getElementModel(elementValue) == 3899) --[[ particle_fire ]] then
						destroyElement(elementValue)
					end
				end
			end
		-- end
	end

	-- rerun this function in 100msecs and remember how long we've been running it for
	g_timeTravelTimers[playerCar] = setTimer(timeTravel, 100, 1, playerCar, cooldown + 100)
end

-- attach the models that have the spark and fire effects in them to the car
function createSparks(playerCar)
	if isElement(playerCar) then
		-- create the spark objects near the car to have the game stream them in
		local posX, posY, posZ = getElementPosition(playerCar)
		local dimension = getElementDimension(playerCar)
		local sparks =	{
			-- order: front left, front right, back left, back right
			[1] = createObject(3900, posX, posY, posZ),
			[2] = createObject(3900, posX, posY, posZ),
			[3] = createObject(3900, posX, posY, posZ),
			[4] = createObject(3900, posX, posY, posZ),
		}
		setElementDimension(sparks[1], dimension)
		setElementDimension(sparks[2], dimension)
		setElementDimension(sparks[3], dimension)
		setElementDimension(sparks[4], dimension)
		-- attach them with offsets so they're at the wheels and they follow it
		attachElements(sparks[1], playerCar, -.91, 1.11, -.39, 0, 222, 85)
		attachElements(sparks[2], playerCar, .91, 1.11, -.39, 0, 222, 85)
		attachElements(sparks[3], playerCar, -.96, -1.66, -.29, 0, 222, 85)
		attachElements(sparks[4], playerCar, .96, -1.66, -.29, 0, 222, 85)

		-- create the fire objects near the car to have the game stream them
		local fire = {	
			--order: front left, front right, back left, back right
			[1] = createObject(3899, posX, posY, posZ),
			[2] = createObject(3899, posX, posY, posZ),
			[3] = createObject(3899, posX, posY, posZ),
			[4] = createObject(3899, posX, posY, posZ),
		}
		setElementDimension(fire[1], dimension)
		setElementDimension(fire[2], dimension)
		setElementDimension(fire[3], dimension)
		setElementDimension(fire[4], dimension)
		-- attach them with offsets so they're at the wheels and they follow it
		attachElements(fire[1], playerCar, -.91, 1.11, -.39, 315, 0, 0)
		attachElements(fire[2], playerCar, .91, 1.11, -.39, 315, 0, 0)
		attachElements(fire[3], playerCar, -.96, -1.66, -.29, 315, 0, 0)
		attachElements(fire[4], playerCar, .96, -1.66, -.29, 315, 0, 0)
	end
end

-- attach the models that have steam particles in them for the vent steam release effect to the car
function createVentSteam(playerCar)
	if isElement(playerCar) then
		-- create the steam objects near the car to have the game stream them in
		local posX, posY, posZ = getElementPosition(playerCar)
		local dimension = getElementDimension(playerCar)
		local ventSteam = {
			-- 1 = left, 2 = right
			[1] = createObject(3897, posX, posY, posZ),
			[2] = createObject(3897, posX, posY, posZ),
		}
		setElementDimension(ventSteam[1], dimension)
		setElementDimension(ventSteam[2], dimension)
		-- attach them with offsets so they're at the rear vents and follow the car
		attachElements(ventSteam[1], playerCar, -.4, -2, .3, 15, 0, 180)
		attachElements(ventSteam[2], playerCar, .4, -2, .3, 15, 0, 180)

		-- trigger the client to play the sound effect
		triggerClientEvent(getRootElement(), "ventSteam", playerCar)

		-- set a timer to destroy the steam models after 5 seconds
		setTimer(destroyVentSteam, 5000, 1, playerCar, ventSteam)
	end
end

-- destroy the steam effect models
function destroyVentSteam(playerCar, ventSteam)
	for i = 1, #ventSteam do
		if isElement(ventSteam[i]) then
			destroyElement(ventSteam[i])
		end
	end
end

-- when the player presses the boost button and they're in the flying DeLorean change the vents' inner color
function toggleVentBoost(keyPresser, key, keyState)
	-- is the player driving a car?
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if not playerCar then
		return
	end

	-- are they flying a DeLorean?
	if getElementModel(playerCar) ~= g_deloreanModels["bttf2flying"] then
		return
	end

	-- make the vents glow when the button is held down,
	-- reset them when the button is released
	if(keyState == "down") then
		setVehicleColor(playerCar, 6, 6, 0, 0)
		g_boostedCars[playerCar] = true
	else
		setVehicleColor(playerCar, 13, 24, 0, 0)
		g_boostedCars[playerCar] = false
	end
end

-- keep increasing the car's forward momentum while the button is being held down
function boostloop(vehicle)
	-- if the vehicle no longer exists or is blown exit the loop
	if not isElement(vehicle) or isVehicleBlown(vehicle) then
		return
	end

	-- if the vehicle is no longer the flying DeLorean, exit the loop
	if getElementModel(vehicle) ~= g_deloreanModels["bttf2flying"] then
		return
	end

	if g_boostedCars[vehicle] then
		ventBoost(vehicle)
	end
	setTimer(boostloop, 100, 1, vehicle)
end

-- apply the momentum boost
function ventBoost(vehicle)
	-- use pythagorean theorem to get actual velocity taking all directions into account
	local speedX, speedY, speedZ = getElementVelocity(vehicle)
	local actualSpeed = ((speedX^2 + speedY^2 + speedZ^2)^(0.5))
	local boostAmount -- = 0.05
	
	-- use a logarithmic curve to increase the car's speed if it's moving
	-- or give it a little starting momentum
	if not (actualSpeed == 0) then
		boostAmount = math.log10(actualSpeed) * -.085
	else
		boostAmount = 0.01
	end

	-- change momentum on all axes
	local rotX, rotY, rotZ = getElementRotation(vehicle)
	local boostX = math.cos(math.rad(90-(360 - rotZ))) * boostAmount
	local boostY = math.sin(math.rad(90-(360 - rotZ))) * boostAmount
	local boostZ = math.sin(math.rad(rotX)) * boostAmount * 1.5
 	setElementVelocity(vehicle, speedX + boostX, speedY + boostY, speedZ + boostZ)
end

-- hover convert the player's car:
--   * if they're in the driving model, swap it with the flying model or vice versa
--   * attach or remove the hover wheels, struts and blinking lights on the bottom of the car
--   * play a rotation and movement animation on the wheels
function hoverConvertPlayerCar(keyPresser, key, keyState)
	local playerCar = getPedOccupiedVehicle(keyPresser)
	-- abort if the player isn't in the driver's seat of a car or the car is already converting
	if not playerCar or getPedOccupiedVehicleSeat(keyPresser) ~= 0 or g_isVehicleHoverConversionActive[playerCar] then
		return
	end

	-- set that the car is being hover converted and get the vehicle's model
	g_isVehicleHoverConversionActive[playerCar] = true
	local vehicleModel = getElementModel(playerCar)
	
	-- is the player in the flying DeLorean? Fold the wheels in
	if (vehicleModel == g_deloreanModels["bttf2flying"]) then
		-- trigger the event on the client to play the sound effect
		triggerClientEvent(getRootElement(), "hoverConvert", playerCar, getVehicleOccupant(playerCar, 0))

		-- get the wheel and strut models atttached to the car
		local d_strut_l
		local d_strut_r
		local d_wheel_l
		local d_wheel_r
		local attachedElements = getAttachedElements(playerCar)
		if attachedElements then
			for elementKey, elementValue in ipairs(attachedElements) do
				if (getElementType(elementValue) == "object") then
					if (getElementModel(elementValue) == 3890) then
						d_strut_l = elementValue
					elseif (getElementModel(elementValue) == 3891) then
						d_strut_r = elementValue
					elseif (getElementModel(elementValue) == 3892) then
						d_wheel_l = elementValue
					elseif (getElementModel(elementValue) == 3893) then
						d_wheel_r = elementValue
					elseif (getElementModel(elementValue) == 3895) then -- d_green
						detachElements(elementValue, playerCar)
						destroyElement(elementValue)
					elseif (getElementModel(elementValue) == 3896) then -- d_wheel_g
						detachElements(elementValue, playerCar)
						destroyElement(elementValue)
					end
				end
			end

			-- play the animation on the wheels and struts
			wheelAnimation(playerCar, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, g_deloreanModels["bttf2"], 1.15, 90)
		end

	-- is the player in the driving DeLorean? Fold the wheels out
	elseif (vehicleModel == g_deloreanModels["bttf2"]) then
		-- first, swap the model to remove the wheels on the driving model
		changeVehicleModel(playerCar, g_deloreanModels["bttf2flying"])

		-- trigger the event on the client to play the sound effect
		triggerClientEvent(getRootElement(), "hoverConvert", playerCar, getVehicleOccupant(playerCar, 0))

		-- create the wheel and strut models and attach them to the car
		local dimension = getElementDimension(playerCar)
		local d_strut_l = createObject(3890, 0.0, 0.0, 0.0)
		setElementDimension(d_strut_l, dimension)
		attachElements(d_strut_l, playerCar, -0.85, 0.0, -0.3, 0.0, 0.0, 0.0)
		local d_strut_r = createObject(3891, 0.0, 0.0, 0.0)
		setElementDimension(d_strut_r, dimension)
		attachElements(d_strut_r, playerCar, 0.85, 0.0, -0.3, 0.0, 0.0, 0.0)
		local d_wheel_l = createObject(3892, 0.0, 0.0, 0.0)
		setElementDimension(d_wheel_l, dimension)
		attachElements(d_wheel_l, playerCar, -0.85, 0.0, -0.3, 0.0, 0.0, 0.0)
		local d_wheel_r = createObject(3893, 0.0, 0.0, 0.0)
		setElementDimension(d_wheel_r, dimension)
		attachElements(d_wheel_r, playerCar, 0.85, 0.0, -0.3, 0.0, 0.0, 0.0)

		-- play the animation on the wheels and struts
		wheelAnimation(playerCar, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, g_deloreanModels["bttf2flying"], 0.85, 0.0)

		-- create the little green light at the bottom of the car
		local d_green = createObject(3895, 0.0, 0.0, 0.0)
		setElementDimension(d_green, dimension)
		attachElements(d_green, playerCar, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

		-- animate the green light
		greenLightAnimation(playerCar, d_green, 0.0)

		-- initiate the boost loop for the flying DeLorean
		boostloop(playerCar)
	end
end

-- animate the wheels and struts until the end position has been reached
function wheelAnimation(theVehicle, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, targetModel, xPosOffset, yRotOffset)
	local animationComplete = false

	-- Flying: fold the wheels out
	if (targetModel == g_deloreanModels["bttf2flying"]) then
		-- first keep moving the wheels until they reach their end position
		if (xPosOffset < 1.15) then
			xPosOffset = xPosOffset + 0.03 -- 0.02
		-- elseif (yRotOffset < 1.55) then
			-- yRotOffset = yRotOffset + 0.07 -- 0.05
		-- then keep rotating the wheels until they reach their end position
		elseif (yRotOffset < 90) then
			yRotOffset = yRotOffset + 8.5 -- 0.05
		else
			-- the animation is done. Attach the glowing wheel covers
			local d_wheel_g = createObject(3896, 0.0, 0.0, 0.0)
			setElementDimension(d_wheel_g, getElementDimension(theVehicle))
			attachElements(d_wheel_g, theVehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
			animationComplete = true
		end
	
	-- Driving: fold the wheels in
	else
		-- first keep rotating the wheels until they reach their end position
		-- if (yRotOffset > 0.0) then
			-- yRotOffset = yRotOffset - 0.07 -- 0.05
		if (yRotOffset > 0.0) then
			yRotOffset = yRotOffset - 8.5 -- 0.05
		-- then keep rotating the wheels until they reach their end position
		elseif (xPosOffset > 0.85) then
			xPosOffset = xPosOffset - 0.03 -- 0.02
		else
			-- the animation is done
			animationComplete = true
		end

		-- remove the animation models and switch the car to the driving model
		if animationComplete then
			detachElements(d_strut_l, theVehicle)
			destroyElement(d_strut_l)
			detachElements(d_strut_r, theVehicle)
			destroyElement(d_strut_r)
			detachElements(d_wheel_l, theVehicle)
			destroyElement(d_wheel_l)
			detachElements(d_wheel_r, theVehicle)
			destroyElement(d_wheel_r)
			changeVehicleModel(theVehicle, targetModel)
			
			-- reset the vent color
			if g_boostedCars[theVehicle] then
				g_boostedCars[theVehicle] = false
				setVehicleColor(theVehicle, 13, 24, 0, 0)
			end
		end
	end

	-- if the animation isn't complete yet, apply the new position and rotation values
	if not animationComplete and isElement(theVehicle) and isElement(d_strut_l) and isElement(d_strut_r) and isElement(d_wheel_l) and isElement(d_wheel_r) then
		setElementAttachedOffsets(d_strut_l, xPosOffset * -1, 0.0, -0.3, 0.0, 0.0, 0.0)
		setElementAttachedOffsets(d_strut_r, xPosOffset, 0.0, -0.3, 0.0, 0.0, 0.0)
		setElementAttachedOffsets(d_wheel_l, xPosOffset * -1, 0.0, -0.3, 0.0, yRotOffset * -1, 0.0)
		setElementAttachedOffsets(d_wheel_r, xPosOffset, 0.0, -0.3, 0.0, yRotOffset, 0.0)

		-- start a timer to apply the next change
		setTimer(wheelAnimation, 50, 1, theVehicle, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, targetModel, xPosOffset, yRotOffset)
	elseif isElement(theVehicle) then
		-- set that the car is no longer being hover converted
		g_isVehicleHoverConversionActive[theVehicle] = false
	end
end

-- change the vehicle model
-- if the vehicle is a helicopter set its rotor speed so that it doesn't drop from the sky like a stone
function changeVehicleModel(theVehicle, targetModel)
	setElementModel(theVehicle, targetModel)
	if (getVehicleType(theVehicle) == "Helicopter") and getVehicleEngineState(theVehicle) then
		for k,v in ipairs({getVehicleOccupant(theVehicle, 0), getVehicleOccupant(theVehicle, 1)}) do
			if v then
				callClientFunction(v, "setHelicopterRotorSpeed", theVehicle, 0.2)
			end
		end
	end
end

-- animate the green light moving between different positions under the car's body
function greenLightAnimation(theVehicle, d_green, yPosOffset)
	-- abort if the green light model has been removed	
	if not isElement(d_green) then
		return
	end
	
	-- destroy the green light model if the vehicle has been removed
	if not isElement(theVehicle) then
		destroyElement(d_green)
		return
	end

	-- keep moving it to the next spot
	-- if it's in the last spot, reset it to the first
	yPosOffset = yPosOffset - 0.1
	if (yPosOffset < -0.4) then
		yPosOffset = 0.0
	end	
	setElementAttachedOffsets(d_green, 0.0, yPosOffset, 0.0, 0.0, 0.0, 0.0)

	-- set a timer to call this function again in 250ms
	setTimer(greenLightAnimation, 250, 1, theVehicle, d_green, yPosOffset)	
end

-- turn the time circuits of the time machine the player is driving on or off
function toggleTimecircuits(keyPresser, key, keyState)
	-- abort if the player isn't driving a car or is in RC mode
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if not playerCar --[[ and (getPedOccupiedVehicleSeat(keyPresser) == 0) ]] or exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		return
	end

	-- check if the player is in a driving or flying DeLorean
	local vehicleModel = getElementModel(playerCar)
	if vehicleModel ~= g_deloreanModels["bttf2"] and vehicleModel ~= g_deloreanModels["bttf2flying"] then
		return
	end

	-- check if the time cuircuits of the car are on or off and pick the correct sound file
	local tcstate = getElementData(playerCar, "tcstate")
	local tcsoundname
	if tcstate then
		tcstate = false
		tcsoundname = "off"
	else
		tcstate = true
		tcsoundname = "on"
	end

	-- set the new state
	setElementData(playerCar, "tcstate", tcstate, true)
	
	-- trigger the client to play a sound effect for the car
	local posX, posY, posZ  = getElementPosition(playerCar)
	triggerClientEvent(getRootElement(), "keypadSound", playerCar, tcsoundname, posX, posY, posZ, getElementDimension(playerCar))

	-- check if MrFusion's fuel chamber is empty and trigger both vehicle's occupants to play the animation if it is
	for k,v in ipairs({keyPresser, getVehicleOccupant(playerCar, 1)}) do
		if v then
			-- callClientFunction(v, "playSound", "sounds/keypad/".. tcsoundname ..".mp3")
			if tcstate then
				if not getElementData(playerCar, "fueled") and getElementData(v, "settings.mrfusionsoundwithtcs") then
					triggerClientEvent(v, "plutoniumEmpty", v, playerCar)
				end
			end
		end
	end
end

-- process keypad input. For this remember the last x keys the player pressed
function keypad(keyPresser, key, keyState)
	-- if the player is driving and not in RC mode
	if not isPedInVehicle(keyPresser) or exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		return
	end

	-- get the vehicle the player is driving and check if its time circuits are turned on
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if getElementData(playerCar, "tcstate") == false then
		return
	end

	-- get the position to play the sound at
	local posX, posY, posZ = getElementPosition(playerCar)

	-- has the player pressed the keys to confirm the input?
	if key == "backspace" or key == "num_sub" then
		-- does the player have a key buffer?
		if not g_keyBuffer[keyPresser] then
			-- trigger the client to play an error sound
			triggerClientEvent(getRootElement(), "keypadSound", playerCar, "off", posX, posY, posZ, getElementDimension(playerCar))
		else
			-- add the numbers together and check if the year is valid
			-- pick the correct dimension for the year
			local destinationTime = g_keyBuffer[keyPresser][1] * 1000 + g_keyBuffer[keyPresser][2] * 100 + g_keyBuffer[keyPresser][3] * 10 + g_keyBuffer[keyPresser][4]
			if (destinationTime == 1885) then
				destinationTime = 1
			elseif (destinationTime == 1955) then
				destinationTime = 2
			elseif (destinationTime == 1985) then
				destinationTime = 3
			elseif (destinationTime == 2015) then
				destinationTime = 4
			else
				-- the year is invalid. Trigger the client to play an error sound
				destinationTime = nil
				triggerClientEvent(getRootElement(), "keypadSound", playerCar, "off", posX, posY, posZ, getElementDimension(playerCar))
			end

			if destinationTime then
				-- set the new destination time and trigger the client to play a confirmation sound
				setElementData(playerCar, "destinationTime", destinationTime, true)
				triggerClientEvent(getRootElement(), "keypadSound", playerCar, "confirm", posX, posY, posZ, getElementDimension(playerCar))
			end
		end
	
	-- the player has pressed a numeric key
	else
		-- cut off the prefix and just take the number
		if string.find(key, "num_") ~= nil then
			key = string.sub(key, 5)
		end

		-- if a key buffer for this player hasn't been set up yet
		if not g_keyBuffer[keyPresser] then
			-- initialize it with the current key
			g_keyBuffer[keyPresser] = {-1, -1, -1, key}
		else
			-- shuffle all keys one position forward and append the current key
			g_keyBuffer[keyPresser][1] = g_keyBuffer[keyPresser][2]
			g_keyBuffer[keyPresser][2] = g_keyBuffer[keyPresser][3]
			g_keyBuffer[keyPresser][3] = g_keyBuffer[keyPresser][4]
			g_keyBuffer[keyPresser][4] = key
		end

		-- trigger the client to play a sound effect for the number
		triggerClientEvent(getRootElement(), "keypadSound", playerCar, key, posX, posY, posZ, getElementDimension(playerCar))
	end
end

-- based on example on http://wiki.multitheftauto.com/wiki/GetElementMatrix  !! Doesn't work, getElementMatrix is only available Client side! !!
--[[function getElementPositionWithOffsets(element, offsetX, offsetY, offsetZ)
	-- Get the matrix
	local matrix = getElementMatrix(element)
	-- Get the transformation of a point 5 units in front of the element
	local relativePosX = offsetX * matrix[1][1] + offsetY * matrix[2][1] + offsetZ * matrix[3][1] + 1 * matrix[4][1]
	local relativePosY = offsetX * matrix[1][2] + offsetY * matrix[2][2] + offsetZ * matrix[3][2] + 1 * matrix[4][2]
	local relativePosZ = offsetX * matrix[1][3] + offsetY * matrix[2][3] + offsetZ * matrix[3][3] + 1 * matrix[4][3]
	--Return the transformed point
	return relativePosX, relativePosY, relativePosZ
end ]]

-- if the player is standing behind the time machine and presses the button for refueling, start playing an animation
function refuelDelorean(keyPresser, key, keyState)
	-- abort if the player hasn't driven a time machine yet, the time machine is already fueld or the player is already playing the animation
	if not isElement(g_lastDeloreanDriven[keyPresser]) or getElementData(g_lastDeloreanDriven[keyPresser], "fueled") or getElementData(keyPresser, "refueling") then
		return
	end
	
	-- get the position near MrFusion behind the car and see if they player is in it
	local posX, posY, behindCarZ = getElementPosition(g_lastDeloreanDriven[keyPresser])
	local rotX, rotY, rotZ = getElementRotation(g_lastDeloreanDriven[keyPresser])
	local radius = 2.7
	local offsetRot = math.rad(rotZ - 90)
	local behindCarX = posX + radius * math.cos(offsetRot)
	local behindCarY = posY + radius * math.sin(offsetRot)
	local playerPosX, playerPosY, playerPosZ = getElementPosition(keyPresser)
	if (getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, behindCarX, behindCarY, behindCarZ) <= 0.75) then
		-- trigger the client to play the sound effect
		triggerClientEvent(getRootElement(), "onClientRefuelsTimemachine", keyPresser, g_lastDeloreanDriven[keyPresser], 1)

		-- lock the player in place and open MrFusion
		toggleAllControls(keyPresser, false)
		setElementData(keyPresser, "refueling", true, true)
		setVehicleDoorOpenRatio(g_lastDeloreanDriven[keyPresser], 1, 1, 250)

		-- start a timer to end the animation
		setTimer(refuelDeloreanStep2, 2900, 1, keyPresser, g_lastDeloreanDriven[keyPresser])
	end
end

-- end the animation by closing MrFusion again and returning controls to the player
function refuelDeloreanStep2(player, vehicle)
	setElementData(vehicle, "fueled", true, true)
	setElementData(player, "refueling", false, true)
	setVehicleDoorOpenRatio(vehicle, 1, 0, 250)
	toggleAllControls(player, true)
end

-- update the present time text for the scoreboard when the player spawns
function reSpawnPlayer(posX, posY, posZ, spawnRotation, theTeam, theSkin, theInterior, theDimension)
	setElementData(source, "PRESENT TIME", getEraText(theDimension))
	g_lastCarSpawn[source] = 0
	setCameraTarget(source, source)
end
addEventHandler("onPlayerSpawn", getRootElement(), reSpawnPlayer)

-- when a player leaves a car, check if it's a DeLorean and remember it
function savelastDeloreanDriven(player, seat)
	-- was the player in the driver seat and were they in a DeLorean?
	local vehicleModel = getElementModel(source)
	if (seat == 0) and (vehicleModel == g_deloreanModels["bttf2"] or vehicleModel == g_deloreanModels["bttf2flying"]) then
		g_lastDeloreanDriven[player] = source
	end
end
addEventHandler("onVehicleExit", getRootElement(), savelastDeloreanDriven)

-- enter the player into RC mode when they press the button for it
function enterRcMode(keyPresser)
	-- abort if the player alrady is in RC mode
	if exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		return
	end
	
	-- abort if the player hadn't been driving a DeLorean before
	if not isElement(g_lastDeloreanDriven[keyPresser]) then
		return
	end

	-- abort if the player is in the driver seat of this time machine
	if getPedOccupiedVehicleSeat(keyPresser) == 0 and getPedOccupiedVehicle(keyPresser) == g_lastDeloreanDriven[keyPresser] then
		return
	end

	exports["RcMode"]:enterRcMode(keyPresser, g_lastDeloreanDriven[keyPresser])
end

-- toggle RC mode camera between the car and the dummy ped if the player presses the button for it
function changeRcCamera(keyPresser)
	if exports["RcMode"]:isCameraOnRcDummy(keyPresser) then
		exports["RcMode"]:setCameraOnRcDummy(false)
	else
		exports["RcMode"]:setCameraOnRcDummy(true)
	end
end

-- exit rc mode if the player chooses to reload the models
function exitRcMode(playerSource)
	exports["RcMode"]:exitRcMode(playerSource)
end
addCommandHandler("reloadmodels", exitRcMode)

-- wrap key binding in a function to call it on resource start or the player joining
function bindKeys(player)
	bindKey(player, "2", "down", "car", "delorean")
	bindKey(player, "num_2", "down", "car", "delorean")
	bindKey(player, "c", "down", hoverConvertPlayerCar)
	bindKey(player, "handbrake", "both", toggleVentBoost)
	bindKey(player, "action", "down", refuelDelorean)
	bindKey(player, "r", "down", enterRcMode)
	-- bindKey(player, "enter_exit", "down", exitRcMode)
	-- bindKey(player, "change_camera", "down", changeRcCamera)
	bindKey(player, "b", "down", changeRcCamera)
	bindKey(player, "i", "down", toggleEngine)
	bindKey(player, "l", "down", toggleLights)
	-- Timecircuits
	for i = 0, 9 do
		bindKey(player, tostring(i), "down", keypad)
		bindKey(player, "num_" .. tostring(i), "down", keypad)
	end
	bindKey(player, "-", "down", toggleTimecircuits)
	bindKey(player, "num_sub", "down", keypad)
	bindKey(player, "backspace", "down", keypad)
	bindKey(player, "num_add", "down", toggleTimecircuits)
end

-- bind the keys when the player joins
function joinHandler()
	bindKeys(source)
end
addEventHandler("onPlayerJoin", getRootElement(), joinHandler)

-- when the player dies, respawn them at the nearest spawnpoint
function deathHandler(totalAmmo, killer, killerWeapon, bodypart)
	-- abort if the player is in RC mode, as the RC mode script will exit RC mode and respawn the player
	if exports["RcMode"]:isPlayerInRcMode(source) then
		return
	end

	-- search the spawnpoint with the smallest distance to the player
	local posX, posY, posZ = getElementPosition(source)
	local spawnpoints = getElementsByType("spawnpoint")
	smallestDistance = { math.huge }
	for i=1, #spawnpoints, 1 do
		local distance = getDistanceBetweenPoints3D(posX, posY, posZ, getElementData(spawnpoints[i], "posX"), getElementData(spawnpoints[i], "posY"), getElementData(spawnpoints[i], "posZ"))
		if distance < smallestDistance[1] then
			smallestDistance[1] = distance
			smallestDistance[2] = i
		end
	end

	-- spawn the player at the spawnpoint we found
	exports["bttfhv_spawnmanager"]:spawnPlayerAtSpawnpoint(source, spawnpoints[smallestDistance[2]], true)
end
addEventHandler("onPlayerWasted", getRootElement(), deathHandler)

-- initialize some data when the resource starts
function resourceStart(startedResource)
	resetMapInfo()
	exports["scoreboard"]:addScoreboardColumn("PRESENT TIME", getRootElement(), 2, .2)
	exports["bttfhv_spawnmanager"]:setSpawnWave(true, 7500)
	setMinuteDuration(60000)
	local players = getElementsByType("player")
	for i=1, #players, 1 do
		-- spawnPlayer(players[i])
		fadeCamera(players[i], true)
		bindKeys(players[i])
		local theDimension = getElementDimension(players[i])
		setElementData(players[i], "PRESENT TIME", getEraText(theDimension))
		g_lastCarSpawn[players[i]] = 0
	end
end
addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), resourceStart)