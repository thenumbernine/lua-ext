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

local function escapeString(s)
	return ('%q'):format(s):gsub('\\\n','\\n')
end

-- returns 'true' if k is a valid variable name
local function isVarName(k)
	return type(k) == 'string' and k:match('^[_,a-z,A-Z][_,a-z,A-Z,0-9]*$')
end

local toLuaRecurse

local function toLuaKey(state, k, path)
	if isVarName(k) then
		return k, true
	else
		local result = toLuaRecurse(state, k, nil, path, true)
		if result then
			return '['..result..']', false
		else
			return false, false
		end
	end
end

local defaultSerializeForType = {
	number = function(state,x) return tostring(x) end,
	boolean = function(state,x) return tostring(x) end,
	['nil'] = function(state,x) return tostring(x) end,
	string = function(state,x) return escapeString(x) end,
	['function'] = function(state, x)
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
	table = function(state, x, tab, path, keyRef)
		local result

		local newtab = tab .. state.indentChar
		-- TODO override for specific metatables?  as I'm doing for types?
		
		if state.touchedTables[x] then
			if state.skipRecursiveReferences then
				result = 'error("recursive reference")'
			else
				result = false	-- false is used internally and means recursive reference
				state.wrapWithFunction = true
				
				-- we're serializing *something*
				-- is it a value?  if so, use the 'path' to dereference the key
				-- is it a key?  if so the what's the value ..
				-- do we have to add an entry for both?
				-- maybe the caller should be responsible for populating this table ...
				if keyRef then
					state.recursiveReferences:insert('root'..path..'['..state.touchedTables[x]..'] = error("can\'t handle recursive references in keys")')
				else 
					state.recursiveReferences:insert('root'..path..' = '..state.touchedTables[x])
				end
			end
		else
			state.touchedTables[x] = 'root'..path
			
			-- prelim see if we can write it as an indexed table
			local numx = table.maxn(x)
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
					local nextResult = toLuaRecurse(state, x[k], newtab, path and path..'['..k..']')
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
					local keyStr, usesDot = toLuaKey(state, k, path)
					if keyStr then
						local newpath
						if path then
							newpath = path 
							if usesDot then newpath = newpath .. '.' end
							newpath = newpath .. keyStr
						end
						local nextResult = toLuaRecurse(state, v, newtab, newpath)
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

			local rs = '{'..state.newlineChar
			if #s > 0 then rs = rs .. newtab ..s:concat(','..state.newlineChar..newtab) .. state.newlineChar end
			rs = rs .. tab.. '}'
			result = rs
		end
		return result
	end,
}

local defaultSerializeMetatableFunc = function(state, m, x, tab)
	return toLuaRecurse(state, m, tab..state.indentChar)
end

toLuaRecurse = function(state, x, tab, path, keyRef)
	if not tab then tab = '' end
	
	local xtype = type(x)
	local serializeFunction
	if state.serializeForType then
		serializeFunction = state.serializeForType[xtype]
	end
	if not serializeFunction then
		serializeFunction = defaultSerializeForType[xtype]
	end
	
	local result
	if serializeFunction then
		result = serializeFunction(state, x, tab, path, keyRef)
	else
		result = '['..type(x)..':'..tostring(x)..']'
	end
	assert(result ~= nil)
	
	if state.serializeMetatables then
		local m = getmetatable(x)
		if m then
			local serializeMetatableFunc = state.serializeMetatableFunc or defaultSerializeMetatableFunc
			local mstr = serializeMetatableFunc(state, m, x, tab)
			-- make sure you get something
			assert(mstr ~= nil)
			-- but if that something is nil, i.e. setmetatable(something newly created with a nil metatable, nil), then don't bother modifing the code
			if mstr ~= 'nil' then
				result = 'setmetatable('..result..', '..mstr..')'
			end
		end
	end
	
	return result
end


local function tolua(x, args)
	local state = {
		indentChar = '',
		newlineChar = '',
		wrapWithFunction = false,
		recursiveReferences = table(),
		touchedTables = {},
	}
	if args then
		if args.indent then
			state.indentChar = '\t'
			state.newlineChar = '\n'
		end
		state.serializeForType = args.serializeForType 
		state.serializeMetatables = args.serializeMetatables
		state.serializeMetatableFunc = args.serializeMetatableFunc
		state.skipRecursiveReferences = args.skipRecursiveReferences 
	end	
	
	local str = toLuaRecurse(state, x, nil, '')
	
	if state.wrapWithFunction then
		str = '(function()' .. state.newlineChar
			.. state.indentChar .. 'local root = '..str .. ' ' .. state.newlineChar
			-- TODO defer self-references to here
			.. state.recursiveReferences:concat(' '..state.newlineChar..state.indentChar) .. ' ' .. state.newlineChar
			.. state.indentChar .. 'return root ' .. state.newlineChar
			.. 'end)()'
	end
	
	return str
end

return setmetatable({}, {
	__call = function(self, x, args)
		return tolua(x, args)
	end,
	__index = {
		-- escaping a Lua string for load() to use
		escapeString = escapeString,
		-- returns 'true' if the key passed is a valid Lua variable string, 'false' otherwise
		isVarName = isVarName,
		-- table of default serialization functions indexed by each time
		defaultSerializeForType = defaultSerializeForType,
		-- default metatable serialization function
		defaultSerializeMetatableFunc = defaultSerializeMetatableFunc,
	}
})
