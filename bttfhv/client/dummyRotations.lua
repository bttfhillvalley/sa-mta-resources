function updateDummyRotations(vehicle)
    if not isVehicleTimeMachine(vehicle) then
        return
    end

	local dummyComponentList = {
		door_lf_dummy = { "door_lf_ok", "door_lf_ok_glass", --[[ "door_lf_ok_window", ]] },
		door_rf_dummy = { "door_rf_ok", "door_rf_ok_glass", --[[ "door_rf_ok_window", ]] },
		--"door_lr_dummy" = nil,
		--"door_rr_dummy" = nil,
		wheel_lf_dummy = { "fxtirebttf1lf", "fxwheelbttf1lf", "fxtirebttf3lf", "fxwheelbttf3lf", "fxhubcapbttf3lf", "fxwheelbttf3rrlf", "fxrotorlf", "brakelf", "holderlf", },
		wheel_rf_dummy = { "fxtirebttf1rf", "fxwheelbttf1rf", "fxtirebttf3rf", "fxwheelbttf3rf", "fxhubcapbttf3rf", "fxwheelbttf3rrrf", "fxrotorrf", "brakerf", "holderrf", },
		wheel_lb_dummy = { "fxtirebttf1lb", "fxwheelbttf1lb", "fxtirebttf3lb", "fxwheelbttf3lb", "fxhubcapbttf3lb", "fxwheelbttf3rrlb", "fxrotorlb", "brakelb", "holderlb", },
		wheel_rb_dummy = { "fxtirebttf1rb", "fxwheelbttf1rb", "fxtirebttf3rb", "fxwheelbttf3rb", "fxhubcapbttf3rb", "fxwheelbttf3rrrb", "fxrotorrb", "brakerb", "holderrb", },
	}
	for dummyName, deloreanList in pairs(dummyComponentList) do
		local x, y, z = getVehicleComponentRotation(vehicle, dummyName)
		if type(x) == "number" and type(y) == "number" and type(z) == "number" then
			-- because Rockstar Games flips the left side tires, we need to undo this here
			if dummyName == "wheel_lf_dummy" or dummyName == "wheel_lb_dummy" then
				y = y + 180.0
				x = 360.0 - x
			end
			for _, deloreanName in ipairs(deloreanList) do
				setVehicleComponentRotation(vehicle, deloreanName, x, y, z)
			end
		end

		x, y, z = getVehicleComponentPosition(vehicle, dummyName)
		if type(x) == "number" and type(y) == "number" and type(z) == "number" then
			for _, deloreanName in ipairs(deloreanList) do
				setVehicleComponentPosition(vehicle, deloreanName, x, y, z)
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