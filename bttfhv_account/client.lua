 -- Get the screen resolution for centering windows
local g_screenWidth, g_screenHeight = guiGetScreenSize()

-- global variables to hold ui components of the login window
local g_loginWindow, g_usernameField, g_passwordField, g_registerButton, g_loginButton 

-- global variables to hold ui components for the wrong login window
local g_wrongLoginWindow, g_wrongLoginText

-- global variables to hold ui components for the rules window
local g_rulesWindow, g_rulesAgreeRadio

-- global variable to hold ui components for the settings window
local g_settingsWindow = {}

-- create the login window
function createLoginWindow()
	-- create the login window centered on the screen
	g_loginWindow = guiCreateWindow(g_screenWidth / 2 - 200, g_screenHeight / 2 - 95, 400, 190, "Back to the Future Hill Valley: Log In", false)
	guiWindowSetSizable(g_loginWindow, false)
	
	-- add the bttfhv logo to the window
	guiCreateStaticImage(10, 25, 89, 70, "bttfhv_logo.png", false, g_loginWindow)
	
	-- add a descriptive text
	-- guiCreateLabel(100, 25, 290, 200, "Welcome to our new multiplayer.\nTo play on this server, you need an account on our\nforums. If you already have an account, type in your\ndetails below and click the login button. If not go\nto http://bttfhv.com and register for one.", false, g_loginWindow)
	guiCreateLabel(100, 25, 295, 200, "Welcome to our new multiplayer.\nThis server uses an account system. To play on it\nyou need to register for an account - don't worry\nit's painless and free! Just type in your desired details\nbelow and click register.", false, g_loginWindow)

	-- create label for username field
	local usernameLabel = guiCreateLabel(10, 155, 75, 15, "Password:", false, g_loginWindow)
	guiSetFont(usernameLabel, "default-bold-small")
	
	-- create label for password field
	local passwordLabel = guiCreateLabel(10, 115, 75, 15, "Username:", false, g_loginWindow)
	guiSetFont(passwordLabel, "default-bold-small")

	-- create username field
	g_usernameField = guiCreateEdit(90, 109, 200, 30, getPlayerName(getLocalPlayer()), false, g_loginWindow)
	guiEditSetMaxLength(g_usernameField, 50)

	-- create password field
	g_passwordField = guiCreateEdit(90, 149, 200, 30, "", false, g_loginWindow)
	guiEditSetMasked(g_passwordField, true)
	guiEditSetMaxLength(g_passwordField, 50)

	-- create register and login buttons
	g_registerButton = guiCreateButton(310, 109, 70, 30, "Register", false, g_loginWindow)
	g_loginButton = guiCreateButton(310, 149, 70, 30, "Log In", false, g_loginWindow)
	
	-- add event handlers
	addEventHandler("onClientGUIAccepted", g_usernameField, clientSubmitLoginEnter, false)
	addEventHandler("onClientGUIAccepted", g_passwordField, clientSubmitLoginEnter, false)
	addEventHandler("onClientGUIClick", g_registerButton, clientSubmitRegistration, false)
	addEventHandler("onClientGUIClick", g_loginButton, clientSubmitLoginButton, false)
	
	-- hide the window until the server calls for it to be shown
	guiSetVisible(g_loginWindow, false)
end

-- submit the login to the server
function submitLogin()
	local username = guiGetText(g_usernameField)
	local password = guiGetText(g_passwordField)
	if (username ~= "") and (password ~= "") then
		triggerServerEvent("submitLogin", getRootElement(), getLocalPlayer(), username, password)
		guiSetProperty(g_loginButton, "Disabled", "true")
		guiSetProperty(g_registerButton, "Disabled", "true")
	else
		guiSetText(g_wrongLoginText, "You need to enter at least *something*")
		guiSetVisible(g_wrongLoginWindow, true)
	end
end

-- when the player presses the enter button in the text fields, submit the data
function clientSubmitLoginEnter(editBox)
	submitLogin()
end

-- when the player clicks the login button, submit the data
function clientSubmitLoginButton(button, state, absoluteX, absoluteY)
	if (button == "left") and (state == "up") then
		submitLogin()
	end
end

