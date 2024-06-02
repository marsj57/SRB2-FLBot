-- Flame

local Lib = FLBotLib

if suckywaypoints then
local defaultWaypointData = {
	__index = {
		x = 0,
		y = 0,
		z = 0,
		sec = false,
		springpoint = nil,
		next = nil
	}
}
registerMetatable(defaultWaypointData)
rawset(_G, "waypoints", setmetatable({}, defaultWaypointData))
rawset(_G, "lastpoint", setmetatable({}, defaultWaypointData))

addHook("MapLoad", do
	waypoints = setmetatable({}, defaultWaypointData)
	lastpoint = setmetatable({}, defaultWaypointData)
end)

Lib.createWaypoint = function(x, y, z, spring)
	local ss = R_PointInSubsectorOrNil(x,y)

	lastpoint = {
		x = x,
		y = y,
		z = z,
		sec = ss and ss.sector or nil,
		sprintpoint = spring,
	}
	waypoints = {
		x = x,
		y = y,
		z = z,
		sec = ss and ss.sector or nil,
		sprintpoint = spring,
		next = waypoints
	}
	if FLBotDebug then
	-- Visual
	local t = P_SpawnMobj(x,y,z,MT_THOK)
	t.tics = 5*TICRATE
	t.fuse = t.tics
	t.color = P_RandomKey(#skincolors)
	end
end

Lib.updateWaypoints = function()
	if (gametype ~= GT_RACE) then return end
	for p in players.iterate
		if (p.spectator or p.bot) then continue end -- Something has gone horribly wrong
		
		if (p.exiting and lastpoint) then continue end
		
		if not valid(p.mo) then continue end
		local mo, cmd = p.mo, p.cmd
		-- If the player has gone further, add a new waypoint!
		local pat = AngleFixed(cmd.angleturn<<FRACBITS)>>FRACBITS
		local pang = AngleFixed(mo.angle)>>FRACBITS

		if not lastpoint
		or (((pat ~= pang) or cmd.sidemove)
		and (FixedHypot(lastpoint.x - mo.x, lastpoint.y - mo.y) > 128*FRACUNIT)
		or (abs(mo.z - lastpoint.z) > MAXSTEPMOVE) and (p.pflags & PF_JUMPED)) then
			Lib.createWaypoint(mo.x, mo.y, mo.z, false)
		end
	end
end

/*addHook("HUD", function(v)
	if waypoints then
		drawContentsRecursively(v, waypoints, {x=0, y=0})
	end
end)*/
end