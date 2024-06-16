-- allows the server to call any function on the client (rather than just trigger events)
-- see https://wiki.multitheftauto.com/wiki/CallClientFunction
function callClientFunction(funcname, ...)
	local arg = { ... }
	if (arg[1]) then
		for key, value in next, arg do arg[key] = tonumber(value) or value end
	end
	loadstring("return "..funcname)()(unpack(arg))
end
addEvent("onServerCallsClientFunction", true)
addEventHandler("onServerCallsClientFunction", getResourceRootElement(getThisResource()), callClientFunction)

-- configure which stock SA models the two DeLorean variants replace
g_deloreanModels = {
	bttf2 = 541,
	bttf2flying = 488,
}

-- predefine some global variables
local g_screenWidth, g_screenHeight = guiGetScreenSize()
g_emptyState = 0 -- fuel state of MrFusion

-- We want to provide the player with 4 possible eras. Configure the time&date values as follows:
-- Month, DayTens, DayOnes, YearThousands, YearHundrds, YearTens, YearOnes, HourTens, HourOnes, MinuteTens, MinuteOnes
-- The month is the only value with tens and ones not split, because the TCD shows it as a three letter text rather than individual numbers.
local g_eras = {
	{9, 0, 2, 1, 8, 8, 5, 0, 8, 0, 0},  -- Sep 02 1885 08:00
	{11, 1, 2, 1, 9, 5, 5, 2, 2, 0, 4}, -- Nov 12 1955 22:04
	{10, 2, 6, 1, 9, 8, 5, 0, 1 ,2, 4}, -- Oct 26 1985 01:24
	{10, 2, 1, 2, 0, 1, 5, 1, 6, 2, 9}  -- Oct 12 2015 16:29
}
local g_display = {{0,0}, {0,0}, {0,0}}

