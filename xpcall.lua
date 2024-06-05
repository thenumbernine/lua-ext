--[[
shim layer for xpcall if it doesn't support ... forwarding
used by ext.load
xpcall doesn't forward extra args in vanilla lua 5.1, and in luajit without 5.2 compat (I think?)
--]]
return function(env)
	env = env or _G
	local oldxpcall = env.xpcall
	local xpcallfwdargs = select(2,
		oldxpcall(
			function(x) return x end,
			function() end,
			true
		)
	)
	if xpcallfwdargs then return end
	local unpack = env.unpack or table.unpack
	local function newxpcall(f, err, ...)
		local args = {...}
		args.n = select('#', ...)
		return oldxpcall(function()
			return f(unpack(args, 1, args.n))
		end, err)
	end
	env.xpcall = newxpcall
end
