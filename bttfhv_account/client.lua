local screenWidth, screenHeight = guiGetScreenSize() -- Get the screen resolution

function createLoginWindow()
	loginWindow = guiCreateWindow(screenWidth / 2 - 200, screenHeight / 2 - 95, 400, 190, "Back to the Future Hill Valley: Log In", false)
	guiWindowSetSizable(loginWindow, false)
	guiCreateStaticImage(10, 25, 89, 70, "bttfhv_logo.png", false, loginWindow)
	-- guiCreateLabel(100, 25, 290, 200, "Welcome to our new multiplayer.\nTo play on this server, you need an account on our\nforums. If you already have an account, type in your\ndetails below and click the login button. If not go\nto http://bttfhv.com and register for one.", false, loginWindow)
	guiCreateLabel(100, 25, 295, 200, "Welcome to our new multiplayer.\nThis server uses an account system. To play on it\nyou need to register for an account - don't worry\nit's painless and free! Just type in your desired details\nbelow and click register.", false, loginWindow)
	local passwordLabel = guiCreateLabel(10, 115, 75, 15, "Username:", false, loginWindow)
	local usernameLabel = guiCreateLabel(10, 155, 75, 15, "Password:", false, loginWindow)
	guiSetFont(usernameLabel, "default-bold-small")
	guiSetFont(passwordLabel, "default-bold-small")
	usernameField = guiCreateEdit(90, 109, 200, 30, getPlayerName(getLocalPlayer()), false, loginWindow)
	passwordField = guiCreateEdit(90, 149, 200, 30, "", false, loginWindow)
	guiEditSetMasked(passwordField, true)
	guiEditSetMaxLength(usernameField, 50)
	guiEditSetMaxLength(passwordField, 50)
	registerButton = guiCreateButton(310, 109, 70, 30, "Register", false, loginWindow)
	addEventHandler("onClientGUIClick", registerButton, clientSubmitRegistration, false)
	loginButton = guiCreateButton(310, 149, 70, 30, "Log In", false, loginWindow)
	addEventHandler("onClientGUIClick", loginButton, clientSubmitLoginButton, false)
	addEventHandler("onClientGUIAccepted", usernameField, clientSubmitLoginEnter, false)
	addEventHandler("onClientGUIAccepted", passwordField, clientSubmitLoginEnter, false)
	-- guiSetInputEnabled(false)
	guiSetVisible(loginWindow, false)
end
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
	guiSetVisible(loginWindow, true)
end
addEventHandler("showLoginWindow", getRootElement(), showLoginWindow)
function clientSubmitLoginButton(button, state, absoluteX, absoluteY)
	if (button == "left") and (state == "up") then
		local username = guiGetText(usernameField)
		local password = guiGetText(passwordField)
		if (username ~= "") and (password ~= "") then
			triggerServerEvent("submitLogin", getRootElement(), getLocalPlayer(), username, password)
			guiSetProperty(loginButton, "Disabled", "true")
			guiSetProperty(registerButton, "Disabled", "true")
		else
			guiSetText(wrongLoginText, "You need to enter at least *something*")
			guiSetVisible(wrongLoginWindow, true)
		end
	end
end
function clientSubmitLoginEnter(editBox)
	local username = guiGetText(usernameField)
	local password = guiGetText(passwordField)
	if (username ~= "") and (password ~= "") then
		triggerServerEvent("submitLogin", getRootElement(), getLocalPlayer(), username, password)
		guiSetProperty(loginButton, "Disabled", "true")
		guiSetProperty(registerButton, "Disabled", "true")
	else
		guiSetText(wrongLoginText, "You need to enter at least *something*")
		guiSetVisible(wrongLoginWindow, true)
	end
end
function clientSubmitRegistration(button, state, absoluteX, absoluteY)
	if (button == "left") and (state == "up") then
		local username = guiGetText(usernameField)
		local password = guiGetText(passwordField)
		if (username ~= "") and (password ~= "") then
			triggerServerEvent("submitRegistration", getRootElement(), getLocalPlayer(), username, password)
			guiSetProperty(loginButton, "Disabled", "true")
			guiSetProperty(registerButton, "Disabled", "true")
		else
			guiSetText(wrongLoginText, "You need to enter at least *something*")
			guiSetVisible(wrongLoginWindow, true)
		end
	end
