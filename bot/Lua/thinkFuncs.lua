-- Flame
-- Various AI thinking functions.

local Lib = FLBotLib

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

Lib.BotWander = function(player, cmd)
	if not valid(player) then return end
	local p = player
	if not valid(p.mo) then return end
	local mo = p.mo

	local jumping = (p.pflags & PF_JUMPDOWN)
	local onground = P_IsObjectOnGround(mo)
	local momz = P_MobjFlip(mo)*mo.momz
	
	-- Random interval turning
	if P_RandomChance(FRACUNIT/16) then
		if P_RandomChance(FRACUNIT/2) then
			cmd.angleturn = ($ - 2560) -- Turn right!
		else
			cmd.angleturn = ($ + 2560) -- Turn left!
		end
	end
	mo.angle = $ + (cmd.angleturn<<FRACBITS)
	cmd.angleturn = (mo.angle>>FRACBITS)
	cmd.forwardmove = 50 -- Go full speed. Always
	
	-- Ability specific stuff
	if (p.charability == CA_THOK)
	or (p.charability == CA_HOMINGTHOK) then
		-- Use your ability, whatever it is, at full jump height.
		if not onground and not jumping and (momz <= 0) then
			cmd.buttons = $ | BT_JUMP
		elseif onground or (jumping and (momz > 0)) then
			cmd.buttons = $ | BT_JUMP
		end
	elseif (p.charability == CA_FLY)
		
	end
end

