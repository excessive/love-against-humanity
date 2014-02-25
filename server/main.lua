if not love then
	love = {
		event = {
			quit = function() end
		}
	}
	hate = true
end

function love.load()
	local settings = require "settings"
	local irc = require "irc"
	irc:run(settings)
	love.event.quit()
end

if hate then
	love.load()
end
