--[[
	Copyright (c) 2013 Christopher E. Moore ( christopher.e.moore@gmail.com / http://christopheremoore.net )

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

table.__index = table

function table.new(...)
	local t = setmetatable({}, table)
	for _,o in ipairs{...} do
		for k,v in pairs(o) do
			t[k] = v
		end
	end
	return t
end

setmetatable(table, {
	__call = function(t, ...)
		return table.new(...)
	end
})

-- something to consider:
-- mapvalue() returns a new table
-- but append() modifies the current table
-- for consistency shouldn't append() create a new one as well?
function table:append(...)
	for _,u in ipairs{...} do
		for _,v in ipairs(u) do
			table.insert(self, v)
		end
	end
	return self
end

function table:removeKeys(...)
	for _,v in ipairs{...} do
		self[v] = nil
	end
end

-- cb(value[, key]) returns newvalue[, newkey]
-- nil newkey means use the old key
function table:map(cb)
	local t = table.new()
	for k,v in pairs(self) do
		local nv, nk = cb(v,k,t)
		if not nk then nk = k end
		t[nk] = nv
	end
	return t
end


-- this excludes keys that don't pass the callback function
-- if the key is an ineteger then it is table.remove'd
-- currently the handling of integer keys is the only difference between this 
-- and calling table.map and returning nil kills on filtered items 
function table:filter(f)
	local t = table.new()
	if type(f) == 'function' then 
		for k,v in pairs(self) do
			if f(v,k) then
				if type(k) == 'string' then
					t[k] = v
				else
					t:insert(v)
				end
			end
		end
	else
		-- I kind of want to do arrays ... but should we be indexing the keys or values?
		-- or separate functions for each?
		error('table.filter second arg must be a function')
	end
	return t
end

function table:keys()
	local t = table()
	for k,_ in pairs(self) do
		t:insert(k)
	end
	return t
end

function table:values()
	local t = table()
	for _,v in pairs(self) do
		t:insert(v)
	end
	return t
end

-- should we have separate finds for pairs and ipairs?
function table:find(value, eq)
	if eq then
		for k,v in pairs(self) do
			if eq(v, value) then return k, v end
		end
	else
		for k,v in pairs(self) do
			if v == value then return k, v end
		end
	end
end

-- should insertUnique only operate on the pairs() ?
-- 	especially when insert() itself is an ipairs() operation
function table:insertUnique(value, eq)
	if not table.find(self, value, eq) then table.insert(self, value) end
end

function table:removeObject(...)
	local removedKeys = table()
	local len = #self
	local k = table.find(self, ...)
	while k ~= nil do
		if type(k) == 'number' and tonumber(k) <= len then
			table.remove(self, k)
		else
			self[k] = nil
		end
		removedKeys:insert(k)
		k = table.find(self, ...)
	end
	return unpack(removedKeys)
end

-- I need to think of a better name for this... kvpairs() ?
function table:kvmerge()
	local t = table.new()
	for k,v in pairs(self) do
		table.insert(t, {k,v})
	end
	return t
end

-- TODO - math instead of table?
-- NOTICE as of 2012.12.04 I changed this to match :find( and return k,v instead of just v
function table:sup(cmp)
	local bestk, bestv
	if cmp then
		for k,v in pairs(self) do
			if bestv == nil or cmp(v, bestv) then bestk, bestv = k, v end
		end
	else
		for k,v in pairs(self) do
			if bestv == nil or v > bestv then bestk, bestv = k, v end
		end
	end
	return bestk, bestv
end

-- TODO - math instead of table?
function table:inf(cmp)
	local bestk, bestv
	if cmp then
		for k,v in pairs(self) do
			if bestv == nil or cmp(v, bestv) then bestk, bestv = k, v end
		end
	else
		for k,v in pairs(self) do
			if bestv == nil or v < bestv then bestk, bestv = k, v end
		end
	end
	return bestk, bestv
end

