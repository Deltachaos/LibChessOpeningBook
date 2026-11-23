#!/usr/bin/env lua
--[[
  Convert a Polyglot .bin opening book to a Lua file that registers with
  LibChessOpeningBook-1.0.

  Usage:
    lua Libs/LibChessOpeningBook/bin/polyglot2lua.lua book.bin out.lua --id gm --name "GM"
]]

local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then source = source:sub(2) end
local scriptDir = source:match("^(.*)[/\\][^/\\]+$") or "."
local sep = package.config:sub(1, 1)
local libDir = scriptDir .. sep .. ".."
package.path = libDir .. sep .. "?.lua;" .. package.path

local Convert = require("PolyglotConvert")

local function usage()
  io.stderr:write("Usage: lua polyglot2lua.lua <book.bin> <out.lua> --id <id> [--name <name>] [--description <text>] [--elo <n>] [--min-elo <n>] [--max-elo <n>]\n")
  os.exit(1)
end

local args = {}
local i = 1
while i <= #arg do
  local a = arg[i]
  if a == "--id" then
    args.id = arg[i + 1]
    i = i + 2
  elseif a == "--name" then
    args.name = arg[i + 1]
    i = i + 2
  elseif a == "--description" then
    args.description = arg[i + 1]
    i = i + 2
  elseif a == "--elo" then
    args.elo = tonumber(arg[i + 1])
    i = i + 2
  elseif a == "--min-elo" then
    args.minElo = tonumber(arg[i + 1])
    i = i + 2
  elseif a == "--max-elo" then
    args.maxElo = tonumber(arg[i + 1])
    i = i + 2
  elseif a:sub(1, 1) == "-" then
    usage()
  elseif not args.bin then
    args.bin = a
    i = i + 1
  elseif not args.out then
    args.out = a
    i = i + 1
  else
    usage()
  end
end

if not args.bin or not args.out or not args.id then
  usage()
end
args.name = args.name or args.id
args.description = args.description or ""

local f = io.open(args.bin, "rb")
if not f then
  io.stderr:write("Cannot open " .. args.bin .. "\n")
  os.exit(1)
end
local data = f:read("*a")
f:close()

local elo
if args.minElo or args.maxElo then
  elo = { args.minElo or args.maxElo, args.maxElo or args.minElo }
elseif args.elo then
  elo = args.elo
end

local entries = Convert.ParseRecords(data)
local lua = Convert.EncodeLua({
  id = args.id,
  name = args.name,
  description = args.description,
  elo = elo,
  entries = entries,
})

local out = io.open(args.out, "w")
if not out then
  io.stderr:write("Cannot write " .. args.out .. "\n")
  os.exit(1)
end
out:write(lua)
out:close()
