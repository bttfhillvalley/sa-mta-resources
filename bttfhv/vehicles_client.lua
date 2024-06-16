------------------------------
--	Script wide used variables
------------------------------

-- handle to the window with the vehicle selection
local g_carSpawnWindow

-- handle to the gridlist to add the vehicle list to
local g_gridList

------------------------------
--	Functionality
------------------------------

-- recursively iterate the xml file node's children and add them to the GUI
function iterateChildNodes(thisNode)
    -- check if there's more children to iterate trhough
	local childrenTable = xmlNodeGetChildren(thisNode)
	if not childrenTable then 
		return 
	end

	-- variable to hold the group name that was last read
	local groupName

	-- iterate through all children of the current element
    for i, node in ipairs(childrenTable) do
		-- add a new row to the gridlist
		local rowId = guiGridListAddRow(g_gridList)
		
		-- get the name attribute
		local name = xmlNodeGetAttribute(node, "name")
		
		-- if the xml element is a group add it as section to the gridlist and furhter descend into its children
		if xmlNodeGetName(node) == "group" then
			groupName = name
			guiGridListSetItemText(g_gridList, rowId, 1, name, true, false)
			iterateChildNodes(node)
		else 
			-- if the xml element is a vehicle read its properties and add it to the gridlist
			if xmlNodeGetName(node) == "vehicle" then
				guiGridListSetItemText(g_gridList, rowId, 2, xmlNodeGetAttribute(node, "id"), false, true)
				guiGridListSetItemText(g_gridList, rowId, 1, name, false, false)
			end
		end

		-- note the group name on the gridlist item
		guiGridListSetItemData(g_gridList, rowId, 1, groupName)
	end
end

-- handle the player double cliking a car, signal the server to spawn it and close the window
function doubleClickedCar()
    local selectedRow, selectedCol = guiGridListGetSelectedItem(g_gridList)
    local id = guiGridListGetItemText(g_gridList, selectedRow, 2)
	triggerServerEvent("spawnVehicle", localPlayer, id)
    guiSetVisible(g_carSpawnWindow, false)
    showCursor(false)
end

-- show the vehicle spawn gui and enable mouse input when the server requests to
addEvent("showVehicleSpawnGui", true)
function showVehicleSpawnGui()
    local visible = not guiGetVisible(g_carSpawnWindow)
	guiSetVisible(g_carSpawnWindow, visible)
	showCursor(visible)
end
addEventHandler("showVehicleSpawnGui", root, showVehicleSpawnGui)

-- create the vehicle selection ui and hide it until the server calls for it
function prepareVehicleSpawnGui()
	-- center the window on the screen
	local width, height = guiGetScreenSize()
	g_carSpawnWindow = guiCreateWindow(width / 2 - 300 / 2, height / 2 - 250 / 2, 300, 250, "Vehicles", false)
	
	-- hide the window until the server calls for it
	guiSetVisible(g_carSpawnWindow, false)
	
	-- add a little descriptive text
	local descriptionLabel = guiCreateLabel(0.03, 0.07, 0.94, 0.06, "Double click a vehicle in this list to spawn it:", true, g_carSpawnWindow)
	guiLabelSetHorizontalAlign(descriptionLabel, "left", true)
	
	-- create a selection gridlist with 2 columns
	g_gridList = guiCreateGridList(0.03, 0.14, 0.94, 0.82, true, g_carSpawnWindow)
	guiGridListSetSelectionMode(g_gridList, 0)
	guiGridListSetSortingEnabled(g_gridList, false)
	guiGridListAddColumn(g_gridList, "Name", 0.8)
	guiGridListAddColumn(g_gridList, "ID", 0.1)
	
	-- fill the gridlist with entries from the xml file
	local xmlRoot = xmlLoadFile("vehicles.xml")
	iterateChildNodes(xmlRoot)
	xmlUnloadFile(xmlRoot)

	-- handle a double click on a car in the list
	addEventHandler("onClientGUIDoubleClick", g_gridList, doubleClickedCar, false)
end
addEventHandler("onClientResourceStart", resourceRoot, prepareVehicleSpawnGui)