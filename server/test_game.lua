require "hate"

local Inhumanity = require "games.inhumanity.logic"

local game = Inhumanity()

assert(game.state == "waiting", "Game is in the wrong initial state.")

game:add_player("freem")
game:add_player("shakesoda")
game:add_player("karai")
game:add_player("frenchfry")

assert(#game.players == 4, "Not every player made it, somehow.")

game:drop_player("frenchfry")
assert(#game.players == 3, "We've got a straggler.")

game:set_rule("score_limit", 2)

assert(game.rules.score_limit == 2, "Setting rules didn't work.")

-- Round 1
game:start()
assert(game.state == "playing", "Game should have started by now.")

assert(game.state == "playing", "Round should have started! (round 1)")
game:set_czar("freem") -- debug only, this is usually automatic

game:play_card("karai", 2)
game:play_card("shakesoda", 5)

assert(#game.cards_in_play == 2, "Not every card made it into play.")
assert(game.state == "voting", "All cards in play, but voting hasn't begun.")

-- everyone has submitted, now voting begins.
game:vote("freem", 1) -- one point should go to karai (note: api weirdity)

assert(game.players["karai"].score == 1, "Karai's score is wrong! (round 1)")

-- Round 2
game:begin_round()
assert(game.state == "playing", "Round should have started! (round 2)")
assert(game.players[game.czar].name == "shakesoda", "shakesoda should be the czar, but it's " .. game.players[game.czar].name)

game:play_card("freem", 3)
game:play_card("karai", 5)

game:vote("shakesoda", 2)

assert(#game.history == 2, "History should contain two cards.")
assert(game.players["karai"].score == 2, "Karai's score is wrong! (round 2)")
assert(game.players["karai"].winner, "Karai should have won the game.")

game:finish()

assert(game.state == "finished", "Karai won, but the game isn't finished!")

print("All tests passed! Yay!")