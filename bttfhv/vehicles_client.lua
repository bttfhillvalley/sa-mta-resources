local carSpawnWindow, gridList

function iterateChildNodes(thisNode)
    local childrenTable = xmlNodeGetChildren(thisNode)
	if not childrenTable then 
		return 
	end
	local groupName
    for i, node in ipairs(childrenTable) do
		local rowId = guiGridListAddRow(gridList)
		local name = xmlNodeGetAttribute(node, "name")
		if xmlNodeGetName(node) == "group" then
			groupName = name
			guiGridListSetItemText(gridList, rowId, 1, name, true, false)
			iterateChildNodes(node)
		else 
			if xmlNodeGetName(node) == "vehicle" then
				guiGridListSetItemText(gridList, rowId, 2, xmlNodeGetAttribute(node, "id"), false, true)
				guiGridListSetItemText(gridList, rowId, 1, name, false, false)
			end
		end
		guiGridListSetItemData(gridList, rowId, 1, groupName)
	end
end

function doubleClickedCar()
    local selectedRow, selectedCol = guiGridListGetSelectedItem(gridList)
    local id = guiGridListGetItemText(gridList, selectedRow, 2)
	triggerServerEvent("spawnVehicle", localPlayer, id)
    guiSetVisible(carSpawnWindow, false)
    showCursor(false)
end

addEvent("showVehicleSpawnGui", true)
function showVehicleSpawnGui()
    local visible = not guiGetVisible(carSpawnWindow)
	guiSetVisible(carSpawnWindow, visible)
	showCursor(visible)
end
addEventHandler("showVehicleSpawnGui", root, showVehicleSpawnGui)

addEventHandler("onClientResourceStart", resourceRoot,
    function()
		local width, height = guiGetScreenSize()
		carSpawnWindow = guiCreateWindow(width / 2 - 300 / 2, height / 2 - 250 / 2, 300, 250, "Vehicles", false)
		guiSetVisible(carSpawnWindow, false)
		local descriptionLabel = guiCreateLabel(0.03, 0.07, 0.94, 0.06, "Double click a vehicle in this list to spawn it:", true, carSpawnWindow)
		guiLabelSetHorizontalAlign(descriptionLabel, "left", true)
		gridList = guiCreateGridList(0.03, 0.14, 0.94, 0.82, true, carSpawnWindow)
		guiGridListSetSelectionMode(gridList, 0)
		guiGridListSetSortingEnabled(gridList, false)
		guiGridListAddColumn(gridList, "Name", 0.8)
		guiGridListAddColumn(gridList, "ID", 0.1)
		local xmlRoot = xmlLoadFile("vehicles.xml")
		iterateChildNodes(xmlRoot)
		xmlUnloadFile(xmlRoot)
		addEventHandler("onClientGUIDoubleClick", gridList, doubleClickedCar, false)
	end
)