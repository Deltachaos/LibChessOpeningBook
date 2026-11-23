--[[
  Open Games: 1. e4 and the usual replies, plus one white follow-up on the main lines.
]]

local Book = LibStub("LibChessOpeningBook-1.0")
Book:Register({
  id = "open_games",
  name = "Open Games",
  description = "1. e4 with replies e5, c5, e6, and c6, plus a main-line follow-up.",
  elo = { 500, 1800 },
  positions = {
    ["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -"] = {
      { move = "e2e4", weight = 100 },
    },
    -- 1. e4
    ["rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3"] = {
      { move = "e7e5", weight = 40 },
      { move = "c7c5", weight = 35 },
      { move = "e7e6", weight = 15 },
      { move = "c7c6", weight = 10 },
    },
    -- 1. e4 e5
    ["rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6"] = {
      { move = "g1f3", weight = 100 },
    },
    -- 1. e4 c5
    ["rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6"] = {
      { move = "g1f3", weight = 100 },
    },
    -- 1. e4 e6
    ["rnbqkbnr/pppp1ppp/4p3/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"] = {
      { move = "d2d4", weight = 100 },
    },
    -- 1. e4 c6
    ["rnbqkbnr/pp1ppppp/2p5/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"] = {
      { move = "d2d4", weight = 100 },
    },
  },
})
