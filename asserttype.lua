local function prependmsg(msg, str)
	return (msg and (tostring(msg)..': ') or '')..str
end

local function asserttype(x, t, msg)
	local xt = type(x)
	if xt ~= t then
		error(prependmsg(msg, "expected "..t.." found "..xt))
	end
	return x
end

-- how to specify varargs...
-- for now: (msg, N, type1, ..., typeN, arg1, ..., argN)
local function asserttypes(msg, n, ...)
	asserttype(n, 'number', prependmsg(msg, "asserttypes number of args"))
	for i=1,n do
		asserttype(select(n+i, ...), select(i, ...), prependmsg(msg, "asserttypes arg "..i))
	end
	return select(n+1, ...)
end
local mt = {
	asserttype = asserttype,
	asserttypes = asserttypes,
	__call = function(mt, ...)
		return asserttype(...)
	end,
}
mt.__index = mt
setmetatable(mt, mt)
return mt
