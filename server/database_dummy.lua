local class = require "libs.hump.class"

local Database_Dummy = class {}

function Database_Dummy:init()
	print("WARNING: DUMMY DATABASE DRIVER SELECTED.")
end

function Database_Dummy:pick_card(type, packs)
	print("WARNING: DUMMY DATABASE DRIVER SELECTED.")
	return { id = math.random(), draw = 1 }
end

function Database_Dummy:get_packs()
	print("WARNING: DUMMY DATABASE DRIVER SELECTED.")
	return {}
end

return Database_Dummy
