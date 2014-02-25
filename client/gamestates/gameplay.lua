require "card"

local gameplay = {}

function gameplay:enter(prevState)
	loveframes.SetState("gameplay")
	
	self.cards = {
		Card(12345, "Buttplugs all up in muh grill", false)
	}
end

function gameplay:update(dt)
	loveframes.update(dt)
end

function gameplay:draw()
	for _, card in pairs(self.cards) do
		card:draw()
	end
	
	loveframes.draw()
end

function gameplay:keypressed(key, isrepeat)
	loveframes.keypressed(key, isrepeat)
end

function gameplay:keyreleased(key)
	loveframes.keyreleased(key)
end

function gameplay:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function gameplay:mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function gameplay:textinput(text)
	loveframes.textinput(text)
end

return gameplay
