-- Flame
-- Core of this script. Without these, the script may not even run!

rawset(_G, "FLBot", {})
rawset(_G, "FLBotLib", {})
local Lib = FLBotLib
rawset(_G, "FLBotDebug", 1)
rawset(_G, "suckywaypoints", true)

-- NOTE:
-- Order of hook operations is as follows
-- BotTiccmd -> BotAI -> PreThinkFrame -> PlayerThink -> MobjThinker -> FollowMobj -> ThinkFrame -> PostThinkFrame

rawset(_G, "valid", function(th)
	return th and th.valid
end)

-- Lach
-- Freeslots something without making duplicates
local function CheckSlot(item) -- this function deliberately errors when a freeslot does not exist
	if _G[item] == nil -- this will error by itself for states and objects
		error() -- this forces an error for sprites, which do actually return nil for some reason
	end
end

rawset(_G, "SafeFreeslot", function(...)
	for _, item in ipairs({...})
		if pcall(CheckSlot, item)
			print("\131NOTICE:\128 " .. item .. " was not allocated, as it already exists.")
		else
			freeslot(item)
		end
	end
end)
-- End Lach

rawset(_G, "createFlags", function(tname, t)
    for i = 1,#t do
		rawset(_G, t[i], 2^(i-1))
		table.insert(tname, {string = t[i], value = 2^(i-1)} )
    end
end)

rawset(_G, "createEnum", function(tname, t, from)
    if from == nil then from = 0 end
    for i = 1,#t do
		rawset(_G, t[i], from+(i-1))
		table.insert(tname, {string = t[i], value = from+(i-1)} )
    end
end)

-- Table sorting
-- Flame, 5-16-21
rawset(_G, "spairs", function(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end)

rawset(_G, "copyTable", function(o)
    local copy = {}
    for k, v in pairs(o)
        if (type(v) == "table")
            copy[k] = copyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end)

-- Set table container
Lib.preframeFuncs = {}
Lib.preplayerFuncs = {}
Lib.frameFuncs = {}
Lib.playerFuncs = {}
Lib.hudFuncs = {}

-- PreThinkFrame funcs
Lib.registerPreFrameFunc = function(fn)
	assert(type(fn) == "function", "Attempting to register non function value")
	table.insert(Lib.preframeFuncs, fn)
end

Lib.registerPrePlayerFunc = function(fn)
	assert(type(fn) == "function", "Attempting to register non function value")
	table.insert(Lib.preplayerFuncs, fn)
end

-- ThinkFrame funcs
Lib.registerFrameFunc = function(fn)
	assert(type(fn) == "function", "Attempting to register non function value")
	table.insert(Lib.frameFuncs, fn)
end

Lib.registerPlayerFunc = function(fn)
	assert(type(fn) == "function", "Attempting to register non function value")
	table.insert(Lib.playerFuncs, fn)
end

-- HUD
Lib.registerHudFunc = function(fn)
	assert(type(fn) == "function", "Attempting to register non function value")
	table.insert(Lib.hudFuncs, fn)
end

addHook("PreThinkFrame", do
	-- run global functions:
	if gamestate ~= GS_LEVEL return end	-- what the fuck.
	--if not valid(server) return end	-- also what the fuck.

	for i = 1, #Lib.preframeFuncs
		local fn = Lib.preframeFuncs[i]
		local run, res = pcall(fn)
		if not run
			print("\x82".."WARNING".."\x80"..": FLBotLib.preframeFuncs #"..i..": "..res)
		end
	end

	-- run player functions:
	for p in players.iterate do
		for i = 1, #Lib.preplayerFuncs
			local fn = Lib.preplayerFuncs[i]
			local run, res = pcall(fn, p)
			if not run
				print("\x82".."WARNING".."\x80"..": FLBotLib.preplayerFuncs #"..i..": "..res)
			end
		end
	end
end)

addHook("ThinkFrame", do
	-- run global functions:
	if gamestate ~= GS_LEVEL return end	-- what the fuck.
	if not valid(server) return end	-- also what the fuck.
	
	for i = 1, #Lib.frameFuncs
		local fn = Lib.frameFuncs[i]
		local run, res = pcall(fn)
		if not run
			print("\x82".."WARNING".."\x80"..": FLBotLib.frameFuncs #"..i..": "..res)
		end
	end
	
	-- run player functions:
	for p in players.iterate do
		for i = 1, #Lib.playerFuncs
			local fn = Lib.playerFuncs[i]
			local run, res = pcall(fn, p)
			if not run
				print("\x82".."WARNING".."\x80"..": FLBotLib.playerFuncs #"..i..": "..res)
			end
		end
	end
end)

addHook("HUD", function(v, p, c)
	for i = 1, #Lib.hudFuncs
		local fn = Lib.hudFuncs[i]
		local run, res = pcall(fn, v, p, c)	--fn(v, p, c)
		if not run
			print("\x82".."WARNING".."\x80"..": FLBotLib.hudFuncs: #"..i..": "..res)
		end
	end
end, "game")

if FLBotDebug then
-- Amperbee
local dict = {
	["nil"] = "nil",
	["boolean"] = "bool",
	["number"] = "int",
	["string"] = "str",
	["function"] = "func",
	["userdata"] = "udata",
	["thread"] = "thrd",
	["table"] = "table",
}
rawset(_G, "drawContentsRecursively", function(dw, t, s)
	-- draws table t recursively
	-- dw must be a drawer, t must be a table, s must be a table
	-- ensure s is already populated with position, do not modify during runtime
	-- s = state
	
	--if s == nil then error("argument #3 is missing",2) end
	if s.level == nil then
		s.level = 0
	end
	
	local levelpush = s.level*4
	
	if next(t) == nil then
		dw.drawString(s.x + levelpush, s.y,
			"\134".."[empty]",
		V_ALLOWLOWERCASE, "small")
		s.y = $+4
		return
	end
	if t._HIDE then
		dw.drawString(s.x + levelpush, s.y,
			"\134".."[hidden]",
		V_ALLOWLOWERCASE, "small")
		s.y = $+4
		return
	end
	for k,v in pairs(t) do
		local vstr = tostring(v)
		local vtype,utype = type(v),""
		
		local hex = vstr:sub(-8,-1)
		local pre,post = dict[vtype],vstr
		
		if vtype == "userdata" then
			utype = userdataType(v)
			post = utype.." "..hex
			--if utype ~= "unknown" then post = utype end
		elseif vtype == "table" then
			--post = hex.." #"..#v
			post = hex
			pre = $.."["..#v.."]"
		elseif vtype == "function" or vtype == "thread" then
			post = hex
		end
		
		
		
		dw.drawString(s.x + levelpush, s.y,
			("\130%s \128%s \131%s"):format(pre, tostring(k), post),
		V_ALLOWLOWERCASE, "small")
		
		s.y = $+4
		if vtype == "table" then
			s.level = $+1
			drawContentsRecursively(dw, v, s)
			s.level = $-1
		end
	end
end)
end