end

function createWrongLoginWindow()
	wrongLoginWindow = guiCreateWindow(screenWidth / 2 - 130, screenHeight / 2 - 75, 260, 150, "Action failed", false)
	guiWindowSetSizable(wrongLoginWindow, false)
	guiSetAlpha(wrongLoginWindow, 255)
	guiSetProperty(wrongLoginWindow, "AlwaysOnTop", "True")
	wrongLoginText = guiCreateLabel(10, 25, 245, 80, "", false, wrongLoginWindow)
	guiLabelSetHorizontalAlign(wrongLoginText, "center", true)
	closeWrongLoginWindowButton = guiCreateButton(125 - 90 / 2, 120, 90, 20, "OK", false, wrongLoginWindow)
	addEventHandler("onClientGUIClick", closeWrongLoginWindowButton, closeWrongLoginWindow, false)
	guiSetVisible(wrongLoginWindow, false)
end
function closeWrongLoginWindow()
	guiSetVisible(wrongLoginWindow, false)
end

addEvent("wrongLogin", true)
function wrongLoginHandler(message)
	guiSetText(wrongLoginText, message)
	guiSetVisible(wrongLoginWindow, true)
	guiSetProperty(loginButton, "Disabled", "false")
	guiSetProperty(registerButton, "Disabled", "false")
end
addEventHandler("wrongLogin", getRootElement(), wrongLoginHandler)

addEvent("correctLogin", true)
function correctLoginHandler(message)
	guiSetInputEnabled(false)
	if isElement(loginWindow) then destroyElement(loginWindow) end
	guiSetVisible(wrongLoginWindow, false)
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

addEvent("showRulesWindow", true)
function showRulesWindow()
	guiSetInputEnabled(true)
	guiSetVisible(rulesWindow, true)
end
addEventHandler("showRulesWindow", getRootElement(), showRulesWindow)
function processRulesAnswer(button, state)
	if (button == "left") and (state == "up") then
		triggerServerEvent("onClientAnswersRules", getLocalPlayer(), guiRadioButtonGetSelected(rulesAgreeRadio))
	end
end
function createRulesWindow()
	rulesWindow = guiCreateWindow(screenWidth / 2 - 297, screenHeight / 2 - 215, 594, 430, "Server Rules", false)
	guiSetAlpha(rulesWindow, 1)
	guiWindowSetSizable(rulesWindow, false)
	guiWindowSetMovable(rulesWindow, false)
	local rulesLabel = guiCreateLabel(31, 29, 539, 34, "To ensure that all players have fun on our server, we have a set of rules. If you know these already then you see this window because they have been updated. Please read the following:", false, rulesWindow)
	guiLabelSetHorizontalAlign(rulesLabel, "left", true)
	local rulesText = guiCreateMemo(26, 69, 541, 324, "1: Don't cheat!\nThere are many methods to cheat in the regular GTA: San Andreas, but it would be unfair to other players if you gave yourself advantages others can't have that easily. The server has methods to detect cheaters and will automatically disconnect them.\n\n2: Speak English! \nThis is an English server. If you want to talk to others via either the textchat or the voicechat, pelase make use of the proper English language. If we see or hear any other languages we will not hesitate to mute you temporarily. If you even after your mute was anulled and you again spam, we might also kick you.\n\n3: Do not spam!\nBoth, the voice and textchat are to talk to other players in a senseful manner. Spammers that post the same messages over and over again will be muted.\n\n4: Respect other players!\nIf people want to experiment alone and in peace, don't go and kill them. If somebody tells you that he wants to be left alone from you, just do leave him alone. Also don't insult other players. Always keep in mind that there's sitting an other person in front of a computer, so show some respect and treat him with respect. Otherwise we will disconnect you from the server.", false, rulesWindow)
	guiMemoSetReadOnly(rulesText, true)
	local rulesDisagreeRadio = guiCreateRadioButton(27, 401, 175, 15, "I do not agree to the rules.", false, rulesWindow)
	guiRadioButtonSetSelected(rulesDisagreeRadio, true)
	rulesAgreeRadio = guiCreateRadioButton(205, 401, 251, 16, "I have read the rules and agree to them.", false, rulesWindow)
	local rulesConfirmButton = guiCreateButton(472, 402, 94, 18, "OK", false, rulesWindow)
	addEventHandler("onClientGUIClick", rulesConfirmButton, processRulesAnswer, false)
	guiSetVisible(rulesWindow, false)
