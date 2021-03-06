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
	require 'ffi.c.sys.time'
	local gettimeofday_tv = ffi.new'struct timeval[1]'
	function T.getTime()
		local results = ffi.C.gettimeofday(gettimeofday_tv, nil)
		return tonumber(gettimeofday_tv[0].tv_sec) + tonumber(gettimeofday_tv[0].tv_usec) / 1000000
	end
end

T.depth = 0
T.tab = ' '

local function timerReturn(name, startTime, indent, ...)
	T.depth = T.depth - 1
	local endTime = T.getTime()
	T.out:write(indent..'...done ')
	if name then
		T.out:write(name..' ')
	end
	T.out:write('('..(endTime - startTime)..'s)\n')
	T.out:flush()
	return ...
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

setmetatable(T, {
	-- call forwards to timer:
	__call = function(T, ...)
		return T.timer(...)
	end,
})

return T