-- when the player clicks the register button, submit the data to the server
function clientSubmitRegistration(button, state, absoluteX, absoluteY)
	if (button == "left") and (state == "up") then
		local username = guiGetText(g_usernameField)
		local password = guiGetText(g_passwordField)
		if (username ~= "") and (password ~= "") then
			triggerServerEvent("submitRegistration", getRootElement(), getLocalPlayer(), username, password)
			guiSetProperty(g_loginButton, "Disabled", "true")
			guiSetProperty(g_registerButton, "Disabled", "true")
		else
			guiSetText(g_wrongLoginText, "You need to enter at least *something*")
			guiSetVisible(g_wrongLoginWindow, true)
		end
	end
end

-- When the server calls for the login window to be visible, show it and hide all other UI components
addEvent("showLoginWindow", true)
function showLoginWindow()
	setPlayerHudComponentVisible("ammo", false)
	setPlayerHudComponentVisible("area_name", false)
	setPlayerHudComponentVisible("armour", false)
	setPlayerHudComponentVisible("breath", false)
	setPlayerHudComponentVisible("clock", false)
	setPlayerHudComponentVisible("health", false)
	setPlayerHudComponentVisible("money", false)
	setPlayerHudComponentVisible("radar", false)
	setPlayerHudComponentVisible("vehicle_name", false)
	setPlayerHudComponentVisible("weapon", false)
	guiSetInputEnabled(true)
	guiSetVisible(g_loginWindow, true)
end
addEventHandler("showLoginWindow", getRootElement(), showLoginWindow)

-- create a window to show when the server answers that the login information is incorrect
function createWrongLoginWindow()
	-- create the wrong login window centered on the screen
	g_wrongLoginWindow = guiCreateWindow(g_screenWidth / 2 - 130, g_screenHeight / 2 - 75, 260, 150, "Action failed", false)
	guiWindowSetSizable(g_wrongLoginWindow, false)
	guiSetAlpha(g_wrongLoginWindow, 255)
	guiSetProperty(g_wrongLoginWindow, "AlwaysOnTop", "True")

	-- add a descriptive text
	g_wrongLoginText = guiCreateLabel(10, 25, 245, 80, "", false, g_wrongLoginWindow)
	guiLabelSetHorizontalAlign(g_wrongLoginText, "center", true)

	-- create a close button
	local closeWrongLoginWindowButton = guiCreateButton(125 - 90 / 2, 120, 90, 20, "OK", false, g_wrongLoginWindow)
	
	-- add event handler
	addEventHandler("onClientGUIClick", closeWrongLoginWindowButton, closeWrongLoginWindow, false)
	
	-- hide the window until the server calls for it to be shown
	guiSetVisible(g_wrongLoginWindow, false)
end

-- close the wrong login window when the player clicks the close button
function closeWrongLoginWindow()
	guiSetVisible(g_wrongLoginWindow, false)
end

-- show the wrong login window when the server requests it
addEvent("wrongLogin", true)
function wrongLoginHandler(message)
	-- apply the error text the server sent
	guiSetText(g_wrongLoginText, message)

	-- show the window
	guiSetVisible(g_wrongLoginWindow, true)

	-- disable the buttons of the login window behind it
	guiSetProperty(g_loginButton, "Disabled", "false")
	guiSetProperty(g_registerButton, "Disabled", "false")
end
addEventHandler("wrongLogin", getRootElement(), wrongLoginHandler)

-- close the login window and reenable the ui components when the server requests it
addEvent("correctLogin", true)
function correctLoginHandler(message)
	-- disable mouse input
	guiSetInputEnabled(false)

	-- destroy the login window - we won't need it anymore
	if isElement(g_loginWindow) then destroyElement(g_loginWindow) end
	
	-- only hide, not destroy the wrong login window
	-- it can be reused for the change password window
	guiSetVisible(g_wrongLoginWindow, false)

	-- reenable the ui components
	setPlayerHudComponentVisible("ammo", true)
	setPlayerHudComponentVisible("area_name", true)
	setPlayerHudComponentVisible("armour", true)
	setPlayerHudComponentVisible("breath", true)
	setPlayerHudComponentVisible("clock", true)
	setPlayerHudComponentVisible("health", true)
	setPlayerHudComponentVisible("money", true)
	setPlayerHudComponentVisible("radar", true)
	setPlayerHudComponentVisible("vehicle_name", true)
	setPlayerHudComponentVisible("weapon", true)
end
addEventHandler("correctLogin", getRootElement(), correctLoginHandler)

