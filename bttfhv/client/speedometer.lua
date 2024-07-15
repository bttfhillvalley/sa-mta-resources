local g_screenWidth, g_screenHeight = guiGetScreenSize()

function onClientRender()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle or not isVehicleTimeMachine(vehicle) then
        return
    end

    local mph = getVehicleSpeedMph(vehicle)
    local mphTxt = string.format("%02d", mph)

    -- Draw speed shadow
    dxDrawText(mphTxt, g_screenWidth * 0.89, g_screenHeight * 0.8, g_screenWidth * 0.1, g_screenHeight * 0.1, tocolor(0, 0, 0, 255), 10.0, "default")
    -- Draw speed
    dxDrawText(mphTxt, g_screenWidth * 0.89 + 1, g_screenHeight * 0.8 + 1, g_screenWidth * 0.1, g_screenHeight * 0.1, tocolor(255, 0, 0, 255), 10.0, "default")
end
addEventHandler("onClientRender", root, onClientRender)