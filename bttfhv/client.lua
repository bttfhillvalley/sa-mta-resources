function callClientFunction(funcname, ...)
	local arg = { ... }
	if (arg[1]) then
		for key, value in next, arg do arg[key] = tonumber(value) or value end
	end
	loadstring("return "..funcname)()(unpack(arg))
end
addEvent("onServerCallsClientFunction", true)
addEventHandler("onServerCallsClientFunction", getResourceRootElement(getThisResource()), callClientFunction)

deloreanModels = {
	bttf2 = 541,
	bttf2flying = 488,
}

local screenWidth, screenHeight = guiGetScreenSize() -- Get the screen resolution
emptyState = 0
lastReplace = 0

local eras = {
{9, 0, 2, 1, 8, 8, 5, 0, 8, 0, 0},
{11, 1, 2, 1, 9, 5, 5, 2, 2, 0, 4},
{10, 2, 6, 1, 9, 8, 5, 0, 1 ,2, 4},
{10, 2, 1, 2, 0, 1, 5, 1, 6, 2, 9}
}
local display = {{0,0},{0,0},{0,0}}

function showSpeedometer()
	local presentTime = getElementDimension(getLocalPlayer()) + 1
	if eras[presentTime] then
		if not (eras[presentTime][8] == 10) and not (eras[presentTime][9] == 10) and not (eras[presentTime][10] == 10) and not (eras[presentTime][11] == 10) then
			setTime(eras[presentTime][8] * 10 + eras[presentTime][9], eras[presentTime][10] * 10 + eras[presentTime][11])
		end
	end
	local playerCar = getPedOccupiedVehicle(getLocalPlayer())
	if playerCar then
		local vehicleModel = getElementModel(playerCar)
		if (vehicleModel == deloreanModels["bttf2"] or vehicleModel == deloreanModels["bttf2flying"]) then
			local posX = screenWidth - (screenWidth * 8 / 100) - 200
			local posY = screenHeight - (screenHeight * 5.5 / 100) - 135
			local tcstate = getElementData(playerCar, "tcstate")
			if ((getElementData(getLocalPlayer(), "settings.hideTimecircuits") == false) and (tcstate == false)) or (tcstate == true) then
				dxDrawImage(posX, posY, 245, 135, "led/TCD.png")
			end
			if (tcstate == true) then
				local tickcount = getTickCount()
				if (tickcount - math.floor(tickcount / 1000) * 1000 > 500) then -- draw the colons if the last three digits of the tickcount are greater than 500
					dxDrawImageSection(posX + 201, posY + 12, 11, 21, 0, 0, 11, 21, "led/colons.png")
					dxDrawImageSection(posX + 201, posY + 57, 11, 21, 11, 0, 11, 21, "led/colons.png")
					dxDrawImageSection(posX + 201, posY + 102, 11, 21, 22, 0, 11, 21, "led/colons.png")
				end
				
				-- destination time
				local destinationTime = getElementData(playerCar, "destinationTime")
				if eras[destinationTime] then
					dxDrawImageSection(posX + 7, posY + 12, 46, 21, 0, eras[destinationTime][1] * 21 + 0, 46, 21, "led/red_months.png")

					dxDrawImageSection(posX + 62, posY + 12, 14, 21, eras[destinationTime][2] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 76, posY + 12, 14, 21, eras[destinationTime][3] * 14 + 14, 0, 14, 21, "led/red_numbers.png")

					dxDrawImageSection(posX + 100, posY + 12, 14, 21, eras[destinationTime][4] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 114, posY + 12, 14, 21, eras[destinationTime][5] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 128, posY + 12, 14, 21, eras[destinationTime][6] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 142, posY + 12, 14, 21, eras[destinationTime][7] * 14 + 14, 0, 14, 21, "led/red_numbers.png")

					if (eras[destinationTime][8] * 10 + eras[destinationTime][9] > 12) then
						display[1][1] = eras[destinationTime][8] - 1
						display[1][2] = eras[destinationTime][9] - 2
						dxDrawImageSection(posX + 157, posY + 11, 16, 21, 0, 42, 16, 21, "led/PAM.png")
					else
						dxDrawImageSection(posX + 157, posY + 11, 16, 21, 0, 21, 16, 21, "led/PAM.png")
					end
					dxDrawImageSection(posX + 172, posY + 12, 14, 21, display[1][1] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 186, posY + 12, 14, 21, display[1][2] * 14 + 14, 0, 14, 21, "led/red_numbers.png")

					dxDrawImageSection(posX + 211, posY + 12, 14, 21, eras[destinationTime][10] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 225, posY + 12, 14, 21, eras[destinationTime][11] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
				end

				-- present time
				if eras[presentTime] then
					dxDrawImageSection(posX + 7, posY + 57, 46, 21, 0, eras[presentTime][1] * 21 + 0, 46, 21, "led/green_months.png")

					dxDrawImageSection(posX + 62, posY + 57, 14, 21, eras[presentTime][2] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 76, posY + 57, 14, 21, eras[presentTime][3] * 14 + 14, 0, 14, 21, "led/green_numbers.png")

					dxDrawImageSection(posX + 100, posY + 57, 14, 21, eras[presentTime][4] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 114, posY + 57, 14, 21, eras[presentTime][5] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 128, posY + 57, 14, 21, eras[presentTime][6] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 142, posY + 57, 14, 21, eras[presentTime][7] * 14 + 14, 0, 14, 21, "led/green_numbers.png")

					if (eras[presentTime][8] * 10 + eras[presentTime][9] > 12) then
						display[2][1] = eras[presentTime][8] - 1
						display[2][2] = eras[presentTime][9] - 2
						dxDrawImageSection(posX + 157, posY + 56, 16, 21, 16, 42, 16, 21, "led/PAM.png")
					else
						dxDrawImageSection(posX + 157, posY + 56, 16, 21, 16, 21, 16, 21, "led/PAM.png")
					end
					dxDrawImageSection(posX + 172, posY + 57, 14, 21, display[2][1] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 186, posY + 57, 14, 21, display[2][2] * 14 + 14, 0, 14, 21, "led/green_numbers.png")

					dxDrawImageSection(posX + 211, posY + 57, 14, 21, eras[presentTime][10] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 225, posY + 57, 14, 21, eras[presentTime][11] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
				end

				-- last time departed
				local lastTime = getElementData(playerCar, "lastTime")
				if lastTime then
					dxDrawImageSection(posX + 7, posY + 102, 46, 21, 0, eras[lastTime][1] * 21 + 0, 46, 21, "led/orange_months.png")

					dxDrawImageSection(posX + 62, posY + 102, 14, 21, eras[lastTime][2] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 76, posY + 102, 14, 21, eras[lastTime][3] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")

					dxDrawImageSection(posX + 100, posY + 102, 14, 21, eras[lastTime][4] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 114, posY + 102, 14, 21, eras[lastTime][5] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 128, posY + 102, 14, 21, eras[lastTime][6] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 142, posY + 102, 14, 21, eras[lastTime][7] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")

					if (eras[lastTime][8] * 10 + eras[lastTime][9] > 12) then
						display[3][1] = eras[lastTime][8] - 1
						display[3][2] = eras[lastTime][9] - 2
						dxDrawImageSection(posX + 157, posY + 101, 16, 21, 32, 42, 16, 21, "led/PAM.png")
					else
						dxDrawImageSection(posX + 157, posY + 101, 16, 21, 32, 21, 16, 21, "led/PAM.png")
					end
					dxDrawImageSection(posX + 172, posY + 102, 14, 21, display[3][1] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 186, posY + 102, 14, 21, display[3][2] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")

					dxDrawImageSection(posX + 211, posY + 102, 14, 21, eras[lastTime][10] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 225, posY + 102, 14, 21, eras[lastTime][11] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
				end
			end
			local speedX, speedY, speedZ = getElementVelocity(playerCar)
			local mph = ((speedX^2 + speedY^2 + speedZ^2)^(0.5)) * 111.847 -- use pythagorean theorem to get actual velocity taking all directions into account and multiply to get miles per hour
			local ones = math.floor(mph % 10)
			local tens = math.floor(mph / 10 % 10)
			local hundrets = math.floor(mph / 10 / 10 % 10)
			posX = screenWidth - (screenWidth * 8 / 100)
			posY = screenHeight - (screenHeight * 5.5 / 100) - 64 - 135
			local digitCountOffset = 0
			if (getElementData(getLocalPlayer(), "settings.useThreedigitspeedo") == true) then
				dxDrawImage(posX - 50 - 64 - 9, posY - 12 - 4, 164, 74, "speedo3d.png")
				digitCountOffset = 32 + 3
			else
				dxDrawImage(posX - 50 - 64 - 9, posY - 12 - 4, 164, 74, "speedo2d.png")
			end
			dxDrawImageSection(posX - 32 - 3 + digitCountOffset, posY, 32, 46, 0, ones * 46 + 2 * 46, 32, 46, "led/speedodigits.png")
			dxDrawImageSection(posX - 32 - 3 + digitCountOffset, posY, 32, 46, 0, 552, 32, 46, "led/speedodigits.png") -- the dot in the lower right corner
			if (tens == 0) and (hundrets == 0) then
				dxDrawImageSection(posX - 64 - 6 + digitCountOffset, posY, 32, 46, 0, 0, 32, 46, "led/speedodigits.png") -- the "off" image
			else
				dxDrawImageSection(posX - 64 - 6 + digitCountOffset, posY, 32, 46, 0, tens * 46 + 2 * 46, 32, 46, "led/speedodigits.png")
			end
			if (getElementData(getLocalPlayer(), "settings.useThreedigitspeedo") == true) then
				if (hundrets == 0) then
					dxDrawImageSection(posX - 64 - 6, posY, 32, 46, 0, 0, 32, 46, "led/speedodigits.png") -- the "off" image
				else
					dxDrawImageSection(posX - 64 - 6, posY, 32, 46, 0, hundrets * 46 + 2 * 46, 32, 46, "led/speedodigits.png")
				end
			end
			
			if (getElementData(playerCar, "fueled") and (getElementData(getLocalPlayer(), "settings.hideMrfusionlight") == false)) or not getElementData(playerCar, "fueled") then
				dxDrawImageSection(posX - 50 - 64 - 70 - 18, posY - 14, 70, 40, 0, 40 * emptyState, 70, 40, "empty_signal.png")
			end
			
			--[[if (mph >= 80) and (getVehicleController(playerCar) == getLocalPlayer()) and (tcstate == true) and getElementData(playerCar, "cooleddown") then
				-- if not (isElement(pre_travel1)) then
					-- pre_travel1 = playSound("sounds/pre_travel.mp3")
				-- end
				if not (isElement(pre_travel2)) then
					local posX, posY, posZ = getElementPosition(playerCar)
					pre_travel2 = playSound3D("sounds/pre_travel.mp3", posX, posY, posZ)
					setElementDimension(pre_travel2, getElementDimension(playerCar))
					attachElements(pre_travel2, playerCar)
				end
			else
				-- if (isElement(pre_travel1)) then
					-- destroyElement(pre_travel1)
				-- end
				if (isElement(pre_travel2)) then
					destroyElement(pre_travel2)
				end
			end]]
		end
		if not emptyLightFlashing then
			if getElementData(playerCar, "fueled") then
				emptyState = 0
			else
				emptyState = 1
			end
		end
	else
		-- if (isElement(pre_travel1)) then
			-- destroyElement(pre_travel1)
		-- end
		if (isElement(pre_travel2)) then
			destroyElement(pre_travel2)
		end
	end
end
addEventHandler("onClientRender", getRootElement(), showSpeedometer)

function getAttachedCoilSound(d_coil_lit)
	if isElement(d_coil_lit) then
		local attachedElements = getAttachedElements(d_coil_lit)
		if attachedElements then
			for key, value in ipairs(attachedElements) do
				if(getElementType(value) == "sound") then
					if (getElementData(value, "filename") == "sounds/pre_travel.mp3") then
						return value
					end
				end
			end
		end
	end
	return false
end

addEvent("onClientCoilsStart", true)
function createCoilSound()
	if not getAttachedCoilSound(source) then
		local posX, posY, posZ = getElementPosition(source)
		local pre_travel = playSound3D("sounds/pre_travel.mp3", posX, posY, posZ)
		setElementData(pre_travel, "filename", "sounds/pre_travel.mp3")
		setElementDimension(pre_travel, getElementDimension(source))
		attachElements(pre_travel, source)
	end
end
addEventHandler("onClientCoilsStart", getRootElement(), createCoilSound)
addEvent("onClientCoilsStop", true)
function destroyCoilSound()
	local coilSound = getAttachedCoilSound(source)
	if isElement(coilSound) then
		destroyElement(coilSound)
	end
end
addEventHandler("onClientCoilsStop", getRootElement(), destroyCoilSound)

addEvent("plutoniumEmpty", true)
function notifiyPlutoniumEmpty(theVehicle)
	if (getElementData(source, "settings.mrfusionsoundwithtcs") == false) or getElementData(theVehicle, "tcstate") then
		emptyLightFlashing = true
		setTimer(flashPlutoniumEmpty, 2000 - 425, 1, 1)
		setTimer(playSound, 2000, 1, "sounds/empty.mp3")
	end
end
function flashPlutoniumEmpty(count)
	if (count == 1) then
		emptyState = 1
	end
	emptyState = 1 - emptyState
	if (count <= 7) then
		setTimer(flashPlutoniumEmpty, 415, 1, count + 1)
	else
		emptyLightFlashing = false
	end
end
addEventHandler("plutoniumEmpty", getRootElement(), notifiyPlutoniumEmpty)

function checkPlutonium(theVehicle, seat)
	if (source == getLocalPlayer()) then
		local vehicleModel = getElementModel(theVehicle)
		if (vehicleModel == deloreanModels["bttf2flying"]) or (vehicleModel == deloreanModels["bttf2"]) then
			if not getElementData(theVehicle, "fueled") then
				triggerEvent("plutoniumEmpty", source, theVehicle)
			end
		end
	end
end
addEventHandler("onClientPlayerVehicleEnter", getRootElement(), checkPlutonium)

function engineReplaceMultiple(models)
	local debugOutput = { replacementFails = {}, replacements = 0, }
	for i = 1, #models do
		if models[i][3] then
			local txd = engineLoadTXD("models/" .. models[i][3] .. ".txd")
			local replacement = engineImportTXD(txd, models[i][1])
			-- outputDebugString("Replacing " .. models[i][3] .. ".txd returned " .. tostring(replacement))
			debugOutput["replacements"] = debugOutput["replacements"] + 1
			if not replacement then
				table.insert(debugOutput["replacementFails"], models[i][1].."="..models[i][3]..".txd")
			end
		end
		if models[i][2] then
			local dff = engineLoadDFF("models/" .. models[i][2] .. ".dff", models[i][1])
			local replacement = engineReplaceModel(dff, models[i][1])
			-- outputDebugString("Replacing " .. models[i][2] .. ".dff returned " .. tostring(replacement))
			debugOutput["replacements"] = debugOutput["replacements"] + 1
			if not replacement then
				table.insert(debugOutput["replacementFails"], models[i][1].."="..models[i][2]..".dff")
			end
		end
		if models[i][4] then
			local col = engineLoadCOL("models/" .. models[i][4] .. ".col")
			local replacement = engineReplaceCOL(col, models[i][1])
			-- outputDebugString("Replacing " .. models[i][4] .. ".col returned " .. tostring(replacement))
			debugOutput["replacements"] = debugOutput["replacements"] + 1
			if not replacement then
				table.insert(debugOutput["replacementFails"], models[i][1].."="..models[i][4]..".col")
			end
		end
	end
	if (debugOutput["replacements"] > 0) then
		outputDebugString(tostring(debugOutput["replacements"]) .. " replacements done.")
	end
	local debugOutputText = "Replacement failed for: " .. table.concat(debugOutput["replacementFails"], ", ")
	if (debugOutputText ~= "Replacement failed for: ") then
		outputDebugString(debugOutputText)
	end
end

function replaceVehiclesModels(printMessage)
	if printMessage == nil then
		printMessage = true
	end
	
	models =	{--	{ID,							dffName,					txdName,	colName,	},
					{deloreanModels["bttf2"],		"bullet",					"bttf2",	nil,		},
					{deloreanModels["bttf2flying"],	"sparrow",					"bttf2",	nil,		},
					{3890,							"d_strut_l",				"bttf2",	"empty",	},
					{3891,							"d_strut_r",				"bttf2",	"empty",	},
					{3892,							"d_wheel_l",				"bttf2",	"empty",	},
					{3893,							"d_wheel_r",				"bttf2",	"empty",	},
					{3894,							"d_coil_lit",				"bttf2",	"empty",	},
					{3895,							"d_green",					"bttf2",	"empty",	},
					{3896,							"d_wheel_g",				"bttf2",	"empty",	},
					{3897,							"particle_extinguisher",	nil,		"editingHelp",		},
					{3898,							"particle_fire",			nil,		"editingHelp",		},
					{3899,							"particle_jetpack",			nil,		"editingHelp",		},
					{3900,							"particle_prt_spark",		nil,		"editingHelp",		},
					{3901,							"particle_vent",			nil,		"editingHelp",		},
				}
	engineReplaceMultiple(models)
	
	if printMessage then
		outputChatBox("Custom models have been loaded. In case you are having texture issues, use the command /reloadmodels", 255, 127, 39)
	end
end
addCommandHandler("reloadmodels", function(commandName) replaceVehiclesModels(true) end, true)

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()) , 
function()
	replaceVehiclesModels(false)
	-- exports["realdriveby"]:setDriverDrivebyAbility({ })
end)

addEvent("hoverConvert", true)
function hoverConversionClientSide(thePlayer)
	local posX, posY, posZ = getElementPosition(source)
	local soundName = ""
	if (getElementModel(source) == deloreanModels["bttf2flying"]) then
		soundName = "on"
	else
		soundName = "off"
	end
	-- playSound("sounds/hover_" .. soundName .. ".mp3")
	local sound = playSound3D("sounds/hover_" .. soundName .. ".mp3", posX, posY, posZ)
	setElementDimension(sound, getElementDimension(source))
	attachElements(sound, source) -- damn, the wiki said that would work. Updated the wiki -- EDIT: WORKS BY NOW, YAY
	-- attachSound(sound, playerCar)
end
addEventHandler("hoverConvert", getRootElement(), hoverConversionClientSide)

addEvent("onVehicleEngineStateToggle", true)
function playEngineSound(engineState, keyPresser)
	local vehicleModel = getElementModel(source)
	if (vehicleModel == deloreanModels["bttf2flying"]) or (vehicleModel == deloreanModels["bttf2"]) then
		if engineState then
			engineState = "on"
		else
			engineState = "off"
		end
		local posX, posY, posZ = getElementPosition(source)
		local engineSound = playSound3D("sounds/engine_" .. engineState .. ".mp3", posX, posY, posZ)
		setElementDimension(engineSound, getElementDimension(source))
		attachElements(engineSound, source)
	end
end
addEventHandler("onVehicleEngineStateToggle", getRootElement(), playEngineSound)

addEvent("onClientRefuelsTimemachine", true)
function refuelDelorean(playerCar, step)
	local posX, posY, posZ = getElementPosition(playerCar)
	local mrfusionSound = playSound3D("sounds/mrfusion.mp3", posX, posY, posZ)
	setElementDimension(mrfusionSound, getElementDimension(playerCar))
	attachElements(mrfusionSound, playerCar)
end
addEventHandler("onClientRefuelsTimemachine", getRootElement(), refuelDelorean)

addEvent("keypadSound", true)
function playKeypadSound(soundName, posX, posY, posZ, dimension)
	local sound = playSound3D("sounds/keypad/".. soundName ..".mp3", posX, posY, posZ)
	setElementDimension(sound, dimension)
	attachElements(sound, source)
end
addEventHandler("keypadSound", getRootElement(), playKeypadSound)
addEvent("onClientTimemachineLeaves", true)
function playDepartureSound(posX, posY, posZ, dimension)
	local departureSound = playSound3D("sounds/time_travel-departure.mp3", posX, posY, posZ)
	setElementDimension(departureSound, dimension)
	setSoundMinDistance(departureSound, 10)
	setSoundMaxDistance(departureSound, 100)
end
addEventHandler("onClientTimemachineLeaves", getRootElement(), playDepartureSound)
addEvent("onClientTimemachineEnters", true)
function playReentrySound(posX, posY, posZ, dimension)
	local reentrySound = playSound3D("sounds/time_travel-reentry.mp3", posX, posY, posZ)
	setElementDimension(reentrySound, dimension)
	setSoundMinDistance(reentrySound, 10)
	setSoundMaxDistance(reentrySound, 100)
end
addEventHandler("onClientTimemachineEnters", getRootElement(), playReentrySound)

addEvent("ventSteam", true)
function playVentSteamSound()
	local posX, posY, posZ = getElementPosition(source)
	local dimension = getElementDimension(source)
	local ventSound = playSound3D("sounds/vent_steam.mp3", posX, posY, posZ)
	setElementDimension(ventSound, dimension)
	setSoundMinDistance(ventSound, 10)
	setSoundMaxDistance(ventSound, 100)
end
addEventHandler("ventSteam", getRootElement(), playVentSteamSound)

--[[function attachSound(theSound, theAttachToElement) -- workaround function to "attach" a sound to a car by constantly repositioning it
	if isElement(theSound) and isElement(theAttachToElement) then
		if (getSoundPosition(theSound) < getSoundLength(theSound)) then
			local posX, posY, posZ = getElementPosition(theAttachToElement)
			setElementPosition(theSound, posX, posY, posZ)
			setTimer(attachSound, 50, 1, theSound, theAttachToElement) -- deoesn't really work via this repeat hookup: It sounds really odd then
		-- else
			-- destoryElement(theSound)
		end
	end
end]]