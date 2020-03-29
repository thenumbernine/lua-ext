local table = {}
for k,v in pairs(require 'table') do table[k] = v end

table.__index = table

function table.new(...)
	local t = setmetatable({}, table)
	for i=1,select('#', ...) do
		local o = select(i, ...)
		if o then
			for k,v in pairs(o) do
				t[k] = v
			end
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

-- 5.1 compatible
if not table.pack then
	function table.pack(...)
		local t = {...}
		t.n = select('#', ...)
		return setmetatable(t, table)
	end
else
	local oldpack = table.pack
	function table.pack(...)
		return setmetatable(oldpack(...), table)
	end
end

-- non-5.1 compat:
if not table.maxn then
	function table.maxn(t)
		local max = 0
		for k,v in pairs(t) do
			if type(k) == 'number' then
				max = math.max(max, k)
			end
		end
		return max
	end
end


-- something to consider:
-- mapvalue() returns a new table
-- but append() modifies the current table
-- for consistency shouldn't append() create a new one as well?
function table:append(...)
	for i=1,select('#', ...) do
		local u = select(i, ...)
		if u then
			for _,v in ipairs(u) do
				table.insert(self, v)
			end
		end
	end
	return self
end

function table:removeKeys(...)
	for i=1,select('#', ...) do
		local v = select(i, ...)
		self[v] = nil
	end
end

-- cb(value, key, newtable) returns newvalue[, newkey]
-- nil newkey means use the old key
function table:map(cb)
	local t = table()
	for k,v in pairs(self) do
		local nv, nk = cb(v,k,t)
		if nk == nil then nk = k end
		t[nk] = nv
	end
	return t
end

-- cb(value, key, newtable) returns newvalue[, newkey]
-- nil newkey means use the old key
function table:mapi(cb)
	local t = table()
	for k=1,#self do
		local v = self[k]
		local nv, nk = cb(v,k,t)
		if nk == nil then nk = k end
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
		if s == nil then
			s = v
		else
			s = callback(s, v)
		end
	end
	return s
end

local op = require 'ext.op'

function table:sum()
	return table.combine(self, op.add)
end

function table:product()
	return table.combine(self, op.mul)
end

function table:last()
	return self[#self]
end

-- just like string subset
function table.sub(t,i,j)
	if i < 0 then 
		if j == nil then
			i = math.max(1, #t + i + 1)
		else
			i = 1
		end
	end
	j = j or #t
	j = math.min(j, #t)
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

-- in-place sort is fine, but it returns nothing.  for kicks I'd like to chain methods
local oldsort = require 'table'.sort
function table:sort(...)
	oldsort(self, ...)
	return self
end

-- returns a shuffled duplicate of the ipairs in table 't'
function table.shuffle(t)
	t = table(t)
	local nt = table()
	while #t > 0 do
		nt:insert(t:remove(math.random(#t)))
	end
	return nt
end

-- where to put this ...
-- I want to convert iterators into tables
-- it looks like a coroutine but it is made for functions returned from coroutine.wrap
-- also, what to do with multiple-value iterators (like ipairs)
-- do I only wrap the first value?
-- do I wrap both values in a double table?
-- do I do it optionally based on the # args returned?
-- how about I ask for a function to convert the iterator to the table?
-- this is looking very similar to table.map
-- I'll just wrap it with table.wrap and then let the caller use :mapi to transform the results
-- usage: table.wrapfor(ipairs(t))
-- if you want to wrap a 'for=' loop then just use range(a,b[,c])
-- ok at this point I should just start using lua-fun ...
function table.wrapfor(f, s, var)
	local t = table()
	while true do
		local vars = table.pack(f(s, var))
		local var_1 = vars[1]
		if var_1 == nil then break end
		var = var_1
		t:insert(vars)
	end
	return t
end

return table
