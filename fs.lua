--[[
fs = filesystem ... this will replace old "file", but i realize that's gonna take a big overhaul of every project that depends on "file"

this is turning into a very shy wrapper to lfs ... and to io.readfile / io.writefile ... and then the vanilla Lua io file stuff

file[path]:open(mode) - to get a file handle
file[path]:read() - to read a file in entirety
file[path]:write() - to write to a file
file[path]:dir() - to iterate through a directory listing
file[path]:attr() - to get file attributes
--]]


-- [[ TODO - this block is also in ext/os.lua and ext/file.lua
local detect_os = require 'ext.detect_os'
local detect_lfs = require 'ext.detect_lfs'
local asserttype = require 'ext.asserttype'

local io = require 'ext.io'
local os = require 'ext.os'
local class = require 'ext.class'

-- append the path if fn is relative, otherwise use fn
local function appendPath(fn, path)
	asserttype(fn, 'string')
	asserttype(path, 'string')
	if detect_os() then
		fn = os.path(fn)
		if not (
			fn:sub(1,1) == '\\'
			or fn:match'^[A-Z,a-z]:\\'
		) then
			fn = path .. '\\' .. fn
		end
	else
		if fn:sub(1,1) ~= '/' then
			fn = path .. '/' .. fn
		end
	end
	return fn
end


local FileSys = class()

function FileSys:init(args)
	self.path = asserttype(asserttype(args, 'table').path, 'string')
	assert(self.path ~= nil)
end

function FileSys:dir(state, lastfunc)
	assert(not lastfunc, "make sure to call() the dir")
	if not os.isdir(self.path) then 
		error("can't dir() a non-directory") 
	end
	return os.listdir(self.path)
end

function FileSys:attr()
	local lfs = detect_lfs()
	return lfs.attributes(self.path)
end

function FileSys:read()
	return io.readfile(self.path)
end

function FileSys:write(data)
	return io.writefile(self.path, data)
end

function FileSys:open(...)
	return io.open(self.path, ...)
end

-- iirc setting __index and __newindex outside :init() is tough, since so much writing is still going on
--[[
TODO how to do the new interface?
specifically reading vs writing?

instead of __newindex for writing new files, how about file(path):write()
--]]
function FileSys:__call(k)
	assert(self.path ~= nil)
	local fn = asserttype(appendPath(k, self.path), 'string')
	
	-- one option is checking existence and returning nil if no file
	-- but then how about file writing?

	return FileSys{
		path = asserttype(fn, 'string'),
	}
end

function FileSys:__tostring()
	local s = self.path
	if #s > 2 and s:sub(1,2) == './' then s = s:sub(3) end
	return 'FileSys['..s..']'
end


local fileSys = FileSys{path='.'}

return fileSys
