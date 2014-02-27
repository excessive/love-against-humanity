local class = require "libs.hump.class"

local Database_Dummy = class {}

function Database_Dummy:init()
	-- TODO
end

function Database_Dummy:pick_card(type)
	return { id = math.random(), draw = 1 }
end

return Database_Dummy
