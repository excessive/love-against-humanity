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

-- XXX: stupid
function IRC:quit(send_kill)
	self.killed = true
	if send_kill then
		self.socket:send("QUIT :Goodbye, cruel world!\r\n\r\n")
		self.socket:close()
	end
end

function IRC:join_channel(channel)
	self.socket:send("JOIN " .. channel .. "\r\n\r\n")
end

function IRC:part_channel(channel)
	self.socket:send("PART " .. channel .. "\r\n\r\n")
end

function IRC:request_names(channel)
	self.socket:send("NAMES " .. channel .. "\r\n\r\n")
end

function IRC:request_topic(channel)
	self.socket:send("TOPIC " .. channel .. "\r\n\r\n")
end

function IRC:handle_receive(receive, time)	
	local receive_type = receive:match(":[%w%d%p]+ ([%u%d]+) .+")

	-- reply to ping
	if receive:find("PING :([%wx]+)") == 1 then
		self.socket:send("PONG :" .. receive:sub(receive:find("PING :") + 6) .. "\r\n\r\n")
		print("pong")
		return true
	end

	-- End of MOTD, safe to join channel now.
	if receive_type == "376" then
		self.socket:send("JOIN " .. self.settings.channel .. "\r\n\r\n")
		self.joined = true
		return true
	end

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
		local nick, channel, line = receive:match(":([%w%d%p]+)![%w%d%p]+ PRIVMSG ([%w%d%p]+) :(.+)")

		print(":".. nick .. " PRIVMSG " .. channel .. " :" .. line)

		if line then
			if channel:find("#") then
				Signal.emit("process_message", nick, line, channel)
			else
				Signal.emit("process_query", nick, line, channel)
			end
			if self.killed then
				self:quit(true)
				return false
			end
		end
	elseif receive_type == "JOIN" then
		local nick, channel = receive:match(":([%w%d%p]+)![%w%d%p]+ JOIN :(#[%w%d%p]+)")
		if nick and channel then
			Signal.emit("process_join", nick, channel)
		end
	elseif receive_type == "PART" then
		local nick, channel = receive:match(":([%w%d%p]+)![%w%d%p]+ PART (#[%w%d%p]+)")
		if nick and channel then
			Signal.emit("process_part", nick, channel)
		end
	elseif receive_type == "QUIT" then
		-- TODO: this is borked
		local nick, message = receive:match(":([%w%d%p]+)![%w%d%p]+ QUIT :(.+)")
		Signal.emit("process_quit", nick, message, time)
	-- NAMES
	elseif receive_type == "353" then
		local channel, names = receive:match(":[%w%d%p]+ 353 [%w%d%p]+ . (#[%w%d%p]+) :(.+)")
		print(channel, names, receive)
		if not self.names[channel] then
			self.names[channel] = ""
		end

		-- accumulate names until we get a 366
		self.names[channel] = self.names[channel] .. " " .. names
		if self.settings.verbose then
			Signal.emit("message", self.settings.channel, names)
		end
	-- End of NAMES
	elseif receive_type == "366" then
		local names = self.names[channel]
		if names then
			Signal.emit("process_names", channel, names:split())

			-- clear out the accumulated names
			self.names[channel] = nil
		end
	-- TOPIC... I don't think we care.
	elseif receive_type == "332" then
		local nick, channel, topic = receive:match(":[%w%d%p]+ TOPIC ([%w%d%p]+) (#[%w%d%p]+) :(.+)")
		Signal.emit("process_topic", nick, channel, topic)
	-- Shit to ignore.
	elseif
		receive_type == "MODE" or
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

function IRC:connect()
	local function connect_socket(params)
		print("Connecting to " .. params.server .. ":" .. params.port .. "/" .. params.channel .. " as " .. params.nick)

		local s = socket.tcp()
		s:connect(socket.dns.toip(params.server), params.port)

		-- USER username hostname servername :realname
		s:send("USER " .. string.format("%s %s %s :%s\r\n\r\n", params.nick, params.nick, params.nick, params.fullname or "inhumanity"))
		s:send("NICK " .. params.nick .. "\r\n\r\n")

		return s
	end

	self.socket = connect_socket(self.settings)

	self.joined = false

	if self.socket == nil then
		return self:connect()
	end

	Signal.register('message', function(channel, content, response_code)
		if response_code then
			content = response_code .. ": " .. content
		end
		self.socket:send("PRIVMSG " .. channel .. " :" .. content ..  "\r\n\r\n")
		print("PRIVMSG " .. channel .. " :" .. content)
	end)

	self.start = socket.gettime()

	return true
end

function IRC:update(dt)
	local ready = socket.select({self.socket}, nil, 0.01)
	local time = socket.gettime() - self.start

	-- process incoming, reply as needed
	if ready[self.socket] then
		local receive = self.socket:receive('*l')

		if self.settings.verbose then print(receive) end
		
		if receive == nil then
			print("Timed out.. attempting to reconnect!")
			return self:connect()
		end

		self:handle_receive(receive, time)

		if self.killed then
			print("killed by user")
			return false
		end
	end

	return true
end

function IRC:run()
	self:connect()
	while true do
		if not self:update() then
			return
		end
	end
end

return IRC
