function joinHandler()
	setCameraMatrix(source, 223.71885681152, 1825.2418212891, 10.0, 219.965, 1822.795, 5.5)
	setElementDimension(source, 3)
	fadeCamera(source, true)
	outputChatBox("Welcome to new Back to the Future: Hill Valley Multiplayer", source)
end
addEventHandler("onPlayerJoin", getRootElement(), joinHandler)

addEvent("onClientBttfhvAccountResourceStarted", true)
function resourceStartHandler(thePlayer)
	local account = getPlayerAccount(thePlayer)
	if account then
		if isGuestAccount(account) then
			triggerClientEvent(thePlayer, "showLoginWindow", thePlayer)
		end
	else
		triggerClientEvent(thePlayer, "showLoginWindow", thePlayer)
	end
end
addEventHandler("onClientBttfhvAccountResourceStarted", getResourceRootElement(getThisResource()), resourceStartHandler)

addEvent("submitLogin", true)
function loginHandler(thePlayer, username, password)
	if thePlayer and username and password then
		local account = getAccount(username, password)
		if account then
			if logIn(thePlayer, account, password) then
				-- triggerClientEvent(thePlayer, "correctLogin", thePlayer)
			else
				if not isGuestAccount(getPlayerAccount(thePlayer)) then
					triggerClientEvent(thePlayer, "correctLogin", thePlayer) -- the player is already logged in, let's just close the login window...
					outputChatBox("Note: You have already been logged in. If the gamemode got restarted while you were in the server it's a good idea to reconnect now and log in again. Otherwise you might be missing functions bound to keys.", thePlayer) -- ...and suggest him to reconnect
				end
			end
		else
			triggerClientEvent(thePlayer, "wrongLogin", thePlayer, "Please check your username and password.\nIn case you forgot your password, contact\nthe forum administration on\nhttp://bttfhv.com")
			outputDebugString("'" .. username .. "' tried to login with wrong credentials.")
		end
	end
end
addEventHandler("submitLogin", getRootElement(), loginHandler)

addEvent("submitRegistration", true)
function registrationHandler(thePlayer, username, password)
	if thePlayer and username and password then
		if not getAccount(username) then
			local account = addAccount(username, password) -- create the account
			logIn(thePlayer, account, password)
			-- triggerClientEvent(thePlayer, "correctLogin", thePlayer)
		else
			triggerClientEvent(thePlayer, "wrongLogin", thePlayer, "Your account could not be created.\nMaybe this username already exists.")
		end
	end
end
addEventHandler("submitRegistration", getRootElement(), registrationHandler)

function storePositionToAccount(thePreviousAccount, theCurrentAccount, quitType) -- quitType only available for onPlayerQuit
    if not (isGuestAccount(getPlayerAccount(source))) then
		local posX, posY, posZ = getElementPosition(source)
		setAccountData(thePreviousAccount, "bttfhv.posX", posX)
		setAccountData(thePreviousAccount, "bttfhv.posY", posY)
		setAccountData(thePreviousAccount, "bttfhv.posZ", posZ + 0.5)
		local rotX, rotY, rotZ = getElementRotation(source)
		setAccountData(thePreviousAccount, "bttfhv.rotZ", rotZ)
		setAccountData(thePreviousAccount, "bttfhv.skinID", getElementModel(source))
		setAccountData(thePreviousAccount, "bttfhv.interior", getElementInterior(source))
		setAccountData(thePreviousAccount, "bttfhv.dimension", getElementDimension(source))
		local team = getPlayerTeam(source)
		if team then
			setAccountData(thePreviousAccount, "bttfhv.team.name", getTeamName(team))
			local r, g, b, a = getTeamColor(team)
			setAccountData(thePreviousAccount, "bttfhv.team.color", rgbToHex(r, g, b, a))
		end
		setAccountData(thePreviousAccount, "bttfhv.money", getPlayerMoney(source))
		setAccountData(thePreviousAccount, "bttfhv.health", getElementHealth(source))
		setAccountData(thePreviousAccount, "bttfhv.armor", getPedArmor(source))
		for i=0, 12, 1 do
			setAccountData(thePreviousAccount, "bttfhv.weapons.slot" .. i .. ".weapon", tostring(getPedWeapon(source, i)))
			setAccountData(thePreviousAccount, "bttfhv.weapons.slot" .. i .. ".ammo", tostring(getPedTotalAmmo(source, i)))
		end
		if quitType then
			quitType = ' [' .. quitType .. ']'
		else
			local quitType = ''
		end
		outputChatBox('* ' .. getPlayerName(source) .. ' has left the game' .. quitType .. '.', root, 255, 100, 100)
	end
end
addEventHandler("onPlayerLogout", getRootElement(), storePositionToAccount)

