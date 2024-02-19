-- Flame

local Lib = FLBotLib

/*addHook("MapChange", do
	if (gametyperules & GTR_RINGSLINGER)
		Lib.RemoveBots(server) -- Necessary due to a hardcode glitch
	end
end)*/

addHook("BotTiccmd", function(p, cmd)
	-- Literally only a return statement here.
	-- Bots don't respond if they're DEAD.
	return true
end)

if suckywaypoints then
Lib.registerPreFrameFunc(Lib.updateWaypoints)

for i = MT_YELLOWSPRING, MT_BLUEHORIZ do
	addHook("MobjCollide", function(mo, toucher)
		if (mo.z > (toucher.z + toucher.height)) -- No Z collision? Let's fix that!
		or ((mo.z + mo.height) < toucher.z) then
			return -- Out of range
		end
		Lib.createWaypoint(mo.x, mo.y, mo.z, true)
	end, i)
end

end -- suckywaypoints

-- Makeshift BotTiccmd hook
Lib.registerPrePlayerFunc(function(p)
	if not leveltime then return false end
	if not p.bot or (p.bot == BOT_2PAI) then return false end
	
	p.botleader = nil
	p.targettimer = $ or 0
	local cmd = p.cmd
	
	-- Bots spawn as spectators in gametypes with spectators!
	if (gametyperules & GTR_SPECTATORS)
	and (p.spectator) then 
		cmd.buttons = $ ^^ (BT_ATTACK) -- Spam attack to spawn
		return false -- Don't process anything else.
	end
	
	-- Playerstate stuff
	if (p.playerstate == PST_DEAD) then
		if not valid(p.mo) then return false end
		local mo = p.mo
		if ((mo.z + mo.height) < mo.floorz) then
			cmd.buttons = $ ^^ (BT_JUMP) -- Spam jump to respawn
		end
	elseif (p.playerstate == PST_LIVE) then
		Lib.updateLook(p)
		if (gametype == GT_MATCH) then
			Lib.MatchThink(p, cmd)
		--elseif (gametype == GT_TAG) then
		--	Lib.TagThink(p, cmd)
		else
			Lib.MatchThink(p, cmd)
		end
	end
end)