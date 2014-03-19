local Class = require "libs.hump.class"
local Timer = require "libs.hump.timer"

local lobby = Class {}

function lobby:init(options)
	local spacing = 0
	local padding = 8
	local offset = 40
	local frame_width = 300
	local frame_height = 0
	
	self.menu = loveframes.Create("frame")
	self.menu:SetState("lobby")
	self.menu:SetName("Lobbies")
	self.menu:ShowCloseButton(false)
	self.menu:SetDraggable(false)
	self:resize_menu()
	
	self.user_panel = loveframes.Create("panel")
	self.user_panel:SetState("lobby")
	self.user_list = loveframes.Create("list", self.user_panel)
	self:resize_user_panel()
	
	self.effects = {}
	self.timer = Timer.new()
	
	for i, option in ipairs(options) do
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

function lobby:resize_menu()
	self.menu:SetPos(0, 0)
	self.menu:SetSize(300, windowHeight)
end

function lobby:resize_user_panel()
	self.user_panel:SetPos(windowWidth - 160, 0)
	self.user_panel:SetSize(160, windowHeight - 320)
	
	self.user_list:SetPos(5, 5)
	self.user_list:SetSize(150, self.user_panel:GetHeight() - 10)
end

function lobby:draw_effects()
	for object, params in pairs(self.effects) do
		local x, y = object:GetStaticPos()
		local w, h = object:GetSize()
		love.graphics.setColor(0, 80, 255, params.opacity * 255)
		love.graphics.rectangle("line", x, y, w, h)
	end
end

return lobby