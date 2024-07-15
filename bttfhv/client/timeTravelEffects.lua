local g_vehicleEffects = {}

function destroyAllVehicleEffects(vehicle)
	for _, effect in ipairs(g_vehicleEffects[vehicle]) do
		destroyElement(effect)
	end
	g_vehicleEffects[vehicle] = nil
end

function timeTravelEffects(vehicle)
	if not isVehicleTimeMachine(vehicle) then
		return
	end

	local mph = getVehicleSpeedMph(vehicle)

	if mph >= 80 then
		setVehicleComponentVisible(vehicle, "fluxcoilson", true)
	else 
		setVehicleComponentVisible(vehicle, "fluxcoilson", false)
	end

	if mph >= 82 and not g_vehicleEffects[vehicle] then
		local X, Y, Z = getElementPosition(vehicle)
		local rX, rY, rZ = getElementRotation(vehicle, "ZYX")
		local effectData = {
--			{ X = -0.4, Y = 1.2,   Z = -0.35, name = "flame" },
--			{ X = -0.4, Y = -1.65, Z = -0.35, name = "flame" },
--			{ X = 1.3,  Y = -1.65, Z = -0.35, name = "flame" },
--			{ X = 1.3,  Y = 1.2,   Z = -0.35, name = "flame" }
			{ X = -0.9, Y = 1.2,   Z = -0.5, rX = 180.0, rY = 0.0, rZ = 0.0, name = "flame" },
			{ X = -0.9, Y = -1.65, Z = -0.5, rX = 180.0, rY = 0.0, rZ = 0.0, name = "flame" },
			{ X = 0.9,  Y = -1.65, Z = -0.5, rX = 180.0, rY = 0.0, rZ = 0.0, name = "flame" },
			{ X = 0.9,  Y = 1.2,   Z = -0.5, rX = 180.0, rY = 0.0, rZ = 0.0, name = "flame" }
		}
		g_vehicleEffects[vehicle] = {}
		for i, effect in ipairs(effectData) do
			g_vehicleEffects[vehicle][i] = createEffect(effect.name, X, Y, Z, rX, rY, rZ, 0, false)
			attachEffect(g_vehicleEffects[vehicle][i], vehicle, effect.X, effect.Y, effect.Z, effect.rX, effect.rY, effect.rZ)
		end
		addEventHandler("onClientElementDestroy", vehicle, function() destroyAllVehicleEffects(vehicle) end)
		--outputDebugString("created effects")
	elseif mph < 82 and g_vehicleEffects[vehicle] then
		destroyAllVehicleEffects(vehicle)
		--outputDebugString("destroyed effects")
	end
end

function onClientRender()
	local vehicles = getElementsByType("vehicle", root, true)
	for _, vehicle in ipairs(vehicles) do
		timeTravelEffects(vehicle)
	end
end
addEventHandler("onClientRender", root, onClientRender)