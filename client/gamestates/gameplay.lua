require "card"

local gameplay = {}

function process_query(...)

end

function process_topic(...)

end

function leave_game(channel)
	self.irc:part_channel(channel)
	self.chat:part_channel(channel)

	Signal.clear("process_query")
	Signal.clear("process_topic")
	Signal.clear("leave_game")

	Gamestate.switch(require "gamestates.lobby", self.irc)
end

function gameplay:enter(prevState, irc, chat)
	loveframes.SetState("gameplay")
	self.irc = irc
	self.chat = chat
	self.chat.panel:SetState("gameplay")
	
	self.cards = {
		Card(12345, "Buttplugs all up in muh grill", false)
	}

	Signal.register("process_query", function(...) self:process_query(...) end)
	Signal.register("process_topic", function(...) self:process_topic(...) end)
	Signal.register("leave_game", function(...) self:leave_game(...) end)
end

function gameplay:update(dt)
	loveframes.update(dt)
	self.irc:update(dt)
	self.chat:update(dt)
end

function gameplay:draw()
	for _, card in pairs(self.cards) do
		card:draw()
	end
	
	loveframes.draw()
end

function gameplay:resize(x, y)
	self.chat:resize()
end

function gameplay:keypressed(key, isrepeat)
	if key ~= "tab" then
		loveframes.keypressed(key, isrepeat)
	end

	if key == "tab" then
		if not self.chat:focus() then
			Signal.emit("ChatFocus")
		else
			Signal.emit("ChatUnfocus")
		end
	end
	if key == "return" then
		if self.chat:focus() then
			Signal.emit("ChatSend")
		end
	end
end

function gameplay:keyreleased(key)
	if key ~= "tab" then
		loveframes.keyreleased(key)
	end
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
