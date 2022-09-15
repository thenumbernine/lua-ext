local function asserttype(x, t)
	local xt = type(x)
	assert(xt == t, "expected "..t.." found "..xt)
	return x
end
return asserttype
