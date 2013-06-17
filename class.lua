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
