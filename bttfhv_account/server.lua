-- when a player connects, set the camera pointing on the map model in the area69 war room
function joinHandler()
	setCameraMatrix(source, 223.71885681152, 1825.2418212891, 10.0, 219.965, 1822.795, 5.5)
	setElementDimension(source, 3)
	fadeCamera(source, true)
	outputChatBox("Welcome to new Back to the Future: Hill Valley Multiplayer", source)
end
addEventHandler("onPlayerJoin", getRootElement(), joinHandler)

-- show the login window to the client if the resource starts
addEvent("onClientBttfhvAccountResourceStarted", true)
function resourceStartHandler(thePlayer)
	-- abort if the player already is signed in
	local account = getPlayerAccount(thePlayer)
	if account and not isGuestAccount(account) then
		return
	end

	-- trigger the client to show the login window
	triggerClientEvent(thePlayer, "showLoginWindow", thePlayer)
end
addEventHandler("onClientBttfhvAccountResourceStarted", getResourceRootElement(getThisResource()), resourceStartHandler)

-- check the login details if the client submits the form
addEvent("submitLogin", true)
function loginHandler(thePlayer, username, password)
	-- abort if data is missing
	if not thePlayer or not username or not password then
		return
	end

	-- abort if the login details are incorrect
	local account = getAccount(username, password)
	if not account then
		triggerClientEvent(thePlayer, "wrongLogin", thePlayer, "Please check your username and password.\nIn case you forgot your password, contact\nthe forum administration on\nhttp://bttfhv.com")
		outputDebugString("'" .. username .. "' tried to login with wrong credentials.")
		return
	end

	if logIn(thePlayer, account, password) then
		-- commented out. This event will be sent from the onPlayerLogin event instead
		-- triggerClientEvent(thePlayer, "correctLogin", thePlayer)
	else
		-- the login failed. But are they logged in already? Trigger the client to close the login window
		if not isGuestAccount(getPlayerAccount(thePlayer)) then
			triggerClientEvent(thePlayer, "correctLogin", thePlayer) -- the player is already logged in, let's just close the login window...
			outputChatBox("Note: You have already been logged in. If the gamemode got restarted while you were in the server it's a good idea to reconnect now and log in again. Otherwise you might be missing functions bound to keys.", thePlayer) -- ...and suggest him to reconnect
		end
	end
end
addEventHandler("submitLogin", getRootElement(), loginHandler)


addEvent("submitRegistration", true)
function registrationHandler(thePlayer, username, password)
	-- check if all necessary parameters were passed
	if not thePlayer or not username or not password then
		return
	end

	-- check if an account with that name already exists
	if getAccount(username) then
		triggerClientEvent(thePlayer, "wrongLogin", thePlayer, "Your account could not be created.\nMaybe this username already exists.")
	end

	-- create the account
	local account = addAccount(username, password)
	
	-- automatically log the player into their new account
	logIn(thePlayer, account, password)
	-- triggerClientEvent(thePlayer, "correctLogin", thePlayer)
end
addEventHandler("submitRegistration", getRootElement(), registrationHandler)

-- when the player logs out of their account or leaves the server, store their position, money, weapons, etc. in their account.
function storePositionToAccount(thePreviousAccount, theCurrentAccount, quitType) -- quitType only available for onPlayerQuit
    if isGuestAccount(getPlayerAccount(source)) then
		return
	end

	--store the player's position
	local posX, posY, posZ = getElementPosition(source)
	setAccountData(thePreviousAccount, "bttfhv.posX", posX)
	setAccountData(thePreviousAccount, "bttfhv.posY", posY)
	setAccountData(thePreviousAccount, "bttfhv.posZ", posZ + 0.5)
	local rotX, rotY, rotZ = getElementRotation(source)
	setAccountData(thePreviousAccount, "bttfhv.rotZ", rotZ)
	setAccountData(thePreviousAccount, "bttfhv.interior", getElementInterior(source))
	setAccountData(thePreviousAccount, "bttfhv.dimension", getElementDimension(source))
	
	-- store their skin
	setAccountData(thePreviousAccount, "bttfhv.skinID", getElementModel(source))

	-- store the player's team, if any
	local team = getPlayerTeam(source)
	if team then
		setAccountData(thePreviousAccount, "bttfhv.team.name", getTeamName(team))
		local r, g, b, a = getTeamColor(team)
		setAccountData(thePreviousAccount, "bttfhv.team.color", rgbToHex(r, g, b, a))
	end

	-- store their inventory
	setAccountData(thePreviousAccount, "bttfhv.money", getPlayerMoney(source))
	setAccountData(thePreviousAccount, "bttfhv.health", getElementHealth(source))
	setAccountData(thePreviousAccount, "bttfhv.armor", getPedArmor(source))
	for i=0, 12, 1 do
		setAccountData(thePreviousAccount, "bttfhv.weapons.slot" .. i .. ".weapon", tostring(getPedWeapon(source, i)))
		setAccountData(thePreviousAccount, "bttfhv.weapons.slot" .. i .. ".ammo", tostring(getPedTotalAmmo(source, i)))
	end

	-- if the game passed a reason for why they were disconnected, add that to the chat message
	if quitType then
		quitType = ' [' .. quitType .. ']'
	else
		local quitType = ''
	end
	outputChatBox('* ' .. getPlayerName(source) .. ' has left the game' .. quitType .. '.', root, 255, 100, 100)
