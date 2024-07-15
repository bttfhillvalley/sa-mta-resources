local g_lastCarSpawn = {}

function spawnDelorean(key, keyState)
	local thePlayer = getLocalPlayer()
	if getPedOccupiedVehicle(thePlayer) or getElementInterior(thePlayer) ~= 0 or isPedDead(thePlayer) then
		return
	end	
	if not g_lastCarSpawn[thePlayer] then
		g_lastCarSpawn[thePlayer] = 0
	end
	local spawnCooldown = (getTickCount() - g_lastCarSpawn[thePlayer]) / 1000
	if not (spawnCooldown >= 30) then
		outputChatBox(string.format("You have to wait an other %2i seconds before you can spawn a new vehicle.", 30 - spawnCooldown), 255, 0, 0)
		return
	end
	triggerServerEvent("spawnVehicle", localPlayer, g_vehicleIdDelorean)
	g_lastCarSpawn[thePlayer] = getTickCount()
end

addEvent("vehicleSpawned", true)
function handleVehicleSpawnedEvent(delorean)
	setVehicleWheelScale(delorean, 0.79)

	for i = 0, 70 do
		local name = string.format("wormhole%d", i)
		setVehicleComponentVisible(delorean, name, false)
		name = string.format("wormholer%d", i)
		setVehicleComponentVisible(delorean, name, false)
	end

	local otherComponentsToHide = {
		"fluxcoilson",
		"inner_vents",
		"inner_ventsglow",
		"door_lf_fr",
		"door_rf_fr",
		"door_lf_window_fr",
		"door_rf_window_fr"	,
		"chassis_fr",
		"bonnet_fr",
		"roof_fr",
		"wing_lf_fr",
		"wing_lr_fr",
		"wing_rf_fr",
		"wing_rr_fr",
		"windscreen_fr",
		"vents_fr",

		"fxthrusterbttf2lf",
		"fxthrusterbttf2rf",
		"fxthrusterbttf2lb",
		"fxthrusterbttf2rb",

		"fxthrusterbttf2lfon",
		"fxthrusterbttf2rfon",
		"fxthrusterbttf2lbon",
		"fxthrusterbttf2rbon",
		
		"fxthrusterbttf2lfth",
		"fxthrusterbttf2rfth",
		"fxthrusterbttf2lbth",
		"fxthrusterbttf2rbth",
		
		--[["fxwheelbttf1lf",
		"fxwheelbttf1rf",
		"fxwheelbttf1lb",
		"fxwheelbttf1rb",]]
		
		"fxwheelbttf2lfon",
		"fxwheelbttf2rfon",
		"fxwheelbttf2lbon",
		"fxwheelbttf2rbon",
		
		"fxwheelbttf3lf",
		"fxwheelbttf3rf",
		"fxwheelbttf3lb",
		"fxwheelbttf3rb",

		"fxwheelbttf3rrlf",
		"fxwheelbttf3rrrf",
		"fxwheelbttf3rrlb",
		"fxwheelbttf3rrrb",

		"fxhubcapbttf3lf",
		"fxhubcapbttf3rf",
		"fxhubcapbttf3lb",
		"fxhubcapbttf3rb",

		--[["fxtirebttf1lf",
		"fxtirebttf1rf",
		"fxtirebttf1lb",
		"fxtirebttf1rb",]]

		"fxtirebttf3lf",
		"fxtirebttf3rf",
		"fxtirebttf3lb",
		"fxtirebttf3rb",

		"hitch",
		"bonnetbttf3",

		"holderbttf1",
		"hookguidebttf1",
		"hookbttf1",
		"hookcableplugbttf1",
		"hookcablesoffbttf1",
		"hookcablesonbttf1",

		"plate",
		"plate_back",
		"platestock",
	}
	for _, name in ipairs(otherComponentsToHide) do
		setVehicleComponentVisible(delorean, name, false)
	end
end
addEventHandler("vehicleSpawned", getRootElement(), handleVehicleSpawnedEvent)

function onStart()	
	bindKey("0", "down", spawnDelorean)
end
addEventHandler("onClientResourceStart", resourceRoot, onStart)