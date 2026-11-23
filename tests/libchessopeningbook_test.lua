--[[
  LibChessOpeningBook unit tests.
  Polyglot hashing, registration, listing, and lookup.
]]

local Test = require("test")
local Book = LibStub("LibChessOpeningBook-1.0")

Test.suite("LibChessOpeningBook", "libchessopeningbook")

local START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
local E4_FEN = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"

local function withTempBook(book, fn)
  local prev = Book.books[book.id]
  Test.assertTrue(Book:Register(book), "Register should succeed")
  local ok, err = pcall(fn)
  if prev then
    Book.books[book.id] = prev
  else
    Book.books[book.id] = nil
  end
  if not ok then error(err) end
end

--------------------------------------------------------------------------------
-- Polyglot hashes
--------------------------------------------------------------------------------

Test.test("HashFen of the start position", function()
  Test.assertEq(Book.HashFen(START_FEN), "463b96181691fc9c")
end)

Test.test("HashFen after e2e4", function()
  Test.assertEq(Book.HashFen(E4_FEN), "823c9b50fd114196")
end)

Test.test("HashFen ignores halfmove and fullmove clocks", function()
  Test.assertEq(
    Book.HashFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -"),
    "463b96181691fc9c"
  )
end)

--------------------------------------------------------------------------------
-- Registry
--------------------------------------------------------------------------------

Test.test("Shipped books are listed by name", function()
  local list = Book:GetBookList()
  local byId = {}
  for i = 1, #list do
    byId[list[i].id] = list[i]
  end
  Test.assertNotNil(byId.first_moves, "first_moves should ship")
  Test.assertNotNil(byId.open_games, "open_games should ship")
  Test.assertNotNil(byId.closed_games, "closed_games should ship")
  Test.assertEq(byId.first_moves.name, "First Moves")
  Test.assertEq(byId.first_moves.minElo, 100)
  Test.assertEq(byId.first_moves.maxElo, 600)
  Test.assertEq(byId.open_games.minElo, 500)
  Test.assertEq(byId.closed_games.maxElo, 1800)
  for i = 2, #list do
    Test.assertTrue(list[i - 1].name <= list[i].name, "list should be sorted by name")
  end
end)