end
addEventHandler("onPlayerLogout", getRootElement(), storePositionToAccount)

-- when the player logs out of their account or leaves the server, store their position, money, weapons, etc. in their account.
function storePositiontoAccountOnQuit(quitType, reason, responsibleElement)
	local thePreviousAccount = getPlayerAccount(source)
	if not thePreviousAccount then	
		outputDebugString("Could not get the account of the player to save his position!")
		return
	end

	storePositionToAccount(thePreviousAccount, nil, quitType)
end
addEventHandler("onPlayerQuit", getRootElement(), storePositiontoAccountOnQuit)

-- when the player logs in to their account restore their position, money, weapons, etc. from their account.
function restorePositionFromAccount(thePreviousAccount, theCurrentAccount, autoLogin)
	-- read the player's position
	local position = {
		X  = getAccountData(theCurrentAccount, "bttfhv.posX"),
		Y = getAccountData(theCurrentAccount, "bttfhv.posY"),
		Z  = getAccountData(theCurrentAccount, "bttfhv.posZ")
	}
	local rotZ = getAccountData(theCurrentAccount, "bttfhv.rotZ")
	local interior = getAccountData(theCurrentAccount, "bttfhv.interior")
	local dimension = getAccountData(theCurrentAccount, "bttfhv.dimension")
	
	-- read their skin
	local skinID = getAccountData(theCurrentAccount, "bttfhv.skinID")
	
	-- read their inventory
	local health = getAccountData(theCurrentAccount, "bttfhv.health")
	local armor = getAccountData(theCurrentAccount, "bttfhv.armor")
	local money = getAccountData(theCurrentAccount, "bttfhv.money")
	
	-- restore the player's team, if any
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
	
	-- if position data was found, spawn the player there. Otherwise spawn them at a random spawnpoint
	if position.X and position.Y and position.Z and rotZ and interior and dimension and theTeam then
		spawnPlayer(source, position.X, position.Y, position.Z, rotZ, skinID, interior, dimension, theTeam)
	else
		exports["bttfhv_spawnmanager"]:spawnPlayerAtSpawnpoint(source, nil, false)
		setPlayerTeam(source, theTeam)
	end
	
	-- restore their inventory
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

	-- Check whether they previously accepted the server rules. 
	-- If they didn't trigger the client the rules window
	local acceptedRules = getAccountData(theCurrentAccount, "bttfhv.acceptedRules")
	if not acceptedRules then
		setTimer(triggerClientEvent, 3000, 1, source, "showRulesWindow", source)
	end

	-- load their preferences
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

	-- output the join and welcome messages to chat
	outputChatBox('* ' .. getPlayerName(source) .. ' has joined the game', root, 255, 100, 100)
	outputChatBox('Press F1 to open the window with your personal settings for this server.', source, 0, 0, 255)
	
	-- trigger the client to close the login window
	-- triggerClientEvent(source, "onClientPlayerLogin", source)
	triggerClientEvent(source, "correctLogin", source)
end
addEventHandler("onPlayerLogin", getRootElement(), restorePositionFromAccount)

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

