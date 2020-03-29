local string = require 'ext.string'

local io = {}
for k,v in pairs(require 'io') do io[k] = v end

local function lfs()
	local result, lfs = pcall(require, 'lfs')
	return result and lfs
end
local function ffi()
	local result, ffi = pcall(require, 'ffi')
	return result and ffi
end

function io.fileexists(fn)
	local lfs = lfs()
	if lfs then
		return lfs.attributes(fn) ~= nil
	else
		local ffi = ffi()
		-- TODO a better windows detect
		if ffi and ffi.os == 'Windows' then
			-- Windows reports 'false' to io.open for directories, so I can't use that ...
			return 'yes' == string.trim(io.readproc('if exist "'..fn:gsub('/','\\')..'" (echo yes) else (echo no)'))
		else
			-- here's a version that works for OSX ...
			local f, err = io.open(fn, 'r')
			if not f then return false, err end
			f:close()
			return true
		end
	end
end

function io.readfile(fn)
	local f, err = io.open(fn, 'rb')
	if not f then return false, err end

	-- file.read compat (tested on Windows)
	-- 						*a	a	*l	l 
	-- lua-5.3.5:			yes	yes	yes	yes		jit == nil and _VERSION == 'Lua 5.3'
	-- lua-5.2.4:			yes	no	yes	no		jit == nil and _VERSION == 'Lua 5.2'
	-- lua-5.1.5:			yes	no	yes	no		jit == nil and _VERSION == 'Lua 5.1'
	-- luajit-2.1.0-beta3:	yes	yes	yes	yes		(jit.version == 'LuaJIT 2.1.0-beta3' / jit.version_num == 20100)
	-- luajit-2.0.5			yes	no	yes	no		(jit.version == 'LuaJIT 2.0.5' / jit.version_num == 20005)
	local d = f:read('*a')
	f:close()
	return d
end

function io.writefile(fn, d)
	local f, err = io.open(fn, 'wb')
	if not f then return false, err end
	if d then f:write(d) end
	f:close()
	return true
end

function io.readproc(cmd)
	local f, err = io.popen(cmd)
	if not f then return false, err end
	local d = f:read('*a')
	f:close()
	return d
end

function io.getfiledir(fn)
	return fn:match('^(.*)/([^/]-)$')
end

-- this should really return the extension first.
-- that is the function name, after all.
function io.getfileext(fn)
	return fn:match('^(.*)%.([^%./]-)$')
end

function io.isdir(fn)
	local lfs = lfs()
	if lfs then
		local attr = lfs.attributes(fn)
		if not attr then return false end
		return attr.mode == 'directory'
	else
		local ffi = ffi()
		-- TODO only detect this once
		local windows
		if ffi then
			windows = ffi.os == 'Windows'
		else
			windows = ({
				msys = true,
				ming = true,
			})[io.popen'uname':read'*l':sub(1,4):lower()]
		end
		if windows then
			return 'yes' == 
				string.trim(io.readproc(
					'if exist "'
					..fn:gsub('/','\\')
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

-- in Lua 5.3.5 at least:
-- (for file = getmetatable(io.open(something)))
-- io.read ~= file.read
-- file.__index == file
-- within meta.lua, simply modifying the file metatable 
-- but if someone requires ext/io.lua and not lua then io.open and all subsequently created files will need to be modified
if jit or (not jit and _VERSION < 'Lua 5.2') then

	local function fixfilereadargs(...)
		if select('#', ...) == 0 then return ... end
		local fmt = select(1, ...)
		if fmt == 'a' then fmt = '*a'
		elseif fmt == 'l' then fmt = '*l'
		elseif fmt == 'n' then fmt = '*n'
		end
		return fmt, fixfilereadargs(select(2, ...))
	end
	
	-- even though io.read is basically the same as file.read, they are still different functions
	-- so file.read will still have to be separately overridden
	local oldfileread
	local function newfileread(...)
		return oldfileread(fixfilereadargs(...))
	end
	io.read = function(...)
		return newfileread(io.stdout, ...)
	end
	
	local oldfilemeta = debug.getmetatable(io.stdout)
	local newfilemeta = {}
	for k,v in pairs(oldfilemeta) do
		newfilemeta[k] = v
	end

	-- override file:read
	oldfileread = oldfilemeta.read
	newfilemeta.read = newfileread 

	-- should these be overridden in this case, or only when running ext/meta.lua?
	debug.setmetatable(io.stdin, newfilemeta)
	debug.setmetatable(io.stdout, newfilemeta)
	debug.setmetatable(io.stderr, newfilemeta)

	local function fixfilemeta(...)
		if select('#', ...) > 0 then
			local f = select(1, ...)
			if f then
				debug.setmetatable(f, newfilemeta)
			end
		end
		return ...
	end

	local oldioopen = io.open
	function io.open(...)
		return fixfilemeta(oldioopen(...))
	end
end

function io.dir(path)
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
			if _G.ffi and _G.ffi.os == 'Windows' then
				cmd = 'dir /b "'..path:gsub('/','\\')..'"'
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
--]]
function io.rdir(path, callback, fs)
	local table = require 'ext.table'
	fs = fs or table()
	for f in io.dir(path) do
		if io.isdir(path..'/'..f) then
			if f ~= '.' and f ~= '..' then
				if not callback or callback(f, true) then
					io.rdir(path..'/'..f, callback, fs)
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

return io