end
addEvent("closeRulesWindow", true)
function closeRulesWindow()
	guiSetVisible(rulesWindow, false)
	guiSetInputEnabled(false)
end
addEventHandler("closeRulesWindow", getRootElement(), closeRulesWindow)

function createSettingsWindow()
	settingsWindow = {}
	settingsWindow["window"] = guiCreateWindow(screenWidth / 2 - 246, screenHeight / 2 - 119, 492, 239, "Back to the Future: Hill Valley Multiplayer Settings", false)
	guiWindowSetSizable(settingsWindow["window"],false)
	settingsWindow["descriptionLabel"] = guiCreateLabel(10, 19, 459, 62, "This is the settings panel for the BTTFHV Multiplayer. \nHere you can change your password, or modify other personal settings, like hiding the TCs if they are off, the plutonium empty gauge if Mr. Fusion is filled, or whether to use a 3 digit instead of a 2 digit only speedometer.", false, settingsWindow["window"])
	guiLabelSetHorizontalAlign(settingsWindow["descriptionLabel"], "left", true)
	settingsWindow["passwordCurrrentEdit"] = guiCreateEdit(9, 102, 130, 24, "", false, settingsWindow["window"])
	guiEditSetMasked(settingsWindow["passwordCurrrentEdit"], true)
	settingsWindow["passwordNewEdit"] = guiCreateEdit(144, 102, 130, 24, "", false, settingsWindow["window"])
	guiEditSetMasked(settingsWindow["passwordNewEdit"], true)
	settingsWindow["passwordConfirmEdit"] = guiCreateEdit(279, 102, 130, 24, "", false, settingsWindow["window"])
	guiEditSetMasked(settingsWindow["passwordConfirmEdit"], true)
	settingsWindow["passwordCurrentLabel"] = guiCreateLabel(9, 85, 130, 15, "Your current password", false, settingsWindow["window"])
	settingsWindow["passwordNewLabel"] = guiCreateLabel(144, 85, 130, 15, "Your new password", false, settingsWindow["window"])
	settingsWindow["passwordConfirmLabel"] = guiCreateLabel(279, 85, 130, 15, "Confirm", false, settingsWindow["window"])
	settingsWindow["passwordSubmitButton"] = guiCreateButton(414, 102, 68, 24, "Submit", false, settingsWindow["window"])
	addEventHandler("onClientGUIClick", settingsWindow["passwordSubmitButton"], submitPasswordChange, false)
	settingsWindow["hideTimecircuitsCheckbox"] = guiCreateCheckBox(9, 135, 464, 15, "Hide the Timecircuits if turned off", false, false, settingsWindow["window"])
	settingsWindow["hideMrfusionlightCheckbox"] = guiCreateCheckBox(9, 152, 464, 15, "Hide the Mr. Fusion empty gauge if it is fuled", false, false, settingsWindow["window"])
	settingsWindow["mrfusionsoundwithtcsCheckbox"] = guiCreateCheckBox(9, 169, 464, 13, "Only play the Mr. Fusion empty sound if the Timecircuits are turned on", false, false, settingsWindow["window"])
	settingsWindow["useThreedigitspeedoCheckbox"] = guiCreateCheckBox(9, 186, 464, 15, "Use a 3 digit instead of a 2 digit speedometer", false, false, settingsWindow["window"])
	settingsWindow["okButton"] = guiCreateButton(272, 206, 100, 23, "OK", false, settingsWindow["window"])
	addEventHandler("onClientGUIClick", settingsWindow["okButton"], saveSettingsWindow, false)
	settingsWindow["cancelButton"] = guiCreateButton(377, 206, 100, 24, "Cancel", false, settingsWindow["window"])
	addEventHandler("onClientGUIClick", settingsWindow["cancelButton"], closeSettingsWindow, false)
	guiSetVisible(settingsWindow["window"], false)
end
function saveSettingsWindow()
	triggerServerEvent("onClientSavesSettings", getLocalPlayer(), guiCheckBoxGetSelected(settingsWindow["hideTimecircuitsCheckbox"]), guiCheckBoxGetSelected(settingsWindow["hideMrfusionlightCheckbox"]), guiCheckBoxGetSelected(settingsWindow["mrfusionsoundwithtcsCheckbox"]), guiCheckBoxGetSelected(settingsWindow["useThreedigitspeedoCheckbox"]))
