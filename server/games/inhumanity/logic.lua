require "utils"
local Class = require "libs.hump.class"
local Game = Class {}
local Database = require "database"
local default_rules = require "games.inhumanity.rules"

Game.states = {
	"waiting",
	"playing",
	"voting", -- voting or choosing (depends on God Is Dead rule)
	"finished"
}

function Game:init()
	self.rules = deepcopy(default_rules)
	--[[
	players[name] = {
		name, -- copy of the player name (useful when using integer keys)
		active, -- bool
		score, -- int
		cards -- table of card IDs
	}
	--]]
	self.players = {}

	-- same as players
	self.spectators = {}

	-- IMPORTANT: removing players makes #t not work
	self.current_card = nil -- black
	self.cards_in_play = {}

	-- all the black cards so far
	self.history = {}
	
	self.czar = 0

	self.state = "waiting"
end

function Game:set_rule(rule, value)
	-- prevent weird crashes?
	if type(value) == type(self.rules[rule]) then
		self.rules[rule] = value
	end
end

function Game:add_spectator(name)
	if #self.spectators + #self.players >= self.rules.max_spectators then
		-- rejected!
		return false
	end
	if not self.spectators[name] then
		local spectator = {
			name = name,
			active = true,
			score = 0,
			cards = {}
		}
		table.insert(self.spectators, spectator)
		self.spectators[name] = spectator
		return true
	end
end

function Game:add_player(name)
	if #self.players >= self.rules.max_players then
		-- reject (leave as spectator)
		return false
	end
	if not self.players[name] then
		table.insert(self.players, self.spectators[name])
		self.players[name] = self.spectators[name]

		for i, spectator in ipairs(self.spectators) do
			if spectator.name == name then
				table.remove(self.spectators, i)
				self.spectators[name] = nil
				break
			end
		end

		return true
	end
end

-- Game:drop_player(name, [time]) would happen when a user pings out or something
-- Game:drop_player(name) would happen when a user leaves or is kicked
function Game:drop_player(name, time)
	assert(self.players[name], "Tried to drop a player that wasn't joined!")

	if time then
		self.players[name].active = false
		self.inactive_players[name] = time
	else
		-- we could've had so much fun together though :(
		for i, player in ipairs(self.players) do
			if player.name == name then
				table.remove(self.players, i)
				self.players[name] = nil
				break
			end
		end
	end
end

function Game:pick_card(card_type)
	-- if the randomly picked card collided with one in someone else's hand,
	-- try again (up to 3 times). limited in the event of fantastically small
	-- chance to get lots of collisions in a row (or way-too-small card db's)
	local check = {
		white = function(players, card)
			for _, player in ipairs(players) do
				for _, card in ipairs(player.cards) do
					if card.id == card then
						return false
					end
				end
			end
			return true
		end,
		black = function(history, card)
			for _, card in ipairs(history) do
				if card.id == card then
					return false
				end
			end
			return true
		end
	}

	local card = nil

	-- TODO
	local packs = {}

	for attempt = 1, 3 do
		card = Database:pick_card(card_type, packs)
		local data = self.players
		if card_type == "black" then
			data = self.history
		end
		if check[card_type](data, card) then
			break
		end
	end

	if card_type == "black" then
		table.insert(self.history, card)
	end

	return card
end

function Game:pick_czar()
	self.czar = self.czar % #self.players + 1
end

function Game:start()
	self.czar = love.math.random(1, #self.players)
	
	self:begin_round(true)
end

-- it's not you, it's me. -server
function Game:finish()
	self.state = "finished"
	for _, _player in ipairs(self.players) do
		self:add_spectator(_player.name)
	end
	self.players = {}
	self.history = {}
end

function Game:begin_round(start)
	--purge cards in play
	self:purge_cards()
	
	--draw to 10
	for _, player in ipairs(self.players) do
		while #player.cards < 10 do
			table.insert(player.cards, self:pick_card("white"))
		end
	end
	
	--set czar
	if not start then self:pick_czar() end
	
	--play black card
	self.current_card = self:pick_card("black")
	
	--black requires extra card
	if self.current_card.draw > 0 then
		for _, player in ipairs(self.players) do
			for i = 1, self.current_card.draw do
				table.insert(player.cards, self:pick_card("white"))
			end
		end
	end

	self.state = "playing"
end

-- For debugging purposes!
function Game:set_czar(name)
	for i, player in ipairs(self.players) do
		if player.name == name then
			self.czar = i
			break
		end
	end
end

-- ID is the card number in the player's hand.
function Game:play_card(name, id)
	local card = {
		id = self.players[name].cards[id].id,
		name = name,
	}
	
	table.remove(self.players[name].cards, id)
	table.insert(self.cards_in_play, card)

	if #self.cards_in_play == #self.players - 1 then
		self.state = "voting"
	end
end

function Game:purge_cards()
	self.cards_in_play = {}
end

function Game:vote(name, id)
	local card = self.cards_in_play[id]
	local player = self.players[card.name]
	player.score = player.score + 1
	
	if player.score >= self.rules.score_limit then
		player.winner = true
	end
end

function Game:update(time)
	-- kick players who disconnected more than 30 seconds ago (involuntarily)
	for player, idle_time in ipairs(self.inactive_players) do
		if idle_time < time - 30 then
			self.inactive_players[player] = nil
		end
	end
end

return Game
