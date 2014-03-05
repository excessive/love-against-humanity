local Class = require "libs.hump.class"

local chat = Class {}

function chat:init(settings, game)
	self.scope = "global"
	self.settings = settings
	self.game = game

	-- Group containing all chat elements
	self.panel = loveframes.Create("panel")
	self.panel:SetState("lobby")
	self.panel:SetSize(windowWidth - 310, 200)
	self.panel:SetPos(300 + 5, windowHeight - 205)
	
	-- List of chat messages
	self.listGlobal = loveframes.Create("list", self.panel)
	self.listGlobal:SetSize(400, 160)
	self.listGlobal:SetAutoScroll(true)
	
	-- self.listTeam = loveframes.Create("list", self.panel)
	-- self.listTeam:SetSize(400, 160)
	-- self.listTeam:SetAutoScroll(true)
	
	-- Toggle lists
	self.tabs = loveframes.Create("tabs", self.panel)
	self.tabs:SetSize(400, 180)
	self.tabs:SetPos(0, 0)
	self.tabs:AddTab("Global", self.listGlobal, nil, nil, function() self.scope="global" end)
	-- self.tabs:AddTab("Team", self.listTeam, nil, nil, function() self.scope="team" end)
	
	-- Input message
	self.input = loveframes.Create("textinput", self.panel)
	self.input:SetSize(350, 20)
	self.input:SetPos(0, 180)
	
	-- Send message
	self.buttonSend = loveframes.Create("button", self.panel)
	self.buttonSend:SetSize(50, 20)
	self.buttonSend:SetPos(350, 180)
	self.buttonSend:SetText("Send")
	self.buttonSend.OnClick = function(this)
		self:send()
	end
	
	Signal.register("ChatFocus", function() self:focus() end)
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

function chat:focus()
	if not self.input:GetFocus() then
		self.input:SetFocus(true)
	else
		if self.input:GetText() then
			self:send()
		end
		
		self.input:SetFocus(false)
	end
end

return chat
