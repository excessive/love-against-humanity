local Class = require "libs.hump.class"

Card = Class {}

--[[
	Initialize Object
]]--
function Card:init(id, text, white)
	self.id		= id
	self.text	= text
	self.white	= white
	
	if self.white then
		self.image = love.graphics.newImage("assets/white.png")
	else
		self.image = love.graphics.newImage("assets/blue.png")
	end
end

--[[
	Draw Object
]]--
function Card:draw()
	local x, y = 10, 380
	love.graphics.draw(self.image, x, y)
	
	if self.white then
		love.graphics.setColor(108, 190, 228, 255)
	end
	
	love.graphics.printf(self.text, x+10, y+10, 130)
	love.graphics.setColor(255, 255, 255, 255)
end