function restorePositionFromAccount(thePreviousAccount, theCurrentAccount, autoLogin)
	local position = {
		X  = getAccountData(theCurrentAccount, "bttfhv.posX"),
		Y = getAccountData(theCurrentAccount, "bttfhv.posY"),
		Z  = getAccountData(theCurrentAccount, "bttfhv.posZ")
	}
	local rotZ = getAccountData(theCurrentAccount, "bttfhv.rotZ")
	local skinID = getAccountData(theCurrentAccount, "bttfhv.skinID")
	local interior = getAccountData(theCurrentAccount, "bttfhv.interior")
	local dimension = getAccountData(theCurrentAccount, "bttfhv.dimension")
	local health = getAccountData(theCurrentAccount, "bttfhv.health")
	local armor = getAccountData(theCurrentAccount, "bttfhv.armor")
	local money = getAccountData(theCurrentAccount, "bttfhv.money")
	local team = {
		name = getAccountData(theCurrentAccount, "bttfhv.team.name"), 
		color = getAccountData(theCurrentAccount, "bttfhv.team.color") 
	}
	if not team.name then
		team.name = "Logged in players"
		team.color = "#FFFFFFFF"
	end
	theTeam = getTeamFromName(team.name)
	if not theTeam then
		local r, g, b, a = getColorFromString(team.color)
		theTeam = createTeam(team.name, r, g, b)
	end
	if position.X and position.Y and position.Z and rotZ and interior and dimension and theTeam then
		spawnPlayer(source, position.X, position.Y, position.Z, rotZ, skinID, interior, dimension, theTeam)
	else
		exports["spawnmanager2"]:spawnPlayerAtSpawnpoint(source, nil, false)
		setPlayerTeam(source, theTeam)
	end
	if health and (health ~= 0) then
		setElementHealth(source, health)
	end
	if armor then
		setPedArmor(source, armor)
	end
	if money then
		setPlayerMoney(source, money)
	end
	for i=0, 12, 1 do
		local weapon = getAccountData(theCurrentAccount, "bttfhv.weapons.slot" .. i .. ".weapon")
		if weapon then
			local ammo = getAccountData(theCurrentAccount, "bttfhv.weapons.slot" .. i .. ".ammo")
			giveWeapon(source, weapon, ammo)
		end
	end
	local acceptedRules = getAccountData(theCurrentAccount, "bttfhv.acceptedRules")
	if not acceptedRules then
		setTimer(triggerClientEvent, 3000, 1, source, "showRulesWindow", source)
	end
	local hideTimecircuits = getAccountData(theCurrentAccount, "bttfhv.settings.hideTimecircuits")
	if hideTimecircuits then
		setElementData(source, "settings.hideTimecircuits", hideTimecircuits)
	end
	local hideMrfusionlight = getAccountData(theCurrentAccount, "bttfhv.settings.hideMrfusionlight")
	if hideMrfusionlight then
		setElementData(source, "settings.hideMrfusionlight", hideMrfusionlight)
	end
	local mrfusionsoundwithtcs = getAccountData(theCurrentAccount, "bttfhv.settings.mrfusionsoundwithtcs")
	if mrfusionsoundwithtcs then
		setElementData(source, "settings.mrfusionsoundwithtcs", mrfusionsoundwithtcs)
	end
	local useThreedigitspeedo = getAccountData(theCurrentAccount, "bttfhv.settings.useThreedigitspeedo")
	if useThreedigitspeedo then
		setElementData(source, "settings.useThreedigitspeedo", useThreedigitspeedo)
	end	
	outputChatBox('* ' .. getPlayerName(source) .. ' has joined the game', root, 255, 100, 100)
	outputChatBox('Press F1 to open the window with your personal settings for this server.', source, 0, 0, 255)
	-- striggerClientEvent(source, "onClientPlayerLogin", source)
	triggerClientEvent(source, "correctLogin", source)
end
addEventHandler("onPlayerLogin", getRootElement(), restorePositionFromAccount)

function storePositiontoAccountOnQuit(quitType, reason, responsibleElement)
	local thePreviousAccount = getPlayerAccount(source)
	if thePreviousAccount then
		storePositionToAccount(thePreviousAccount, nil, quitType)
	else
		outputDebugString("Could not get the account of the player to save his position!")
	end
end
addEventHandler("onPlayerQuit", getRootElement(), storePositiontoAccountOnQuit)
--[[
function loadTeams(startedResource)
	local teams = executeSQLSelect("bttfhv_Teams", "name, color_r, color_g, color_b")
	for i=1, #teams, 1 do
		createTeam(teams[i].name, teams[i].color_r, teams[i].color_g, teams[i].color_b)
	end
end
addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), loadTeams)

function saveTeams(stoppedResource)
	local teams = getElementsByType("team")
	if teams then
		executeSQLCreateTable("bttfhv_Teams", "name TEXT, color_r INTEGER, color_g INTEGER, color_b INTEGER")
		executeSQLQuery("DELETE FROM bttfhv_Teams")
		for i=1, #teams, 1 do
			local name = getTeamName(teams[i])
			local r, g, b = getTeamColor(teams[i])
			if name and r and g and b then
				executeSQLInsert("bttfhv_Teams", "'" .. name .. "','" .. tostring(r) .."','" .. tostring(g) .."','" .. tostring(b) .. "'")
			else
				outputDebugString("Could not get either name or color off a team!", 1)
			end
		end
	end
