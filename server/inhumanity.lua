-- Basic Rules
--[[
To start the game, each player draws ten White Cards. 

One randomly chosen player begins as the Card Czar and plays a Black Card. The
Card Czar reads the question or fill-in-the-blank phrase on the Black Card out
loud. 

Everyone else answers the question or fills in the blank by passing one White
Card, face down, to the Card Czar. 

The Card Czar shuffles all of the answers and shares each card combination
with the group. For full effect, the Card Czar should usually re-read the
Black Card before presenting each answer. The Card Czar then picks a
favourite, and whomever played that answer keeps the Black Card as one
Awesome Point. 

After the round, a new player becomes the Card Czar, and everyone draws back
up to ten White Cards. 

Some cards say PICK 2 on the bottom. 

To answer these, each player plays two White Cards in combination. Play them
in the order that the Card Czar should read them-the order matters. 

If the Card Czar has lobster claws for hands, you can use paper clips to
secure the cards in the right order. 

Gambling 

If a Black Card is played and you have more than one White Card that you think
could win, you can bet one of your Awesome Points to play an additional White
Card.

If you win, you keep your point. If you lose, whomever won the round gets the
point you wagered.
--]]

-- House Rules
local default_rules = {
	--[[
		When you’re ready to stop playing, play the “Make a Haiku” Black Card
		to end the game. This is the official ceremonial ending of a good game
		of Cards Against Humanity, and this card should be reserved for the
		end. (Note: Haikus don’t need to follow the 5-7-5 form. They just have
		 to be read dramatically).
	--]]
	happy_ending = false,

	--[[
		At any time, players may trade in an Awesome Point to return as many
		White Cards as they’d like to the deck and draw back up to 10.
	--]]
	rebooting_the_universe = false,

	--[[
		For Pick 25, all players draw an extra card before playing the hand to
		open up more options.
	--]]
	packing_heat = false,

	--[[
		Every round, pick one random White Card from the pile and place it
		into play. This card belongs to an imaginary player named Rando 
		Cardrissian, and if he wins the game, all players go home in a
		state of everlasting shame.
	--]]
	rando_cardrissian = false,

	--[[
		Play without a Card Czar. Each player picks his or her favourite card
		each round. The card with the most votes wins the round.
	--]]
	god_is_dead = false,

	--[[
		After everyone has answered the question, players take turns
		eliminating one card each. The last remaining card is declared the
		funniest.
	--]]
	survival_of_the_fittest = false,

	--[[
		Instead of picking a favourite card each round, the Card Czar ranks the
		top three in order. The best card gets 3 Awesome Points, the second-
		best gets 2, and the third gets 1. Keep a running tally of the score,
		and at the end of the game, the Winner is declared the funniest,
		mathematically speaking.
	--]]
	serious_business = false,

	--[[
		At any time, players may discard cards that they don’t understand, but
		they must confess their ignorance to the group and suffer the
		resulting humiliation.
	--]]
	never_have_i_ever = false,

	--[[
		Players submit cards for 60 seconds (+10% for each additional card),
		Czar has 60 seconds + 5 seconds for each player and an additional 2
		seconds for any additional cards, i.e. 7 seconds for pick two rounds
		and 9 seconds for pick 3.
	]]
	round_timer = 60,

	--[[
		You win if you get to this score.
	--]]
	score_limit = 8
}

require "utils"
local Class = require "libs.hump.class"
local Game = Class {}
local Database = require "database"

Game.states = {
	"waiting",
	"playing",
	"picking", -- voting or choosing (depends on God Is Dead rule)
	"finished"
}

function Game:init()
	self.rules = deepcopy(default_rules)
	--[[
	players[name] = {
		active, -- bool
		score, -- int
		cards -- table of card IDs
	}
	--]]
	self.players = {}

	-- IMPORTANT: removing players makes #t not work
	self.current_card = nil -- black
	self.cards_in_play = {}

	-- same as players
	self.spectators = {}
	self.max_players = 20

	-- all the black cards so far
	self.history = {}
	
	self.czar = 0
end

function Game:set_rule(rule, value)
	-- prevent weird crashes?
	if type(value) == type(self.rules[rule]) then
		self.rules[rule] = value
	end
end

function Game:add_player(name)
	if #self.players >= self.max_players then
		-- reject (spectate?)
		return false
	end
	if not self.players[name] then
		local player = {
			name = name,
			active = true,
			score = 0,
			cards = {}
		}
		table.insert(self.players, player)
		self.players[name] = player
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
				table.remove(self.players, name)
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

	for attempt = 1, 3 do
		card = Database:pick_card(card_type)
		local data = self.players
		if card_type == "black" then
			data = self.history
		end
		if check[card_type](data, card) then
			break
		end
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
	for _, player in ipairs(self.players) do
		player.cards = {}
	end
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
