-- Pseudorandom Numbers Library v1.0 by LJ Sonic

local t, x, y, z, w = 0, 6278, 975, 39207, 45678

rawset(_G, "N_Random", function()
	t = x ^^ (x << 11)
	x, y, z, w = y, z, w, w ^^ (w >> 19) ^^ t ^^ (t >> 8)
	return w
end)

rawset(_G, "N_RandomKey", function(n) return abs(N_Random() % n) end)
rawset(_G, "N_RandomRange", function(a, b) return a + abs(N_Random() % (b - a + 1)) end)