end
function closeSettingsWindow()
	guiSetVisible(settingsWindow["window"], false)
	guiSetInputEnabled(false)
end
addEvent("onServerSavedSettings", true)
function handleServerSavedSettingsResponse(savingSuccess)
	if savingSuccess then
		closeSettingsWindow()
	else
		outputChatBox("Saving the settings failed!")
	end
end
addEventHandler("onServerSavedSettings", getRootElement(), handleServerSavedSettingsResponse)
function openSettingsWindow()
	guiSetVisible(settingsWindow["window"], true)
	guiSetInputEnabled(true)
end
function loadSettingsWindow()
	triggerServerEvent("onClientLoadsSettings", getLocalPlayer())
end
addEvent("onServerLoadedSettings", true)
function handleServerLoadedSettingsResponse(hideTimecircuits, hideMrfusionlight, mrfusionsoundwithtcs, useThreedigitspeedo)
	if hideTimecircuits then 
		guiCheckBoxSetSelected(settingsWindow["hideTimecircuitsCheckbox"], parseboolean(hideTimecircuits))
	else
		outputDebugString("Loadind the setting 'hideTimecircuitsCheckbox' failed!")
	end
	if hideMrfusionlight then 
		guiCheckBoxSetSelected(settingsWindow["hideMrfusionlightCheckbox"], parseboolean(hideMrfusionlight))
	else
		outputDebugString("Loadind the setting 'hideMrfusionlight' failed!")
	end
	if mrfusionsoundwithtcs then 
		guiCheckBoxSetSelected(settingsWindow["mrfusionsoundwithtcsCheckbox"], parseboolean(mrfusionsoundwithtcs))
	else
		outputDebugString("Loadind the setting 'mrfusionsoundwithtcs' failed!")
	end
	if useThreedigitspeedo then
		guiCheckBoxSetSelected(settingsWindow["useThreedigitspeedoCheckbox"], parseboolean(useThreedigitspeedo))
	else
		outputDebugString("Loadind the setting 'useThreedigitspeedo' failed!")
	end
	openSettingsWindow()
end
addEventHandler("onServerLoadedSettings", getRootElement(), handleServerLoadedSettingsResponse)

function submitPasswordChange()
	local newPassword  = guiGetText(settingsWindow["passwordNewEdit"])
	local confirmPassword = guiGetText(settingsWindow["passwordConfirmEdit"])
	if (newPassword ~= "") and (confirmPassword ~= "") then
		if (newPassword == confirmPassword) then
			local currentPassword = guiGetText(settingsWindow["passwordCurrrentEdit"])
			if (currentPassword ~= "") then
				triggerServerEvent("onClientChangesPassword", getLocalPlayer(), currentPassword, newPassword)
			else
				handleServerPasswordChanged(false, "You need to enter your current password to authorize the password change!")
			end
		else
			handleServerPasswordChanged(false, "The new passwords you entered for confirmation do not match!")
		end
	else
		handleServerPasswordChanged(false, "You need to fill in all three boxes!")
	end
end

addEvent("onServerPasswordChanged", true)
function handleServerPasswordChanged(succes, message)
	guiSetText(wrongLoginText, message)
	guiSetVisible(wrongLoginWindow, true)
	if succes then
		guiSetText(settingsWindow["passwordNewEdit"], "")
		guiSetText(settingsWindow["passwordConfirmEdit"], "")
		guiSetText(settingsWindow["passwordCurrrentEdit"], "")
	end
end
addEventHandler("onServerPasswordChanged", getRootElement(), handleServerPasswordChanged)

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), 
function()
	createLoginWindow()
	createWrongLoginWindow()
	createRulesWindow()
	createSettingsWindow()
	bindKey("F1", "up", loadSettingsWindow)
	triggerServerEvent("onClientBttfhvAccountResourceStarted", getResourceRootElement(getThisResource()), getLocalPlayer(), getLocalPlayer())	
end)

function parseboolean(argument)
	if (argument == "true") or (argument == true) then
		return true
	elseif (argument == "false") or (argument == false) then
		return false
	else
		return argument
	end
end