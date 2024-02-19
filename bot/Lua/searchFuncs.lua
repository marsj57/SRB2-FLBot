-- Flame
-- Various AI searching functions. Some function names are self explainitory.

local Lib = FLBotLib

-- Look4Spring
-- Flame
--
Lib.Look4Spring = function(mo, dist)
	if not valid(mo) then return end -- Sanity check
	if (mo.state == S_PLAY_SPRING) then return end -- Already springing? Don't do anything else!
	if not dist then dist = 4096<<FRACBITS end -- Searching distance
	
	local lastmo, fdist
	local lastdist = 0
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if not (found.flags & MF_SPRING) then return nil end
		if Lib.searchTarget(found, refmo.player) then return nil end
		if (found.health <= 0) then return nil end
		if not P_CheckSight(refmo, found) then return nil end
		
		fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))
		
		-- Last mobj is closer?
		if (lastmo and (fdist > lastdist)) then return nil end

		-- Found a target
		lastmo = found
		lastdist = fdist
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return lastmo
end

-- Look4Monitors
-- Flame
--
Lib.Look4Monitor = function(mo, dist)
	if not valid(mo) then return end -- Sanity check
	if not dist then dist = 4096<<FRACBITS end -- Searching distance
	
	local lastmo, fdist
	local lastdist = 0
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if not (found.flags & MF_MONITOR) then return nil end
		if Lib.searchTarget(found, refmo.player) then return nil end
		if (found.health <= 0) then return nil end
		if not P_CheckSight(refmo, found) then return nil end
		
		fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))
		
		-- Last mobj is closer?
		if (lastmo and (fdist > lastdist)) then return nil end

		-- Found a target
		lastmo = found
		lastdist = fdist
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return lastmo
end

-- Look4Collect
-- Flame
--
Lib.Look4Collect = function(mo, dist)
	if not valid(mo) then return end -- Sanity check
	if not dist then dist = 4096<<FRACBITS end -- Searching distance

	local lastmo, fdist
	local lastdist = 0
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if Lib.searchTarget(found, refmo.player) then return nil end
		if (found.health <= 0) then return nil end

		if (found.type == MT_PLAYER) then
			-- If it's not REALLY a player, or if it's not alive, just skip it. No point in worrying.
			local p = found.player
			if not valid(p) -- Not a valid player
			or Lib.isInvulnerable(p) -- Player is invulnerable
			or p.spectator then -- Player is a spectator?
				return nil
			end
			-- Team check
			if (gametype == GT_CTF) 
			and (not p.ctfteam
			or (p.ctfteam == refmo.player.ctfteam)) then
				return nil
			elseif (gametype == GT_TEAMMATCH) and (found.color == refmo.color) then
				return nil
			end
			
			-- If player is not close, I cannot see them,
			-- or I don't have the rings to do anything about it anyway...
			-- I do not worry.
			fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))
			if (refmo.player.rings <= 2) or (found.z > (refmo.z + 128<<FRACBITS))
			-- Don't go after them if you're not flashing...
			or (not refmo.player.powers[pw_flashing]
				-- And they're farther then 1024 units from you.
				and fdist > (1024<<FRACBITS))
			or not P_CheckSight(refmo,found) then 
				return nil
			end
			
			-- Otherwise... I worry.
			-- I can't look for rings if I'm being watched.
			-- I must fight, ready or not!
			lastmo = found
			return true

		-- Look for objects!
		elseif (found.type == MT_RING)
		or (found.type == MT_COIN)
		or (found.type == MT_BLUESPHERE)
		or (found.type == MT_FLINGBLUESPHERE)
		--or (found.type == MT_BOMBSPHERE) -- Don't be STUPID now...
		or (found.type == MT_TOKEN)
		or (found.type == MT_EMERALD1)
		or (found.type == MT_EMERALD2)
		or (found.type == MT_EMERALD3)
		or (found.type == MT_EMERALD4)
		or (found.type == MT_EMERALD5)
		or (found.type == MT_EMERALD6)
		or (found.type == MT_EMERALD7)
		or (found.type == MT_FLINGEMERALD)
		or (found.type == MT_EXTRALARGEBUBBLE) then -- Take bubbles too!
			-- Can't see it or don't think you can jump to it? Too bad...
			if not P_CheckSight(refmo,found) then return nil end
			if (found.z > (refmo.z + 128<<FRACBITS)) then return nil end

		elseif (found.flags & MF_MONITOR) then -- Monitor? Go for it.
			-- Can't see it or don't think you can jump to it? Too bad...
			if not P_CheckSight(refmo,found) then return nil end
			if (found.flags & MF_NOCLIP) then return nil end
			if (found.z > (refmo.z + 128<<FRACBITS)) then return nil end

		elseif (found.flags & MF_SPRING) then
			-- Check if a spring is the closest thing to you.
			-- Only use it if you're within stepping distance
			-- as well as closer to you then anything else
			-- that you find... Otherwise, forget it.
			if not P_CheckSight(refmo,found) then return nil end
			if (refmo.state == S_PLAY_SPRING) then return nil end
			if (found.z > (refmo.z + 128<<FRACBITS)) then return nil end

		else
			return nil -- Not an object I need to worry about
		end

		fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))
		
		-- Last mobj is closer?
		if (lastmo and (fdist > lastdist)) then return nil end

		-- Found a target
		lastmo = found
		lastdist = fdist
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return lastmo
end