-- create a window that shows the server rules and asks the user to accept them
function createRulesWindow()
	-- create the rules window centered on the screen
	g_rulesWindow = guiCreateWindow(g_screenWidth / 2 - 297, g_screenHeight / 2 - 215, 594, 430, "Server Rules", false)
	guiSetAlpha(g_rulesWindow, 1)
	guiWindowSetSizable(g_rulesWindow, false)
	guiWindowSetMovable(g_rulesWindow, false)

	-- add a descriptive label
	local rulesLabel = guiCreateLabel(31, 29, 539, 34, "To ensure that all players have fun on our server, we have a set of rules. If you know these already then you see this window because they have been updated. Please read the following:", false, g_rulesWindow)
	guiLabelSetHorizontalAlign(rulesLabel, "left", true)

	-- add the rules text in a readonly textarea
	local rulesText = guiCreateMemo(26, 69, 541, 324, "1: Don't cheat!\nThere are many methods to cheat in the regular GTA: San Andreas, but it would be unfair to other players if you gave yourself advantages others can't have that easily. The server has methods to detect cheaters and will automatically disconnect them.\n\n2: Speak English! \nThis is an English server. If you want to talk to others via either the textchat or the voicechat, pelase make use of the proper English language. If we see or hear any other languages we will not hesitate to mute you temporarily. If you even after your mute was anulled and you again spam, we might also kick you.\n\n3: Do not spam!\nBoth, the voice and textchat are to talk to other players in a senseful manner. Spammers that post the same messages over and over again will be muted.\n\n4: Respect other players!\nIf people want to experiment alone and in peace, don't go and kill them. If somebody tells you that he wants to be left alone from you, just do leave him alone. Also don't insult other players. Always keep in mind that there's sitting an other person in front of a computer, so show some respect and treat him with respect. Otherwise we will disconnect you from the server.", false, g_rulesWindow)
	guiMemoSetReadOnly(rulesText, true)

	-- add radio buttons to select accepting or denying the rules
	local rulesDisagreeRadio = guiCreateRadioButton(27, 401, 175, 15, "I do not agree to the rules.", false, g_rulesWindow)
	guiRadioButtonSetSelected(rulesDisagreeRadio, true)
	g_rulesAgreeRadio = guiCreateRadioButton(205, 401, 251, 16, "I have read the rules and agree to them.", false, g_rulesWindow)
	
	-- create the button to confirm the selection and add an event handler
	local rulesConfirmButton = guiCreateButton(472, 402, 94, 18, "OK", false, g_rulesWindow)
	addEventHandler("onClientGUIClick", rulesConfirmButton, processRulesAnswer, false)
	
	-- hide the window until the server calls for it to be shown
	guiSetVisible(g_rulesWindow, false)
end

-- send the player's response to the rules to the server
function processRulesAnswer(button, state)
	if (button == "left") and (state == "up") then
		triggerServerEvent("onClientAnswersRules", getLocalPlayer(), guiRadioButtonGetSelected(g_rulesAgreeRadio))
	end
end

-- show the rules window when the server requests it
addEvent("showRulesWindow", true)
function showRulesWindow()
	guiSetInputEnabled(true)
	guiSetVisible(g_rulesWindow, true)
end
addEventHandler("showRulesWindow", getRootElement(), showRulesWindow)

-- close the rules window when the server requests it
addEvent("closeRulesWindow", true)
function closeRulesWindow()
	guiSetVisible(g_rulesWindow, false)
	guiSetInputEnabled(false)
end
addEventHandler("closeRulesWindow", getRootElement(), closeRulesWindow)

