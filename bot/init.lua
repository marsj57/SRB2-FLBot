-- Flame

if not FLBot then
	for _, filename in ipairs({
		"global.lua",
		"console.lua",
		"waypointFuncs.lua",
		"utilityFuncs.lua",
		"searchFuncs.lua",
		"thinkFuncs.lua",
		"executeFuncs.lua"
	}) do
		dofile(filename)
	end
else
	print("Another instance of Flame's Bot AI! Duplicate script loading aborted!")
end