end
addEventHandler("onResourceStop", getResourceRootElement(getThisResource()), saveTeams)
]]
addEvent("onClientAnswersRules", true)
function handleRulesAnswer(answer)
	if (answer == true) then
		local account = getPlayerAccount(source)
		setAccountData(account, "bttfhv.acceptedRules", true)
		triggerClientEvent(source, "closeRulesWindow", source)
	else
		kickPlayer(source, "You did not agree to the server rules!")
	end
end
addEventHandler("onClientAnswersRules", getRootElement(), handleRulesAnswer)

addEvent("onClientSavesSettings", true)
function saveSettings(hideTimecircuits, hideMrfusionlight, mrfusionsoundwithtcs, useThreedigitspeedo)
	local account = getPlayerAccount(source)
	if account then
		if not isGuestAccount(account) then
			local success = setAccountData(account, "bttfhv.settings.hideTimecircuits", tostring(hideTimecircuits))
			if success then
				success = setAccountData(account, "bttfhv.settings.hideMrfusionlight", tostring(hideMrfusionlight))
			end
			if success then
				success = setAccountData(account, "bttfhv.settings.mrfusionsoundwithtcs", tostring(mrfusionsoundwithtcs))
			end
			if success then
				success = setAccountData(account, "bttfhv.settings.useThreedigitspeedo", tostring(useThreedigitspeedo))
			end
			setElementData(source, "settings.hideTimecircuits", hideTimecircuits)
			setElementData(source, "settings.hideMrfusionlight", hideMrfusionlight)
			setElementData(source, "settings.mrfusionsoundwithtcs", mrfusionsoundwithtcs)
			setElementData(source, "settings.useThreedigitspeedo", useThreedigitspeedo)
			triggerClientEvent(source, "onServerSavedSettings", source, success)
		else
			outputChatBox("You need to be logged in to save your settings.", source)
			triggerClientEvent(source, "onServerSavedSettings", source, false)
		end
	else
		outputDebugString("The account for the player '" .. tostring(getPlayerName(source)) .. "' could not be found.", 1)
	end
end
addEventHandler("onClientSavesSettings", getRootElement(), saveSettings)

addEvent("onClientLoadsSettings", true)
function loadSettings()
	local account = getPlayerAccount(source)
	if account then
		if not isGuestAccount(account) then
			local hideTimecircuits = getAccountData(account, "bttfhv.settings.hideTimecircuits")
			local hideMrfusionlight = getAccountData(account, "bttfhv.settings.hideMrfusionlight")
			local mrfusionsoundwithtcs = getAccountData(account, "bttfhv.settings.mrfusionsoundwithtcs")
			local useThreedigitspeedo = getAccountData(account, "bttfhv.settings.useThreedigitspeedo")
			triggerClientEvent(source, "onServerLoadedSettings", source, hideTimecircuits, hideMrfusionlight, mrfusionsoundwithtcs, useThreedigitspeedo)
		else
			outputChatBox("You need to be logged in to load your settings.", source)
		end
	else
		outputDebugString("The account for the player '" .. tostring(getPlayerName(source)) .. "' could not be found.", 1)
	end
end
addEventHandler("onClientLoadsSettings", getRootElement(), loadSettings)

addEvent("onClientChangesPassword", true)
function changePassword(oldPassword, newPassword)
	local account = getAccount(getPlayerName(source), oldPassword)
	if account then
		if not isGuestAccount(account) then
			setAccountPassword(account, newPassword)
			triggerClientEvent(source, "onServerPasswordChanged", source, true, "Your password has been successfully changed!")
		else
			outputChatBox("You need to be logged in to change your password.", source)
		end
	else
		triggerClientEvent(source, "onServerPasswordChanged", source, false, "The password you entered did not match our records!")
		outputDebugString("The account for the player '" .. tostring(getPlayerName(source)) .. "' could not be found.", 1)
	end
end
addEventHandler("onClientChangesPassword", getRootElement(), changePassword)

function rgbToHex ( nR, nG, nB, nA )
    local sColor = "#"
    nR = string.format ( "%X", nR )
    sColor = sColor .. ( ( string.len ( nR ) == 1 ) and ( "0" .. nR ) or nR )
    nG = string.format ( "%X", nG )
    sColor = sColor .. ( ( string.len ( nG ) == 1 ) and ( "0" .. nG ) or nG )
    nB = string.format ( "%X", nB )
    sColor = sColor .. ( ( string.len ( nB ) == 1 ) and ( "0" .. nB ) or nB )
    if not nA then nA = 255 end
	nA = string.format ( "%X", nA )
    sColor = sColor .. ( ( string.len ( nA ) == 1 ) and ( "0" .. nA ) or nA )
    return sColor
end