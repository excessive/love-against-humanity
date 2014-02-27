require "hate"

local Inhumanity = require "inhumanity"

local game = Inhumanity()

-- testing
game:add_player("freem")
game:add_player("shakesoda")
game:add_player("karai")

game:set_rule("score_limit", 2)

-- Round 1
game:start()

game:begin_round()
game:set_czar("freem") -- debug only, this is usually automatic

game:play_card("karai", 2)
game:play_card("shakesoda", 5)

-- everyone has submitted, now voting begins.
game:vote("freem", 1) -- one point should go to karai (note: api weirdity)

assert(game.players["karai"].score == 1, "Karai's score is wrong! (round 1)")

-- Round 2
game:begin_round()
assert(game.players[game.czar].name == "shakesoda", "shakesoda should be the czar, but it's " .. game.players[game.czar].name)

game:play_card("freem", 3)
game:play_card("karai", 5)

game:vote("shakesoda", 2)

assert(game.players["karai"].score == 2, "Karai's score is wrong! (round 2)")
assert(game.players["karai"].winner, "Karai should have won the game.")
assert(game.state == "finished", "Why isn't the game over? Karai won.")
