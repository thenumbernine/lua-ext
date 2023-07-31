--[[
path(pathtofile):open(mode) - to get a file handle
path(pathtofile):read() - to read a file in entirety
path(pathtofile):write() - to write to a file
path(pathtofile):dir() - to iterate through a directory listing
path(pathtofile):attr() - to get file attributes
--]]


-- [[ TODO - this block is also in ext/os.lua and ext/file.lua
local detect_os = require 'ext.detect_os'
local detect_lfs = require 'ext.detect_lfs'
local asserttype = require 'ext.asserttype'

local io = require 'ext.io'
local os = require 'ext.os'
local string = require 'ext.string'
local class = require 'ext.class'


-- TODO this goes in file or os or somewhere in ext
local function fixpath(p)
	p = string.split(p, '/')
	for i=#p-1,1,-1 do
		-- convert a//b's to a/b
		if i > 1 then	-- don't remove empty '' as the first entry - this signifies a root path
			while p[i] == '' do p:remove(i) end
		end
		-- convert a/./b's to a/b
		while p[i] == '.' do p:remove(i) end
		-- convert a/b/../c's to a/c
		if p[i+1] == '..'
		and p[i] ~= '..'
		then
			if i == 1 and p[1] == '' then
				error("/.. absolute + previous doesn't make sense")	-- don't allow /../ to remove the base / ... btw this is invalid anyways ...
			end
			p:remove(i)
			p:remove(i)
		end
	end
	return p:concat'/'
end


-- PREPEND the path if fn is relative, otherwise use fn
-- I should reverse these arguments
-- but this function is really specific to the Path path state variable
local function appendPath(fn, p)
	asserttype(fn, 'string')
	asserttype(p, 'string')
	--[[ dont change to path sep ... always use / internally
	if detect_os() then
		fn = os.path(fn)
		if not (
			fn:sub(1,1) == '\\'
			or fn:match'^[A-Z,a-z]:\\'
		) then
			fn = p .. '\\' .. fn
		end
	else
	--]]
		if fn:sub(1,1) ~= '/' then
			fn = p .. '/' .. fn
		end
	--end
	fn = fn:gsub('/%./', '/')
	fn = fn:gsub('/+', '/')
	if #fn > 2 and fn:sub(1,2) == './' then
		fn = fn:sub(3)
	end
	return fn
end


local Path = class()

--Path.sep = os.sep	-- TOO redundant?

function Path:init(args)
	self.path = asserttype(asserttype(args, 'table').path, 'string')
	assert(self.path ~= nil)
end

-- wrappers
local mappings = {
	[io] = {
		lines = 'lines',
		open = 'open',
		read = 'readfile',
		write = 'writefile',
		append = 'appendfile',
		getdir = 'getfiledir',
		getext = 'getfileext',
	},
	[os] = {
		-- vanilla
		remove = 'remove',
		-- ext
		mkdir = 'mkdir',	-- using os.mkdir instead of lfs.mkdir becasuse of fallbacks ... and 'makeParents' flag
		rmdir = 'rmdir',
		move = 'move',
		exists = 'fileexists',
		isdir = 'isdir',
		--dir = 'listdir',
		rdir = 'rlistdir',

		-- TODO what about the 'fixpath' that removes extra /'s also?
		-- make that also replace with :sep()?
		-- or make that into simplifypath() and this into fixpathsep() ?
		fixpathsep = 'path',
	},
}
local lfs = detect_lfs()
if lfs then
	mappings[lfs] = {
		attr = 'attributes',
		symattr = 'symlinkattributes',
		cd = 'chdir',
		link = 'link',
		setmode = 'setmode',
		touch = 'touch',
		--cwd = 'currentdir',		-- TODO how about some kind of cwd or something ... default 'file' obj path is '.', so how about relating this to the default. path storage?
		--mkdir = 'mkdir',			-- in 'ext.os'
		--rmdir = 'rmdir',			-- in 'ext.os'
		--lock = 'lock',			-- in 'file' objects via ext.io.open
		--unlock = 'unlock',		-- in 'file' objects via ext.io.open
		lockdir = 'lock_dir',		-- can this be combined with lock() nah since lock() needs an open file handle.
	}
end

for obj,mapping in pairs(mappings) do
	for k,v in pairs(mapping) do
		Path[k] = function(self, ...)
			return obj[v](self.path, ...)
		end
	end
end

-- [[ same as above but with non-lfs options.
-- TODO put them in io or os like I am doing to abstract non-lfs stuff elsewhere?

-- TODO return a Path instance instead of a string?
function Path:cwd()
	if lfs then
		return lfs.currentdir()
	else
		--[=[ TODO should I even bother with the non-lfs fallback?
		-- if so then use this:
		require 'ffi.req' 'c.stdlib'
		local dirp = unistd.getcwd(nil, 0)
		local dir = ffi.string(dirp)
		ffi.C.free(dirp)
		return dir
		--]=]
		if detect_os() then
			return string.trim(io.readproc'cd')
		else
			return string.trim(io.readproc'pwd')
		end
	end
end
--]]

-- os.listdir wrapper

function Path:dir(state, lastfunc)
	assert(not lastfunc, "make sure to call() the dir")
	if not os.isdir(self.path) then
		error("can't dir() a non-directory")
	end
	return os.listdir(self.path)
end

-- iirc setting __index and __newindex outside :init() is tough, since so much writing is still going on
--[[
TODO how to do the new interface?
specifically reading vs writing?

instead of __newindex for writing new files, how about path(path):write()
--]]
function Path:__call(k)
	assert(self.path ~= nil)
	local fn = asserttype(appendPath(k, self.path), 'string')
	-- is this safe?
	fn = fixpath(fn)

	-- one option is checking existence and returning nil if no file
	-- but then how about file writing?

	return Path{
		path = asserttype(fn, 'string'),
	}
end

-- clever stl idea: path(a)/path(b) = path(a..'/'..b)
Path.__div = Path.__call

-- TODO remove the wrapper?  just convert to .path? for ease of use?
function Path:__tostring()
	return 'Path['..self.path..']'
end

function Path.__concat(a,b) return tostring(a) .. tostring(b) end

local pathSys = Path{path='.'}

return pathSys
