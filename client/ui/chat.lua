local Class = require "libs.hump.class"

local chat = Class {}

function chat:init(settings)
	self.settings = settings
	self.channels = {}
	self.users = {}
	
	-- Group containing all chat elements
	self.panel = loveframes.Create("panel")
	self.panel:SetState("lobby")
	
	self.tabs = loveframes.Create("tabs", self.panel)
	--self.users = loveframes.Create("list", self.panel)
	self.input = loveframes.Create("textinput", self.panel)
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

	Signal.register("process_join", function(...) self:process_join(...) end)
	Signal.register("process_part", function(...) self:process_part(...) end)
	Signal.register("process_quit", function(...) self:process_quit(...) end)
	Signal.register("process_names", function(...) self:process_names(...) end)
	--Signal.register("process_nick", function(...) self:process_nick(...) end)

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

function chat:process_join(nick, channel)
	local text = loveframes.Create("text")
	text:SetMaxWidth(150)
	text:SetText(nick)
	self.users[channel]:AddItem(text)

	table.sort(self.users[channel].children, function(a,b)
		return a.text < b.text
	end)
end

function chat:process_part(nick, channel)
	local items = self.users[channel].children
	
	for i, item in pairs(items) do
		if item.text == nick then
			self.users[channel]:RemoveItem(items[i])
		end
	end
end

function chat:process_quit(nick, message, time)
	for channel, _ in pairs(self.channels) do
		self:process_part(nick, channel)
	end
end

function chat:process_names(channel, names)
	print("Users in " .. channel)

	self.users[channel]:Clear()

	for nick in names:split() do
		local text = loveframes.Create("text")
		text:SetMaxWidth(150)
		text:SetText(nick)
		self.users[channel]:AddItem(text)
	end

	table.sort(self.users[channel].children, function(a,b)
		return a.text < b.text
	end)
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
	local button_height = 25
	local box_height = 200
	local users_width = 150
	local box_width = windowWidth - 300 - padding * 2
	
	self.panel:SetSize(box_width, box_height)
	self.panel:SetPos(windowWidth - box_width - padding, windowHeight - box_height - padding)
	
	self.tabs:SetSize(box_width - users_width - padding, button_height)
	self.tabs:SetPos(0, 0)
	
	self.buttonSend:SetSize(users_width, button_height - 2)
	self.buttonSend:SetPos(box_width - users_width - padding, box_height - button_height - padding)
	
	self.input:SetSize(box_width - users_width - padding * 3, button_height)
	self.input:SetPos(padding, box_height - button_height - padding)
	
	for _, channel in pairs(self.channels) do
		channel:SetSize(box_width - users_width - padding * 3, box_height - button_height * 2 - padding * 3)
		channel:SetPos(0, 0)
	end
	
	for _, channel in pairs(self.users) do
		channel:SetSize(users_width, box_height - button_height * 2 - padding * 3)
		channel:SetPos(box_width - users_width - padding * 2, 0)
	end
end

function chat:join_channel(channel)
	local panel = loveframes.Create("panel", self.panel)
	self.channels[channel] = loveframes.Create("list", panel)
	self.users[channel] = loveframes.Create("list", panel)
	self.channels[channel]:SetAutoScroll(true)
	self.tabs:AddTab(channel, panel)
	self.tabs:SwitchToTab(self.tabs.tabnumber - 1)
	self:resize()
end

function chat:part_channel(channel)
	self.tabs:RemoveTab(channel)
end

return chat
