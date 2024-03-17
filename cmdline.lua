-- auto serialize all cmdline params and store them in the global 'cmdline'
-- well, don't store them here, instead return the table from the require()
-- have ext.env store them in the global

local fromlua = require 'ext.fromlua'

local function getCmdline(...)
	-- let cmdline[1...] work as well
	local cmdline = {...}

	for _,w in ipairs{...} do
		local k,v = w:match'^(.-)=(.*)$'
		if k then
			pcall(function()
				cmdline[k] = fromlua(v)
			end)
			if cmdline[k] == nil then cmdline[k] = v end
		else
			cmdline[w] = true
		end
	end

	return cmdline
end

--[[
ok now for some stern support
errors if it does't get a validated argument
TODO how to support key'd, indexed, or both cmds ...
for now just validate key'd commands.

desc =
	[cmdline key] = 
		true = use anything
		string = Lua type of the argument
			or 'number' will cast strings to numbers for you
			or 'file' = string + validate the file exists
		table = 
			.type = type of the argument \_ ... use one of these
			.validate = input validation /
			.must = error if the argument isn't present
			.desc = description of the argument (to print for help?)
		function
			= function for validating the argument

--]]
local function validate(desc)
	return function(...)
		local asserttype = require 'ext.assert'.type
		local table = require 'ext.table'
		local tolua = require 'ext.tolua'
		local cmdline = getCmdline(...)

		-- make sure all cmdline keys are in the description
		-- TODO this is going to assume the int key'd cmdline are from ... 
		--  and the string key'd cmdline are from 'k' or 'k=v'
		-- so if someon does '[1]=true', then yes, it will overwrite the int-key'd cmdline, and that should probably be prevented in 'getCmdline'
		for _,k in ipairs(table.keys(cmdline)) do
			local cmdValue = cmdline[k]
			if type(k) == 'number' then
				-- assume its part of the ... sequence
			elseif type(k) == 'string' then
				local descValue = desc[k]
				if not descValue then
					error("got an unknown command "..tolua(k))
				else
					-- use desc[k] to handle the cmdline
					if descValue == true then
						-- check.  valid.
					elseif type(descValue) == 'string' then
						-- special-case casting numbers etc?
						if descValue == 'number' then
							cmdline[k] = assert(tonumber(cmdValue))
						elseif descValue == 'file' then
							asserttype(cmdValue, 'string')
							assert(require 'ext.path'(cmdValue):exists(), "failed to find file "..tolua(cmdValue))
						else
							asserttype(cmdValue, descValue)
						end
					else
						error("TODO function/table validation of commandline args")
					end
				end
			else
				error("got a cmdline with an unknown key type: "..tolua(k))
			end
		end

		-- make sure all must-be keys are in the command-line
		for k,v in pairs(desc) do
			if type(v) == 'table' and v.must then
				if not cmdline[k] then
					error("expected to find key "..k)
				end
			end
		end

		return cmdline
	end
end

return setmetatable({
		getCmdline = getCmdline,
		validate = validate,
	}, {
	__call = function(t,...)
		return getCmdline(...)
	end,
})
