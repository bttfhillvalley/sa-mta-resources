function updateDummyRotations(vehicle)
    if not isVehicleTimeMachine(vehicle) then
        return
    end

	local dummyComponentList = {
		door_lf_dummy = { "door_lf_ok", "door_lf_ok_glass", --[[ "door_lf_ok_window", ]] },
		door_rf_dummy = { "door_rf_ok", "door_rf_ok_glass", --[[ "door_rf_ok_window", ]] },
		--"door_lr_dummy" = nil,
		--"door_rr_dummy" = nil,
		wheel_lf_dummy = { "fxtirebttf1lf", "fxwheelbttf1lf", "fxrotorlf", "brakelf", "holderlf", },
		wheel_rf_dummy = { "fxtirebttf1rf", "fxwheelbttf1rf", "fxrotorrf", "brakerf", "holderrf", },
		wheel_lb_dummy = { "fxtirebttf1lb", "fxwheelbttf1lb", "fxrotorlb", "brakelb", "holderlb", },
		wheel_rb_dummy = { "fxtirebttf1rb", "fxwheelbttf1rb", "fxrotorrb", "brakerb", "holderrb", },
	}
	for dummyName, deloreanList in pairs(dummyComponentList) do
		local rX, rY, rZ = getVehicleComponentRotation(vehicle, dummyName)
		if rX and rY and rZ then
			-- because Rockstar Games flips the left side tires, we need to undo this here
			if dummyName == "wheel_lf_dummy" or dummyName == "wheel_lb_dummy" then
				rY = rY + 180.0
				rX = 360.0 - rX
			end
			for _, deloreanName in ipairs(deloreanList) do
				setVehicleComponentRotation(vehicle, deloreanName, rX, rY, rZ)
			end
		end
	end
end

function onClientRender()
	local vehicles = getElementsByType("vehicle", root, true)
	for _, vehicle in ipairs(vehicles) do
		updateDummyRotations(vehicle)
	end
end
addEventHandler("onClientRender", root, onClientRender)