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

require 'ext.table'

-- classes

local function newmember(class, ...)
	local obj = setmetatable({}, class)
	if obj.init then obj:init(...) end
	return obj
end

local function callnew(self, ...)
	return self:new(...)
end

local function isa(self, cl)
	assert(cl, "isa expected a class")
	if self.class == cl then return true end
	if self.class.super then return isa(self.class.super, cl) end
	return false
end

local function class(...)
	local cl = table(...)
	cl.class = cl
	
	local parents = {...}
	cl.super = parents[1]
	cl.supers = parents
	
	cl.__index = cl
	cl.new = newmember
	cl.isa = isa
	
	setmetatable(cl, {__call = callnew})
	
	return cl
end

return class
