--[[
  Polyglot converter unit tests.
  Decodes moves and groups hand-built 16-byte records. No binary fixture.
]]

local Test = require("test")

Test.suite("PolyglotConvert", "polyglotconvert")

local function loadConvert()
  local sep = package.config:sub(1, 1)
  local paths = {
    "Libs" .. sep .. "LibChessOpeningBook" .. sep .. "PolyglotConvert.lua",
  }
  local info = debug.getinfo(1, "S").source
  if info:sub(1, 1) == "@" then
    local dir = info:sub(2):match("^(.*)[/\\][^/\\]+$")
    if dir then
      paths[#paths + 1] = dir .. sep .. ".." .. sep .. "PolyglotConvert.lua"
    end
  end
  for i = 1, #paths do
    local fn = loadfile(paths[i])
    if fn then
      return fn()
    end
  end
  error("PolyglotConvert.lua not found")
end

local Convert = loadConvert()

Test.test("DecodeMove e2e4", function()
  -- from e2=12, to e4=28 -> 28 + 12*64 = 796
  Test.assertEq(Convert.DecodeMove(796), "e2e4")
end)

Test.test("DecodeMove promotion e7e8q", function()
  -- from e7=52, to e8=60, promo queen=4 -> 60 + 52*64 + 4*4096 = 19772
  Test.assertEq(Convert.DecodeMove(19772), "e7e8q")
end)

Test.test("DecodeMove castling as king move e1g1", function()
  -- Polyglot white kingside is e1h1 (from=4, to=7) -> 7 + 4*64 = 263
  Test.assertEq(Convert.DecodeMove(263), "e1g1")
end)

Test.test("ParseRecords groups a start-position e2e4 entry", function()
  -- key 463b96181691fc9c, move 0x031c, weight 40, learn 0
  local rec = string.char(
    0x46, 0x3b, 0x96, 0x18, 0x16, 0x91, 0xfc, 0x9c,
    0x03, 0x1c,
    0x00, 0x28,
    0x00, 0x00, 0x00, 0x00
  )
  local entries = Convert.ParseRecords(rec)
  local moves = entries["463b96181691fc9c"]
  Test.assertNotNil(moves)
  Test.assertEq(#moves, 1)
  Test.assertEq(moves[1].move, "e2e4")
  Test.assertEq(moves[1].weight, 40)
end)

Test.test("ParseRecords drops weight 0", function()
  local rec = string.char(
    0x46, 0x3b, 0x96, 0x18, 0x16, 0x91, 0xfc, 0x9c,
    0x03, 0x1c,
    0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
  )
  local entries = Convert.ParseRecords(rec)
  Test.assertNil(entries["463b96181691fc9c"])
end)

Test.test("EncodeLua emits a Register call", function()
  local lua = Convert.EncodeLua({
    id = "gm",
    name = "GM",
    description = "Test",
    entries = {
      ["463b96181691fc9c"] = { { move = "e2e4", weight = 40 } },
    },
  })
  Test.assertTrue(lua:find('LibStub%("LibChessOpeningBook%-1%.0"%)', 1) ~= nil)
  Test.assertTrue(lua:find("Book:Register", 1, true) ~= nil)
  Test.assertTrue(lua:find('id = "gm"', 1, true) ~= nil)
  Test.assertTrue(lua:find("e2e4", 1, true) ~= nil)
end)

Test.test("EncodeLua includes elo when set", function()
  local lua = Convert.EncodeLua({
    id = "gm",
    name = "GM",
    elo = { 1800, 2400 },
    entries = {},
  })
  Test.assertTrue(lua:find("elo = { 1800, 2400 }", 1, true) ~= nil)
end)
