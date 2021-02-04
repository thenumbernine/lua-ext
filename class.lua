local table = require 'ext.table'

-- classes

local function newmember(class, ...)
	local obj = setmetatable({}, class)
	if obj.init then return obj, obj:init(...) end
	return obj
end

local classmeta = {
	__call = function(self, ...)
		return self:new(...)
	end,
}

-- usage: obj:isa(class)
local function isa(self, cl)
	assert(cl, "isa expected a class")
--[[
	if self.class == cl then return true end
	if self.class.super then return isa(self.class.super, cl) end
	return false
--]]
	return self.isaKeys[cl] or false
end

local function class(...)
	local cl = table(...)
	cl.class = cl
	
	local parents = {...}
	cl.super = parents[1]
	cl.supers = parents
	
	cl.isaKeys = {[cl] = true}
	for _,parent in ipairs(parents) do
		cl.isaKeys[parent] = true
		if parent.isaKeys then
			for k,_ in pairs(parent.isaKeys) do
				cl.isaKeys[k] = true
			end
		end
	end

	cl.__index = cl
	cl.new = newmember
	cl.isa = isa
	
	-- class.is(object)
	cl.is = function(x)
		return type(x) == 'table' and x.isa and x:isa(cl)
	end
	
	setmetatable(cl, classmeta)
	return cl
end

return class
