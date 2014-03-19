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

function lobby:check_games()
	-- TODO
end

function lobby:process_join(nick, channel)
	local text = loveframes.Create("text")
	text:SetMaxWidth(150)
	text:SetText(nick)
	self.ui.user_list:AddItem(text)

	table.sort(self.ui.user_list.children, function(a,b)
		return a.text < b.text
	end)
end

function lobby:process_part(nick, channel)
	local items = self.ui.user_list.children
	
	for i, item in pairs(items) do
		if item.text == nick then
			self.ui.user_list:RemoveItem(items[i])
		end
	end
end

function lobby:process_quit(nick, message, time)
	-- get list of all channels connected to
	local channel = "#inhumanity"
	self:process_part(nick, channel)
end

function lobby:process_nick(old_nick, new_nick)

end

function lobby:process_names(channel, names)
	print("Users in " .. channel)

	self.ui.user_list:Clear()

	for nick in names:split() do
		local text = loveframes.Create("text")
		text:SetMaxWidth(150)
		text:SetText(nick)
		self.ui.user_list:AddItem(text)
	end

	table.sort(self.ui.user_list.children, function(a,b)
		return a.text < b.text
	end)
end

function lobby:process_query(nick, message, channel)
	local status = message:match("(%d+): .+")
	print(nick, message, channel, status)
end

function lobby:process_topic(nick, channel, topic)

end

function lobby:enter(prevState, irc)
	loveframes.SetState("lobby")
	
	love.graphics.setBackgroundColor(100, 100, 100)
	
	self.irc = irc
	self.option_selected = 1
	self.timer = Timer.new()
	self.timer:addPeriodic(30, function() self:check_games() end)
	self.using_keyboard_navigation = false
	
	Signal.register("process_join", function(...) self:process_join(...) end)
	Signal.register("process_part", function(...) self:process_part(...) end)
	Signal.register("process_quit", function(...) self:process_quit(...) end)
	Signal.register("process_nick", function(...) self:process_nick(...) end)
	Signal.register("process_names", function(...) self:process_names(...) end)
	Signal.register("process_query", function(...) self:process_query(...) end)
	Signal.register("process_topic", function(...) self:process_topic(...) end)

	local channel = self.irc.settings.bot
	self.options = {
		{
			label = "New Lobby",
			enabled = true,
			action = function()
				Signal.emit("message", channel, "!create")
			end
		},{
			label = "List Games",
			enabled = true,
			action = function()
				Signal.emit("message", channel, "!list")
			end
		},{
			label = "Change Name",
			enabled = false,
			action = function()
				-- TODO
			end
		},{
			label = "Quit",
			enabled = true,
			action = function()
				self.irc:quit(true)
				love.event.quit()
			end
		}
	}
	
	self.ui = UI(self.options)
	self.chat = Chatbox(self.irc.settings)
end

function lobby:resize(x, y)
	self.ui:resize_menu()
	self.ui:resize_user_panel()
	self.chat:resize()
end

function lobby:update(dt)
	loveframes.update(dt)
	self.timer:update(dt)
	self.irc:update(dt)
end

function lobby:draw()
	loveframes.draw()
	if self.using_keyboard_navigation then
		for i, option in ipairs(self.options) do
			if i == self.option_selected then
				local x, y = option.GetPos()
				local w, h = option.GetSize()
				if option.type == "textinput" then
					option.SetFocus(true)
				else
					love.graphics.setColor(100, 130, 230, 255)
					love.graphics.rectangle("line", x, y, w, h)
				end
			elseif option.type == "textinput" then
				option.SetFocus(false)
			end
		end
	end
	self.ui:draw_effects()
	love.graphics.setColor(255, 255, 255, 255)
end

function lobby:keypressed(key, isrepeat)
	if key ~= "tab" then
		loveframes.keypressed(key, isrepeat)
	end
	local function prev()
		self.using_keyboard_navigation = true
		self.option_selected = self.option_selected - 1
		if self.option_selected < 1 then
			self.option_selected = #self.options
		end
	end
	local function next()
		self.using_keyboard_navigation = true
		self.option_selected = self.option_selected + 1
		if self.option_selected > #self.options then
			self.option_selected = 1
		end
	end
	if not self.chat:focus() then
		if key == "up" then
			repeat prev() until self.options[self.option_selected].enabled
		end
		if key == "down" then
			repeat next() until self.options[self.option_selected].enabled
		end
		if key == "escape" then
			self.using_keyboard_navigation = false
		end
	end
	if key == "tab" then
		if not self.chat:focus() then
			Signal.emit("ChatFocus")
			self.using_keyboard_navigation = false
		else
			Signal.emit("ChatUnfocus")
			self.using_keyboard_navigation = true
		end
	end
	if key == "return" then
		if self.chat:focus() then
			Signal.emit("ChatSend")
		-- Don't run the action if the user can't see the highlight.
		elseif self.using_keyboard_navigation then
			self.options[self.option_selected].action()
			self.using_keyboard_navigation = false
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
