Gamestate = require "libs.hump.gamestate"
Signal = require "libs.hump.signal"

function love.load()
	require "libs.LoveFrames"

	loveframes.util.SetActiveSkin("LAH")

	Signal.register('resize', function()
		windowWidth		= love.graphics.getWidth()
		windowHeight	= love.graphics.getHeight()
	end)
	
	Signal.emit('resize')

	local title = require "gamestates.title"
	Gamestate.switch(title)
end

local callbacks = {
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
