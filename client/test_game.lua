local lah = require "games/lah"

local game = lah:new_game()

-- testing
game:add_player("shakesoda")
game:add_player("karai")
game:add_player("freem")

-- Round 1
game:set_czar(3)
game:draw_card(10)
game:begin_round()

game:play_card("black", 123, "freem")
game:play_card("white", 12345, "karai")
game:play_card("white", 12846, "shakesoda")
game:shuffle_submit()

game:begin_vote()
game:vote(12345)
game:award("karai")
game:end_round()

-- Round 2
game:set_czar(1)
game:draw_card(1)
game:begin_round()

game:play_card("black", 123, "shakesoda")
game:play_card("white", 12345, "karai")
game:play_card("white", 12846, "freem")
game:shuffle_submit()

game:begin_vote()
game:vote(12345)
game:award("karai")
game:end_round()

-- Round 3
game:set_czar(2)
game:draw_card(1)
game:begin_round()

game:play_card("black", 123, "karai")
game:play_card("white", 12345, "shakesoda")
game:play_card("white", 12846, "freem")
game:shuffle_submit()

game:begin_vote()
game:vote(12345)
game:award("shakesoda")
game:end_round()