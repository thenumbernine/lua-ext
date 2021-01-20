-- [[ TODO - this block is also in ext/io.lua and ext/file.lua

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
		})[io.popen'uname':read'*l':sub(1,4):lower()]
	end
end

--]]


local io = require 'ext.io'
local os = require 'ext.os'

local filemeta
filemeta = {
	-- directory listing
	__call = function(t, state, lastfunc)
		assert(not lastfunc, "make sure to call() the dir")
		return os.listdir(t.path)
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
				if os.isdir(fn) then
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
		local fn = k
		if windows() then
			fn = fn:gsub('/', '\\')
			if not (
				fn:sub(1,1) == '\\' 
				or fn:match'^[A-Z,a-z]:\\'
			) then
				fn = t.path .. '\\' .. fn
			end
		else
			if fn:sub(1,1) ~= '/' then
				fn = t.path .. '/' .. fn
			end
		end
		if not v then
			if os.fileexists(fn) then
				-- throws error if something went wrong during the remove
				assert(os.remove(fn))
			end
		else
			local tolua = require 'ext.tolua'
			print('t.path = '..tolua(t.path))
			print('k = '..tolua(t.path))
			print('fn '..tolua(fn))
			print(io.writefile(fn, v))
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
