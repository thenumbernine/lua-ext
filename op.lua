-- functions for operators
return {
	-- __index overloadable operators
	add = function(a,b) return a + b end,
	sub = function(a,b) return a - b end,
	mul = function(a,b) return a * b end,
	div = function(a,b) return a / b end,
	mod = function(a,b) return a % b end,
	pow = function(a,b) return a ^ b end,
	unm = function(f) return -f end,
	idiv = function(a,b) return a // b end,
	band = function(a,b) return a & b end,
	bor = function(a,b) return a | b end,
	bxor = function(a,b) return a ~ b end,
	bnot = function(a) return ~a end,	
	shl = function(a,b) return a << b end,
	shr = function(a,b) return a >> b end,
	concat = function(a,b) return a .. b end,
	len = function(f) return #f end,
	eq = function(a,b) return a == b end,
	lt = function(a,b) return a < b end,
	le = function(a,b) return a <= b end,
	index = function(t, k) return t[k] end,
	newindex = function(t, k, v)
		t[k] = v
		return t, k, v	-- ? should it return anything ?
	end,
	call = function(f, ...) return f(...) end,
	
	-- non-overloadable operators:
	land = function(a,b) return a and b end,
	lor = function(a,b) return a or b end,
	lnot = function(a) return not a end,
}
