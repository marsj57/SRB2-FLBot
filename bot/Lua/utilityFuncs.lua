-- Flame
-- Utility Functions to assist with AI Behavior.

local Lib = FLBotLib

-- SetTarget: Sets a target and returns the mobj if valid.
-- Returns a nil value if no target. Can be used in if statements to check conditionals.
-- Flame
--
-- mo (mobj_t)		- source mobj
-- target (mobj_t)		- target mobj
Lib.SetTarget = function(mo, target)
	mo.target = target
	return target
end

-- SetTracer: Same as above, but sets a tracer instead
-- Flame
--
-- mo (mobj_t)		- source mobj
-- tracer (mobj_t)		- target mobj
Lib.SetTracer = function(mo, tracer)
	mo.tracer = tracer
	return tracer
end

-- AngleMove: This determines if the mobj is facing the direction they are travelling or not.
-- Didn't your teacher say to pay attention in Geometry/Trigonometry class? ;)
-- Flame
--
Lib.AngleMove = function(player)
	if not valid(player) then return false end -- Sanity check
	local p = player
	if not valid(p.mo) then return false end
	local mo = p.mo

	local ca = AngleFixed(mo.angle)>>FRACBITS -- Converted Angle

	if (p.rmomx > 0) and (p.rmomy > 0) -- Quadrant 1
	and (ca < 90) then
		return true
	elseif (p.rmomx < 0) and (p.rmomy > 0) -- Quadrant 2
	and (ca >= 90) and (ca < 180) then
		return true
	elseif (p.rmomx < 0) and (p.rmomy < 0) -- Quadrant 3
	and (ca >= 180) and (ca < 270) then
		return true
	elseif (p.rmomx > 0) and (p.rmomy < 0) -- Quadrant 4
	and (ca >= 270) and (ca <= 359) then
		return true
	elseif (p.rmomx > 0) -- Direct Right
	and (ca >= 315) and ((ca <= 359) or (ca < 45)) then
		return true
	elseif (p.rmomx < 0) -- Direct left
	and (ca >= 135) and (ca < 225) then
		return true
	elseif (p.rmomy > 0) -- Direct upwards
	and (ca >= 45) and (ca < 135) then
		return true
	elseif (p.rmomy < 0) -- Direct down
	and (ca >= 225) and (ca < 315) then
		return true
	else
		return false
	end
end

-- look4ClosestMo: Looks for the closest mobj around 'mo'
-- Flame
--
-- mo (mobj_t)			- source mobj
-- dist (fixed_t)		- distance to search (Defaults to 1024*FRACUNITS if not specified)
-- mtype (MT_* type)		- Look for a specific MT_* object?
Lib.Look4ClosestMo = function(mo, dist, mtype)
	if not valid(mo) then return nil end
	if not dist then dist = 1024<<FRACBITS end
	
	local closestmo
	local closestdist = dist
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if mtype and (found.type ~= mtype) then return nil end
		if (found.health <= 0) then return nil end
		--if found.player and found.player.spectator then return nil end
		
		local idist = FixedMul(FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z)), refmo.scale)
		if (idist > dist) then return nil end -- Ignore objects outside of 'dist' range.
		
		if (idist < closestdist) then
			closestmo = found
			closestdist = idist
		end
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return closestmo
end

Lib.isInvulnerable = function(p)
	return p.powers[pw_flashing]
		or p.powers[pw_invulnerability]
		or p.powers[pw_super]
		or (p.playerstate == PST_DEAD)
		or p.exiting
		or p.quittime
end

-- Flame
Lib.GetFFloorTopZAt = function(r, x, y)
	if r.t_slope then return P_GetZAt(r.t_slope, x, y)
	else return r.topheight end
end

-- Flame
Lib.GetFFloorBottomZAt = function(r, x, y)
	if r.b_slope then return P_GetZAt(r.b_slope, x, y)
	else return r.bottomheight end
end

-- CountSectorFOFs
-- Counts the number of FOFs in a given sector.
--
-- From Flame
--
Lib.CountSectorFOFs = function(sector)
	local count = 0
	for rover in sector.ffloors()
		if not (rover.flags & FF_EXISTS) then continue end
		count = $ + 1
	end
	return count
end

