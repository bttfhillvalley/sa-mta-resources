local g_lastCarSpawn = {}
local g_idxLastVariation = 0
local g_vehicleComponents = { _variationNames = {} }

function spawnDeloreanOrChangeVariation()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if vehicle and getElementModel(vehicle) == g_vehicleIdDelorean then 
		nextDeloreanVariation(vehicle)
	else 
		spawnDelorean(vehicle)
	end
end

function nextDeloreanVariation(vehicle)
	g_idxLastVariation = g_idxLastVariation + 1
	if g_idxLastVariation > #g_vehicleComponents._variationNames then 
		g_idxLastVariation = 1
	end

	applyDeloreanVariation(vehicle, g_vehicleComponents._variationNames[g_idxLastVariation])
end

function spawnDelorean(vehicle)
	if vehicle or getElementInterior(localPlayer) ~= 0 or isPedDead(localPlayer) then
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

function applyDeloreanVariation(delorean, variation)
	-- loop through all the components of the DeLorean and apply
	-- visibility on the components as configured in the gobal array
	local components = getVehicleComponents(delorean)
    for name, _ in pairs(components) do
		
		-- The global array only contains items that should be visible.
		-- Check if it contains this item. Use a double negation on the check
		-- to get false for items not in the array (those would return nil)
		local common = not not g_vehicleComponents["common"][name]
		local thisVariation = not not g_vehicleComponents[variation][name]
		
		-- show the component if it either belongs to the common variation
		-- or this specific one
		local visibility = common or thisVariation 
        
		-- apply
        local result = setVehicleComponentVisible(delorean, name, visibility)
		--if not result then
		--	outputDebugString(string.format("failed to set visibility of component '%s' to %s", name, tostring(visibility)))
		--end
	end
	outputChatBox(string.format("Applied variation %s.", variation))
end

addEvent("vehicleSpawned", true)
function handleVehicleSpawnedEvent(delorean)
	setVehicleWheelScale(delorean, 0.79)

	local variation = getElementData(delorean, "deloreanVariation")
	applyDeloreanVariation(delorean, variation)	
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
		-- get the name attribute and add an empty array this variation
		local variationName = xmlNodeGetAttribute(variationNode, "name")
		g_vehicleComponents[variationName] = {}

		-- add the variationName to the array to be able to get it by a numerical index
		table.insert(g_vehicleComponents._variationNames, variationName)
		
		-- get the list of components and loop through them
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
	bindKey("0", "down", spawnDeloreanOrChangeVariation)
	loadVehicleComponentsList()
end
addEventHandler("onClientResourceStart", resourceRoot, onStart)
