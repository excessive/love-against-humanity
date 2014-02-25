require "irc"
require "libs.LoveFrames"
Gamestate = require "libs.hump.gamestate"
Signal = require "libs.hump.signal"

function love.load()
	Signal.register('resize', function()
		windowWidth		= love.graphics.getWidth()
		windowHeight	= love.graphics.getHeight()
	end)
	
	Signal.emit('resize')

	local gameplay = require("gamestates.gameplay")
	Gamestate.switch(gameplay)
end

local callbacks = {
	"errhand", "threaderror",
	"focus", "visible", "resize",
	"textinput", "keypressed", "keyreleased",
	"mousepressed", "mousereleased", "mousefocus",
	"joystickpressed", "joystickreleased",
	"joystickadded", "joystickremoved",
	"joystickaxis", "joystickhat",
	"gamepadpressed", "gamepadreleased", "gamepadaxis",
	"update", "draw",
	"quit"
}

for _, callback in ipairs(callbacks) do
	love[callback] = function(...)
		Signal.emit(callback, ...)
		Gamestate[callback](...)
	end
end
