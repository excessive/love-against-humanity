local Class = require "libs.hump.class"

local chat = Class {}

function chat:init(settings, game)
	local padding = 8
	local box_height = 200
	local box_width = windowWidth - 310 - 10
	local control_height = 0

	self.scope = "global"
	self.settings = settings
	self.game = game

	-- Group containing all chat elements
	self.panel = loveframes.Create("panel")
	self.panel:SetState("lobby")
	
	-- List of chat messages
	self.listGlobal = loveframes.Create("list", self.panel)
	self.listGlobal:SetAutoScroll(true)
	
	-- self.listTeam = loveframes.Create("list", self.panel)
	-- self.listTeam:SetSize(400, 160)
	-- self.listTeam:SetAutoScroll(true)
	
	-- Toggle lists
	self.tabs = loveframes.Create("tabs", self.panel)
	self.tabs:SetPos(0, 0)
	self.tabs:AddTab("Global", self.listGlobal, nil, nil, function() self.scope="global" end)
	-- self.tabs:AddTab("Team", self.listTeam, nil, nil, function() self.scope="team" end)
	
	-- Input message
	self.input = loveframes.Create("textinput", self.panel)
	local width, height = self.input:GetSize()
	control_height = height + padding
	self.input:SetSize(350, height + padding)
	
	-- Send message
	self.buttonSend = loveframes.Create("button", self.panel)
	local width, height = self.buttonSend:GetSize()
	control_height = height + padding
	self.buttonSend:SetSize(width + padding, height + padding)
	self.buttonSend:SetText("Send")
	self.buttonSend.OnClick = function(this)
		Signal.emit("ChatSend")
	end

	self.panel:SetSize(windowWidth - 310, box_height)
	self.panel:SetPos(300 + 5, windowHeight - 205)

	self.listGlobal:SetSize(box_width, box_height - control_height - padding * 4 - 10)

	self.tabs:SetSize(box_width, box_height - padding * 3)

	self.buttonSend:SetPos(360, box_height - control_height - 5)
	self.input:SetPos(5, box_height - control_height - 5)

	Signal.register("ChatFocus", function() self:focus(true) end)
	Signal.register("ChatUnfocus", function() self:focus(false) end)
	Signal.register("ChatSend", function() self:send() end)
	Signal.register("process_message", function(...) self:process_message(...) end)
end

function chat:update()
	if client.chat.global then
		self:receive("global")
	end
	
	-- if client.chat.team then
	-- 	self:receive("team")
	-- end
end

-- Send Chat Message
function chat:send()
	if self.input:GetText() ~= "" then
		Signal.emit("message", self.settings.channel, self.input:GetText())
		self:receive("global", self.settings.nick, self.input:GetText())
		self.input:Clear()
	end
end

function chat:process_message(nick, message, channel)
	if channel == self.settings.channel then
		self:receive("global", nick, message)
	end
end

function chat:receive(scope, nick, message)
	local text = loveframes.Create("text")
	text:SetMaxWidth(400)
	text:SetText({ { color = { 50, 50, 50, 255 } }, "<" .. nick .. "> ", { color = { 0, 0, 0, 255 } }, message })
	-- if scope == "team" then
	-- 	self.listTeam:AddItem(text)
	-- else
	self.listGlobal:AddItem(text)
	-- end
end

function chat:focus(focus)
	if focus ~= nil then
		self.input:SetFocus(focus)
	end
	return self.input:GetFocus()
end

function chat:resize()
	self.panel:SetPos(300 + 5, windowHeight - 205)
end

return chat
