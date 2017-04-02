--[[
	Copyright (c) 2015 Christopher E. Moore ( christopher.e.moore@gmail.com / http://christopheremoore.net )

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
--]]

local table = require 'ext.table'

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
local numbermeta
numbermeta = {
	__index = require 'ext.math',
--[[ tostring machine precision of arbitrary base
	base = 10,
	maxdigits = 50,
	__tostring = function(t,base)
		local s = {}
		if t < 0 then 
			t = -t 
			table.insert(s, '-')
		end
		if t == 0 then 
			table.insert(s, '0.')
		else
			--print('t',t)
			if not base then base = numbermeta.base end
			--print('base',base)
			local i = math.floor(math.log(t,base))+1
			if i == math.huge then error'infinite number of digits' end
			--print('i',i)	
			t = t / base^i
			--print('t',t)
			local dot
			while true do
				if i < 1 then 
					if not dot then
						dot = true
						table.insert(s, '.')
						table.insert(s, ('0'):rep(-i))
					end
					if t == 0 then break end
					if i <= -numbermeta.maxdigits then break end
				end		
				t = t * base
				local last = math.floor(t)
				t = t - last
				if last >= 0 and last < 10 then
					last = string.char(('0'):byte() + last)
				elseif last >= 10 and last < 10+26 then
					last = string.char(('a'):byte() + last-10)
				else
					last = '?'
				end
				table.insert(s, last)
				i = i - 1
				--print('t',t,'i',i,'last',last)	
			end
		end
		return table.concat(s)
	end,
--]]
}
debug.setmetatable(0, numbermeta)	

-- strings
getmetatable('').__concat = defaultConcat	
getmetatable('').__index = require 'ext.string'

-- It'd be fun if I could apply the operator to all return values, and not just the first ...
-- like (function() return 1,2 end + function() return 3,4 end)() returns 4,6
local function combineFunctionsWithBinaryOperator(f, g, op)
	if type(f) == 'function' and type(g) == 'function' then
		return function(...)
			return op(f(...), g(...))
		end
	elseif type(f) == 'function' then
		return function(...)
			return op(f(...), g)
		end
	elseif type(g) == 'function' then
		return function(...)
			return op(f, g(...))
		end
	else
		-- shouldn't get called unless __add is called explicitly
		return function()
			return op(f, g)
		end
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
local functionMeta = {
	-- I could make this a function composition like the rest of the meta operations, 
	-- but instead I'm going to have it follow the default __concat convention I have with other primitive types
	__concat = defaultConcat,
	dump = function(f) return string.dump(f) end,
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
		index = function(f, k)
			return function(...)
				return f(...)[k]
			end
		end,
		-- takes a function that returns an object
		--  returns a function that applies that object's __newindex to the key and value arguments
		-- so if t={} and f()==t then f:assign('a',1)() assigns t.a==1
		assign = function(f, k, v)
			return function(...)
				f(...)[k] = v
			end
		end,
		compose = function(...)	
			local funcs = {...}
			local funcsn = select('#', ...)
			for i=1,funcsn do
				assert(type(funcs[i]) == 'function')
			end
			return function(...)
				local args = {...}
				local argn = select('#', ...)
				for i=funcsn,1,-1 do
					args = {funcs[i](table.unpack(args,1,argn))}
					argn = table.maxn(args)
				end
				return table.unpack(args,1,argn)
			end
		end,
		-- bind / partial apply -- currying first args, and allowing vararg rest of args
		bind = function(f, ...)
			local args = {...}
			local argn = select('#', ...)
			return function(...)
				local n = argn
				local callargs = {table.unpack(args, 1, n)}
				for i=1,select('#', ...) do
					n=n+1
					callargs[n] = select(i, ...)
				end
				return f(table.unpack(callargs, 1, n))
			end
		end,
		-- Takes a function and a number of arguments,
		-- returns a function that applies them individually,
		-- first to the function, then to each function returned
		-- (a1 -> (a2 -> ... (an -> b))) -> (a1, a2, ..., an -> b)
		uncurry = function(f, n)
			return function(...)
				local s = f
				for i=1,n do
					s = s(select(i, ...))
				end
				return s
			end
		end,
		-- swaps the next two arguments
		swap = function(f)
			return function(a, b, ...)
				return f(b, a, ...)
			end
		end,
		dump = string.dump,
	}
	--]]
}
-- shorthand
functionMeta.__index._ = functionMeta.__index.index 
functionMeta.__index.o = functionMeta.__index.compose
debug.setmetatable(function() end, functionMeta)

-- TODO lightuserdata, if you can create it within lua somehow ...
