local lua53 = _VERSION >= 'Lua 5.3'

local symbolscode = [[
	local unary = {
		unm = true,
		bnot = true,
		len = true,
		lnot = true,
	}
	
	local symbols = {
		add = '+',
		sub = '-',
		mul = '*',
		div = '/',
		mod = '%',
		pow = '^',
		unm = '-',			-- unary
		concat = '..',
		eq = '==',
		lt = '<',
		le = '<=',
		land = 'and',		-- non-overloadable
		lor = 'or',			-- non-overloadable
		len = '#',			-- unary
		lnot = 'not',		-- non-overloadable, unary
]]
if lua53 then
	symbolscode = symbolscode .. [[
		idiv = '//',		-- 5.3
		band = '&',			-- 5.3
		bor = '|',			-- 5.3
		bxor = '~',			-- 5.3
		shl = '<<',			-- 5.3
		shr = '>>',			-- 5.3
		bnot = '~',			-- 5.3, unary
]]	
end
symbolscode = symbolscode .. [[
	}
]]

local symbols, unary = assert((loadstring or load)(symbolscode..' return symbols, unary'))()

local code = symbolscode .. [[
	-- functions for operators
	return {
]]
for name,symbol in pairs(symbols) do
	if unary[name] then
		code = code .. [[
		]]..name..[[ = function(a) return ]]..symbol..[[ a end,
]]
	else
		code = code .. [[
		]]..name..[[ = function(a,b) return a ]]..symbol..[[ b end,
]]
	end
end
code = code .. [[
		index = function(t, k) return t[k] end,
		newindex = function(t, k, v)
			t[k] = v
			return t, k, v	-- ? should it return anything ?
		end,
		call = function(f, ...) return f(...) end,
		
		symbols = symbols,
	}
]]
return assert((loadstring or load)(code))()
