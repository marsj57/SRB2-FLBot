-- Flame
-- Various console commands for adding / removing AI bots.

-- Clairebun
COM_AddCommand("addbot", function(player, bot, name, skin, color)
	if not(G_AddPlayer)
		CONS_Printf(player, "This command isn't available! Are you using the right build?")
		return
	end
	if bot == nil
		CONS_Printf(player, "addbot <bottype> <name> <skin> <color>")
		CONS_Printf(player, "bottype: 0 None, 1 2P AI, 2 MP AI")
		return
	end
	
	-- Skin
	if skin == nil
		skin = skins[P_RandomRange(0,5)].name
		color = P_RandomRange(1,68)
	end
	if not(skins[tostring(skin)])
		CONS_Printf(player, "Skin "..skin.." does not exist!")
		return
	end
	-- Color
	color = tonumber($)
	if not(color)
		color = nil
	end
	-- name
	if name == nil
		name = skins[skin].realname
	end
	-- bot type
	bot = tonumber($)
	if bot == nil
		bot = BOT_MPAI
	elseif tonumber(bot) == 1
		bot = BOT_2PAI
	elseif tonumber(bot) == 0
		bot = BOT_NONE
	else
		bot = BOT_MPAI
	end
	local newplayer = G_AddPlayer(skin, color, name, bot)
	if newplayer and newplayer.valid
		local t = 
			newplayer.bot == BOT_2PAI and "2P AI"
			or newplayer.bot == BOT_MPAI and "MP AI"
			or newplayer.bot == BOT_NONE and "Standard player"
			or "Unknown type"
		CONS_Printf(player, 'Created '..newplayer.name..' ('..tostring(t)..')')
	else
		CONS_Printf(player, 'Failed to get player instance')
	end
end, COM_ADMIN)

COM_AddCommand("kickbot", function(player, playernum, reason)
	if not(G_RemovePlayer)
		CONS_Printf(player, "This command isn't available! Are you using the right build?")
		return
	end
	if playernum == nil or tonumber(playernum) == nil
		CONS_Printf(player, "kickbot <playernum> <reason>")
		return
	end
	if G_RemovePlayer(tonumber(playernum))
		CONS_Printf(player, "Successfully kicked bot with player number "..playernum)
	else
		CONS_Printf(player, "Player doesn't exist, or is not a bot.")
	end
end, COM_ADMIN)

COM_AddCommand("listbots", do
	for n = 0, 31 do
		local player = players[n]
		if not player 
		or not player.bot then
			continue
		end
		local str = "\x83".."#"..n.."\x80"..": "..player.name.." \x86"
		local str2 = player.bot == BOT_2PAI and "2P AI"
			or player.bot == BOT_2PHUMAN and "2P HUMAN"
			or player.bot == BOT_MPAI and "MP AI"
			or "? ("..player.bot..")"
		print(str..str2)
	end
end, COM_LOCAL)

COM_AddCommand("kickallbots", do
	for n = 0, 31 do
		local player = players[n]
		if not player 
		or not player.bot then
			continue
		end
		COM_BufInsertText(server, "kickbot " .. n)
	end
end, COM_ADMIN)