--[[
shim layer for xpcall if it doesn't support ... forwarding
used by ext.load
xpcall doesn't forward extra args in vanilla lua 5.1, and in luajit without 5.2 compat (I think?)

For now I'm not going to add this to ext.env since it just outright modifies _G and not a specified env.
I'm not sure if or when I'll change it to operate on specific envs.
--]]
local env = _G	-- TODO or make this allow custom envs? function(env) wrapping the whole thing?
local xpcallfwdargs = select(2,
	env.xpcall(
		function(x) return x end,
		function() end,
		true
	)
)
if not xpcallfwdargs then
	local oldxpcall = env.xpcall
	local unpack = env.unpack or table.unpack
	local function newxpcall(f, err, ...)
		local args = {...}
		args.n = select('#', ...)
		return oldxpcall(function()
			return f(unpack(args, 1, args.n))
		end, err)
	end
	env.xpcall = newxpcall
	return newxpcall
else
	return xpcall	-- or just true?
end
