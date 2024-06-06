--[[
shim load() and loadstring() and loadfile() layer
comes with callback handler for various AST or string modifications

For now I'm not going to add this to ext.env since it just outright modifies _G and not a specified env.
I'm not sure if or when I'll change it to operate on specific envs.
--]]
local env = _G	-- TODO return function(env)  maybe?

require 'ext.xpcall'(env)

-- package.searchpath is missing in 5.1 (but not luajit) ... I need a package.searchpath
-- Put in its own file?  does anyone else need this?  or not since it pairs with my require-override, which is in this file too.
local searchpath = package.searchpath
if not searchpath then
	function searchpath(name, path, sep, rep)
		sep = sep or ';'
		rep = rep or '/'	-- or \ for windows ... TODO meh?
		local namerep = name:gsub('%.', rep)
		local attempted = {}
		for w in path:gmatch('[^'..sep..']*') do	-- TODO escape sep? meh?
			local fn = w
			if fn == '' then	-- search default locations ... which are ... builtin ... or not?
			else
				fn = fn:gsub('%?', namerep)
				-- path(fn):exists() implementation:
				local exists = io.open(fn,'rb')
				if exists then
					exists:close()
					return fn
				end
				table.insert(attempted, "\n\tno file '"..fn.."'")
			end
		end
		return nil, table.concat(attempted)
	end
end

-- used for error reporting in newload()
-- ... too bad there's no easy way to get around the need for this ...
-- ... like maybe in the future preserve all comments and whitespaces and newlines, and regen the source with those so as little as possible has changed ...
local showcode = require 'template.showcode'

local xforms = setmetatable({}, {__index=table})

-- TODO proper test?  like if load'string' fails?
local loadUsesFunctions = (_VERSION == 'Lua 5.1' and not env.jit)
local oldload = loadUsesFunctions and loadstring or load

-- ok here's my modified load behavior
-- it's going to parse the lua 5.4 code and spit out the luajit code
local function newload(data, ...)
	-- 5.1 behavior: load(func, name) versus loadstring(data, name)
	-- 5.2..5.4 behavior: load(chunk, name, mode, env)
	-- TODO mind you the formatting on re-converting it will be off ...
	-- errors won't match up ...
	-- so I'll re-insert the generated code
	-- TODO would be nice to save whitespace and re-insert that ... hmm maybe long into the future ...
	-- TODO xpcall behavior testing for when we are allowed to forward the args ... maybe that compat behavior belongs in ext ?
	local source = ... or ('['..data:sub(1,10)..'...]')
	local success, result = xpcall(function(...)
		for i,xform in ipairs(xforms) do
			data = xform(data, source)
			if not data then error("ext.load.xform["..i.."] produced nothing for source "..tostring(source)) end
		end
		return assert(oldload(data, ...))
	end, function(err)
		return 'error for source: '..tostring(source)..'\n'
			..(data and showcode(data)..'\n' or '')
			..err..'\n'
			..debug.traceback()
	end, ...)
	if not success then return nil, result end
	return result
end

-- override global load() function, and maybe loadfile() if it's present too
-- (maybe loadstring() too ?)
if env.loadstring ~= nil then env.loadstring = newload end
-- TODO if we're in luajit (_VERSION=Lua 5.1) then load() will handle strings, but if we're in lua 5.1 then it will only handle functions (according to docs?) right?
env.load = newload

local function newloadfile(filename, ...)
	local f, err = io.open(filename, 'rb')
	if not f then return nil, err end
	local data, err = f:read'*a'
	f:close()
	if err then return nil, err end

	return newload(data, filename, ...)
end
env.loadfile = newloadfile

-- next TODO here , same as ext.debug (consider making modular)
-- ... wedge in new package.seachers[2]/package.loaders[2] behavior to use my modified load()
-- replace the package.loaders[2] / package.searchers[2] table entry
-- make it to replace file contents before loading
local searchers = assert(package.searchers or package.loaders, "couldn't find searchers")
local oldsearchfile = searchers[2]
local function newsearchfile(req, ...)
	local filename, err = searchpath(req, package.path)
	if not filename then return err end
	local f, err = newloadfile(filename)
	return f or err
end
searchers[2] = newsearchfile

return {
	oldload = oldload,
	load = newload,
	xforms = xforms,
}
