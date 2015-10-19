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
notice that,
while this does override the 'string' and add some extra stuff,
it does not explicitly replace the default string metatable __index
to do that, require 'ext.meta' (or do it yourself)
--]]
local string = {}
for k,v in pairs(require 'string') do string[k] = v end

local table = require 'ext.table'

function string.split(s, exp)
	s = tostring(s)
	local t = table()
	local searchpos = 1
	local start, fin = s:find(exp, searchpos)
	while start do
		t:insert(s:sub(searchpos, start-1))
		searchpos = fin+1
		start, fin = s:find(exp, searchpos)
	end
	t:insert(s:sub(searchpos))
	return t
end

function string.trim(s)
	return s:match('^%s*(.-)%s*$')
end

function string.bytes(s)
	return table{s:byte(1,#s)}
end

--[[
-- drifting further from standards...
-- this string-converts everything concat'd (no more errors, no more print(a,b,c)'s)
getmetatable('').__concat = function(a,b)
	return tostring(a)..tostring(b)
end
--]]

-- a C++-ized accessor to subsets
-- indexes are zero-based inclusive
-- sizes are zero-based-exclusive (or one-based-inclusive depending on how you think about it)
-- parameters are (index, size) rather than (start index, end index)
function string.csub(d, start, size)
	if not size then return string.sub(d, start + 1) end	-- til-the-end
	return string.sub(d, start + 1, start + size)
end

--d = string data
--l = length of a column.  default 32
--w = hex word size.  default 1
--c = extra column space.  default 8
function string.hexdump(d, l, w, c)
	d = tostring(d)
	l = tonumber(l)
	w = tonumber(w)
	c = tonumber(c)
	if not l or l < 1 then l = 32 end
	if not w or w < 1 then w = 1 end
	if not c or c < 1 then c = 8 end
	local s = {}
	local col = 0
	for i=1,#d,w do
		if i % l == 1 then table.insert(s, string.format('%.8x ', (i-1))) col = 1 end
		table.insert(s, ' ')
		for j=w,1,-1 do
			local e = i+j-1
			local sub = d:sub(e,e)
			if #sub > 0 then
				table.insert(s, string.format('%.2x', string.byte(sub)))
			end
		end
		if col % c == 0 then table.insert(s, ' ') end
		if (i + w - 1) % l == 0 then table.insert(s, '\n') end
		col = col + 1
	end
	return table.concat(s)
end

return string
