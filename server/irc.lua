local socket = require "socket"

Signal = require "libs.hump.signal"

require "utils"

local irc = {}

function irc:init()
	-- Process Commands
	Signal.register("channel_message",	self:channel_message)
	Signal.register("private_message",	self:private_message)
	
	-- Channel Commands
	Signal.register("create",			self:game_create)
	Signal.register("join",				self:game_join)
	Signal.register("chat",				self:chat_send)
	
	-- Admin Commands
	Signal.register("option",			self:set_game_option)
	
	-- Player Commands
	Signal.register("sit",				self:game_sit)
	Signal.register("stand",			self:game_stand)
	Signal.register("help",				self:game_help)
	
	-- Game Commands
	Signal.register("play",				self:game_play_card)
	Signal.register("vote",				self:game_vote_vard)
end

function irc:game_create(nick)
	
	return
end

function irc:game_join(game)
	
	return
end

function irc:chat(nick, line)
	
	return
end

function irc:set_game_option(option, value)
	if option == "password" then
		return "password", value
	end

	if option == "limit" then
		if value >= 3 and value <= 12 then
			return "player_limit", value
		end
	end
	
	if option == "score" then
		if value >= 3 and value <= 20 then
			return "score_limit", value
		end
	end
	
	if option == "timer" then
		if (value >= 30 and value <= 90) or value == 0 then
			return "round_timer", value
		end
	end
	
	return false
end

function irc:game_sit(nick)
	
	return
end

function irc:game_stand(nick)
	
	return
end

function irc:game_help(nick)
	
	return
end

function irc:game_play_card(card, nick)
	
	return
end

function irc:game_vote_card(card, nick)
	
	return
end

function irc:channel_message(channel nick, line)
	if line:find("!") == 1 then
		local command = line:sub(2)
		local args = {}

		for token in command:split() do
			table.insert(args, token)
		end
		
		if args[1] == "create" then
			if not self.games[nick] then
				Signal.emit("create", nick)
				return true
			end
			
			return false
		end
		
		if args[1] == "join" then
			if self.games[args[2]] then
				Signal.emit("join", args[2])
				return true
			end
			
			return false
		end
	else
		Signal.emit("chat", nick, line)
		return true
	end
end

function irc:private_message(nick, line)
	if line:find("!") ~= 1 then return true end

	local command = line:sub(2)
	local args = {}

	for token in command:split() do
		table.insert(args, token)
	end
	
	--[[ ADMIN COMMANDS ]]--
	
	if self.games[nick] then
		if args[1] == "option" then
			if self.rules[args[1]] then
				return Signal.emit("option", args[2], args[3])
			end
			
			return false
		end
	end
	
	--[[ PLAYER COMMANDS ]]--
	
	if args[1] == "sit" then
		Signal.emit("sit", nick)
		return true
	end

	if args[1] == "stand" then
		Signal.emit("stand", nick)
		return true
	end
	
	if args[1] == "help" then
		Signal.emit("help", nick)
		return true
	end
	
	--[[ GAME COMMANDS ]]--
	if args[1] == "play" then
		Signal.emit("play", args[2], nick)
		return true
	end
	
	if args[1] == "vote" then
		Signal.emit("vote", args[2], nick)
		return true
	end
end

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
	
	Signal.emit("channel_message", channel, nick, line)
	
	return true
end

function irc:process_message(nick, line)
	-- TODO
	Signal.emit("channel_message", nick, line)
	
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
