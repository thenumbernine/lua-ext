local coroutine = {}
for k,v in pairs(require 'coroutine') do coroutine[k] = v end

local function safehandle(thread, res, ...)
	if not res then
		local err = tostring(...)..'\n'..debug.traceback(thread)
		io.stderr:write(err..'\n')
		io.stderr:flush()
		return false, err
	end
	return true, ...
end

-- resumes thread
-- if the thread is dead, return false
-- if the thread is alive and resume failed due to error, prints the stack trace of the thread upon error
-- 	as opposed to assert(coroutine.resume(thread)), which only prints the stack trace of the resume statement
-- if the thread is alive and resume succeeded, returns true
function coroutine.assertresume(thread, ...)
	if coroutine.status(thread) == 'dead' then return false, 'dead' end
	return safehandle(thread, coroutine.resume(thread, ...))
end

return coroutine