-- Check water
-- Almost a full copy of P_MobjCheckWater
Lib.CheckWater = function(mo)
	local waterwasnotset = (mo.watertop == INT32_MAX)
	local wasinwater = (mo.eflags & MFE_UNDERWATER) == MFE_UNDERWATER
	local player = mo.pd.player
	local sector = mo.subsector.sector
	mo.watertop = mo.z - 1000*FRACUNIT
	mo.waterbottom = mo.watertop
	
	if (Lib.CountSectorFOFs(sector)) then -- Count FOFs in the sector
		local topheight, bottomheight
		mo.eflags = $ & ~(MFE_UNDERWATER|MFE_TOUCHWATER)
		for rover in sector.ffloors()
			local topheight, bottomheight
			
			if (not (rover.flags & FF_EXISTS) or not (rover.flags & FF_SWIMMABLE)
				or (((rover.flags & FF_BLOCKPLAYER) and player)
				or ((rover.flags & FF_BLOCKOTHERS) and not player))) then
				continue
			end
			
			topheight = Lib.GetFFloorTopZAt(rover, mo.x, mo.y)
			bottomheight = Lib.GetFFloorBottomZAt(rover, mo.x, mo.y)
			
			if (mo.eflags & MFE_VERTICALFLIP) then
				if (topheight < (mo.z - mo.height/2)) 
				or (bottomheight > (mo.z + mo.height)) then
					continue
				end
			else
				if (topheight < (mo.z)) 
				or (bottomheight > (mo.z + mo.height/2)) then
					continue
				end
			end
			
			-- Set the watertop and waterbottom
			mo.watertop = topheight
			mo.waterbottom = bottomheight
			
			-- Just touching the water?
			if (((mo.eflags & MFE_VERTICALFLIP) and mo.z < bottomheight)
			or (not (mo.eflags & MFE_VERTICALFLIP) and (mo.z + mo.height) > topheight))
				mo.eflags = $ | MFE_TOUCHWATER
			end

			-- Actually in the water?
			if (((mo.eflags & MFE_VERTICALFLIP) and (mo.z - mo.height/2) > bottomheight)
			or (not (mo.eflags & MFE_VERTICALFLIP) and (mo.z + mo.height/2) < topheight))
				mo.eflags = $ | MFE_UNDERWATER
			end
		end
	else
		mo.eflags = $ & ~(MFE_UNDERWATER|MFE_TOUCHWATER)
	end
	
	-- The rest of this code only executes on a water state change.
	if waterwasnotset or not (not (mo.eflags & MFE_UNDERWATER) == wasinwater) then return end
	
	-- Check to make sure you didn't just cross into a sector to jump out of
	-- that has shallower water than the block you were originally in.
	if ((not (mo.eflags & MFE_VERTICALFLIP) and ((mo.watertop - mo.floorz) <= mo.height/2))
	or ((mo.eflags & MFE_VERTICALFLIP) and ((mo.ceilingz - mo.waterbottom) <= mo.height/2))) then
		return
	end
	
	if (P_MobjFlip(mo)*mo.momz < 0) then
		if ((mo.eflags & MFE_VERTICALFLIP and (thingtop - mo.height/2 - mo.momz <= mo.waterbottom))
		or (not (mo.eflags & MFE_VERTICALFLIP) and (mo.z + mo.height/2 - mo.momz >= mo.watertop))) then
			-- Spawn a splash
			local splish
			if (mo.eflags & MFE_VERTICALFLIP) then
				splish = P_SpawnMobj(mo.x, mo.y, mo.waterbottom - FixedMul(mobjinfo[MT_SPLISH].height, mo.scale), MT_SPLISH)
				splish.flags2 = $ | MF2_OBJECTFLIP
				splish.eflags = $ | MFE_VERTICALFLIP
			else
				splish = P_SpawnMobj(mo.x, mo.y, mo.watertop, MT_SPLISH)
				splish.destscale = mo.scale
				P_SetScale(splish, mo.scale)
			end
		end
	elseif (P_MobjFlip(mo)*mo.momz > 0) then
		if (((mo.eflags & MFE_VERTICALFLIP and (thingtop - mo.height/2 - mo.momz > mo.waterbottom))
		or (not (mo.eflags & MFE_VERTICALFLIP) and (mo.z + mo.height/2 - mo.momz < mo.watertop)))
		and not (mo.eflags & MFE_UNDERWATER)) then -- underwater check to prevent splashes on opposite side
			-- Spawn a splash
			local splish
			if (mo.eflags & MFE_VERTICALFLIP) then
				splish = P_SpawnMobj(mo.x, mo.y, mo.waterbottom - FixedMul(mobjinfo[MT_SPLISH].height, mo.scale), MT_SPLISH)
				splish.flags2 = $ | MF2_OBJECTFLIP
				splish.eflags = $ | MFE_VERTICALFLIP
			else
				splish = P_SpawnMobj(mo.x, mo.y, mo.watertop, MT_SPLISH)
				splish.destscale = mo.scale
				P_SetScale(splish, mo.scale)
			end
		end
	end
	
	S_StartSound(mo, sfx_splish) -- And make a sound!
end

Lib.Jump4Air = function(player, cmd)
	if not valid(player) then return end
	local p = player
	if not valid(p.mo) then return end
	local mo = p.mo
	
	local jumping = (p.pflags & PF_JUMPDOWN)
	local onground = P_IsObjectOnGround(mo)
	local momz = P_MobjFlip(mo)*mo.momz
	
	cmd.forwardmove = 0 -- Don't bother moving
	
	-- Use your ability, whatever it is, at full jump height.
	if not onground and not jumping and (momz <= 0) then
		cmd.buttons = $ | BT_JUMP
	elseif onground or (jumping and (momz > 0)) then
		cmd.buttons = $ | BT_JUMP
	end
