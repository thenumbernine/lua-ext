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

--[[
how to handle recursion ...
a={}
b={}
a.b=b
b.a=a

tolua(a) would give ...
{b={a=error('recursive reference')}}

but how about, if something is found that is marked in touched tables ...
1) wrap everything in a function block
2) give root a local
3) add assignments of self-references after-the-fact

(function()
	local _tmp={b={}}
	_tmp.b.a= _tmp
	return _tmp
end)()
--]]

local table = require 'ext.table'

local function maxn(t)
	local max = 0
	for k,v in pairs(t) do
		if type(k) == 'number' then
			max = math.max(max, k)
		end
	end
	return max
end

local function escapeString(s)
	return ('%q'):format(s):gsub('\\\n','\\n')
end

local defaultSerializeForType = {
	number = tostring,
	boolean = tostring,
	['nil'] = tostring,
	string = escapeString,
	['function'] = function(x)
		local result, s = pcall(string.dump, x)
		
		if result then
			s = 'load('..escapeString(s)..')'
		else
			-- if string.dump failed then check the builtins
			-- check the global object and one table deep 
			-- todo maybe, check against a predefined set of functions?
			if s == "unable to dump given function" then
				for k,v in pairs(_G) do
					if v == x then
						s = k
						break
					elseif type(v) == 'table' then
						-- only one level deep ...
						local done = false
						for k2,v2 in pairs(v) do
							if v2 == x then
								s = k..'.'..k2
								done = true
								break
							end
						end
						if done then break end
					end
				end
			else
				return "error('got a function I could neither dump nor lookup in the global namespace nor one level deep')"
			end
		end
			
		return s
	end,
}

-- returns 'true' if k is a valid variable name
local function isVarName(k)
	return type(k) == 'string' and k:match('^[_,a-z,A-Z][_,a-z,A-Z,0-9]*$')
end

local function tolua(x, args)
	local indentChar = ''
	local newlineChar = ''
	local serializeForType 
	local serializeMetatables
	if args then
		if args.indent then
			indentChar = '\t'
			newlineChar = '\n'
		end
		serializeForType = args.serializeForType 
		serializeMetatables = args.serializeMetatables
	end	
	
	local wrapWithFunction = false
	local recursiveReferences = table()
	local touchedTables = {}

	local toLuaRecurse
	local function toLuaKey(k, path)
		if isVarName(k) then
			return k, true
		else
			local result = toLuaRecurse(k, nil, path, true)
			if result then
				return '['..result..']', false
			else
				return false, false
			end
		end
	end
	
	toLuaRecurse = function(x, tab, path, keyRef)
		if not tab then tab = '' end
		local newtab = tab .. indentChar
		local xtype = type(x)
		local result
		if xtype == 'table' then
			-- TODO override for specific metatables?  as I'm doing for types?
			
			if touchedTables[x] then
				result = false	-- false is used internally and means recursive reference
				wrapWithFunction = true
				
				-- we're serializing *something*
				-- is it a value?  if so, use the 'path' to dereference the key
				-- is it a key?  if so the what's the value ..
				-- do we have to add an entry for both?
				-- maybe the caller should be responsible for populating this table ...
				if keyRef then
					recursiveReferences:insert('root'..path..'['..touchedTables[x]..'] = error("can\'t handle recursive references in keys")')
				else 
					recursiveReferences:insert('root'..path..' = '..touchedTables[x])
				end
			else
				touchedTables[x] = 'root'..path
				
				-- prelim see if we can write it as an indexed table
				local numx = maxn(x)
				local intNilKeys, intNonNilKeys = 0, 0				
				for i=1,numx do
					if x[i] == nil then
						intNilKeys = intNilKeys + 1
					else
						intNonNilKeys = intNonNilKeys + 1
					end
				end

				local s = table()
				
				-- add integer keys without keys explicitly. nil-padded so long as there are 2x values than nils
				local addedIntKeys = {}
				if intNonNilKeys >= intNilKeys * 2 then	-- some metric
					for k=1,numx do
						local nextResult = toLuaRecurse(x[k], newtab, path and path..'['..k..']')
						if nextResult then
							s:insert(nextResult)
						-- else x[k] is a recursive reference 
						end
						addedIntKeys[k] = true
					end
				end

				-- sort key/value pairs added here by key
				local mixed = table()
				for k,v in pairs(x) do
					if not addedIntKeys[k] then
						local keyStr, usesDot = toLuaKey(k, path)
						if keyStr then
							local newpath
							if path then
								newpath = path 
								if usesDot then newpath = newpath .. '.' end
								newpath = newpath .. keyStr
							end
							local nextResult = toLuaRecurse(v, newtab, newpath)
							if nextResult then
								mixed:insert{keyStr, nextResult}
							-- else x[k] is a recursive reference
							end
						end
					end
				end
				mixed:sort(function(a,b) return a[1] < b[1] end)	-- sort by keys
				mixed = mixed:map(function(kv) return table.concat(kv, '=') end)
				s:append(mixed)

				local rs = '{'..newlineChar
				if #s > 0 then rs = rs .. newtab ..s:concat(','..newlineChar..newtab) .. newlineChar end
				rs = rs .. tab.. '}'
				result = rs
			end
		else
			local serializeFunction
			if serializeForType then
				serializeFunction = serializeForType[xtype]
			end
			if not serializeFunction then
				serializeFunction = defaultSerializeForType[xtype]
			end
			if serializeFunction then
				result = serializeFunction(x)
			else
				result = '['..type(x)..':'..tostring(x)..']'
			end
		end
		assert(result ~= nil)
		if serializeMetatables then
			local m = getmetatable(x)
			if m then
				result = 'setmetatable('..result..', '..toLuaRecurse(m, newtab)..')'
			end
		end
		return result
	end

	local str = toLuaRecurse(x, nil, '')
	
	if wrapWithFunction then
		str = '(function()' .. newlineChar
			.. indentChar .. 'local root = '..str .. ' ' .. newlineChar
			-- TODO defer self-references to here
			.. recursiveReferences:concat(' '..newlineChar..indentChar) .. ' ' .. newlineChar
			.. indentChar .. 'return root ' .. newlineChar
			.. 'end)()'
	end
	
	return str
end

return setmetatable({}, {
	__call = function(self, ...)
		return tolua(...)
	end,
	__index = {
		-- the function itself
		tolua = tolua,
		-- escaping a Lua string for load() to use
		escapeString = escapeString,
		-- returns 'true' if the key passed is a valid Lua variable string, 'false' otherwise
		isVarName = isVarName,
	}
})
