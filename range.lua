local table = require 'ext.table'

-- for-loop to generate a table
local function range(a,b,c)
	local t = table()
	if c then
		for x=a,b,c do
			t:insert(x)
		end
	elseif b then
		for x=a,b do
			t:insert(x)
		end
	else
		for x=1,a do
			t:insert(x)
		end
	end
	return t
end

return range
