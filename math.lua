local math = {}
for k,v in pairs(require 'math') do math[k] = v end

math.nan = 0/0

math.e = math.exp(1)

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

return math
