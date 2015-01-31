-- fix up lua type metatables

local function defaultConcat(a,b) return tostring(a) .. tostring(b) end

-- nil
debug.setmetatable(nil, {__concat = defaultConcat})	

-- booleans
debug.setmetatable(true, {
	__concat = defaultConcat,
	__index = {
		and_ = function(a,b) return a and b end,
		or_ = function(a,b) return a or b end,
		not_ = function(a) return not a end,
		xor = function(a,b) return a ~= b end,
		implies = function(a,b) return not a or b end,
	}
})

-- numbers
debug.setmetatable(0, {__index = math})	

-- strings
getmetatable('').__concat = defaultConcat	

-- function operators generate functions
debug.setmetatable(function()end, {
	__concat = defaultConcat,
	__tostring = function(f)
		assert(type(f) == 'function')
		local m = debug.getmetatable(f)
		debug.setmetatable(f, nil)
		local s = tostring(f)
		debug.setmetatable(f, m)
		return s .. ' ' .. string.dump(f)
	end,
	__add = function(f, g) return function(...) return f(...) + g(...) end end,
	__sub = function(f, g) return function(...) return f(...) - g(...) end end,
	__mul = function(f, g) return function(...) return f(...) * g(...) end end,
	__div = function(f, g) return function(...) return f(...) / g(...) end end,
	__pow = function(f, g) return function(...) return f(...) ^ g(...) end end,
	__mod = function(f, g) return function(...) return f(...) % g(...) end end,
	-- TODO comparison operations too?  probably not equivalence for compatability with sort() and anything else
	-- TODO boolean operations?  anything else?
	--[[ here's one option for allowing any function object dereference to be mapped to a new function
	__index = function(f, k) return function(...) return f(...)[k] end end,
	__newindex = function(f, k, v) return function(...) f(...)[k] = v end end,
	--]]
	-- [[ ... but that prevents us from overloading our own methods.  
	-- so here's "index" to be used in its place
	-- while we can provide more of our own methods as we desire
	__index = {
		-- takes a function that returns an object
		--  returns a function that returns that object's __index to the key argument 
		-- so if f() = {a=1} then f:index'a'() == 1
		index = function(f, k) return function(...) return f(...)[k] end end,
		-- takes a function that returns an object
		--  returns a function that applies that object's __newindex to the key and value arguments
		-- so if t={} and f()==t then f:assign('a',1)() assigns t.a==1
		assign = function(f, k, v) return function(...) f(...)[k] = v end end,
		compose = function(...)	-- equivalent of lisp's "mapcar"
			local funcs = {...}
			for _,f in ipairs(funcs) do assert(type(f) == 'function') end
			return function(...)
				local args = {...}
				for i=#funcs,1,-1 do
					args = {funcs[i](unpack(args))}
				end
				return unpack(args)
			end
		end,
		-- bind / partial apply -- currying first args, and allowing vararg rest of args
		bind = function(f, ...)
			local args = {...}
			return function(...)
				local callargs = {unpack(args)}
				for _,v in ipairs{...} do table.insert(callargs, v) end
				return f(unpack(callargs))
			end
		end,
	}
	--]]
})

-- TODO lightuserdata, if you can create it within lua somehow ...

