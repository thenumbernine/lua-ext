-- TODO rename this file to ext.assert

local function prependmsg(msg, str)
	return (msg and (tostring(msg)..': ') or '')..str
end

local function asserttype(x, t, msg)
	local xt = type(x)
	if xt ~= t then
		error(prependmsg(msg, "expected "..tostring(t).." found "..tostring(xt)))
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

local function asserteq(a, b, msg)
	if not (a == b) then
		error(prependmsg(msg, "got "..tostring(a).." == "..tostring(b)))
	end
	return true
end

local function asserteqeps(a,b,eps,msg)
	eps = eps or 1e-7
	if math.abs(a - b) > eps then
		error((msg and msg..': ' or '').."expected |"..a.." - "..b.."| < "..eps)
	end
	return a, b, eps, msg
end

local function assertne(a, b, msg)
	if not (a ~= b) then
		error(prependmsg(msg, "got "..tostring(a).." ~= "..tostring(b)))
	end
	return true
end

local function assertlt(a, b, msg)
	if not (a < b) then
		error(prependmsg(msg, "got "..tostring(a).." < "..tostring(b)))
	end
	return true
end

local function assertle(a, b, msg)
	if not (a <= b) then
		error(prependmsg(msg, "got "..tostring(a).." <= "..tostring(b)))
	end
	return true
end

local function assertgt(a, b, msg)
	if not (a > b) then
		error(prependmsg(msg, "got "..tostring(a).." > "..tostring(b)))
	end
	return true
end

local function assertge(a, b, msg)
	if not (a >= b) then
		error(prependmsg(msg, "got "..tostring(a).." >= "..tostring(b)))
	end
	return true
end

local function assertindex(t, k, msg)
	local v = t[k]
	return assert(v, prependmsg(msg, "expected "..tostring(t).." [ "..tostring(k).." ]"))
end

-- assert integer indexes 1 to len, and len of tables matches
-- maybe I'll use ipairs... maybe
local function asserttableieq(t1, t2, msg)
	asserteq(#t1, #t2, msg)
	for i=1,#t1 do
		asserteq(t1[i], t2[i], msg)
	end
end

return {
	type = asserttype,
	types = asserttypes,
	eq = asserteq,
	ne = assertne,
	lt = assertlt,
	le = assertle,
	gt = assertgt,
	ge = assertge,
	index = assertindex,
	eqeps = asserteqeps,
	tableieq = asserttableieq,
}
