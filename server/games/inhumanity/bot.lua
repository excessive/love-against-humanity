local socket = require "socket"
local Class = require "libs.hump.class"
local IRC = require "libs.libirc"
local Inhumanity = require "games.inhumanity.logic"

Signal = require "libs.hump.signal"

require "utils"

local responses = {
		-- channel messages (1xx)
		list = 101,
		create = 102,
		join = 103,
		part = 104,

		-- admin commands (2xx)
		option = 201,
		start = 202,

		-- player commands (3xx)
		sit = 301,
		stand = 302,
		play = 303,
		vote = 304,

		-- errors (4xx)
		not_enough_players = 401,
		game_already_exists = 402,
		forbidden = 403,
		not_found = 404,

		-- misc (6xx)
		help = 601,
		killed = 602,
}

local bot = Class {}

function bot:init(settings)
	self.irc = IRC(settings)
	self.settings = settings
	self.games = {}
	self.players = {} -- table of players and the game they're in
	self.channels = {} -- table of channels and their games (just a shortcut)
	self.commands = {
		kill = function()
			self.irc:quit()
		end,
		
		stop = function(nick)
			Signal.emit("stop", nick)
		end,

		list = function(nick)
			Signal.emit("list", nick)
		end,
		
		create = function(nick)
			Signal.emit("create", nick)
		end,
		
		option = function(nick, option, value)
			if option and value then
				Signal.emit("option", nick, option, value)
			end
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
			if card then
				Signal.emit("play", nick, card)
			end
		end,
		
		vote = function(nick, card)
			if card then
				Signal.emit("vote", nick, card)
			end
		end,
	}

	-- This is emitted by the IRC lib
	Signal.register("process_message",	function(...) self:process_message(...) end)
	Signal.register("process_join",		function(...) self:process_join(...) end)
	Signal.register("process_part",		function(...) self:process_part(...) end)
	
	-- These are all emitted by the next functions
	-- Channel Commands
	Signal.register("list",				function(...) self:list_games(...) end)
	Signal.register("create",			function(...) self:game_create(...) end)
	
	-- Admin Commands
	Signal.register("option",			function(...) self:set_game_option(...) end)
	Signal.register("start",			function(...) self:game_start(...) end)
	Signal.register("stop",				function(...) self:game_stop(...) end)
	
	-- Player Commands
	Signal.register("sit",				function(...) self:game_sit(...) end)
	Signal.register("stand",			function(...) self:game_stand(...) end)
	Signal.register("help",				function(...) self:game_help(...) end)
	
	-- Game Commands
	Signal.register("play",				function(...) self:game_play_card(...) end)
	Signal.register("vote",				function(...) self:game_vote_vard(...) end)
end

function bot:process_message(nick, line, channel)
	if channel then
		if line:find("!") == 1 then
			line = line:sub(2)
		else
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
	
	-- Don't process messages from sub-channels for games.
	if self.commands[cmd] then
		self.commands[cmd](nick, unpack(args))
	end
end

function bot:process_join(nick, channel)
	local game = self.channels[channel]
	if game then
		game:add_player(nick)
	end
	--Signal.emit('message', self.settings.channel, "JOIN: " .. nick .. " (" .. channel .. ")")
end

-- parts are generally voluntary
function bot:process_part(nick, channel)
	--Signal.emit('message', self.settings.channel, "PART: " .. nick .. " (" .. channel .. ")")
end

-- quits may not be voluntary (i.e. ping timeout/resets)
function bot:process_quit(nick, message, time)
	local game = self.players[nick]
	if game then
		if game.players[nick] then
			self.players[nick]:drop_player(nick, time)
		end
	end
	--Signal.emit('message', self.settings.channel, "QUIT: " .. nick .. " (" .. channel .. " @ " .. time .. ")")
end

function bot:run()
	return self.irc:run()
end

function bot:list_games(nick)
	local list = ""
	
	for game in pairs(self.games) do
		list = list .. game .. ", "
	end
	
	Signal.emit("message", nick, list, responses.list)
end

function bot:game_create(nick)
	if self.games[nick] then
		Signal.emit('message', nick, nick .. "'s game already exists.", responses.game_already_exists)
		return
	end
	local game = Inhumanity(nick, self.settings.channel_prefix .. "-" .. nick)
	self.games[nick] = game
	self.players[nick] = game
	self.channels[game.channel] = game
	self.irc:join_channel(game.channel)
	Signal.emit('message', nick, "Welcome to LÖVE Against Humanity! Be sure to join " .. game.channel, responses.create)
end

function bot:set_game_option(nick, option, value)
	if not self.games[nick] then return end

	Signal.emit('message', nick, "NOPE", responses.forbidden)
--[[
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
]]
end

function bot:game_stop(nick)
	local game = self.games[nick]
	if game then
		Signal.emit('message', nick, "We could have had so much fun together!", responses.killed)
		self.irc:part_channel(game.channel)

		for player, player_game in pairs(self.players) do
			if player_game == game then
				self.players[player] = nil
			end
		end

		self.games[nick] = nil
		self.players[nick] = nil
		self.channels[game.channel] = nil
	end
end

function bot:game_start(nick)
	local game = self.games[nick]
	if game then
		if game:start() then
			Signal.emit('message', game.channel, "The game is starting!", responses.start)
		else
			Signal.emit('message', game.channel, "There aren't enough players to start the game.", responses.not_enough_players)
		end
	end
end

function bot:game_sit(nick, channel)
	local game = self.players[nick]
	if not game then return end

	game:add_player(nick)

	Signal.emit('message', nick, "You've sat down to play.", responses.sit)
end

function bot:game_stand(nick)
	local game = self.players[nick]
	if not game then return end

	game:drop_player(nick)
	
	Signal.emit('message', nick, "You've dropped out of the game.", responses.stand)
end

function bot:game_help(nick)
end

function bot:game_play_card(nick, card)
	local game = self.players[nick]
	if game and game.players[nick] and game.state == "playing" then
		game:play_card(nick, card)
		Signal.emit('message', nick, "Played card " .. card .. " from your hand.", responses.play)
	end
end

function bot:game_vote_card(nick, card)
	local game = self.players[nick]
	if game and game.players[nick] == game.players[game.czar] and game.state == "voting" then
		game:vote(nick, card)
		Signal.emit('message', nick, "Voted for card " .. card .. " from the pile.", responses.vote)
	end
end

return bot
