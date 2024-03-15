--[[
I use this too often, so now it goes here

override T.getTime to change the timing function
override T.out to change the output file handle
--]]

local hasffi, ffi = pcall(require, 'ffi')

local T = {}

T.out = io.stderr

if not hasffi or ffi.os == 'Windows' then
	-- in linux this is the live time, or something other than the actual time
	T.getTime = os.clock
else
	require 'ffi.req' 'c.sys.time'	-- gettimeofday
	require 'ffi.req' 'c.string'		-- strerror
	local errno = require 'ffi.req' 'c.errno'
	local gettimeofday_tv = ffi.new'struct timeval[1]'
	function T.getTime()
		local result = ffi.C.gettimeofday(gettimeofday_tv, nil)
		if result ~= 0 then
			error(ffi.string(ffi.C.strerror(errno.errno())))
		end
		return tonumber(gettimeofday_tv[0].tv_sec) + tonumber(gettimeofday_tv[0].tv_usec) / 1000000
	end
end

T.depth = 0
T.tab = ' '

local function timerReturn(name, startTime, indent, ...)
	local endTime = T.getTime()
	local dt = endTime - startTime

	-- this is all printing ...
	T.depth = T.depth - 1
	T.out:write(indent..'...done ')
	if name then
		T.out:write(name..' ')
	end
	T.out:write('('..dt..'s)\n')
	T.out:flush()

	return dt, ...
end

function T.timer(name, cb, ...)
	local indent = T.tab:rep(T.depth)
	if name then
		T.out:write(indent..name..'...\n')
	end
	T.out:flush()
	local startTime = T.getTime()
	T.depth = T.depth + 1
	return timerReturn(name, startTime, indent, cb(...))
end


-- same as above but without printing (and no name too cuz we're not printing)
local function timerReturnQuiet(startTime, ...)
	local endTime = T.getTime()
	local dt = endTime - startTime
	return dt, ...
end

function T.timerQuiet(cb, ...)
	local startTime = T.getTime()
	return timerReturnQuiet(startTime, cb(...))
end


setmetatable(T, {
	-- call forwards to timer:
	__call = function(self, ...)
		return self.timer(...)
	end,
})

return T
