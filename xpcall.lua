--[[
shim layer for xpcall if it doesn't support ... forwarding
used by ext.load
xpcall doesn't forward extra args in vanilla lua 5.1, and in luajit without 5.2 compat (I think?)

while I'm here I will insert a default error handler, since 99% of my xpcall functions do nothing more than
`function(err) return err..'\n'..debug.traceback() end`
 so that it will always capture the stack trace at the error by default.
--]]

local function defaultErrorHandler(err)
	return tostring(err)..'\n'..debug.traceback()
end

return function(env)
	env = env or _G
	local oldxpcall = env.xpcall or _G.xpcall
	local xpcallCanFwdArgs = select(2,
		oldxpcall(
			function(x) return x end,
			function() end,
			true
		)
	)

	-- perform an xpcall without an error handler
	-- see if it errors
	local xpcallHasDefaultErrorHandler = xpcall(function()
		xpcall(function() end)
	end, function() end)
	if xpcallCanFwdArgs then
		if not xpcallHasDefaultErrorHandler then
			-- xpcall arg forwarding works
			-- just replace xpcall with a default error handler
			local newxpcall = function(f, err, ...)
				err = err or defaultErrorHandler
				return oldxpcall(f, err, ...)
			end
			env.xpcall = newxpcall
		else
			-- no changes necessary to xpcall's behavior
			-- write .xpcall if it's not already there
			if not env.xpcall then
				env.xpcall = oldxpcall
			end
		end
	else
		-- xpcall arg forwarding doesn't work
		-- replace it with an xpcall that does arg forwarding
		local unpack = env.unpack or table.unpack
		local newxpcall = function(f, err, ...)
			err = err or defaultErrorHandler
			local args = {...}
			args.n = select('#', ...)
			return oldxpcall(function()
				return f(unpack(args, 1, args.n))
			end, err)
		end
		env.xpcall = newxpcall
	end
end
