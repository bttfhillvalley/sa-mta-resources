local g_lastCarSpawn = {}
local g_vehicleComponents = {}

function spawnDelorean(key, keyState)
	if getPedOccupiedVehicle(localPlayer) or getElementInterior(localPlayer) ~= 0 or isPedDead(localPlayer) then
		return
	end	
	if not g_lastCarSpawn[localPlayer] then
		g_lastCarSpawn[localPlayer] = 0
	end
	local spawnCooldown = (getTickCount() - g_lastCarSpawn[localPlayer]) / 1000
	if not (spawnCooldown >= 30) then
		outputChatBox(string.format("You have to wait an other %2i seconds before you can spawn a new vehicle.", 30 - spawnCooldown), 255, 0, 0)
		return
	end
	triggerServerEvent("spawnVehicle", localPlayer, g_vehicleIdDelorean)
	g_lastCarSpawn[localPlayer] = getTickCount()
end

addEvent("vehicleSpawned", true)
function handleVehicleSpawnedEvent(delorean)
	setVehicleWheelScale(delorean, 0.79)

	local variation = getElementData(delorean, "deloreanVariation")
	local components = getVehicleComponents(delorean)
    for name, _ in pairs(components) do
		-- the double negation changes a nil (for a not set list item) to false
		local common = not not g_vehicleComponents["common"][name]
		local thisVariation = not not g_vehicleComponents[variation][name]
		--outputDebugString(string.format("%s, common = %s, var = %s", name, tostring(common), tostring(thisVariation)))
		local visibility = common or thisVariation 
        local result = setVehicleComponentVisible(delorean, name, visibility)
		if not result then
			outputDebugString(string.format("failed to set visibility of components '%s' to %s", name, tostring(visibility)))
		end
	end
end
addEventHandler("vehicleSpawned", getRootElement(), handleVehicleSpawnedEvent)

function loadVehicleComponentsList()
	-- try loading the file and output an error message if it fails
	local file = xmlLoadFile("client/vehicleComponents.xml")
	if not file then
		outputDebugString("Failed to load the file client/vehicleComponents.xml")
		return
	end

	-- build a lookup table of the form
	-- g_vehicleComponents = {
	--     stock = {
	--         component1 = true,
	--         component2 = true,
	--         component3 = true,
	--         ...
	--     },
	--     bttf1 = {
	--         component1 = true,
	--         component2 = true,
	--         component3 = true,
	--         ...
	--     },
	--         ...
	-- }
	-- get the list of variation nodes and loop through them
	local variations = xmlNodeGetChildren(file)
	for _, variationNode in ipairs(variations) do
		-- get the name attribute, get the list of components and loop through them
		local variationName = xmlNodeGetAttribute(variationNode, "name")
		g_vehicleComponents[variationName] = {}
		local components = xmlNodeGetChildren(variationNode)
		for _, componentNode in ipairs(components) do
			-- add this component to the array and set to visible
			local componentName = xmlNodeGetAttribute(componentNode, "name")
			g_vehicleComponents[variationName][componentName] = true
		end
	end

	-- free memory
	xmlUnloadFile(file)
end

function onStart()	
	bindKey("0", "down", spawnDelorean)
	loadVehicleComponentsList()
end
addEventHandler("onClientResourceStart", resourceRoot, onStart)
