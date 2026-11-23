--[[
  Closed Games: 1. d4 and 1. c4, replies d5 and Nf6, plus Queen's Gambit / Indian follow-ups.
]]

local Book = LibStub("LibChessOpeningBook-1.0")
Book:Register({
  id = "closed_games",
  name = "Closed Games",
  description = "1. d4 and 1. c4 with replies d5 and Nf6, plus Queen's Gambit and Indian setups.",
  elo = { 500, 1800 },
  positions = {
    ["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -"] = {
      { move = "d2d4", weight = 70 },
      { move = "c2c4", weight = 30 },
    },
    -- 1. d4
    ["rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3"] = {
      { move = "d7d5", weight = 55 },
      { move = "g8f6", weight = 45 },
    },
    -- 1. c4
    ["rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b KQkq c3"] = {
      { move = "e7e5", weight = 40 },
      { move = "g8f6", weight = 35 },
      { move = "c7c5", weight = 25 },
    },
    -- 1. d4 d5
    ["rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq d6"] = {
      { move = "c2c4", weight = 100 },
    },
    -- 1. d4 Nf6
    ["rnbqkb1r/pppppppp/5n2/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq -"] = {
      { move = "c2c4", weight = 100 },
    },
  },
})