end

-- Add a new entry to the bot's don't target list.
-- Is this how you do a linked list?
Lib.botDontTarget = function(mo, bot)
	if not valid(mo) or not valid(bot) then return end
	
	bot.targettimer = 0
	
	---- My attempt using a linked list
	--bot.targetlist = { data = mo, timer = 5*TICRATE, next = bot.targetlist }
	--bot.targetlist.last = bot.targetlist
	--Lib.SetTarget(bot.targetlist.data, mo)
	if not bot.targetlist then bot.targetlist = {} end
	table.insert(bot.targetlist, {data = mo, timer = 5*TICRATE})
end

-- Find if mobj on don't target list
Lib.searchTarget = function(mo, bot)
	if not valid(mo) or not valid(bot) then return false end
	
	/*-- My attempt using a linked list
	local l = bot.targetlist
	while l do
		if (l.data == mo) then
			return true
		end
		l = l.next
	end*/
	if not (bot.targetlist) then return end
	for k,v in ipairs(bot.targetlist)
		if (v.data == mo) then
			return true
		end
	end
	return false
end

Lib.updateLook = function(bot)
	if not valid(bot) then return end -- Sanity check
	local b = bot
	if not valid(b.mo) then return end
	local mo = b.mo
	
	if (gametype == GT_COOP) then return end
	
	if suckywaypoints then
	-- Change Waypoints
	if not #waypoints then
		-- I guess you don't need them for this gametype!
	elseif not b.waypoint then
		b.waypoint = waypoints -- Start at the beginning
		b.waydist = FixedHypot(FixedHypot(mo.x - b.waypoint.x, 
										mo.y - b.waypoint.y), 
										mo.z - b.waypoint.z)
	else
		if (FixedHypot(FixedHypot(mo.x - b.waypoint.x, 
								mo.y - b.waypoint.y), 
								mo.z - b.waypoint.z) > b.waydist+(32<<FRACBITS)) then
			-- This loop finds the closest waypoint
			local point = waypoints
			while point do
				if FixedHypot(FixedHypot(mo.x - point.x, 
								mo.y - point.y), 
								mo.z - point.z)
								< FixedHypot(FixedHypot(mo.x - b.waypoint.x, 
									mo.y - b.waypoint.y), 
									mo.z - b.waypoint.z) then
					b.waypoint = point -- Switch to it then!
				end
				point = point.next
			end
		end
		
		-- This loop goes to the next waypoint and accounts for skipping
		local point = b.waypoint
		while point do
			if (mo.subsector.sector == point.sec) -- In the same sector as waypoint?
			-- And it's close enough to switch to the next one?
			and (FixedHypot(FixedHypot(mo.x - point.x, mo.y - point.y), mo.z - point.z) < 128<<FRACBITS)
			and point.next -- And it has a next one?
				bot.waypoint = point.next -- Switch to it then!
				bot.waydist = FixedHypot(FixedHypot(mo.x - b.waypoint.x, 
										mo.y - b.waypoint.y), 
										mo.z - b.waypoint.z)
				-- No skipping springpoints
				if point.next.springpoint then
					break
				end
			end
			point = point.next
		end
	end
	end
	
	-- Add to list
	b.targettimer = $ + 1
	if valid(mo.target) and (b.targettimer >= (5*TICRATE)/2) then
		Lib.botDontTarget(mo.target, b)
	end
	
	-- Iterate through the list
	-- Decrease the timer
	-- If timer runs out, remove it!
	if not (b.targetlist) then return end
	for i = 1, #b.targetlist do
		local l = b.targetlist[i]
		l.timer = $ - 1
		
		/*if FLBotDebug 
		and valid(l.data) then -- Visual
			local fx = P_SpawnMobjFromMobj(l.data,0,0,0,MT_THOK)
			fx.color = mo.color
			fx.tics = 2
		end*/
		if not l.timer then
			table.remove(b.targetlist, i)
			continue -- Only remove one per tic
		end
	end
	/*-- My attempt using a linked list
	local l = b.targetlist
	while l do
		l.timer = $ - 1
		if valid(l.data) then -- Visual
			local fx = P_SpawnMobjFromMobj(l.data,0,0,0,MT_THOK)
			fx.color = mo.color
			fx.tics = 2
		end
		if not l.timer then
			if l.next then
				l.next.last = l.last
			else
				b.targetlist.last = l.last
			end
			
			if not l.last or (l.last == b.targetlist.last) then
				b.targetlist = l.next
			else
				l.last.next = l.next
			end
			return
		end
		l = l.next -- Next in line!
	end*/	
end

if FLBotDebug then
addHook("HUD", function(v)
	if not valid(p) then return end
	if not p.bot then return end
	if not p.targetlist then return end
	drawContentsRecursively(v, p.targetlist, {x=2, y=20})
end)
end