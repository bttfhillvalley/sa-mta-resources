-- needs configurable blip colors, and team support
root = getRootElement ()
color = { 0, 255, 0 }
players = {}
resourceRoot = getResourceRootElement ( getThisResource () )

function onResourceStart ( resource )
  	for id, player in ipairs( getElementsByType ( "player" ) ) do
		if ( players[player] ) then
			createBlipAttachedTo ( player, 0, 2, players[source][1], players[source][2], players[source][3] )
		else
			createBlipAttachedTo ( player, 0, 2, color[1], color[2], color[3] )
		end
	end
end

function onPlayerSpawn ( spawnpoint )
	if ( players[source] ) then
		createBlipAttachedTo ( source, 0, 2, players[source][1], players[source][2], players[source][3] )
	else
		createBlipAttachedTo ( source, 0, 2, color[1], color[2], color[3] )
	end
	if not ( chosenPlayer ) then
		highlightBlipOn ( getRandomPlayer () )
	end
end

function onPlayerQuit ()
	destroyBlipsAttachedTo ( source )
	if ( source == chosenPlayer ) and ( getPlayerCount () > 1 ) then
		highlightBlipOn ( getRandomPlayer () )
	end
end

function onPlayerWasted ( totalammo, killer, killerweapon )
	destroyBlipsAttachedTo ( source )
	if ( source == chosenPlayer ) then
		if killer then
			givePlayerMoney ( killer, 1210 )
			outputChatBox ( "Congratulations, " .. getPlayerName ( killer ) .. ", you killed the target! You earned yourself $1.21k.", killer, 255, 255, 0)
			highlightBlipOn ( killer )
		else
			if ( getPlayerCount () > 1 ) then
				local newTarget = getRandomPlayer ()
				while ( source == newTarget ) do
					newTarget = getRandomPlayer ()
				end
				highlightBlipOn ( newTarget )
			end
		end
	end
end

function resign ( playerSource, commandName )
	if ( playerSource == chosenPlayer ) then
		local newTarget = getRandomPlayer ()
		while ( playerSource == newTarget ) do
			newTarget = getRandomPlayer ()
		end
		highlightBlipOn ( newTarget )
	end
end

function setBlipsColor ( source, commandName, r, g, b )
	if ( tonumber ( b ) ) then
		color = { tonumber ( r ), tonumber ( g ), tonumber ( b ) }
  		for id, player in ipairs( getElementsByType ( "player" ) ) do
			destroyBlipsAttachedTo ( player )
			if ( players[player] ) then
				createBlipAttachedTo ( player, 0, 2, players[source][1], players[source][2], players[source][3] )
			else
				createBlipAttachedTo ( player, 0, 2, color[1], color[2], color[3] )
			end
		end
	end
end

function setBlipColor ( source, commandName, r, g, b )
	if ( tonumber ( b ) ) then
		destroyBlipsAttachedTo ( source )
		players[source] = { tonumber ( r ), tonumber ( g ), tonumber ( b ) }
  		createBlipAttachedTo ( source, 0, 2, players[source][1], players[source][2], players[source][3] )
	end
end

function highlightBlipOn ( player )
	playerName = getPlayerName ( player )
	local thePlayers = getElementsByType("player")
	for k,v in ipairs(thePlayers) do
		destroyBlipsAttachedTo ( v )
		if ( string.lower ( getPlayerName ( v ) ) == string.lower ( playerName ) ) then
			players[v] = { 255, 0, 0 }
			outputChatBox ( "You are now the target. Good luck surviving! (if you don't want that honor, type /resign)", v, 255, 0, 0)
		else
			players[v] = { 0, 255, 0 }
			outputChatBox ( getPlayerName ( player )  .. " is now the target. Find and kill him!", v, 0, 255, 0)
		end
		createBlipAttachedTo ( v, 0, 2, players[v][1], players[v][2], players[v][3] )
	end
	chosenPlayer = player
end

addCommandHandler ( "setblipscolor", setBlipsColor )
addCommandHandler ( "setblipcolor", setBlipColor )
addCommandHandler ( "resign", resign )
addEventHandler ( "onResourceStart", resourceRoot, onResourceStart )
addEventHandler ( "onPlayerSpawn", root, onPlayerSpawn )
addEventHandler ( "onPlayerQuit", root, onPlayerQuit )
addEventHandler ( "onPlayerWasted", root, onPlayerWasted )

function destroyBlipsAttachedTo(player)
	local attached = getAttachedElements ( player )
	if ( attached ) then
		for k,element in ipairs(attached) do
			if isElement ( element ) then
				if getElementType ( element ) == "blip" then
					destroyElement ( element )
				end
			end
		end
	end
end