-- auto serialize all cmdline params and store them in the global 'cmdline'
-- well, don't store them here, instead return the table from the require()
-- have ext.env store them in the global

local fromlua = require 'ext.fromlua'

local cmdline = {}

for _,w in ipairs(arg or {}) do
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
