-- With slight modifications taken from https://wiki.multitheftauto.com/wiki/AttachEffect

local attachedEffects = {}
-- Taken from https://wiki.multitheftauto.com/wiki/GetElementMatrix example
function getPositionFromElementOffset(element, offX, offY, offZ)
    -- Get the matrix
    local m = getElementMatrix(element)
    -- Apply transform
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
    -- Return the transformed point
    return x, y, z
end

function attachEffect(effect, element, offX, offY, offZ, rotX, rotY, rotZ)
    attachedEffects[effect] = { element = element, offX = offX, offY = offY, offZ = offZ, rotX = rotX, rotY = rotY, rotZ = rotZ }
    addEventHandler("onClientElementDestroy", effect, function() attachedEffects[effect] = nil end)
    addEventHandler("onClientElementDestroy", element, function() attachedEffects[effect] = nil end)
    return true
end

function detatchEffect(effect, theAttachToElement)
    if not attachedEffects[effect] then
        return false
    end

    if theAttachToElement and attachedEffects[effect].element ~= theAttachToElement then
        return false
    end

    -- remove the effect from the list of tracked elements to stop
    attachedEffects[effect] = nil
end

addEventHandler("onClientPreRender", root, function()
    for fx, info in pairs(attachedEffects) do
        local x, y, z = getPositionFromElementOffset(info.element, info.offX, info.offY, info.offZ)
        setElementPosition(fx, x, y, z)
        x, y, z = getElementRotation(info.element, "ZYX")
        x = x + info.rotX
        y = y + info.rotY
        z = z + info.rotZ
        setElementRotation(fx, x, y, z)
    end
end)