-- create the settings window
function createSettingsWindow()
	-- create the login window centered on the screen
	g_settingsWindow["window"] = guiCreateWindow(g_screenWidth / 2 - 246, g_screenHeight / 2 - 119, 492, 239, "Back to the Future: Hill Valley Multiplayer Settings", false)
	guiWindowSetSizable(g_settingsWindow["window"], false)

	-- add a descriptive text
	g_settingsWindow["descriptionLabel"] = guiCreateLabel(10, 19, 459, 62, "This is the settings panel for the BTTFHV Multiplayer. \nHere you can change your password, or modify other personal settings, like hiding the TCs if they are off, the plutonium empty gauge if Mr. Fusion is filled, or whether to use a 3 digit instead of a 2 digit only speedometer.", false, g_settingsWindow["window"])
	guiLabelSetHorizontalAlign(g_settingsWindow["descriptionLabel"], "left", true)

	-- add text fields and labels to change the account password
	g_settingsWindow["passwordCurrentLabel"] = guiCreateLabel(9, 85, 130, 15, "Your current password", false, g_settingsWindow["window"])
	g_settingsWindow["passwordCurrrentEdit"] = guiCreateEdit(9, 102, 130, 24, "", false, g_settingsWindow["window"])
	guiEditSetMasked(g_settingsWindow["passwordCurrrentEdit"], true)
	
	g_settingsWindow["passwordNewLabel"] = guiCreateLabel(144, 85, 130, 15, "Your new password", false, g_settingsWindow["window"])
	g_settingsWindow["passwordNewEdit"] = guiCreateEdit(144, 102, 130, 24, "", false, g_settingsWindow["window"])
	guiEditSetMasked(g_settingsWindow["passwordNewEdit"], true)
	
	g_settingsWindow["passwordConfirmLabel"] = guiCreateLabel(279, 85, 130, 15, "Confirm", false, g_settingsWindow["window"])
	g_settingsWindow["passwordConfirmEdit"] = guiCreateEdit(279, 102, 130, 24, "", false, g_settingsWindow["window"])
	guiEditSetMasked(g_settingsWindow["passwordConfirmEdit"], true)
	
	-- add a submit button to apply the new password
	g_settingsWindow["passwordSubmitButton"] = guiCreateButton(414, 102, 68, 24, "Submit", false, g_settingsWindow["window"])
	
	-- add checkboxes for preferences regarding the rendering of time machine ui elements
	g_settingsWindow["hideTimecircuitsCheckbox"] = guiCreateCheckBox(9, 135, 464, 15, "Hide the Timecircuits if turned off", false, false, g_settingsWindow["window"])
	g_settingsWindow["hideMrfusionlightCheckbox"] = guiCreateCheckBox(9, 152, 464, 15, "Hide the Mr. Fusion empty gauge if it is fuled", false, false, g_settingsWindow["window"])
	g_settingsWindow["mrfusionsoundwithtcsCheckbox"] = guiCreateCheckBox(9, 169, 464, 13, "Only play the Mr. Fusion empty sound if the Timecircuits are turned on", false, false, g_settingsWindow["window"])
	g_settingsWindow["useThreedigitspeedoCheckbox"] = guiCreateCheckBox(9, 186, 464, 15, "Use a 3 digit instead of a 2 digit speedometer", false, false, g_settingsWindow["window"])
	
	-- add buttons to close the window saving or discarding changes
	g_settingsWindow["okButton"] = guiCreateButton(272, 206, 100, 23, "OK", false, g_settingsWindow["window"])
	g_settingsWindow["cancelButton"] = guiCreateButton(377, 206, 100, 24, "Cancel", false, g_settingsWindow["window"])
	
	-- add event handlers
	addEventHandler("onClientGUIClick", g_settingsWindow["okButton"], saveSettingsWindow, false)
	addEventHandler("onClientGUIClick", g_settingsWindow["passwordSubmitButton"], submitPasswordChange, false)
	addEventHandler("onClientGUIClick", g_settingsWindow["cancelButton"], closeSettingsWindow, false)
	
	-- hide the window until the server calls for it to be shown
	guiSetVisible(g_settingsWindow["window"], false)
end

-- send the user preferences to the server
function saveSettingsWindow()
	triggerServerEvent("onClientSavesSettings", getLocalPlayer(), guiCheckBoxGetSelected(g_settingsWindow["hideTimecircuitsCheckbox"]), guiCheckBoxGetSelected(g_settingsWindow["hideMrfusionlightCheckbox"]), guiCheckBoxGetSelected(g_settingsWindow["mrfusionsoundwithtcsCheckbox"]), guiCheckBoxGetSelected(g_settingsWindow["useThreedigitspeedoCheckbox"]))
end

-- close the settings window when the server requests it
function closeSettingsWindow()
	guiSetVisible(g_settingsWindow["window"], false)
	guiSetInputEnabled(false)
end

-- close the settings window if the server successfully saved the preferences
addEvent("onServerSavedSettings", true)
function handleServerSavedSettingsResponse(savingSuccess)
	if savingSuccess then
		closeSettingsWindow()
	else
		outputChatBox("Saving the settings failed!")
	end
