local Class = require "libs.hump.class"
local Timer = require "libs.hump.timer"

local gameplay = Class {}

function gameplay:init(irc, channel)
	local spacing = 0
	local padding = 8
	local offset = 40
	local frame_width = 300
	local frame_height = 0
	
	self.menu = loveframes.Create("frame")
	self.menu:SetState("gameplay")
	self.menu:SetName(irc.settings.nick .. "'s game")
	self.menu:ShowCloseButton(false)
	self.menu:SetDraggable(false)
	self:resize()
	
	self.effects = {}
	self.irc = irc
	self.channel = channel
	self.timer = Timer.new()
	self.using_keyboard_navigation = false
	self.options = {
		{
			label = "Sit",
			enabled = true,
			action = function()
				Signal.emit("message", channel, "!sit")
			end
		},{
			label = "Stand",
			enabled = true,
			action = function()
				Signal.emit("message", channel, "!stand")
			end
		},{
			label = "Change Name",
			enabled = false,
			action = function()
--				self.irc:change_nick(...)
			end
		},{
			label = "Leave Game",
			enabled = true,
			action = function()
				Signal.emit("leave_game")
			end
		}
	}
	
	for i, option in ipairs(self.options) do
		local button = loveframes.Create("button", self.menu)
		local width, height = button:GetSize()
		spacing = height + 5
		option.GetPos = function() return button:GetStaticPos() end
		option.GetSize = function() return button:GetSize() end
		button:SetClickable(option.enabled)
		button:SetSize(frame_width - padding * 2, height + padding * 2)
		button:SetPos(padding, frame_height + offset + padding)
		button:SetText(option.label)
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
			option.action()
		end
		frame_height = frame_height + spacing + padding * 2
	end
end

function gameplay:resize()
	self.menu:SetPos(0, 0)
	self.menu:SetSize(300, windowHeight)
end

function gameplay:draw()
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
end

function gameplay:keypressed(key, isrepeat)
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
	
	if key == "down" then
		repeat next() until self.options[self.option_selected].enabled
	end
	
	if key == "escape" then
		self.using_keyboard_navigation = false
	end
end

return gameplay