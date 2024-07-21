function getCurrentWormholeComponentVisible(vehicle, formatString)
	for i = 0, 70 do
		local name = string.format(formatString, i)
		if getVehicleComponentVisible(vehicle, name, false)	then
			return i
		end
	end
	return false
end

function resetWormholeComponents(vehicle, formatString, loopAll)
	if loopAll then
		for i = 0, 70 do
			local name = string.format(formatString, i)
			setVehicleComponentVisible(vehicle, name, false)		
		end
		return
	end

	local i = getCurrentWormholeComponentVisible(vehicle, formatString)
	if i then 
		setVehicleComponentVisible(vehicle, i, false)
	end
end

function wormhole(vehicle)    
    if not isVehicleTimeMachine(vehicle) then
        return
    end

    -- the bttf3 variants get different wormhole models than the other time machines
    local formatStr
    local variation = getElementData(vehicle, "deloreanVariation")
    if string.sub(variation, 1, 5) == "bttf3" then
        formatStr = "wormholer%d"
    else
        formatStr = "wormhole%d" 
    end
    
    local mph = getVehicleSpeedMph(vehicle)
    if mph > 44.9 then
        -- get which animation frame is currently visible
        local i = getCurrentWormholeComponentVisible(vehicle, formatStr)
        if not i then 
            -- if none is visible, start with the first frame
            i = 0
        else
            -- reset the frame that's currently visible
            local name = string.format(formatStr, i)
            setVehicleComponentVisible(vehicle, name, false)
        end
        -- count to the next animation frame
        i = i + 1
        -- depending on the speed, calculate the maximum animation frame currently allowed
        -- so that the wormhole grows with the speed
        --local j = math.floor((mph - 44.9) * 0.5)
        local j = math.ceil(
            (mph - 44.8) / 44.8 * 70
        )
        if j > 70 then
            j = 70
        end
        -- check if the next frame would be above the maximum for the current speed
        -- loop back down 10 frames if it is, but prevent underflowing 0
        if i > j then
            i = i - 10
            if i < 0 then
                i = 0
            end
        end
        local name = string.format(formatStr, i)
        setVehicleComponentVisible(vehicle, name, true)
    else
        resetWormholeComponents(vehicle, formatStr, true)
    end
end

function onClientRender()
	local vehicles = getElementsByType("vehicle", root, true)
	for _, vehicle in ipairs(vehicles) do
		wormhole(vehicle)
	end
end
addEventHandler("onClientRender", root, onClientRender)