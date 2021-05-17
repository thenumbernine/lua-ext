local table = require 'ext.table'

-- classes

local function newmember(class, ...)
	local obj = setmetatable({}, class)
	if obj.init then return obj, obj:init(...) end
	return obj
end

local classmeta = {
	__call = function(self, ...)
-- [[ normally:
		return self:new(...)
--]]
--[[ if you want to keep track of all instances
		local results = table.pack(self:new(...))
		local obj = results[1]
		table.insert(self.instances, obj)
		return results:unpack()
--]]
	end,
}

-- usage: class:isa(obj)
--  so it's not really a member method, since the object doesn't come first, but this way we can use it as Class:isa(obj) and not worry about nils or local closures
local function isa(cl, obj)
	assert(cl, "isa: argument 1 is nil, should be the class object")	-- isa(nil, anything) errors, because it should always have a class in the 1st arg
	if type(obj) ~= 'table' then return false end	-- class:isa(not a table) will return false
	if not obj.isaSet then return false end	-- not an object generated by class(), so it doesn't have a set of all classes that it "is-a"
	return obj.isaSet[cl] or false	-- returns true if the 'isaSet' of the object's metatable (its class) holds the calling class
end

local function class(...)
	local cl = table(...)
	cl.class = cl
	
	cl.super = ...	-- .super only stores the first.  the rest can be accessed by iterating .isaSet's keys

	-- I was thinking of calling this '.superSet', but it is used for 'isa' which is true for its own class, so this is 'isaSet'
	cl.isaSet = {[cl] = true}
	for i=1,select('#', ...) do
		local parent = select(i, ...)
		if parent ~= nil then
			cl.isaSet[parent] = true
			if parent.isaSet then
				for grandparent,_ in pairs(parent.isaSet) do
					cl.isaSet[grandparent] = true
				end
			end
		end
	end
	
	-- store 'descendantSet' as well that gets appended when we call class() on this obj?
	for ancestor,_ in pairs(cl.isaSet) do
		ancestor.descendantSet = ancestor.descendantSet or {}
		ancestor.descendantSet[cl] = true
	end

	cl.__index = cl
	cl.new = newmember
	
	cl.isa = isa	-- usage: Class:isa(obj)
	
	-- Class.is(object)
	-- requires closure & is a local function (which goes much slower)
	-- ... so I'm leaning away from this, but I already use it everywhere
	cl.is = function(x) return cl:isa(x) end

--[[ if you want to keep track of all instances
	cl.instances = setmetatable({}, {__mode = 'v'})
--]]

	setmetatable(cl, classmeta)
	return cl
end

return class
