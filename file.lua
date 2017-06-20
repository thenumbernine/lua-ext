local function lfs()
	local result, lfs = pcall(require, 'lfs')
	return result and lfs
end
local function ffi()
	local result, ffi = pcall(require, 'ffi')
	return result and ffi
end

local io = require 'ext.io'

local filemeta
filemeta = {
	-- directory listing
	__call = function(t, state, lastfunc)
		assert(not lastfunc, "make sure to call() the dir")
		local lfs = lfs()
		if not lfs then
			-- no lfs?  use a fallback of shell ls or dir (based on OS)
			local fns
			-- all I'm using ffi for is reading the OS ...
--			local ffi = ffi()	-- no lfs?  are you using luajit?
--			if not ffi then
				-- if 'dir' exists ...
				--	local filestr = io.readproc('dir "'..t.path..'"')
				--	error('you are here: '..filestr)
				-- if 'ls' exists ...
				
				local string = require 'ext.string'
				local cmd
				if _G.ffi and _G.ffi.os == 'Windows' then
					cmd = 'dir /b "'..t.path:gsub('/','\\')..'"'
				else
					cmd = 'ls '..t.path:gsub('[|&;<>`\"\' \t\r\n#~=%$%(%)%%%[%*%?]', [[\%0]])
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
					local dirp = ffi.C.opendir(t.path)
					if dirp == nil then
						error('failed to open dir '..t.path)
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
					local fn = k:sub(1,1) == '/' and k or (t.path..'/'..k)
					coroutine.yield(k, io.readfile(fn))					
				end
			end)
		else
			return coroutine.wrap(function()
				for k in lfs.dir(t.path) do
					if k ~= '.' and k ~= '..' then
						local fn = k:sub(1,1) == '/' and k or (t.path..'/'..k)
						-- I shouldn't have io.readfile for performance
						--  but for convenience it is so handy...
						coroutine.yield(k, io.readfile(fn))
					end
				end
			end)
		end
	end,
	
	-- read file
	__index = function(t,k)
		local fn = k:sub(1,1) == '/' and k or (t.path..'/'..k)
		local lfs = lfs()
		if not lfs then
--			local ffi = ffi()
--			if not ffi then
				-- if no lfs then no nested read dereferences
				-- and let directories error
				if io.isdir(fn) then
					-- is a directory
					return setmetatable({
						path = fn,
					}, filemeta)
				else
					return io.readfile(fn)
				end
--[[
			else
				if ffi.os == 'Windows' then
					error('sorry windows')
				else
					error('TODO stat() for ffi...')
				end
			end
--]]
		else
			local attr = lfs.attributes(fn)
			if not attr then
				return false, "couldn't open file"
			end
			if attr.mode == 'directory' then
				return setmetatable({
					path = fn,
				}, filemeta)
			elseif attr.mode == 'file' then
				return io.readfile(fn)
			end
			return false, "can't read file"
		end
	end,
	
	-- write file
	__newindex = function(t,k,v)
		local fn = k:sub(1,1) == '/' and k or (t.path..'/'..k)
		if not v then
			if io.fileexists(fn) then
				-- throws error if something went wrong during the remove
				assert(os.remove(fn))
			end
		else
			io.writefile(fn, v)
		end
	end,
	
	__tostring = function(t)
		local s = t.path .. (t.path:sub(-1,-1) == '/' and '' or '/')
		if #s > 2 and s:sub(1,2) == './' then s = s:sub(3) end
		return 'path['..s..']'
	end,
}

local file = setmetatable({path='.'}, filemeta)

return file
