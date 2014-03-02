local socket = require "socket"
local Class = require "libs.hump.class"
local IRC = require "libs.libirc"
local Inhumanity = require "games.inhumanity.logic"

Signal = require "libs.hump.signal"

require "utils"

local bot = Class {}

function bot:init(settings)
	self.irc = IRC(settings)
	self.games = {}
	self.commands = {
		kill = function()
			self.irc:quit()
		end,
		
		create = function(nick)
			Signal.emit("create", nick)
		end,
		
		join = function(nick, game)
			Signal.emit("join", nick, game)
		end,
		
		option = function(nick, option, value)
			Signal.emit("option", nick, option, value)
		end,
		
		sit = function(nick)
			Signal.emit("sit", nick)
		end,

		stand = function(nick)
			Signal.emit("stand", nick)
		end,
		
		help = function(nick)
			Signal.emit("help", nick)
		end,
		
		play = function(nick, card)
			Signal.emit("play", nick, card)
		end,
		
		vote = function(nick, card)
			Signal.emit("vote", nick, card)
		end,
	}

	-- This is emitted by the IRC lib
	Signal.register("process_message",	function(...) self:process_message(...) end)
	
	-- These are all emitted by the next functions
	-- Channel Commands
	Signal.register("create",			function(...) self:game_create(...) end)
	Signal.register("join",				function(...) self:game_join(...) end)
	Signal.register("chat",				function(...) self:chat(...) end)
	
	-- Admin Commands
	Signal.register("option",			function(...) self:set_game_option(...) end)
	
	-- Player Commands
	Signal.register("sit",				function(...) self:game_sit(...) end)
	Signal.register("stand",			function(...) self:game_stand(...) end)
	Signal.register("help",				function(...) self:game_help(...) end)
	
	-- Game Commands
	Signal.register("play",				function(...) self:game_play_card(...) end)
	Signal.register("vote",				function(...) self:game_vote_vard(...) end)
end


function bot:process_message(nick, line, channel)
	print(nick, line, channel)
	if channel then
		if line:find("!") == 1 then
			line = line:sub(2)
		else
			Signal.emit("chat", nick, line)
			return
		end
	end
	
	local cmd = nil
	local args = {}
	
	for token in line:split() do
		if not cmd then
			cmd = token
		else
			table.insert(args, token)
		end
	end
	
	if self.commands[cmd] then
		self.commands[cmd](nick, unpack(args))
	end
end

function bot:run()
	return self.irc:run()
end

function bot:game_create(nick)
	self.games[nick] = Inhumanity()
	Signal.emit('message', nick, "Welcome to Love Against Humanity!")
end

function bot:game_join(nick, game)
	if not self.games[game] then
		return
	end
	self.games[game]:add_spectator(nick)
	for _, name in ipairs(self.games[game].spectators) do
		Signal.emit('message', self.irc.settings.channel, name)
	end
end

function bot:chat(nick, line)
end

function bot:set_game_option(nick, option, value)
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

function bot:game_sit(nick)
end

function bot:game_stand(nick)
end

function bot:game_help(nick)
end

function bot:game_play_card(nick, card)
end

function bot:game_vote_card(nick, card)
end

return bot