Test.test("Register replaces a book by id", function()
  withTempBook({
    id = "test_replace",
    name = "First",
    positions = {
      [START_FEN] = { { move = "e2e4", weight = 1 } },
    },
  }, function()
    Test.assertEq(Book:GetBook("test_replace").name, "First")
    Book:Register({
      id = "test_replace",
      name = "Second",
      positions = {
        [START_FEN] = { { move = "d2d4", weight = 1 } },
      },
    })
    local b = Book:GetBook("test_replace")
    Test.assertEq(b.name, "Second")
    local hits = Book:Lookup(START_FEN, "test_replace")
    Test.assertEq(#hits, 1)
    Test.assertEq(hits[1].move, "d2d4")
  end)
end)

Test.test("Register rejects a book without id or name", function()
  Test.assertTrue(not Book:Register({ name = "No Id" }))
  Test.assertTrue(not Book:Register({ id = "no_name" }))
  Test.assertTrue(not Book:Register(nil))
end)

Test.test("GetBook returns nil for unknown ids", function()
  Test.assertNil(Book:GetBook("no_such_book_xyz"))
end)

--------------------------------------------------------------------------------
-- Lookup and weights
--------------------------------------------------------------------------------

Test.test("Lookup finds first_moves from FEN", function()
  local hits = Book:Lookup(START_FEN, "first_moves")
  local moves = {}
  for i = 1, #hits do
    moves[hits[i].move] = hits[i].weight
    Test.assertEq(hits[i].bookId, "first_moves")
  end
  Test.assertEq(moves.e2e4, 40)
  Test.assertEq(moves.d2d4, 30)
  Test.assertEq(moves.g1f3, 15)
  Test.assertEq(moves.c2c4, 15)
end)

Test.test("Lookup by Polyglot hash via entries", function()
  withTempBook({
    id = "test_hash_entry",
    name = "Hash Entry",
    entries = {
      ["463b96181691fc9c"] = { { move = "a2a3", weight = 7 } },
    },
  }, function()
    local hits = Book:Lookup(START_FEN, "test_hash_entry")
    Test.assertEq(#hits, 1)
    Test.assertEq(hits[1].move, "a2a3")
    Test.assertEq(hits[1].weight, 7)
  end)
end)

Test.test("Register sums weights for the same move", function()
  withTempBook({
    id = "test_weights",
    name = "Weights",
    positions = {
      [START_FEN] = {
        { move = "e2e4", weight = 10 },
        { move = "e2e4", weight = 5 },
        { move = "d2d4", weight = 3 },
      },
    },
  }, function()
    local hits = Book:Lookup(START_FEN, "test_weights")
    local byMove = {}
    for i = 1, #hits do
      byMove[hits[i].move] = hits[i].weight
    end
    Test.assertEq(byMove.e2e4, 15)
    Test.assertEq(byMove.d2d4, 3)
  end)
end)

Test.test("Lookup with nil bookIds searches every book", function()
  local hits = Book:Lookup(START_FEN)
  Test.assertTrue(#hits >= 4, "start position should have shipped book moves")
end)

Test.test("Lookup misses a position with no book entry", function()
  local hits = Book:Lookup("4k3/8/8/8/8/8/8/4K3 w - - 0 1", "first_moves")
  Test.assertEq(#hits, 0)
end)

--------------------------------------------------------------------------------
-- Depth and ELO
--------------------------------------------------------------------------------

Test.test("PlyFromFen at start and after e4", function()
  Test.assertEq(Book.PlyFromFen(START_FEN), 0)
  Test.assertEq(Book.PlyFromFen(E4_FEN), 1)
end)

Test.test("Lookup honors book depth", function()
  Test.assertTrue(#Book:Lookup(START_FEN, "first_moves", 1) > 0)
  Test.assertEq(#Book:Lookup(START_FEN, "first_moves", 0), 0)
  Test.assertTrue(#Book:Lookup(E4_FEN, "open_games", 2) > 0)
  Test.assertEq(#Book:Lookup(E4_FEN, "open_games", 1), 0)
end)

Test.test("SelectMove returns nil when depth is exhausted", function()
  Test.assertNil(Book:SelectMove(E4_FEN, "open_games", 1))
  local hit = Book:SelectMove(START_FEN, "first_moves", 1)
  Test.assertNotNil(hit)
  Test.assertNotNil(hit.move)
end)

Test.test("GetBooksForElo picks in-range books", function()
  local low = Book:GetBooksForElo(200)
  Test.assertEq(#low, 1)
  Test.assertEq(low[1].id, "first_moves")

  local mid = Book:GetBooksForElo(800)
  local ids = {}
  for i = 1, #mid do
    ids[mid[i].id] = true
  end
  Test.assertTrue(ids.open_games)
  Test.assertTrue(ids.closed_games)
  Test.assertTrue(not ids.first_moves)
end)

Test.test("GetBooksForElo falls back to the nearest book", function()
  local high = Book:GetBooksForElo(2500)
  local ids = {}
  for i = 1, #high do
    ids[high[i].id] = true
  end
  Test.assertTrue(ids.open_games)
  Test.assertTrue(ids.closed_games)
  Test.assertTrue(not ids.first_moves)
end)

--------------------------------------------------------------------------------
-- Framework wrapper
--------------------------------------------------------------------------------

Test.test("DeltaChess.OpeningBook is available", function()
  local OpeningBook = LibStub("DeltachessFramework-1.0").OpeningBook
  Test.assertTrue(OpeningBook.IsAvailable())
  local list = OpeningBook.GetBookList()
  Test.assertTrue(#list >= 3)
end)

Test.test("SelectMove returns a legal start-position move", function()
  local OpeningBook = LibStub("DeltachessFramework-1.0").OpeningBook
  local hit = OpeningBook.SelectMove(START_FEN, "first_moves")
  Test.assertNotNil(hit)
  local allowed = { e2e4 = true, d2d4 = true, g1f3 = true, c2c4 = true }
  Test.assertTrue(allowed[hit.move], "move should be from first_moves")
  Test.assertEq(hit.bookId, "first_moves")
  Test.assertNotNil(hit.san)
end)

Test.test("SelectMove returns nil off book", function()
  local OpeningBook = LibStub("DeltachessFramework-1.0").OpeningBook
  Test.assertNil(OpeningBook.SelectMove("4k3/8/8/8/8/8/8/4K3 w - - 0 1", "first_moves"))
end)

Test.test("SelectMove honors depth", function()
  local OpeningBook = LibStub("DeltachessFramework-1.0").OpeningBook
  Test.assertNil(OpeningBook.SelectMove(E4_FEN, "open_games", 1))
  Test.assertNotNil(OpeningBook.SelectMove(E4_FEN, "open_games", 2))
end)

Test.test("DepthForElo scales with strength", function()
  local OpeningBook = LibStub("DeltachessFramework-1.0").OpeningBook
  local low = OpeningBook.DepthForElo(100)
  local high = OpeningBook.DepthForElo(2600)
  Test.assertEq(low, 1)
  Test.assertEq(high, 16)
  Test.assertTrue(OpeningBook.DepthForElo(1350) > low)
  Test.assertTrue(OpeningBook.DepthForElo(1350) < high)
end)

Test.test("GetBooksForElo is exposed on DeltaChess.OpeningBook", function()
  local OpeningBook = LibStub("DeltachessFramework-1.0").OpeningBook
  local list = OpeningBook.GetBooksForElo(200)
  Test.assertEq(#list, 1)
  Test.assertEq(list[1].id, "first_moves")
end)