end
addEventHandler("onServerSavedSettings", getRootElement(), handleServerSavedSettingsResponse)

-- open the settings window
function openSettingsWindow()
	guiSetVisible(g_settingsWindow["window"], true)
	guiSetInputEnabled(true)
end

-- apply the settings the server sent to the settings window and open it when the server requests it
addEvent("onServerLoadedSettings", true)
function handleServerLoadedSettingsResponse(hideTimecircuits, hideMrfusionlight, mrfusionsoundwithtcs, useThreedigitspeedo)
	if hideTimecircuits then 
		guiCheckBoxSetSelected(g_settingsWindow["hideTimecircuitsCheckbox"], parseboolean(hideTimecircuits))
	else
		outputDebugString("Loadind the setting 'hideTimecircuitsCheckbox' failed!")
	end
	
	if hideMrfusionlight then 
		guiCheckBoxSetSelected(g_settingsWindow["hideMrfusionlightCheckbox"], parseboolean(hideMrfusionlight))
	else
		outputDebugString("Loadind the setting 'hideMrfusionlight' failed!")
	end
	
	if mrfusionsoundwithtcs then 
		guiCheckBoxSetSelected(g_settingsWindow["mrfusionsoundwithtcsCheckbox"], parseboolean(mrfusionsoundwithtcs))
	else
		outputDebugString("Loadind the setting 'mrfusionsoundwithtcs' failed!")
	end
	
	if useThreedigitspeedo then
		guiCheckBoxSetSelected(g_settingsWindow["useThreedigitspeedoCheckbox"], parseboolean(useThreedigitspeedo))
	else
		outputDebugString("Loadind the setting 'useThreedigitspeedo' failed!")
	end
	
	openSettingsWindow()
end
addEventHandler("onServerLoadedSettings", getRootElement(), handleServerLoadedSettingsResponse)


function loadSettingsWindow()
	triggerServerEvent("onClientLoadsSettings", getLocalPlayer())
end

-- verify the user input when the user clicks the password change submit button
function submitPasswordChange()
	-- did the user enter values into the new and confirm password fields?
	local newPassword  = guiGetText(g_settingsWindow["passwordNewEdit"])
	local confirmPassword = guiGetText(g_settingsWindow["passwordConfirmEdit"])
	if newPassword == "" or confirmPassword == "" then
		handleServerPasswordChanged(false, "You need to fill in all three boxes!")
		return
	end

	-- do the values of the new and confirm password fields match?
	if newPassword ~= confirmPassword then
		handleServerPasswordChanged(false, "The new passwords you entered for confirmation do not match!")
		return
	end

	-- did the user enter values into the old password field?
	local currentPassword = guiGetText(g_settingsWindow["passwordCurrrentEdit"])
	if currentPassword == "" then
		handleServerPasswordChanged(false, "You need to enter your current password to authorize the password change!")
		return
	end
		
	-- send old and new password to the server
	triggerServerEvent("onClientChangesPassword", getLocalPlayer(), currentPassword, newPassword)
end

-- clear the password fields when the server requests it
addEvent("onServerPasswordChanged", true)
function handleServerPasswordChanged(succes, message)
	-- (mis)use the wrong login window to show a message if the password was changed
	guiSetText(g_wrongLoginText, message)
	guiSetVisible(g_wrongLoginWindow, true)

	if succes then
		-- clear the text boxes
		guiSetText(g_settingsWindow["passwordNewEdit"], "")
		guiSetText(g_settingsWindow["passwordConfirmEdit"], "")
		guiSetText(g_settingsWindow["passwordCurrrentEdit"], "")
	end
end
addEventHandler("onServerPasswordChanged", getRootElement(), handleServerPasswordChanged)

-- prepare the windows, add keybinds and trigger the server that this resource is ready for action on this client
function onClientResourceStart()
	createLoginWindow()
	createWrongLoginWindow()
	createRulesWindow()
	createSettingsWindow()
	bindKey("F1", "up", loadSettingsWindow)
	triggerServerEvent("onClientBttfhvAccountResourceStarted", getResourceRootElement(getThisResource()), getLocalPlayer(), getLocalPlayer())	
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), onClientResourceStart)

-- helper function to convert text to boolean 
function parseboolean(argument)
	if (argument == "true") or (argument == true) then
		return true
	elseif (argument == "false") or (argument == false) then
		return false
	else
		return argument
	end
end