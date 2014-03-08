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
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

DeLoreanModels = {
	bttf2 = 541,
	bttf2flying = 488,
}

function getEraText(dimension)
	local eras = {
		"SEP 02 1885 08:00",
		"NOV 12 1955 22:04",
		"OCT 26 1985 01:24",
		"OCT 21 2015 16:29",
	}
	if (dimension > -1) and (dimension + 1 <= #eras) then
		return eras[dimension + 1]
	end
	return "ERR"
end

lastTimeTravel = {}
function isVehicleOccupantInSeatReadyForTimetravel(vehicle, seat)
	local occupant = getVehicleOccupant(vehicle, seat)
	if occupant and lastTimeTravel[occupant] then
		if getTickCount() - lastTimeTravel[occupant] > 10000 then
			return true
		end
	else
		return true -- either there is no player in this seat or he hasn't timetravelled at all yet
	end
	return false
end

timeTravelTimers = {}
function timeTravel(playerCar, cooldown)
	if isElement(playerCar) then
		local speedX, speedY, speedZ = getElementVelocity(playerCar)
		local mph = ((speedX^2 + speedY^2 + speedZ^2)^(0.5)) * 111.847 -- use pythagorean theorem to get actual velocity taking all directions into account and multiply to get miles per hour
		if (cooldown >= 10000) and getElementData(playerCar, "tcstate") and isVehicleOccupantInSeatReadyForTimetravel(playerCar, 0) and isVehicleOccupantInSeatReadyForTimetravel(playerCar, 1) then
			if (mph >= 80) then
				local d_coil_lit
				local attachedElements = getAttachedElements(playerCar)
				for elementKey, elementValue in ipairs(attachedElements) do
					if isElement(elementValue) then
						if (getElementModel(elementValue) == 3894) then -- d_coil_lit
							d_coil_lit = elementValue
						end
					end
				end
				if not isElement(d_coil_lit) then
					local posX, posY, posZ = getElementPosition(playerCar)
					local d_coil_lit = createObject(3894, posX, posY, posZ)
					if isElement(d_coil_lit) then
						setElementDimension(d_coil_lit, getElementDimension(playerCar))
						attachElements(d_coil_lit, playerCar, 0.0, 0.0, 0.0)
						triggerClientEvent(getRootElement(), "onClientCoilsStart", d_coil_lit)
					end
				end
			else
				local attachedElements = getAttachedElements(playerCar)
				for elementKey, elementValue in ipairs(attachedElements) do
					if isElement(elementValue) then
						if (getElementModel(elementValue) == 3894) then -- d_coil_lit
							triggerClientEvent(getRootElement(), "onClientCoilsStop", elementValue)
							destroyElement(elementValue)
						end
					end
				end
			end
			if (mph >= 82) then
				--check first if we don't already have the sparks created...
				local sparks
				local attachedElements = getAttachedElements(playerCar)
				for elementKey, elementValue in ipairs(attachedElements) do
					if isElement(elementValue) then
						if (getElementModel(elementValue) == 3900) then -- particle_prt_spark
							sparks = elementValue
						end
					end
				end
				if not isElement(sparks) then
					createSparks(playerCar)
				end
			else
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
			if (mph >= 88) and getElementData(playerCar, "fueled") then
				setElementData(playerCar, "lastTime", getElementDimension(playerCar) + 1, true)
				setElementData(playerCar, "cooleddown", false, true)
				setElementData(playerCar, "fueled", false, true)
				local dimension = getElementData(playerCar, "destinationTime") - 1
				for i = 0, getVehicleMaxPassengers(playerCar), 1 do
					local passenger = getVehicleOccupant(playerCar, i) -- not using an array here, we are safe to overwrite the variable since we don't need it these commands
					if passenger then
						if (isElement(exports["RcMode"]:getPlayerRcDummy(passenger)) and (getPedOccupiedVehicle(passenger) == getPedOccupiedVehicle(exports["RcMode"]:getPlayerRcDummy(passenger)))) or not exports["RcMode"]:isPlayerInRcMode(passenger) then -- if the player is remote controlling the car he is in himself or not remote controlling at all
							callClientFunction(passenger, "playSound", "sounds/time_travel-instant.mp3")
							fadeCamera(passenger, false, .1, 255, 255, 255)
							setElementDimension(passenger, dimension)
							setElementData(passenger, "PRESENT TIME", getEraText(dimension))
							setTimer(fadeCamera, 125, 1, passenger, true, .1)
							lastTimeTravel[passenger] = getTickCount()
							triggerClientEvent(passenger, "plutoniumEmpty", passenger, playerCar)
						else
							exports["RcMode"]:exitRcMode(passenger)
						end
					end
				end
				local posX, posY, posZ = getElementPosition(playerCar)
				triggerClientEvent(getRootElement(), "onClientTimemachineLeaves", playerCar, posX, posY, posZ, getElementDimension(playerCar))
				setElementDimension(playerCar, dimension)
				triggerClientEvent(getRootElement(), "onClientTimemachineEnters", playerCar, posX, posY, posZ, dimension)
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
				setTimer(createVentSteam, 6000, 1, playerCar)
				cooldown = 0
			else
				setElementData(playerCar, "cooleddown", true, true)
				cooldown = 10000
			end
		else
			if (cooldown >= 2500) or (mph < 80) then -- as per Mike's request, leave the coil glow intact for three seconds after a timetravel
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
		timeTravelTimers[playerCar] = setTimer(timeTravel, 100, 1, playerCar, cooldown + 100)
	end
end

function createSparks(playerCar)
	if isElement(playerCar) then
		local posX, posY, posZ = getElementPosition(playerCar)
		local dimension = getElementDimension(playerCar)
		local sparks =	{	--order: front left, front right, back left, back right
							[1] = createObject(3900, posX, posY, posZ),
							[2] = createObject(3900, posX, posY, posZ),
							[3] = createObject(3900, posX, posY, posZ),
							[4] = createObject(3900, posX, posY, posZ),
						}
		setElementDimension(sparks[1], dimension)
		setElementDimension(sparks[2], dimension)
		setElementDimension(sparks[3], dimension)
		setElementDimension(sparks[4], dimension)
		attachElements(sparks[1], playerCar, -.91, 1.11, -.39, 0, 222, 85)
		attachElements(sparks[2], playerCar, .91, 1.11, -.39, 0, 222, 85)
		attachElements(sparks[3], playerCar, -.96, -1.66, -.29, 0, 222, 85)
		attachElements(sparks[4], playerCar, .96, -1.66, -.29, 0, 222, 85)
		local fire =	{	--order: front left, front right, back left, back right
							[1] = createObject(3899, posX, posY, posZ),
							[2] = createObject(3899, posX, posY, posZ),
							[3] = createObject(3899, posX, posY, posZ),
							[4] = createObject(3899, posX, posY, posZ),
						}
		setElementDimension(fire[1], dimension)
		setElementDimension(fire[2], dimension)
		setElementDimension(fire[3], dimension)
		setElementDimension(fire[4], dimension)
		attachElements(fire[1], playerCar, -.91, 1.11, -.39, 315, 0, 0)
		attachElements(fire[2], playerCar, .91, 1.11, -.39, 315, 0, 0)
		attachElements(fire[3], playerCar, -.96, -1.66, -.29, 315, 0, 0)
		attachElements(fire[4], playerCar, .96, -1.66, -.29, 315, 0, 0)
	end
end

function createVentSteam(playerCar)
	if isElement(playerCar) then
		local posX, posY, posZ = getElementPosition(playerCar)
		local dimension = getElementDimension(playerCar)
		local ventSteam =	{	-- 1 = left, 2 = right
								[1] = createObject(3897, posX, posY, posZ),
								[2] = createObject(3897, posX, posY, posZ),
							}
		setElementDimension(ventSteam[1], dimension)
		setElementDimension(ventSteam[2], dimension)
		-- attachElements(ventSteam[1], playerCar, -.4, -2.3, .3, 15, 0, 180)
		attachElements(ventSteam[1], playerCar, -.4, -2, .3, 15, 0, 180)
		-- attachElements(ventSteam[2], playerCar, .8, -2.3, .2, 15, 0, 180)
		attachElements(ventSteam[2], playerCar, .4, -2, .3, 15, 0, 180)
		triggerClientEvent(getRootElement(), "ventSteam", playerCar)
		setTimer(destroyVentSteam, 5000, 1, playerCar, ventSteam)
	end
end

function destroyVentSteam(playerCar, ventSteam)
	for i = 1, #ventSteam do
		if isElement(ventSteam[i]) then
			destroyElement(ventSteam[i])
		end
	end
end

boostedCars = {}
function toggleVentBoost(keyPresser, key, keyState)
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if playerCar then
		if(keyState == "down") and (getElementModel(playerCar) == DeLoreanModels["bttf2flying"]) then
			setVehicleColor(playerCar, 6, 6, 0, 0)
			boostedCars[playerCar] = true
		elseif (getElementModel(playerCar) == DeLoreanModels["bttf2flying"]) then
			setVehicleColor(playerCar, 13, 24, 0, 0)
			boostedCars[playerCar] = false
		end
	end
end

function boostloop(vehicle)
	if isElement(vehicle) then
		if not isVehicleBlown(vehicle) and boostedCars[vehicle] == true then
			ventBoost(vehicle)
		end
		setTimer(boostloop, 100, 1, vehicle)
	end
end

function ventBoost(vehicle)
	local speedX, speedY, speedZ = getElementVelocity(vehicle)
	local actualSpeed = ((speedX^2 + speedY^2 + speedZ^2)^(0.5))
	local boostAmount = 0.05
	if not (actualSpeed == 0) then
		boostAmount = math.log10(actualSpeed) * -.085
	else
		boostAmount = 0.01
	end
	local rotX, rotY, rotZ = getElementRotation(vehicle)
	local boostX = math.cos(math.rad(90-(360 - rotZ))) * boostAmount
	local boostY = math.sin(math.rad(90-(360 - rotZ))) * boostAmount
	local boostZ = math.sin(math.rad(rotX)) * boostAmount * 1.5
 	setElementVelocity(vehicle, speedX + boostX, speedY + boostY, speedZ + boostZ)
end

isVehicleHoverConversionActive = {}
function hoverConvertPlayerCar(keyPresser, key, keyState)
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if playerCar and (getPedOccupiedVehicleSeat(keyPresser) == 0) and not isVehicleHoverConversionActive[playerCar] then
		isVehicleHoverConversionActive[playerCar] = true
		local vehicleModel = getElementModel(playerCar)
		if (vehicleModel == DeLoreanModels["bttf2flying"]) then -- Sparrow: fold the wheels in
			triggerClientEvent(getRootElement(), "hoverConvert", playerCar, getVehicleOccupant(playerCar, 0))
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
				wheelAnimation(playerCar, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, DeLoreanModels["bttf2"], 1.15, 90)
			end
		elseif (vehicleModel == DeLoreanModels["bttf2"]) then -- Bullet: fold the wheels out
			changeVehicleModel(playerCar, DeLoreanModels["bttf2flying"])
			triggerClientEvent(getRootElement(), "hoverConvert", playerCar, getVehicleOccupant(playerCar, 0))
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
			wheelAnimation(playerCar, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, DeLoreanModels["bttf2flying"], 0.85, 0.0)
			local d_green = createObject(3895, 0.0, 0.0, 0.0)
			setElementDimension(d_green, dimension)
			attachElements(d_green, playerCar, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
			greenLightAnimation(playerCar, d_green, 0.0)
			boostloop(playerCar)
		end
	end
end

function wheelAnimation(theVehicle, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, targetModel, xPosOffset, yRotOffset)
	local animationComplete = false
	if (targetModel == DeLoreanModels["bttf2flying"]) then -- Flying: fold the wheels out
		if (xPosOffset < 1.15) then
			xPosOffset = xPosOffset + 0.03 -- 0.02
		-- elseif (yRotOffset < 1.55) then
			-- yRotOffset = yRotOffset + 0.07 -- 0.05
		elseif (yRotOffset < 90) then
			yRotOffset = yRotOffset + 8.5 -- 0.05
		else
			local d_wheel_g = createObject(3896, 0.0, 0.0, 0.0)
			setElementDimension(d_wheel_g, getElementDimension(theVehicle))
			attachElements(d_wheel_g, theVehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
			animationComplete = true
		end
	else  -- Driving: fold the wheels in
		-- if (yRotOffset > 0.0) then
			-- yRotOffset = yRotOffset - 0.07 -- 0.05
		if (yRotOffset > 0.0) then
			yRotOffset = yRotOffset - 8.5 -- 0.05
		elseif (xPosOffset > 0.85) then
			xPosOffset = xPosOffset - 0.03 -- 0.02
		else
			animationComplete = true
		end
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
			if boostedCars[theVehicle] then
				boostedCars[theVehicle] = false
				setVehicleColor(theVehicle, 13, 24, 0, 0)
			end
		end
	end
	if not animationComplete and isElement(theVehicle) and isElement(d_strut_l) and isElement(d_strut_r) and isElement(d_wheel_l) and isElement(d_wheel_r) then
		setElementAttachedOffsets(d_strut_l, xPosOffset * -1, 0.0, -0.3, 0.0, 0.0, 0.0)
		setElementAttachedOffsets(d_strut_r, xPosOffset, 0.0, -0.3, 0.0, 0.0, 0.0)
		setElementAttachedOffsets(d_wheel_l, xPosOffset * -1, 0.0, -0.3, 0.0, yRotOffset * -1, 0.0)
		setElementAttachedOffsets(d_wheel_r, xPosOffset, 0.0, -0.3, 0.0, yRotOffset, 0.0)
		setTimer(wheelAnimation, 50, 1, theVehicle, d_strut_l, d_strut_r, d_wheel_l, d_wheel_r, targetModel, xPosOffset, yRotOffset)
	elseif isElement(theVehicle) then
		isVehicleHoverConversionActive[theVehicle] = false
	end
end

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

function greenLightAnimation(theVehicle, d_green, yPosOffset)
	if isElement(d_green) then
		if isElement(theVehicle) then
			yPosOffset = yPosOffset - 0.1
			if (yPosOffset < -0.4) then
				yPosOffset = 0.0
			end	
			setElementAttachedOffsets(d_green, 0.0, yPosOffset, 0.0, 0.0, 0.0, 0.0)
			setTimer(greenLightAnimation, 250, 1, theVehicle, d_green, yPosOffset)
		else
			destroyElement(d_green)
		end
	end
end

function toggleTimecircuits(keyPresser, key, keyState)
	local playerCar = getPedOccupiedVehicle(keyPresser)
	if playerCar --[[ and (getPedOccupiedVehicleSeat(keyPresser) == 0) ]] and not exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		local vehicleModel = getElementModel(playerCar)
		if (vehicleModel == DeLoreanModels["bttf2"]) or (vehicleModel == DeLoreanModels["bttf2flying"]) then
			local tcstate = getElementData(playerCar, "tcstate")
			local tcsoundname
			if tcstate then
				tcstate = false
				tcsoundname = "off"
			else
				tcstate = true
				tcsoundname = "on"
			end
			setElementData(playerCar, "tcstate", tcstate, true)
			local posX, posY, posZ  = getElementPosition(playerCar)
			triggerClientEvent(getRootElement(), "keypadSound", playerCar, tcsoundname, posX, posY, posZ, getElementDimension(playerCar))
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
	end
end

keyBuffer = {}
function keypad(keyPresser, key, keyState)
	if isPedInVehicle(keyPresser) and not exports["RcMode"]:isPlayerInRcMode(keyPresser) then
		local playerCar = getPedOccupiedVehicle(keyPresser)
		if (getElementData(playerCar, "tcstate") == true) then
			local posX, posY, posZ = getElementPosition(playerCar)
			if ((key == "backspace") or (key == "num_sub")) then
				if keyBuffer[keyPresser] then
					local destinationTime = keyBuffer[keyPresser][1] * 1000 + keyBuffer[keyPresser][2] * 100 + keyBuffer[keyPresser][3] * 10 + keyBuffer[keyPresser][4]
					if (destinationTime == 1885) then
						destinationTime = 1
					elseif (destinationTime == 1955) then
						destinationTime = 2
					elseif (destinationTime == 1985) then
						destinationTime = 3
					elseif (destinationTime == 2015) then
						destinationTime = 4
					else
						destinationTime = nil
						triggerClientEvent(getRootElement(), "keypadSound", playerCar, "off", posX, posY, posZ, getElementDimension(playerCar))
						--[[for k,v in ipairs({keyPresser, getVehicleOccupant(playerCar, 1)}) do
							if v then
								callClientFunction(v, "playSound", "sounds/keypad/off.mp3")
							end
						end]]
					end
					if destinationTime then
						setElementData(playerCar, "destinationTime", destinationTime, true)
						triggerClientEvent(getRootElement(), "keypadSound", playerCar, "confirm", posX, posY, posZ, getElementDimension(playerCar))
						--[[ for k,v in ipairs({keyPresser, getVehicleOccupant(playerCar, 1)}) do
							if v then
								callClientFunction(v, "playSound", "sounds/keypad/confirm.mp3")
							end
						end ]]
					end
				else
					triggerClientEvent(getRootElement(), "keypadSound", playerCar, "off", posX, posY, posZ, getElementDimension(playerCar))
					--[[ for k,v in ipairs({keyPresser, getVehicleOccupant(playerCar, 1)}) do
						if v then
							callClientFunction(v, "playSound", "sounds/keypad/off.mp3")
						end
					end ]]
				end
			else
				if not (string.find(key, "num_") == nil) then
					key = string.sub(key, 5)
				end
				if keyBuffer[keyPresser] then
					keyBuffer[keyPresser][1] = keyBuffer[keyPresser][2]
					keyBuffer[keyPresser][2] = keyBuffer[keyPresser][3]
					keyBuffer[keyPresser][3] = keyBuffer[keyPresser][4]
					keyBuffer[keyPresser][4] = key
				else
					keyBuffer[keyPresser] = {-1, -1, -1, key}
				end
				triggerClientEvent(getRootElement(), "keypadSound", playerCar, key, posX, posY, posZ, getElementDimension(playerCar))
				--[[ for k,v in ipairs({keyPresser, getVehicleOccupant(playerCar, 1)}) do
					if v then
						callClientFunction(v, "playSound", "sounds/keypad/" .. key .. ".mp3")
					end
				end ]]
			end
		end
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

function refuelDelorean(keyPresser, key, keyState)
	if isElement(lastDeloreanDriven[keyPresser]) and not getElementData(lastDeloreanDriven[keyPresser], "fueled") and not getElementData(keyPresser, "refueling") then
		local posX, posY, behindCarZ = getElementPosition(lastDeloreanDriven[keyPresser])
		local rotX, rotY, rotZ = getElementRotation(lastDeloreanDriven[keyPresser])
		local radius = 2.7
		local offsetRot = math.rad(rotZ - 90)
		local behindCarX = posX + radius * math.cos(offsetRot)
		local behindCarY = posY + radius * math.sin(offsetRot)
		local playerPosX, playerPosY, playerPosZ = getElementPosition(keyPresser)
		if (getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, behindCarX, behindCarY, behindCarZ) <= 0.75) then
			triggerClientEvent(getRootElement(), "onClientRefuelsTimemachine", keyPresser, lastDeloreanDriven[keyPresser], 1)
			toggleAllControls(keyPresser, false)
			setElementData(keyPresser, "refueling", true, true)
			setVehicleDoorOpenRatio(lastDeloreanDriven[keyPresser], 1, 1, 250)
			setTimer(refuelDeloreanStep2, 2900, 1, keyPresser, lastDeloreanDriven[keyPresser])
		end
	end
end
function refuelDeloreanStep2(player, vehicle)
	setElementData(vehicle, "fueled", true, true)
	setElementData(player, "refueling", false, true)
	setVehicleDoorOpenRatio(vehicle, 1, 0, 250)
	toggleAllControls(player, true)
end

function reSpawnPlayer(posX, posY, posZ, spawnRotation, theTeam, theSkin, theInterior, theDimension)
	setElementData(source, "PRESENT TIME", getEraText(theDimension))
	lastCarSpawn[source] = 0
	setCameraTarget(source, source)
end
addEventHandler("onPlayerSpawn", getRootElement(), reSpawnPlayer)

lastDeloreanDriven = {}
function savelastDeloreanDriven(player, seat)
	local vehicleModel = getElementModel(source)
	if (seat == 0) and (vehicleModel == DeLoreanModels["bttf2"] or vehicleModel == DeLoreanModels["bttf2flying"]) then
		lastDeloreanDriven[player] = source
	end
end
addEventHandler("onVehicleExit", getRootElement(), savelastDeloreanDriven)

function enterRcMode(keyPresser)
	if not exports["RcMode"]:isPlayerInRcMode(keyPresser) and isElement(lastDeloreanDriven[keyPresser]) then
		if (getPedOccupiedVehicleSeat(keyPresser) == 0 and lastDeloreanDriven[keyPresser] ~= getPedOccupiedVehicle(keyPresser)) or (getPedOccupiedVehicleSeat(keyPresser) ~= 0) then
			exports["RcMode"]:enterRcMode(keyPresser, lastDeloreanDriven[keyPresser])
		end
	end
end

function changeRcCamera(keyPresser)
	if exports["RcMode"]:isCameraOnRcDummy(keyPresser) then
		exports["RcMode"]:setCameraOnRcDummy(false)
	else
		exports["RcMode"]:setCameraOnRcDummy(true)
	end
end

function exitRcMode(playerSource)
	exports["RcMode"]:exitRcMode(playerSource)
end
addCommandHandler("reloadmodels", exitRcMode)

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

function joinHandler()
	bindKeys(source)
end
addEventHandler("onPlayerJoin", getRootElement(), joinHandler)

function deathHandler(totalAmmo, killer, killerWeapon, bodypart)
	if not exports["RcMode"]:isPlayerInRcMode(source) then
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
		exports["spawnmanager2"]:spawnPlayerAtSpawnpoint(source, spawnpoints[smallestDistance[2]], true)
	end
end
addEventHandler("onPlayerWasted", getRootElement(), deathHandler)

addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), 
function(startedResource)
	resetMapInfo()
	exports["scoreboard"]:addScoreboardColumn("PRESENT TIME", getRootElement(), 2, .2)
	exports["spawnmanager2"]:setSpawnWave(true, 7500)
	setMinuteDuration(60000)
	local players = getElementsByType("player")
	for i=1, #players, 1 do
		-- spawnPlayer(players[i])
		fadeCamera(players[i], true)
		bindKeys(players[i])
		local theDimension = getElementDimension(players[i])
		setElementData(players[i], "PRESENT TIME", getEraText(theDimension))
		lastCarSpawn[players[i]] = 0
	end
end)