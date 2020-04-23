local math = {}
for k,v in pairs(require 'math') do math[k] = v end

math.nan = 0/0

math.e = math.exp(1)

-- luajit and lua 5.1 compat ...
if not math.atan2 then math.atan2 = math.atan end
-- also note, code that uses math.atan(y,x) in luajit will instead just call math.atan(y) ...

function math.clamp(v,min,max)
	return math.min(math.max(v,min), max)
end

function math.sign(x)
	if x < 0 then return -1 end
	if x > 0 then return 1 end
	return 0
end

function math.trunc(x)
	if x < 0 then return math.ceil(x) else return math.floor(x) end
end

function math.round(x)
	return math.floor(x+.5)
end

function math.isnan(x) return x ~= x end
function math.isinf(x) return x == math.huge or x == -math.huge end
function math.isfinite(x) return tonumber(x) and not math.isnan(x) and not math.isinf(x) end

function math.isprime(n)
	if n < 2 then return false end	-- 1 isnt prime
	for i=2,math.floor(math.sqrt(n)) do
		if n%i == 0 then
			return false
		end
	end
	return true
end

function math.factors(n)
	local table = require 'ext.table'
	local f = table()
	for i=1,n do
		if n%i == 0 then 
			f:insert(i)
		end
	end
	return f
end

-- returns a table containing the prime factorization of the number
function math.primeFactorization(n)
	local table = require 'ext.table'
	n = math.floor(n)
	local f = table()
	while n > 1 do
		local found = false
		for i=2,math.floor(math.sqrt(n)) do
			if n%i == 0 then
				n = math.floor(n/i)
				f:insert(i)
				found = true
				break
			end
		end
		if not found then
			f:insert(n)
			break
		end
	end
	return f
end

function math.cbrt(x) return x^(1/3) end

return math
