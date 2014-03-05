local Timer = require "libs.hump.timer"
local Chatbox = require "ui.chat"

local lobby = {}

-- process_join
-- process_part
-- process_quit
-- process_names
-- process_topic

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

function lobby:process_query(nick, message, channel)
	local status = message:match("(%d+): .+")
	print(nick, message, channel, status)
end

function lobby:enter(prevState, irc)
	self.irc = irc
	self.chat = Chatbox(self.irc.settings)
	love.graphics.setBackgroundColor(100, 100, 100)

	loveframes.SetState("lobby")
	local frame = loveframes.Create("frame")
	frame:SetName("Lobbies")
	frame:SetState("lobby")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)

	self.frame = frame
	self.option_selected = 1

	self.timer = Timer.new()
	self.timer:addPeriodic(30, function() self:check_games() end)

	self.using_keyboard_navigation = false

	self.effects = {}

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

	local spacing = 0
	local padding = 8
	local offset = 40
	local frame_width = 300
	local frame_height = 0
	for i,v in ipairs(self.options) do
		local button = loveframes.Create("button", frame)
		local width, height = button:GetSize()
		spacing = height + 5
		self.options[i].GetPos = function() return button:GetStaticPos() end
		self.options[i].GetSize = function() return button:GetSize() end
		button:SetClickable(v.enabled)
		button:SetSize(frame_width - padding * 2, height + padding * 2)
		button:SetPos(padding, frame_height + offset + padding)
		button:SetText(v.label)
		button.OnMouseEnter = function(object)
			if object:GetClickable() then
				local x, y = object:GetStaticPos()
				self.effects[object] = {
					opacity = 0.0
				}
				local function fade_in()
					self.timer:tween(
						0.1,
						self.effects[object],
						{
							opacity = 1.0
						}, 'out-quad'
					)
				end
				fade_in()
			end
		end
		button.OnMouseExit = function(object)
			if object:GetClickable() then
				local function vanish()
					self.effects[object] = { opacity = 0 }
				end
				local function fade_out()
					self.timer:tween(
						0.2,
						self.effects[object],
						{
							opacity = 0.0
						}, 'out-quad', vanish
					)
				end
				fade_out()
			end
		end
		button.OnClick = function(object)
			v.action()
		end
		frame_height = frame_height + spacing + padding * 2
	end

	frame:SetSize(300, love.graphics.getHeight())
	frame:SetPos(0, 0)
end

function lobby:resize(x, y)
	self.frame:SetPos(0, 0)
	self.frame:SetSize(300, y)
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
				love.graphics.setColor(255, 255, 255, 255)
				love.graphics.rectangle("line", x, y, w, h)
			end
		end
	end
	for object, params in pairs(self.effects) do
		local x, y = object:GetStaticPos()
		local w, h = object:GetSize()
		love.graphics.setColor(0, 80, 255, params.opacity * 255)
		love.graphics.rectangle("line", x, y, w, h)
	end
	love.graphics.setColor(255, 255, 255, 255)
end

function lobby:keypressed(key, isrepeat)
	loveframes.keypressed(key, isrepeat)
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
		self.option_selected = self.option_selected % #self.options + 1
	end
	if key == "up" then
		repeat prev() until self.options[self.option_selected].enabled
	end
	if key == "down" or "tab" then
		repeat next() until self.options[self.option_selected].enabled
	end
	if key == "escape" then
		self.using_keyboard_navigation = false
	end
	if key == "return" then
		-- Don't run the action if the user can't see the highlight.
		if self.using_keyboard_navigation then
			self.options[self.option_selected].action()
			self.using_keyboard_navigation = false
		end
	end
end

function lobby:keyreleased(key)
	loveframes.keyreleased(key)
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
