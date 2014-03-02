Signal = require "libs.hump.signal"
local Class = require "libs.hump.class"
local socket = require "socket"

local IRC = Class {}

function IRC:init(settings)
	self.settings = settings
	self.killed = false
end

function IRC:quit()
	self.killed = true
end

function IRC:process_message(nick, line, channel)
	Signal.emit("process_message", nick, line, channel)
end

function IRC:handle_receive(receive, time)	
	-- reply to ping
	if receive:find("PING :") then
		self.socket:send("PONG :" .. receive:sub(receive:find("PING :") + 6) .. "\r\n\r\n")
		if self.settings.verbose then print("pong") end
	end

	if receive:find(":End of /MOTD command.") or 
	   receive:find(":End of message of the day.") then
		self.socket:send("JOIN " .. self.settings.channel .. "\r\n\r\n")
		joined = true
	end

	if joined and receive:find("PRIVMSG") then
		local line = nil
		local channel = channel
		if self.settings.verbose then Signal.emit('message', self.settings.channel, receive) end

		-- :Xkeeper!xkeeper@netadmin.badnik.net PRIVMSG #fart :gas
		-- local name, message = string.match(message, ":(.+)!.+ PRIVMSG #.+ :(.+)")

		local start = receive:find("PRIVMSG ") + 8
		local channel = receive:sub(start, receive:find(" :") - 1)
		if receive:find(" :") then line = receive:sub((receive:find(" :") + 2)) end
		if receive:find(":") and receive:find("!") then lnick = receive:sub(receive:find(":")+1, receive:find("!")-1) end

		if line then
			self:process_message(lnick, line, channel)
			if self.killed then
				self.socket:send("QUIT :Goodbye, cruel world!\r\n\r\n")
				self.socket:close()
				return false
			end
		end
	end

	if self.settings.verbose then print(receive) end

	return true
end

function IRC:run()
	local function connect(params)
		print("Connecting to " .. params.server .. ":" .. params.port .. "/" .. params.channel .. " as " .. params.nick)

		local s = socket.tcp()
		s:connect(socket.dns.toip(params.server), params.port)

		-- USER username hostname servername :realname
		s:send("USER " .. string.format("%s %s %s :%s\r\n\r\n", params.nick, params.nick, params.nick, params.fullname))
		s:send("NICK " .. params.nick .. "\r\n\r\n")

		return s
	end

	self.socket = connect(self.settings)

	local joined = false

	self.games = {}

	if self.socket == nil then
		return self:run(self.settings)
	end

	Signal.register('message', function(channel, content)
		self.socket:send("PRIVMSG " .. channel .. " :" .. content ..  "\r\n\r\n")
	end)

	local start = socket.gettime()
	while true do
		local ready = socket.select({self.socket}, nil, 0.1)
		local time = socket.gettime() - start

		-- process incoming, reply as needed
		if ready[self.socket] then
			local receive = self.socket:receive('*l')

			if self.settings.verbose then print(receive) end
			
			if receive == nil then
				print("Timed out.. attempting to reconnect!")
				return self.run(self.settings)
			end

			self:handle_receive(receive, time)

			if self.killed then
				print("killed by user")
				return
			end
		end

		-- update game timers
		for channel, game in pairs(self.games) do
			game:update(time)
			if #game.players == 0 and #game.spectators == 0 then
				self.games[channel] = nil
			end
		end
	end
end

return IRC