-- Look4Players
-- Flame
--
Lib.Look4Players = function(mo, dist)
	if not valid(mo) then return end -- Sanity check
	if not dist then dist = 4096<<FRACBITS end -- Searching distance
	
	local lastmo, fdist
	local lastdist = 0
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if not (found.player) then return nil end
		if Lib.searchTarget(found, refmo.player) then return nil end
		if (found.health <= 0) then return nil end
		if not P_CheckSight(refmo, found) then return nil end
		local p = found.player
		if not valid(p) -- Not a valid player
		or Lib.isInvulnerable(p) -- Player is invulnerable		
		or p.spectator then -- Player is a spectator?
			return nil
		end

		-- Team check
		if (gametype == GT_CTF) 
		and (not p.ctfteam
		or (p.ctfteam == refmo.player.ctfteam)) then
			return nil
		elseif (gametype == GT_TEAMMATCH) and (found.color == refmo.color) then
			return nil
		end

		fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))
		
		-- Last mobj is closer?
		if (lastmo and (fdist > lastdist)) then return nil end

		-- Found a target
		lastmo = found
		lastdist = fdist
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return lastmo
end

-- Look4Air
-- Flame
--
Lib.Look4Air = function(mo, dist)
	if not valid(mo) then return end -- Sanity check
	if not dist then dist = 4096<<FRACBITS end -- Searching distance

	local lastmo, fdist
	local lastdist = 0
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		-- Ignore anything EXCEPT bubbles
		if not ((found.type == MT_BUBBLES)
		or (found.type == MT_EXTRALARGEBUBBLE)
		or (found.flags & MF_SPRING)) then -- Springs are an exception
			return nil
		end
		
		if not P_CheckSight(refmo, found) then return nil end -- Can't get it if you can't see it!
		
		fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))

		-- Last mobj is closer?
		if (lastmo and (fdist > lastdist)) then return nil end

		-- Found a target
		lastmo = found
		lastdist = fdist
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return lastmo
end

-- Look4Enemy
-- Flame
--
Lib.Look4Enemy = function(mo, dist)
	if not valid(mo) then return end -- Sanity check
	if not dist then dist = 4096<<FRACBITS end -- Searching distance

	local lastmo, fdist
	local lastdist = 0
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if Lib.searchTarget(found, refmo.player) then return nil end
		
		if not ((found.flags & MF_ENEMY)
		or (found.flags & MF_BOSS))
		or not found.health
		or (not (found.eflags & MFE_VERTICALFLIP) and (found.z >= refmo.z)
		or (found.eflags & MFE_VERTICALFLIP) and (found.z < refmo.z))
		or not P_CheckSight(refmo, found) -- Can't get it if you can't see it!
			return nil
		end
		
		fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))

		-- Last mobj is closer?
		if (lastmo and (fdist > lastdist)) then return nil end

		-- Found a target
		lastmo = found
		lastdist = fdist
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return lastmo
end