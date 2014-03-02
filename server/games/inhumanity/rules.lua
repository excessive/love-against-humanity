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
return {
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
	--]]
	round_timer = 60,

	--[[
		You win if you get to this score.
	--]]
	score_limit = 8,
	
	--[[
		Maximum players who can sit in a game.
	--]]
	max_players = 12,
	
	--[[
		Maximum spectators (+ players) who can watch a game.
	--]]
	max_spectators = 24,
	
	--[[
		Optional lockout password for game.
	--]]
	password = false,
}
