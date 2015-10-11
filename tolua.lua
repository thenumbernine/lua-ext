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

local function escapeString(s)
	return ('%q'):format(s):gsub('\\\n','\\n')
end

local defaultSerializeForType = {
	number = tostring,
	boolean = tostring,
	['nil'] = tostring,
	string = escapeString,
	['function'] = function(x)
		return 'load(' .. escapeString(string.dump(x)) .. ')'
	end,
}

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
	local function toLuaKey(k)
		if type(k) == 'string' and k:match('^[_,a-z,A-Z][_,a-z,A-Z,0-9]*$') then
			return k
		else
			return '['..toLuaRecurse(k)..']'
		end
	end
	local touchedTables = {}
	function toLuaRecurse(x, tab)
		if not tab then tab = '' end
		local newtab = tab .. indentChar
		local xtype = type(x)
		local result
		if xtype == 'table' then
			-- TODO override for specific metatables?  as I'm doing for types?
			
			if touchedTables[x] then
				result = 'error("recursive reference")'	-- TODO allow recursive serialization by declaring locals before their reference?
			else
				touchedTables[x] = true
				
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
						s:insert(toLuaRecurse(x[k], newtab))
						addedIntKeys[k] = true
					end
				end

				-- sort key/value pairs added here by key
				local mixed = table()
				for k,v in pairs(x) do
					if not addedIntKeys[k] then
						mixed:insert{toLuaKey(k), toLuaRecurse(v, newtab)}
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
		assert(result)
		if serializeMetatables then
			local m = getmetatable(x)
			if m then
				result = 'setmetatable('..result..', '..toLuaRecurse(m, newtab)..')'
			end
		end
		return result
	end
	return toLuaRecurse(x)
end

return tolua
