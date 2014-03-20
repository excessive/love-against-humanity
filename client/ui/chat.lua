local Class = require "libs.hump.class"

local chat = Class {}

function chat:init(settings)
	self.settings = settings
	self.channels = {}
	
	-- Group containing all chat elements
	self.panel = loveframes.Create("panel")
	self.panel:SetState("lobby")
	
	self.tabs = loveframes.Create("tabs", self.panel)
	
	-- Input message
	self.input = loveframes.Create("textinput", self.panel)
	
	-- Send message
	self.buttonSend = loveframes.Create("button", self.panel)
	self.buttonSend:SetText("Send")
	self.buttonSend.OnClick = function(this)
		Signal.emit("ChatSend")
	end

	self:join_channel(self.settings.channel)
	self.active_channel = self.settings.channel
	self:resize()
	
	Signal.register("ChatFocus", function() self:focus(true) end)
	Signal.register("ChatUnfocus", function() self:focus(false) end)
	Signal.register("ChatSend", function() self:send() end)
	Signal.register("process_message", function(...) self:process_message(...) end)
end

function chat:update(dt)
	self.active_channel = self.tabs.internals[self.tabs.tab].text
end

-- Send Chat Message
function chat:send()
	if self.input:GetText() ~= "" then
		Signal.emit("message", self.active_channel, self.input:GetText())
		self:process_message(self.settings.nick, self.input:GetText(), self.active_channel)
		self.input:Clear()
	end
end

function chat:process_message(nick, message, channel)
	local text = loveframes.Create("text")
	text:SetMaxWidth(400)
	text:SetText({ { color = { 50, 50, 50, 255 } }, "<" .. nick .. "> ", { color = { 0, 0, 0, 255 } }, message })
	self.channels[channel]:AddItem(text)
end

function chat:focus(focus)
	if focus ~= nil then
		self.input:SetFocus(focus)
	end
	return self.input:GetFocus()
end

function chat:resize()
	local padding = 5
	local box_height = 200
	local userlist_width = 160
	local box_width = windowWidth - 300 - userlist_width - padding * 3
	
	self.panel:SetPos(windowWidth - box_width - userlist_width - padding * 2, windowHeight - box_height - padding)
	self.panel:SetSize(box_width, box_height)
	
	self.tabs:SetPos(0, 0)
	self.tabs:SetSize(box_width, 25)
	
	self.buttonSend:SetSize(100, 25 - 2)
	local width, height = self.buttonSend:GetSize()
	self.buttonSend:SetPos(box_width - width - padding, box_height - height - padding - 2)
	
	self.input:SetSize(box_width - self.buttonSend:GetWidth() - padding * 3, 25)
	local width, height = self.input:GetSize()
	self.input:SetPos(padding, box_height - height - padding)
	
	for _, channel in pairs(self.channels) do
		channel:SetPos(padding, self.tabs:GetHeight() + padding)
		channel:SetSize(box_width - padding * 2, box_height - self.tabs:GetHeight() - self.buttonSend:GetHeight() - padding * 3)
	end
end

function chat:join_channel(channel)
	self.channels[channel] = loveframes.Create("list", self.panel)
	self.channels[channel]:SetAutoScroll(true)
	self.tabs:AddTab(channel, self.channels[channel])
	self.tabs:SwitchToTab(self.tabs.tabnumber - 1)
	self:resize()
end

function chat:part_channel(channel)
	self.tabs:RemoveTab(channel)
end

return chat
