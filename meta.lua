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

local function combineFunctionsWithBinaryOperator(f, g, op)
	if type(f) == 'function' and type(g) == 'function' then
		return function(...) return op(f(...), g(...)) end
	elseif type(f) == 'function' then
		return function(...) return op(f(...), g) end
	elseif type(g) == 'function' then
		return function(...) return op(f, g(...)) end
	else
		return function() return op(f, g) end	-- shouldn't get called unless __add is called explicitly
	end
end

-- primitive functions.  should these be public?  or put in a single table?
local function add(a,b) return a + b end
local function sub(a,b) return a - b end
local function mul(a,b) return a * b end
local function div(a,b) return a / b end
local function pow(a,b) return a ^ b end
local function mod(a,b) return a % b end

-- function operators generate functions
-- f(x) = y, g(x) = z, (f+g)(x) = y+z 
debug.setmetatable(function() end, {
	-- I could make this a function composition like the rest of the meta operations, 
	-- but instead I'm going to have it follow the default __concat convention I have with other primitive types
	__concat = defaultConcat,	
	__tostring = function(f)
		assert(type(f) == 'function')
		local m = debug.getmetatable(f)
		debug.setmetatable(f, nil)
		local s = tostring(f)
		debug.setmetatable(f, m)
		return s .. ' ' .. string.dump(f)
	end,
	__add = function(f, g) return combineFunctionsWithBinaryOperator(f, g, add) end,
	__sub = function(f, g) return combineFunctionsWithBinaryOperator(f, g, sub) end,
	__mul = function(f, g) return combineFunctionsWithBinaryOperator(f, g, mul) end,
	__div = function(f, g) return combineFunctionsWithBinaryOperator(f, g, div) end,
	__pow = function(f, g) return combineFunctionsWithBinaryOperator(f, g, pow) end,
	__mod = function(f, g) return combineFunctionsWithBinaryOperator(f, g, mod) end,
	__unm = function(f) return function(...) return -f(...) end end,
	__len = function(f) return function(...) return #f(...) end end,
	-- boolean operations aren't overloaded just yet.  should they be?
	--__call doesn't work anyways
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
		-- swaps the next two arguments
		swap = function(f)
			return function(a, b, ...)
				return f(b, a, ...)
			end
		end,
	}
	--]]
})

-- TODO lightuserdata, if you can create it within lua somehow ...

