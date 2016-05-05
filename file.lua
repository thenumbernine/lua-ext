--[[
	Copyright (c) 2015 Christopher E. Moore ( christopher.e.moore@gmail.com / http://christopheremoore.net )

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
--]]

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
			-- all I'm using ffi for is reading the OS ...
			local ffi = ffi()	-- no lfs?  are you using luajit?
			if not ffi then
				error("directory listing only available with lfs or ffi")
			else
				-- do a directory listing
				local fns
				-- TODO escape?
				if ffi.os == 'Windows' then
					local filestr = io.readproc('dir "'..t.path..'"')
					error('you are here: '..filestr)
				else
					local filestr = io.readproc('ls '..t.path:gsub([[|&;<>`\"' \t\r\n#~=%$%(%)%%%[%*%?]], [[\%0]]))
					fns = filestr:split'\n'
					assert(fns:remove() == '')
				end
				return coroutine.wrap(function()
					for _,k in ipairs(fns) do
						local fn = k:sub(1,1) == '/' and k or (t.path..'/'..k)
						coroutine.yield(k, io.readfile(fn))					
					end
				end)
			end
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
		local lfs = lfs()
		if not lfs then
			-- if no lfs then no nested read dereferences
			return io.readfile(k)
		else
			local fn = k:sub(1,1) == '/' and k or (t.path..'/'..k)
			local attr = lfs.attributes(fn)
			if not attr then
				return false, "couldn't open file"
			end
			if attr.mode == 'directory' then
				return setmetatable({
					path = fn
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