-- MatchThink: Thinker for the match gametype!
-- Flame
Lib.MatchThink = function(player, cmd)
	if not valid(player) then return end
	local p = player
	if not valid(p.mo) then return end
	local mo = p.mo
	
	local jumping = (p.pflags & PF_JUMPDOWN)
	local onground = P_IsObjectOnGround(mo)
	local momz = P_MobjFlip(mo)*mo.momz
	
	if (gamestate ~= GS_LEVEL) -- In a level?
	or paused -- Paused?
		return -- Don't do anything else
	end
	-- Let's start to function like a bot!
	
	-- Targeting
	if not mo.target
	or (mo.target and not mo.target.player)
	or (p.rings <= 5) then
		Lib.SetTarget(mo, nil)
		if (p.powers[pw_underwater] 
		and (p.powers[pw_underwater] < 15*TICRATE)) then
			if not Lib.SetTarget(mo, Lib.Look4Air(mo)) then -- Uh oh... No air?! Try to jump as high as you can, then!
				Lib.Jump4Air(p, cmd)
				return -- Don't process anything else
			end
		elseif (p.rings <= 10) then -- Ring count less than 10?
			Lib.SetTarget(mo, Lib.Look4Collect(mo)) -- Look for collectables
		else -- Ring count above 10? Not under water?
			if Lib.SetTarget(mo, Lib.Look4Players(mo)) -- Target found?
			and (mo.target.state == S_PLAY_SPRING) then -- Target "escaping"?
				Lib.SetTarget(mo, Lib.Look4Spring(mo)) -- Try to follow your target.
			elseif not (mo.target) then -- No target?
				Lib.SetTarget(mo, Lib.Look4Collect(mo)) -- Look for something else
			end
		end
	end
	
	-- STILL No Target?
	if not mo.target then
		Lib.BotWander(p, cmd) -- Wander around I guess..
		return
	else -- Cool, we maintained our target this tic!
		-- If we didn't lose sight of our target, try to keep it!
		if not P_CheckSight(mo, mo.target) -- Alas, if we can no longer see our target...
		or (mo.target.player 
		and Lib.isInvulnerable(mo.target.player)) then -- Or they can't be hit.
			Lib.SetTarget(mo, nil) -- Assume it no longer exists.
			return -- Don't process anything else
		end
	end
	
	-- Target info
	local target = mo.target -- From here on out, refer to mo.target as just target
	local dist = R_PointToDist2(mo.x, mo.y, target.x, target.y)
	local zdiff = (target.z - mo.z)
	local zaim = R_PointToAngle2(0, 0, dist, zdiff)
	dist = $>>FRACBITS -- Simple numbers for later checks.
	local angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
	local nextsector = R_PointInSubsector(mo.x + (mo.momx*3), mo.y + (mo.momy*3)).sector
	
	-- Turning movement
	local aimed = false
	if not player.climbing
		if ((mo.angle - ANG10) - angle > angle - (mo.angle - ANG10)) then
			cmd.angleturn = ($ - 2560) -- Turn right!
		elseif ((mo.angle + ANG10) - angle < angle - (mo.angle + ANG10)) then
			cmd.angleturn = ($ + 2560) -- Turn left!
		elseif (Lib.AngleMove(p)) then
			aimed = true
		end
		mo.angle = $ + (cmd.angleturn<<FRACBITS)
		cmd.angleturn = (mo.angle>>FRACBITS)
	end
	--cmd.angleturn = $ | 1

	-- Ability stuff
	local abilityjump = false
	if (p.charability == CA_THOK)
	or (p.charability == CA_HOMINGTHOK) then -- Thok
		if (target.flags & MF_SPRING) -- No thok over spring!
		or (target.type == MT_EXTRALARGEBUBBLE)
		or (p.rings <= 5) then -- No thok over rings if no ammo!
			-- Don't do anything else here

		elseif (aimed 
		and not ((mo.z <= mo.floorz) or p.powers[pw_tailsfly]) 
		and not jumping
		and (momz <= 0)) then -- Thok!
			cmd.buttons = $ | BT_JUMP
			abilityjump = true -- Ability is controlling jump button!
		elseif ((not jumping
		and ((mo.z <= mo.floorz) or p.powers[pw_tailsfly]))
		or (jumping and (momz > 0))) then
			cmd.buttons = $ | BT_JUMP -- Jump to full height!
			abilityjump = true -- Ability is controlling jump button!
		else
			cmd.buttons = $ & ~BT_JUMP -- Ready the jump button!
			abilityjump = true -- Ability is controlling jump button!
		end

	elseif (p.charability == CA_FLY) -- Fly
	or (p.charability == CA_SWIM) then -- Swim
		if ((target.flags & MF_SPRING) -- No fly over spring!
		or ((p.charability == CA_SWIM) -- No swim out of water!
		and not (mo.eflags & MFE_UNDERWATER))
		or p.rings <= 10) then -- No snipe without ammo!
			-- Don't do anything else here

		elseif (not ((mo.z <= mo.floorz) or p.powers[pw_tailsfly]) 
		and not jumping and (momz <= 0)) then
			cmd.buttons = $ | BT_JUMP -- Fly!
			abilityjump = true -- Ability is controlling jump button!
		elseif ((not jumping
		and ((mo.z <= mo.floorz) or p.powers[pw_tailsfly])) 
		or (jumping and (momz > 0))) then
			cmd.buttons = $ | BT_JUMP -- Jump to full height!
			abilityjump = true -- Ability is controlling jump button!
		else
			cmd.buttons = $ & ~BT_JUMP -- Ready the jump button!
			abilityjump = true -- Ability is controlling jump button!
		end
		
	/*elseif (p.charability == CA_GLIDEANDCLIMB) then -- Glide and climb
		if ((target.flags & MF_SPRING) -- No glide over spring!
		or (target.type == MT_EXTRALARGEBUBBLE)) then
			-- Break away from this statement
		elseif ((target.z > mo.z) -- Target still above you
		and not ((mo.z <= mo.floorz) or p.powers[pw_tailsfly])
		and not jumping -- You're in the air but not holding the jump button
		and (momz <= 0)) -- You aren't gonna get high enough
		or (p.pflags & PF_GLIDING) then -- Or are you already gliding?
			-- So what do you do? Glide I guess... I dunno.
			cmd.buttons = $ | BT_JUMP
			abilityjump = true
		end*/
	elseif (p.charability == CA_DOUBLEJUMP) then -- Double-Jump
		if (not ((mo.z <= mo.floorz) or p.powers[pw_tailsfly]) 
		and not jumping and (momz <= 0)) then
			cmd.buttons = $ | BT_JUMP -- Jump again at top of jump height!
		end
	elseif (p.charability2 == CA2_MELEE) -- Amy Hammer
		if (target.type == MT_EXTRALARGEBUBBLE)
		or (target.flags & MF_SPRING)
		or (p.rings <= 5) then -- No thok over rings if no ammo!
			-- Don't do anything else here

		elseif (dist < (target.radius*3)>>FRACBITS) -- If you're close to your target
		and ((target.flags & MF_MONITOR) -- And it needs to be popped
		or ((target.flags & MF_ENEMY) -- Or it's An enemy...
		or (target.flags & MF_BOSS)
		and not (target.flags2 & MF2_FRET))) -- That's NOT FLASHING
			cmd.buttons = $ | BT_SPIN -- Use your Melee!
			abilityjump = true
		else
			cmd.buttons = $ & ~BT_SPIN
		end
	else
		-- Do nothing
	end

	-- Forward movement
	if (momz > 0 and not jumping) -- If you're bouncing on a spring...
	and (mo.state == S_PLAY_SPRING) then -- And you're already moving in a direction from it...
		cmd.forwardmove = 0 -- Do nothing. Moving could ruin it.
	elseif (GetSecSpecial(nextsector.special, 1) >= 1) -- If the next sector
	and (GetSecSpecial(nextsector.special, 1) < 9) then -- is HARMFUL to you...
			cmd.forwardmove = -50/NEWTICRATERATIO -- STOP RUNNING TWARDS IT! AGH!
	elseif (not aimed and not target.player) then -- If you're not aimed properly at something that isn't a person...
		cmd.forwardmove = 25/NEWTICRATERATIO -- Start slowing down.
	else -- Otherwise...
		cmd.forwardmove = 50/NEWTICRATERATIO -- Go full speed. Always.
	end

	-- Jumping stuff
	if (abilityjump) -- Ability has changed the state of your jump button already?
		 -- Then don't mess with it!
	elseif (not ((mo.z <= mo.floorz) or p.powers[pw_tailsfly]) 
	and not jumping) then -- In the air but not holding the jump button?
		cmd.buttons = $ & ~BT_JUMP -- Don't press it again, then.
	elseif (nextsector.floorheight > mo.z -- If the next sector is above you...
	and (nextsector.floorheight - mo.z) < 128*FRACUNIT) then -- And you can jump up on it...
		cmd.buttons = $ | BT_JUMP -- Then jump!
	elseif (target.z > mo.z -- If your target's still above you...
	and jumping -- And you're already holding the jump button...
	and momz > 0) then -- And you're still jumping, and still going up...
		cmd.buttons = $ | BT_JUMP -- Continue to do so!
	elseif (target.z > (mo.z + mo.height) -- If your target is above your head...
	and not jumping -- And you're not jumping already...
	and target.state ~= S_PLAY_SPRING) then -- And they didn't just fly off a spring...
		cmd.buttons = $ | BT_JUMP -- Then jump!
	elseif ((target.flags & MF_ENEMY) -- If the target
	or (target.flags & MF_BOSS) -- NEEDS to be popped...
	or (target.flags & MF_MONITOR))
	and (dist < 128) -- And you're getting close to it...
	and not jumping then -- And you're not already jumping...
		cmd.buttons = $ | BT_JUMP -- Then jump!
	else -- Otherwise...
		cmd.buttons = $ & ~BT_JUMP -- I guess you shouldn't be jumping, then...
	end
	
	-- Aiming stuff
	if target.player then
		cmd.aiming = zaim>>FRACBITS
	end
	
	-- Shooting stuff
	if (cmd.buttons & BT_ATTACK) then -- If you're pressing the attack button
		cmd.buttons = $ & ~BT_ATTACK -- DO NOT HOLD THE BUTTON DOWN
	elseif aimed -- If you're properly aimed...
	and target.player -- At a player...
	and (p.rings > 2) then -- And you have at least one ring to spare...
		cmd.buttons = $ | BT_ATTACK
	end
end