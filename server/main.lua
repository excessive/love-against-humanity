require "hate"

function love.load()
	local settings = require "settings"
	local LAH = require "games.inhumanity.bot"
	bot = LAH(settings)
	bot:run()

	love.event.quit()
end

if hate then
	love.load()
end