function showSpeedometer()
	-- To hide players that have travelled to a different time than the local player, we use MTA's dimensions.
	-- Check which of the dimensions the player is currently in in order to display the current time&date associated
	-- to this dimension on the TCD.
	local presentTime = getElementDimension(getLocalPlayer()) + 1
	-- prevent invalid array index if the player ends up in a dimension other than we defined (i.e. using another resource to change the dimension, such as admin panel)
	if g_eras[presentTime] then
		-- set the ingame time according to the value for the era
		if not (g_eras[presentTime][8] == 10) and not (g_eras[presentTime][9] == 10) and not (g_eras[presentTime][10] == 10) and not (g_eras[presentTime][11] == 10) then
			setTime(g_eras[presentTime][8] * 10 + g_eras[presentTime][9], g_eras[presentTime][10] * 10 + g_eras[presentTime][11])
		end
	end

	-- draw timecircuits, speedometer and empty light only if the player is driving a DeLorean
	local playerCar = getPedOccupiedVehicle(getLocalPlayer())
	if playerCar then
		-- is the player driving one of the DeLorean models?
		local vehicleModel = getElementModel(playerCar)
		if (vehicleModel == g_deloreanModels["bttf2"] or vehicleModel == g_deloreanModels["bttf2flying"]) then
			-- calculate the position to draw the timecircuits at
			local posX = g_screenWidth - (g_screenWidth * 8 / 100) - 200
			local posY = g_screenHeight - (g_screenHeight * 5.5 / 100) - 135
			
			-- the timnecitcuit state is saved on the car element to allow for one car's timecircuits to be on while another's are off
			local tcstate = getElementData(playerCar, "tcstate")
			
			-- Draw the background if
			--   * the timecircuits are turned on or
			--   * in the settings panel, the player chose to also show the background if the timecircuits are off 
			if (tcstate == true) or ((getElementData(getLocalPlayer(), "settings.hideTimecircuits") == false) and (tcstate == false)) then
				dxDrawImage(posX, posY, 245, 135, "led/TCD.png")
			end

			-- if the timecircuits are on draw all the lights 
			if (tcstate == true) then

				-- draw the colons between hour and minute every 500ms (flash every second)
				local tickcount = getTickCount()
				if (tickcount - math.floor(tickcount / 1000) * 1000 > 500) then
					dxDrawImageSection(posX + 201, posY + 12, 11, 21, 0, 0, 11, 21, "led/colons.png")
					dxDrawImageSection(posX + 201, posY + 57, 11, 21, 11, 0, 11, 21, "led/colons.png")
					dxDrawImageSection(posX + 201, posY + 102, 11, 21, 22, 0, 11, 21, "led/colons.png")
				end
				
				-- destination time
				local destinationTime = getElementData(playerCar, "destinationTime")
				if g_eras[destinationTime] then
					-- draw month
					dxDrawImageSection(posX + 7, posY + 12, 46, 21, 0, g_eras[destinationTime][1] * 21 + 0, 46, 21, "led/red_months.png")
					-- draw day
					dxDrawImageSection(posX + 62, posY + 12, 14, 21, g_eras[destinationTime][2] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 76, posY + 12, 14, 21, g_eras[destinationTime][3] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					-- draw year
					dxDrawImageSection(posX + 100, posY + 12, 14, 21, g_eras[destinationTime][4] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 114, posY + 12, 14, 21, g_eras[destinationTime][5] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 128, posY + 12, 14, 21, g_eras[destinationTime][6] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 142, posY + 12, 14, 21, g_eras[destinationTime][7] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					
					-- check whether the time to draw is before or after noon for the AM/PM indicator
					if (g_eras[destinationTime][8] * 10 + g_eras[destinationTime][9] > 12) then
						g_display[1][1] = g_eras[destinationTime][8] - 1
						g_display[1][2] = g_eras[destinationTime][9] - 2
						dxDrawImageSection(posX + 157, posY + 11, 16, 21, 0, 42, 16, 21, "led/PAM.png")
					else
						dxDrawImageSection(posX + 157, posY + 11, 16, 21, 0, 21, 16, 21, "led/PAM.png")
					end

					-- draw hour
					dxDrawImageSection(posX + 172, posY + 12, 14, 21, g_display[1][1] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 186, posY + 12, 14, 21, g_display[1][2] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					-- draw minute
					dxDrawImageSection(posX + 211, posY + 12, 14, 21, g_eras[destinationTime][10] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
					dxDrawImageSection(posX + 225, posY + 12, 14, 21, g_eras[destinationTime][11] * 14 + 14, 0, 14, 21, "led/red_numbers.png")
				end

				-- present time
				if g_eras[presentTime] then
					-- draw month
					dxDrawImageSection(posX + 7, posY + 57, 46, 21, 0, g_eras[presentTime][1] * 21 + 0, 46, 21, "led/green_months.png")
					-- draw day
					dxDrawImageSection(posX + 62, posY + 57, 14, 21, g_eras[presentTime][2] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 76, posY + 57, 14, 21, g_eras[presentTime][3] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					-- draw year
					dxDrawImageSection(posX + 100, posY + 57, 14, 21, g_eras[presentTime][4] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 114, posY + 57, 14, 21, g_eras[presentTime][5] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 128, posY + 57, 14, 21, g_eras[presentTime][6] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 142, posY + 57, 14, 21, g_eras[presentTime][7] * 14 + 14, 0, 14, 21, "led/green_numbers.png")

					-- check whether the time to draw is before or after noon for the AM/PM indicator
					if (g_eras[presentTime][8] * 10 + g_eras[presentTime][9] > 12) then
						g_display[2][1] = g_eras[presentTime][8] - 1
						g_display[2][2] = g_eras[presentTime][9] - 2
						dxDrawImageSection(posX + 157, posY + 56, 16, 21, 16, 42, 16, 21, "led/PAM.png")
					else
						dxDrawImageSection(posX + 157, posY + 56, 16, 21, 16, 21, 16, 21, "led/PAM.png")
					end

					-- draw hour
					dxDrawImageSection(posX + 172, posY + 57, 14, 21, g_display[2][1] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 186, posY + 57, 14, 21, g_display[2][2] * 14 + 14, 0, 14, 21, "led/green_numbers.png")

					-- draw minute
					dxDrawImageSection(posX + 211, posY + 57, 14, 21, g_eras[presentTime][10] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
					dxDrawImageSection(posX + 225, posY + 57, 14, 21, g_eras[presentTime][11] * 14 + 14, 0, 14, 21, "led/green_numbers.png")
				end

				-- last time departed
				-- read the value from the car element, as this can be different for every time machine
				local lastTime = getElementData(playerCar, "lastTime")
				if lastTime then
					-- draw month
					dxDrawImageSection(posX + 7, posY + 102, 46, 21, 0, g_eras[lastTime][1] * 21 + 0, 46, 21, "led/orange_months.png")
					-- draw day
					dxDrawImageSection(posX + 62, posY + 102, 14, 21, g_eras[lastTime][2] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 76, posY + 102, 14, 21, g_eras[lastTime][3] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					-- draw year
					dxDrawImageSection(posX + 100, posY + 102, 14, 21, g_eras[lastTime][4] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 114, posY + 102, 14, 21, g_eras[lastTime][5] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 128, posY + 102, 14, 21, g_eras[lastTime][6] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 142, posY + 102, 14, 21, g_eras[lastTime][7] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")

					-- check whether the time to draw is before or after noon for the AM/PM indicator
					if (g_eras[lastTime][8] * 10 + g_eras[lastTime][9] > 12) then
						g_display[3][1] = g_eras[lastTime][8] - 1
						g_display[3][2] = g_eras[lastTime][9] - 2
						dxDrawImageSection(posX + 157, posY + 101, 16, 21, 32, 42, 16, 21, "led/PAM.png")
					else
						dxDrawImageSection(posX + 157, posY + 101, 16, 21, 32, 21, 16, 21, "led/PAM.png")
					end

					-- draw hour
					dxDrawImageSection(posX + 172, posY + 102, 14, 21, g_display[3][1] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 186, posY + 102, 14, 21, g_display[3][2] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")

					-- draw minute
					dxDrawImageSection(posX + 211, posY + 102, 14, 21, g_eras[lastTime][10] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
					dxDrawImageSection(posX + 225, posY + 102, 14, 21, g_eras[lastTime][11] * 14 + 14, 0, 14, 21, "led/orange_numbers.png")
				end
			end

			-- get the car's speed in game units and calculate an mph value
			-- use pythagorean theorem to get actual velocity taking all directions into account and multiply to get miles per hour
			local speedX, speedY, speedZ = getElementVelocity(playerCar)
			local mph = ((speedX^2 + speedY^2 + speedZ^2)^(0.5)) * 111.847 
			-- split the number into individual digits to draw them individually
			local ones = math.floor(mph % 10)
			local tens = math.floor(mph / 10 % 10)
			local hundreds = math.floor(mph / 10 / 10 % 10)
			-- calculate the bottom right screen corner to start drawing at
			posX = g_screenWidth - (g_screenWidth * 8 / 100)
			posY = g_screenHeight - (g_screenHeight * 5.5 / 100) - 64 - 135
			
			-- depending on the player's choice in the settings panel, either draw the speed background with
			-- 2 digits (as seen in the movies) or 3 digits
			-- if we draw 3 digits, we need to start a little further to the right
			local digitCountOffset = 0
			if (getElementData(getLocalPlayer(), "settings.useThreedigitspeedo") == true) then
				dxDrawImage(posX - 50 - 64 - 9, posY - 12 - 4, 164, 74, "speedo3d.png")
				digitCountOffset = 32 + 3
			else
				dxDrawImage(posX - 50 - 64 - 9, posY - 12 - 4, 164, 74, "speedo2d.png")
			end

			-- The numbers are in a sprite file with them stacked on top of each other (top to bottom). 
			-- Multiply a number's height with the value of the number to draw to pick its offset in the sprite.
			-- The first row in the sprite file shows all segments of the LED display as off. 
			-- The second row shows all segments as on.
			-- The actual numbers start in the third row, hence offset by another two row heights.
			dxDrawImageSection(posX - 32 - 3 + digitCountOffset, posY, 32, 46, 0, ones * 46 + 2 * 46, 32, 46, "led/speedodigits.png")

			-- The little red dot is in the last line of the sprite. Draw that behind the last number
			dxDrawImageSection(posX - 32 - 3 + digitCountOffset, posY, 32, 46, 0, 552, 32, 46, "led/speedodigits.png")
			
			-- don't draw a leading 0. Instead, draw the image with all LED segments off
			if (tens == 0) and (hundreds == 0) then
				dxDrawImageSection(posX - 64 - 6 + digitCountOffset, posY, 32, 46, 0, 0, 32, 46, "led/speedodigits.png")
			else
				dxDrawImageSection(posX - 64 - 6 + digitCountOffset, posY, 32, 46, 0, tens * 46 + 2 * 46, 32, 46, "led/speedodigits.png")
			end

			-- depending on the player's choice in the settings panel, draw the third digit
			if (getElementData(getLocalPlayer(), "settings.useThreedigitspeedo") == true) then
				-- don't draw a leading 0. Instead, draw the image with all LED segments off
				if (hundreds == 0) then
					dxDrawImageSection(posX - 64 - 6, posY, 32, 46, 0, 0, 32, 46, "led/speedodigits.png")
				else
					dxDrawImageSection(posX - 64 - 6, posY, 32, 46, 0, hundreds * 46 + 2 * 46, 32, 46, "led/speedodigits.png")
				end
			end
			
			-- draw the MrFusion empty indicator if it's empty or the player chose to always show the image for the light being off in the settings panel.
			-- The image for this is a sprite file with the lamp off and on images stacked. Thus multiply the light's height by the emptyState to get the correct offset.
			-- emptyState is a flag that toggles between 0 and 1 for the flashing animation.
			if not getElementData(playerCar, "fueled") or (getElementData(playerCar, "fueled") and (getElementData(getLocalPlayer(), "settings.hideMrfusionlight") == false)) then
				dxDrawImageSection(posX - 50 - 64 - 70 - 18, posY - 14, 70, 40, 0, 40 * g_emptyState, 70, 40, "empty_signal.png")
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

		-- only turn off the empty light if the timer that controls the flashing isn't currently running
		-- to avoid messing with the blink cycle
		if not g_emptyLightFlashing then
			if getElementData(playerCar, "fueled") then
				g_emptyState = 0
			else
				g_emptyState = 1
			end
		end
	else
		-- if the player isn't driving, stop the pre travel sound file
		-- if (isElement(pre_travel1)) then
			-- destroyElement(pre_travel1)
		-- end
		-- if (isElement(pre_travel2)) then
		--	destroyElement(pre_travel2)
		--end
	end
end
addEventHandler("onClientRender", getRootElement(), showSpeedometer)

-- Search if there's a coil sound effect attached to the car and return it.
-- If none is found, return false.
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

-- Create a coil sound effect for a specific car if the server requests it
addEvent("onClientCoilsStart", true)
function createCoilSound()
	-- Create a coil sound effect and attach it to the car if it doesn't already exist.
	if not getAttachedCoilSound(source) then
		local posX, posY, posZ = getElementPosition(source)
		local pre_travel = playSound3D("sounds/pre_travel.mp3", posX, posY, posZ)
		-- put the sound effect in the same dimension as the car
		setElementDimension(pre_travel, getElementDimension(source))
		attachElements(pre_travel, source)
		-- Store the filename to the element to be able to search it later.
		setElementData(pre_travel, "filename", "sounds/pre_travel.mp3")
	end
end
addEventHandler("onClientCoilsStart", getRootElement(), createCoilSound)

-- Stop the coil effect sound for a specific car if the server requests it
addEvent("onClientCoilsStop", true)
function destroyCoilSound()
	local coilSound = getAttachedCoilSound(source)
	if isElement(coilSound) then
		destroyElement(coilSound)
	end
end
addEventHandler("onClientCoilsStop", getRootElement(), destroyCoilSound)

-- Run a timer loop to toggle the MrFusion empty light on and off 7 times
function flashPlutoniumEmpty(count)
	-- in the first timer cicle the light needs to be on
	if (count == 1) then
		g_emptyState = 1
	end
	-- toggle the value
	g_emptyState = 1 - g_emptyState
	-- repeat toggling 7 times
	if (count <= 7) then
		setTimer(flashPlutoniumEmpty, 415, 1, count + 1)
	else
		-- animation complete, reset the flag that we're flashing
		g_emptyLightFlashing = false
	end
end

-- Flash the MrFusion empty light and play the sound effect if the server requests it
addEvent("plutoniumEmpty", true)
function notifiyPlutoniumEmpty(theVehicle)
	if (getElementData(source, "settings.mrfusionsoundwithtcs") == false) or getElementData(theVehicle, "tcstate") then
		-- signal the graphics drawing thread to not overwrite the light state
		g_emptyLightFlashing = true
		-- Start the timer that flashes the MrFusion empty light
		setTimer(flashPlutoniumEmpty, 2000 - 425, 1, 1)
		-- play the MrFusion empty sound effect after a two second delay
		setTimer(playSound, 2000, 1, "sounds/empty.mp3")
	end
end
addEventHandler("plutoniumEmpty", getRootElement(), notifiyPlutoniumEmpty)

-- Everytime a player enters a car, check if its MrFusion chamber is empty.
-- If it is, flash the empty light and play a sound effect.
function checkPlutonium(theVehicle, seat)
	if (source == getLocalPlayer()) then
		local vehicleModel = getElementModel(theVehicle)
		if (vehicleModel == g_deloreanModels["bttf2flying"]) or (vehicleModel == g_deloreanModels["bttf2"]) then
			if not getElementData(theVehicle, "fueled") then
				triggerEvent("plutoniumEmpty", source, theVehicle)
			end
		end
	end
end
addEventHandler("onClientPlayerVehicleEnter", getRootElement(), checkPlutonium)

-- Replace a list of game models with textures, models and collisions.
-- Count how many replacements were successful and output a debug message at the end.
-- If there were failures, output which models failed.
function engineReplaceMultiple(models)
	local debugOutput = { replacementFails = {}, replacements = 0, }
	for i = 1, #models do
		-- does the list have a texture for this model?
		if models[i][3] then
			local txd = engineLoadTXD("models/" .. models[i][3] .. ".txd")
			local replacement = engineImportTXD(txd, models[i][1])
			-- outputDebugString("Replacing " .. models[i][3] .. ".txd returned " .. tostring(replacement))
			debugOutput["replacements"] = debugOutput["replacements"] + 1
			if not replacement then
				table.insert(debugOutput["replacementFails"], models[i][1].."="..models[i][3]..".txd")
			end
		end
		-- does the list have a mesh for this model?
		if models[i][2] then
			local dff = engineLoadDFF("models/" .. models[i][2] .. ".dff", models[i][1])
			local replacement = engineReplaceModel(dff, models[i][1])
			-- outputDebugString("Replacing " .. models[i][2] .. ".dff returned " .. tostring(replacement))
			debugOutput["replacements"] = debugOutput["replacements"] + 1
			if not replacement then
				table.insert(debugOutput["replacementFails"], models[i][1].."="..models[i][2]..".dff")
			end
		end
		-- does the list have a collision for this model? (only world models, i.e. not cars)
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

-- Wrap definition of replacement list and call to function that processes the list into a function so it can be called
-- from resource start event and /reloadmodels command.
function replaceVehiclesModels(printMessage)
	if printMessage == nil then
		printMessage = true
	end
	
	local models = {
				--	{ID,								dffName,					txdName,	colName,			},
					{g_deloreanModels["bttf2"],			"bullet",					"bttf2",	nil,				},
					{g_deloreanModels["bttf2flying"],	"sparrow",					"bttf2",	nil,				},
					{3890,								"d_strut_l",				"bttf2",	"empty",			},
					{3891,								"d_strut_r",				"bttf2",	"empty",			},
					{3892,								"d_wheel_l",				"bttf2",	"empty",			},
					{3893,								"d_wheel_r",				"bttf2",	"empty",			},
					{3894,								"d_coil_lit",				"bttf2",	"empty",			},
					{3895,								"d_green",					"bttf2",	"empty",			},
					{3896,								"d_wheel_g",				"bttf2",	"empty",			},
					{3897,								"particle_extinguisher",	nil,		"editingHelp",		},
					{3898,								"particle_fire",			nil,		"editingHelp",		},
					{3899,								"particle_jetpack",			nil,		"editingHelp",		},
					{3900,								"particle_prt_spark",		nil,		"editingHelp",		},
					{3901,								"particle_vent",			nil,		"editingHelp",		},
	}
	engineReplaceMultiple(models)
	
	if printMessage then
		outputChatBox("Custom models have been loaded. In case you are having texture issues, use the command /reloadmodels", 255, 127, 39)
	end
end

-- Add a command to retry loading the custom models
addCommandHandler("reloadmodels", function(commandName) replaceVehiclesModels(true) end, true)

-- Load custom models when the game starts
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()) , 
function()
	replaceVehiclesModels(false)
end)

-- Play the sound effect for engaging or disengaging hover mode and attach it to the car when the server requests to
addEvent("hoverConvert", true)
function hoverConversionClientSide(thePlayer)
	local posX, posY, posZ = getElementPosition(source)
	local soundName = ""
	if (getElementModel(source) == g_deloreanModels["bttf2flying"]) then
		soundName = "on"
	else
		soundName = "off"
	end
	local sound = playSound3D("sounds/hover_" .. soundName .. ".mp3", posX, posY, posZ)
	-- put the sound effect in the same dimension as the car
	setElementDimension(sound, getElementDimension(source))
	attachElements(sound, source)
end
addEventHandler("hoverConvert", getRootElement(), hoverConversionClientSide)

-- if the player is driving a DeLorean and the engine is turned on or off, play the sound effect when the server requests to
addEvent("onVehicleEngineStateToggle", true)
function playEngineSound(engineState, keyPresser)
	local vehicleModel = getElementModel(source)
	if (vehicleModel == g_deloreanModels["bttf2flying"]) or (vehicleModel == g_deloreanModels["bttf2"]) then
		if engineState then
			engineState = "on"
		else
			engineState = "off"
		end
		local posX, posY, posZ = getElementPosition(source)
		local engineSound = playSound3D("sounds/engine_" .. engineState .. ".mp3", posX, posY, posZ)
		-- put the sound effect in the same dimension as the car
		setElementDimension(engineSound, getElementDimension(source))
		attachElements(engineSound, source)
	end
end
addEventHandler("onVehicleEngineStateToggle", getRootElement(), playEngineSound)

-- play the sound effect of MrFusion being refueled when the server requests to
addEvent("onClientRefuelsTimemachine", true)
function refuelDelorean(playerCar, step)
	local posX, posY, posZ = getElementPosition(playerCar)
	local mrfusionSound = playSound3D("sounds/mrfusion.mp3", posX, posY, posZ)
	-- put the sound effect in the same dimension as the car
	setElementDimension(mrfusionSound, getElementDimension(playerCar))
	attachElements(mrfusionSound, playerCar)
end
addEventHandler("onClientRefuelsTimemachine", getRootElement(), refuelDelorean)

-- play a keypad dial tone when the server requests to
addEvent("keypadSound", true)
function playKeypadSound(soundName, posX, posY, posZ, dimension)
	local sound = playSound3D("sounds/keypad/".. soundName ..".mp3", posX, posY, posZ)
	setElementDimension(sound, dimension)
	attachElements(sound, source)
end
addEventHandler("keypadSound", getRootElement(), playKeypadSound)

-- play the sound effect of a time machine departing when the server requests to
addEvent("onClientTimemachineLeaves", true)
function playDepartureSound(posX, posY, posZ, dimension)
	local departureSound = playSound3D("sounds/time_travel-departure.mp3", posX, posY, posZ)
	setElementDimension(departureSound, dimension)
	setSoundMinDistance(departureSound, 10)
	setSoundMaxDistance(departureSound, 100)
end
addEventHandler("onClientTimemachineLeaves", getRootElement(), playDepartureSound)

-- play the sound effect of a time machine reentering when the server requests to
addEvent("onClientTimemachineEnters", true)
function playReentrySound(posX, posY, posZ, dimension)
	local reentrySound = playSound3D("sounds/time_travel-reentry.mp3", posX, posY, posZ)
	setElementDimension(reentrySound, dimension)
	setSoundMinDistance(reentrySound, 10)
	setSoundMaxDistance(reentrySound, 100)
end
addEventHandler("onClientTimemachineEnters", getRootElement(), playReentrySound)

-- play the sound effect of a time machine venting steam when the server requests to
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

--[[ -- no longer needed!
	-- workaround function to "attach" a sound to a car by constantly repositioning it
	function attachSound(theSound, theAttachToElement)
	if isElement(theSound) and isElement(theAttachToElement) then
		if (getSoundPosition(theSound) < getSoundLength(theSound)) then
			local posX, posY, posZ = getElementPosition(theAttachToElement)
			setElementPosition(theSound, posX, posY, posZ)
			setTimer(attachSound, 50, 1, theSound, theAttachToElement) -- deoesn't really work via this repeat hookup: It sounds really odd then
		-- else
			-- destoryElement(theSound)
		end
	end
end
]]