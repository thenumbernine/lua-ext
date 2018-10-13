local coroutine = {}
for k,v in pairs(require 'coroutine') do coroutine[k] = v end

-- resumes thread
-- if the thread is dead, return false
-- if the thread is alive and resume failed due to error, prints the stack trace of the thread upon error
-- 	as opposed to assert(coroutine.resume(thread)), which only prints the stack trace of the resume statement
-- if the thread is alive and resume succeeded, returns true
function coroutine.assertresume(thread, ...)
	if coroutine.status(thread) == 'dead' then
		return false
	else
		local res, err = coroutine.resume(thread, ...)
		if not res then
			io.stderr:write(err,'\n')
			io.stderr:write(debug.traceback(thread),'\n')
			return false
		end
	end
	return true
end

return coroutine
