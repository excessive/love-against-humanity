local Timer = require "libs.hump.timer"
local IRC = require "libs.libirc"

local title = {}

function title:check_version()
	-- TODO
end

function title:connect()
	local settings = require "settings"
	settings.nick = self.text_fields["name"].GetText()
	self.irc = IRC(settings)

	if self.irc:connect() then
		Gamestate.switch(require "gamestates.lobby", self.irc)
	end
end

function title:enter(prevState)
	love.graphics.setBackgroundColor(100, 100, 100)

	self.titlefont = love.graphics.newFont("assets/fonts/OpenSans-Light.ttf", 32)

	loveframes.SetState("title")
	local frame = loveframes.Create("frame")
	frame:SetName("Login")
	frame:SetState("title")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)

	self.frame = frame
	self.option_selected = 1

	self.timer = Timer.new()
	self.timer:addPeriodic(3600, function() self:check_version() end)

	self.using_keyboard_navigation = false

	self.effects = {}
	self.text_fields = {}

	self.options = {
		{
			label = { { color = {100, 100, 100, 255} }, "Name" },
			type = "text",
			enabled = false
		},{
			label = "NameInput",
			name = "name",
			type = "textinput",
			enabled = true,
			action = function()
				self:connect()
			end
		},{
			label = "Connect",
			type = "button",
			enabled = true,
			action = function()
				self:connect()
			end
		},{
			label = "Quit",
			type = "button",
			enabled = true,
			action = function()
				love.event.quit()
			end
		}
	}

	local spacing = 0
	local padding = 8
	local offset = 40
	local frame_width = 300
	local frame_height = 0
	
	for i, v in ipairs(self.options) do
		local button = loveframes.Create(v.type, frame)
		local width, height = button:GetSize()
		spacing = height + 5
		self.options[i].GetText = function() return button:GetText() end
		self.options[i].GetPos = function() return button:GetStaticPos() end
		self.options[i].GetSize = function() return button:GetSize() end
		if v.type == "button" then
			button:SetClickable(v.enabled)
		end
		button:SetSize(frame_width - padding * 2, height + padding * 2)
		button:SetPos(padding, frame_height + offset + padding)
		if v.type ~= "textinput" then
			button:SetText(v.label)
		else
			self.options[i].SetFocus = function(v) return button:SetFocus(v) end
			self.text_fields[v.name] = self.options[i]
		end
		button.OnMouseEnter = function(object)
			if v.type == "button" and object:GetClickable() then
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
			if v.type == "button" and object:GetClickable() then
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
			if v.action then
				v.action(object)
			end
		end
		if v.type == "text" then
			frame_height = frame_height + spacing / 2 + padding * 2
		else
			frame_height = frame_height + spacing + padding * 2
		end
	end

	frame:SetSize(300, love.graphics.getHeight())
	frame:SetPos(0, 0)

	local title = loveframes.Create("text", frame)
	title:SetPos(310, 5)
	title:SetSize(500, 500)
	title:SetDefaultColor(255, 255, 255, 255)
	title:SetFont(self.titlefont)
	title:SetShadow(true)
	title:SetShadowOffsets(0, 2)
	title:SetShadowColor(0, 0, 0, 100)
	title:SetText("LÖVE Against Humanity")

	local body = loveframes.Create("text", frame)
	body:SetPos(313, 45)
	body:SetSize(500, 500)
	body:SetDefaultColor(255, 255, 255, 200)
	body:SetShadow(true)
	body:SetShadowOffsets(0, 2)
	body:SetShadowColor(0, 0, 0, 100)
	body:SetText("Version 0.01")
end

function title:resize(x, y)
	self.frame:SetPos(0, 0)
	self.frame:SetSize(300, y)
end

function title:update(dt)
	loveframes.update(dt)
	self.timer:update(dt)
end

function title:draw()
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
	for object, params in pairs(self.effects) do
		local x, y = object:GetStaticPos()
		local w, h = object:GetSize()
		love.graphics.setColor(0, 80, 255, params.opacity * 255)
		love.graphics.rectangle("line", x, y, w, h)
	end
	love.graphics.setColor(255, 255, 255, 255)
end

function title:keypressed(key, isrepeat)
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
	if key == "up" then
		repeat prev() until self.options[self.option_selected].enabled
	end
	if key == "down" or key == "tab" then
		repeat next() until self.options[self.option_selected].enabled
	end
	if key == "escape" then
		self.using_keyboard_navigation = false
	end
	if key == "return" then
		local option = self.options[self.option_selected]
		-- Don't run the action if the user can't see the highlight.
		if self.using_keyboard_navigation then
			option.action()
			self.using_keyboard_navigation = false
		end
	end
end

function title:keyreleased(key)
	if key ~= "tab" then
		loveframes.keyreleased(key)
	end
end

function title:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function title:mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function title:textinput(text)
	loveframes.textinput(text)
end

return title
