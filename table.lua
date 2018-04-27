local table = {}
for k,v in pairs(require 'table') do table[k] = v end

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

-- 5.2 or 5.3 compatible
table.unpack = table.unpack or unpack

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
	local t = table()
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
	local t = table()
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
-- should we also return value, key to match map, sup, and inf?
--   that seems redundant if it's find-by-value ...
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
	return table.unpack(removedKeys)
end

function table:kvpairs()
	local t = table()
	for k,v in pairs(self) do
		table.insert(t, {[k]=v})
	end
	return t
end

-- TODO - math instead of table?
-- TODO - have cmp default to operator> just like inf and sort?
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
	return bestv, bestk
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
	return bestv, bestk
end

-- combine elements of
function table:combine(callback)
	local s
	for _,v in pairs(self) do
		if not s then
			s = v
		else
			s = callback(s, v)
		end
	end
	return s
end

function table:sum()
	return table.combine(self, function(a,b) return a+b end)
end

function table:product()
	return table.combine(self, function(a,b) return a*b end)
end

function table:last()
	return self[#self]
end

-- just like string subset
function table.sub(t,i,j)
	j = j or #t
	if i < 0 then 
		if j == nil then
			i = math.max(1, #t + i + 1)
		else
			i = 1
		end
	end
	local res = {}
	for k=i,j do
		res[k-i+1] = t[k]
	end
	setmetatable(res, table)
	return res
end

function table.reverse(t)
	local r = table()
	for i=#t,1,-1 do
		r:insert(t[i])
	end
	return r
end

function table.rep(t,n)
	local c = table()
	for i=1,n do
		c:append(t)
	end
	return c
end

function table.maxn(t)
	local max = 0
	for k,v in pairs(t) do
		if type(k) == 'number' then
			max = math.max(max, k)
		end
	end
	return max
end

-- in-place sort is fine, but it returns nothing.  for kicks I'd like to chain methods
local oldsort = require 'table'.sort
function table:sort(...)
	oldsort(self, ...)
	return self
end

function table.getn(...)
	local t = setmetatable({...}, table)
	t.n = select('#', ...)
	return t
end

return table
