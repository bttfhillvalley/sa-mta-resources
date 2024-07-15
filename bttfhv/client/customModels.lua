function onStart()	
	local txd = engineLoadTXD("client/models/delorean.txd")
	if not txd then
		outputDebugString("engineLoadTXD failed.")
		return
	end
	
	local dff = engineLoadDFF("client/models/delorean.dff")
	if not dff then
		outputDebugString("engineLoadDFF failed.")
		return
	end
	
	engineImportTXD(txd, g_vehicleIdDelorean)
	engineReplaceModel(dff, g_vehicleIdDelorean)
end
addEventHandler("onClientResourceStart", resourceRoot, onStart)