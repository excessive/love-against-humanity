Signal = require "libs.hump.signal"
local Class = require "libs.hump.class"
local socket = require "socket"

local IRC = Class {}
require "utils"

function IRC:init(settings)
	self.settings = settings
	self.killed = false
	self.names = {}
end

function IRC:quit()
	self.killed = true
end

function IRC:join_channel(channel)
	self.socket:send("JOIN " .. channel .. "\r\n\r\n")
end

function IRC:part_channel(channel)
	self.socket:send("PART " .. channel .. "\r\n\r\n")
end

function IRC:handle_receive(receive, time)	
	local receive_type = receive:match(":.+ ([%u%d]+) .+")

	-- End of MOTD, safe to join channel now.
	if receive_type == "376" then
		self.socket:send("JOIN " .. self.settings.channel .. "\r\n\r\n")
		self.joined = true
		return true
	end

	-- reply to ping
	if receive:find("PING :([%wx]+)") == 1 then
		self.socket:send("PONG :" .. receive:sub(receive:find("PING :") + 6) .. "\r\n\r\n")
		print("pong")
		return true
	end

--	if self.settings.verbose then print(receive) end

	if not self.joined then
		return true
	end

	if receive_type == "PRIVMSG" then
		local line = nil
		local channel = channel
		if self.settings.verbose then
			Signal.emit('message', self.settings.channel, receive)
		end

		-- :Xkeeper!xkeeper@netadmin.badnik.net PRIVMSG #fart :gas
		local nick, channel, line = receive:match(":(.+)!.+ PRIVMSG ([%w%d%p]+) :(.+)")

		if line then
			if channel:find("#") then
				Signal.emit("process_message", nick, line, channel)
			else
				Signal.emit("process_query", nick, line, channel)
			end
			if self.killed then
				self.socket:send("QUIT :Goodbye, cruel world!\r\n\r\n")
				self.socket:close()
				return false
			end
		end
	elseif receive_type == "JOIN" then
		local nick, channel = receive:match(":(.+)!.+ JOIN :(#[%w%d%p]+)")
		if nick and channel then
			Signal.emit("process_join", nick, channel)
		end
	elseif receive_type == "PART" then
		local nick, channel = receive:match(":(.+)!.+ PART (#[%w%d%p]+)")
		if nick and channel then
			Signal.emit("process_part", nick, channel)
		end
	elseif receive_type == "QUIT" then
		-- TODO: this is borked
		local nick, message = receive:match(":(.+)!.+ QUIT :(.+)")
		Signal.emit("process_quit", nick, message, time)
	-- NAMES
	elseif receive_type == "353" then
		local channel, names = receive:match(":.+ 353 .+ @ (#[%w%d%p]+) :(.+)")
		if not self.names[channel] then
			self.names[channel] = ""
		end
		self.names[channel] = self.names[channel] .. " " .. names
		if self.settings.verbose then
			Signal.emit("message", self.settings.channel, names)
		end
	-- End of NAMES
	elseif receive_type == "366" then
		local names = self.names[channel]
		if names then
			Signal.emit("process_names", channel, names:split())
		end
	-- Shit to ignore.
	elseif
		receive_type == "MODE" or
		receive_type == "332" or -- TOPIC... I don't think we care.
		receive_type == "333" then -- TOPICWHOTIME. Don't care.
		-- Pass. Just preventing it from going into the unhandled block.
	else
		if self.settings.verbose then
			Signal.emit("message", self.settings.channel, "unhandled response: " .. tostring(receive_type) .. ": " .. receive)
		end
		print(self.settings.channel, "unhandled response: " .. tostring(receive_type) .. ": " .. receive)
	end



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

	self.joined = false

	self.games = {}

	if self.socket == nil then
		return self:run(self.settings)
	end

	Signal.register('message', function(channel, content, response_code)
		if response_code then
			content = response_code .. ": " .. content
		end
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
