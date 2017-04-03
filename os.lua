local os = {}
for k,v in pairs(require 'os') do os[k] = v end

-- 5.2 os.execute compat
if _VERSION == 'Lua 5.1' then
	local execute = os.execute
	function os.execute(cmd)
		local errcode = execute(cmd)
		local reason = ({
			[0] = 'exit',
		})[errcode] or 'unknown'
		return errcode==0 and true or nil, reason, errcode
	end
end

return os
