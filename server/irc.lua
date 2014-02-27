local socket = require "socket"

Signal = require "libs.hump.signal"

require "utils"

local irc = {}

function irc:process_channel(channel, nick, line)
	if line:find("!") ~= 1 then return true end

	local command = line:sub(2)
	local args = {}

	for token in command:split() do
		table.insert(args, token)
	end

	if args[1] == "kill" then
		return false
	end

	if args[1] == "set" then
		if #args == 3 and args[2] == "verbose" then
			self.settings.verbose = not self.settings.verbose
		end
	end

	return true
end

function irc:process_message(channel, nick, line)
	-- TODO
	return true
end

function irc:handle_receive(receive, time)	
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

		-- for private messages, we want to talk back to the sender.
		if channel == self.settings.nick then channel = lnick end
		if line then
			local process = (channel == self.settings.channel) and self.process_channel or self.process_message
			if not process(self, channel, lnick, line) then
				self.socket:send("QUIT :Goodbye, cruel world!\r\n\r\n")
				self.socket:close()
				return false
			end
		end
	end

	if self.settings.verbose then print(receive) end

	return true
end

function irc:run(settings)
	local function connect(params)
		print("Connecting to " .. params.server .. ":" .. params.port .. "/" .. params.channel .. " as " .. params.nick)

		local s = socket.tcp()
		s:connect(socket.dns.toip(params.server), params.port)

		-- USER username hostname servername :realname
		s:send("USER " .. string.format("%s %s %s :%s\r\n\r\n", params.nick, params.nick, params.nick, params.fullname))
		s:send("NICK " .. params.nick .. "\r\n\r\n")

		return s
	end

	self.socket = connect(settings)

	local joined = false

	self.settings = settings
	self.games = {}

	if self.socket == nil then
		return self:run(settings)
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
				return run(settings)
			end

			if not self:handle_receive(receive, time) then
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

return irc
