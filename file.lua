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
		return io.dir(t.path)
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
