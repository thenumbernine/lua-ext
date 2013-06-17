function io.fileexists(fn)
	local f, err = io.open(fn, 'r')
	if not f then return false, err end
	f:close()
	return true
end

function io.readfile(fn)
	local f, err = io.open(fn, 'rb')
	if not f then return false, err end
	local d = f:read('*a')
	f:close()
	return d
end

function io.writefile(fn, d)
	local f, err = io.open(fn, 'wb')
	if not f then return false, err end
	if d then f:write(d) end
	f:close()
	return true
end

function io.readproc(cmd)
	local f, err = io.popen(cmd)
	if not f then return false, err end
	local d = f:read('*a')
	f:close()
	return d
end

