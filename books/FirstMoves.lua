--[[
  First Moves: the four most common opening moves from the starting position.
]]

local Book = LibStub("LibChessOpeningBook-1.0")
Book:Register({
  id = "first_moves",
  name = "First Moves",
  description = "The four most common first moves: e4, d4, Nf3, and c4.",
  elo = { 100, 600 },
  positions = {
    ["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -"] = {
      { move = "e2e4", weight = 40 },
      { move = "d2d4", weight = 30 },
      { move = "g1f3", weight = 15 },
      { move = "c2c4", weight = 15 },
    },
  },
})