-- When the player clicks the GUI button to accept the rules, 
-- store it in their account and trigger the client to close the window
addEvent("onClientAnswersRules", true)
function handleRulesAnswer(answer)
	if answer ~= true then
		kickPlayer(source, "You did not agree to the server rules!")
		return
	end

	local account = getPlayerAccount(source)
	setAccountData(account, "bttfhv.acceptedRules", true)
	triggerClientEvent(source, "closeRulesWindow", source)
end
addEventHandler("onClientAnswersRules", getRootElement(), handleRulesAnswer)

-- When the client clicks the save settings GUI button, store them in their account and trigger
-- the client to close the window
addEvent("onClientSavesSettings", true)
function saveSettings(hideTimecircuits, hideMrfusionlight, mrfusionsoundwithtcs, useThreedigitspeedo)
	local account = getPlayerAccount(source)
	if not account then
		outputDebugString("The account for the player '" .. tostring(getPlayerName(source)) .. "' could not be found.", 1)
		return
	end

	-- if the player is logged into an account, store their settings into it
	-- if the are a guest, skip saving them
	if isGuestAccount(account) then
		outputChatBox("You need to be logged in to save your settings.", source)
	else
		setAccountData(account, "bttfhv.settings.hideTimecircuits", tostring(hideTimecircuits))
		setAccountData(account, "bttfhv.settings.hideMrfusionlight", tostring(hideMrfusionlight))
		setAccountData(account, "bttfhv.settings.mrfusionsoundwithtcs", tostring(mrfusionsoundwithtcs))
		setAccountData(account, "bttfhv.settings.useThreedigitspeedo", tostring(useThreedigitspeedo))
	end

	-- apply the settings to the player element to easily read them from other scripts
	setElementData(source, "settings.hideTimecircuits", hideTimecircuits)
	setElementData(source, "settings.hideMrfusionlight", hideMrfusionlight)
	setElementData(source, "settings.mrfusionsoundwithtcs", mrfusionsoundwithtcs)
	setElementData(source, "settings.useThreedigitspeedo", useThreedigitspeedo)

	-- trigger the client to close the settings window
	triggerClientEvent(source, "onServerSavedSettings", source, success)
end
addEventHandler("onClientSavesSettings", getRootElement(), saveSettings)

-- When the player presses the button to show the settings GUI, load the settings from their account and send them to the client
addEvent("onClientLoadsSettings", true)
function loadSettings()
	-- get the player's account
	local account = getPlayerAccount(source)
	if not account then
		outputDebugString("The account for the player '" .. tostring(getPlayerName(source)) .. "' could not be found.", 1)
		return
	end

	-- load their settings
	if isGuestAccount(account) then
		outputChatBox("You need to be logged in to load your settings.", source)
	else
		local hideTimecircuits = getAccountData(account, "bttfhv.settings.hideTimecircuits")
		local hideMrfusionlight = getAccountData(account, "bttfhv.settings.hideMrfusionlight")
		local mrfusionsoundwithtcs = getAccountData(account, "bttfhv.settings.mrfusionsoundwithtcs")
		local useThreedigitspeedo = getAccountData(account, "bttfhv.settings.useThreedigitspeedo")

		-- send the settings to the client so it can open the GUI
		triggerClientEvent(source, "onServerLoadedSettings", source, hideTimecircuits, hideMrfusionlight, mrfusionsoundwithtcs, useThreedigitspeedo)
	end
end
addEventHandler("onClientLoadsSettings", getRootElement(), loadSettings)

-- When the player wants to change their password, verify the old password and update the account with the new one
addEvent("onClientChangesPassword", true)
function changePassword(oldPassword, newPassword)
	-- get the account and verify the old password 
	local account = getAccount(getPlayerName(source), oldPassword)
	if not account then
		triggerClientEvent(source, "onServerPasswordChanged", source, false, "The password you entered did not match our records!")
		outputDebugString("The account for the player '" .. tostring(getPlayerName(source)) .. "' could not be found.", 1)
		return
	end

	-- check if the player is signed in
	if isGuestAccount(account) then
		outputChatBox("You need to be logged in to change your password.", source)
		return
	end

	-- set the new password and trigger the client to show that the password was successfully changed
	setAccountPassword(account, newPassword)
	triggerClientEvent(source, "onServerPasswordChanged", source, true, "Your password has been successfully changed!")
end
addEventHandler("onClientChangesPassword", getRootElement(), changePassword)

-- helper function to convert rgb color values to hex values
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