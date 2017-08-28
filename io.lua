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
		local f, err = io.open(fn, 'r')
		if not f then return false, err end
		f:close()
		return true
	end
end

function io.readfile(fn)
	local f, err = io.open(fn, 'rb')
	if not f then return false, err end
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

return io
