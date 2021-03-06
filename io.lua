local string = require 'ext.string'

local io = {}
for k,v in pairs(require 'io') do io[k] = v end

-- io or os?  io since it is shorthand for io.open():read()
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


-- deprecated - moved to os.fileexists
function io.fileexists(...)
	io.stderr:write('io.fileexists deprecated - use os.fileexists\n')
	return require 'ext.os'.fileexists(...)
end

-- deprecated - moved to os.isdir
function io.isdir(...)
	io.stderr:write('io.isdir deprecated - use os.isdir\n')
	return require 'ext.os'.isdir(...)
end

-- deprecated - moved to os.listdir
function io.dir(...)
	io.stderr:write('io.dir deprecated - use os.listdir\n')
	return require 'ext.os'.listdir(...)
end

-- deprecated - moved to os.rlistdir
function io.rdir(...)
	io.stderr:write('io.rdir deprecated - use os.rlistdir\n')
	return require 'ext.os'.rlistdir(...)
end

return io
