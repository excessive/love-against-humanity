local Timer = require "libs.hump.timer"
local Chatbox = require "ui.chat"
local UI = require "ui.lobby"

local lobby = {}

local responses = {
	-- channel messages (1xx)
	list = 101,
	create = 102,
	join = 103,
	part = 104,

	-- admin commands (2xx)
	option = 201,
	start = 202,

	-- player commands (3xx)
	sit = 301,
	stand = 302,
	play = 303,
	vote = 304,

	-- errors (4xx)
	not_enough_players = 401,
	game_already_exists = 402,
	forbidden = 403,
	not_found = 404,

	-- misc (6xx)
	help = 601,
	killed = 602,
}

responses.lookup = {}
for k,v in pairs(responses) do
	responses.lookup[v] = k
end

function lobby:check_games()
	Signal.emit("message", self.irc.settings.bot, "!list")
end

function lobby:process_query(sender, full_message, nick)
	local status, message = full_message:match("(%d+): (.+)")
	local channel = message and message:match("(#[%w%d%p]+)") or nil
	local thingies = {
		-- channel messages (1xx)
		list = function(message)
			function trim(s)
				return s:match("^()%s*$") and '' or s:match("^%s*(.*%S)")
			end
			self.games = {}
			for game in message:split(",") do
				local name = trim(game):match("([%w%d%p]+)")
				if name then
					table.insert(self.games, name)
				end
				print(name)
			end
			self:update_games()
		end,
		
		create = function(message)
			if channel then
				self.irc:join_channel(channel)
				self.chat:join_channel(channel)
				print("Joined " .. channel)
			end
		end,
		
		join = function(message)
			if channel then
				self.irc:join_channel(channel)
				self.chat:join_channel(channel)
				print("Joined " .. channel)
			end
		end,

		-- admin commands (2xx)
		option = function(message)
		end,

		-- player commands (3xx)
		play = function(message)
		end,

		-- errors (4xx)
		not_enough_players = function(message)
		end,
		
		game_already_exists = function(message)
			if channel then
				self.irc:join_channel(channel)
				self.chat:join_channel(channel)
				print("Joined " .. channel)
			end
		end,
		
		forbidden = function(message)
		end,
		
		not_found = function(message)
		end,

		-- misc (6xx)
		help = function(message)
		end,
		
		killed = function(message)
		end,
	}
	local rescode = responses.lookup[tonumber(status)]
	local fn = thingies[rescode]
	if fn then
		fn(message)
	end
	print(sender, full_message, nick, status, message, channel)
end

function lobby:process_topic(nick, channel, topic)

end

function lobby:join_game(channel)
	self.irc:join_channel(channel)
	self.chat:join_channel(channel)

	Signal.clear("process_query")
	Signal.clear("process_topic")
	Signal.clear("join_game")

	Gamestate.switch(require "gamestates.gameplay", self.irc, self.chat, channel)
end

function lobby:update_games()
	-- update the UI with the shit in self.games
	self.game_list:Clear()

	for i, name in ipairs(self.games) do
		local text = loveframes.Create("button")
		text.OnClick = function(button)
			local channel = "#inhumanity-" .. button.text
			Signal.emit("join_game", channel)
		end
		text:SetText(name)
		self.game_list:AddItem(text)
	end

	table.sort(self.game_list.children, function(a,b)
		return a.text < b.text
	end)
end

function lobby:enter(prevState, irc, chat)
	loveframes.SetState("lobby")
	
	self.panel = loveframes.Create("panel")
	self.panel:SetState("lobby")
	self.panel:SetPos(305, 5)
	self.panel:SetSize(windowWidth - 310, windowHeight - 215)

	self.game_list = loveframes.Create("list", self.panel)
	self.game_list:SetPos(5, 5)
	self.game_list:SetSize(windowWidth - 320, windowHeight - 215 - 10)

	love.graphics.setBackgroundColor(100, 100, 100)
	self.irc = irc
	self.option_selected = 1
	self.timer = Timer.new()
	self.timer:add(1, function() self:check_games() end)
	self.timer:addPeriodic(30, function() self:check_games() end)
	
	Signal.register("process_query", function(...) self:process_query(...) end)
	Signal.register("process_topic", function(...) self:process_topic(...) end)
	Signal.register("join_game", function(...) self:join_game(...) end)

	self.ui = UI(self.irc)
	self.chat = chat or Chatbox(self.irc.settings)
	self.chat.panel:SetState("lobby")
end

function lobby:update(dt)
	loveframes.update(dt)
	self.timer:update(dt)
	self.irc:update(dt)
	self.chat:update(dt)
end

function lobby:draw()
	loveframes.draw()
	self.ui:draw()
	love.graphics.setColor(255, 255, 255, 255)
end

function lobby:resize(x, y)
	self.ui:resize()
	self.chat:resize()
end

function lobby:keypressed(key, isrepeat)
	if key ~= "tab" then
		loveframes.keypressed(key, isrepeat)
	end
	
	if not self.chat:focus() then
		self.ui:keypressed(key, isrepeat)
	end
	
	if key == "tab" then
		if not self.chat:focus() then
			Signal.emit("ChatFocus")
			self.ui.using_keyboard_navigation = false
		else
			Signal.emit("ChatUnfocus")
			self.ui.using_keyboard_navigation = true
		end
	end
	if key == "return" then
		if self.chat:focus() then
			Signal.emit("ChatSend")
		-- Don't run the action if the user can't see the highlight.
		elseif self.ui.using_keyboard_navigation then
			self.ui.options[self.option_selected].action()
			self.ui.using_keyboard_navigation = false
		end
	end
end

function lobby:keyreleased(key)
	if key ~= "tab" then
		loveframes.keyreleased(key)
	end
end

function lobby:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function lobby:mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function lobby:textinput(text)
	loveframes.textinput(text)
end

return lobby
