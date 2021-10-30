local os = {}
for k,v in pairs(require 'os') do os[k] = v end

-- for io.readproc
-- don't require os from inside io ...
local io = require 'ext.io'

-- table.pack
local table = require 'ext.table'

-- string.trim
local string = require 'ext.string'

-- [[ TODO - this block is also in ext/file.lua

local function asserttype(x, t)
	local xt = type(x)
	assert(xt == t, "expected "..t.." found "..xt)
	return x
end

local function lfs()
	local result, lfs = pcall(require, 'lfs')
	return result and lfs
end


local function ffi()
	local result, ffi = pcall(require, 'ffi')
	return result and ffi
end

-- TODO only detect this once?
local function windows()
	local ffi = ffi()
	if ffi then
		return ffi.os == 'Windows'
	else
		return ({
			msys = true,
			ming = true,
		})[(io.popen'uname 2> NIL':read'*a'):sub(1,4):lower()]
	end
end

os.sep = windows() and '\\' or '/'

function os.path(str)
	asserttype(str, 'string')
	return (str:gsub('/', os.sep))
end

--]]

-- 5.2 os.execute compat
if _VERSION == 'Lua 5.1' then
	local execute = os.execute
	function os.execute(cmd)
		local results = table.pack(execute(cmd))
		if #results > 1 then return table.unpack(results, 1, results.n) end
		local errcode = execute(cmd)
		local reason = ({
			[0] = 'exit',
		})[errcode] or 'unknown'
		return errcode == 0 and true or nil, reason, errcode
	end
end

-- TODO should this fail if the dir already exists?  or should it succeed?
-- should it fail if a file is presently there? probably.
-- should makeParents be set by default?  it's on by default in Windows.
function os.mkdir(dir, makeParents)
	local tonull
	if windows() then
		dir = os.path(dir)
		tonull = ' 2> nul'
		makeParents = nil -- mkdir in Windows always makes parents, and doesn't need a switch
	else
		tonull = ' 2> /dev/null'
	end
	local cmd = 'mkdir'..(makeParents and ' -p' or '')..' '..('%q'):format(dir)..tonull
	return os.execute(cmd)
end

function os.rmdir(dir)
	local cmd = 'rmdir "'..os.path(dir)..'"'
	return os.execute(cmd)
end

function os.move(from, to)
	-- [[
	-- alternatively I could write this as readfile/writefile and os.remove
	local cmd = (windows() and 'move' or 'mv') .. ' "'..os.path(from)..'" "'..os.path(to)..'"'
	return os.execute(cmd)
	--]]
	--[[
	file[from], file[to] = nil, file[from]
	--]]
end

function os.isdir(fn)
	local lfs = lfs()
	if lfs then
		local attr = lfs.attributes(fn)
		if not attr then return false end
		return attr.mode == 'directory'
	else
		if windows() then
			return 'yes' == 
				string.trim(io.readproc(
					'if exist "'
					..os.path(fn)
					..'\\*" (echo yes) else (echo no)'
				))
		else
			-- for OSX:
			-- TODO you could work around this for directories: 
			-- f:read(1) for 5.1,jit,5.2,5.3 returns nil, 'Is a directory', 21
			local f = io.open(fn,'rb')
			if not f then return false end
			local result, reason, errcode = f:read(1)
			f:close()
			if result == nil
			and reason == 'Is a directory'
			and errcode == 21
			then
				return true
			end
			return false
		end
	end
end

function os.listdir(path)
	local lfs = lfs()
	if not lfs then
		-- no lfs?  use a fallback of shell ls or dir (based on OS)
		local fns
		-- all I'm using ffi for is reading the OS ...
--			local ffi = ffi()	-- no lfs?  are you using luajit?
--			if not ffi then
			-- if 'dir' exists ...
			--	local filestr = io.readproc('dir "'..path..'"')
			--	error('you are here: '..filestr)
			-- if 'ls' exists ...
			
			local string = require 'ext.string'
			local cmd
			if windows() then
				cmd = 'dir /b "'..os.path(path)..'"'
			else
				cmd = 'ls '..path:gsub('[|&;<>`\"\' \t\r\n#~=%$%(%)%%%[%*%?]', [[\%0]])
			end
			local filestr = io.readproc(cmd)
			fns = string.split(filestr, '\n')
			assert(fns:remove() == '')
--[[
		else
			-- do a directory listing
			-- TODO escape?
			if ffi.os == 'Windows' then
				-- put your stupid FindFirstFile/FindNextFile code here
				error('windows sucks...')
			else
				fns = {}
				require 'ffi.c.dirent'
				-- https://stackoverflow.com/questions/10678522/how-can-i-get-this-readdir-code-sample-to-search-other-directories
				local dirp = ffi.C.opendir(path)
				if dirp == nil then
					error('failed to open dir '..path)
				end
				repeat
					local dp = ffi.C.readdir(dirp)
					if dp == nil then break end
					local name = ffi.string(dp[0].d_name)
					if name ~= '.' and name ~= '..' then
						table.insert(fns, name)
					end
				until false
				ffi.C.closedir(dirp)
			end
		end
--]]
		return coroutine.wrap(function()
			for _,k in ipairs(fns) do
				local fn = k:sub(1,1) == '/' and k or (path..'/'..k)
				coroutine.yield(k)--, io.readfile(fn))					
			end
		end)
	else
		return coroutine.wrap(function()
			for k in lfs.dir(path) do
				if k ~= '.' and k ~= '..' then
					local fn = k:sub(1,1) == '/' and k or (path..'/'..k)
					-- I shouldn't have io.readfile for performance
					--  but for convenience it is so handy...
					coroutine.yield(k)--, io.readfile(fn))
				end
			end
		end)
	end
end

--[[ recurse directory
args:
	path = directory to search from
	callback(filename, isdir) = optional callback to filter each file

should this be in io or os?
should this be an iterator like os.listdir() is?
--]]
function os.rlistdir(path, callback, fs)
	local table = require 'ext.table'
	fs = fs or table()
	for f in os.listdir(path) do
		if os.isdir(path..'/'..f) then
			if f ~= '.' and f ~= '..' then
				if not callback or callback(f, true) then
					os.rlistdir(path..'/'..f, callback, fs)
				end
			end
		else
			if not callback or callback(f, false) then
				fs:insert(path..'/'..f)
			end
		end
	end
	return fs
end

function os.fileexists(fn)
	assert(fn, "expected filename")
	local lfs = lfs()
	if lfs then
		return lfs.attributes(fn) ~= nil
	else
		if windows() then
			-- Windows reports 'false' to io.open for directories, so I can't use that ...
			return 'yes' == string.trim(io.readproc('if exist "'..os.path(fn)..'" (echo yes) else (echo no)'))
		else
			-- here's a version that works for OSX ...
			local f, err = io.open(fn, 'r')
			if not f then return false, err end
			f:close()
			return true
		end
	end
end

return os
